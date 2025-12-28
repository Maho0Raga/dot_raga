#!/bin/bash

# Disable immediate exit to handle UI gracefully
set +e 

# --- 🎨 VIBRANT COLOR PALETTE ---
R='\033[1;31m'    # Red
G='\033[1;32m'    # Green
B='\033[1;34m'    # Blue
Y='\033[1;33m'    # Yellow
C='\033[1;36m'    # Cyan
M='\033[1;35m'    # Purple
W='\033[1;37m'    # White
D='\033[0;90m'    # Grey
RESET='\033[0m'

# --- ⚙️ CONFIG ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

# --- 🎬 VISUAL ENGINE ---

# 1. Classic NPM-Style Spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -ne "  "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${C}%c${RESET} ${D}Working...${RESET}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r  "
    done
    printf "\r\033[K" # Clear the line after finishing
}

# 2. Section Headers
print_step() {
    echo -e "\n${C}⚡ PROCESSING:${RESET} ${W}$1${RESET}"
    echo -e "${D}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# 3. ASCII Header
show_header() {
    clear
    echo -e "${M}"
    echo "  ██████╗  █████╗  ██████╗  █████╗ "
    echo "  ██╔══██╗██╔══██╗██╔════╝ ██╔══██╗"
    echo "  ██████╔╝███████║██║  ███╗███████║"
    echo "  ██╔══██╗██╔══██║██║   ██║██╔══██║"
    echo "  ██║  ██║██║  ██║╚██████╔╝██║  ██║"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${RESET}"
    echo -e "   ${C}:: RAGA ULTIMATE INSTALLER ::${RESET}"
    echo -e "   ${D}--------------------------------${RESET}"
    echo -e "   ${W}📅 Time:${RESET}   $TIMESTAMP"
    echo -e "   ${W}📂 Source:${RESET} $REPO_DIR"
    echo -e "   ${W}🎯 Target:${RESET} $CONFIG_DIR"
    echo -e "   ${D}--------------------------------${RESET}\n"
}

# 4. Status Messages
msg_ask()  { echo -ne "${Y}❓ $1 ${W}[y/N]${RESET}: "; }
msg_ok()   { echo -e "   ${G}✔  DONE:${RESET} $1"; }
msg_back() { echo -e "   ${M}📦 BACKUP:${RESET} $1"; }
msg_err()  { echo -e "   ${R}✖  ERROR:${RESET} $1"; }

# 5. Confirmation
confirm() {
    msg_ask "$1"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then return 0; else return 1; fi
}

# ==============================================================================
# 🧩 LOGIC: REPLACE FOLDER (Waybar & Fastfetch)
# ==============================================================================
replace_folder() {
    NAME=$1
    print_step "${NAME^^}"

    TARGET="$CONFIG_DIR/$NAME"
    SOURCE="$REPO_DIR/$NAME"
    BACKUP_ROOT="$TARGET/${NAME}_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE" ]; then msg_err "Source not found!"; return; fi

    mkdir -p "$TARGET" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    # Start Spinner
    sleep 0.7 & spinner $!

    # 1. Backup
    find "$TARGET" -mindepth 1 -maxdepth 1 -not -name "${NAME}_backups" -exec mv {} "$NEW_BACKUP_DIR/" \; 2>/dev/null
    msg_back "Old files moved to ${NAME}_backups/"

    # 2. Cleanup (Max 2)
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")

    # 3. Copy
    cp -r "$SOURCE/." "$TARGET/"
    msg_ok "Installed new $NAME configuration."
}

# ==============================================================================
# 🧩 LOGIC: HYPR
# ==============================================================================
install_hypr() {
    print_step "HYPRLAND"
    TARGET="$CONFIG_DIR/hypr"
    SOURCE="$REPO_DIR/hypr"
    BACKUP_ROOT="$TARGET/backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    mkdir -p "$TARGET" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    sleep 0.7 & spinner $!

    FILES=("hyprlock.conf" "looknfeel.conf")
    for FILE in "${FILES[@]}"; do
        if [ -f "$TARGET/$FILE" ]; then mv "$TARGET/$FILE" "$NEW_BACKUP_DIR/"; fi
        if [ -f "$SOURCE/$FILE" ]; then cp "$SOURCE/$FILE" "$TARGET/$FILE"; fi
    done
    
    msg_back "Configs archived in backups/"
    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")
    msg_ok "Hyprland visual configs updated."
}

# ==============================================================================
# 🧩 LOGIC: OMARCHY
# ==============================================================================
install_omarchy() {
    print_step "SCREENSAVER"
    PARENT="$CONFIG_DIR/omarchy"
    TARGET="$PARENT/branding"
    SOURCE="$REPO_DIR/omarchy/branding"
    BACKUP_ROOT="$PARENT/branding_backups"
    NEW_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ ! -d "$SOURCE" ]; then msg_err "Omarchy source missing!"; return; fi

    mkdir -p "$PARENT" "$BACKUP_ROOT"
    if [ -d "$NEW_BACKUP_DIR" ]; then rm -rf "$NEW_BACKUP_DIR"; fi
    mkdir -p "$NEW_BACKUP_DIR"

    sleep 0.7 & spinner $!

    if [ -d "$TARGET" ]; then
        mv "$TARGET" "$NEW_BACKUP_DIR/"
        msg_back "Old branding backed up."
    fi

    (cd "$BACKUP_ROOT" && ls -dt */ 2>/dev/null | tail -n +3 | xargs -I {} rm -rf "{}")
    cp -r "$SOURCE" "$PARENT/"
    msg_ok "New RAGA Screensaver text installed."
}

# ==============================================================================
# 🧩 LOGIC: STARSHIP
# ==============================================================================
install_starship() {
    print_step "STARSHIP"
    TARGET="$CONFIG_DIR/starship.toml"
    SOURCE="$REPO_DIR/starship/starship.toml"
    BACKUP="$CONFIG_DIR/starship_backup.toml"

    sleep 0.7 & spinner $!

    if [ -f "$TARGET" ]; then
        mv "$TARGET" "$BACKUP"
        msg_back "Created starship_backup.toml"
    fi

    cp "$SOURCE" "$TARGET"
    msg_ok "Starship prompt is now active."
}


# ==============================================================================
# 🚀 MAIN EXECUTION
# ==============================================================================

show_header

# 1. Waybar
if confirm "💻 Install Raga's Waybar?"; then
    replace_folder "waybar"
else
    echo -e "   ${D}Skipped Waybar.${RESET}"
fi

# 2. Fastfetch
if confirm "🚀 Install Raga's Fastfetch?"; then
    replace_folder "fastfetch"
else
    echo -e "   ${D}Skipped Fastfetch.${RESET}"
fi

# 3. Hypr
if confirm "🎨 Update Hyprland Look & Lock?"; then
    install_hypr
else
    echo -e "   ${D}Skipped Hyprland.${RESET}"
fi

# 4. Omarchy
if confirm "✨ Install Custom Screensaver Text?"; then
    install_omarchy
else
    echo -e "   ${D}Skipped Screensaver.${RESET}"
fi

# 5. Starship
if confirm "🪐 Install Starship Shell Prompt?"; then
    install_starship
else
    echo -e "   ${D}Skipped Starship.${RESET}"
fi

echo -e "\n${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "   ${W}✨  RAGA INSTALLATION COMPLETE SUCCESSFULLY!  ✨${RESET}"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
