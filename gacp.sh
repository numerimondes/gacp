#!/bin/bash
GACP_VERSION="0.0.7"

# Constants
readonly GACP_REPO_URL="https://raw.githubusercontent.com/numerimondes/gacp/refs/heads/main/gacp.sh"
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
    echo -e "${RED}[gacp] Error:${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[gacp] Success:${NC} $1"
}

log_info() {
    echo -e "${BLUE}[gacp] Info:${NC} $1"
}

show_help() {
    echo -e "${CYAN}GACP v$GACP_VERSION - Git Add Commit Push${NC}"
    echo -e "A one-word command from Heaven for your terminal that saves you time"
    echo -e "Add, commit, and push all in one go with intelligent commit messages"
    echo ""
    echo -e "${YELLOW}Installation:${NC}"
    echo -e "  ${BLUE}curl -sL https://raw.githubusercontent.com/numerimondes/gacp/refs/heads/main/gacp.sh -o gacp.sh && chmod +x gacp.sh && ./gacp.sh --install-now${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} gacp [OPTION]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}-h, --help${NC}      Show this help message"
    echo -e "  ${GREEN}-v, --version${NC}   Show version and check for updates"
    echo -e "  ${GREEN}--update-now${NC}    Update gacp to the latest version"
    echo -e "  ${GREEN}--install-now${NC}   Install gacp globally"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${BLUE}gacp${NC}            # Add all changes and commit with intelligent message"
    echo -e "  ${BLUE}gacp -v${NC}         # Show version and check for updates"
    echo -e "  ${BLUE}gacp --update-now${NC} # Update to latest version"
    echo ""
    echo -e "${YELLOW}Features:${NC}"
    echo -e "  • Intelligent Commit Messages: Automatically generates meaningful commit messages"
    echo -e "  • Conventional Commits: Supports and enforces conventional commit standards"
    echo -e "  • Project Awareness: Smart detection for Laravel/PHP, Node.js, Python, and other project types"
    echo -e "  • Individual File Commits: Commits files individually by default for better history tracking"
    echo -e "  • Automatic Branch Setup: Handles upstream branch configuration automatically"
    echo -e "  • Auto-Update: Built-in update mechanism to keep GACP current"
    echo -e "  • Colorized Output: Beautiful, informative terminal output with color coding"
}

get_remote_version() {
    local remote_version
    remote_version=$(curl -s "$GACP_REPO_URL" | head -n 5 | grep -E "^GACP_VERSION=" | cut -d'"' -f2 2>/dev/null)
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
            update_gacp
        else
            log_info "Update canceled"
        fi
    else
        log_info "gacp is up to date (v$GACP_VERSION)"
    fi
}

update_gacp() {
    log_info "Updating gacp..."
    
    local temp_file
    temp_file=$(mktemp)
    
    if ! curl -s "$GACP_REPO_URL" -o "$temp_file"; then
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
    source "$GACP_SCRIPT_PATH"
    
    log_success "Updated to latest version"
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
            if ! curl -s "$GACP_REPO_URL" -o "$gacp_file"; then
                log_error "Failed to download gacp script"
                return 1
            fi
        fi
    fi
    
    chmod +x "$gacp_file"
    
    local source_line="source $gacp_file"
    
    if [[ -f "$bashrc_file" ]] && ! grep -q "source.*gacp.sh" "$bashrc_file"; then
        echo "$source_line" >> "$bashrc_file"
        log_info "Added gacp to ~/.bashrc"
    fi
    
    if [[ -f "$zshrc_file" ]] && ! grep -q "source.*gacp.sh" "$zshrc_file"; then
        echo "$source_line" >> "$zshrc_file"
        log_info "Added gacp to ~/.zshrc"
    fi
    
    source "$gacp_file"
    
    log_success "gacp v$GACP_VERSION installed successfully!"
    log_info "Usage: gacp [-h] [-v] [--version] [--update-now]"
}

install_hook_if_needed() {
    local git_dir=$(git rev-parse --git-dir)
    local hook_file="$git_dir/hooks/prepare-commit-msg"
    
    if [[ ! -f "$hook_file" ]]; then
        mkdir -p "$git_dir/hooks"
        cat > "$hook_file" << 'EOF'
#!/bin/bash
# Simple commit message generator
COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"
# Only generate message for regular commits
if [[ "$COMMIT_SOURCE" == "message" ]] || [[ -n "$COMMIT_SOURCE" ]]; then
    exit 0
fi
# Get staged files
staged_files=$(git diff --cached --name-only)
if [[ -z "$staged_files" ]]; then
    exit 0
fi
# Simple message generation
file_count=$(echo "$staged_files" | wc -l)
if [[ $file_count -eq 1 ]]; then
    filename=$(basename "$staged_files")
    echo "update $filename" > "$COMMIT_MSG_FILE"
else
    echo "update $file_count files" > "$COMMIT_MSG_FILE"
fi
EOF
        chmod +x "$hook_file"
        log_info "Hook installed"
    fi
}

gacp() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                return 0
                ;;
            -v|--version)
                echo "gacp v$GACP_VERSION"
                check_for_updates
                return 0
                ;;
            --update-now)
                update_gacp
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
    
    # Install the hook if not present
    install_hook_if_needed
    
    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        log_info "No changes to commit"
        return 0
    fi
    
    # Add all changes
    git add -A
    
    # Commit with the hook-generated message (no editor)
    git commit --no-edit
    
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
