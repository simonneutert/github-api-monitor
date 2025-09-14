# Installation Guide

## Prerequisites

Ensure you have the following dependencies installed:

```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL/Fedora
sudo yum install curl jq  # or dnf install curl jq
```

## Installation

```bash
# Clone to your home directory
git clone https://github.com/simonneutert/gh-api-tools.git ~/.gh-api-tools
cd ~/.gh-api-tools

# Make scripts executable
chmod +x github-api-monitor.sh github-api-monitor.zsh
```

## Shell Setup

### Bash Setup
Add to your `~/.bashrc` or `~/.bash_profile`:

```bash
# GitHub API Monitor
export PATH="$HOME/.gh-api-tools:$PATH"

# Optional: Create convenient aliases
alias gh-rate='github-api-monitor.sh'
alias gh-rate-watch='github-api-monitor.sh --watch'
```

### Zsh Setup
Add to your `~/.zshrc`:

```zsh
# GitHub API Monitor
export PATH="$HOME/.gh-api-tools:$PATH"

# Optional: Create convenient aliases
alias gh-rate='github-api-monitor.zsh'
alias gh-rate-watch='github-api-monitor.zsh --watch'

# Enable completions (if using the zsh version)
autoload -Uz compinit && compinit
```

### Reload Your Shell
```bash
# Reload your shell configuration
source ~/.bashrc   # or ~/.zshrc
```

## Verify Installation
```bash
# Should now work from anywhere
gh-rate --version
github-api-monitor.sh --help
```

## Updates
```bash
# Update to latest version
cd ~/.gh-api-tools && git pull
```

## Uninstall
```bash
# Remove installation
rm -rf ~/.gh-api-tools

# Remove from shell config (manually edit ~/.bashrc or ~/.zshrc)
```

## Alternative Installation Methods

### Temporary Usage
If you don't want to install permanently, you can use the scripts directly:

```bash
git clone https://github.com/simonneutert/gh-api-tools.git
cd gh-api-tools
chmod +x github-api-monitor.sh github-api-monitor.zsh

# Use directly
./github-api-monitor.sh --token ghp_your_token_here
```

### Custom Location
Install to a different location:

```bash
# Clone to custom location
git clone https://github.com/simonneutert/gh-api-tools.git /path/to/custom/location
cd /path/to/custom/location
chmod +x github-api-monitor.sh github-api-monitor.zsh

# Add custom path to shell config
echo 'export PATH="/path/to/custom/location:$PATH"' >> ~/.bashrc
```

## Troubleshooting

### Command Not Found
If you get "command not found" after installation:

1. Make sure you reloaded your shell: `source ~/.bashrc` or `source ~/.zshrc`
2. Check if the path was added: `echo $PATH | grep gh-api-tools`
3. Verify scripts are executable: `ls -la ~/.gh-api-tools/github-api-monitor.*`

### Permission Issues
If you get permission errors:

```bash
# Fix permissions
chmod +x ~/.gh-api-tools/github-api-monitor.sh
chmod +x ~/.gh-api-tools/github-api-monitor.zsh
```

### Missing Dependencies
If scripts fail with missing dependencies:

```bash
# Check if dependencies are installed
which curl jq awk

# Install missing dependencies (see Prerequisites section above)
```

### Zsh Completions Not Working
If tab completion doesn't work in Zsh:

1. Make sure `compinit` is loaded in your `~/.zshrc`
2. Try rebuilding completions: `rm ~/.zcompdump && compinit`
3. Restart your terminal

## Development Installation

If you want to contribute or develop:

```bash
# Fork the repository first, then clone your fork
git clone https://github.com/YOUR_USERNAME/gh-api-tools.git ~/.gh-api-tools
cd ~/.gh-api-tools

# Set up remote for upstream
git remote add upstream https://github.com/simonneutert/gh-api-tools.git

# Follow the same shell setup as above
```