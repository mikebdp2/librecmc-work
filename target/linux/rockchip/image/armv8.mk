# 
# Copyright (C) 2020 Tobias Maedel
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Device/friendlyarm_nanopi-r2s
  DEVICE_TITLE := FriendlyARM NanoPi R2S
  SOC := rk3328
  UBOOT_DEVICE_NAME := nanopi-r2s-rk3328
  IMAGE/sysupgrade.img.gz := boot-common | boot-script nanopi-r2s | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-usb-net-rtl8152
endef

TARGET_DEVICES += friendlyarm_nanopi-r2s

define Device/thinkpenguin_tpe-r1400
  DEVICE_TITLE := ThinkPenguin TPE-R1400
  SOC := rk3328
  UBOOT_DEVICE_NAME := tpe-r1400-rk3328
  IMAGE/sysupgrade.img.gz := boot-common | boot-script tpe-r1400 | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-usb-net-rtl8152
endef

TARGET_DEVICES += thinkpenguin_tpe-r1400
