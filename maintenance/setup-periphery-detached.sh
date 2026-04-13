#!/bin/bash

systemd-run --on-active=60 --unit=periphery-update \
    bash -c "curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3 - >> /tmp/periphery_install.log 2>&1"

echo "Periphery update scheduled via systemd in 60s. Log at /tmp/periphery_install.log"
exit 0