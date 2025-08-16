#!/bin/bash

# Deployment script for GuildItemScanner WoW addon
# Copies files from source to WoW Classic Era addon directory

SOURCE_DIR="/home/chris/GuildItemScanner"
TARGET_DIR="/home/chris/.var/app/com.usebottles.bottles/data/bottles/bottles/Games/drive_c/Program Files (x86)/World of Warcraft/_classic_era_/Interface/AddOns/GuildItemScanner"

echo "Deploying GuildItemScanner addon..."
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Remove existing files in target directory
if [ -d "$TARGET_DIR" ]; then
    echo "Removing existing files from target directory..."
    rm -rf "$TARGET_DIR"/*
fi

# Copy all files from source to target, excluding the deployment script itself
echo "Copying files..."
rsync -av --exclude='deploy.sh' --exclude='.git' "$SOURCE_DIR/" "$TARGET_DIR/"

echo "Deployment complete!"
echo "Files copied to: $TARGET_DIR"