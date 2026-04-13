#!/bin/bash

# Schedule the actual install to run 1 minute from now,
# completely outside of the current session/connection
echo "curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3 - >> /tmp/periphery_install.log 2>&1" | at now + 1 minute

echo "Periphery update scheduled in 1 minute. Log at /tmp/periphery_install.log"
exit 0