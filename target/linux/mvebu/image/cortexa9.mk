# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2012-2016 OpenWrt.org
# Copyright (C) 2016 LEDE-project.org

define Build/fortigate-header
  ( \
    dd if=/dev/zero bs=384 count=1 2>/dev/null; \
    datalen=$$(wc -c $@ | cut -d' ' -f1); \
    datalen=$$(printf "%08x" $$datalen); \
    datalen="$${datalen:6:2}$${datalen:4:2}$${datalen:2:2}$${datalen:0:2}"; \
    printf $$(echo "00020000$${datalen}ffff0000ffff0000" | sed 's/../\\x&/g'); \
    dd if=/dev/zero bs=112 count=1 2>/dev/null; \
    cat $@; \
  ) > $@.new
  mv $@.new $@
endef

define Device/dsa-migration
  DEVICE_COMPAT_VERSION := 1.1
  DEVICE_COMPAT_MESSAGE := Config cannot be migrated from swconfig to DSA
endef

define Device/kernel-size-migration
  DEVICE_COMPAT_VERSION := 2.0
  DEVICE_COMPAT_MESSAGE := Partition design has changed compared to older versions (up to 19.07) due to kernel size restrictions. \
	Upgrade via sysupgrade mechanism is not possible, so new installation via factory style image is required.
endef

define Device/buffalo_ls220de
  $(Device/NAND-128K)
  DEVICE_VENDOR := Buffalo
  DEVICE_MODEL := LinkStation LS220DE
  KERNEL_UBIFS_OPTS = -m $$(PAGESIZE) -e 124KiB -c 172 -x none
  KERNEL := kernel-bin | append-dtb | uImage none | buffalo-kernel-ubifs
  KERNEL_INITRAMFS := kernel-bin | append-dtb | uImage none
  DEVICE_DTS := armada-370-buffalo-ls220de
  DEVICE_PACKAGES :=  \
    kmod-hwmon-gpiofan kmod-hwmon-drivetemp kmod-linkstation-poweroff \
    kmod-md-mod kmod-md-raid0 kmod-md-raid1 kmod-md-raid10 kmod-fs-xfs \
    mdadm mkf2fs e2fsprogs partx-utils
endef
TARGET_DEVICES += buffalo_ls220de

define Device/buffalo_ls421de
  $(Device/NAND-128K)
  DEVICE_VENDOR := Buffalo
  DEVICE_MODEL := LinkStation LS421DE
  SUBPAGESIZE :=
  KERNEL_SIZE := 33554432
  FILESYSTEMS := squashfs ubifs
  KERNEL := kernel-bin | append-dtb | uImage none | buffalo-kernel-jffs2
  KERNEL_INITRAMFS := kernel-bin | append-dtb | uImage none
  DEVICE_DTS := armada-370-buffalo-ls421de
  DEVICE_PACKAGES :=  \
    kmod-rtc-rs5c372a kmod-hwmon-gpiofan kmod-hwmon-drivetemp kmod-usb3 \
    kmod-linkstation-poweroff kmod-md-raid0 kmod-md-raid1 kmod-md-mod \
    kmod-fs-xfs mkf2fs e2fsprogs partx-utils
endef
TARGET_DEVICES += buffalo_ls421de

define Device/ctera_c200-v2
  PAGESIZE := 2048
  SUBPAGESIZE := 512
  BLOCKSIZE := 128k
  DEVICE_VENDOR := Ctera
  DEVICE_MODEL := C200
  DEVICE_VARIANT := V2
  SOC := armada-370
  KERNEL := kernel-bin | append-dtb | uImage none | ctera-firmware
  KERNEL_IN_UBI :=
  KERNEL_SUFFIX := -factory.firm
  DEVICE_PACKAGES :=  \
    kmod-gpio-button-hotplug kmod-hwmon-drivetemp kmod-hwmon-nct7802 \
    kmod-rtc-s35390a kmod-usb3 kmod-usb-ledtrig-usbport
  IMAGES := sysupgrade.bin
endef
TARGET_DEVICES += ctera_c200-v2

define Device/cznic_turris-omnia
  DEVICE_VENDOR := CZ.NIC
  DEVICE_MODEL := Turris Omnia
  KERNEL_INSTALL := 1
  SOC := armada-385
  KERNEL := kernel-bin
  KERNEL_INITRAMFS := kernel-bin | gzip | fit gzip $$(KDIR)/image-$$(DEVICE_DTS).dtb
  DEVICE_PACKAGES :=  \
    mkf2fs e2fsprogs kmod-fs-vfat kmod-nls-cp437 kmod-nls-iso8859-1 \
    wpad-basic-wolfssl kmod-ath9k partx-utils kmod-i2c-mux-pca954x \
    kmod-leds-turris-omnia
  IMAGES := $$(DEVICE_IMG_PREFIX)-sysupgrade.img.gz omnia-medkit-$$(DEVICE_IMG_PREFIX)-initramfs.tar.gz
  IMAGE/$$(DEVICE_IMG_PREFIX)-sysupgrade.img.gz := boot-scr | boot-img | sdcard-img | gzip | append-metadata
  IMAGE/omnia-medkit-$$(DEVICE_IMG_PREFIX)-initramfs.tar.gz := omnia-medkit-initramfs | gzip
  DEVICE_IMG_NAME = $$(2)
  SUPPORTED_DEVICES += armada-385-turris-omnia
  BOOT_SCRIPT := turris-omnia
endef
TARGET_DEVICES += cznic_turris-omnia

define Device/iptime_nas1dual
  DEVICE_VENDOR := ipTIME
  DEVICE_MODEL := NAS1dual
  DEVICE_PACKAGES := kmod-hwmon-drivetemp kmod-hwmon-gpiofan kmod-usb3
  SOC := armada-385
  KERNEL := kernel-bin | append-dtb | iptime-naspkg nas1dual
  KERNEL_SIZE := 6144k
  IMAGES := sysupgrade.bin
  IMAGE_SIZE := 64256k
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | \
	append-rootfs | pad-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += iptime_nas1dual

define Device/kobol_helios4
  DEVICE_VENDOR := Kobol
  DEVICE_MODEL := Helios4
  KERNEL_INSTALL := 1
  KERNEL := kernel-bin
  DEVICE_PACKAGES := mkf2fs e2fsprogs partx-utils
  IMAGES := sdcard.img.gz
  IMAGE/sdcard.img.gz := boot-scr | boot-img-ext4 | sdcard-img-ext4 | gzip | append-metadata
  SOC := armada-388
  UBOOT := helios4-u-boot-with-spl.kwb
  BOOT_SCRIPT := clearfog
endef
TARGET_DEVICES += kobol_helios4

define Device/linksys
  $(Device/NAND-128K)
  DEVICE_VENDOR := Linksys
  DEVICE_PACKAGES := kmod-mwlwifi wpad-basic-wolfssl
  IMAGES += factory.img
  IMAGE/factory.img := append-kernel | pad-to $$$$(KERNEL_SIZE) | \
	append-ubi | pad-to $$$$(PAGESIZE)
  KERNEL_SIZE := 6144k
endef

define Device/linksys_wrt1200ac
  $(call Device/linksys)
  $(Device/dsa-migration)
  DEVICE_MODEL := WRT1200AC
  DEVICE_ALT0_VENDOR := Linksys
  DEVICE_ALT0_MODEL := Caiman
  DEVICE_DTS := armada-385-linksys-caiman
  DEVICE_PACKAGES += mwlwifi-firmware-88w8864
  SUPPORTED_DEVICES += armada-385-linksys-caiman linksys,caiman
endef
TARGET_DEVICES += linksys_wrt1200ac

define Device/linksys_wrt1900ac-v1
  $(call Device/linksys)
  $(Device/kernel-size-migration)
  DEVICE_MODEL := WRT1900AC
  DEVICE_VARIANT := v1
  DEVICE_ALT0_VENDOR := Linksys
  DEVICE_ALT0_MODEL := Mamba
  DEVICE_DTS := armada-xp-linksys-mamba
  KERNEL_SIZE := 4096k
  SUPPORTED_DEVICES += armada-xp-linksys-mamba linksys,mamba
endef
TARGET_DEVICES += linksys_wrt1900ac-v1
