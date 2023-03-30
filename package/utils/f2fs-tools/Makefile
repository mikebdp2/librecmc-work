#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=f2fs-tools
PKG_VERSION:=1.14.0
PKG_RELEASE:=3

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git/snapshot/
PKG_HASH:=619263d4e2022152a1472c1d912eaae104f20bd227ce0bb9d41d1d6608094bd1

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/f2fs-tools/Default
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=Filesystem
  DEPENDS:=+libf2fs
  URL:=http://git.kernel.org/cgit/linux/kernel/git/jaegeuk/f2fs-tools.git
  VARIANT:=default
endef

define Package/mkf2fs
  $(Package/f2fs-tools/Default)
  TITLE:=Utility for creating a Flash-Friendly File System (F2FS)
  CONFLICTS:=mkf2fs-selinux
endef

define Package/f2fsck
  $(Package/f2fs-tools/Default)
  TITLE:=Utility for checking/repairing a Flash-Friendly File System (F2FS)
  CONFLICTS:=f2fsck-selinux
endef

define Package/f2fs-tools
  $(Package/f2fs-tools/Default)
  TITLE:=Tools for Flash-Friendly File System (F2FS)
  DEPENDS += +mkf2fs +f2fsck
  CONFLICTS:=f2fs-tools-selinux
endef

define Package/libf2fs
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Library for Flash-Friendly File System (F2FS) tools
  DEPENDS:=+libuuid
  ABI_VERSION:=6
  CONFLICTS:=libf2fs-selinux
  VARIANT:=default
endef

CONFIGURE_ARGS += \
	--disable-static \
	--without-blkid \
        --without-selinux

CONFIGURE_VARS += \
	ac_cv_file__git=no

define Package/libf2fs/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/libf2fs.so.* $(1)/usr/lib/
endef

define Package/mkf2fs/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/mkfs.f2fs $(1)/usr/sbin
endef

define Package/f2fsck/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/fsck.f2fs $(1)/usr/sbin
	ln -s /usr/sbin/fsck.f2fs $(1)/usr/sbin/defrag.f2fs
	ln -s /usr/sbin/fsck.f2fs $(1)/usr/sbin/dump.f2fs
	ln -s /usr/sbin/fsck.f2fs $(1)/usr/sbin/sload.f2fs
	ln -s /usr/sbin/fsck.f2fs $(1)/usr/sbin/resize.f2fs
endef

define Package/f2fs-tools/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/f2fstat $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/fibmap.f2fs $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/parse.f2fs $(1)/usr/sbin
endef

$(eval $(call BuildPackage,libf2fs))
$(eval $(call BuildPackage,mkf2fs))
$(eval $(call BuildPackage,f2fsck))
$(eval $(call BuildPackage,f2fs-tools))
