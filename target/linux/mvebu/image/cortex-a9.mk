#
# Copyright (C) 2012-2016 OpenWrt.org
# Copyright (C) 2016 LEDE-project.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

ifeq ($(SUBTARGET),cortexa9)

define Device/linksys
  $(Device/NAND-128K)
  DEVICE_TITLE := Linksys $(1)
  DEVICE_PACKAGES := swconfig wpad-basic
  IMAGES += factory.img
  KERNEL_SIZE := 6144k
endef

define Device/linksys_wrt1900ac
  $(call Device/linksys,WRT1900AC (Mamba))
  DEVICE_DTS := armada-xp-linksys-mamba
  DEVICE_PACKAGES := kmod-ath9k
  KERNEL_SIZE := 3072k
  SUPPORTED_DEVICES := armada-xp-linksys-mamba linksys,mamba
endef
TARGET_DEVICES += linksys_wrt1900ac

define Device/cznic_turris-omnia
  KERNEL_INSTALL := 1
  KERNEL := kernel-bin
  KERNEL_INITRAMFS := kernel-bin
  DEVICE_TITLE := Turris Omnia
  DEVICE_PACKAGES :=  \
    mkf2fs e2fsprogs kmod-fs-vfat kmod-nls-cp437 kmod-nls-iso8859-1 \
    wpad-basic kmod-ath9k partx-utils kmod-i2c-core kmod-i2c-mux \
    kmod-i2c-mux-pca954x
  IMAGES := $$(IMAGE_PREFIX)-sysupgrade.img.gz omnia-medkit-$$(IMAGE_PREFIX)-initramfs.tar.gz
  IMAGE/$$(IMAGE_PREFIX)-sysupgrade.img.gz := boot-img | sdcard-img | gzip | append-metadata
  IMAGE/omnia-medkit-$$(IMAGE_PREFIX)-initramfs.tar.gz := omnia-medkit-initramfs | gzip
  IMAGE_NAME = $$(2)
  DEVICE_DTS := armada-385-turris-omnia
  SUPPORTED_DEVICES += armada-385-turris-omnia
endef
TARGET_DEVICES += cznic_turris-omnia

endif
