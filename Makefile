#  Copyright (c) 2025, Lawrence Berkeley National Laboratory.  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#  THIS SOFTWARE IS PROVIDED BY LAWRENCE BERKELEY NATIONAL LABORATORY "AS IS" AND ANY EXPRESS
#  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

# Products
k8s: base overlay-packages overlay-k8s overlay-mofed overlay-ceph cleanup
generic: base overlay-packages cleanup
node: base overlay-packages overlay-mofed overlay-ceph cleanup

# Layers
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