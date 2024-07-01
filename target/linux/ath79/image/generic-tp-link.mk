include ./common-tp-link.mk

define Device/tplink_archer-c5-v1
  $(Device/tplink-16mlzma)
  SOC := qca9558
  DEVICE_MODEL := Archer C5
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0xc5000001
  SUPPORTED_DEVICES += archer-c5
endef
TARGET_DEVICES += tplink_archer-c5-v1

define Device/tplink_archer-c7-v1
  $(Device/tplink-8mlzma)
  SOC := qca9558
  DEVICE_MODEL := Archer C7
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x75000001
  SUPPORTED_DEVICES += archer-c7
endef
TARGET_DEVICES += tplink_archer-c7-v1

define Device/tplink_archer-c7-v2
  $(Device/tplink-16mlzma)
  SOC := qca9558
  DEVICE_MODEL := Archer C7
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0xc7000002
  SUPPORTED_DEVICES += archer-c7
  IMAGES += factory-us.bin factory-eu.bin
  IMAGE/factory-us.bin := tplink-v1-image factory -C US
  IMAGE/factory-eu.bin := tplink-v1-image factory -C EU
endef
TARGET_DEVICES += tplink_archer-c7-v2

define Device/tplink_cpe210-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE210
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE210
  SUPPORTED_DEVICES += cpe210
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe210-v1

define Device/tplink_cpe210-v2
  $(Device/tplink-safeloader)
  SOC := qca9533
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE210
  DEVICE_VARIANT := v2
  TPLINK_BOARD_ID := CPE210V2
  DEVICE_PACKAGES := rssileds
  LOADER_TYPE := elf
  SUPPORTED_DEVICES += cpe210-v2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe210-v2

define Device/tplink_cpe210-v3
  $(Device/tplink-safeloader)
  SOC := qca9533
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE210
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE210V3
  LOADER_TYPE := elf
  SUPPORTED_DEVICES += cpe210-v3
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe210-v3

define Device/tplink_cpe220-v2
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE220
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE220V2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe220-v2

define Device/tplink_cpe220-v3
  $(Device/tplink-safeloader)
  SOC := qca9533
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE220
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE220V3
  LOADER_TYPE := elf
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe220-v3

define Device/tplink_cpe510-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE510
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE510
  SUPPORTED_DEVICES += cpe510
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe510-v1

define Device/tplink_cpe510-v2
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE510
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE510V2
  SUPPORTED_DEVICES += cpe510-v2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe510-v2

define Device/tplink_cpe510-v3
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE510
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := CPE510V3
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe510-v3

define Device/tplink_cpe605-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE605
  DEVICE_VARIANT := v1
  TPLINK_BOARD_ID := CPE605V1
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe605-v1

define Device/tplink_cpe610-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE610
  DEVICE_VARIANT := v1
  TPLINK_BOARD_ID := CPE610V1
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe610-v1

define Device/tplink_cpe610-v2
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := CPE610
  DEVICE_VARIANT := v2
  TPLINK_BOARD_ID := CPE610V2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_cpe610-v2

define Device/tplink-eap2x5
  $(Device/tplink-safeloader)
  LOADER_TYPE := elf
  KERNEL := kernel-bin | append-dtb | lzma | loader-kernel
  KERNEL_INITRAMFS := $$(KERNEL)
  IMAGE/factory.bin := append-rootfs | tplink-safeloader factory | \
	pad-extra 128
endef

define Device/tplink_tl-mr6400-v1
  $(Device/tplink-8mlzma)
  SOC := qca9531
  DEVICE_MODEL := TL-MR6400
  DEVICE_VARIANT := v1
  TPLINK_HWID := 0x64000001
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-net-rndis \
	kmod-usb-serial-option adb-enablemodem
  SUPPORTED_DEVICES += tl-mr6400
endef
TARGET_DEVICES += tplink_tl-mr6400-v1

define Device/tplink_tl-wdr3500-v1
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WDR3500
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x35000001
  SUPPORTED_DEVICES += tl-wdr3500
endef
TARGET_DEVICES += tplink_tl-wdr3500-v1

define Device/tplink_tl-wdr3600-v1
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WDR3600
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x36000001
  SUPPORTED_DEVICES += tl-wdr4300
endef
TARGET_DEVICES += tplink_tl-wdr3600-v1

define Device/tplink_tl-wdr4300-v1
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WDR4300
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x43000001
  SUPPORTED_DEVICES += tl-wdr4300
endef
TARGET_DEVICES += tplink_tl-wdr4300-v1

define Device/tplink_tl-wdr4300-v1-il
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WDR4300
  DEVICE_VARIANT := v1 (IL)
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x43008001
  SUPPORTED_DEVICES += tl-wdr4300
endef
TARGET_DEVICES += tplink_tl-wdr4300-v1-il

define Device/tplink_tl-wdr4310-v1
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WDR4310
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x43100001
  SUPPORTED_DEVICES += tl-wdr4300
endef
TARGET_DEVICES += tplink_tl-wdr4310-v1

define Device/tplink_tl-wdr4900-v2
  $(Device/tplink-8mlzma)
  SOC := qca9558
  DEVICE_MODEL := TL-WDR4900
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x49000002
  SUPPORTED_DEVICES += tl-wdr4900-v2
endef
TARGET_DEVICES += tplink_tl-wdr4900-v2

define Device/tplink_tl-wr1043nd-v1
  $(Device/tplink-8m)
  SOC := ar9132
  DEVICE_MODEL := TL-WR1043N/ND
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport kmod-switch-rtl8366rb
  TPLINK_HWID := 0x10430001
  SUPPORTED_DEVICES += tl-wr1043nd
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr1043nd-v1

define Device/tplink_tl-wr1043nd-v2
  $(Device/tplink-8mlzma)
  SOC := qca9558
  DEVICE_MODEL := TL-WR1043N/ND
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x10430002
  SUPPORTED_DEVICES += tl-wr1043nd-v2
endef
TARGET_DEVICES += tplink_tl-wr1043nd-v2

define Device/tplink_tl-wr1043nd-v3
  $(Device/tplink-8mlzma)
  SOC := qca9558
  DEVICE_MODEL := TL-WR1043N/ND
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x10430003
  SUPPORTED_DEVICES += tl-wr1043nd-v2
endef
TARGET_DEVICES += tplink_tl-wr1043nd-v3

define Device/tplink_tl-wr1043nd-v4
  $(Device/tplink-safeloader)
  SOC := qca9563
  IMAGE_SIZE := 15552k
  DEVICE_MODEL := TL-WR1043N/ND
  DEVICE_VARIANT := v4
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x10430004
  TPLINK_HWREV := 0x1
  TPLINK_BOARD_ID := TLWR1043NDV4
  SUPPORTED_DEVICES += tl-wr1043nd-v4
endef
TARGET_DEVICES += tplink_tl-wr1043nd-v4

define Device/tplink_tl-wr1043n-v5
  $(Device/tplink-safeloader-uimage)
  SOC := qca9563
  IMAGE_SIZE := 15104k
  DEVICE_MODEL := TL-WR1043N
  DEVICE_VARIANT := v5
  TPLINK_BOARD_ID := TLWR1043NV5
  SUPPORTED_DEVICES += tl-wr1043n-v5
endef
TARGET_DEVICES += tplink_tl-wr1043n-v5

define Device/tplink_tl-wr1045nd-v2
  $(Device/tplink-8mlzma)
  SOC := qca9558
  DEVICE_MODEL := TL-WR1045ND
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x10450002
endef
TARGET_DEVICES += tplink_tl-wr1045nd-v2

define Device/tplink_tl-wr2543-v1
  $(Device/tplink-8mlzma)
  SOC := ar7242
  DEVICE_MODEL := TL-WR2543N/ND
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport kmod-switch-rtl8367
  TPLINK_HWID := 0x25430001
  IMAGE/sysupgrade.bin := tplink-v1-image sysupgrade -v 3.13.99 | \
	check-size | append-metadata
  IMAGE/factory.bin := tplink-v1-image factory -v 3.13.99
  SUPPORTED_DEVICES += tl-wr2543n
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr2543-v1

define Device/tplink_tl-wr710n-v1
  $(Device/tplink-8mlzma)
  SOC := ar9331
  DEVICE_MODEL := TL-WR710N
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x07100001
  SUPPORTED_DEVICES += tl-wr710n
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr710n-v1

define Device/tplink_tl-wr710n-v2.1
  $(Device/tplink-8mlzma)
  SOC := ar9331
  DEVICE_MODEL := TL-WR710N
  DEVICE_VARIANT := v2.1
  DEVICE_PACKAGES := kmod-usb-chipidea2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x07100002
  TPLINK_HWREV := 0x2
  SUPPORTED_DEVICES += tl-wr710n
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr710n-v2.1

define Device/tplink_tl-wr810n-v1
  $(Device/tplink-8mlzma)
  SOC := qca9531
  DEVICE_MODEL := TL-WR810N
  DEVICE_VARIANT := v1
  TPLINK_HWID := 0x8100001
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += tl-wr810n
endef
TARGET_DEVICES += tplink_tl-wr810n-v1

define Device/tplink_tl-wr810n-v2
  $(Device/tplink-8mlzma)
  SOC := qca9533
  DEVICE_MODEL := TL-WR810N
  DEVICE_VARIANT := v2
  TPLINK_HWID := 0x8100002
  SUPPORTED_DEVICES += tl-wr810n-v2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr810n-v2

define Device/tplink_tl-wr841hp-v2
  $(Device/tplink-8mlzma)
  SOC := ar9344
  DEVICE_MODEL := TL-WR841HP
  DEVICE_VARIANT := v2
  TPLINK_HWID := 0x08411002
endef
TARGET_DEVICES += tplink_tl-wr841hp-v2

define Device/tplink_tl-wr841hp-v3
  $(Device/tplink-8mlzma)
  SOC := qca9533
  DEVICE_MODEL := TL-WR841HP
  DEVICE_VARIANT := v3
  TPLINK_HWID := 0x08411003
endef
TARGET_DEVICES += tplink_tl-wr841hp-v3

define Device/tplink_tl-wr842n-v1
  $(Device/tplink-8m)
  SOC := ar7241
  DEVICE_MODEL := TL-WR842N/ND
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x8420001
  SUPPORTED_DEVICES += tl-mr3420
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr842n-v1

define Device/tplink_tl-wr842n-v2
  $(Device/tplink-8mlzma)
  SOC := ar9341
  DEVICE_MODEL := TL-WR842N/ND
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x8420002
  SUPPORTED_DEVICES += tl-wr842n-v2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr842n-v2

define Device/tplink_tl-wr842n-v3
  $(Device/tplink-16mlzma)
  SOC := qca9533
  DEVICE_MODEL := TL-WR842N
  DEVICE_VARIANT := v3
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ledtrig-usbport
  TPLINK_HWID := 0x8420003
  SUPPORTED_DEVICES += tl-wr842n-v3
endef
TARGET_DEVICES += tplink_tl-wr842n-v3


define Device/tplink_tl-wr941hp-v1
  $(Device/tplink-safeloader)
  SOC := tp9343
  DEVICE_MODEL := TL-WR941HP
  DEVICE_VARIANT := v1
  TPLINK_BOARD_ID := TL-WR941HP-V1
  IMAGE_SIZE := 7360k
  DEFAULT := n
endef
TARGET_DEVICES += tplink_tl-wr941hp-v1

define Device/tplink_wbs210-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := WBS210
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := WBS210
  SUPPORTED_DEVICES += wbs210
  DEFAULT := n
endef
TARGET_DEVICES += tplink_wbs210-v1

define Device/tplink_wbs210-v2
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := WBS210
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := WBS210V2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_wbs210-v2

define Device/tplink_wbs510-v1
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := WBS510
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := WBS510
  SUPPORTED_DEVICES += wbs510
  DEFAULT := n
endef
TARGET_DEVICES += tplink_wbs510-v1

define Device/tplink_wbs510-v2
  $(Device/tplink-safeloader-okli)
  SOC := ar9344
  IMAGE_SIZE := 7680k
  DEVICE_MODEL := WBS510
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := rssileds
  TPLINK_BOARD_ID := WBS510V2
  DEFAULT := n
endef
TARGET_DEVICES += tplink_wbs510-v2
