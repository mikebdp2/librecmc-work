define Build/dongwon-header
	head -c 4 $@ > $@.tmp
	head -c 8 /dev/zero >> $@.tmp
	tail -c +9 $@ >> $@.tmp
	( \
		header_crc="$$(head -c 68 $@.tmp | gzip -c | \
			tail -c 8 | od -An -N4 -tx4 --endian little | tr -d ' \n')"; \
		printf "$$(echo $$header_crc | sed 's/../\\x&/g')" | \
			dd of=$@.tmp bs=4 count=1 seek=1 conv=notrunc \
	)
	mv $@.tmp $@
endef

# attention: only zlib compression is allowed for the boot fs
define Build/zyxel-buildkerneljffs
	mkdir -p $@.tmp/boot
	cp $@ $@.tmp/boot/vmlinux.lzma.uImage
	$(STAGING_DIR_HOST)/bin/mkfs.jffs2 \
		--big-endian --squash-uids -v -e 128KiB -q -f -n -x lzma -x rtime \
		-o $@ \
		-d $@.tmp
	rm -rf $@.tmp
endef

define Build/zyxel-factory
	let \
		maxsize="$(subst k,* 1024,$(RAS_ROOTFS_SIZE))"; \
		let size="$$(stat -c%s $@)"; \
		if [ $$size -lt $$maxsize ]; then \
			$(STAGING_DIR_HOST)/bin/mkrasimage \
				-b $(RAS_BOARD) \
				-v $(RAS_VERSION) \
				-r $@ \
				-s $$maxsize \
				-o $@.new \
				-l 131072 \
			&& mv $@.new $@ ; \
		fi
endef

define Device/8dev_rambutan
  SOC := qca9557
  DEVICE_VENDOR := 8devices
  DEVICE_MODEL := Rambutan
  DEVICE_PACKAGES := kmod-usb2
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  KERNEL_IN_UBI := 1
  IMAGES := factory.bin sysupgrade.tar
  IMAGE/sysupgrade.tar := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := append-ubi
endef
TARGET_DEVICES += 8dev_rambutan

define Device/aerohive_hiveap-121
  SOC := ar9344
  DEVICE_VENDOR := Aerohive
  DEVICE_MODEL := HiveAP 121
  DEVICE_PACKAGES := kmod-usb2
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 116m
  KERNEL_SIZE := 5120k
  UBINIZE_OPTS := -E 5
  SUPPORTED_DEVICES += hiveap-121
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(KERNEL_SIZE) | append-ubi | \
	check-size
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += aerohive_hiveap-121




define Device/glinet_gl-ar300m-common-nand
  SOC := qca9531
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := GL-AR300M
  DEVICE_PACKAGES := kmod-usb2
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 16000k
  PAGESIZE := 2048
  VID_HDR_OFFSET := 2048
endef

define Device/glinet_gl-ar300m-nand
  $(Device/glinet_gl-ar300m-common-nand)
  DEVICE_VARIANT := NAND
  BLOCKSIZE := 128k
  IMAGES += factory.img
  IMAGE/factory.img := append-kernel | pad-to $$$$(KERNEL_SIZE) | append-ubi
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  SUPPORTED_DEVICES += glinet,gl-ar300m-nor
endef
TARGET_DEVICES += glinet_gl-ar300m-nand

define Device/glinet_gl-ar300m-nor
  $(Device/glinet_gl-ar300m-common-nand)
  DEVICE_VARIANT := NOR
  SUPPORTED_DEVICES += glinet,gl-ar300m-nand gl-ar300m
endef
TARGET_DEVICES += glinet_gl-ar300m-nor




define Device/glinet_gl-xe300
  SOC := qca9531
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := GL-XE300
  DEVICE_PACKAGES := kmod-usb2 block-mount kmod-usb-serial-ch341
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 131072k
  PAGESIZE := 2048
  VID_HDR_OFFSET := 2048
  BLOCKSIZE := 128k
  IMAGES += factory.img
  IMAGE/factory.img := append-kernel | pad-to $$$$(KERNEL_SIZE) | append-ubi
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += glinet_gl-xe300

define Device/linksys_ea4500-v3
  SOC := qca9558
  DEVICE_VENDOR := Linksys
  DEVICE_MODEL := EA4500
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := kmod-usb2
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 81920k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  LINKSYS_HWNAME := EA4500V3
  IMAGES += factory.img
  IMAGE/factory.img := append-kernel | pad-to $$$$(KERNEL_SIZE) | \
	append-ubi | check-size | linksys-image type=$$$$(LINKSYS_HWNAME)
  UBINIZE_OPTS := -E 5
endef
TARGET_DEVICES += linksys_ea4500-v3

# fake rootfs is mandatory, pad-offset 129 equals (2 * uimage_header + 0xff)
define Device/netgear_ath79_nand
  DEVICE_VENDOR := NETGEAR
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  KERNEL_SIZE := 4096k
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 25600k
  KERNEL := kernel-bin | append-dtb | lzma -d20 | \
	pad-offset $$(KERNEL_SIZE) 129 | uImage lzma | \
	append-string -e '\xff' | \
	append-uImage-fakehdr filesystem $$(UIMAGE_MAGIC)
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma -d20 | uImage lzma
  IMAGES := sysupgrade.bin factory.img
  IMAGE/factory.img := append-kernel | append-ubi | netgear-dni | \
	check-size
  IMAGE/sysupgrade.bin := sysupgrade-tar | check-size | append-metadata
  UBINIZE_OPTS := -E 5
endef


define Device/netgear_wndr3700-v4
  SOC := ar9344
  DEVICE_MODEL := WNDR3700
  DEVICE_VARIANT := v4
  UIMAGE_MAGIC := 0x33373033
  NETGEAR_BOARD_ID := WNDR3700v4
  NETGEAR_HW_ID := 29763948+128+128
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr3700-v4

define Device/netgear_wndr4300
  SOC := ar9344
  DEVICE_MODEL := WNDR4300
  UIMAGE_MAGIC := 0x33373033
  NETGEAR_BOARD_ID := WNDR4300
  NETGEAR_HW_ID := 29763948+0+128+128+2x2+3x3
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr4300

define Device/netgear_wndr4300sw
  SOC := ar9344
  DEVICE_MODEL := WNDR4300SW
  UIMAGE_MAGIC := 0x33373033
  NETGEAR_BOARD_ID := WNDR4300SW
  NETGEAR_HW_ID := 29763948+0+128+128+2x2+3x3
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr4300sw

define Device/netgear_wndr4300tn
  SOC := ar9344
  DEVICE_MODEL := WNDR4300TN
  UIMAGE_MAGIC := 0x33373033
  NETGEAR_BOARD_ID := WNDR4300TN
  NETGEAR_HW_ID := 29763948+0+128+128+2x2+3x3
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr4300tn

define Device/netgear_wndr4300-v2
  SOC := qca9563
  DEVICE_MODEL := WNDR4300
  DEVICE_VARIANT := v2
  UIMAGE_MAGIC := 0x27051956
  NETGEAR_BOARD_ID := WNDR4500series
  NETGEAR_HW_ID := 29764821+2+128+128+3x3+3x3+5508012175
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr4300-v2

define Device/netgear_wndr4500-v3
  SOC := qca9563
  DEVICE_MODEL := WNDR4500
  DEVICE_VARIANT := v3
  UIMAGE_MAGIC := 0x27051956
  NETGEAR_BOARD_ID := WNDR4500series
  NETGEAR_HW_ID := 29764821+2+128+128+3x3+3x3+5508012173
  $(Device/netgear_ath79_nand)
endef
TARGET_DEVICES += netgear_wndr4500-v3






