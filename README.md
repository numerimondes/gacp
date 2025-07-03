# gacp

**Git Add Commit Push** - A one-word command from Heaven for your terminal that saves you time — add, commit, and push all in one go.

An intelligent Git workflow automation tool with conventional commits and smart commit message generation, especially optimized for Laravel applications.

## Features

- **Individual commits by default** - Each file gets its own commit with intelligent messages
- **Grouped commits option** - Use `-g` flag to commit all files together
- **Smart commit messages** - Context-aware message generation based on file types and changes
- **Conventional commits** - Follows conventional commit standards
- **Laravel optimized** - Special handling for Models, Controllers, Services, Migrations, etc.
- **One-line installation** - Install and setup in seconds

## Installation

### Quick Install

```bash
curl -sL https://raw.githubusercontent.com/numerimondes/gacp/main/gacp.sh -o gacp.sh && chmod +x gacp.sh && ./gacp.sh --install-now
```

### Manual Install

```bash
git clone https://github.com/numerimondes/gacp
cd gacp
chmod +x gacp.sh
./gacp.sh --install-now
```

## Usage

```bash
# Individual commits (default behavior)
gacp

# Grouped commit (all files in one commit)
gacp -g

# Show help
gacp -h
```

## How it works

1. **Stages** all changes (`git add .`)
2. **Analyzes** files and generates intelligent commit messages
3. **Commits** each file individually (or grouped with `-g`)
4. **Pushes** to remote repository

## Smart Message Examples

- `feat: add new User model with relationships`
- `fix: resolve authentication controller validation`
- `refactor: update UserService logic`
- `feat: add database schema migrations`
- `style: update stylesheets and UI design`

## Requirements

- Git repository
- Bash or Zsh shell
- Git remote configured (for push)

## License

MIT
