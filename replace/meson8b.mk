define Device/Default
  FILESYSTEMS := squashfs ubifs
  IMAGES := emmc.img
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(DEVICE_DTS).dts)
  KERNEL_LOADADDR := 0x01080000
  KERNEL_NAME := uImage
  KERNEL := kernel-bin | uImage none
  PROFILES = Default $$(DEVICE_NAME)
endef

define Device/default-nand
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  MKUBIFS_OPTS := -m $$(PAGESIZE) -e 124KiB -c 2048
endef

define Device/thunder-onecloud
  DEVICE_DTS := meson8b-onecloud
  DEVICE_TITLE := Thunder OneCloud
  KERNEL_LOADADDR := 0x00208000
  IMAGE/emmc.img := boot-script onecloud | emmc-common $$(DEVICE_NAME)
  MKUBIFS_OPTS := --min-io-size=2048 --leb-size=126976 --max-leb-cnt=704
endef
TARGET_DEVICES += thunder-onecloud
