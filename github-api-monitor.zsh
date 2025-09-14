#!/usr/bin/env zsh

#
# GitHub GraphQL API Rate Limit Monitor - Zsh Version
#
# A comprehensive script to monitor GitHub GraphQL API rate limits and usage.
# Provides detailed information about your current API consumption, remaining
# quota, reset times, and helpful recommendations.
#
# This is the Zsh-optimized version that leverages Zsh-specific features
# while maintaining compatibility with the shared codebase.
#
# Usage: ./github-api-monitor.zsh [OPTIONS]
#
# Author: Open Source Community
# License: MIT
# Version: 1.0.0
#

# Zsh-specific settings
setopt ERR_EXIT          # Exit on error (equivalent to set -e)
setopt NO_UNSET          # Treat unset variables as error (equivalent to set -u)
setopt PIPE_FAIL         # Fail on pipe errors (equivalent to set -o pipefail)
setopt EXTENDED_GLOB     # Enable extended globbing
setopt NULL_GLOB         # Don't complain if glob doesn't match anything

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="GitHub GraphQL API Rate Limit Monitor (Zsh)"

# Determine the script's directory for loading shared components
readonly SCRIPT_DIR="${0:A:h}"
readonly SHARED_DIR="${SCRIPT_DIR}/shared"

# Source shared components
if [[ -f "${SHARED_DIR}/core.sh" ]]; then
    source "${SHARED_DIR}/core.sh"
else
    print "Error: Cannot find shared/core.sh" >&2
    exit 1
fi

if [[ -f "${SHARED_DIR}/api.sh" ]]; then
    source "${SHARED_DIR}/api.sh"
else
    print "Error: Cannot find shared/api.sh" >&2
    exit 1
fi

if [[ -f "${SHARED_DIR}/formatters.sh" ]]; then
    source "${SHARED_DIR}/formatters.sh"
else
    print "Error: Cannot find shared/formatters.sh" >&2
    exit 1
fi

#
# Zsh-specific utility functions
#
show_help() {
    cat << EOF
${BOLD}${SCRIPT_NAME}${NC} - ${SCRIPT_DESCRIPTION}

${BOLD}USAGE:${NC}
    ${SCRIPT_NAME} [OPTIONS]

${BOLD}DESCRIPTION:${NC}
    Monitor your GitHub GraphQL API rate limits and usage. This script provides
    detailed information about your current API consumption, remaining quota,
    reset times, and helpful recommendations for staying within limits.

    This is the Zsh-optimized version with enhanced features and performance.

${BOLD}OPTIONS:${NC}
    -t, --token TOKEN       GitHub personal access token (required)
    -f, --format FORMAT     Output format: table, json, compact (default: table)
    -c, --config FILE       Configuration file path (default: ~/.github-api-monitor)
    -w, --watch             Continuous monitoring mode
    -i, --interval SECONDS  Refresh interval for watch mode (default: 60)
    -H, --headers           Show raw HTTP headers
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message
    --version               Show version information

${BOLD}EXAMPLES:${NC}
    # Basic usage with token
    ${SCRIPT_NAME} --token ghp_xxxxxxxxxxxxxxxxxxxx

    # Continuous monitoring with 30-second intervals
    ${SCRIPT_NAME} --token ghp_xxxxxxxxxxxxxxxxxxxx --watch --interval 30

    # JSON output for scripting
    ${SCRIPT_NAME} --token ghp_xxxxxxxxxxxxxxxxxxxx --format json

    # Verbose mode with headers
    ${SCRIPT_NAME} --token ghp_xxxxxxxxxxxxxxxxxxxx --verbose --headers

${BOLD}ZSH FEATURES:${NC}
    This Zsh version includes enhanced features:
    • Improved tab completion support
    • Better error handling with Zsh-specific features
    • Enhanced parameter expansion
    • Optimized array handling

${BOLD}TOKEN REQUIREMENTS:${NC}
    Your GitHub personal access token needs basic access to query the GraphQL API.
    Both classic personal access tokens and fine-grained tokens are supported.

${BOLD}CONFIGURATION:${NC}
    You can store your token in a configuration file to avoid passing it
    each time. Create ~/.github-api-monitor with:

    GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

${BOLD}ENVIRONMENT VARIABLES:${NC}
    GITHUB_TOKEN            GitHub personal access token
    GITHUB_API_MONITOR_CONFIG   Alternative config file path

${BOLD}EXIT CODES:${NC}
    0    Success
    1    General error
    2    Invalid arguments
    3    Missing dependencies
    4    Authentication error
    5    API error

For more information, visit: https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api
EOF
}

show_version() {
    print "${SCRIPT_NAME} ${SCRIPT_VERSION}"
}

#
# Zsh-specific signal handling
#
setup_signal_handling() {
    # Zsh-style signal handling with enhanced features
    TRAPINT() {
        log_info "Monitoring stopped (SIGINT received)"
        exit 0
    }

    TRAPTERM() {
        log_info "Monitoring stopped (SIGTERM received)"
        exit 0
    }
}

#
# Zsh-enhanced argument parsing
#
parse_arguments() {
    local -A options
    zparseopts -D -A options \
        t:=token -token:=token \
        f:=format -format:=format \
        c:=config -config:=config \
        w=watch -watch=watch \
        i:=interval -interval:=interval \
        H=headers -headers=headers \
        v=verbose -verbose=verbose \
        h=help -help=help \
        -version=version

    # Process parsed options
    if [[ -n "${options[(i)-h]}" || -n "${options[(i)--help]}" ]]; then
        show_help
        exit 0
    fi

    if [[ -n "${options[(i)--version]}" ]]; then
        show_version
        exit 0
    fi

    if [[ -n "${options[(i)-t]}" ]]; then
        GITHUB_TOKEN="${options[-t]}"
    elif [[ -n "${options[(i)--token]}" ]]; then
        GITHUB_TOKEN="${options[--token]}"
    fi

    if [[ -n "${options[(i)-f]}" ]]; then
        case "${options[-f]}" in
            table|json|compact)
                OUTPUT_FORMAT="${options[-f]}"
                ;;
            *)
                log_error "Invalid format: ${options[-f]}. Must be one of: table, json, compact"
                exit 2
                ;;
        esac
    elif [[ -n "${options[(i)--format]}" ]]; then
        case "${options[--format]}" in
            table|json|compact)
                OUTPUT_FORMAT="${options[--format]}"
                ;;
            *)
                log_error "Invalid format: ${options[--format]}. Must be one of: table, json, compact"
                exit 2
                ;;
        esac
    fi

    if [[ -n "${options[(i)-c]}" ]]; then
        CONFIG_FILE="${options[-c]}"
    elif [[ -n "${options[(i)--config]}" ]]; then
        CONFIG_FILE="${options[--config]}"
    fi

    if [[ -n "${options[(i)-w]}" || -n "${options[(i)--watch]}" ]]; then
        CONTINUOUS_MODE=true
    fi

    if [[ -n "${options[(i)-i]}" ]]; then
        if [[ "${options[-i]}" == <-> && "${options[-i]}" -gt 0 ]]; then
            REFRESH_INTERVAL="${options[-i]}"
        else
            log_error "Invalid interval: ${options[-i]}. Must be a positive integer"
            exit 2
        fi
    elif [[ -n "${options[(i)--interval]}" ]]; then
        if [[ "${options[--interval]}" == <-> && "${options[--interval]}" -gt 0 ]]; then
            REFRESH_INTERVAL="${options[--interval]}"
        else
            log_error "Invalid interval: ${options[--interval]}. Must be a positive integer"
            exit 2
        fi
    fi

    if [[ -n "${options[(i)-H]}" || -n "${options[(i)--headers]}" ]]; then
        SHOW_HEADERS=true
    fi

    if [[ -n "${options[(i)-v]}" || -n "${options[(i)--verbose]}" ]]; then
        VERBOSE=true
    fi

    # Check for unknown arguments
    if [[ $# -gt 0 ]]; then
        log_error "Unknown arguments: $*"
        print "Use --help for usage information"
        exit 2
    fi
}

#
# Main execution function
#
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Check dependencies
    if ! check_dependencies; then
        exit 3
    fi

    # Load configuration
    load_config "${CONFIG_FILE}"

    # Validate token
    if ! validate_token; then
        exit 4
    fi

    # Run monitoring
    if [[ "${CONTINUOUS_MODE}" == "true" ]]; then
        if ! monitor_continuous; then
            exit 5
        fi
    else
        if ! monitor_once; then
            exit 5
        fi
    fi
}

# Zsh-specific completion setup (if running interactively)
if [[ -n "${ZSH_VERSION}" && -o interactive ]]; then
    # Enable completion for this script
    autoload -Uz compinit
    compinit -u

    # Define completion function
    _github_api_monitor_zsh() {
        local context state state_descr line
        typeset -A opt_args

        _arguments \
            '(-t --token)'{-t,--token}'[GitHub personal access token]:token:' \
            '(-f --format)'{-f,--format}'[Output format]:format:(table json compact)' \
            '(-c --config)'{-c,--config}'[Configuration file path]:file:_files' \
            '(-w --watch)'{-w,--watch}'[Continuous monitoring mode]' \
            '(-i --interval)'{-i,--interval}'[Refresh interval in seconds]:seconds:' \
            '(-H --headers)'{-H,--headers}'[Show raw HTTP headers]' \
            '(-v --verbose)'{-v,--verbose}'[Enable verbose output]' \
            '(-h --help)'{-h,--help}'[Show help message]' \
            '--version[Show version information]'
    }

    compdef _github_api_monitor_zsh "${SCRIPT_NAME}"
fi

# Execute main function if script is run directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    main "$@"
fi