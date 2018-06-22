#!/bin/bash
# script that runs via outset login item.

backupTitle="Backblaze Backup"
prefFile="/Library/Preferences/BZdeployer"
iconFile="/Library/Mac-MSP/Gruntwork/cocoad.png"
installTrigger="/Library/Scripts/bz/.trigger"
installerDMG="/Library/Scripts/bz/install_backblaze.dmg"
cocoaDialog="/Library/Mac-MSP/Gruntwork/cocoaDialog.app/Contents/MacOS/cocoaDialog"
log="/Library/Scripts/bz/bzinstall.log"

# set up log
exec >> >(tee -ai ${log})
exec 2>&1

## functions

getEmail() {
  email=$(${cocoaDialog} standard-inputbox --informative-text "Please enter your email address:" \
    --title "${backupTitle}" \
    --icon-file "${iconFile}" \
    --float --value-required --quiet)
  if [[ -z $email ]]; then
    echo "   User cancelled."
    exit 0
  fi
  until [[ $email =~ ^.*@.*$ ]]
  do
    email=$(${cocoaDialog} standard-inputbox --informative-text "Invalid email, enter your email address:" \
      --title "${backupTitle}" \
      --icon-file "${iconFile}" \
      --float --value-required --quiet)
    if [[ -z $email ]]; then
      echo "   User cancelled."
      exit 0
     fi
  done
  verify=$(${cocoaDialog} standard-inputbox --informative-text "Please verify your email address:" \
    --title "${backupTitle}" \
    --icon-file "${iconFile}" \
    --float --value-required --quiet)
  if [[ -z $verify ]]; then
    echo "   User cancelled."
    exit 0
   fi
}

getPassword() {
  password=$(${cocoaDialog} secure-standard-inputbox --informative-text "Please enter your Backblaze password:" \
    --title "${backupTitle}" \
    --icon-file "${iconFile}" \
    --float --value-required --quiet)
  if [[ -z $password ]]; then
    echo "   User cancelled."
    exit 0
  fi
  verify=$(${cocoaDialog} secure-standard-inputbox --informative-text "Please verify your Backblaze password:" \
    --title "${backupTitle}" \
    --icon-file "${iconFile}" \
    --float --value-required --quiet)
  if [[ -z $verify ]]; then
    echo "   User cancelled."
    exit 0
   fi
}

## lets do this...
echo ">> TRMSP Backblaze Install..."

# check if bz is already installed/registered
if [ -e /Library/Backblaze.bzpkg/bzdata/bzinfo.xml ]; then
  echo "   Seems Backblaze is already installed and registered.  Bailing..."
  exit 0
fi

# check if we have already opted out of the backup previously
optOut=$(defaults read "${prefFile}" bzOptOut 2>/dev/null)
if [ "${optOut}" == "1" ]; then
  echo "   User has already opted out of our backup.  Bailing..."
  exit 0
fi

# check and get our group id and token
bzGroup=$(defaults read "${prefFile}" bzGroup 2>/dev/null)
bzToken=$(defaults read "${prefFile}" bzToken 2>/dev/null)
if [[ -z "${bzGroup}" || -z "${bzToken}" ]]; then
  echo "   We have not been set up with a Group ID or Token.  Bailing..."
  exit 0
fi

# exit with error if our pref file doesnt already exist
if [ ! -e "${prefFile}.plist" ]; then
  echo "   Pref file doesnt exist - we do not have enough provided information for install.  Bailing..."
  exit 1
fi

# prompt User
rv=$(${cocoaDialog} msgbox --text "Would you like to opt-in to the TR MSP provided backup?" \
  --title "${backupTitle}" \
  --icon-file "${iconFile}" \
  --float \
  --button1 "Ask Later" \
  --button2 "Yes" \
  --button3 "No")

if [[ ${rv} -eq 3 ]]; then
  # they are opting out - lets set preference key
  defaults write "${prefFile}" bzOptOut -bool true
  exit 0
elif [[ ${rv} -eq 2 ]]; then
  # opting in - lets ask for email
  getEmail
  until [[ $verify == $email ]]; do
    getEmail
  done

  # are we a prexisting user or new?
  rv2=$(${cocoaDialog} msgbox --text "Has $email been used with Backblaze before?" \
    --title "${backupTitle}" \
    --icon-file "${iconFile}" \
    --float \
    --button1 "No" \
    --button2 "Yes")

  if [[ ${rv2} -eq 2 ]]; then
    # set install type to signinaccount and prompt user for password
    installType="signinaccount"
    getPassword
    until [[ $verify == $password ]]; do
      getPassword
    done
  else
    # new account - lets set our install type as such and generate a password
    installType="createaccount"
    password="none"
  fi
else
  exit 0
fi

## now we need to pass the info along to our installer script which is privileged
echo -e "${installType}\n${email}\n${password}\n${bzGroup}\n${bzToken}" > ${installTrigger}

echo "   Installation should be taking place... Done for now."
