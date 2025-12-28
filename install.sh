#!/bin/bash

# Disable immediate exit to handle UI gracefully
set +e 

# --- 🎨 VIBRANT COLOR PALETTE ---
# Bold and Bright
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
NC='\033[0m' # No Color

# --- ⚙️ CONFIG ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

# --- 🎬 VISUAL FX FUNCTIONS ---

# 1. Smooth Spinner Animation
spinner() {
    local pid=$1
    local delay=0.08
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    echo -ne "  "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${PURPLE}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    printf " \b\b"
}

# 2. Fake Progress Bar
progress_bar() {
    echo -ne "  ${CYAN}[${NC}"
    for i in {1..20}; do
        echo -ne "${CYAN}▓${NC}"
        sleep 0.02
    done
    echo -e "${CYAN}]${NC} ${GREEN}100%${NC}"
}

# 3. The Banner
show_header() {
    clear
    echo -e "${PURPLE}"
    echo "  ██████╗  ██████╗ ████████╗    ██████╗  █████╗  ██████╗  █████╗ "
    echo "  ██╔══██╗██╔═══██╗╚══██╔══╝    ██╔══██╗██╔══██╗██╔════╝ ██╔══██╗"
    echo "  ██║  ██║██║   ██║   ██║       ██████╔╝███████║██║  ███╗███████║"
    echo "  ██║  ██║██║   ██║   ██║       ██╔══██╗██╔══██║██║   ██║██╔══██║"
    echo "  ██████╔╝╚██████╔╝   ██║       ██║  ██║██║  ██║╚██████╔╝██║  ██║"
    echo "  ╚═════╝  ╚═════╝    ╚═╝       ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}:: 🧬 THE ULTIMATE DOTFILES INSTALLER ::${NC}"
    echo -e "  ${GREY}----------------------------------------${NC}"
    echo -e "  ⌚ ${WHITE}Time:${NC}   $TIMESTAMP"
    echo -e "  📂 ${WHITE}Source:${NC} $REPO_DIR"
    echo -e "  🎯 ${WHITE}Target:${NC} $CONFIG_DIR"
    echo -e "  ${GREY}----------------------------------------${NC}\n"
}

# 4. Helpers
ask() { echo -ne "${YELLOW}🔮 $1 ${WHITE}[y/N]: ${NC}"; }
success() { echo -e "  ${GREEN}🔥 SUCCESS:${NC} $1"; }
info() { echo -e "  ${BLUE}🔹 INFO:${NC}    $1"; }
backup() { echo -e "  ${PURPLE}📦 BACKUP:${NC}  $1"; }
error() { echo -e "  ${RED}💀 ERROR:${NC}   $1"; }

confirm() {
    ask "$1"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then return 0; else return 1; fi
}

# ==============================================================================
# 🧩 LOGIC: REPLACE FOLDER (Waybar/Fastfetch)
# ==============================================================================
replace_folder() {
    NAME=$1
    echo -e "\n${WHITE}:: 🧬 Processing ${CYAN}$NAME${WHITE}...${NC}"

    TARGET="$CONFIG_DIR/$NAME"
    SOURCE="$REPO_DIR/$NAME"
    BACKUP_ROOT="$TARGET/${NAME}_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE" ]; then error "Source not found!"; return; fi

    mkdir -p "$TARGET" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    # Animation
    sleep 0.5 & spinner $!

    # 1. Backup
    find "$TARGET" -mindepth 1 -maxdepth 1 -not -name "${NAME}_backups" -exec mv {} "$NEW_BACKUP_DIR/" \; 2>/dev/null
    backup "Archived to ${NAME}_backups/..."

    # 2. Cleanup (Max 2)
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    # 3. Copy with bar
    progress_bar
    cp -r "$SOURCE/." "$TARGET/"
    success "New $NAME installed successfully."
}

# ==============================================================================
# 🧩 LOGIC: HYPR (Files Only)
# ==============================================================================
install_hypr() {
    echo -e "\n${WHITE}:: ⚙️  Processing ${CYAN}Hyprland${WHITE}...${NC}"
    TARGET="$CONFIG_DIR/hypr"
    SOURCE="$REPO_DIR/hypr"
    BACKUP_ROOT="$TARGET/backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    mkdir -p "$TARGET" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    sleep 0.5 & spinner $!

    FILES=("hyprlock.conf" "looknfeel.conf")

    for FILE in "${FILES[@]}"; do
        # Backup
        if [ -f "$TARGET/$FILE" ]; then
            mv "$TARGET/$FILE" "$NEW_BACKUP_DIR/"
        fi
        # Copy
        if [ -f "$SOURCE/$FILE" ]; then
            cp "$SOURCE/$FILE" "$TARGET/$FILE"
        fi
    done
    
    backup "Old configs moved to backups/"
    
    # Cleanup (Max 2)
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")
    
    progress_bar
    success "Updated Hyprland Look & Lock."
}

# ==============================================================================
# 🧩 LOGIC: OMARCHY (Branding)
# ==============================================================================
install_omarchy() {
    echo -e "\n${WHITE}:: 🎨 Processing ${CYAN}Screensaver Text${WHITE}...${NC}"
    PARENT="$CONFIG_DIR/omarchy"
    TARGET="$PARENT/branding"
    SOURCE="$REPO_DIR/omarchy/branding"
    BACKUP_ROOT="$PARENT/branding_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE" ]; then error "Source missing!"; return; fi

    mkdir -p "$PARENT" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    sleep 0.5 & spinner $!

    if [ -d "$TARGET" ]; then
        mv "$TARGET" "$NEW_BACKUP_DIR/"
        backup "Old branding archived."
    fi

    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    progress_bar
    cp -r "$SOURCE" "$PARENT/"
    success "DOT_RAGA Screensaver Applied."
}

# ==============================================================================
# 🧩 LOGIC: STARSHIP (Single File)
# ==============================================================================
install_starship() {
    echo -e "\n${WHITE}:: 🚀 Processing ${CYAN}Starship${WHITE}...${NC}"
    TARGET="$CONFIG_DIR/starship.toml"
    SOURCE="$REPO_DIR/starship/starship.toml"
    BACKUP="$CONFIG_DIR/starship_backup.toml"

    sleep 0.5 & spinner $!

    if [ -f "$TARGET" ]; then
        mv "$TARGET" "$BACKUP"
        backup "Overwrote starship_backup.toml"
    fi

    progress_bar
    cp "$SOURCE" "$TARGET"
    success "Starship prompt locked and loaded."
}


# ==============================================================================
# 🚀 MAIN LOOP
# ==============================================================================

show_header

# 1. Waybar
if confirm "Install DOT_RAGA Waybar Config?"; then
    replace_folder "waybar"
else
    echo -e "  ${GREY}✖ Skipped Waybar.${NC}"
fi

# 2. Fastfetch
if confirm "Install DOT_RAGA Fastfetch?"; then
    replace_folder "fastfetch"
else
    echo -e "  ${GREY}✖ Skipped Fastfetch.${NC}"
fi

# 3. Hypr
if confirm "Update Hyprland (Lock & Look)?"; then
    install_hypr
else
    echo -e "  ${GREY}✖ Skipped Hyprland.${NC}"
fi

# 4. Omarchy
if confirm "Apply Custom Screensaver Text Effect?"; then
    install_omarchy
else
    echo -e "  ${GREY}✖ Skipped Screensaver.${NC}"
fi

# 5. Starship
if confirm "Install Starship Shell Prompt?"; then
    install_starship
else
    echo -e "  ${GREY}✖ Skipped Starship.${NC}"
fi

echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN} 🛸  DOT_RAGA INSTALLATION COMPLETE!  🛸 ${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
