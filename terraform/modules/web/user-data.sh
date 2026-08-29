#!/usr/bin/env bash

# user-data.sh - Configure the EC2 instance as a simple web server

# References:
# Amazon EC2 user data

set -euo pipefail

WEB_ROOT="/opt/reframe-web"
SERVICE_FILE="/etc/systemd/system/reframe-web.service"

# Create the web root
mkdir -p "${WEB_ROOT}"

# Create a simple challenge page
cat > "${WEB_ROOT}/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>AWS Terraform Engineering Challenge</title>
</head>
<body>
    <h1>AWS Terraform Engineering Challenge</h1>
    <p>Private EC2 web server is running</p>
</body>
</html>
EOF

# Run the built-in Python web server as a system service
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Engineering Challenge Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 80 --bind 0.0.0.0 --directory ${WEB_ROOT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the web server now and on future boots
systemctl daemon-reload
systemctl enable --now reframe-web.service
