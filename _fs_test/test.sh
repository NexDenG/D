#!/usr/bin/env bash

set -e

# Define the mount directory
MOUNT_DIR=./fs_test

# Ensure the mount directory exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "Mount directory $MOUNT_DIR does not exist."
    exit 1
fi

# Function to verify if a file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "Error: File $1 does not exist."
        exit 1
    fi
}

# Function to verify if a directory exists
check_dir_exists() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory $1 does not exist."
        exit 1
    fi
}

# Test operations
echo "Starting test operations..."

# 1. Copy a file
echo "Copying a file..."
echo "hello 1234" > testfile.txt
cp testfile.txt $MOUNT_DIR/testfile.txt
cmp testfile.txt $MOUNT_DIR/testfile.txt && echo "File copied successfully." || { echo "File copy failed."; exit 1; }
rm testfile.txt

# 2. Move a file
echo "Moving a file..."
mv $MOUNT_DIR/testfile.txt $MOUNT_DIR/moved_testfile.txt
check_file_exists "$MOUNT_DIR/moved_testfile.txt" && echo "File moved successfully." || { echo "File move failed."; exit 1; }
rm $MOUNT_DIR/moved_testfile.txt

# 3. Move a directory
echo "Moving a directory..."
mkdir -p testdir/subdir
mv testdir $MOUNT_DIR/
check_dir_exists "$MOUNT_DIR/testdir" && echo "Directory moved successfully." || { echo "Directory move failed."; exit 1; }

# 4. Create a directory
echo "Creating a directory..."
mkdir $MOUNT_DIR/newdir
check_dir_exists "$MOUNT_DIR/newdir" && echo "Directory created successfully." || { echo "Directory creation failed."; exit 1; }

# 5. Create a nested directory structure
echo "Creating nested directories..."
mkdir -p $MOUNT_DIR/nesteddir/innerdir
check_dir_exists "$MOUNT_DIR/nesteddir/innerdir" && echo "Nested directories created successfully." || { echo "Nested directory creation failed."; exit 1; }

# 6. Remove a directory
echo "Removing a single directory..."
rmdir $MOUNT_DIR/newdir
[ ! -d "$MOUNT_DIR/newdir" ] && echo "Directory removed successfully." || { echo "Directory removal failed."; exit 1; }

# 7. Remove directories and files recursively
echo "Removing directories and files recursively..."
rm -rf $MOUNT_DIR/nesteddir
[ ! -d "$MOUNT_DIR/nesteddir" ] && echo "Recursive removal successful." || { echo "Recursive removal failed."; exit 1; }

##################################################
echo "Creating nested directories for testing..."
mkdir -p $MOUNT_DIR/subdir1/nestsubdir1/nestsubdir2
mkdir -p $MOUNT_DIR/subdir2/nestsubdir1/nestsubdir2

# 8. Move a nested directory where a directory with the same name already exists
echo "Case 1: Moving nested directory to a location where same name directory exists..."
if mv $MOUNT_DIR/subdir1/nestsubdir1 $MOUNT_DIR/subdir2/ 2>/dev/null; then
    echo "Unexpected success: Directory move should have failed."
    exit 1
else
    echo "Expected failure: Directory move failed as expected."
fi

# 9. Move a nested directory into a deeper level of another directory structure
echo "Case 2: Moving nested directory into a deeper directory structure..."
mv $MOUNT_DIR/subdir1/nestsubdir1 $MOUNT_DIR/subdir2/nestsubdir2/
check_dir_exists "$MOUNT_DIR/subdir2/nestsubdir2/nestsubdir2"
rm -rf $MOUNT_DIR/subdir1 $MOUNT_DIR/subdir2 $MOUNT_DIR/testdir

echo "Test operations completed."

# End of script
