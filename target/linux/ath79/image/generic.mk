include ./common-buffalo.mk
include ./common-netgear.mk
include ./common-senao.mk
include ./common-tp-link.mk
include ./common-yuncore.mk
include ./common-ubnt.mk

DEVICE_VARS += ADDPATTERN_ID ADDPATTERN_VERSION
DEVICE_VARS += SEAMA_SIGNATURE SEAMA_MTDBLOCK
DEVICE_VARS += KERNEL_INITRAMFS_PREFIX DAP_SIGNATURE
DEVICE_VARS += EDIMAX_HEADER_MAGIC EDIMAX_HEADER_MODEL
DEVICE_VARS += OPENMESH_CE_TYPE ZYXEL_MODEL_STRING
DEVICE_VARS += SUPPORTED_TELTONIKA_DEVICES

define Build/addpattern
	-$(STAGING_DIR_HOST)/bin/addpattern -B $(ADDPATTERN_ID) \
		-v v$(ADDPATTERN_VERSION) -i $@ -o $@.new
	-mv "$@.new" "$@"
endef

define Build/append-md5sum-bin
	$(MKHASH) md5 $@ | sed 's/../\\\\x&/g' |\
		xargs echo -ne >> $@
endef

define Build/cybertan-trx
	@echo -n '' > $@-empty.bin
	-$(STAGING_DIR_HOST)/bin/trx -o $@.new \
		-f $(IMAGE_KERNEL) -F $@-empty.bin \
		-x 32 -a 0x10000 -x -32 -f $@
	-mv "$@.new" "$@"
	-rm $@-empty.bin
endef

define Build/edimax-headers
	$(eval edimax_magic=$(word 1,$(1)))
	$(eval edimax_model=$(word 2,$(1)))

	$(STAGING_DIR_HOST)/bin/edimax_fw_header -M $(edimax_magic) -m $(edimax_model)\
		-v $(VERSION_DIST)$(firstword $(subst +, , $(firstword $(subst -, ,$(REVISION))))) \
		-n "uImage" \
		-i $(KDIR)/loader-$(DEVICE_NAME).uImage \
		-o $@.uImage
	$(STAGING_DIR_HOST)/bin/edimax_fw_header -M $(edimax_magic) -m $(edimax_model)\
		-v $(VERSION_DIST)$(firstword $(subst +, , $(firstword $(subst -, ,$(REVISION))))) \
		-n "rootfs" \
		-i $@ \
		-o $@.rootfs
	cat $@.uImage $@.rootfs > $@
	rm -rf $@.uImage $@.rootfs
endef

define Build/mkdapimg2
	$(STAGING_DIR_HOST)/bin/mkdapimg2 \
		-i $@ -o $@.new \
		-s $(DAP_SIGNATURE) \
		-v $(VERSION_DIST)-$(firstword $(subst +, , \
			$(firstword $(subst -, ,$(REVISION))))) \
		-r Default \
		$(if $(1),-k $(1))
	mv $@.new $@
endef

define Build/mkmylofw_16m
	$(eval device_id=$(word 1,$(1)))
	$(eval revision=$(word 2,$(1)))

	# On WPJ344, WPJ531, and WPJ563, the default boot command tries 0x9f680000
	# first and fails if the remains of the stock image are sill there
	# - resulting in an infinite boot loop.
	# The size parameter is grown to have that block deleted if the firmware
	# isn't big enough by itself.

	let \
		size="$$(stat -c%s $@)" \
		pad="$(subst k,* 1024,$(BLOCKSIZE))" \
		pad="(pad - (size % pad)) % pad" \
		newsize='size + pad' ; \
		[ $$newsize -lt $$((0x660000)) ] && newsize=0x660000 ; \
		$(STAGING_DIR_HOST)/bin/mkmylofw \
			-B WPE72 -i 0x11f6:$(device_id):0x11f6:$(device_id) -r $(revision) \
			-s 0x1000000 -p0x30000:$$newsize:al:0x80060000:"OpenWRT":$@ \
			$@.new
		@mv $@.new $@
endef

define Build/mkwrggimg
	$(STAGING_DIR_HOST)/bin/mkwrggimg -b \
		-i $@ -o $@.imghdr -d /dev/mtdblock/1 \
		-m $(DEVICE_MODEL)-$(DEVICE_VARIANT) -s $(DAP_SIGNATURE) \
		-v $(VERSION_DIST) -B $(REVISION)
	mv $@.imghdr $@
endef

define Build/nec-enc
  $(STAGING_DIR_HOST)/bin/nec-enc \
    -i $@ -o $@.new -k $(1)
  mv $@.new $@
endef

define Build/nec-fw
  ( stat -c%s $@ | tr -d "\n" | dd bs=16 count=1 conv=sync; ) >> $@
  ( \
    echo -n -e "$(1)" | dd bs=16 count=1 conv=sync; \
    echo -n "0.0.00" | dd bs=16 count=1 conv=sync; \
    dd if=$@; \
  ) > $@.new
  mv $@.new $@
endef

define Build/pisen_wmb001n-factory
  -[ -f "$@" ] && \
  mkdir -p "$@.tmp" && \
  cp "$(KDIR)/loader-$(word 1,$(1)).uImage" "$@.tmp/uImage" && \
  mv "$@" "$@.tmp/rootfs" && \
  cp "bin/pisen_wmb001n_factory-header.bin" "$@" && \
  $(TAR) -cp --numeric-owner --owner=0 --group=0 --mode=a-s --sort=name \
    $(if $(SOURCE_DATE_EPOCH),--mtime="@$(SOURCE_DATE_EPOCH)") \
    -C "$@.tmp" . | gzip -9n >> "$@" && \
  rm -rf "$@.tmp"
endef

define Build/teltonika-fw-fake-checksum
	# Teltonika U-Boot web based firmware upgrade/recovery routine compares
	# 16 bytes from md5sum1[16] field in TP-Link v1 header (offset: 76 bytes
	# from begin of the firmware file) with 16 bytes stored just before
	# 0xdeadc0de marker. Values are only compared, MD5 sum is not verified.
	let \
		offs="$$(stat -c%s $@) - $(1)"; \
		dd if=$@ bs=1 count=16 skip=76 |\
		dd of=$@ bs=1 count=16 seek=$$offs conv=notrunc
endef

define Build/teltonika-v1-header
	$(STAGING_DIR_HOST)/bin/mktplinkfw \
		-c -H $(TPLINK_HWID) -W $(TPLINK_HWREV) -L $(KERNEL_LOADADDR) \
		-E $(if $(KERNEL_ENTRY),$(KERNEL_ENTRY),$(KERNEL_LOADADDR)) \
		-m $(TPLINK_HEADER_VERSION) -N "$(VERSION_DIST)" -V "RUT2xx      " \
		-k $@ -o $@.new $(1)
	@mv $@.new $@
endef

metadata_json_teltonika = \
	'{ $(if $(IMAGE_METADATA),$(IMAGE_METADATA)$(comma)) \
		"metadata_version": "1.1", \
		"compat_version": "$(call json_quote,$(compat_version))", \
		"version":"$(call json_quote,$(VERSION_DIST))-$(call json_quote,$(VERSION_NUMBER))-$(call json_quote,$(REVISION))", \
		"device_code": [".*"], \
		"hwver": [".*"], \
		"batch": [".*"], \
		"serial": [".*"], \
		$(if $(DEVICE_COMPAT_MESSAGE),"compat_message": "$(call json_quote,$(DEVICE_COMPAT_MESSAGE))"$(comma)) \
		$(if $(filter-out 1.0,$(compat_version)),"new_supported_devices": \
			[$(call metadata_devices,$(SUPPORTED_TELTONIKA_DEVICES))]$(comma) \
			"supported_devices": ["$(call json_quote,$(legacy_supported_message))"]$(comma)) \
		$(if $(filter 1.0,$(compat_version)),"supported_devices":[$(call metadata_devices,$(SUPPORTED_TELTONIKA_DEVICES))]$(comma)) \
		"version_wrt": { \
			"dist": "$(call json_quote,$(VERSION_DIST))", \
			"version": "$(call json_quote,$(VERSION_NUMBER))", \
			"revision": "$(call json_quote,$(REVISION))", \
			"target": "$(call json_quote,$(TARGETID))", \
			"board": "$(call json_quote,$(if $(BOARD_NAME),$(BOARD_NAME),$(DEVICE_NAME)))" \
		}, \
		"hw_support": {}, \
		"hw_mods": {} \
	}'

define Build/append-metadata-teltonika
	echo $(call metadata_json_teltonika) | fwtool -I - $@
endef

define Build/wrgg-pad-rootfs
	$(STAGING_DIR_HOST)/bin/padjffs2 $(IMAGE_ROOTFS) -c 64 >>$@
endef

define Build/zyxel-tar-bz2
	mkdir -p $@.tmp
	mv $@ $@.tmp/$(word 2,$(1))
	cp $(KDIR)/loader-$(DEVICE_NAME).uImage $@.tmp/$(word 1,$(1)).lzma.uImage
	$(TAR) -cjf $@ -C $@.tmp .
	rm -rf $@.tmp
endef

define Device/seama
  KERNEL := kernel-bin | append-dtb | relocate-kernel | lzma
  KERNEL_INITRAMFS := $$(KERNEL) | seama
  IMAGES += factory.bin
  SEAMA_MTDBLOCK := 1

  # 64 bytes offset:
  # - 28 bytes seama_header
  # - 36 bytes of META data (4-bytes aligned)
  IMAGE/default := append-kernel | pad-offset $$$$(BLOCKSIZE) 64 | append-rootfs
  IMAGE/sysupgrade.bin := $$(IMAGE/default) | seama | pad-rootfs | \
	check-size | append-metadata
  IMAGE/factory.bin := $$(IMAGE/default) | pad-rootfs -x 64 | seama | \
	seama-seal | check-size
  SEAMA_SIGNATURE :=
endef


define Device/8dev_carambola2
  SOC := ar9331
  DEVICE_VENDOR := 8devices
  DEVICE_MODEL := Carambola2
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += carambola2
endef
TARGET_DEVICES += 8dev_carambola2

define Device/8dev_lima
  SOC := qca9531
  DEVICE_VENDOR := 8devices
  DEVICE_MODEL := Lima
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 15616k
  SUPPORTED_DEVICES += lima
endef
TARGET_DEVICES += 8dev_lima

define Device/adtran_bsap1880
  SOC := ar7161
  DEVICE_VENDOR := Adtran/Bluesocket
  DEVICE_PACKAGES += -swconfig -uboot-envtools fconfig
  KERNEL := kernel-bin | append-dtb | lzma | pad-to $$(BLOCKSIZE)
  KERNEL_INITRAMFS := kernel-bin | append-dtb
  IMAGE_SIZE := 11200k
  IMAGES += kernel.bin rootfs.bin
  IMAGE/kernel.bin := append-kernel
  IMAGE/rootfs.bin := append-rootfs | pad-rootfs | pad-to $$(BLOCKSIZE)
  IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | \
	check-size | sysupgrade-tar rootfs=$$$$@ | append-metadata
endef

define Device/adtran_bsap1800-v2
  $(Device/adtran_bsap1880)
  DEVICE_MODEL := BSAP-1800
  DEVICE_VARIANT := v2
endef
TARGET_DEVICES += adtran_bsap1800-v2

define Device/adtran_bsap1840
  $(Device/adtran_bsap1880)
  DEVICE_MODEL := BSAP-1840
endef
TARGET_DEVICES += adtran_bsap1840

define Device/alcatel_hh40v
  SOC := qca9531
  DEVICE_VENDOR := Alcatel
  DEVICE_MODEL := HH40V
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-serial-option kmod-usb-net-rndis
  IMAGE_SIZE := 14976k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs
endef
TARGET_DEVICES += alcatel_hh40v


define Device/alfa-network_ap121f
  SOC := ar9331
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := AP121F
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-storage -swconfig
  IMAGE_SIZE := 16064k
  SUPPORTED_DEVICES += ap121f
endef
TARGET_DEVICES += alfa-network_ap121f

define Device/alfa-network_ap121fe
  SOC := ar9331
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := AP121FE
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-gadget-eth -swconfig
  IMAGE_SIZE := 16064k
endef
TARGET_DEVICES += alfa-network_ap121fe

define Device/alfa-network_n2q
  SOC := qca9531
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := N2Q
  DEVICE_PACKAGES := kmod-i2c-gpio kmod-gpio-pcf857x kmod-usb2 \
	kmod-usb-ledtrig-usbport rssileds
  IMAGE_SIZE := 15872k
endef
TARGET_DEVICES += alfa-network_n2q

define Device/alfa-network_n5q
  SOC := ar9344
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := N5Q
  DEVICE_PACKAGES := rssileds
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += n5q
endef
TARGET_DEVICES += alfa-network_n5q

define Device/alfa-network_pi-wifi4
  SOC := qca9531
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := Pi-WiFi4
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport -swconfig
  IMAGE_SIZE := 15872k
endef
TARGET_DEVICES += alfa-network_pi-wifi4

define Device/alfa-network_r36a
  SOC := qca9531
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := R36A
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += r36a
endef
TARGET_DEVICES += alfa-network_r36a

define Device/alfa-network_tube-2hq
  SOC := qca9531
  DEVICE_VENDOR := ALFA Network
  DEVICE_MODEL := Tube-2HQ
  DEVICE_PACKAGES := rssileds -swconfig
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += tube-2hq
endef
TARGET_DEVICES += alfa-network_tube-2hq


define Device/araknis_an-300-ap-i-n
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := Araknis
  DEVICE_MODEL := AN-300-AP-I-N
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-an300
endef
TARGET_DEVICES += araknis_an-300-ap-i-n



define Device/arduino_yun
  SOC := ar9331
  DEVICE_VENDOR := Arduino
  DEVICE_MODEL := Yun
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-ledtrig-usbport \
	kmod-usb-storage block-mount -swconfig
  IMAGE_SIZE := 15936k
  SUPPORTED_DEVICES += arduino-yun
endef
TARGET_DEVICES += arduino_yun

define Device/aruba_ap-105
  SOC := ar7161
  DEVICE_VENDOR := Aruba
  DEVICE_MODEL := AP-105
  IMAGE_SIZE := 16000k
  DEVICE_PACKAGES := kmod-i2c-gpio kmod-tpm-i2c-atmel
  LOADER_TYPE := bin
  LOADER_FLASH_OFFS := 0x42000
  COMPILE := loader-$(1).bin
  COMPILE/loader-$(1).bin := loader-okli-compile
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49 | loader-okli $(1) 8128 | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
endef
TARGET_DEVICES += aruba_ap-105

define Device/aruba_ap-115
  SOC := qca9558
  DEVICE_VENDOR := Aruba
  DEVICE_MODEL := AP-115
  IMAGE_SIZE := 16000k
  DEVICE_PACKAGES := kmod-usb2
  LOADER_TYPE := bin
  LOADER_FLASH_OFFS := 0x102000
  COMPILE := loader-$(1).bin
  COMPILE/loader-$(1).bin := loader-okli-compile
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49 | loader-okli $(1) 8128 | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | loader-kernel
endef
TARGET_DEVICES += aruba_ap-115

define Device/aruba_ap-175
  SOC := ar7161
  DEVICE_VENDOR := Aruba
  DEVICE_MODEL := AP-175
  IMAGE_SIZE := 16000k
  DEVICE_PACKAGES := kmod-gpio-pca953x kmod-hwmon-lm75 kmod-i2c-gpio kmod-rtc-ds1374
  LOADER_TYPE := bin
  LOADER_FLASH_OFFS := 0x42000
  COMPILE := loader-$(1).bin
  COMPILE/loader-$(1).bin := loader-okli-compile
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49 | loader-okli $(1) 8128 | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
endef
TARGET_DEVICES += aruba_ap-175




define Device/atheros_db120
  $(Device/loader-okli-uimage)
  SOC := ar9344
  DEVICE_VENDOR := Atheros
  DEVICE_MODEL := DB120
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 7808k
  SUPPORTED_DEVICES += db120
  LOADER_FLASH_OFFS := 0x50000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | pad-to 6336k | \
	append-loader-okli-uimage $(1) | pad-to 64k
endef
TARGET_DEVICES += atheros_db120

define Device/avm
  DEVICE_VENDOR := AVM
  KERNEL := kernel-bin | append-dtb | lzma | eva-image
  KERNEL_INITRAMFS := $$(KERNEL)
  IMAGE/sysupgrade.bin := append-kernel | pad-to 64k | \
	append-squashfs-fakeroot-be | pad-to 256 | append-rootfs | pad-rootfs | \
	check-size | append-metadata
  DEVICE_PACKAGES := fritz-tffs
endef

define Device/avm_fritz300e
  $(Device/avm)
  SOC := ar7242
  IMAGE_SIZE := 15232k
  DEVICE_MODEL := FRITZ!WLAN Repeater 300E
  DEVICE_PACKAGES += rssileds -swconfig
  SUPPORTED_DEVICES += fritz300e
endef
TARGET_DEVICES += avm_fritz300e

define Device/avm_fritz4020
  $(Device/avm)
  SOC := qca9561
  IMAGE_SIZE := 15232k
  DEVICE_MODEL := FRITZ!Box 4020
  SUPPORTED_DEVICES += fritz4020
endef
TARGET_DEVICES += avm_fritz4020

define Device/avm_fritz450e
  $(Device/avm)
  SOC := qca9556
  IMAGE_SIZE := 15232k
  DEVICE_MODEL := FRITZ!WLAN Repeater 450E
  SUPPORTED_DEVICES += fritz450e
endef
TARGET_DEVICES += avm_fritz450e

define Device/buffalo_bhr-4grv
  $(Device/buffalo_common)
  SOC := ar7242
  DEVICE_MODEL := BHR-4GRV
  BUFFALO_PRODUCT := BHR-4GRV
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  IMAGE_SIZE := 32256k
  SUPPORTED_DEVICES += wzr-hp-g450h
endef
TARGET_DEVICES += buffalo_bhr-4grv

define Device/buffalo_bhr-4grv2
  SOC := qca9557
  DEVICE_VENDOR := Buffalo
  DEVICE_MODEL := BHR-4GRV2
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += buffalo_bhr-4grv2

define Device/buffalo_wzr_ar7161
  $(Device/buffalo_common)
  SOC := ar7161
  BUFFALO_PRODUCT := WZR-HP-AG300H
  DEVICE_PACKAGES := kmod-usb-ohci kmod-usb2 kmod-usb-ledtrig-usbport \
	kmod-leds-reset kmod-owl-loader
  IMAGE_SIZE := 32320k
  SUPPORTED_DEVICES += wzr-hp-ag300h
endef

define Device/buffalo_wzr-600dhp
  $(Device/buffalo_wzr_ar7161)
  DEVICE_MODEL := WZR-600DHP
endef
TARGET_DEVICES += buffalo_wzr-600dhp

define Device/buffalo_wzr-hp-ag300h
  $(Device/buffalo_wzr_ar7161)
  DEVICE_MODEL := WZR-HP-AG300H
endef
TARGET_DEVICES += buffalo_wzr-hp-ag300h

define Device/buffalo_wzr-hp-g300nh
  $(Device/buffalo_common)
  SOC := ar9132
  BUFFALO_PRODUCT := WZR-HP-G300NH
  BUFFALO_HWVER := 1
  DEVICE_PACKAGES := kmod-gpio-cascade kmod-mux-gpio kmod-usb2 kmod-usb-ledtrig-usbport
  BLOCKSIZE := 128k
  IMAGE_SIZE := 32128k
  SUPPORTED_DEVICES += wzr-hp-g300nh
endef

define Device/buffalo_wzr-hp-g300nh-rb
  $(Device/buffalo_wzr-hp-g300nh)
  DEVICE_MODEL := WZR-HP-G300NH (RTL8366RB switch)
  DEVICE_PACKAGES += kmod-switch-rtl8366rb
endef
TARGET_DEVICES += buffalo_wzr-hp-g300nh-rb

define Device/buffalo_wzr-hp-g300nh-s
  $(Device/buffalo_wzr-hp-g300nh)
  DEVICE_MODEL := WZR-HP-G300NH (RTL8366S switch)
  DEVICE_PACKAGES += kmod-switch-rtl8366s
endef
TARGET_DEVICES += buffalo_wzr-hp-g300nh-s

define Device/buffalo_wzr-hp-g302h-a1a0
  $(Device/buffalo_common)
  SOC := ar7242
  DEVICE_MODEL := WZR-HP-G302H
  DEVICE_VARIANT := A1A0
  BUFFALO_PRODUCT := WZR-HP-G302H
  BUFFALO_HWVER := 4
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  IMAGE_SIZE := 32128k
  SUPPORTED_DEVICES += wzr-hp-g300nh2
endef
TARGET_DEVICES += buffalo_wzr-hp-g302h-a1a0

define Device/buffalo_wzr-hp-g450h
  $(Device/buffalo_common)
  SOC := ar7242
  DEVICE_MODEL := WZR-HP-G450H/WZR-450HP
  BUFFALO_PRODUCT := WZR-HP-G450H
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  IMAGE_SIZE := 32256k
  SUPPORTED_DEVICES += wzr-hp-g450h
endef
TARGET_DEVICES += buffalo_wzr-hp-g450h

define Device/comfast_cf-e110n-v2
  SOC := qca9533
  DEVICE_VENDOR := COMFAST
  DEVICE_MODEL := CF-E110N
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds -swconfig -uboot-envtools
  IMAGE_SIZE := 16192k
endef
TARGET_DEVICES += comfast_cf-e110n-v2

define Device/comfast_cf-e120a-v3
  SOC := ar9344
  DEVICE_VENDOR := COMFAST
  DEVICE_MODEL := CF-E120A
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := rssileds -uboot-envtools
  IMAGE_SIZE := 8000k
endef
TARGET_DEVICES += comfast_cf-e120a-v3

define Device/comfast_cf-e130n-v2
  SOC := qca9531
  DEVICE_VENDOR := COMFAST
  DEVICE_MODEL := CF-E130N
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds -swconfig -uboot-envtools
  IMAGE_SIZE := 7936k
endef
TARGET_DEVICES += comfast_cf-e130n-v2


define Device/comfast_cf-e314n-v2
  SOC := qca9531
  DEVICE_VENDOR := COMFAST
  DEVICE_MODEL := CF-E314N
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds
  IMAGE_SIZE := 7936k
endef
TARGET_DEVICES += comfast_cf-e314n-v2

define Device/comfast_cf-e5
  SOC := qca9531
  DEVICE_VENDOR := COMFAST
  DEVICE_MODEL := CF-E5/E7
  DEVICE_PACKAGES := rssileds kmod-usb2 kmod-usb-net-qmi-wwan -swconfig \
	-uboot-envtools
  IMAGE_SIZE := 16192k
endef
TARGET_DEVICES += comfast_cf-e5

define Device/compex_wpj344-16m
  SOC := ar9344
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16128k
  DEVICE_VENDOR := Compex
  DEVICE_MODEL := WPJ344
  DEVICE_VARIANT := 16M
  SUPPORTED_DEVICES += wpj344
  IMAGES += cpximg-6a08.bin
  IMAGE/cpximg-6a08.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x690 3
endef
TARGET_DEVICES += compex_wpj344-16m

define Device/compex_wpj531-16m
  SOC := qca9531
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16128k
  DEVICE_VENDOR := Compex
  DEVICE_MODEL := WPJ531
  DEVICE_VARIANT := 16M
  SUPPORTED_DEVICES += wpj531
  IMAGES += cpximg-7a03.bin cpximg-7a04.bin cpximg-7a06.bin cpximg-7a07.bin
  IMAGE/cpximg-7a03.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x68a 2
  IMAGE/cpximg-7a04.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x693 3
  IMAGE/cpximg-7a06.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x693 3
  IMAGE/cpximg-7a07.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x693 3
endef
TARGET_DEVICES += compex_wpj531-16m

define Device/compex_wpj558-16m
  SOC := qca9558
  IMAGE_SIZE := 16128k
  DEVICE_VENDOR := Compex
  DEVICE_MODEL := WPJ558
  DEVICE_VARIANT := 16M
  SUPPORTED_DEVICES += wpj558
  IMAGES += cpximg-6a07.bin
  IMAGE/cpximg-6a07.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | mkmylofw_16m 0x691 3
  DEVICE_PACKAGES := kmod-gpio-beeper
endef
TARGET_DEVICES += compex_wpj558-16m

define Device/compex_wpj563
  SOC := qca9563
  DEVICE_PACKAGES := kmod-usb2 kmod-usb3
  IMAGE_SIZE := 16128k
  DEVICE_VENDOR := Compex
  DEVICE_MODEL := WPJ563
  SUPPORTED_DEVICES += wpj563
  IMAGES += cpximg-7a02.bin
  IMAGE/cpximg-7a02.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | mkmylofw_16m 0x694 2
endef
TARGET_DEVICES += compex_wpj563

define Device/dlink_dap-13xx
  SOC := qca9533
  DEVICE_VENDOR := D-Link
  DEVICE_PACKAGES += rssileds
  IMAGE_SIZE := 7936k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | mkdapimg2 0xE0000
endef

define Device/dlink_dap-2xxx
  IMAGES += factory.img
  IMAGE/factory.img := append-kernel | pad-offset 6144k 160 | \
	append-rootfs | wrgg-pad-rootfs | mkwrggimg | check-size
  IMAGE/sysupgrade.bin := append-kernel | mkwrggimg | \
	pad-to $$$$(BLOCKSIZE) | append-rootfs | wrgg-pad-rootfs | \
	check-size | append-metadata
  KERNEL := kernel-bin | append-dtb | relocate-kernel | lzma
  KERNEL_INITRAMFS := $$(KERNEL) | mkwrggimg
endef

define Device/dlink_dap-2230-a1
  $(Device/dlink_dap-2xxx)
  SOC := qca9533
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DAP-2230
  DEVICE_VARIANT := A1
  IMAGE_SIZE := 15232k
  DAP_SIGNATURE := wapn31_dkbs_dap2230
endef
TARGET_DEVICES += dlink_dap-2230-a1

define Device/dlink_dap-3320-a1
  $(Device/dlink_dap-2xxx)
  SOC := qca9533
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DAP-3320
  DEVICE_VARIANT := A1
  IMAGE_SIZE := 15296k
  DAP_SIGNATURE := wapn29_dkbs_dap3320
endef
TARGET_DEVICES += dlink_dap-3320-a1

define Device/dlink_dir-505
  SOC := ar9330
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DIR-505
  IMAGE_SIZE := 7680k
  DEVICE_PACKAGES := kmod-usb-chipidea2
  SUPPORTED_DEVICES += dir-505-a1
endef
TARGET_DEVICES += dlink_dir-505

define Device/dlink_dir-629-a1
  $(Device/seama)
  SOC := qca9558
  IMAGE_SIZE := 7616k
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DIR-629
  DEVICE_VARIANT := A1
  DEVICE_PACKAGES := -uboot-envtools
  SEAMA_MTDBLOCK := 6
  SEAMA_SIGNATURE := wrgn83_dlob.hans_dir629
endef
TARGET_DEVICES += dlink_dir-629-a1

define Device/dlink_dir-825-c1
  SOC := ar9344
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DIR-825
  DEVICE_VARIANT := C1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport kmod-leds-reset \
	kmod-owl-loader
  SUPPORTED_DEVICES += dir-825-c1
  IMAGE_SIZE := 15936k
  IMAGES := factory.bin sysupgrade.bin
  IMAGE/default := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | \
	pad-rootfs
  IMAGE/factory.bin := $$(IMAGE/default) | pad-offset $$$$(IMAGE_SIZE) 26 | \
	append-string 00DB120AR9344-RT-101214-00 | check-size
  IMAGE/sysupgrade.bin := $$(IMAGE/default) | check-size | append-metadata
endef
TARGET_DEVICES += dlink_dir-825-c1

define Device/dlink_dir-835-a1
  SOC := ar9344
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DIR-835
  DEVICE_VARIANT := A1
  DEVICE_PACKAGES := kmod-usb2 kmod-leds-reset kmod-owl-loader
  SUPPORTED_DEVICES += dir-835-a1
  IMAGE_SIZE := 15936k
  IMAGES := factory.bin sysupgrade.bin
  IMAGE/default := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | \
	pad-rootfs
  IMAGE/factory.bin := $$(IMAGE/default) | pad-offset $$$$(IMAGE_SIZE) 26 | \
	append-string 00DB120AR9344-RT-101214-00 | check-size
  IMAGE/sysupgrade.bin := $$(IMAGE/default) | check-size | append-metadata
endef
TARGET_DEVICES += dlink_dir-835-a1

define Device/elecom_wrc-300ghbk2-i
  SOC := qca9563
  DEVICE_VENDOR := ELECOM
  DEVICE_MODEL := WRC-300GHBK2-I
  IMAGE_SIZE := 7616k
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS := initramfs-factory.bin
  ARTIFACT/initramfs-factory.bin := append-image initramfs-kernel.bin | \
	pad-to 2 | edimax-header -b -s CSYS -m RN51 -f 0x70000 -S 0x01100000 | \
	elecom-product-header WRC-300GHBK2-I | check-size
endif
endef
TARGET_DEVICES += elecom_wrc-300ghbk2-i

define Device/embeddedwireless_balin
  SOC := ar9344
  DEVICE_VENDOR := Embedded Wireless
  DEVICE_MODEL := Balin
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += embeddedwireless_balin

define Device/embeddedwireless_dorin
  SOC := ar9331
  DEVICE_VENDOR := Embedded Wireless
  DEVICE_MODEL := Dorin
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += embeddedwireless_dorin

define Device/engenius_eap300-v2
  $(Device/senao_loader_okli)
  SOC := ar9341
  DEVICE_VENDOR := EnGenius
  DEVICE_MODEL := EAP300
  DEVICE_VARIANT := v2
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-eap300v2
endef
TARGET_DEVICES += engenius_eap300-v2

define Device/engenius_eap600
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := EnGenius
  DEVICE_MODEL := EAP600
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-eap600
endef
TARGET_DEVICES += engenius_eap600

define Device/engenius_ecb600
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := EnGenius
  DEVICE_MODEL := ECB600
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-ecb600
endef
TARGET_DEVICES += engenius_ecb600

define Device/engenius_ens202ext-v1
  $(Device/senao_loader_okli)
  SOC := ar9341
  DEVICE_VENDOR := EnGenius
  DEVICE_MODEL := ENS202EXT
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := rssileds
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-ens202ext
endef
TARGET_DEVICES += engenius_ens202ext-v1

define Device/engenius_esr900
  SOC := qca9558
  DEVICE_VENDOR := EnGenius
  DEVICE_MODEL := ESR900
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 14656k
  IMAGES += factory.dlf
  IMAGE/factory.dlf := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | \
	senao-header -r 0x101 -p 0x4e -t 2
  SUPPORTED_DEVICES += esr900
endef
TARGET_DEVICES += engenius_esr900

define Device/enterasys_ws-ap3705i
  SOC := ar9344
  DEVICE_VENDOR := Enterasys
  DEVICE_MODEL := WS-AP3705i
  IMAGE_SIZE := 30528k
endef
TARGET_DEVICES += enterasys_ws-ap3705i

define Device/etactica_eg200
  SOC := ar9331
  DEVICE_VENDOR := eTactica
  DEVICE_MODEL := EG200
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-ledtrig-oneshot \
	kmod-usb-serial-ftdi kmod-usb-storage kmod-fs-ext4
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += rme-eg200
endef
TARGET_DEVICES += etactica_eg200

define Device/fortinet_fap-221-b
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := Fortinet
  DEVICE_MODEL := FAP-221-B
  FACTORY_IMG_NAME := FP221B-9.99-AP-build999-999999-patch99
  IMAGE_SIZE := 9216k
  LOADER_FLASH_OFFS := 0x040000
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | \
	check-size | pad-to $$$$(IMAGE_SIZE) | \
	append-loader-okli-uimage $(1) | pad-to 10944k | \
	gzip-filename $$$$(FACTORY_IMG_NAME)
endef
TARGET_DEVICES += fortinet_fap-221-b

define Device/glinet_6408
  $(Device/tplink-8mlzma)
  SOC := ar9331
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := 6408
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 8000k
  TPLINK_HWID := 0x08000001
  IMAGES := sysupgrade.bin
  SUPPORTED_DEVICES += gl-inet
endef
TARGET_DEVICES += glinet_6408

define Device/glinet_6416
  $(Device/tplink-16mlzma)
  SOC := ar9331
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := 6416
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16192k
  TPLINK_HWID := 0x08000001
  IMAGES := sysupgrade.bin
  SUPPORTED_DEVICES += gl-inet
endef
TARGET_DEVICES += glinet_6416

define Device/glinet_gl-ar150
  SOC := ar9330
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := GL-AR150
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += gl-ar150
endef
TARGET_DEVICES += glinet_gl-ar150

define Device/glinet_gl-ar300m-common-nor
  SOC := qca9531
  DEVICE_VENDOR := GL.iNet
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += gl-ar300m
endef

define Device/glinet_gl-ar300m-lite
  $(Device/glinet_gl-ar300m-common-nor)
  DEVICE_MODEL := GL-AR300M
  DEVICE_VARIANT := Lite
endef
TARGET_DEVICES += glinet_gl-ar300m-lite

define Device/glinet_gl-ar300m16
  $(Device/glinet_gl-ar300m-common-nor)
  DEVICE_MODEL := GL-AR300M16
endef
TARGET_DEVICES += glinet_gl-ar300m16

define Device/glinet_gl-mifi
  SOC := ar9331
  DEVICE_VENDOR := GL.iNET
  DEVICE_MODEL := GL-MiFi
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += gl-mifi
endef
TARGET_DEVICES += glinet_gl-mifi

define Device/glinet_gl-usb150
  SOC := ar9331
  DEVICE_VENDOR := GL.iNET
  DEVICE_MODEL := GL-USB150
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += gl-usb150
endef
TARGET_DEVICES += glinet_gl-usb150

define Device/glinet_gl-x300b
  SOC := qca9531
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := GL-X300B
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += glinet_gl-x300b

define Device/hak5_lan-turtle
  $(Device/tplink-16mlzma)
  SOC := ar9331
  DEVICE_VENDOR := Hak5
  DEVICE_MODEL := LAN Turtle
  TPLINK_HWID := 0x5348334c
  IMAGES := sysupgrade.bin
  DEVICE_PACKAGES := kmod-usb-chipidea2 -iwinfo -kmod-ath9k -swconfig \
	-uboot-envtools -wpad-basic-mbedtls
  SUPPORTED_DEVICES += lan-turtle
endef
TARGET_DEVICES += hak5_lan-turtle

define Device/hak5_packet-squirrel
  $(Device/tplink-16mlzma)
  SOC := ar9331
  DEVICE_VENDOR := Hak5
  DEVICE_MODEL := Packet Squirrel
  TPLINK_HWID := 0x5351524c
  IMAGES := sysupgrade.bin
  DEVICE_PACKAGES := kmod-usb-chipidea2 -iwinfo -kmod-ath9k -swconfig \
	-uboot-envtools -wpad-basic-mbedtls
  SUPPORTED_DEVICES += packet-squirrel
endef
TARGET_DEVICES += hak5_packet-squirrel

define Device/hak5_wifi-pineapple-nano
  $(Device/tplink-16mlzma)
  SOC := ar9331
  DEVICE_VENDOR := Hak5
  DEVICE_MODEL := WiFi Pineapple NANO
  TPLINK_HWID := 0x4e414e4f
  IMAGES := sysupgrade.bin
  DEVICE_PACKAGES := kmod-ath9k-htc kmod-usb-chipidea2 kmod-usb-storage \
	-swconfig -uboot-envtools
  SUPPORTED_DEVICES += wifi-pineapple-nano
endef
TARGET_DEVICES += hak5_wifi-pineapple-nano

define Device/hiwifi_hc6361
  SOC := ar9331
  DEVICE_VENDOR := HiWiFi
  DEVICE_MODEL := HC6361
  DEVICE_PACKAGES := kmod-usb-core kmod-usb2 kmod-usb-chipidea2 kmod-usb-storage \
	kmod-fs-ext4 kmod-nls-iso8859-1 e2fsprogs
  BOARDNAME := HiWiFi-HC6361
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma | pad-to $$(BLOCKSIZE)
  IMAGE_SIZE := 16128k
endef
TARGET_DEVICES += hiwifi_hc6361

define Device/iodata_etg3-r
  SOC := ar9342
  DEVICE_VENDOR := I-O DATA
  DEVICE_MODEL := ETG3-R
  IMAGE_SIZE := 7680k
  DEVICE_PACKAGES := -iwinfo -kmod-ath9k -wpad-basic-mbedtls
endef
TARGET_DEVICES += iodata_etg3-r

define Device/iodata_wn-ag300dgr
  SOC := ar1022
  DEVICE_VENDOR := I-O DATA
  DEVICE_MODEL := WN-AG300DGR
  IMAGE_SIZE := 15424k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | \
	senao-header -r 0x30a -p 0x47 -t 2
  DEVICE_PACKAGES := kmod-usb2
endef
TARGET_DEVICES += iodata_wn-ag300dgr

define Device/jjplus_ja76pf2
  SOC := ar7161
  DEVICE_VENDOR := jjPlus
  DEVICE_MODEL := JA76PF2
  DEVICE_PACKAGES += -kmod-ath9k -swconfig -wpad-basic-mbedtls -uboot-envtools fconfig kmod-hwmon-lm75
  LOADER_TYPE := bin
  LOADER_FLASH_OFFS := 0x60000
  COMPILE := loader-$(1).bin
  COMPILE/loader-$(1).bin := loader-okli-compile | lzma | pad-to 128k
  ARTIFACTS := loader.bin
  ARTIFACT/loader.bin := append-loader-okli $(1)
  IMAGES += firmware.bin
  IMAGE/firmware.bin := append-kernel | uImage lzma -M 0x4f4b4c49 | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | pad-to $$$$(BLOCKSIZE) | check-size
  IMAGE/sysupgrade.bin := $$(IMAGE/firmware.bin) | \
	sysupgrade-tar kernel=$$$$(KDIR)/loader-$(1).bin rootfs=$$$$@ | append-metadata
  KERNEL := kernel-bin | append-dtb | lzma
  KERNEL_INITRAMFS := kernel-bin | append-dtb
  IMAGE_SIZE := 15872k
  DEVICE_COMPAT_VERSION := 2.0
  DEVICE_COMPAT_MESSAGE := Partition design has changed compared to older versions (19.07 and 21.02) \
	due to kernel drivers restrictions. Upgrade via sysupgrade mechanism is one way operation. \
	Downgrading libreCMC version will involve usage of bootloader command line interface.
endef
TARGET_DEVICES += jjplus_ja76pf2

define Device/jjplus_jwap230
  SOC := qca9558
  DEVICE_VENDOR := jjPlus
  DEVICE_MODEL := JWAP230
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += jjplus_jwap230

define Device/kuwfi_c910
  $(Device/loader-okli-uimage)
  SOC := qca9533
  DEVICE_VENDOR := KuWFi
  DEVICE_MODEL := C910
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-net-cdc-ether comgt-ncm
  LOADER_FLASH_OFFS := 0x50000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
  IMAGE_SIZE := 15936k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | pad-to 14528k | \
	append-loader-okli-uimage $(1) | pad-to 64k
endef
TARGET_DEVICES += kuwfi_c910

define Device/letv_lba-047-ch
  $(Device/loader-okli-uimage)
  SOC := qca9531
  DEVICE_VENDOR := Letv
  DEVICE_MODEL := LBA-047-CH
  DEVICE_PACKAGES := -uboot-envtools
  FACTORY_SIZE := 14528k
  IMAGE_SIZE := 15936k
  LOADER_FLASH_OFFS := 0x50000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
  IMAGES += kernel.bin rootfs.bin
  IMAGE/kernel.bin := append-loader-okli-uimage $(1) | pad-to 64k
  IMAGE/rootfs.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size $$$$(FACTORY_SIZE)
endef
TARGET_DEVICES += letv_lba-047-ch

define Device/librerouter_librerouter-v1
  SOC := qca9558
  DEVICE_VENDOR := Librerouter
  DEVICE_MODEL := LibreRouter
  DEVICE_VARIANT := v1
  IMAGE_SIZE := 7936k
  DEVICE_PACKAGES := kmod-usb2
endef
TARGET_DEVICES += librerouter_librerouter-v1

define Device/meraki_mr12
  SOC := ar7242
  DEVICE_VENDOR := Meraki
  DEVICE_MODEL := MR12
  IMAGE_SIZE := 15616k
  DEVICE_PACKAGES := kmod-owl-loader rssileds
  SUPPORTED_DEVICES += mr12
  DEVICE_COMPAT_VERSION := 2.0
  DEVICE_COMPAT_MESSAGE := Partitions differ from ar71xx version of MR12. Image format is incompatible. \
	To use sysupgrade, you must change /lib/update/common.sh::get_image to prepend 128K zeroes to this image, \
	and change the bootcmd in u-boot to "bootm 0xbf0a0000". After that, you can use "sysupgrade -F -n". \
	Make sure you do not keep your old config, as ethernet setup is not compatible either. \
	For more details, see the libreCMC Wiki: https://openwrt.org/toh/meraki/MR12, \
	or the commit message of the MR12 ath79 port on git.openwrt.org.
endef
TARGET_DEVICES += meraki_mr12

define Device/meraki_mr16
  SOC := ar7161
  DEVICE_VENDOR := Meraki
  DEVICE_MODEL := MR16
  IMAGE_SIZE := 15616k
  DEVICE_PACKAGES := kmod-owl-loader
  SUPPORTED_DEVICES += mr16
  DEVICE_COMPAT_VERSION := 2.0
  DEVICE_COMPAT_MESSAGE := Partitions differ from ar71xx version of MR16. Image format is incompatible. \
	To use sysupgrade, you must change /lib/update/common.sh::get_image to prepend 128K zeroes to this image, \
	and change the bootcmd in u-boot to "bootm 0xbf0a0000". After that, you can use "sysupgrade -F". \
	For more details, see the libreCMC Wiki: https://openwrt.org/toh/meraki/mr16, \
	or the commit message of the MR16 ath79 port on git.openwrt.org.
endef
TARGET_DEVICES += meraki_mr16

define Device/mercury_mw4530r-v1
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_VENDOR := Mercury
  DEVICE_MODEL := MW4530R
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x45300001
  SUPPORTED_DEVICES += tl-wdr4300
endef
TARGET_DEVICES += mercury_mw4530r-v1

define Device/netgear_wndap360
  $(Device/netgear_generic)
  SOC := ar7161
  DEVICE_MODEL := WNDAP360
  DEVICE_PACKAGES := kmod-leds-reset
  IMAGE_SIZE := 7744k
  BLOCKSIZE := 256k
  KERNEL := kernel-bin | append-dtb | gzip | uImage gzip
  KERNEL_INITRAMFS := kernel-bin | append-dtb | uImage none
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to 64k | append-rootfs | pad-rootfs | \
	check-size | append-metadata
endef
TARGET_DEVICES += netgear_wndap360

define Device/netgear_wndr3x00
  $(Device/netgear_generic)
  SOC := ar7161
  DEVICE_PACKAGES := kmod-usb-ohci kmod-usb2 kmod-usb-ledtrig-usbport \
	kmod-leds-reset kmod-owl-loader kmod-switch-rtl8366s
endef

define Device/netgear_wndr3700
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDR3700
  DEVICE_VARIANT := v1
  UIMAGE_MAGIC := 0x33373030
  NETGEAR_BOARD_ID := WNDR3700
  IMAGE_SIZE := 7680k
  IMAGES += factory-NA.img
  IMAGE/factory-NA.img := $$(IMAGE/default) | netgear-dni NA | \
	check-size
  SUPPORTED_DEVICES += wndr3700
endef
TARGET_DEVICES += netgear_wndr3700

define Device/netgear_wndr3700-v2
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDR3700
  DEVICE_VARIANT := v2
  UIMAGE_MAGIC := 0x33373031
  NETGEAR_BOARD_ID := WNDR3700v2
  NETGEAR_HW_ID := 29763654+16+64
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += wndr3700 netgear,wndr3700v2
endef
TARGET_DEVICES += netgear_wndr3700-v2

define Device/netgear_wndr3800
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDR3800
  UIMAGE_MAGIC := 0x33373031
  NETGEAR_BOARD_ID := WNDR3800
  NETGEAR_HW_ID := 29763654+16+128
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += wndr3700
endef
TARGET_DEVICES += netgear_wndr3800

define Device/netgear_wndr3800ch
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDR3800CH
  UIMAGE_MAGIC := 0x33373031
  NETGEAR_BOARD_ID := WNDR3800CH
  NETGEAR_HW_ID := 29763654+16+128
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += wndr3700
endef
TARGET_DEVICES += netgear_wndr3800ch

define Device/netgear_wndrmac-v1
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDRMAC
  DEVICE_VARIANT := v1
  UIMAGE_MAGIC := 0x33373031
  NETGEAR_BOARD_ID := WNDRMAC
  NETGEAR_HW_ID := 29763654+16+64
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += wndr3700
endef
TARGET_DEVICES += netgear_wndrmac-v1

define Device/netgear_wndrmac-v2
  $(Device/netgear_wndr3x00)
  DEVICE_MODEL := WNDRMAC
  DEVICE_VARIANT := v2
  UIMAGE_MAGIC := 0x33373031
  NETGEAR_BOARD_ID := WNDRMACv2
  NETGEAR_HW_ID := 29763654+16+128
  IMAGE_SIZE := 15872k
  SUPPORTED_DEVICES += wndr3700
endef
TARGET_DEVICES += netgear_wndrmac-v2

define Device/netgear_wnr2200_common
  $(Device/netgear_generic)
  SOC := ar7241
  DEVICE_MODEL := WNR2200
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  UIMAGE_MAGIC := 0x32323030
  NETGEAR_BOARD_ID := wnr2200
endef

define Device/netgear_wnr2200-8m
  $(Device/netgear_wnr2200_common)
  DEVICE_VARIANT := 8M
  NETGEAR_HW_ID := 29763600+08+64
  IMAGE_SIZE := 7808k
  IMAGES += factory-NA.img
  IMAGE/factory-NA.img := $$(IMAGE/default) | netgear-dni NA | \
	check-size
  SUPPORTED_DEVICES += wnr2200
endef
TARGET_DEVICES += netgear_wnr2200-8m

define Device/netgear_wnr2200-16m
  $(Device/netgear_wnr2200_common)
  DEVICE_VARIANT := 16M
  DEVICE_ALT0_VENDOR := NETGEAR
  DEVICE_ALT0_MODEL := WNR2200
  DEVICE_ALT0_VARIANT := CN/RU
  NETGEAR_HW_ID :=
  IMAGE_SIZE := 16000k
endef
TARGET_DEVICES += netgear_wnr2200-16m

define Device/ocedo_raccoon
  SOC := ar9344
  DEVICE_VENDOR := Ocedo
  DEVICE_MODEL := Raccoon
  IMAGE_SIZE := 14848k
endef
TARGET_DEVICES += ocedo_raccoon

define Device/onion_omega
  $(Device/tplink-16mlzma)
  SOC := ar9331
  DEVICE_VENDOR := Onion
  DEVICE_MODEL := Omega
  DEVICE_PACKAGES := kmod-usb-chipidea2
  SUPPORTED_DEVICES += onion-omega
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | uImage lzma
  IMAGE_SIZE := 16192k
  TPLINK_HWID := 0x04700001
endef
TARGET_DEVICES += onion_omega

define Device/openmesh_common_64k
  DEVICE_VENDOR := OpenMesh
  DEVICE_PACKAGES := uboot-envtools
  IMAGE_SIZE := 7808k
  OPENMESH_CE_TYPE :=
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma | \
	pad-to $$(BLOCKSIZE)
  IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | \
	openmesh-image ce_type=$$$$(OPENMESH_CE_TYPE) | append-metadata
endef

define Device/openmesh_common_256k
  DEVICE_VENDOR := OpenMesh
  DEVICE_PACKAGES := uboot-envtools
  IMAGE_SIZE := 7168k
  BLOCKSIZE := 256k
  OPENMESH_CE_TYPE :=
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma | \
	pad-to $$(BLOCKSIZE)
  IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | \
	openmesh-image ce_type=$$$$(OPENMESH_CE_TYPE) | append-metadata
endef

define Device/openmesh_mr600-v1
  $(Device/openmesh_common_64k)
  SOC := ar9344
  DEVICE_MODEL := MR600
  DEVICE_VARIANT := v1
  OPENMESH_CE_TYPE := MR600
  SUPPORTED_DEVICES += mr600
endef
TARGET_DEVICES += openmesh_mr600-v1

define Device/openmesh_mr600-v2
  $(Device/openmesh_common_64k)
  SOC := ar9344
  DEVICE_MODEL := MR600
  DEVICE_VARIANT := v2
  OPENMESH_CE_TYPE := MR600
  SUPPORTED_DEVICES += mr600v2
endef
TARGET_DEVICES += openmesh_mr600-v2

define Device/openmesh_mr900-v1
  $(Device/openmesh_common_64k)
  SOC := qca9558
  DEVICE_MODEL := MR900
  DEVICE_VARIANT := v1
  OPENMESH_CE_TYPE := MR900
  SUPPORTED_DEVICES += mr900
endef
TARGET_DEVICES += openmesh_mr900-v1

define Device/openmesh_mr900-v2
  $(Device/openmesh_common_64k)
  SOC := qca9558
  DEVICE_MODEL := MR900
  DEVICE_VARIANT := v2
  OPENMESH_CE_TYPE := MR900
  SUPPORTED_DEVICES += mr900v2
endef
TARGET_DEVICES += openmesh_mr900-v2

define Device/openmesh_om2p-v1
  $(Device/openmesh_common_256k)
  SOC := ar7240
  DEVICE_MODEL := OM2P
  DEVICE_VARIANT := v1
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p
endef
TARGET_DEVICES += openmesh_om2p-v1

define Device/openmesh_om2p-v2
  $(Device/openmesh_common_256k)
  SOC := ar9330
  DEVICE_MODEL := OM2P
  DEVICE_VARIANT := v2
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2pv2
endef
TARGET_DEVICES += openmesh_om2p-v2

define Device/openmesh_om2p-v4
  $(Device/openmesh_common_256k)
  SOC := qca9533
  DEVICE_MODEL := OM2P
  DEVICE_VARIANT := v4
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2pv4
endef
TARGET_DEVICES += openmesh_om2p-v4

define Device/openmesh_om2p-hs-v1
  $(Device/openmesh_common_256k)
  SOC := ar9341
  DEVICE_MODEL := OM2P-HS
  DEVICE_VARIANT := v1
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p-hs
endef
TARGET_DEVICES += openmesh_om2p-hs-v1

define Device/openmesh_om2p-hs-v2
  $(Device/openmesh_common_256k)
  SOC := ar9341
  DEVICE_MODEL := OM2P-HS
  DEVICE_VARIANT := v2
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p-hsv2
endef
TARGET_DEVICES += openmesh_om2p-hs-v2

define Device/openmesh_om2p-hs-v3
  $(Device/openmesh_common_256k)
  SOC := ar9341
  DEVICE_MODEL := OM2P-HS
  DEVICE_VARIANT := v3
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p-hsv3
endef
TARGET_DEVICES += openmesh_om2p-hs-v3

define Device/openmesh_om2p-hs-v4
  $(Device/openmesh_common_256k)
  SOC := qca9533
  DEVICE_MODEL := OM2P-HS
  DEVICE_VARIANT := v4
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p-hsv4
endef
TARGET_DEVICES += openmesh_om2p-hs-v4

define Device/openmesh_om2p-lc
  $(Device/openmesh_common_256k)
  SOC := ar9330
  DEVICE_MODEL := OM2P-LC
  OPENMESH_CE_TYPE := OM2P
  SUPPORTED_DEVICES += om2p-lc
endef
TARGET_DEVICES += openmesh_om2p-lc

define Device/openmesh_om5p
  $(Device/openmesh_common_64k)
  SOC := ar9344
  DEVICE_MODEL := OM5P
  OPENMESH_CE_TYPE := OM5P
  SUPPORTED_DEVICES += om5p
endef
TARGET_DEVICES += openmesh_om5p

define Device/openmesh_om5p-an
  $(Device/openmesh_common_64k)
  SOC := ar9344
  DEVICE_MODEL := OM5P-AN
  OPENMESH_CE_TYPE := OM5P
  SUPPORTED_DEVICES += om5p-an
endef
TARGET_DEVICES += openmesh_om5p-an

define Device/pcs_cap324
  SOC := ar9344
  DEVICE_VENDOR := PowerCloud Systems
  DEVICE_MODEL := CAP324
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += cap324
endef
TARGET_DEVICES += pcs_cap324

define Device/pcs_cr3000
  SOC := ar9341
  DEVICE_VENDOR := PowerCloud Systems
  DEVICE_MODEL := CR3000
  IMAGE_SIZE := 7808k
  SUPPORTED_DEVICES += cr3000
endef
TARGET_DEVICES += pcs_cr3000

define Device/pcs_cr5000
  SOC := ar9344
  DEVICE_VENDOR := PowerCloud Systems
  DEVICE_MODEL := CR5000
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 7808k
  SUPPORTED_DEVICES += cr5000
endef
TARGET_DEVICES += pcs_cr5000

define Device/pisen_ts-d084
  $(Device/tplink-8mlzma)
  SOC := ar9331
  DEVICE_VENDOR := PISEN
  DEVICE_MODEL := TS-D084
  DEVICE_PACKAGES := kmod-usb-chipidea2
  TPLINK_HWID := 0x07030101
endef
TARGET_DEVICES += pisen_ts-d084

define Device/pisen_wmb001n
  $(Device/loader-okli-uimage)
  SOC := ar9341
  DEVICE_VENDOR := PISEN
  DEVICE_MODEL := WMB001N
  IMAGE_SIZE := 14080k
  DEVICE_PACKAGES := kmod-i2c-gpio kmod-usb2
  LOADER_FLASH_OFFS := 0x20000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
  IMAGES += factory.bin
  IMAGE/factory.bin := $$(IMAGE/sysupgrade.bin) | pisen_wmb001n-factory $(1)
endef
TARGET_DEVICES += pisen_wmb001n

define Device/pisen_wmm003n
  $(Device/tplink-8mlzma)
  SOC := ar9331
  DEVICE_VENDOR := PISEN
  DEVICE_MODEL := Cloud Easy Power (WMM003N)
  DEVICE_PACKAGES := kmod-usb-chipidea2
  TPLINK_HWID := 0x07030101
endef
TARGET_DEVICES += pisen_wmm003n

define Device/plasmacloud_pa300-common
  SOC := qca9533
  DEVICE_VENDOR := Plasma Cloud
  DEVICE_PACKAGES := uboot-envtools
  IMAGE_SIZE := 7168k
  IMAGES += factory.bin
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma | pad-to $$(BLOCKSIZE)
  IMAGE/factory.bin := append-rootfs | pad-rootfs | openmesh-image ce_type=PA300
  IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | sysupgrade-tar rootfs=$$$$@ | append-metadata
endef

define Device/plasmacloud_pa300
  $(Device/plasmacloud_pa300-common)
  DEVICE_MODEL := PA300
endef
TARGET_DEVICES += plasmacloud_pa300

define Device/plasmacloud_pa300e
  $(Device/plasmacloud_pa300-common)
  DEVICE_MODEL := PA300E
endef
TARGET_DEVICES += plasmacloud_pa300e

define Device/qca_ap143
  $(Device/loader-okli-uimage)
  SOC := qca9533
  DEVICE_VENDOR := Qualcomm Atheros
  DEVICE_MODEL := AP143
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += ap143
  LOADER_FLASH_OFFS := 0x50000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
endef

define Device/qca_ap143-8m
  $(Device/qca_ap143)
  DEVICE_VARIANT := (8M)
  IMAGE_SIZE := 7744k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | pad-to 6336k | \
	append-loader-okli-uimage $(1) | pad-to 64k
endef
TARGET_DEVICES += qca_ap143-8m

define Device/qca_ap143-16m
  $(Device/qca_ap143)
  DEVICE_VARIANT := (16M)
  IMAGE_SIZE := 15936k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | \
	append-rootfs | pad-rootfs | check-size | pad-to 14528k | \
	append-loader-okli-uimage $(1) | pad-to 64k
endef
TARGET_DEVICES += qca_ap143-16m

define Device/qxwlan_e558-v2
  SOC := qca9558
  DEVICE_VENDOR := Qxwlan
  DEVICE_MODEL := E558
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += e558-v2
endef

define Device/qxwlan_e558-v2-16m
  $(Device/qxwlan_e558-v2)
  DEVICE_VARIANT := v2 (16M)
  IMAGE_SIZE := 15936k
endef
TARGET_DEVICES += qxwlan_e558-v2-16m

define Device/qxwlan_e558-v2-8m
  $(Device/qxwlan_e558-v2)
  DEVICE_VARIANT := v2 (8M)
  IMAGE_SIZE := 7744k
endef
TARGET_DEVICES += qxwlan_e558-v2-8m

define Device/qxwlan_e600g-v2
  SOC := qca9531
  DEVICE_VENDOR := Qxwlan
  DEVICE_MODEL := E600G
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += e600g-v2
endef

define Device/qxwlan_e600g-v2-16m
  $(Device/qxwlan_e600g-v2)
  DEVICE_VARIANT := v2 (16M)
  IMAGE_SIZE := 15936k
endef
TARGET_DEVICES += qxwlan_e600g-v2-16m

define Device/qxwlan_e600g-v2-8m
  $(Device/qxwlan_e600g-v2)
  DEVICE_VARIANT := v2 (8M)
  IMAGE_SIZE := 7744k
endef
TARGET_DEVICES += qxwlan_e600g-v2-8m

define Device/qxwlan_e750a-v4
  SOC := ar9344
  DEVICE_VENDOR := Qxwlan
  DEVICE_MODEL := E750A
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += e750a-v4
endef

define Device/qxwlan_e750a-v4-16m
  $(Device/qxwlan_e750a-v4)
  DEVICE_VARIANT := v4 (16M)
  IMAGE_SIZE := 15936k
endef
TARGET_DEVICES += qxwlan_e750a-v4-16m

define Device/qxwlan_e750a-v4-8m
  $(Device/qxwlan_e750a-v4)
  DEVICE_VARIANT := v4 (8M)
  IMAGE_SIZE := 7744k
endef
TARGET_DEVICES += qxwlan_e750a-v4-8m

define Device/qxwlan_e750g-v8
  SOC := ar9344
  DEVICE_VENDOR := Qxwlan
  DEVICE_MODEL := E750G
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += e750g-v8
endef

define Device/qxwlan_e750g-v8-16m
  $(Device/qxwlan_e750g-v8)
  DEVICE_VARIANT := v8 (16M)
  IMAGE_SIZE := 15936k
endef
TARGET_DEVICES += qxwlan_e750g-v8-16m

define Device/qxwlan_e750g-v8-8m
  $(Device/qxwlan_e750g-v8)
  DEVICE_VARIANT := v8 (8M)
  IMAGE_SIZE := 7744k
endef
TARGET_DEVICES += qxwlan_e750g-v8-8m

define Device/rosinson_wr818
  SOC := qca9563
  DEVICE_VENDOR := Rosinson
  DEVICE_MODEL := WR818
  IMAGE_SIZE := 15872k
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += rosinson_wr818

define Device/ruckus_common
  DEVICE_VENDOR := Ruckus
  LOADER_TYPE := bin
  KERNEL := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
endef

define Device/ruckus_zf7025
  $(Device/ruckus_common)
  SOC := ar7240
  DEVICE_MODEL := ZoneFlex 7025
  IMAGE_SIZE := 15616k
  BLOCKSIZE := 256k
endef
TARGET_DEVICES += ruckus_zf7025

define Device/ruckus_gd11_common
  $(Device/ruckus_common)
  SOC := ar7161
  IMAGE_SIZE := 15616k
  BLOCKSIZE := 256k
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-chipidea2
endef

define Device/ruckus_zf7341
  $(Device/ruckus_gd11_common)
  DEVICE_MODEL := ZoneFlex 7341[-U]
  DEVICE_PACKAGES += -swconfig
endef
TARGET_DEVICES += ruckus_zf7341

define Device/ruckus_zf7351
  $(Device/ruckus_gd11_common)
  DEVICE_MODEL := ZoneFlex 7351[-U]
  DEVICE_PACKAGES += -swconfig
endef
TARGET_DEVICES += ruckus_zf7351

define Device/ruckus_zf7363
  $(Device/ruckus_gd11_common)
  DEVICE_MODEL := ZoneFlex 7363[-U]
  DEVICE_ALT0_VENDOR := Ruckus
  DEVICE_ALT0_MODEL := ZoneFlex 7343[-U]
endef
TARGET_DEVICES += ruckus_zf7363

define Device/ruckus_zf73xx_common
  $(Device/ruckus_common)
  DEVICE_PACKAGES := -swconfig kmod-usb2 kmod-usb-chipidea2
  IMAGE_SIZE := 31744k
endef

define Device/ruckus_zf7321
  $(Device/ruckus_zf73xx_common)
  SOC := ar9342
  DEVICE_MODEL := ZoneFlex 7321[-U]
endef
TARGET_DEVICES += ruckus_zf7321

define Device/ruckus_zf7372
  $(Device/ruckus_zf73xx_common)
  SOC := ar9344
  DEVICE_MODEL := ZoneFlex 7352/7372[-E/-U]
endef
TARGET_DEVICES += ruckus_zf7372

define Device/samsung_wam250
  SOC := ar9344
  DEVICE_VENDOR := Samsung
  DEVICE_MODEL := WAM250
  IMAGE_SIZE := 15872k
  DEVICE_PACKAGES := kmod-usb2
  SUPPORTED_DEVICES += wam250
endef
TARGET_DEVICES += samsung_wam250

define Device/siemens_ws-ap3610
  SOC := ar7161
  DEVICE_VENDOR := Siemens
  DEVICE_MODEL := WS-AP3610
  IMAGE_SIZE := 14336k
  BLOCKSIZE := 256k
  LOADER_TYPE := bin
  LOADER_FLASH_OFFS := 0x82000
  COMPILE := loader-$(1).bin
  COMPILE/loader-$(1).bin := loader-okli-compile
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49 | loader-okli $(1) 8128 | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | uImage none
endef
TARGET_DEVICES += siemens_ws-ap3610

define Device/telco_t1
  SOC := qca9531
  DEVICE_VENDOR := Telco
  DEVICE_MODEL := T1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-net-qmi-wwan \
	kmod-usb-serial-option uqmi -swconfig -uboot-envtools
  IMAGE_SIZE := 16192k
  SUPPORTED_DEVICES += telco_electronics,tel-t1
endef
TARGET_DEVICES += telco_t1

define Device/teltonika_rut230-v1
  SOC := ar9331
  DEVICE_VENDOR := Teltonika
  DEVICE_MODEL := RUT230
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-acm kmod-usb-net-qmi-wwan \
	uqmi -uboot-envtools
  IMAGE_SIZE := 15552k
  TPLINK_HWID := 0x32200002
  TPLINK_HWREV := 0x1
  TPLINK_HEADER_VERSION := 1
  KERNEL := kernel-bin | append-dtb | lzma | teltonika-v1-header
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | uImage lzma
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs |\
	pad-rootfs | pad-extra 64 | teltonika-fw-fake-checksum 54 | check-size
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$$$(BLOCKSIZE) |\
	append-rootfs | pad-rootfs | append-metadata |\
	check-size
endef
TARGET_DEVICES += teltonika_rut230-v1

define Device/teltonika_rut300
  SOC := qca9531
  DEVICE_VENDOR := Teltonika
  DEVICE_MODEL := RUT300
  SUPPORTED_TELTONIKA_DEVICES := teltonika,rut30x
  DEVICE_PACKAGES := -kmod-ath9k -uboot-envtools -wpad-basic-mbedtls kmod-usb2
  IMAGE_SIZE := 15552k
  IMAGES += factory.bin
  IMAGE/factory.bin = append-kernel | pad-to $$$$(BLOCKSIZE) | \
			 append-rootfs | pad-rootfs | append-metadata-teltonika | \
			 check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin = append-kernel | pad-to $$$$(BLOCKSIZE) | \
			 append-rootfs | pad-rootfs | append-metadata | \
			 check-size $$$$(IMAGE_SIZE)
endef
TARGET_DEVICES += teltonika_rut300

define Device/teltonika_rut955
  SOC := ar9344
  DEVICE_VENDOR := Teltonika
  DEVICE_MODEL := RUT955
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-acm kmod-usb-net-qmi-wwan \
	kmod-usb-serial-option kmod-hwmon-mcp3021 uqmi -uboot-envtools
  IMAGE_SIZE := 15552k
  TPLINK_HWID := 0x35000001
  TPLINK_HWREV := 0x1
  TPLINK_HEADER_VERSION := 1
  KERNEL := kernel-bin | append-dtb | lzma | tplink-v1-header
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | uImage lzma
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs |\
	pad-rootfs | teltonika-fw-fake-checksum 20 | append-string master |\
	append-md5sum-bin | check-size
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$$$(BLOCKSIZE) |\
	append-rootfs | pad-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += teltonika_rut955

define Device/teltonika_rut955-h7v3c0
  $(Device/teltonika_rut955)
  DEVICE_VARIANT := H7V3C0
endef
TARGET_DEVICES += teltonika_rut955-h7v3c0

define Device/thinkpenguin_tpe-r1100
  SOC := ar9330
  DEVICE_VENDOR := ThinkPenguin
  DEVICE_MODEL := TPE-R1100
  DEVICE_PACKAGES := kmod-usb-chipidea2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += tpe-r1100
endef
TARGET_DEVICES += thinkpenguin_tpe-r1100

define Device/thinkpenguin_tpe-r1200
  SOC := qca9531
  DEVICE_VENDOR := ThinkPenguin
  DEVICE_MODEL := TPE-R1200
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += tpe-r1200
endef
TARGET_DEVICES += thinkpenguin_tpe-r1200

define Device/thinkpenguin_tpe-r1300
  SOC := qca9531
  DEVICE_VENDOR := ThinkPenguin
  DEVICE_PACKAGES := kmod-usb2
  IMAGE_SIZE := 16000k
  SUPPORTED_DEVICES += tpe-r1300
  DEVICE_MODEL := TPE-R1300
endef
TARGET_DEVICES += thinkpenguin_tpe-r1300

define Device/wallys_dr531
  SOC := qca9531
  DEVICE_VENDOR := Wallys
  DEVICE_MODEL := DR531
  DEVICE_PACKAGES := kmod-usb2 rssileds
  IMAGE_SIZE := 7808k
  SUPPORTED_DEVICES += dr531
endef
TARGET_DEVICES += wallys_dr531

define Device/watchguard_ap100
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := WatchGuard
  DEVICE_MODEL := AP100
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-ap100
  WATCHGUARD_MAGIC := 82kdlzk2
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | \
	check-size | senao-tar-gz $$$$(SENAO_IMGNAME) | watchguard-cksum $$$$(WATCHGUARD_MAGIC)
endef
TARGET_DEVICES += watchguard_ap100

define Device/watchguard_ap200
  $(Device/senao_loader_okli)
  SOC := ar9344
  DEVICE_VENDOR := WatchGuard
  DEVICE_MODEL := AP200
  IMAGE_SIZE := 12096k
  LOADER_FLASH_OFFS := 0x220000
  SENAO_IMGNAME := senao-ap200
  WATCHGUARD_MAGIC := 82kdlzk2
  IMAGE/factory.bin := append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | \
	check-size | senao-tar-gz $$$$(SENAO_IMGNAME) | watchguard-cksum $$$$(WATCHGUARD_MAGIC)
endef
TARGET_DEVICES += watchguard_ap200

define Device/wd_mynet-n600
  $(Device/seama)
  SOC := ar9344
  DEVICE_VENDOR := Western Digital
  DEVICE_MODEL := My Net N600
  IMAGE_SIZE := 15872k
  DEVICE_PACKAGES := kmod-usb2
  SEAMA_SIGNATURE := wrgnd16_wd_db600
  SUPPORTED_DEVICES += mynet-n600
endef
TARGET_DEVICES += wd_mynet-n600

define Device/wd_mynet-n750
  $(Device/seama)
  SOC := ar9344
  DEVICE_VENDOR := Western Digital
  DEVICE_MODEL := My Net N750
  IMAGE_SIZE := 15872k
  DEVICE_PACKAGES := kmod-usb2
  SEAMA_SIGNATURE := wrgnd13_wd_av
  SUPPORTED_DEVICES += mynet-n750
endef
TARGET_DEVICES += wd_mynet-n750

define Device/wd_mynet-wifi-rangeextender
  SOC := ar9344
  DEVICE_VENDOR := Western Digital
  DEVICE_MODEL := My Net Wi-Fi Range Extender
  DEVICE_PACKAGES := rssileds nvram -swconfig
  IMAGE_SIZE := 7808k
  ADDPATTERN_ID := mynet-rext
  ADDPATTERN_VERSION := 1.00.01
  IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | cybertan-trx | \
	addpattern | append-metadata
  SUPPORTED_DEVICES += mynet-rext
  DEFAULT := n
endef
TARGET_DEVICES += wd_mynet-wifi-rangeextender

define Device/winchannel_wb2000
  SOC := ar9344
  DEVICE_VENDOR := Winchannel
  DEVICE_MODEL := WB2000
  IMAGE_SIZE := 15872k
  DEVICE_PACKAGES := kmod-i2c-gpio kmod-rtc-ds1307 kmod-usb2 \
	kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += winchannel_wb2000


define Device/xiaomi_mi-router-4q
  SOC := qca9561
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 4Q
  IMAGE_SIZE := 14336k
endef
TARGET_DEVICES += xiaomi_mi-router-4q

define Device/yuncore_a930
  SOC := qca9533
  DEVICE_VENDOR := YunCore
  DEVICE_MODEL := A930
  IMAGE_SIZE := 16000k
  IMAGES += tftp.bin
  IMAGE/tftp.bin := $$(IMAGE/sysupgrade.bin) | yuncore-tftp-header-16m
endef
TARGET_DEVICES += yuncore_a930

define Device/ziking_cpe46b
  SOC := ar9330
  DEVICE_VENDOR := ZiKing
  DEVICE_MODEL := CPE46B
  IMAGE_SIZE := 8000k
  DEVICE_PACKAGES := kmod-i2c-gpio
  DEFAULT := n
endef
TARGET_DEVICES += ziking_cpe46b

define Device/zbtlink_zbt-wd323
  SOC := ar9344
  DEVICE_VENDOR := ZBT
  DEVICE_MODEL := WD323
  IMAGE_SIZE := 16000k
  DEVICE_PACKAGES := kmod-usb2 kmod-i2c-gpio kmod-rtc-pcf8563 \
	kmod-usb-serial-cp210x uqmi
endef
TARGET_DEVICES += zbtlink_zbt-wd323

define Device/zyxel_nwa11xx
  $(Device/loader-okli-uimage)
  SOC := ar9342
  DEVICE_VENDOR := ZyXEL
  LOADER_FLASH_OFFS := 0x050000
  KERNEL := kernel-bin | append-dtb | lzma | uImage lzma -M 0x4f4b4c49
  IMAGE_SIZE := 8192k
  IMAGES += factory-$$$$(ZYXEL_MODEL_STRING).bin
  IMAGE/factory-$$$$(ZYXEL_MODEL_STRING).bin := \
	append-kernel | pad-to $$$$(BLOCKSIZE) | append-rootfs | \
	pad-rootfs | pad-to 8192k | check-size | zyxel-tar-bz2 \
	vmlinux_mi124_f1e mi124_f1e-jffs2 | append-md5sum-bin
endef

define Device/zyxel_nwa1100-nh
  $(Device/zyxel_nwa11xx)
  DEVICE_MODEL := NWA1100
  DEVICE_VARIANT := NH
  ZYXEL_MODEL_STRING := AASI
endef
TARGET_DEVICES += zyxel_nwa1100-nh

define Device/zyxel_nwa1121-ni
  $(Device/zyxel_nwa11xx)
  DEVICE_MODEL := NWA1121
  DEVICE_VARIANT := NI
  ZYXEL_MODEL_STRING := AABJ
endef
TARGET_DEVICES += zyxel_nwa1121-ni

define Device/zyxel_nwa1123-ni
  $(Device/zyxel_nwa11xx)
  DEVICE_MODEL := NWA1123
  DEVICE_VARIANT := NI
  ZYXEL_MODEL_STRING := AAEO
endef
TARGET_DEVICES += zyxel_nwa1123-ni
