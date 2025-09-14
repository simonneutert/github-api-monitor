#!/bin/sh

#
# GitHub GraphQL API Rate Limit Monitor
#
# POSIX-compatible script to monitor GitHub GraphQL API rate limits and usage.
# Provides detailed information about your current API consumption, remaining
# quota, reset times, and helpful recommendations.
#
# Usage: ./github-api-monitor.sh [OPTIONS]
#
# Author: Open Source Community
# License: MIT
# Version: 1.0.0
#

set -eu

# Script metadata
SCRIPT_NAME="$(basename "${0}")"
readonly SCRIPT_NAME
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="GitHub GraphQL API Rate Limit Monitor"

# Determine the script's directory for loading shared components
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
readonly SCRIPT_DIR
readonly SHARED_DIR="${SCRIPT_DIR}/shared"

# Source shared components
if [ -f "${SHARED_DIR}/core.sh" ]; then
    . "${SHARED_DIR}/core.sh"
else
    echo "Error: Cannot find shared/core.sh" >&2
    exit 1
fi

if [ -f "${SHARED_DIR}/api.sh" ]; then
    . "${SHARED_DIR}/api.sh"
else
    echo "Error: Cannot find shared/api.sh" >&2
    exit 1
fi

if [ -f "${SHARED_DIR}/formatters.sh" ]; then
    . "${SHARED_DIR}/formatters.sh"
else
    echo "Error: Cannot find shared/formatters.sh" >&2
    exit 1
fi

# POSIX color overrides (enhancing the shared colors)
if [ -t 1 ] && [ -z "${RED:-}" ]; then
    readonly RED='\033[0;31m'
    readonly BLUE='\033[0;34m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
fi

#
# POSIX logging function overrides
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
show_help() {
    cat << EOF
${BOLD}${SCRIPT_NAME}${NC} - ${SCRIPT_DESCRIPTION}

${BOLD}USAGE:${NC}
    ${SCRIPT_NAME} [OPTIONS]

${BOLD}DESCRIPTION:${NC}
    Monitor your GitHub GraphQL API rate limits and usage. This script provides
    detailed information about your current API consumption, remaining quota,
    reset times, and helpful recommendations for staying within limits.

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
    echo "${SCRIPT_NAME} ${SCRIPT_VERSION}"
}

#
# POSIX signal handling
#
setup_signal_handling() {
    # POSIX signal handling
    trap 'log_info "Monitoring stopped (SIGINT received)"; exit 0' INT
    trap 'log_info "Monitoring stopped (SIGTERM received)"; exit 0' TERM
}

#
# Argument parsing
#
parse_arguments() {
    while [ $# -gt 0 ]; do
        case $1 in
            -t|--token)
                export GITHUB_TOKEN="$2"
                shift 2
                ;;
            -f|--format)
                case "$2" in
                    table|json|compact)
                        export OUTPUT_FORMAT="$2"
                        ;;
                    *)
                        log_error "Invalid format: $2. Must be one of: table, json, compact"
                        exit 2
                        ;;
                esac
                shift 2
                ;;
            -c|--config)
                export CONFIG_FILE="$2"
                shift 2
                ;;
            -w|--watch)
                export CONTINUOUS_MODE=true
                shift
                ;;
            -i|--interval)
                # POSIX-compatible numeric validation
                case "$2" in
                    ''|*[!0-9]*)
                        log_error "Invalid interval: $2. Must be a positive integer"
                        exit 2
                        ;;
                    *)
                        if [ "$2" -gt 0 ] 2>/dev/null; then
                            export REFRESH_INTERVAL="$2"
                        else
                            log_error "Invalid interval: $2. Must be a positive integer"
                            exit 2
                        fi
                        ;;
                esac
                shift 2
                ;;
            -H|--headers)
                export SHOW_HEADERS=true
                shift
                ;;
            -v|--verbose)
                export VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 2
                ;;
        esac
    done
}

#
# Main execution
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
    if [ "${CONTINUOUS_MODE}" = "true" ]; then
        if ! monitor_continuous; then
            exit 5
        fi
    else
        if ! monitor_once; then
            exit 5
        fi
    fi
}

# Execute main function if script is run directly
case "${0}" in
    */github-api-monitor.sh|github-api-monitor.sh)
        main "$@"
        ;;
esac
