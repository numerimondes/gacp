#!/bin/bash
GACP_VERSION="0.0.6"

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
    echo -e "A simple wrapper that leverages git hooks for intelligent commits"
    echo ""
    echo -e "${YELLOW}Usage:${NC} gacp [OPTION]"
    echo ""
    echo -e "Options:"
    echo -e "  ${GREEN}-h, --help${NC}      Show this help message"
    echo -e "  ${GREEN}-v, --version${NC}   Show version and check for updates"
    echo -e "  ${GREEN}--update-now${NC}    Update gacp to the latest version"
    echo -e "  ${GREEN}--install-now${NC}   Install gacp globally"
    echo ""
    echo -e "Examples:"
    echo -e "  ${BLUE}gacp${NC}            # Add all changes and commit with intelligent message"
    echo -e "  ${BLUE}gacp -v${NC}         # Show version and check for updates"
    echo ""
    echo -e "Installation:"
    echo -e "  ${BLUE}curl -sL https://raw.githubusercontent.com/numerimondes/gacp/refs/heads/main/gacp.sh | bash -s -- --install-now${NC}"
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
    
    # Reload the updated script
    source "$GACP_SCRIPT_PATH"
    
    log_success "Updated to latest version"
    rm -f "$temp_file"
}

install_commit_hook() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    
    if [[ -z "$git_dir" ]]; then
        log_error "Not in a git repository"
        return 1
    fi
    
    local hooks_dir="$git_dir/hooks"
    local hook_file="$hooks_dir/prepare-commit-msg"
    
    mkdir -p "$hooks_dir"
    
    cat > "$hook_file" << 'EOF'
#!/bin/bash
# GACP intelligent commit message hook

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

# Only generate message for regular commits (not merges, squashes, etc.)
if [[ "$COMMIT_SOURCE" == "message" ]] || [[ -n "$COMMIT_SOURCE" ]]; then
    exit 0
fi

# Get staged files
staged_files=$(git diff --cached --name-only)
if [[ -z "$staged_files" ]]; then
    exit 0
fi

# Detect project type
detect_project_type() {
    if [[ -f "composer.json" ]]; then echo "php"
    elif [[ -f "package.json" ]]; then echo "node"
    elif [[ -f "requirements.txt" || -f "setup.py" || -f "pyproject.toml" ]]; then echo "python"
    elif [[ -f "Cargo.toml" ]]; then echo "rust"
    elif [[ -f "go.mod" ]]; then echo "go"
    else echo "generic"
    fi
}

# Generate commit type and message
generate_commit_message() {
    local files="$1"
    local project_type="$2"
    local file_count=$(echo "$files" | wc -l)
    
    local commit_type="chore"
    local message=""
    
    # Determine commit type
    if echo "$files" | grep -qE "(test|spec|Test\.)" || \
       git diff --cached | grep -qE "^\+.*(test|spec|describe|it\(|expect)"; then
        commit_type="test"
    elif echo "$files" | grep -qE "\.(md|txt|rst)$|readme|doc"; then
        commit_type="docs"
    elif echo "$files" | grep -qE "\.github/|\.gitlab-ci|docker|ci\.yml"; then
        commit_type="ci"
    elif echo "$files" | grep -qE "composer\.(json|lock)|package\.(json|lock)|webpack|vite"; then
        commit_type="build"
    elif git diff --cached | grep -qE "^\+.*(fix|bug|error|issue)"; then
        commit_type="fix"
    elif git diff --cached | grep -qE "^\+.*(cache|optimize|performance)"; then
        commit_type="perf"
    elif echo "$files" | grep -qE "\.(css|scss|sass|less)$"; then
        commit_type="style"
    elif [[ $file_count -eq 1 ]]; then
        # Single file logic
        local file="$files"
        local filename=$(basename "$file")
        local dirname=$(dirname "$file")
        
        case "$project_type" in
            "php")
                if echo "$file" | grep -qE "/Models?/|Model\.php$"; then
                    local model_name=$(basename "$file" .php)
                    if git diff --cached | grep -qE "^\+.*class\s+$model_name"; then
                        commit_type="feat"
                        message="add $model_name model"
                    else
                        commit_type="refactor"
                        message="update $model_name model"
                    fi
                elif echo "$file" | grep -qE "/Controllers?/|Controller\.php$"; then
                    local controller_name=$(basename "$file" .php | sed 's/Controller$//')
                    commit_type="feat"
                    message="update $controller_name controller"
                elif echo "$file" | grep -qE "database/migrations/"; then
                    commit_type="feat"
                    message="add database migration"
                elif echo "$file" | grep -qE "/Helpers?/|helpers?\.php$"; then
                    commit_type="feat"
                    message="update helper functions"
                elif echo "$file" | grep -qE "routes/"; then
                    commit_type="feat"
                    message="update routes"
                elif echo "$file" | grep -qE "config/"; then
                    commit_type="chore"
                    message="update configuration"
                else
                    commit_type="refactor"
                    message="update $filename"
                fi
                ;;
            "node")
                if echo "$file" | grep -qE "\.(js|ts|jsx|tsx)$"; then
                    local component_name=$(basename "$file" | sed 's/\.[^.]*$//')
                    commit_type="feat"
                    message="update $component_name component"
                elif echo "$file" | grep -qE "package\.json"; then
                    commit_type="build"
                    message="update dependencies"
                else
                    commit_type="refactor"
                    message="update $filename"
                fi
                ;;
            *)
                commit_type="refactor"
                message="update $filename"
                ;;
        esac
    else
        # Multiple files
        if [[ $file_count -gt 10 ]]; then
            commit_type="refactor"
            message="major codebase update"
        else
            commit_type="feat"
            message="update $file_count files"
        fi
    fi
    
    # If no specific message was generated, create a generic one
    if [[ -z "$message" ]]; then
        if [[ $file_count -eq 1 ]]; then
            message="update $(basename "$files")"
        else
            message="update $file_count files"
        fi
    fi
    
    echo "$commit_type: $message"
}

# Main logic
project_type=$(detect_project_type)
generated_message=$(generate_commit_message "$staged_files" "$project_type")

# Replace the commit message
echo "$generated_message" > "$COMMIT_MSG_FILE"
EOF
    
    chmod +x "$hook_file"
    log_success "Commit message hook installed"
}

install_gacp() {
    local install_dir="$GACP_INSTALL_DIR"
    local gacp_file="$GACP_SCRIPT_PATH"
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    log_info "Installing gacp..."
    
    mkdir -p "$install_dir"
    
    # Copy or download the script
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
    
    # Update shell configuration files
    if [[ -f "$bashrc_file" ]] && ! grep -q "source.*gacp.sh" "$bashrc_file"; then
        echo "$source_line" >> "$bashrc_file"
        log_info "Added gacp to ~/.bashrc"
    fi
    
    if [[ -f "$zshrc_file" ]] && ! grep -q "source.*gacp.sh" "$zshrc_file"; then
        echo "$source_line" >> "$zshrc_file"
        log_info "Added gacp to ~/.zshrc"
    fi
    
    # Load gacp in current session
    source "$gacp_file"
    
    log_success "gacp v$GACP_VERSION installed successfully!"
    log_info "Usage: gacp [-h] [-v] [--version] [--update-now]"
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
        echo "Initialize a git repository first: git init"
        return 1
    fi
    
    # Install commit hook if not present
    local git_dir=$(git rev-parse --git-dir)
    if [[ ! -f "$git_dir/hooks/prepare-commit-msg" ]]; then
        install_commit_hook
    fi
    
    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        log_info "No changes to commit"
        return 0
    fi
    
    # Add all changes
    git add -A
    
    # Show status
    echo -e "${BLUE}[gacp] Status:${NC}"
    git status --short
    
    # Commit with hook-generated message
    echo ""
    log_info "Committing with intelligent message..."
    git commit
    
    # Push if remote exists
    if git remote >/dev/null 2>&1; then
        local current_branch=$(git branch --show-current)
        if [[ -n "$current_branch" ]]; then
            # Check if upstream is set
            if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
                log_info "Setting upstream for branch: $current_branch"
                git push -u origin "$current_branch"
            else
                git push
            fi
            log_success "Changes pushed to remote repository"
        fi
    else
        log_info "No remote repository configured"
    fi
}

# Main execution logic
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
