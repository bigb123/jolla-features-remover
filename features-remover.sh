#!/bin/bash
#
# Script to remove headphone high level volume warning and word prediction
# It also changes sd card mount rights (umask and fmask 0002) 
#
# It can remove auto capitalization feature (very useful during ownNote app usage).
# To do it give parameter to script.
# 
#

# Error codes:
ROOT_ERR=1
VOL_BACKUP_ERR=2
VOL_CHANGES_ERR=3
WORD_PREDICTION_BACKUP_ERR=4
WORD_PREDICTION_CHANGE_ERR=5
KEYBOARD_RESTART_ERR=6
MOUNT_BACKUP_ERR=7
MOUNT_CHANGE_ERR=8
INSTALL_ERR=10
KEYBOARD_CONFIG_BACKUP_ERR=11
KEYBOARD_CONFIG_CHANGE_ERR=12

OPT_ERR=254
UNKNOWN_ERR=255


# Global vars
unset VOL_WARNING_PATH &&       VOL_WARNING_PATH="/etc/pulse/mainvolume-listening-time-notifier.conf"
unset WORD_PREDICTION_PATH &&   WORD_PREDICTION_PATH="/usr/share/maliit/plugins/com/jolla/layouts/layouts.conf"
unset MOUNT_SD &&               MOUNT_SD="/usr/sbin/mount-sd.sh"
unset KEYBOARD_CONFIG_PATH &&   KEYBOARD_CONFIG_PATH="/usr/share/maliit/plugins/com/jolla/KeyboardBase.qml"

usage() {
  echo 
  echo "Script to:"
  echo "- remove headphone high level volume warning"
  echo "- remove word prediction buttons from keyboard"
  echo "- change SD card mount rights (umask and fmask 0002)"
  echo
  echo "It can also remove auto capitalization feature. To do it add '-r' parameter to script. It will remove only this feature"
  echo
  echo "Usage:"
  echo
  echo "  $0 [-rh]"
  echo
  echo "Where:"
  echo "  -r - remove auto capitalization keyboard feature"
  echo "  -h - show this help and exit"
  echo
}


backup() {
  local file_path="$1"
  local err_code="$2"
  
  cp "$file_path" "${file_path}.bak"
  if [ "0" == "$?" ]; then
    echo "Backup created for $file_path"
  else
    echo "Cannot create backup for $file_path"
    exit "$err_code"
  fi
}


patch_file() {
  local file_path="$1"
  local patch_name="$2"
  local err_code="$3"
  
  patch "$file_path" < "patches/${patch_name}"
  
  if [ "0" == "$?"  ]; then
    echo "Changes saved for $file_path"
  else
    echo "Cannot provide changes for $file_path"
    exit "$err_code"
  fi
}



remove_volume_warning() {

  backup "$VOL_WARNING_PATH" "$VOL_BACKUP_ERR"

  # change setting
  # sed -i s/mode-list\ =\ lineout,hs/mode-list\ =\/ "$VOL_WARNING_PATH"
  patch_file "$VOL_WARNING_PATH" "no_vol_warning.patch" "$VOL_CHANGES_ERR"
}


keyboard_restart() {
  systemctl --user restart maliit-server.service
  if [ "0" == "$?"  ]; then
    echo "Keyboard service restarted"
  else
    echo "Cannot restart keyboard service"
    exit "$KEYBOARD_RESTART_ERR"
  fi
}


remove_word_prediction() {
  
  backup  "$WORD_PREDICTION_PATH" "$WORD_PREDICTION_BACKUP_ERR"
  
  # find and replace
  # sed -i s/handler=Xt9InputHandler.qml/#\ handler=Xt9InputHandler.qml/g "$WORD_PREDICTION_PATH"
  patch_file "$WORD_PREDICTION_PATH" "no_word_prediction.patch" "$WORD_PREDICTION_CHANGE_ERR"
  
  keyboard_restart
}


change_mount_rules() {

  backup "$MOUNT_SD" "$MOUNT_BACKUP_ERR"

  # replace
  #sed -i s:'DEVNAME=$2':'DEVNAME=$2\n\n# trying to mount bind owncloud directory (on sd) to dir on sd\nunset MASK\nMASK="fmask=0002,dmask=0002"':g "$MOUNT_SD"
  #sed -i s:'mount ${DEVNAME} $MNT/${UUID} -o uid=$DEF_UID,gid=$DEF_GID,$MOUNT_OPTS,utf8,flush,discard || /bin/rmdir $MNT/${UUID}':'mount ${DEVNAME} $MNT/${UUID} -o uid=$DEF_UID,gid=$DEF_GID,$MOUNT_OPTS,utf8,flush,discard,$MASK || /bin/rmdir $MNT/${UUID}\n      mount --bind  $MNT/${UUID}/owncloud/ /home/nemo/android_storage/owncloud':g "$MOUNT_SD"
  patch_file "$MOUNT_SD" "sd_mount.patch" "$MOUNT_CHANGE_ERR"

}

remove_autocapitalization() {
  backup "$KEYBOARD_CONFIG_PATH" "$KEYBOARD_CONFIG_BACKUP_ERR"
  patch_file "$KEYBOARD_CONFIG_PATH" "no_auto_capitalization.patch" "$KEYBOARD_CONFIG_CHANGE_ERR"
  keyboard_restart
}


main() {

  while getopts ":rh" optname; do
    case "$optname" in
      "r")
        remove_autocapitalization
        exit 0
      ;;
      "h")
        usage
        exit 0
      ;;
      ":")
        echo "ERROR: No argument for option $OPTARG"
        usage
        exit "$OPT_ERR"
      ;;
      "?")
        echo "Unknown option"
        usage
        exit "$OPT_ERR"
      ;;
      "*")
        echo "Unknown error"
        exit "$UNKNOWN_ERR"
      ;;
    esac
  done


  remove_volume_warning
  remove_word_prediction
  change_mount_rules
}


# Check if prerequisites are fulfilled

if [ "root" != "$(whoami)" ]; then
  echo "You must run this script as root!"
  exit "$ROOT_ERR"
fi


# install 'patch' package - required to do the changes
pkcon install patch
if [ "0" != "$?" ]; then
  echo "Cannot install 'patch' package"
  exit "$INSTALL_ERR"
fi


## Run the script ##

main "$@"


echo "Restarting machine"
reboot
