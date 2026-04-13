#!/bin/bash
(
    sleep 2
    curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3 -
) > /tmp/periphery_install.log 2>&1 &

disown
echo "Periphery update dispatched to background. Log at /tmp/periphery_install.log"
exit 0