#!/usr/bin/env bash

# original file:
# OSXLockdown set — https://github.com/SummitRoute/osxlockdown

# Ask for the administrator password upfront
echo "I need root password for system configuration:"
sudo -v

# Keep-alive: update existing `sudo` time stamp until `osxdefaults.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# OSXLockdown set (Security Settings)                                         #
###############################################################################

# Verify all application software is current
sudo softwareupdate -i -a

# Enable Auto Update
sudo softwareupdate --schedule on

# Disable Bluetooth
#sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0;
#sudo killall -HUP blued

# Disable infrared receiver
sudo defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -int 0

# Disable AirDrop
defaults write com.apple.NetworkBrowser DisableAirDrop -bool YES

# Set time and date manually
sudo systemsetup setusingnetworktime off

# Set an inactivity interval of 1000 minutes or less for the screen saver 
UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep "IOPlatformUUID" | sed -e 's/^.*"\(.*\)"$/\1/'`;
for i in $(find /Users -type d -maxdepth 1); do
  PREF=$i/Library/Preferences/ByHost/com.apple.screensaver.$UUID;
  if [ -e $PREF.plist ]; then
    defaults -currentHost write $PREF.plist idleTime -int 60000;
  fi
done

# Enable secure screen saver corners
for i in $(find /Users -type d -maxdepth 1); do 
  PREF=$i/Library/Preferences/com.apple.dock.plist; 
  if [ -e $PREF ]; then 
    CORNER=$(defaults read $PREF | grep corner | grep 6) && {
      if [ -n "$CORNER" ]; then 
        defaults write $PREF wvous-tr-corner 5; 
      fi
    } 
  fi
done

# Require a password to wake the computer from sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Disable Remote Apple Events
sudo systemsetup -setremoteappleevents off

# Disable Remote Login
sudo systemsetup -f -setremotelogin off

# Disable Internet Sharing
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add Enabled -int 0

# Disable Screen Sharing
launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

# Disable Printer Sharing
cupsctl --no-share-printers

# Disable Wake on Network Access
sudo systemsetup -setwakeonnetworkaccess off

# Disable File Sharing
launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist

# Disable Remote Management
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop

# Enable FileVault (I don't use it because of SSD)
# fdesetup enable

# Destroy File Vault Key when going to standby (I don't use it because of SSD)
# sudo pmset -a destroyfvkeyonstandby 1

# Enable hibernation mode (no memory power on sleep)
# (I don't use it because of it will write system state to disk (sleep image)
# instead of memory, but... I don't use FileVault. No sense.)
# sudo pmset -a hibernatemode 25

# Enable Gatekeeper
sudo spctl --master-enable

# Enable Firewall
defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# Enable Firewall Stealth Mode
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Disable signed apps from being auto-permitted to listen through firewall
sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -bool false

# Disable iCloud drive (Save to disk (not to iCloud) by default)
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Require an administrator password to access system-wide preferences
security authorizationdb read system.preferences > /tmp/system.preferences.plist
/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
sudo security authorizationdb write system.preferences < /tmp/system.preferences.plist
rm -f /tmp/system.preferences.plist

# Disable IPv6
networksetup -listallnetworkservices | while read i; do 
  SUPPORT=$(networksetup -getinfo "$i" | grep "IPv6: Automatic") 
  if [ -n "$SUPPORT" ]; then 
    sudo networksetup -setv6off "$i";
  fi
done

# Disable Previews
/usr/libexec/PlistBuddy -c "Add StandardViewOptions:ColumnViewOptions:ShowIconThumbnails bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:ListViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:IconViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:ExtendedListViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewOptions:ColumnViewOptions:ShowPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:ListViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:IconViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist";
/usr/libexec/PlistBuddy -c "Add StandardViewSettings:ExtendedListViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist";

# Secure Safari by crippling it
defaults write com.apple.Safari WebKitOmitPDFSupport -bool YES;
defaults write com.apple.Safari WebKitJavaScriptEnabled -bool FALSE;
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptEnabled -bool FALSE;

# Disable automatic loading of remote content by Mail.app
defaults write com.apple.mail-shared DisableURLLoading -bool true

# Verify no HTTP update URLs for Sparkle Updater
for i in /Applications/*/Contents/Info.plist; do
  URL=$(defaults read "$i" SUFeedURL 2>/dev/null | grep "http://");
  APP=$(echo $i | cut -d "/" -f 3);
  if [ -n "$URL" ]; then
    echo ''
    echo 'WARNING:'
    echo "$APP updates itself using HTTP!"
  fi
done

## Some additional stuff

# Disable Captive Portal
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

# Enable logging
sudo defaults write /Library/Preferences/com.apple.alf loggingenabled -bool true
