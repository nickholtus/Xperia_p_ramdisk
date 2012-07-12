#!/system/bin/sh
# *********************************************************************
# *  ____                      _____      _                           *
# * / ___|  ___  _ __  _   _  | ____|_ __(_) ___ ___ ___  ___  _ __   *
# * \___ \ / _ \| '_ \| | | | |  _| | '__| |/ __/ __/ __|/ _ \| '_ \  *
# *  ___) | (_) | | | | |_| | | |___| |  | | (__\__ \__ \ (_) | | | | *
# * |____/ \___/|_| |_|\__, | |_____|_|  |_|\___|___/___/\___/|_| |_| *
# *                    |___/                                          *
# *                                                                   *
# *********************************************************************
# * Copyright 2010 Sony Ericsson Mobile Communications AB.            *
# * All rights, including trade secret rights, reserved.              *
# *********************************************************************
#

TAG="usb"
USB_FUNC_TABLE="/system/etc/usbmode.table"
COMMENT="#"

comp()
{
  case $1 in
    $2)
      return 0
      ;;
  esac
  return 1
}

ADB_PROP=$(/system/bin/getprop persist.service.adb.enable)
ENG_PROP=$(/system/bin/getprop persist.usb.eng)
RNDIS_PROP=$(/system/bin/getprop usb.rndis.enable)
USERSTORAGE_PROP=$(/system/bin/getprop ro.semc.product.user_storage)
PCC_PROP=$(/system/bin/getprop usb.pcc.enable)

PROP="${ADB_PROP:-0}${ENG_PROP:-0}${RNDIS_PROP:-0}${PCC_PROP:-0}"
STORAGE_PROP="${USERSTORAGE_PROP:-emmc_only}"

while read LINE
do

  set -- $LINE

  if comp $1 $COMMENT ; then
    continue
  fi

  if ! comp $1 $STORAGE_PROP ; then
    continue
  fi

  if ! comp $2 $PROP ; then
    continue
  fi

  RNDIS=$3
  MODEM=$4
  MTP=$5
  MSC=$6
  ADB=$7
  USBSTATE=$8

  if ! comp $MSC "0" ; then
    echo "0" > /sys/class/usb_composite/usb_mass_storage/enable
    echo $MSC > /sys/class/usb_composite/usb_mass_storage/mode
  fi

  echo $RNDIS > /sys/class/usb_composite/rndis/enable
  echo $MODEM > /sys/class/usb_composite/acm/enable
  echo $MTP > /sys/class/usb_composite/mtp/enable
  echo $MSC > /sys/class/usb_composite/usb_mass_storage/enable
  echo $ADB > /sys/class/usb_composite/adb/enable
  echo "0" > /sys/class/usb_composite/accessory/enable

  /system/bin/log -t $TAG -p d "USB STATE: $USBSTATE"

  exit 0

done < $USB_FUNC_TABLE

/system/bin/log -t $TAG -p e "There is no matching USB mode:$PROP"

exit 1
