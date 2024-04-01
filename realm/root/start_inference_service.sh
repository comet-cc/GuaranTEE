#!/bin/bash

folder_name="shared_with_realm"

if [ ! -d "$folder_name" ]; then
   mkdir "$folder_name"
fi
mount -t 9p sh /root/shared_with_realm
/root/realm_inference -l /root/labels.txt -m /root/mobilenet_v1_1.0_224.tflite -x 1 > /root/shared_with_realm/output.txt 2>&1 &
