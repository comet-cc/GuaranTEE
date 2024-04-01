#!/bin/bash

folder_name="shared_with_realm"
if [ ! -d "$folder_name" ]; then
    mkdir "$folder_name"
fi
screen lkvm run --realm -c 1 -m 300 -k /realm/Image -d /realm/realm-fs.ext4 \
--9p /root/shared_with_realm,sh -p earlycon  --irqchip=gicv3 --disable-sve
