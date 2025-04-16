#!/usr/bin/env bash

MOUNT_DIR=./fs_test
FTP_HOST=localhost
FTP_PORT=2525
FTP_USER=username
FTP_PASSWORD=Cvw89IJmDNPdILj91XZHxMRGjIMClnKn

# Function to unmount and perform cleanup
cleanup() {
    echo "Caught Ctrl+C, unmounting..."
    sudo umount -l $MOUNT_DIR
    rmdir $MOUNT_DIR
    exit 0
}

# Trap SIGINT (Ctrl+C) and call the cleanup function
trap cleanup SIGINT

mkdir -p $MOUNT_DIR

rclone mount :ftp: --ftp-host=$FTP_HOST --ftp-port=$FTP_PORT --ftp-user=$FTP_USER --ftp-pass=$FTP_PASSWORD $MOUNT_DIR