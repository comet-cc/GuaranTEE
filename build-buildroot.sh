#!/usr/bin/env bash

# Copyright (c) 2023, ARM Limited and Contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither the name of ARM nor the names of its contributors may be used
# to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# This script uses the following environment variables from the variant
#
# BUILDROOT_PATH - Directory containing the buildroot source
# LINUX_PATH - Directory containing the linux source
# BUILDROOT_GCC_PATH - Path where the compiler is installed
# VARIANT_LINUX_GNU - The compiler variant
# BUILDROOT_CONFIG_FILE - Path of the configuration file used to build
# OUTPUT_DIR - Directory where build products are stored
#

do_build ()
{
	echo
	echo -e "${GREEN}Building Buildroot for $PLATFORM on [`date`]${NORMAL}"
	echo

	pushd $BUILDROOT_PATH
	# Set Compiler
	export CROSS_COMPILE=$BUILDROOT_CROSS_COMPILE
	export PATH=$BUILDROOT_GCC_PATH:$PATH

	# Build realm-fs

	# Replace out buildroot config file with the original one
	cp $DIR/../GuaranTEE/realm-buildroot-config .config
	# Overlay our realm folder into the realm file system
#	 ./utils/config --set-val BR2_TARGET_ROOTFS_EXT2_SIZE "\"200M\""
	./utils/config --set-val BR2_ROOTFS_OVERLAY "\"${ROOTFS_OVERLAY} ${DIR}/../GuaranTEE/realm/\""
	make oldconfig
	make BR2_JLEVEL=$PARALLELISM

	# Build host-fs
	# Prepare overlay for realm (filesystem+kernel)
	mkdir -p $PWD/tmp_realm_overlay/realm
	cp $BUILDROOT_PATH/output/images/rootfs.ext4 ./tmp_realm_overlay/realm/realm-fs.ext4
	cp $BUILDROOT_PATH/output/images/rootfs.cpio ./tmp_realm_overlay/realm/realm-fs.cpio
	e2fsck -fp ./tmp_realm_overlay/realm/realm-fs.ext4
#	resize2fs ./tmp_realm_overlay/realm/realm-fs.ext4 300M
	cp $LINUX_PATH/arch/arm64/boot/Image ./tmp_realm_overlay/realm/.
	make clean
	# Copy networking utils.
	mkdir -p $PWD/tmp_realm_overlay/realm/utils
	cp ${GUEST_NETWORK_UTILS}/* $PWD/tmp_realm_overlay/realm/utils/

	# Prepare overlay for kvm-unit-tests
	mkdir -p $PWD/tmp_kvm_overlay/
	cp -R $KVM_UNIT_TESTS_PATH ./tmp_kvm_overlay/.

	# Enable build of KvmTool & set up the path
	cp ${BUILDROOT_CONFIG_FILE} .config
	sed -i 's/#\sBR2_PACKAGE_KVMTOOL\sis\snot\sset/BR2_PACKAGE_KVMTOOL=y/' .config
	echo "KVMTOOL_OVERRIDE_SRCDIR = ${KVM_TOOL_PATH}" > local.mk
	# Set the overlays needed on the host-fs
	./utils/config --set-val BR2_ROOTFS_OVERLAY "\"${ROOTFS_OVERLAY} $PWD/tmp_realm_overlay $PWD/tmp_kvm_overlay ${DIR}/../GuaranTEE/normal_world/\""
	./utils/config --set-val BR2_PACKAGE_SCREEN "y"
	./utils/config --set-val BR2_TARGET_ROOTFS_EXT2_SIZE "\"1024M\""
	make oldconfig
	make -j$PARALLELISM kvmtool-rebuild
	make BR2_JLEVEL=$PARALLELISM

	# Remove the temporary overlays
	rm -rf $PWD/tmp_realm_overlay
	rm -rf $PWD/tmp_kvm_overlay
	popd
}

do_clean ()
{
	echo
	echo -e "${GREEN}Cleaning Buildroot for $PLATFORM on [`date`]${NORMAL}"
	echo

	pushd $BUILDROOT_PATH
	make clean

	# Remove the temporary overlays if they are left in from previous incompelte builds
	rm -rf $PWD/tmp_realm_overlay
	rm -rf $PWD/tmp_kvm_overlay
	popd
}

do_package ()
{
	echo
	echo -e "${GREEN}Packing Buildroot for $PLATFORM on [`date`]${NORMAL}"
	echo

	cp $BUILDROOT_PATH/output/images/rootfs.ext4 $OUTPUT_PLATFORM_DIR/host-fs.ext4
}


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/framework.sh $@
