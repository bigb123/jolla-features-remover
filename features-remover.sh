#!/bin/bash
#
# Script to remove headphone high level warning and word prediction
#
#

if [ "root" != "$(whoami)" ]; then
	echo "You must run this script as root!"
	exit 1
fi

###
#
# Remove volume warning
#
###

# create backup
vol_warning_path="/etc/pulse/mainvolume-listening-time-notifier.conf"
cp "$vol_warning_path" "${vol_warning_path}.bak"
if [ "0" == "$?" ]; then
	echo "Backup created for $vol_warning_path"
else
	echo "Cannot create backup for $vol_warning_path"
	exit 2
fi

# change setting
sed -i s/mode-list\ =\ lineout,hs/mode-list\ =\ lineout/ "$vol_warning_path"
if [ "0" == "$?"  ]; then
	echo "Changes saved for $vol_warning_path"
else
	echo "Cannot provide changes for $vol_warning_path"
	exit 3
fi

###
#
# Remove word prediction
#
###

# backup 
word_prediction="/usr/share/maliit/plugins/com/jolla/layouts/layouts.conf"
cp "$word_prediction" "${word_prediction}.bak"
if [ "0" == "$?" ]; then
  echo "Backup created for $word_prediction"
else
  echo "Cannot create backup for $word_prediction"
  exit 4
fi

# find and replace
sed -i s/handler=Xt9InputHandler.qml/#\ handler=Xt9InputHandler.qml/g "$word_prediction"
if [ "0" == "$?"  ]; then
  echo "Changes saved for $word_prediction"
else
  echo "Cannot provide changes for $word_prediction"
  exit 5
fi

# keyboard service restart
systemctl --user restart maliit-server.service
if [ "0" == "$?"  ]; then
  echo "Keyboard service restarted"
else
  echo "Cannot restart keyboard service"
  exit 6
fi
