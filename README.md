# GitHub GraphQL API Rate Limit Monitor

<div align="center">

🚨 (supervised) Vibe-Code alert 🚨

</div>

> 🚀 Modern Clojure/Babashka and multi-shell command-line tool for real-time monitoring of GitHub GraphQL API rate limits

[![Babashka](https://img.shields.io/badge/Babashka-5881C7?style=flat&logo=clojure&logoColor=white)](https://babashka.org/)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?style=flat&logo=zsh&logoColor=white)](https://www.zsh.org/)
[![Fish](https://img.shields.io/badge/Fish-00D4AA?style=flat&logo=fish&logoColor=white)](https://fishshell.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🔍 Overview

Monitor your GitHub GraphQL API rate limits with a modern Clojure/Babashka implementation or traditional shell scripts. This tool provides detailed information about your API consumption, remaining quota, reset times, and usage recommendations.

**Available implementations:**

- **🎯 Babashka (Recommended)** - Modern Clojure implementation with fast startup, excellent error handling, and comprehensive features
- **Bash** - Original implementation with full POSIX compatibility
- **Zsh** - Enhanced version with Zsh-specific optimizations
- **Fish** - Complete implementation with native Fish features

Perfect for developers, DevOps engineers, and CI/CD pipelines that need to respect GitHub's API limits.

## ✨ Features

### Babashka Version (Recommended)
- **🚀 Fast startup** - Native binary with sub-second initialization
- **🔒 Enhanced security** - File permission validation and token pattern checking
- **🎯 Superior error handling** - Comprehensive HTTP, network, and GraphQL error handling
- **📊 Professional output** - Beautifully formatted table, JSON, and compact modes
- **⚡ Built-in libraries** - No external dependencies beyond Babashka
- **🔄 Continuous monitoring** with intelligent screen clearing
- **🛡️ Robust validation** - Token validation before API calls

### All Versions
- **Real-time API monitoring** with current usage statistics
- **Multiple output formats**: table (default), JSON, compact
- **Continuous monitoring** mode with customizable intervals
- **Smart recommendations** based on usage levels
- **Configuration file support** for secure token storage
- **Colored output** with terminal detection
- **Cross-platform compatibility**

## 🚀 Installation

### Babashka Version (Recommended)

**Prerequisites:**
- [Babashka](https://babashka.org/) installed on your system

**Install Babashka:**
```bash
# macOS (Homebrew)
brew install babashka/brew/babashka

# Linux (using installer script)
curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | sudo bash

# Or download binary from: https://github.com/babashka/babashka/releases
```

**Install the monitor:**
```bash
git clone https://github.com/simonneutert/github-api-monitor.git
cd github-api-monitor
chmod +x github-api-monitor.clj

# Optional: Add to PATH
echo 'export PATH="'$(pwd)':$PATH"' >> ~/.bashrc  # or ~/.zshrc
```

### Shell Versions

**Quick Install:**

```bash
git clone https://github.com/simonneutert/gh-api-tools.git ~/.gh-api-tools
cd ~/.gh-api-tools && chmod +x github-api-monitor.sh github-api-monitor.zsh github-api-monitor.fish

# Add to your shell config (~/.bashrc or ~/.zshrc):
export PATH="$HOME/.gh-api-tools:$PATH"

# Optional: Create convenient aliases
alias gh-rate='github-api-monitor.sh'      # Bash users
alias gh-rate='github-api-monitor.zsh'     # Zsh users (enhanced features)
alias gh-rate='github-api-monitor.fish'    # Fish users (native Fish features)
alias gh-rate-watch='gh-rate --watch'      # Quick watch mode
```

📋 **For complete shell installation instructions, setup, and troubleshooting, see [INSTALL.md](INSTALL.md)**

## 🏃 Quick Start

### Babashka Version (Recommended)

```bash
# Basic usage
./github-api-monitor.clj --token ghp_your_token_here

# JSON output for automation
./github-api-monitor.clj --token ghp_your_token_here --format json

# Continuous monitoring
./github-api-monitor.clj --token ghp_your_token_here --watch --interval 30

# Verbose mode with headers
./github-api-monitor.clj --token ghp_your_token_here --verbose --headers

# Run comprehensive test suite
bb test

# Quick smoke test
bb test-quick
```

### Shell Versions

After installation, you can use either the direct commands or convenient aliases:

#### Using Direct Commands

```bash
# Bash version
github-api-monitor.sh --token ghp_your_token_here

# Zsh version (enhanced features)
github-api-monitor.zsh --token ghp_your_token_here --format json

# Fish version (native Fish features)
github-api-monitor.fish --token ghp_your_token_here --format json
```

#### Using Aliases (if configured)

```bash
# Quick check (uses your gh-rate alias)
gh-rate --token ghp_your_token_here

# Continuous monitoring (uses gh-rate-watch alias)
gh-rate-watch --token ghp_your_token_here --interval 30

# Tab completion works with Zsh and Fish versions!
github-api-monitor.zsh --format <TAB>   # Shows: table json compact
github-api-monitor.fish --format <TAB>  # Shows: table json compact
```

## 📖 Usage

### Babashka Version

```bash
./github-api-monitor.clj [OPTIONS]
```

### Shell Versions

You can use the scripts in two ways:

```bash
# Direct commands (always work)
github-api-monitor.sh [OPTIONS]
github-api-monitor.zsh [OPTIONS]
github-api-monitor.fish [OPTIONS]

# Convenient aliases (if you set them up during installation)
gh-rate [OPTIONS]              # Points to your preferred version
gh-rate-watch [OPTIONS]        # Quick watch mode
```

### Command Options

| Option                   | Description                               | Default                 |
| ------------------------ | ----------------------------------------- | ----------------------- |
| `-t, --token TOKEN`      | GitHub personal access token (required)   | -                       |
| `-f, --format FORMAT`    | Output format: `table`, `json`, `compact` | `table`                 |
| `-c, --config FILE`      | Configuration file path                   | `~/.github-api-monitor` |
| `-w, --watch`            | Continuous monitoring mode                | `false`                 |
| `-i, --interval SECONDS` | Refresh interval for watch mode           | `60`                    |
| `-H, --headers`          | Show raw HTTP headers                     | `false`                 |
| `-v, --verbose`          | Enable verbose output                     | `false`                 |
| `-h, --help`             | Show help message                         | -                       |
| `--version`              | Show version information                  | -                       |
| `--setup-fish`           | Add Fish shell abbreviations (Fish only)  | -                       |

### Fish Shell Abbreviations

Fish users can set up convenient abbreviations for faster access:

```fish
# Set up abbreviations (run once in Fish)
./github-api-monitor.fish --setup-fish

# After setup, use these shortcuts:
gh-rate --token YOUR_TOKEN                    # Basic monitoring
gh-rate-json --token YOUR_TOKEN               # JSON output
gh-rate-watch --token YOUR_TOKEN              # Continuous monitoring
gh-rate-verbose --token YOUR_TOKEN            # Verbose output
```

The abbreviations persist across Fish sessions and expand when you type them, providing convenient shortcuts while maintaining full transparency.

## ⚙️ Configuration

### Token Setup

Create a GitHub Personal Access Token:

1. Go to **GitHub Settings** → **Developer settings** → **Personal access tokens**
2. Generate a new token (classic or fine-grained)
3. **No special scopes required** - basic access is sufficient

### Config File

Store your token to avoid passing it each time:

```bash
echo "GITHUB_TOKEN=ghp_your_token_here" > ~/.github-api-monitor

# Now use without --token flag
github-api-monitor.sh    # Direct command
gh-rate                  # Or alias (if configured)
```

### Environment Variables

| Variable                    | Description                  |
| --------------------------- | ---------------------------- |
| `GITHUB_TOKEN`              | GitHub personal access token |
| `GITHUB_API_MONITOR_CONFIG` | Alternative config file path |

## 📊 Output Formats

### Table Format (Default)

```
GitHub GraphQL API Rate Limit Status
=====================================

User:                your-username
Current Time:        2025-09-13 10:30:45 UTC

Rate Limit Information:
Limit:               5000 points/hour
Used:                150 points (3.0%)
Remaining:           4850 points
Status:              Low
Query Cost:          1 points

Reset Information:
Reset Time:          2025-09-13 11:00:00 UTC
Time Remaining:      29m

Recommendations:
✓  Usage is within normal limits
```

### JSON Format

```json
{
  "timestamp": "2025-09-13T10:30:45Z",
  "user": "your-username",
  "rateLimit": {
    "limit": 5000,
    "used": 150,
    "remaining": 4850,
    "usagePercentage": 3.0,
    "resetAt": "2025-09-13T11:00:00Z",
    "cost": 1
  },
  "status": "low"
}
```

### Compact Format

```
your-username: 150/5000 (3.0%) - 4850 remaining
```

## 🔧 Examples

### Basic Monitoring

#### Babashka Version (Recommended)

```bash
# Check current status
./github-api-monitor.clj --token ghp_your_token_here

# With verbose logging and headers
./github-api-monitor.clj --token ghp_your_token_here --verbose --headers

# Compact format for quick checks
./github-api-monitor.clj --format compact
```

#### Shell Versions

```bash
# Check current status (direct command)
github-api-monitor.sh --token ghp_your_token_here

# Or using alias (if configured)
gh-rate --token ghp_your_token_here

# With verbose logging
github-api-monitor.sh --token ghp_your_token_here --verbose
```

### Continuous Monitoring

#### Babashka Version (Recommended)

```bash
# Continuous monitoring with 30-second intervals
./github-api-monitor.clj --token ghp_your_token_here --watch --interval 30

# JSON output for parsing and automation
./github-api-monitor.clj --token ghp_your_token_here --watch --format json --interval 60
```

#### Shell Versions

```bash
# Direct command approach
github-api-monitor.sh --token ghp_your_token_here --watch --interval 30

# Or using alias (if configured)
gh-rate-watch --token ghp_your_token_here --interval 30

# JSON output for parsing (zsh version)
github-api-monitor.zsh --token ghp_your_token_here --watch --format json
```

### Scripting Integration

#### Babashka Version (Recommended)

```bash
# Get usage percentage for automation - cleaner JSON parsing
USAGE=$(./github-api-monitor.clj --token ghp_your_token_here --format json | jq -r '.rateLimit.usagePercentage')

if (( $(echo "$USAGE > 90.0" | bc -l) )); then
    echo "⚠️  API usage critical: ${USAGE}%"
    exit 1
fi

# Or use compact format for simple parsing
COMPACT=$(./github-api-monitor.clj --format compact)
echo "Current status: $COMPACT"
```

#### Shell Versions

```bash
# Get usage percentage for automation (use direct command for reliability)
USAGE=$(github-api-monitor.sh --token ghp_your_token_here --format json | jq -r '.rateLimit.usagePercentage')

if (( $(echo "$USAGE > 90" | bc -l) )); then
    echo "⚠️  API usage critical: ${USAGE}%"
    exit 1
fi
```

### CI/CD Pipeline

#### Babashka Version (Recommended)

```yaml
# GitHub Actions example with Babashka
- name: Setup Babashka
  uses: tachyons/setup-babashka@v1
  with:
    babashka-version: 1.3.185

- name: Check API Rate Limits
  run: |
    ./github-api-monitor.clj --token ${{ secrets.GITHUB_TOKEN }} --format compact
    if [ $? -ne 0 ]; then
      echo "Rate limit check failed"
      exit 1
    fi
```

#### Shell Versions

```yaml
# GitHub Actions example (you'd need to install in CI too)
- name: Check API Rate Limits
  run: |
    github-api-monitor.sh --token ${{ secrets.GITHUB_TOKEN }} --format compact
    if [ $? -ne 0 ]; then
      echo "Rate limit check failed"
      exit 1
    fi
```

## 🧪 Testing

### Babashka Version Testing

The Babashka implementation includes a comprehensive test suite via `bb.edn` tasks:

```bash
# Run all tests (comprehensive test suite)
bb test

# Quick smoke test (fast validation)
bb test-quick

# List available tasks
bb tasks
```

#### Test Coverage

The test suite validates:

1. **Help functionality** - Validates `--help` output and content
2. **Version display** - Confirms `--version` shows correct version number
3. **Error handling** - Tests invalid token handling with proper exit codes
4. **Output formats** - Validates table, JSON, and compact formats
5. **Configuration loading** - Confirms config file detection and token loading

#### Test Features

- **🎯 Comprehensive coverage** of all major functionality
- **⚡ Process isolation** - Each test runs CLI as separate process
- **🛡️ Graceful degradation** - Skips tests when tokens unavailable
- **📊 Clear reporting** - Emoji indicators and detailed status messages
- **🔄 Smart token detection** - Uses environment or config file when available

#### Sample Test Output

```
🧪 Testing GitHub API Monitor (Babashka Implementation)
= ============================================================

1️⃣  Testing help functionality...
✅ Help test passed
   ✓ Help message contains expected title

2️⃣  Testing version display...
✅ Version test passed
   ✓ Version number correct

3️⃣  Testing error handling with invalid token...
✅ Invalid token error handling passed

4️⃣  Testing output formats...
   Testing table format...
   ✅ Table format test passed
   Testing JSON format...
   ✅ JSON format test passed
   Testing compact format...
   ✅ Compact format test passed

5️⃣  Testing configuration file loading...
   ✅ Configuration file exists
   ✅ Configuration loading test passed

🎉 Test suite completed!
= ============================================================
```

## 🏗️ Architecture

The project provides multiple implementations optimized for different use cases:

### Babashka Version (Modern Architecture)

```
github-api-monitor/
├── github-api-monitor.clj    # 🎯 Babashka/Clojure implementation (RECOMMENDED)
├── bb.edn                    # Babashka build configuration with test tasks
└── README.md                 # This documentation
```

**Babashka Implementation Features:**
- **Self-contained**: Single file with all functionality
- **Fast startup**: Native binary execution via GraalVM
- **Built-in libraries**: HTTP client, JSON processing, CLI parsing, file system operations
- **Advanced error handling**: Comprehensive exception handling with specific error types
- **Security-first**: File permission validation, token pattern checking
- **Professional output**: Sophisticated formatting with color detection
- **Built-in testing**: Comprehensive test suite via `bb.edn` tasks

### Shell Versions (Multi-Shell Architecture)

The shell versions use a hybrid approach with shared components:

```
gh-api-tools/
├── github-api-monitor.sh     # Bash implementation
├── github-api-monitor.zsh    # Zsh implementation
├── github-api-monitor.fish   # Fish implementation
├── shared/
│   ├── core.sh              # Common utilities (POSIX compatible)
│   ├── api.sh               # GitHub API interaction
│   └── formatters.sh        # Output formatting
├── completions/
│   └── github-api-monitor.fish  # Fish shell completions
└── README.md                # This file
```

### Implementation Comparison

**Babashka Version (Recommended):**
- **Runtime**: Native binary (GraalVM compiled)
- **Startup time**: < 100ms
- **Dependencies**: Only Babashka binary required
- **Error handling**: Comprehensive with specific exception types
- **Maintainability**: Single file, modern language features
- **Security**: Built-in file permission and token validation
- **Cross-platform**: Excellent (native binaries available)

**Shell Versions:**

**Bash Version:**
- Full compatibility with bash 3.2+
- Uses traditional bash argument parsing
- Standard error handling

**Zsh Version:**
- Enhanced argument parsing with `zparseopts`
- Built-in tab completion support
- Improved error handling with Zsh features
- Better signal management

**Fish Version:**
- Native Fish argument parsing with `argparse`
- Advanced tab completion system
- Fish abbreviations for convenient shortcuts
- Fish-specific variable handling and syntax
- Enhanced signal handling with Fish event system

### Cross-Platform Compatibility

**Babashka Version:**
- **Native binaries**: Available for Linux, macOS, Windows
- **No runtime dependencies**: Self-contained executable
- **Consistent behavior**: Same functionality across all platforms

**Shell Versions:**
- **POSIX awk compliance**: All `awk` usage strictly follows POSIX standards for maximum compatibility across Linux, macOS, and other Unix-like systems
- **Portable shell scripting**: Uses POSIX-compatible features wherever possible
- **Standard utilities**: Relies only on common Unix utilities (curl, jq, awk) available across platforms

## 🚧 Exit Codes

| Code | Description          |
| ---- | -------------------- |
| `0`  | Success              |
| `1`  | General error        |
| `2`  | Invalid arguments    |
| `3`  | Missing dependencies |
| `4`  | Authentication error |
| `5`  | API error            |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📜 License

This project is licensed under the MIT License.

---

<div align="center">

**[⭐ Star this repo](https://github.com/simonneutert/gh-api-tools)** if you find it helpful!

Made with ❤️ and 🤖🧃 (Copilot and Claude) by [Simon Neutert](https://github.com/simonneutert)

</div>
