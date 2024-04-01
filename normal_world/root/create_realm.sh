#!/bin/bash

screen lkvm run --realm -c 1 -m 300 -k /realm/Image -d /realm/realm-fs.ext4 \
--9p /root/shared_with_realm,sh -p earlycon  --irqchip=gicv3 --disable-sve
