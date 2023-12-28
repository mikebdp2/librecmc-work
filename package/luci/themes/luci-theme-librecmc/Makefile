#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI libreCMC.org theme
LUCI_DEPENDS:=

define Package/luci-theme-librecmc/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete luci.themes.libreCMC
	uci commit luci
}
endef

include ../../luci.mk

# call BuildPackage - libreCMC buildroot signature
