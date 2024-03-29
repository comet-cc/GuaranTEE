#!/bin/bash

screen lkvm run --realm --irqchip=gicv3 -c 1 -m 300 -k ./Image -i ./rootfs.cpio \
--9p /root/mnt/shared_with_realm,sh --disable-sve --nodefaults
