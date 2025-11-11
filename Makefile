.PHONY: all
BUILDDIR    := /var/chroots
GITVERS     := $(shell git describe --always)
TAG         ?= $(firstword $(MAKECMDGOALS))
VNFSNAME    := uvnfs
CHROOTDIR   := $(BUILDDIR)/$(VNFSNAME)-$(TAG)-$(GITVERS)
KERNEL_VER  := 6.8.0-79-generic
APPTAINER_BUILD	:= sudo apptainer build --build-arg-file=env-vars --warn-unused-build-args


all:
	@ echo "Select a make target: generic, mofed, mofed-cuda, mofed-cuda-lustre, mofed-lustre"

k8s: base overlay-packages overlay-k8s overlay-mofed overlay-ceph cleanup

base:
	${APPTAINER_BUILD} --force -s $(CHROOTDIR) $(VNFSNAME)-base.def

overlay-ceph: overlay-packages
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-ceph.def

overlay-kernel: base
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-kernel.def

overlay-packages: overlay-kernel
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-packages.def

overlay-containers: overlay-packages
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-containers.def

overlay-k8s: overlay-packages
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-k8s.def

overlay-mofed: overlay-kernel
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-mofed.def

cleanup:
	${APPTAINER_BUILD} -s -u $(CHROOTDIR) $(VNFSNAME)-cleanup.def
	echo $(GITVERS) > $(CHROOTDIR)/.vnfsbuild


vnfs:
	sudo wwvnfs -c $(CHROOTDIR) $(VNFSNAME)-$(TAG)

bootstrap:
	sudo wwbootstrap -c $(CHROOTDIR) $(KERNEL_VER)