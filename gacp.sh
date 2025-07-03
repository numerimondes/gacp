#!/bin/bash
GACP_VERSION="1.1.0"

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
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

# Message prefix constants
readonly ERROR_PREFIX="${RED}[gacp] Error:${NC}"
readonly WARNING_PREFIX="${YELLOW}[gacp] Warning:${NC}"
readonly SUCCESS_PREFIX="${GREEN}[gacp] Success:${NC}"
readonly INFO_PREFIX="${BLUE}[gacp] Info:${NC}"

log_error() {
    echo -e "${ERROR_PREFIX} $1" >&2
}

log_warning() {
    echo -e "${WARNING_PREFIX} $1" >&2
}

log_success() {
    echo -e "${SUCCESS_PREFIX} $1"
}

log_info() {
    echo -e "${INFO_PREFIX} $1"
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
        log_warning "Could not check for updates"
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

unset_gacp_functions() {
    local functions_to_unset=(
        "gacp" "is_conventional_commit" "log_error" "log_warning" "log_success" "log_info"
        "generate_intelligent_message" "determine_commit_type" "show_file_changes"
        "get_namespace_from_composer" "extract_class_name" "analyze_file_content"
        "commit_individual_files" "show_help" "check_for_updates" "update_gacp"
        "install_gacp" "get_remote_version" "version_gt" "unset_gacp_functions"
    )
    
    for func in "${functions_to_unset[@]}"; do
        unset -f "$func" 2>/dev/null || true
    done
    
    unset GACP_REPO_URL GACP_INSTALL_DIR GACP_SCRIPT_PATH 2>/dev/null || true
    unset RED GREEN YELLOW BLUE CYAN MAGENTA WHITE GRAY NC 2>/dev/null || true
    unset ERROR_PREFIX WARNING_PREFIX SUCCESS_PREFIX INFO_PREFIX 2>/dev/null || true
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
    
    local remote_version
    remote_version=$(head -n 5 "$temp_file" | grep -E "^GACP_VERSION=" | cut -d'"' -f2)
    
    if [[ -z "$remote_version" ]]; then
        log_error "Invalid remote version"
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
    
    if ! chmod +x "$GACP_SCRIPT_PATH"; then
        log_error "Failed to make script executable"
        rm -f "$temp_file"
        return 1
    fi
    
    unset_gacp_functions
    source "$GACP_SCRIPT_PATH"
    
    log_success "Updated to version $remote_version"
    rm -f "$temp_file"
}

install_gacp() {
    local install_dir="$GACP_INSTALL_DIR"
    local gacp_file="$GACP_SCRIPT_PATH"
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    log_info "Installing gacp..."
    
    if ! mkdir -p "$install_dir"; then
        log_error "Failed to create installation directory: $install_dir"
        return 1
    fi
    
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
    
    if ! chmod +x "$gacp_file"; then
        log_error "Failed to make script executable"
        return 1
    fi
    
    local source_line="source $gacp_file"
    local shell_updated=false
    
    # Update shell configuration files
    if [[ -f "$bashrc_file" ]]; then
        if ! grep -q "source.*gacp.sh" "$bashrc_file"; then
            echo "$source_line" >> "$bashrc_file"
            shell_updated=true
            log_info "Added gacp to ~/.bashrc"
        fi
    fi
    
    if [[ -f "$zshrc_file" ]]; then
        if ! grep -q "source.*gacp.sh" "$zshrc_file"; then
            echo "$source_line" >> "$zshrc_file"
            shell_updated=true
            log_info "Added gacp to ~/.zshrc"
        fi
    fi
    
    # Load gacp in current shell session
    unset_gacp_functions
    if ! source "$gacp_file"; then
        log_error "Failed to load gacp functions"
        return 1
    fi
    
    # Verify installation
    if ! command -v gacp >/dev/null 2>&1; then
        log_error "Installation verification failed"
        return 1
    fi
    
    log_success "gacp v$GACP_VERSION installed successfully!"
    
    if [[ "$shell_updated" == true ]]; then
        log_info "To use gacp in future terminal sessions, restart your terminal or run:"
        if [[ -f "$bashrc_file" ]]; then
            echo "  source ~/.bashrc"
        fi
        if [[ -f "$zshrc_file" ]]; then
            echo "  source ~/.zshrc"
        fi
    fi
    
    log_info "You can now use gacp in this terminal session"
    log_info "Usage: gacp [-g] [-h] [-v] [--version] [--update-now]"
}

is_conventional_commit() {
    local message="$1"
    [[ "$message" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?:\ .+ ]]
}

show_file_changes() {
    local file="$1"
    local additions="$2"
    local deletions="$3"
    local status_color=""
    local change_indicator=""
    
    local git_status
    git_status=$(git status --porcelain "$file" 2>/dev/null | cut -c1-2)
    
    case "$git_status" in
        "M ")
            status_color="${YELLOW}"
            change_indicator="M"
            ;;
        "A ")
            status_color="${GREEN}"
            change_indicator="A"
            ;;
        "D ")
            status_color="${RED}"
            change_indicator="D"
            ;;
        "R ")
            status_color="${CYAN}"
            change_indicator="R"
            ;;
        "??")
            status_color="${BLUE}"
            change_indicator="?"
            ;;
        *)
            if [[ "$additions" -gt 0 && "$deletions" -gt 0 ]]; then
                status_color="${YELLOW}"
                change_indicator="M"
            elif [[ "$additions" -gt 0 ]]; then
                status_color="${GREEN}"
                change_indicator="A"
            elif [[ "$deletions" -gt 0 ]]; then
                status_color="${RED}"
                change_indicator="D"
            else
                status_color="${GRAY}"
                change_indicator="?"
            fi
            ;;
    esac
    
    printf "  ${status_color}%s${NC} %s ${GREEN}+%d${NC} ${RED}-%d${NC}\n" \
        "$change_indicator" "$file" "$additions" "$deletions"
}

get_namespace_from_composer() {
    local composer_file="composer.json"
    if [[ -f "$composer_file" ]]; then
        grep -oE '"[^"]*":\s*"[^"]*"' "$composer_file" | grep -E "App\\\\|src\\\\|lib\\\\" | head -1 | cut -d'"' -f4 | sed 's/\\\\/\//g'
    fi
}

extract_class_name() {
    local file="$1"
    local namespace_prefix="$2"
    
    if [[ -n "$namespace_prefix" ]]; then
        echo "$file" | sed "s|${namespace_prefix}/||g" | sed 's|/|\\|g' | sed 's|\.php$||g'
    else
        basename "$file" .php
    fi
}

analyze_file_content() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "new_file"
        return
    fi
    
    local diff_content
    diff_content=$(git diff --cached "$file" 2>/dev/null)
    
    if [[ -z "$diff_content" ]]; then
        diff_content=$(git diff "$file" 2>/dev/null)
    fi
    
    if echo "$diff_content" | grep -qE "^\+.*class\s+|^\+.*interface\s+|^\+.*trait\s+"; then
        echo "new_class"
    elif echo "$diff_content" | grep -qE "^\+.*function\s+|^\+.*public function\s+|^\+.*private function\s+|^\+.*protected function\s+"; then
        echo "new_method"
    elif echo "$diff_content" | grep -qE "^\+.*(belongsTo|hasMany|hasOne|belongsToMany|morphTo|morphMany)"; then
        echo "relationship"
    elif echo "$diff_content" | grep -qE "^\+.*fillable|^\+.*guarded|^\+.*casts"; then
        echo "attributes"
    elif echo "$diff_content" | grep -qE "^\+.*rules|^\+.*validate"; then
        echo "validation"
    elif echo "$diff_content" | grep -qE "^\+.*(where|join|select|insert|update|delete|create)"; then
        echo "database"
    elif echo "$diff_content" | grep -qE "^\+.*(fix|bug|error|exception|try|catch)"; then
        echo "fix"
    else
        echo "update"
    fi
}

generate_intelligent_message() {
    local files="$1"
    local diff_stats="$2"
    local diff_content="$3"
    local commit_type="$4"
    local file_count="$5"
    
    local message=""
    local additions deletions
    additions=$(echo "$diff_stats" | awk '{sum+=$1} END {print sum+0}')
    deletions=$(echo "$diff_stats" | awk '{sum+=$2} END {print sum+0}')
    
    local namespace_prefix
    namespace_prefix=$(get_namespace_from_composer)
    
    if [[ "$file_count" -eq 1 ]]; then
        local file="$files"
        local file_analysis=$(analyze_file_content "$file")
        
        if echo "$file" | grep -qE "/Models?/|Model\.php$"; then
            local class_name=$(extract_class_name "$file" "$namespace_prefix")
            case "$file_analysis" in
                "new_class"|"new_file")
                    message="add $class_name model"
                    ;;
                "relationship")
                    message="define $class_name model relationships"
                    ;;
                "attributes")
                    message="configure $class_name model attributes"
                    ;;
                "validation")
                    message="add $class_name model validation"
                    ;;
                *)
                    message="update $class_name model"
                    ;;
            esac
        elif echo "$file" | grep -qE "/Controllers?/|Controller\.php$"; then
            local class_name=$(extract_class_name "$file" "$namespace_prefix")
            case "$file_analysis" in
                "new_class"|"new_file")
                    message="add $class_name controller"
                    ;;
                "new_method")
                    message="implement $class_name methods"
                    ;;
                "validation")
                    message="add $class_name validation logic"
                    ;;
                "database")
                    message="implement $class_name database operations"
                    ;;
                *)
                    message="update $class_name controller"
                    ;;
            esac
        elif echo "$file" | grep -qE "/Services?/|Service\.php$"; then
            local class_name=$(extract_class_name "$file" "$namespace_prefix")
            case "$file_analysis" in
                "new_class"|"new_file")
                    message="add $class_name service"
                    ;;
                *)
                    message="update $class_name service"
                    ;;
            esac
        elif echo "$file" | grep -qE "database/migrations/"; then
            local migration_name=$(echo "$file" | sed 's/.*_//g' | sed 's/\.php$//g')
            message="add $migration_name migration"
        elif echo "$file" | grep -qE "routes/"; then
            local route_diff
            route_diff=$(git diff --cached "$file" 2>/dev/null || git diff "$file" 2>/dev/null)
            if echo "$route_diff" | grep -qiE "Route::(get|post|put|patch|delete|resource)"; then
                message="define new routes"
            else
                message="update routing"
            fi
        else
            local filename=$(basename "$file")
            message="update $filename"
        fi
    else
        local php_files=$(echo "$files" | grep -E "\.php$" | wc -l)
        local model_files=$(echo "$files" | grep -E "/Models?/|Model\.php$" | wc -l)
        local controller_files=$(echo "$files" | grep -E "/Controllers?/|Controller\.php$" | wc -l)
        local migration_files=$(echo "$files" | grep -E "database/migrations/" | wc -l)
        
        if [[ "$model_files" -gt 1 ]]; then
            message="update $model_files models"
        elif [[ "$controller_files" -gt 1 ]]; then
            message="update $controller_files controllers"
        elif [[ "$migration_files" -gt 1 ]]; then
            message="add $migration_files migrations"
        elif [[ "$php_files" -gt 5 ]]; then
            message="major codebase refactor"
        else
            message="update $file_count files"
        fi
    fi
    
    echo "$message"
}

determine_commit_type() {
    local files="$1"
    local diff_stats="$2"
    local diff_content="$3"
    local type="chore"
    
    local additions deletions
    additions=$(echo "$diff_stats" | awk '{sum+=$1} END {print sum+0}')
    deletions=$(echo "$diff_stats" | awk '{sum+=$2} END {print sum+0}')
    
    if echo "$files" | grep -qiE "(fix|bug|patch|hotfix)" || \
       echo "$diff_content" | grep -qiE "(fix|bug|error|issue|exception)"; then
        type="fix"
    elif echo "$files" | grep -qiE "(filament|Filament)" || \
         echo "$files" | grep -qE "/Filament/|filament/|resources/views/filament/"; then
        if [[ "$additions" -gt $((deletions * 2)) ]]; then
            type="feat"
        else
            type="refactor"
        fi
    elif echo "$files" | grep -qE "/Models?/|Model\.php$|models?/"; then
        if [[ "$additions" -gt $((deletions * 2)) ]]; then
            type="feat"
        else
            type="refactor"
        fi
    elif echo "$files" | grep -qE "/Controllers?/|Controller\.php$|controllers?/"; then
        if [[ "$additions" -gt $((deletions * 2)) ]]; then
            type="feat"
        else
            type="refactor"
        fi
    elif echo "$files" | grep -qE "/Services?/|Service\.php$|services?/"; then
        if [[ "$additions" -gt $((deletions * 2)) ]]; then
            type="feat"
        else
            type="refactor"
        fi
    elif echo "$files" | grep -qE "database/migrations/|migrations/"; then
        type="feat"
    elif echo "$files" | grep -qE "routes/|Routes/"; then
        type="feat"
    elif echo "$files" | grep -qiE "(test|spec|Test\.php|\.test\.|\.spec\.)" || \
         echo "$files" | grep -qE "tests/|Tests/|__tests__/|spec/"; then
        type="test"
    elif echo "$files" | grep -qiE "\.(md|txt|rst)$|readme|doc|changelog"; then
        type="docs"
    elif echo "$files" | grep -qiE "\.github/|\.gitlab-ci|jenkins|docker|Docker|\.ci/|ci\.yml|pipeline"; then
        type="ci"
    elif echo "$files" | grep -qE "composer\.(json|lock)|package\.(json|lock)|webpack\.mix\.js|vite\.config\.js|gulpfile|gruntfile|rollup\.config|tsconfig\.json"; then
        type="build"
    elif echo "$files" | grep -qE "config/|Config/|\.env|\.env\."; then
        type="chore"
    elif echo "$diff_content" | grep -qiE "(cache|optimize|performance|speed|query|perf)"; then
        type="perf"
    elif echo "$files" | grep -qE "resources/|Resources/"; then
        if echo "$files" | grep -qE "\.(css|scss|sass|less|styl)$"; then
            type="style"
        else
            type="feat"
        fi
    elif echo "$files" | grep -qE "\.php$"; then
        if [[ "$additions" -gt $((deletions * 2)) ]]; then
            type="feat"
        else
            type="refactor"
        fi
    elif echo "$files" | grep -qE "\.(js|ts|vue|jsx|tsx|svelte)$"; then
        type="feat"
    elif echo "$files" | grep -qE "\.(css|scss|sass|less|styl)$"; then
        type="style"
    fi
    
    echo "$type"
}

commit_individual_files() {
    local files="$1"
    
    echo "$files" | while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        if ! git reset HEAD >/dev/null 2>&1; then
            log_error "Failed to reset staging area"
            continue
        fi
        
        if ! git add "$file"; then
            log_error "Failed to stage $file"
            continue
        fi
        
        local file_diff_stats file_diff_content
        file_diff_stats=$(git diff --cached --numstat "$file" 2>/dev/null)
        file_diff_content=$(git diff --cached "$file" 2>/dev/null)
        
        local additions deletions
        additions=$(echo "$file_diff_stats" | awk '{print $1}')
        deletions=$(echo "$file_diff_stats" | awk '{print $2}')
        
        local file_type file_message
        file_type=$(determine_commit_type "$file" "$file_diff_stats" "$file_diff_content")
        file_message=$(generate_intelligent_message "$file" "$file_diff_stats" "$file_diff_content" "$file_type" "1")
        
        echo ""
        echo -e "${WHITE}File:${NC} $file"
        show_file_changes "$file" "$additions" "$deletions"
        echo ""
        echo -e "${MAGENTA}Suggested commit:${NC} ${file_type}: ${file_message}"
        echo -n "Press Enter to use suggested message, or type custom message: "
        read -r user_input
        
        local final_message
        if [[ -z "$user_input" ]]; then
            final_message="${file_type}: ${file_message}"
        elif is_conventional_commit "$user_input"; then
            final_message="$user_input"
        else
            final_message="${file_type}: ${user_input}"
        fi
        
        if git commit -m "$final_message"; then
            log_success "Committed: $final_message"
        else
            log_error "Failed to commit $file"
        fi
    done
}

show_help() {
    echo -e "${CYAN}GACP v$GACP_VERSION - Git Add Commit Push${NC}"
    echo -e "${WHITE}A one-word command from Heaven for your terminal that saves you time${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} gacp [OPTION]"
    echo ""
    echo -e "${WHITE}Options:${NC}"
    echo -e "  ${GREEN}-g${NC}              Group all changes into a single commit (default: individual commits)"
    echo -e "  ${GREEN}-h${NC}              Show this help message"
    echo -e "  ${GREEN}-v, --version${NC}   Show version and check for updates"
    echo -e "  ${GREEN}--update-now${NC}    Update gacp to the latest version"
    echo -e "  ${GREEN}--install-now${NC}   Install gacp globally"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  ${BLUE}gacp${NC}            # Commit files individually (default)"
    echo -e "  ${BLUE}gacp -g${NC}         # Group all changes into one commit"
    echo -e "  ${BLUE}gacp -v${NC}         # Show version and check for updates"
    echo -e "  ${BLUE}gacp --update-now${NC} # Update to latest version"
    echo ""
    echo -e "${WHITE}Installation:${NC}"
    echo -e "  ${BLUE}curl -sL https://raw.githubusercontent.com/numerimondes/gacp/refs/heads/main/gacp.sh | bash -s -- --install-now${NC}"
    echo ""
    echo -e "${WHITE}Features:${NC}"
    echo -e "  ${GREEN}*${NC} Intelligent commit message generation"
    echo -e "  ${GREEN}*${NC} Conventional commits support"
    echo -e "  ${GREEN}*${NC} Laravel/PHP project awareness"
    echo -e "  ${GREEN}*${NC} Individual file commits by default"
    echo -e "  ${GREEN}*${NC} Automatic upstream branch setup"
    echo -e "  ${GREEN}*${NC} Auto-update functionality"
}

gacp() {
    local grouped=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g)
                grouped=true
                shift
                ;;
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
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    
    echo -e "${BLUE}[gacp] Current git status:${NC}"
    git status --porcelain
    
    local modified_files deleted_files untracked_files
    modified_files=$(git diff --name-only 2>/dev/null)
    deleted_files=$(git diff --name-only --diff-filter=D 2>/dev/null)
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)
    
    if [[ -n "$modified_files" || -n "$deleted_files" || -n "$untracked_files" ]]; then
        if ! git add -A; then
            log_error "Failed to add files"
            return 1
        fi
    fi
    
    local files
    files=$(git diff --cached --name-only 2>/dev/null)
    
    if [[ -z "$files" ]]; then
        log_info "No changes to commit"
        return 0
    fi
    
    local diff_stats diff_content
    diff_stats=$(git diff --cached --numstat 2>/dev/null)
    diff_content=$(git diff --cached 2>/dev/null)
    
    local file_count
    file_count=$(echo "$files" | wc -l | sed 's/^[[:space:]]*//')
    
    echo ""
    echo -e "${WHITE}Files to be committed (${file_count}):${NC}"
    while IFS=$'\t' read -r additions deletions filename; do
        show_file_changes "$filename" "$additions" "$deletions"
    done <<< "$diff_stats"
    
    if [[ "$grouped" == true ]]; then
        local auto_prefix
        auto_prefix=$(determine_commit_type "$files" "$diff_stats" "$diff_content")
        
        local intelligent_message
        intelligent_message=$(generate_intelligent_message "$files" "$diff_stats" "$diff_content" "$auto_prefix" "$file_count")
        
        echo ""
        echo -e "${MAGENTA}Suggested commit:${NC} ${auto_prefix}: ${intelligent_message}"
        echo -n "Press Enter to use suggested message, or type custom message: "
        read -r user_input
        
        local final_message
        if [[ -z "$user_input" ]]; then
            final_message="${auto_prefix}: ${intelligent_message}"
        elif is_conventional_commit "$user_input"; then
            final_message="$user_input"
        else
            final_message="${auto_prefix}: ${user_input}"
        fi
        
        if ! git commit -m "$final_message"; then
            log_error "Failed to commit changes"
            return 1
        fi
        
        log_success "Committed: $final_message"
    else
        commit_individual_files "$files"
    fi
    
    if ! git remote >/dev/null 2>&1; then
        log_warning "No remote repository configured"
        return 0
    fi
    
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
        log_warning "Could not determine current branch"
        return 0
    fi
    
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        log_info "Setting upstream for branch: $current_branch"
        if ! git push -u origin "$current_branch"; then
            log_error "Failed to push and set upstream"
            return 1
        fi
    else
        if ! git push; then
            log_error "Failed to push changes"
            return 1
        fi
    fi
    
    log_success "Changes pushed to remote repository"
}

# Main execution logic
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --install-now)
            install_gacp
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "gacp v$GACP_VERSION"
            check_for_updates
            exit 0
            ;;
        --update-now)
            update_gacp
            exit 0
            ;;
        *)
            if git rev-parse --git-dir >/dev/null 2>&1; then
                gacp "$@"
            else
                log_error "Not in a git repository. Use 'gacp --install-now' to install gacp globally."
                exit 1
            fi
            ;;
    esac
fi
