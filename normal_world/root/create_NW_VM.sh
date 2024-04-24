#!/bin/bash

folder_name="shared_with_realm"
if [ ! -d "$folder_name" ]; then
    mkdir "$folder_name"
fi
screen lkvm run -c 1 -m 300 -k /realm/Image -i /realm/realm-fs.cpio \
--9p /root/shared_with_realm,sh --irqchip=gicv3 --disable-sve
