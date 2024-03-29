#!/bin/bash

./label_image -l ./labels.txt -m ./mobilenet_v1_1.0_224.tflite -x 1 > /root/mnt/shared_with_realm/output.txt 2>&1 &
