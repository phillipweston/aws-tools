#!/bin/bash

for i in `sudo fdisk -l |grep Disk |grep bytes |awk '{print $2}' |awk -F ':' '{print $1}'`; do sudo resize2fs $i; done
