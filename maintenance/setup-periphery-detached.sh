#!/bin/bash

# Fully clear any previous unit state
systemctl stop periphery-update.timer 2>/dev/null || true
systemctl stop periphery-update.service 2>/dev/null || true
systemctl reset-failed periphery-update.service 2>/dev/null || true

# Pass HOME explicitly so the python installer doesn't crash
systemd-run --on-active=60 --unit=periphery-update \
    --setenv=HOME=/root \
    --setenv=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3 - >> /tmp/periphery_install.log 2>&1"

echo "Periphery update scheduled via systemd in 60s. Log at /tmp/periphery_install.log"
exit 0