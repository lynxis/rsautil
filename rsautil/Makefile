#
# Copyright (C) 2018 Alexander Couzens <lynxis@fe80.eu>
#
# This is free software, licensed under the MIT license.
# See /LICENSE for more information.
#
#

include $(TOPDIR)/rules.mk

PKG_NAME:=rsautil
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_BUILD_DIR:=$(BUILD_DIR)/rsautil

PKG_MAINTAINER:=Alexander Couzens <lynxis@fe80.eu>

include $(INCLUDE_DIR)/package.mk

define Package/rsautil
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=Encryption
  TITLE:=A simple util to encrypt rsa messages
  DEPENDS:=+libmbedtls
endef

define Package/rsautil/description
 a simple rsa util to encrypt messages using mbedtls
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp rsautil.c $(PKG_BUILD_DIR)/
endef

TARGET_LDFLAGS += -lmbedtls -lmbedcrypto -static

TARGET_CFLAGS += -Wl,--gc-sections

define Build/Compile
	$(TARGET_CC) $(TARGET_CPPFLAGS) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/rsautil $(PKG_BUILD_DIR)/rsautil.c $(TARGET_LDFLAGS)
endef

define Package/rsautil/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rsautil $(1)/usr/sbin/rsautil
endef

$(eval $(call BuildPackage,rsautil))
