#!/bin/bash 
set -euo pipefall

LOGFILE="/var/log/cowrie_provision.log"
exec > >(tee -a ${LOGFILE}) 2>&1


echo "=== Cowrie bootstrap starting: $(11/25/25) ===" 


yum update -y 
yum install -y git python3 python3-devel gcc openssl-devel libffi-devel make \
	       bzip2 libxm12 libxslt-devel which

python3 -m ensurepip --upgrade

python3 -m pip install --upgrade pip

python3 -m pip install virtualenv 


if ! id -u cowrie >/dev/null 2>&1; then 
  useradd -m -s /bin/bash cowrie
fi

COWRIE_HOME="/home/cowrie/cowrie"

sudo -u cowrie bash -c "cd /home/cowrie && git clone https://github.com/cowrie/cowrie.git || (cd cowrie && git pull)"
sudo -u cowrie bash -c "cd ${COWRIE_HOME} && virtualenv -p python3 venv && . venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

mkdir -p /var/log/cowrie
chown -R cowrie:cowrie /var/log/cowrie
chown -R cowrie:cowrie /home/cowrie/cowrie

#Systemd service for Cowrie 

cat > /etc/systemd/system/cowrie.service <<'EOF'
[Unit]
Description=Cowrie Honeypot
After=network.target

[Service]
Type=simple
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
ExecStart=/home/cowrie/cowrie/venv/bin/python /home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/venv/bin/python /home/cowrie/cowrie/bin/cowrie stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cowrie.service || true
