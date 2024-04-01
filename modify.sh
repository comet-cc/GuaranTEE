#!/bin/bash

GuaranTEE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Replace our build-buildroot.sh script with the original to apply our changes into file systems of realm and hypervisor
cp ${GuaranTEE_DIR}/build-buildroot.sh ${GuaranTEE_DIR}/../build-scripts/build-buildroot.sh

# Remove a line in the linux build scripts which does not allow to create the stack for more that one time
SCRIPT="${GuaranTEE_DIR}/../build-scripts/build-linux.sh"
PATTERN="git apply --ignore-space-change --whitespace=warn --inaccurate-eof -v \$LINUX_CMD_LINE_EXTEND_PATCH"
sed -i "/${PATTERN}/d" "${SCRIPT}"

