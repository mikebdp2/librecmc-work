#
# Copyright (C) 2017 Hauke Mehrtens
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-rockchip
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/ARM-software/arm-trusted-firmware
PKG_SOURCE_DATE:=2021-10-13
PKG_SOURCE_VERSION:=fa1e016766fa5e289bcb0071d79dfb803d31be71
PKG_MIRROR_HASH:=0e5b7ca16861270f6c8924c8e2451208477e38febac6a6cb0e0d4f9388122462

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=license.md

PKG_MAINTAINER:=Hauke Mehrtens <hauke@hauke-m.de>

include $(INCLUDE_DIR)/package.mk


define Package/arm-trusted-firmware-rockchip
    SECTION:=boot
    CATEGORY:=Boot Loaders
    TITLE:=ARM Trusted Firmware for Rockchip
    DEPENDS:=@TARGET_rockchip_armv8
endef

export GCC_HONOUR_COPTS=s

MAKE_VARS = \
	CROSS_COMPILE="$(TARGET_CROSS)"

MAKE_FLAGS += \
	PLAT=rk3328 \
	bl31

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(PKG_BUILD_DIR)/build/rk3328/release/bl31/bl31.elf $(STAGING_DIR_IMAGE)/rk3328_bl31.elf
endef

define Package/arm-trusted-firmware-rockchip/install
endef

$(eval $(call BuildPackage,arm-trusted-firmware-rockchip))
