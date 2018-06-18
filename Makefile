# Makefile to build cuscom Ubuntu installer ISO and cloud image

BUILD_DIR:=./build
PATCH_DIR:=./patch
SCRIPT_DIR:=./setup
SRC_DIR_PATH:=$(BUILD_DIR)/src

CLUSTER_JSON:=$(SCRIPT_DIR)/cluster.json

ORIGINAL_ISO_NAME=ubuntu-18.04-server-amd64.iso
ORIGINAL_ISO_URL=http://cdimage.ubuntu.com/releases/18.04/release/$(ORIGINAL_ISO_NAME)
ORIGINAL_ISO_PATH=$(BUILD_DIR)/$(ORIGINAL_ISO_NAME)
CUSTOM_ISO_PATH=$(BUILD_DIR)/cybozu-$(ORIGINAL_ISO_NAME)

ORIGINAL_CLOUD_IMAGE=ubuntu-18.04-server-cloudimg-amd64.img
ORIGINAL_CLOUD_URL=https://cloud-images.ubuntu.com/releases/18.04/release/$(ORIGINAL_CLOUD_IMAGE)
ORIGINAL_CLOUD_PATH=$(BUILD_DIR)/$(ORIGINAL_CLOUD_IMAGE)
CUSTOM_CLOUD_PATH=$(BUILD_DIR)/cybozu-$(ORIGINAL_CLOUD_IMAGE)

RKT_DEB_NAME=rkt_1.30.0-1_amd64.deb
RKT_DEB_URL=https://github.com/rkt/rkt/releases/download/v1.30.0/$(RKT_DEB_NAME)
RKT_DEB_PATH=build/$(RKT_DEB_NAME)

ETCDPASSWD_DEB_NAME=etcdpasswd_0.1-1_amd64.deb
ETCDPASSWD_DEB_PATH=build/$(ETCDPASSWD_DEB_NAME)

DEBS=$(RKT_DEB_PATH) $(ETCDPASSWD_DEB_PATH)

DOCKER2ACI_URL=https://github.com/appc/docker2aci/releases/download/v0.17.2/docker2aci-v0.17.2.tar.gz
DOCKER2ACI=$(BUILD_DIR)/docker2aci

PYTHON3_FILES=$(shell find setup/ -type f | xargs awk '/python3/ {print FILENAME} {nextfile}')
PYLINT3:=pylint

BUILD_DEPS:=xorriso qemu-utils qemu-kvm ovmf curl ca-certificates cloud-image-utils gdisk kpartx python3-pip python3-setuptools
CONTAINERS:=\
	bird:2.0 \
	ubuntu-debug:18.04 \
	etcd:3.3 \
	chrony:3.3 \
	sabakan:0
ACI_FILES=$(patsubst %,build/cybozu-%.aci,$(subst :,-,$(CONTAINERS)))
ARTIFACTS=$(ORIGINAL_ISO_PATH) $(ORIGINAL_CLOUD_PATH) $(RKT_DEB_PATH) $(DOCKER2ACI)
PREVIEW_IMG=$(BUILD_DIR)/ubuntu.img
LOCALDS_IMG=$(BUILD_DIR)/seed.img
CURL=curl -fSL

help:
	@echo "Targets:"
	@echo "    setup         - install packages to build custom images."
	@echo "    all           - build both custom ISO and cloud images."
	@echo "    iso           - build custom Ubuntu server ISO image."
	@echo "    preview-iso   - run QEMU/KVM to test custom ISO image."
	@echo "    cloud         - build custom Ubuntu cloud image."
	@echo "    preview-cloud - run QEMU/KVM to test custom cloud image."
	@echo "    clean         - remove built images."
	@echo "    fullclean     - do clean + remove downloaded artifacts."

all: iso cloud

iso: $(CUSTOM_ISO_PATH)
cloud: $(CUSTOM_CLOUD_PATH)

$(CLUSTER_JSON):
	@echo Create $@, or copy $@.example as $@.
	exit 1

$(ORIGINAL_ISO_PATH):
	$(CURL) -o $@ $(ORIGINAL_ISO_URL)

$(ORIGINAL_CLOUD_PATH):
	$(CURL) -o $@ $(ORIGINAL_CLOUD_URL)

$(RKT_DEB_PATH):
	$(CURL) -o $@ $(RKT_DEB_URL)

etcdpasswd/Makefile:
	@echo "prepare etcdpasswd directory by creating symlink to your repository"
	@echo "    ln -s /path/to/your/etcdpasswd ."
	exit 1

etcdpasswd/$(ETCDPASSWD_DEB_NAME): etcdpasswd/Makefile
	cd etcdpasswd; $(MAKE) clean
	cd etcdpasswd; $(MAKE) setup
	cd etcdpasswd; $(MAKE) deb

$(ETCDPASSWD_DEB_PATH): etcdpasswd/$(ETCDPASSWD_DEB_NAME)
	mv $< $@

$(DOCKER2ACI):
	cd $(BUILD_DIR); $(CURL) $(DOCKER2ACI_URL) | tar -x -z -f - --strip-components=1

%.aci: $(DOCKER2ACI)
	cd $(BUILD_DIR); ./docker2aci $$(echo $@ | sed -r 's,build/cybozu-(.*)-([^-]+).aci,docker://quay.io/cybozu/\1:\2,')
	chmod 644 $@

$(CUSTOM_ISO_PATH): $(ORIGINAL_ISO_PATH) $(DEBS) $(ACI_FILES) $(CLUSTER_JSON)
	rm -rf $(SRC_DIR_PATH)
	mkdir -p $(SRC_DIR_PATH)
	xorriso -osirrox on -indev $(ORIGINAL_ISO_PATH) \
		-extract / $(SRC_DIR_PATH)

	# Patch preseeds
	find $(SRC_DIR_PATH) | xargs chmod u+w
	for f in $$(cd $(PATCH_DIR); find . -type f); do \
		cp -a $(PATCH_DIR)/$$f $(SRC_DIR_PATH)/$$f; \
	done
	cd $(SRC_DIR_PATH); find . -type f -print0 | xargs -0 md5sum > md5sum.txt

	# Add container runtimes
	mkdir -p $(SRC_DIR_PATH)/pool/extras
	cp $(DEBS) $(SRC_DIR_PATH)/pool/extras/
	cp $(ACI_FILES) $(SRC_DIR_PATH)/pool/extras/
	cp -r $(SCRIPT_DIR) $(SRC_DIR_PATH)/pool/extras/

	# Build an ISO file
	xorriso -as mkisofs -r -V "Custom Ubuntu Install CD" \
		-J -l -b isolinux/isolinux.bin \
		-c isolinux/boot.cat -no-emul-boot \
		-e boot/grub/efi.img \
		-eltorito-alt-boot \
		-boot-load-size 4 -boot-info-table \
		-isohybrid-gpt-basdat \
		-o $(CUSTOM_ISO_PATH) $(SRC_DIR_PATH)

preview-iso: $(CUSTOM_ISO_PATH)
	rm -f $(PREVIEW_IMG)
	qemu-img create -f qcow2 $(PREVIEW_IMG) 10G
	sudo kvm -m 2G \
		-bios /usr/share/ovmf/OVMF.fd \
		-drive file=$(PREVIEW_IMG) \
		-drive file=$(CUSTOM_ISO_PATH),media=cdrom

$(CUSTOM_CLOUD_PATH): $(ORIGINAL_CLOUD_PATH) $(DEBS) $(ACI_FILES) $(CLUSTER_JSON)
	cp $< $@
	qemu-img resize $@ 10G
	sudo ./resize-and-copy-in-qcow2 $@ $(DEBS) $(ACI_FILES) $(SCRIPT_DIR)

preview-cloud: $(CUSTOM_CLOUD_PATH)
	rm -f $(PREVIEW_IMG) $(LOCALDS_IMG)
	cloud-localds $(LOCALDS_IMG) cybozu.seed
	cp $(CUSTOM_CLOUD_PATH) $(PREVIEW_IMG)
	sudo kvm -m 2G -net nic -net nic \
		-drive file=$(PREVIEW_IMG) \
		-drive file=$(LOCALDS_IMG),format=raw

lint:
	$(PYLINT3) --rcfile=.pylint -d missing-docstring -d duplicate-code -f colorized $(PYTHON3_FILES)

clean:
	rm -rf $(CUSTOM_ISO_PATH) \
		$(CUSTOM_CLOUD_PATH) \
		$(ETCDPASSWD_DEB_PATH) \
		$(SRC_DIR_PATH) $(PREVIEW_IMG) $(LOCALDS_IMG)

fullclean: clean
	rm -f $(ACI_FILES) $(ARTIFACTS)

setup:
	pip3 install pylint
	sudo apt-get -y install --no-install-recommends $(BUILD_DEPS)

.PHONY: help all iso cloud preview-iso preview-cloud lint clean fullclean setup
