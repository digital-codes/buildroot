################################################################################
#
# sysvinit
#
################################################################################

SYSVINIT_VERSION = 3.14
SYSVINIT_SOURCE = sysvinit-$(SYSVINIT_VERSION).tar.xz
SYSVINIT_SITE = https://github.com/slicer69/sysvinit/releases/download/$(SYSVINIT_VERSION)
SYSVINIT_LICENSE = GPL-2.0+
SYSVINIT_LICENSE_FILES = COPYING
SYSVINIT_CPE_ID_VALID = YES

SYSVINIT_MAKE_OPTS = SYSROOT=$(STAGING_DIR) VERSION=$(SYSVINIT_VERSION)

ifeq ($(BR2_PACKAGE_LIBSELINUX),y)
SYSVINIT_DEPENDENCIES += libselinux
SYSVINIT_MAKE_OPTS += WITH_SELINUX="yes"
endif

ifeq ($(BR2_PACKAGE_LIBXCRYPT),y)
SYSVINIT_DEPENDENCIES += libxcrypt
endif

define SYSVINIT_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) $(SYSVINIT_MAKE_OPTS) -C $(@D)/src
endef

define SYSVINIT_INSTALL_TARGET_CMDS
	for x in halt init shutdown killall5; do \
		$(INSTALL) -D -m 0755 $(@D)/src/$$x $(TARGET_DIR)/sbin/$$x || exit 1; \
	done
	$(INSTALL) -D -m 0644 package/sysvinit/inittab $(TARGET_DIR)/etc/inittab
	ln -sf /sbin/halt $(TARGET_DIR)/sbin/reboot
	ln -sf /sbin/halt $(TARGET_DIR)/sbin/poweroff
	ln -sf killall5 $(TARGET_DIR)/sbin/pidof
endef

ifeq ($(BR2_TARGET_GENERIC_GETTY),y)
define SYSVINIT_SET_GETTY
	$(SED) '/# GENERIC_SERIAL$$/s~^.*#~$(shell echo $(SYSTEM_GETTY_PORT) | tail -c+4)::respawn:/sbin/getty -L $(SYSTEM_GETTY_OPTIONS) $(SYSTEM_GETTY_PORT) $(SYSTEM_GETTY_BAUDRATE) $(SYSTEM_GETTY_TERM) #~' \
		$(TARGET_DIR)/etc/inittab
endef
else
define SYSVINIT_SET_GETTY
	$(SED) '/# GENERIC_SERIAL$$/s~^.*#~# S0:1:respawn:/sbin/getty -L ttyS0 115200 vt100 #~' \
		$(TARGET_DIR)/etc/inittab
endef
endif # BR2_TARGET_GENERIC_GETTY
SYSVINIT_TARGET_FINALIZE_HOOKS += SYSVINIT_SET_GETTY

SYSVINIT_TARGET_FINALIZE_HOOKS += SYSTEM_REMOUNT_ROOT_INITTAB

$(eval $(generic-package))
