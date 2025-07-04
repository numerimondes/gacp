# GACP - Git Add Commit Push

A one-word command from Heaven for your terminal that saves you time — add, commit, and push all in one go. **GACP** is an intelligent Git automation tool that streamlines your development workflow. It automatically generates conventional commit messages and handles the full `git add`, `commit`, and `push` process — all in one go.

## Installation

### Quick One-Line Installer

```bash
curl -sL https://raw.githubusercontent.com/numerimondes/gacp/main/gacp.sh -o gacp.sh && chmod +x gacp.sh && ./gacp.sh --install-now
```

<br>

<img src="art/og_image_gacp.png" alt="gacp command adding committing and pushing every file with its own commit">


### Manual Installation

1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/numerimondes/gacp/main/gacp.sh
   ```

2. Make it executable:
   ```bash
   chmod +x gacp.sh
   ```

3. Install it:
   ```bash
   ./gacp.sh --install-now
   ```

## Usage

### Basic Usage

Simply run `gacp` in any Git repository:

```bash
gacp
```

This will:
1. Add all changes (`git add -A`)
2. Commit with an appropriate message
3. Push to the remote repository

### Command Options

```bash
gacp [OPTION]

Options:
  -h, --help         Show help message
  -v, --version      Show version and check for updates
  -e, --edit         Force edit commit message
  --update-now       Update gacp to the latest version
```

### Examples

```bash
# Basic usage - add, commit, push everything
gacp

# Force edit commit message
gacp -e

# Check version and updates
gacp -v

# Show help
gacp -h
```

## Features

### Intelligent Commit Handling

- **Single file changes**: Uses `--no-edit` for quick commits
- **Multiple file changes**: Prompts to edit commit message
- **Force edit mode**: Use `-e` flag to always edit commit message

### Smart Repository Detection

- Automatically detects if you're in a Git repository
- Checks for changes before attempting to commit
- Handles both tracked and untracked files

### Remote Repository Support

- Automatically pushes to existing remotes
- Sets up upstream tracking for new branches
- Gracefully handles repositories without remotes

### Self-Updating

- Built-in version checking
- Automatic updates with `--update-now`
- Cache-busting for reliable downloads

## Workflow

1. **Change Detection**: Checks for modified, staged, and untracked files
2. **Add All Changes**: Runs `git add -A` to stage everything
3. **Smart Commit**: 
   - Single file: Quick commit with `--no-edit`
   - Multiple files: Option to edit commit message
   - Force edit: Always opens editor with `-e` flag
4. **Push**: Automatically pushes to remote repository

## Installation Details

GACP installs itself to `~/.gacp/gacp.sh` and adds itself to your shell configuration:

- **Bash**: Adds to `~/.bashrc`
- **Zsh**: Adds to `~/.zshrc`

After installation, restart your shell or run:
```bash
exec $SHELL
```

## Requirements

- Git (obviously)
- Bash or Zsh
- curl (for installation and updates)
- Internet connection (for installation and updates)

## Uninstallation

To remove GACP:

1. Remove the installation directory:
   ```bash
   rm -rf ~/.gacp
   ```

2. Remove from shell configuration:
   ```bash
   # For Bash
   sed -i '/source.*gacp\.sh/d' ~/.bashrc
   
   # For Zsh
   sed -i '/source.*gacp\.sh/d' ~/.zshrc
   ```

3. Restart your shell:
   ```bash
   exec $SHELL
   ```

## Troubleshooting

### Command Not Found

If `gacp` command is not found after installation:

1. Check if it's in your shell config:
   ```bash
   grep gacp ~/.bashrc ~/.zshrc
   ```

2. Manually source the script:
   ```bash
   source ~/.gacp/gacp.sh
   ```

3. Restart your shell:
   ```bash
   exec $SHELL
   ```

### Update Issues

If updates fail:

1. Check internet connection
2. Try manual reinstallation:
   ```bash
   curl -sL https://raw.githubusercontent.com/numerimondes/gacp/main/gacp.sh -o gacp.sh && chmod +x gacp.sh && ./gacp.sh --install-now
   ```

### Git Repository Issues

- Make sure you're in a Git repository: `git status`
- Check if you have a remote configured: `git remote -v`
- Ensure you have proper Git credentials set up

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is open source and available under the [MPL-2.0 license](LICENSE).

## Version History

- **v0.0.1**: Latest development version

## Support

For issues and questions:
- Open an issue on GitHub
- Check the troubleshooting section above
- Review the help output: `gacp -h`

## Credits

**El Moumen Yassine**
**yassine@numerimondes.com**
**❤️ Made with love by numerimondes**


---

**GACP** - Because `git add . && git commit -m "update" && git push` is too long to type every time.

*Save time, commit better, code happier with GACP !*
