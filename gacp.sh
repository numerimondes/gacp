#!/bin/bash
GACP_VERSION="0.0.5"

# Constants
readonly GACP_REPO_URL="https://raw.githubusercontent.com/numerimondes/gacp/main/gacp.sh"
readonly GACP_INSTALL_DIR="$HOME/.gacp"
readonly GACP_SCRIPT_PATH="$GACP_INSTALL_DIR/gacp.sh"

# Color constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_error() {
    echo -e "${RED}error:${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}success:${NC} $1"
}

log_info() {
    echo -e "${BLUE}info:${NC} $1"
}

show_help() {
    echo "gacp v$GACP_VERSION - Git Add Commit Push"
    echo "A one-word command from Heaven for your terminal that saves you time"
    echo ""
    echo "Usage: gacp [OPTION]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -v, --version      Show version and check for updates"
    echo "  --update-now       Update gacp to the latest version"
    echo ""
}

get_remote_version() {
    local remote_version
    # Force fresh download with multiple cache-busting headers
    remote_version=$(curl -s \
        -H 'Cache-Control: no-cache, no-store, must-revalidate' \
        -H 'Pragma: no-cache' \
        -H 'Expires: 0' \
        "$GACP_REPO_URL?$(date +%s)" | head -n 5 | grep -E "^GACP_VERSION=" | cut -d'"' -f2 2>/dev/null)
    echo "$remote_version"
}

version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

check_for_updates() {
    local remote_version
    remote_version=$(get_remote_version)
    
    if [[ -z "$remote_version" ]]; then
        log_info "Could not check for updates"
        return 1
    fi
    
    if version_gt "$remote_version" "$GACP_VERSION"; then
        echo -e "${YELLOW}Update available: v$GACP_VERSION -> v$remote_version${NC}"
        echo -n "Update now? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            update_gacp "$remote_version"
        else
            log_info "Update canceled"
        fi
    else
        log_info "gacp is up to date (v$GACP_VERSION)"
    fi
}

update_gacp() {
    local new_version="$1"
    
    log_info "Updating gacp v$GACP_VERSION -> v$new_version..."
    
    # Remove old installation
    if [[ -f "$GACP_SCRIPT_PATH" ]]; then
        rm -f "$GACP_SCRIPT_PATH"
    fi
    
    # Remove from shell config files
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    if [[ -f "$bashrc_file" ]] && grep -q "source.*gacp.sh" "$bashrc_file"; then
        sed -i '/source.*gacp\.sh/d' "$bashrc_file"
    fi
    
    if [[ -f "$zshrc_file" ]] && grep -q "source.*gacp.sh" "$zshrc_file"; then
        sed -i '/source.*gacp\.sh/d' "$zshrc_file"
    fi
    
    # Fresh installation with cache-busting
    local temp_file
    temp_file=$(mktemp)
    
    if ! curl -s \
        -H 'Cache-Control: no-cache, no-store, must-revalidate' \
        -H 'Pragma: no-cache' \
        -H 'Expires: 0' \
        "$GACP_REPO_URL?$(date +%s)" -o "$temp_file"; then
        log_error "Failed to download update"
        rm -f "$temp_file"
        return 1
    fi
    
    if ! mkdir -p "$GACP_INSTALL_DIR"; then
        log_error "Failed to create installation directory"
        rm -f "$temp_file"
        return 1
    fi
    
    if ! cp "$temp_file" "$GACP_SCRIPT_PATH"; then
        log_error "Failed to copy updated script"
        rm -f "$temp_file"
        return 1
    fi
    
    chmod +x "$GACP_SCRIPT_PATH"
    
    # Add to shell config files
    local source_line="source $GACP_SCRIPT_PATH"
    
    if [[ -f "$bashrc_file" ]]; then
        echo "$source_line" >> "$bashrc_file"
    fi
    
    if [[ -f "$zshrc_file" ]]; then
        echo "$source_line" >> "$zshrc_file"
    fi
    
    log_success "Updated to v$new_version"
    echo -e "${YELLOW}warning:${NC} This shell is still running v$GACP_VERSION"
    echo -n "Restart shell now? (Y/n): "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}info:${NC} Run 'exec \$SHELL' when ready"
    else
        echo -e "${BLUE}info:${NC} Restarting shell..."
        exec $SHELL
    fi
    
    rm -f "$temp_file"
}

install_gacp() {
    local install_dir="$GACP_INSTALL_DIR"
    local gacp_file="$GACP_SCRIPT_PATH"
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    log_info "Installing gacp..."
    
    mkdir -p "$install_dir"
    
    if [[ "$0" != "$gacp_file" ]]; then
        if ! cp "$0" "$gacp_file" 2>/dev/null; then
            log_info "Downloading gacp script..."
            if ! curl -s \
                -H 'Cache-Control: no-cache, no-store, must-revalidate' \
                -H 'Pragma: no-cache' \
                -H 'Expires: 0' \
                "$GACP_REPO_URL?$(date +%s)" -o "$gacp_file"; then
                log_error "Failed to download gacp script"
                return 1
            fi
        fi
    fi
    
    chmod +x "$gacp_file"
    
    local source_line="source $gacp_file"
    
    if [[ -f "$bashrc_file" ]] && ! grep -q "source.*gacp.sh" "$bashrc_file"; then
        echo "$source_line" >> "$bashrc_file"
    fi
    
    if [[ -f "$zshrc_file" ]] && ! grep -q "source.*gacp.sh" "$zshrc_file"; then
        echo "$source_line" >> "$zshrc_file"
    fi
    
    source "$gacp_file"
    
    log_success "gacp v$GACP_VERSION installed successfully!"
}

gacp() {
    local force_edit=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                return 0
                ;;
            -e|--edit)
                force_edit=true
                shift
                ;;
            -v|--version)
                echo "gacp v$GACP_VERSION"
                check_for_updates
                return 0
                ;;
            --update-now)
                gacp -v
                return 0
                ;;
            --install-now)
                install_gacp
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                return 1
                ;;
        esac
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    
    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        log_info "No changes to commit"
        return 0
    fi
    
    # Add all changes
    git add -A
    
    # Check number of files changed
    local changed_files=$(git diff --cached --name-only | wc -l)
    
    if [[ $force_edit == true ]]; then
        # Force edit mode
        git commit
    elif [[ $changed_files -gt 1 ]]; then
        # Multiple files, ask user
        echo -e "${YELLOW}Multiple files edited. Edit commit message? (y/N)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git commit
        else
            git commit --no-edit
        fi
    else
        # Single file or default, use --no-edit
        git commit --no-edit
    fi
    
    # Push if remote exists
    if git remote >/dev/null 2>&1; then
        git push 2>/dev/null || git push -u origin $(git branch --show-current)
    fi
}

# If script is run directly, execute gacp
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --install-now)
            install_gacp
            exit 0
            ;;
        *)
            gacp "$@"
            ;;
    esac
fi
