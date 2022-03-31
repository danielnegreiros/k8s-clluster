#!/bin/bash

## Reboot nodes, so we now everything works fine after reboot
## Sleep 30 seconds to wait sync with master
sleep 30
sudo -i

echo "Finished successfully"
reboot
