#
# Copyright (C) 2006-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

WIRELESS_MENU:=Wireless Drivers

define KernelPackage/owl-loader
  SUBMENU:=$(WIRELESS_MENU)
  TITLE:=Owl loader for initializing Atheros PCI(e) Wifi chips
  DEPENDS:=@PCI_SUPPORT
  KCONFIG:=CONFIG_OWL_LOADER
  FILES:=$(LINUX_DIR)/drivers/misc/owl-loader.ko
  AUTOLOAD:=$(call AutoProbe,owl-loader)
endef

define KernelPackage/owl-loader/description
  Kernel module that helps to initialize certain Qualcomm
  Atheros' PCI(e) Wifi chips, which have the init data
  (which contains the PCI device ID for example) stored
  together with the calibration data in the file system.

  This is necessary for devices like the Cisco Meraki Z1.
endef

$(eval $(call KernelPackage,owl-loader))
