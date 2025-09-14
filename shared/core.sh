#!/bin/sh

#
# GitHub GraphQL API Rate Limit Monitor - Core Functions
#
# POSIX-compatible shared functions for multi-shell support
# These functions work across bash, zsh, and can be adapted for fish
#

# Configuration
readonly DEFAULT_CONFIG_FILE="${HOME}/.github-api-monitor"
readonly GITHUB_API_URL="https://api.github.com/graphql"

# Colors (shell-specific scripts may override these)
if [ -t 1 ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# Global variables (to be set by shell-specific scripts)
GITHUB_TOKEN=""
OUTPUT_FORMAT="table"
VERBOSE=false
SHOW_HEADERS=false
CONTINUOUS_MODE=false
REFRESH_INTERVAL=60
CONFIG_FILE=""

#
# Logging functions
#
log_error() {
    printf "%b[ERROR]%b %s\n" "${RED}" "${NC}" "$*" >&2
}

log_info() {
    printf "%b[INFO]%b %s\n" "${BLUE}" "${NC}" "$*" >&2
}

log_debug() {
    if [ "${VERBOSE}" = "true" ]; then
        printf "[DEBUG] %s\n" "$*" >&2
    fi
}

#
# Utility functions
#
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log_error "Missing required dependency: ${cmd}"
            log_error "Please install ${cmd} and try again."
            return 3
        fi
    done
    return 0
}

#
# Configuration management
#
load_config() {
    _config_file="${1:-}"

    # Determine config file path
    if [ -n "${_config_file}" ]; then
        CONFIG_FILE="${_config_file}"
    elif [ -n "${GITHUB_API_MONITOR_CONFIG:-}" ]; then
        CONFIG_FILE="${GITHUB_API_MONITOR_CONFIG}"
    else
        CONFIG_FILE="${DEFAULT_CONFIG_FILE}"
    fi

    # Load configuration if file exists
    if [ -f "${CONFIG_FILE}" ]; then
        log_debug "Loading configuration from ${CONFIG_FILE}"

        # Save command-line token if already set
        _saved_token="${GITHUB_TOKEN:-}"

        # Source the config file in a POSIX-compatible way
        . "${CONFIG_FILE}"

        # Restore command-line token if it was provided (takes precedence)
        if [ -n "${_saved_token}" ]; then
            GITHUB_TOKEN="${_saved_token}"
            log_debug "Using command-line token (overriding config file)"
        fi
    fi
}

validate_token() {
    if [ -z "${GITHUB_TOKEN}" ]; then
        log_error "GitHub token is required"
        log_error "Provide it via --token, config file, or GITHUB_TOKEN environment variable"
        return 4
    fi

    # Test token validity with a simple API call
    log_debug "Validating token..."
    _test_response=""
    if _test_response=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" \
                           -H "User-Agent: github-api-monitor/1.0.0" \
                           "https://api.github.com/user" 2>&1); then
        if echo "${_test_response}" | jq -e '.login' >/dev/null 2>&1; then
            _username=""
            _username=$(echo "${_test_response}" | jq -r '.login')
            log_debug "Token validated for user: ${_username}"
        else
            log_error "Token validation failed. API response:"
            echo "${_test_response}" | jq . 2>/dev/null || echo "${_test_response}"
            return 4
        fi
    else
        log_error "Failed to validate token: ${_test_response}"
        return 4
    fi

    return 0
}

#
# Data processing functions
#
calculate_usage_percentage() {
    _used="${1}"
    _limit="${2}"

    if [ "${_limit}" -eq 0 ]; then
        echo "0"
    else
        # Use awk for POSIX-compatible floating point arithmetic
        echo "${_used}" "${_limit}" | awk '{printf "%.1f", $1 * 100 / $2}'
    fi
}

format_timestamp() {
    _timestamp="${1}"
    # Convert ISO 8601 to readable format: 2025-09-13T09:15:15Z -> 2025-09-13 09:15:15 UTC
    echo "${_timestamp}" | sed 's/T/ /' | sed 's/Z/ UTC/'
}

calculate_time_remaining() {
    _reset_time="${1}"

    # Convert ISO 8601 to Unix timestamp
    _reset_unix=""
    if command -v gdate >/dev/null 2>&1; then
        _reset_unix=$(gdate -d "${_reset_time}" +%s 2>/dev/null)
    elif date -d "1970-01-01" +%s >/dev/null 2>&1; then
        _reset_unix=$(date -d "${_reset_time}" +%s 2>/dev/null)
    elif [ "$(uname)" = "Darwin" ]; then
        # macOS: try BSD date with -j -f
        # ISO 8601: 2025-09-13T09:15:15Z
        _reset_unix=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${_reset_time}" "+%s" 2>/dev/null)
    else
        _reset_unix=""
    fi

    # If date parsing failed, _reset_unix will be empty or not a number
    if [ -z "${_reset_unix}" ] || ! echo "${_reset_unix}" | grep -Eq '^[0-9]+$'; then
        echo "Unknown (timestamp parsing not supported on this platform. If on macOS, install GNU coreutils and use 'gdate'.)"
        return
    fi
    _current_time=""
    _current_time=$(date +%s)
    _diff=$((_reset_unix - _current_time))

    if [ "${_diff}" -le 0 ]; then
        echo "Now"
    elif [ "${_diff}" -lt 60 ]; then
        echo "${_diff}s"
    elif [ "${_diff}" -lt 3600 ]; then
        echo "$((_diff / 60))m"
    else
        echo "$((_diff / 3600))h"
    fi
}

get_usage_status() {
    _percentage="${1}"

    # Use awk for floating point comparison
    if echo "${_percentage}" | awk '{exit !($1 >= 90)}'; then
        printf "%bCritical%b" "${RED}" "${NC}"
    elif echo "${_percentage}" | awk '{exit !($1 >= 75)}'; then
        printf "%bHigh%b" "${YELLOW}" "${NC}"
    elif echo "${_percentage}" | awk '{exit !($1 >= 50)}'; then
        printf "%bMedium%b" "${BLUE}" "${NC}"
    else
        printf "%bLow%b" "${GREEN}" "${NC}"
    fi
}

#
# Shell detection
#
detect_shell() {
    if [ -n "${BASH_VERSION:-}" ]; then
        echo "bash"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        echo "zsh"
    elif [ -n "${FISH_VERSION:-}" ]; then
        echo "fish"
    else
        echo "unknown"
    fi
}

#
# Signal handling setup (shell-specific implementations will override)
#
setup_signal_handling() {
    # Default POSIX signal handling
    trap 'log_info "Monitoring stopped"; exit 0' INT TERM
}