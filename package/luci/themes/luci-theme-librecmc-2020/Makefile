#
# Copyright (C) 2020 Jo-Philipp Wich <jo@mein.io>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI modern libreCMC theme
LUCI_DEPENDS:=

define Package/luci-theme-librecmc-2020/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete luci.themes.libreCMC2020
	uci commit luci
}
endef

include ../../luci.mk

# call BuildPackage - libreCMC buildroot signature
