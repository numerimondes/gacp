#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

install_gacp() {
    local install_dir="$HOME/.gacp"
    local gacp_file="$install_dir/gacp.sh"
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    mkdir -p "$install_dir"
    
    if [[ "$0" != "$gacp_file" ]]; then
        cp "$0" "$gacp_file"
        chmod +x "$gacp_file"
    fi
    
    local source_line="source ~/.gacp/gacp.sh"
    
    if [[ -f "$bashrc_file" ]]; then
        if ! grep -q "source ~/.gacp/gacp.sh" "$bashrc_file"; then
            echo "$source_line" >> "$bashrc_file"
        fi
    fi
    
    if [[ -f "$zshrc_file" ]]; then
        if ! grep -q "source ~/.gacp/gacp.sh" "$zshrc_file"; then
            echo "$source_line" >> "$zshrc_file"
        fi
    fi
    
    echo -e "${GREEN}gacp installed successfully!${NC}"
    echo -e "${BLUE}Restart your terminal or run: source ~/.gacp/gacp.sh${NC}"
    echo -e "${CYAN}Usage: gacp [-g] [-h]${NC}"
    
    source "$gacp_file"
}

is_conventional_commit() {
    local message="$1"
    [[ "$message" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?:\ .+ ]]
}

log_error() {
    echo -e "${RED}[gacp] Error:${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[gacp] Warning:${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[gacp] Success:${NC} $1"
}

log_info() {
    echo -e "${BLUE}[gacp] Info:${NC} $1"
}

show_file_changes() {
    local file="$1"
    local additions="$2"
    local deletions="$3"
    local status_color=""
    local change_indicator=""
    
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
    
    printf "  ${status_color}%s${NC} %s ${GREEN}+%d${NC} ${RED}-%d${NC}\n" \
        "$change_indicator" "$file" "$additions" "$deletions"
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
    
    local file_suffix=""
    if [[ "$file_count" -eq 1 ]]; then
        file_suffix="file"
    else
        file_suffix="files"
    fi
    
    if echo "$files" | grep -qiE "(filament|Filament)"; then
        if [[ "$additions" -gt $((deletions * 3)) ]]; then
            message="implement new Filament components and features"
        elif [[ "$deletions" -gt $((additions * 2)) ]]; then
            message="remove unused Filament components"
        else
            message="update Filament admin interface"
        fi
    elif echo "$files" | grep -qE "/Models?/|Model\.php$"; then
        local model_files=$(echo "$files" | grep -E "/Models?/|Model\.php$")
        local model_count=$(echo "$model_files" | wc -l)
        if [[ "$model_count" -eq 1 ]]; then
            local model_name=$(echo "$model_files" | sed 's/.*\///g' | sed 's/\.php$//g')
            if [[ "$additions" -gt $((deletions * 3)) ]]; then
                message="add new ${model_name} model with relationships"
            elif echo "$diff_content" | grep -qiE "(fillable|guarded|casts|dates)"; then
                message="configure ${model_name} model attributes"
            elif echo "$diff_content" | grep -qiE "(belongsTo|hasMany|hasOne|belongsToMany)"; then
                message="define ${model_name} model relationships"
            else
                message="update ${model_name} model structure"
            fi
        else
            message="update multiple model definitions"
        fi
    elif echo "$files" | grep -qE "/Controllers?/|Controller\.php$"; then
        local controller_files=$(echo "$files" | grep -E "/Controllers?/|Controller\.php$")
        local controller_count=$(echo "$controller_files" | wc -l)
        if [[ "$controller_count" -eq 1 ]]; then
            local controller_name=$(echo "$controller_files" | sed 's/.*\///g' | sed 's/Controller\.php$//g')
            if [[ "$additions" -gt $((deletions * 3)) ]]; then
                message="implement ${controller_name}Controller logic"
            elif echo "$diff_content" | grep -qiE "(index|show|store|update|destroy)"; then
                message="add CRUD operations to ${controller_name}Controller"
            elif echo "$diff_content" | grep -qiE "(authorize|validate|request)"; then
                message="add validation and authorization to ${controller_name}Controller"
            else
                message="refactor ${controller_name}Controller methods"
            fi
        else
            message="update controller implementations"
        fi
    elif echo "$files" | grep -qE "/Services?/|Service\.php$"; then
        local service_files=$(echo "$files" | grep -E "/Services?/|Service\.php$")
        local service_count=$(echo "$service_files" | wc -l)
        if [[ "$service_count" -eq 1 ]]; then
            local service_name=$(echo "$service_files" | sed 's/.*\///g' | sed 's/Service\.php$//g')
            message="implement ${service_name}Service logic"
        else
            message="update service layer implementations"
        fi
    elif echo "$files" | grep -qE "database/migrations/"; then
        local migration_files=$(echo "$files" | grep -E "database/migrations/")
        local migration_count=$(echo "$migration_files" | wc -l)
        if [[ "$migration_count" -eq 1 ]]; then
            local migration_name=$(echo "$migration_files" | sed 's/.*_//g' | sed 's/\.php$//g')
            message="add ${migration_name} database migration"
        else
            message="add database schema migrations"
        fi
    elif echo "$files" | grep -qE "routes/"; then
        if echo "$diff_content" | grep -qiE "(get|post|put|patch|delete|resource)"; then
            message="define new API routes and endpoints"
        else
            message="update routing configuration"
        fi
    elif echo "$files" | grep -qE "resources/views/"; then
        local view_files=$(echo "$files" | grep -E "resources/views/")
        if echo "$view_files" | grep -qE "\.blade\.php$"; then
            message="update Blade templates and views"
        else
            message="update view templates"
        fi
    elif echo "$files" | grep -qE "resources/js/|resources/css/"; then
        if echo "$files" | grep -qE "\.vue$"; then
            message="update Vue.js components"
        elif echo "$files" | grep -qE "\.js$|\.ts$"; then
            message="update JavaScript functionality"
        elif echo "$files" | grep -qE "\.css$|\.scss$"; then
            message="update stylesheets and UI design"
        else
            message="update frontend assets"
        fi
    elif echo "$files" | grep -qE "config/"; then
        local config_files=$(echo "$files" | grep -E "config/")
        if [[ $(echo "$config_files" | wc -l) -eq 1 ]]; then
            local config_name=$(echo "$config_files" | sed 's/.*\///g' | sed 's/\.php$//g')
            message="configure ${config_name} settings"
        else
            message="update application configuration"
        fi
    elif echo "$files" | grep -qiE "(test|spec)" || echo "$files" | grep -qE "tests/|Tests/"; then
        if echo "$diff_content" | grep -qiE "(test|assert|expect)"; then
            message="add comprehensive test coverage"
        else
            message="update test suite"
        fi
    elif echo "$files" | grep -qE "\.md$|readme|README"; then
        message="update project documentation"
    elif echo "$files" | grep -qE "composer\.(json|lock)"; then
        if echo "$diff_content" | grep -qiE "(require|autoload)"; then
            message="update Composer dependencies"
        else
            message="update package configuration"
        fi
    elif echo "$files" | grep -qE "package\.(json|lock)"; then
        message="update npm dependencies"
    elif echo "$files" | grep -qE "\.env|\.env\."; then
        message="update environment configuration"
    elif echo "$files" | grep -qE "\.github/|\.gitlab-ci|docker|Docker"; then
        message="update CI/CD pipeline configuration"
    elif echo "$files" | grep -qE "webpack|vite|gulpfile|rollup"; then
        message="update build system configuration"
    else
        if echo "$files" | grep -qE "\.php$" && [[ "$file_count" -gt 10 ]]; then
            message="major PHP codebase refactoring"
        elif echo "$files" | grep -qE "\.php$"; then
            message="update PHP implementation"
        elif echo "$files" | grep -qE "\.(js|ts|vue|jsx|tsx|svelte)$"; then
            message="update frontend JavaScript code"
        elif echo "$files" | grep -qE "\.(css|scss|sass)$"; then
            message="update stylesheet design"
        else
            message="update project files"
        fi
    fi
    
    if [[ "$file_count" -gt 1 ]]; then
        message="${message} (${file_count} ${file_suffix})"
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
        
        git reset HEAD >/dev/null 2>&1
        
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
    echo -e "${CYAN}GACP - Git Add Commit Push${NC}"
    echo -e "${WHITE}A one-word command from Heaven for your terminal that saves you time${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} gacp [OPTION]"
    echo ""
    echo -e "${WHITE}Options:${NC}"
    echo -e "  ${GREEN}-g${NC}    Group all changes into a single commit (default: individual commits)"
    echo -e "  ${GREEN}-h${NC}    Show this help message"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  ${BLUE}gacp${NC}      # Commit files individually (default)"
    echo -e "  ${BLUE}gacp -g${NC}   # Group all changes into one commit"
    echo -e "  ${BLUE}gacp -h${NC}   # Show help"
    echo ""
    echo -e "${WHITE}Features:${NC}"
    echo -e "  ${GREEN}•${NC} Intelligent commit message generation"
    echo -e "  ${GREEN}•${NC} Conventional commits support"
    echo -e "  ${GREEN}•${NC} Laravel/PHP project awareness"
    echo -e "  ${GREEN}•${NC} Individual file commits by default"
    echo -e "  ${GREEN}•${NC} Automatic upstream branch setup"
    echo ""
    echo -e "${WHITE}Smart Message Examples:${NC}"
    echo -e "  ${MAGENTA}feat:${NC} add new User model with relationships"
    echo -e "  ${MAGENTA}fix:${NC} resolve authentication controller validation"
    echo -e "  ${MAGENTA}refactor:${NC} update UserService logic"
    echo -e "  ${MAGENTA}feat:${NC} add database schema migrations"
    echo -e "  ${MAGENTA}style:${NC} update stylesheets and UI design"
}

gacp() {
    local grouped=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g)
                grouped=true
                shift
                ;;
            -h)
                show_help
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
    
    if ! git add .; then
        log_error "Failed to add files"
        return 1
    fi
    
    local files
    files=$(git diff --cached --name-only 2>/dev/null)
    
    if [[ -z "$files" ]]; then
        local untracked
        untracked=$(git ls-files --others --exclude-standard)
        if [[ -n "$untracked" ]]; then
            log_info "Untracked files found, adding them..."
            git add -A
            files=$(git diff --cached --name-only 2>/dev/null)
        fi
        
        if [[ -z "$files" ]]; then
            log_info "No changes to commit"
            return 0
        fi
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

if [[ "$1" == "--install-now" ]]; then
    install_gacp
    exit 0
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
        gacp "$@"
    else
        echo -e "${RED}Error:${NC} Not in a git repository"
        echo -e "${CYAN}To install gacp globally, run:${NC}"
        echo "  $0 --install-now"
        exit 1
    fi
fi
