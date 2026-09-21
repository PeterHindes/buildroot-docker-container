################################################################################
#
# network-app
#
################################################################################

NETWORK_APP_VERSION = 1.0.0
NETWORK_APP_SITE = $(BR2_EXTERNAL_NETWORK_PROJECT_PATH)/../app
NETWORK_APP_SITE_METHOD = local

NETWORK_APP_INSTALL_TARGET_CMDS =
	$(INSTALL) -D -m 0755 $(@D)/network-app $(TARGET_DIR)/usr/bin/network-app

define NETWORK_APP_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		$(NETWORK_APP_SITE)/src/main.c \
		-o $(@D)/network-app
endef

$(eval $(generic-package))
