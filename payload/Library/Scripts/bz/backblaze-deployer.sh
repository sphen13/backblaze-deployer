#!/bin/bash
# script to perform backblaze install.  triggered by a launchdaemon watchpath

prefFile="/Library/Preferences/BZdeployer"
installerDMG="/Library/Scripts/bz/install_backblaze.dmg"
installTrigger="/Library/Scripts/bz/.trigger"
log="/Library/Scripts/bz/bzinstall.log"

# set up log
exec >> >(tee -ai ${log})
exec 2>&1

input=$(cat ${installTrigger})
input=(${input[@]})

## attach the dmg and install using the provided info
/usr/bin/hdiutil attach -mountpoint /tmp/bzinstall -quiet "${installerDMG}"
/tmp/bzinstall/Backblaze\ Installer.app/Contents/MacOS/bzinstall_mate -nogui -${input[0]} ${input[1]} ${input[2]} ${input[3]} ${input[4]}
sleep 2
/usr/bin/hdiutil detach -quiet /tmp/bzinstall
rm -f ${installTrigger}
