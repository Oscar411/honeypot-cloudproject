"""Lambda that handles GuardDuty findings:
- Parses finding JSON
- Snapshots EBS volumes attached to the honeypot instance
- Computes SHA256 of metadata
- Uploads metadata JSON to S3
- Posts a Slack alert and creates a TheHive case (if secrets provided)
"""

import json
import hashlib
import os
import time
import urllib.request
from datetime import datetime, timezone

import boto3

# boto3 clients
ec2 = boto3.client("ec2")
s3 = boto3.client("s3")
secretsmanager = boto3.client("secretsmanager")


def _get_secret_json(secret_arn: str) -> dict:
    """Return secret value parsed as JSON (empty dict if missing)."""
    if not secret_arn:
        return {}
    resp = secretsmanager.get_secret_value(SecretId=secret_arn)
    if "SecretString" in resp and resp["SecretString"]:
        try:
            return json.loads(resp["SecretString"])
        except Exception:
            return {"value": resp["SecretString"]}
    return {}


def _get_instance_id_from_finding(detail: dict) -> str | None:
    """Try multiple paths to extract an EC2 instance ID from GuardDuty detail."""
    resource = detail.get("resource", {})
    # common shapes
    inst = resource.get("instanceDetails") or resource.get("instance")
    if isinstance(inst, dict):
        return inst.get("instanceId") or inst.get("InstanceId")
    # older shape
    if "instanceId" in resource:
        return resource.get("instanceId")
    return None


def _get_attached_volumes(instance_id: str) -> list:
    """Return list of EBS volume IDs attached to instance."""
    resp = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = resp.get("Reservations") or []
    if not reservations:
        return []
    instance = reservations[0]["Instances"][0]
    mappings = instance.get("BlockDeviceMappings", [])
    return [m["Ebs"]["VolumeId"] for m in mappings if "Ebs" in m]


def _create_snapshots_for_volumes(volume_ids: list, finding_id: str, instance_id: str) -> list:
    """Create snapshots for volumes and tag them. Return list of dicts with snapshot details."""
    snapshots = []
    for vol in volume_ids:
        desc = f"Honeypot snapshot for finding {finding_id} on {instance_id} at {datetime.now(timezone.utc).isoformat()}"
        snap = ec2.create_snapshot(VolumeId=vol, Description=desc)
        snap_id = snap["SnapshotId"]
        # tag snapshot (best-effort)
        try:
            ec2.create_tags(Resources=[snap_id], Tags=[
                {"Key": "Honeypot", "Value": "true"},
                {"Key": "FindingId", "Value": finding_id},
                {"Key": "InstanceId", "Value": instance_id}
            ])
        except Exception:
            pass
        snapshots.append({"snapshot_id": snap_id, "volume_id": vol, "description": desc})
    return snapshots


def _upload_metadata(bucket: str, metadata: dict) -> str:
    """Upload metadata to S3 and return the key used."""
    timestamp = int(time.time())
    key = f"metadata/{metadata.get('finding_id','manual')}_{timestamp}.json"
    s3.put_object(Bucket=bucket, Key=key, Body=json.dumps(metadata).encode("utf-8"), ContentType="application/json")
    return key


def _post_slack(webhook_url: str, text: str):
    """Post a message to a Slack webhook (simple)."""
    if not webhook_url:
        return
    payload = json.dumps({"text": text}).encode("utf-8")
    req = urllib.request.Request(webhook_url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        resp.read()


def _create_thehive_case(api_url: str, api_key: str, title: str, description: str):
    """Create a basic case in TheHive. Adjust headers/payload if your instance requires different auth."""
    if not api_url or not api_key:
        return
    payload = json.dumps({
        "title": title,
        "description": description,
        "severity": 2,
        "tags": ["honeypot", "guardduty"]
    }).encode("utf-8")
    req = urllib.request.Request(api_url, data=payload, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp.read()
    except Exception:
        # best-effort: do not fail the Lambda if thehive call fails
        pass


def lambda_handler(event, _context):  # pylint: disable=unused-argument
    """
    Entrypoint: expects GuardDuty EventBridge event.
    Environment variables used:
      METADATA_BUCKET - target S3 bucket name (required)
      DEFAULT_HONEYPOT_INSTANCE - optional fallback instance id
      SLACK_SECRET_ARN - optional Secrets Manager ARN with {"webhook_url": "..."}
      THEHIVE_SECRET_ARN - optional Secrets Manager ARN with {"api_url":"...","api_key":"..."}
    """
    # required env
    bucket = os.environ.get("METADATA_BUCKET")
    if not bucket:
        raise RuntimeError("METADATA_BUCKET environment variable must be set")

    default_instance = os.environ.get("DEFAULT_HONEYPOT_INSTANCE", "")
    slack_secret_arn = os.environ.get("SLACK_SECRET_ARN", "")
    thehive_secret_arn = os.environ.get("THEHIVE_SECRET_ARN", "")

    detail = event.get("detail", {}) or {}
    finding_id = detail.get("id", f"manual-{int(datetime.now(timezone.utc).timestamp())}")
    finding_type = detail.get("type", "Unknown")

    # determine instance id
    instance_id = _get_instance_id_from_finding(detail) or default_instance
    if not instance_id:
        # store finding only and exit
        metadata = {
            "finding_id": finding_id,
            "finding_type": finding_type,
            "instance_id": None,
            "snapshots": [],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "note": "no_instance_found"
        }
        key = _upload_metadata(bucket, metadata)
        return {"status": "no_instance", "s3_key": key}

    # get attached volumes
    volume_ids = _get_attached_volumes(instance_id)

    # create snapshots
    snapshots = _create_snapshots_for_volumes(volume_ids, finding_id, instance_id)

    # build metadata and sha256
    metadata = {
        "finding_id": finding_id,
        "finding_type": finding_type,
        "instance_id": instance_id,
        "snapshots": snapshots,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    meta_json = json.dumps(metadata, sort_keys=True)
    sha256 = hashlib.sha256(meta_json.encode("utf-8")).hexdigest()
    metadata["sha256"] = sha256

    # upload metadata
    s3_key = _upload_metadata(bucket, metadata)

    # Slack alert
    slack_secret = _get_secret_json(slack_secret_arn)
    slack_webhook = slack_secret.get("webhook_url")
    if slack_webhook:
        text = (f"🚨 Honeypot GuardDuty finding: {finding_id}\n"
                f"Instance: {instance_id}\n"
                f"Snapshots: {[s['snapshot_id'] for s in snapshots]}\n"
                f"S3: s3://{bucket}/{s3_key}\nSHA256: {sha256}")
        try:
            _post_slack(slack_webhook, text)
        except Exception:
            pass

    # TheHive case
    thehive_secret = _get_secret_json(thehive_secret_arn)
    api_url = thehive_secret.get("api_url")
    api_key = thehive_secret.get("api_key")
    if api_url and api_key:
        title = f"Honeypot finding {finding_id}"
        desc = f"Instance: {instance_id}\nSnapshots: {[s['snapshot_id'] for s in snapshots]}\nS3: s3://{bucket}/{s3_key}\nSHA256: {sha256}\nFinding: {json.dumps(detail)}"
        _create_thehive_case(api_url, api_key, title, desc)

    return {"status": "ok", "s3_key": s3_key, "sha256": sha256}