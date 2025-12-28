#!/bin/bash

# Stop the script if any command fails
set -e 

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

echo ":: ---------------------------------------------------"
echo ":: DOTFILES INSTALLER - RAGA (FINAL V5)"
echo ":: Source: $REPO_DIR"
echo ":: Target: $CONFIG_DIR"
echo ":: Time:   $TIMESTAMP"
echo ":: ---------------------------------------------------"

# Ensure .config exists
mkdir -p "$CONFIG_DIR"

# ==============================================================================
# 1. FUNCTION: REPLACE FULL FOLDER (Fastfetch & Waybar)
# Logic: Backups INSIDE folder | Max 2 Backups
# ==============================================================================
replace_folder() {
    FOLDER_NAME=$1
    echo ":: Processing $FOLDER_NAME..."

    TARGET="$CONFIG_DIR/$FOLDER_NAME"
    SOURCE="$REPO_DIR/$FOLDER_NAME"
    
    BACKUP_ROOT="$TARGET/${FOLDER_NAME}_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE" ]; then
        echo "   [ERROR] Source $SOURCE not found. Skipping."
        return
    fi

    if [ ! -d "$TARGET" ]; then mkdir -p "$TARGET"; fi
    mkdir -p "$BACKUP_ROOT"

    # Collision check
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    # Backup existing content (excluding backup folder itself)
    echo "   -> Backing up existing config..."
    find "$TARGET" -mindepth 1 -maxdepth 1 -not -name "${FOLDER_NAME}_backups" -exec mv {} "$NEW_BACKUP_DIR/" \;
    echo "   [BACKUP] Saved to: ${FOLDER_NAME}_backups/$TIMESTAMP"

    # Clean up: Max 2 backups
    echo "   -> Checking backup limit (Max 2)..."
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    # Copy new content
    cp -r "$SOURCE/." "$TARGET/"
    echo "   [COPY] Installed new $FOLDER_NAME."
    echo "   [OK] $FOLDER_NAME done."
    echo ""
}

# ==============================================================================
# 2. FUNCTION: HYPR (Specific Files Only)
# Logic: Backup specific files | Max 2 Backups
# ==============================================================================
install_hypr() {
    echo ":: Processing Hypr..."
    TARGET="$CONFIG_DIR/hypr"
    SOURCE="$REPO_DIR/hypr"
    BACKUP_ROOT="$TARGET/backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    mkdir -p "$TARGET"
    mkdir -p "$BACKUP_ROOT"

    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    FILES=("hyprlock.conf" "looknfeel.conf")

    for FILE in "${FILES[@]}"; do
        if [ -f "$TARGET/$FILE" ]; then
            mv "$TARGET/$FILE" "$NEW_BACKUP_DIR/"
            echo "   [BACKUP] $FILE moved to backups/$TIMESTAMP"
        fi
        if [ -f "$SOURCE/$FILE" ]; then
            cp "$SOURCE/$FILE" "$TARGET/$FILE"
            echo "   [COPY] $FILE installed."
        fi
    done

    # Clean up: Max 2 backups
    echo "   -> Checking backup limit (Max 2)..."
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    echo "   [OK] Hypr done."
    echo ""
}

# ==============================================================================
# 3. FUNCTION: OMARCHY (Branding Folder Only)
# Logic: Backup branding folder | Max 2 Backups
# ==============================================================================
install_omarchy() {
    echo ":: Processing Omarchy..."
    
    PARENT_DIR="$CONFIG_DIR/omarchy"               
    TARGET_DIR="$PARENT_DIR/branding"              
    SOURCE_DIR="$REPO_DIR/omarchy/branding"        
    BACKUP_ROOT="$PARENT_DIR/branding_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE_DIR" ]; then
        echo "   [ERROR] Source '$SOURCE_DIR' not found."
        return
    fi

    mkdir -p "$PARENT_DIR"
    mkdir -p "$BACKUP_ROOT"

    if [ -d "$TARGET_DIR" ]; then
        if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
        mkdir -p "$NEW_BACKUP_DIR"
        
        mv "$TARGET_DIR" "$NEW_BACKUP_DIR/"
        echo "   [BACKUP] Old branding moved to branding_backups/$TIMESTAMP"
    fi

    # Clean up: Max 2 backups
    echo "   -> Checking backup limit (Max 2)..."
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    cp -r "$SOURCE_DIR" "$PARENT_DIR/"
    
    echo "   [COPY] New branding folder installed."
    echo "   [OK] Omarchy done."
    echo ""
}

# ==============================================================================
# 4. FUNCTION: STARSHIP (Single File Backup)
# Logic: Overwrite previous backup file. No folders.
# ==============================================================================
install_starship() {
    echo ":: Processing Starship..."
    TARGET="$CONFIG_DIR/starship.toml"
    SOURCE="$REPO_DIR/starship/starship.toml"
    
    # Single backup file in root of .config
    BACKUP_FILE="$CONFIG_DIR/starship_backup.toml"

    # Backup: Just move the current file to the backup name (Overwrite if exists)
    if [ -f "$TARGET" ]; then
        mv "$TARGET" "$BACKUP_FILE"
        echo "   [BACKUP] Old config saved to: starship_backup.toml"
    fi

    # Copy new
    cp "$SOURCE" "$TARGET"
    echo "   [COPY] New starship.toml installed."
    echo "   [OK] Starship done."
    echo ""
}

# ==============================================================================
# EXECUTION
# ==============================================================================

replace_folder "fastfetch"
replace_folder "waybar"
install_hypr
install_omarchy
install_starship

echo ":: ---------------------------------------------------"
echo ":: SUCCESS! All dotfiles installed."
echo ":: ---------------------------------------------------"
