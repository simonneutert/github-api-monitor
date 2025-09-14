#!/usr/bin/env fish

#
# GitHub GraphQL API Rate Limit Monitor - Fish Version
#
# A comprehensive script to monitor GitHub GraphQL API rate limits and usage.
# Provides detailed information about your current API consumption, remaining
# quota, reset times, and helpful recommendations.
#
# This is the Fish-optimized version that leverages Fish-specific features
# while maintaining full compatibility with bash and zsh implementations.
#
# Usage: ./github-api-monitor.fish [OPTIONS]
#
# Author: Open Source Community
# License: MIT
# Version: 1.0.0
#

# Fish-specific settings
# Note: fish_greeting is not modified to respect user preferences

# Script metadata
set -g SCRIPT_NAME (basename (status --current-filename))
set -g SCRIPT_VERSION "1.0.0"
set -g SCRIPT_DESCRIPTION "GitHub GraphQL API Rate Limit Monitor (Fish)"

# Configuration
set -g DEFAULT_CONFIG_FILE "$HOME/.github-api-monitor"
set -g GITHUB_API_URL "https://api.github.com/graphql"

# Colors for output formatting
if isatty stdout
    set -g RED '\033[0;31m'
    set -g GREEN '\033[0;32m'
    set -g YELLOW '\033[0;33m'
    set -g BLUE '\033[0;34m'
    set -g CYAN '\033[0;36m'
    set -g BOLD '\033[1m'
    set -g NC '\033[0m'
else
    set -g RED ''
    set -g GREEN ''
    set -g YELLOW ''
    set -g BLUE ''
    set -g CYAN ''
    set -g BOLD ''
    set -g NC ''
end

# Global variables
set -g GITHUB_TOKEN ""
set -g OUTPUT_FORMAT "table"
set -g VERBOSE false
set -g SHOW_HEADERS false
set -g CONTINUOUS_MODE false
set -g REFRESH_INTERVAL 60
set -g CONFIG_FILE ""

# Signal handler for continuous monitoring
function cleanup_handler --on-signal INT --on-signal TERM
    log_info "Monitoring stopped"
    exit 0
end

#
# Logging functions
#
function log_error
    printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$argv" >&2
end

function log_info
    printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$argv" >&2
end

function log_debug
    if test "$VERBOSE" = "true"
        printf "[DEBUG] %s\n" "$argv" >&2
    end
end

#
# Utility functions
#
function show_help
    printf "%s%s%s - %s\n\n" $BOLD $SCRIPT_NAME $NC $SCRIPT_DESCRIPTION
    printf "%sUSAGE:%s\n" $BOLD $NC
    printf "    %s [OPTIONS]\n\n" $SCRIPT_NAME
    printf "%sDESCRIPTION:%s\n" $BOLD $NC
    printf "    Monitor your GitHub GraphQL API rate limits and usage. This script provides\n"
    printf "    detailed information about your current API consumption, remaining quota,\n"
    printf "    reset times, and helpful recommendations for staying within limits.\n\n"
    printf "    This is the Fish-optimized version with enhanced features and native completion.\n\n"
    printf "%sOPTIONS:%s\n" $BOLD $NC
    printf "    -t, --token TOKEN       GitHub personal access token (required)\n"
    printf "    -f, --format FORMAT     Output format: table, json, compact (default: table)\n"
    printf "    -c, --config FILE       Configuration file path (default: ~/.github-api-monitor)\n"
    printf "    -w, --watch             Continuous monitoring mode\n"
    printf "    -i, --interval SECONDS  Refresh interval for watch mode (default: 60)\n"
    printf "    -H, --headers           Show raw HTTP headers\n"
    printf "    -v, --verbose           Enable verbose output\n"
    printf "    -h, --help              Show this help message\n"
    printf "    --version               Show version information\n"
    printf "    --setup-fish            Add Fish shell abbreviations for convenience\n\n"
    printf "%sEXAMPLES:%s\n" $BOLD $NC
    printf "    # Basic usage with token\n"
    printf "    %s --token ghp_xxxxxxxxxxxxxxxxxxxx\n\n" $SCRIPT_NAME
    printf "    # Continuous monitoring with 30-second intervals\n"
    printf "    %s --token ghp_xxxxxxxxxxxxxxxxxxxx --watch --interval 30\n\n" $SCRIPT_NAME
    printf "    # JSON output for scripting\n"
    printf "    %s --token ghp_xxxxxxxxxxxxxxxxxxxx --format json\n\n" $SCRIPT_NAME
    printf "    # Verbose mode with headers\n"
    printf "    %s --token ghp_xxxxxxxxxxxxxxxxxxxx --verbose --headers\n\n" $SCRIPT_NAME
    printf "    # Setup Fish abbreviations for convenience\n"
    printf "    %s --setup-fish\n\n" $SCRIPT_NAME
    printf "%sFISH FEATURES:%s\n" $BOLD $NC
    printf "    This Fish version includes enhanced features:\n"
    printf "    • Native Fish completion support\n"
    printf "    • Fish abbreviations for convenient shortcuts\n"
    printf "    • Enhanced error handling with Fish-specific features\n"
    printf "    • Optimized Fish syntax and functions\n"
    printf "    • Fish-style variable handling\n\n"
    printf "%sTOKEN REQUIREMENTS:%s\n" $BOLD $NC
    printf "    Your GitHub personal access token needs basic access to query the GraphQL API.\n"
    printf "    Both classic personal access tokens and fine-grained tokens are supported.\n\n"
    printf "%sCONFIGURATION:%s\n" $BOLD $NC
    printf "    You can store your token in a configuration file to avoid passing it\n"
    printf "    each time. Create ~/.github-api-monitor with:\n\n"
    printf "    GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx\n\n"
    printf "%sENVIRONMENT VARIABLES:%s\n" $BOLD $NC
    printf "    GITHUB_TOKEN            GitHub personal access token\n"
    printf "    GITHUB_API_MONITOR_CONFIG   Alternative config file path\n\n"
    printf "%sEXIT CODES:%s\n" $BOLD $NC
    printf "    0    Success\n"
    printf "    1    General error\n"
    printf "    2    Invalid arguments\n"
    printf "    3    Missing dependencies\n"
    printf "    4    Authentication error\n"
    printf "    5    API error\n\n"
    printf "For more information, visit: https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api\n"
end

function show_version
    printf "%s %s\n" $SCRIPT_NAME $SCRIPT_VERSION
end

function check_dependencies
    for cmd in curl jq
        if not command -v $cmd >/dev/null 2>&1
            log_error "Missing required dependency: $cmd"
            log_error "Please install $cmd and try again."
            return 3
        end
    end
    return 0
end

#
# Configuration management
#
function load_config
    set -l config_file $argv[1]

    # Determine config file path
    if test -n "$config_file"
        set -g CONFIG_FILE "$config_file"
    else if test -n "$GITHUB_API_MONITOR_CONFIG"
        set -g CONFIG_FILE "$GITHUB_API_MONITOR_CONFIG"
    else
        set -g CONFIG_FILE "$DEFAULT_CONFIG_FILE"
    end

    # Load configuration if file exists
    if test -f "$CONFIG_FILE"
        log_debug "Loading configuration from $CONFIG_FILE"

        # Save command-line token if already set
        set -l saved_token "$GITHUB_TOKEN"

        # Source the config file and extract GITHUB_TOKEN
        if test -r "$CONFIG_FILE"
            # Securely extract the token value from the config file
            set -l token_line ""
            for line in (cat "$CONFIG_FILE")
                if string match -r '^GITHUB_TOKEN=' -- $line
                    set token_line (string replace -r '^GITHUB_TOKEN=' '' -- $line | string trim)
                    break
                end
            end
            if test -n "$token_line"
                # Validate token format: GitHub tokens usually start with ghp_, gho_, etc. but formats may change. Only check for plausible prefix and non-empty value.
                if string match -r '^(gh[pou]_|ghr_|ghs_|github_pat_)' -- $token_line
                    set -g GITHUB_TOKEN $token_line
                else
                    log_error "Invalid token format in config file. Token not set."
                end
            end
        end

        # Restore command-line token if it was provided (takes precedence)
        if test -n "$saved_token"
            set -g GITHUB_TOKEN "$saved_token"
            log_debug "Using command-line token (overriding config file)"
        end
    end
end

function validate_token
    if test -z "$GITHUB_TOKEN"
        log_error "GitHub token is required"
        log_error "Provide it via --token, config file, or GITHUB_TOKEN environment variable"
        return 4
    end

    # Test token validity with a simple API call
    log_debug "Validating token..."
    set -l test_response (curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
                              -H "User-Agent: $SCRIPT_NAME/$SCRIPT_VERSION" \
                              "https://api.github.com/user" 2>&1)

    if test $status -eq 0
        if echo "$test_response" | jq -e '.login' >/dev/null 2>&1
            set -l username (echo "$test_response" | jq -r '.login')
            log_debug "Token validated for user: $username"
        else
            log_error "Token validation failed. API response:"
            echo "$test_response" | jq . 2>/dev/null; or echo "$test_response"
            return 4
        end
    else
        log_error "Failed to validate token: $test_response"
        return 4
    end

    return 0
end

#
# Data processing functions
#
function calculate_usage_percentage
    set -l used $argv[1]
    set -l limit $argv[2]

    if test "$limit" -eq 0
        echo "0"
    else
        # Use awk for floating point arithmetic
        echo "$used $limit" | awk '{printf "%.1f", $1 * 100 / $2}'
    end
end

function format_timestamp
    set -l timestamp $argv[1]
    # Convert ISO 8601 to readable format: 2025-09-13T09:15:15Z -> 2025-09-13 09:15:15 UTC
    echo "$timestamp" | sed 's/T/ /' | sed 's/Z/ UTC/'
end

function calculate_time_remaining
    set -l reset_time $argv[1]

    # Convert ISO 8601 to Unix timestamp
    set -l reset_unix
    if command -v gdate >/dev/null 2>&1
        set reset_unix (gdate -d "$reset_time" +%s 2>/dev/null)
    else
        set reset_unix (date -d "$reset_time" +%s 2>/dev/null)
    end

    # Validate that reset_unix is a non-empty positive integer
    if test -z "$reset_unix"
        log_debug "Failed to parse timestamp: value is empty"
        echo "Unknown"
        return
    else if not string match -rq '^[0-9]+$' "$reset_unix"
        log_debug "Failed to parse timestamp: not a valid number ('$reset_unix')"
        echo "Unknown"
        return
    else if test "$reset_unix" -le 0
        log_debug "Invalid timestamp: not a positive integer ('$reset_unix')"
        echo "Unknown"
        return
    end

    set -l current_time (date +%s)
    set -l diff (math "$reset_unix - $current_time")

    if test "$diff" -le 0
        echo "Now"
    else if test "$diff" -lt 60
        echo "$diff"s
    else if test "$diff" -lt 3600
        echo (math "$diff / 60")"m"
    else
        echo (math "$diff / 3600")"h"
    end
end

function get_usage_status
    set -l percentage $argv[1]

    # Use awk for floating point comparison
    if echo "$percentage" | awk '{exit !($1 >= 90)}'
        printf "$RED%s$NC" "Critical"
    else if echo "$percentage" | awk '{exit !($1 >= 75)}'
        printf "$YELLOW%s$NC" "High"
    else if echo "$percentage" | awk '{exit !($1 >= 50)}'
        printf "$BLUE%s$NC" "Medium"
    else
        printf "$GREEN%s$NC" "Low"
    end
end

#
# API interaction functions
#
function make_graphql_request
    set -l query $argv[1]
    set -l temp_file (mktemp)

    if test $status -ne 0
        log_error "Failed to create temporary file"
        return 5
    end

    # Prepare JSON payload
    set -l json_payload (printf '%s' "$query" | jq -R .)
    if test $status -ne 0
        log_error "Failed to prepare JSON payload"
        rm -f "$temp_file"
        return 5
    end

    log_debug "Making GraphQL request to $GITHUB_API_URL"

    # Make the API request
    set -l response (curl \
        --silent \
        --show-error \
        --fail \
        --header "Authorization: Bearer $GITHUB_TOKEN" \
        --header "Content-Type: application/json" \
        --header "User-Agent: $SCRIPT_NAME/$SCRIPT_VERSION" \
        --dump-header "$temp_file" \
        --data "{\"query\": $json_payload}" \
        "$GITHUB_API_URL" 2>&1)
    set -l curl_exit_code $status

    if test $curl_exit_code -eq 0
        # Extract headers if requested
        if test "$SHOW_HEADERS" = "true"
            printf "\n$BOLD%s$NC\n" "HTTP Headers:"
            cat "$temp_file"
            printf "\n"
        end

        # Check for GraphQL errors
        if echo "$response" | jq -e '.errors' >/dev/null 2>&1
            log_error "GraphQL API returned errors:"
            echo "$response" | jq -r '.errors[] | "  - \(.message)"'
            rm -f "$temp_file"
            return 5
        end

        rm -f "$temp_file"
        echo "$response"
        return 0
    else
        log_error "Failed to make API request: $response"
        rm -f "$temp_file"
        return 5
    end
end

function get_rate_limit_info
    set -l query 'query { viewer { login } rateLimit { limit remaining used resetAt cost } }'
    make_graphql_request "$query"
end

#
# Output formatting functions
#
function format_table_output
    set -l data $argv[1]

    set -l viewer_login (echo "$data" | jq -r '.data.viewer.login')
    set -l limit (echo "$data" | jq -r '.data.rateLimit.limit')
    set -l remaining (echo "$data" | jq -r '.data.rateLimit.remaining')
    set -l used (echo "$data" | jq -r '.data.rateLimit.used')
    set -l reset_at (echo "$data" | jq -r '.data.rateLimit.resetAt')
    set -l cost (echo "$data" | jq -r '.data.rateLimit.cost')

    set -l usage_percentage (calculate_usage_percentage "$used" "$limit")
    set -l reset_formatted (format_timestamp "$reset_at")
    set -l time_remaining (calculate_time_remaining "$reset_at")
    set -l usage_status (get_usage_status "$usage_percentage")

    printf "\n"
    printf "$BOLD%s$NC\n" "GitHub GraphQL API Rate Limit Status"
    printf "$BOLD%s$NC\n" "====================================="
    printf "\n"
    printf "%-20s $CYAN%s$NC\n" "User:" "$viewer_login"
    printf "%-20s %s\n" "Current Time:" (date '+%Y-%m-%d %H:%M:%S UTC')
    printf "\n"
    printf "$BOLD%s$NC\n" "Rate Limit Information:"
    printf "%-20s %s\n" "Limit:" "$limit points/hour"
    printf "%-20s %s\n" "Used:" "$used points ($usage_percentage%)"
    printf "%-20s %s\n" "Remaining:" "$remaining points"
    printf "%-20s %s\n" "Status:" "$usage_status"
    printf "%-20s %s\n" "Query Cost:" "$cost points"
    printf "\n"
    printf "$BOLD%s$NC\n" "Reset Information:"
    printf "%-20s %s\n" "Reset Time:" "$reset_formatted"
    printf "%-20s %s\n" "Time Remaining:" "$time_remaining"

    # Add recommendations
    printf "\n"
    printf "$BOLD%s$NC\n" "Recommendations:"
    if echo "$usage_percentage" | awk '{exit !($1 >= 90)}'
        printf "$RED%s$NC  Critical usage! Consider:\n" "⚠"
        printf "   • Pause non-essential API calls\n"
        printf "   • Wait for rate limit reset\n"
        printf "   • Optimize queries to use fewer points\n"
    else if echo "$usage_percentage" | awk '{exit !($1 >= 75)}'
        printf "$YELLOW%s$NC  High usage. Consider:\n" "⚠"
        printf "   • Monitor usage closely\n"
        printf "   • Reduce query complexity\n"
        printf "   • Use smaller page sizes\n"
    else
        printf "$GREEN%s$NC  Usage is within normal limits\n" "✓"
    end

    printf "\n"
    printf "For more information, visit:\n"
    printf "https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api\n"
end

function format_json_output
    set -l data $argv[1]

    set -l enhanced_data (echo "$data" | jq --arg timestamp (date -u +%Y-%m-%dT%H:%M:%SZ) '
        .data.rateLimit as $rl |
        .data.viewer.login as $user |
        {
            timestamp: $timestamp,
            user: $user,
            rateLimit: {
                limit: $rl.limit,
                used: $rl.used,
                remaining: $rl.remaining,
                usagePercentage: (($rl.used * 100) / $rl.limit * 100 | floor) / 100,
                resetAt: $rl.resetAt,
                resetAtFormatted: ($rl.resetAt | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M:%S UTC")),
                cost: $rl.cost
            },
            status: (
                if (($rl.used * 100) / $rl.limit) >= 90 then "critical"
                elif (($rl.used * 100) / $rl.limit) >= 75 then "high"
                elif (($rl.used * 100) / $rl.limit) >= 50 then "medium"
                else "low"
                end
            )
        }
    ')

    echo "$enhanced_data"
end

function format_compact_output
    set -l data $argv[1]

    set -l viewer_login (echo "$data" | jq -r '.data.viewer.login')
    set -l limit (echo "$data" | jq -r '.data.rateLimit.limit')
    set -l remaining (echo "$data" | jq -r '.data.rateLimit.remaining')
    set -l used (echo "$data" | jq -r '.data.rateLimit.used')

    set -l usage_percentage (calculate_usage_percentage "$used" "$limit")

    printf "%s: %s/%s (%s%%) - %s remaining\n" \
        "$viewer_login" "$used" "$limit" "$usage_percentage" "$remaining"
end

#
# Main monitoring functions
#
function monitor_once
    log_debug "Fetching rate limit information..."

    set -l response (get_rate_limit_info)
    set -l api_exit_code $status

    if test $api_exit_code -ne 0
        return $api_exit_code
    end

    switch "$OUTPUT_FORMAT"
        case "json"
            format_json_output "$response"
        case "compact"
            format_compact_output "$response"
        case "table" "*"
            format_table_output "$response"
    end
end

function monitor_continuous
    log_info "Starting continuous monitoring (refresh every $REFRESH_INTERVAL""s)"
    log_info "Press Ctrl+C to stop"

    # Signal handling is set up at global scope

    while true
        if test "$OUTPUT_FORMAT" = "table"
            clear
        end

        monitor_once

        if test "$OUTPUT_FORMAT" != "table"
            printf "---\n"
        end

        sleep "$REFRESH_INTERVAL"
    end
end

#
# Fish-specific argument parsing
#
function parse_arguments
    argparse 't/token=' 'f/format=' 'c/config=' 'w/watch' 'i/interval=' 'H/headers' 'v/verbose' 'h/help' 'version' 'setup-fish' -- $argv
    or return 2

    if set -q _flag_help
        show_help
        exit 0
    end

    if set -q _flag_version
        show_version
        exit 0
    end

    if set -q _flag_setup_fish
        setup_fish_integration
        exit 0
    end

    if set -q _flag_token
        set -g GITHUB_TOKEN $_flag_token
    end

    if set -q _flag_format
        switch $_flag_format
            case table json compact
                set -g OUTPUT_FORMAT $_flag_format
            case '*'
                log_error "Invalid format: $_flag_format. Must be one of: table, json, compact"
                exit 2
        end
    end

    if set -q _flag_config
        set -g CONFIG_FILE $_flag_config
    end

    if set -q _flag_watch
        set -g CONTINUOUS_MODE true
    end

    if set -q _flag_interval
        if string match -qr '^[1-9][0-9]*$' $_flag_interval
            set -g REFRESH_INTERVAL $_flag_interval
        else
            log_error "Invalid interval: $_flag_interval. Must be a positive integer"
            exit 2
        end
    end

    if set -q _flag_headers
        set -g SHOW_HEADERS true
    end

    if set -q _flag_verbose
        set -g VERBOSE true
    end

    # Check for unknown arguments
    if test (count $argv) -gt 0
        log_error "Unknown arguments: $argv"
        printf "Use --help for usage information\n"
        exit 2
    end
end

#
# Main execution function
#
function main
    # Parse command line arguments
    parse_arguments $argv

    # Check dependencies
    if not check_dependencies
        exit 3
    end

    # Load configuration
    load_config "$CONFIG_FILE"

    # Validate token
    if not validate_token
        exit 4
    end

    # Run monitoring
    if test "$CONTINUOUS_MODE" = "true"
        if not monitor_continuous
            exit 5
        end
    else
        if not monitor_once
            exit 5
        end
    end
end

#
# Fish-specific environment integration
#
function setup_fish_integration
    # Add convenient abbreviations for Fish users
    if not status is-interactive
        log_error "Fish abbreviations can only be set up in an interactive Fish session"
        log_info "Please run this command from an interactive Fish shell"
        return 1
    end

    if command -v abbr >/dev/null 2>&1
        set -l script_path (status --current-filename)

        # Core abbreviations
        abbr --add gh-rate "$script_path"
        abbr --add gh-rate-table "$script_path --format table"
        abbr --add gh-rate-json "$script_path --format json"
        abbr --add gh-rate-compact "$script_path --format compact"
        abbr --add gh-rate-watch "$script_path --watch"
        abbr --add gh-rate-verbose "$script_path --verbose"

        log_info "Fish abbreviations added successfully:"
        log_info "  gh-rate, gh-rate-table, gh-rate-json, gh-rate-compact"
        log_info "  gh-rate-watch, gh-rate-verbose"
        log_info "Type 'abbr --list | grep gh-rate' to see all abbreviations"
        log_info "These abbreviations will be available in future Fish sessions"
    else
        log_error "Fish abbreviations not available in this Fish version"
        return 1
    end
end

# Execute main function if script is run directly
if status is-interactive
    # When running interactively, show help if no arguments
    if test (count $argv) -eq 0
        show_help
        printf "\n$YELLOW%s$NC Fish users can run:\n" "💡 TIP:"
        printf "   %s --setup-fish    # Add convenient abbreviations\n" $SCRIPT_NAME
    else
        main $argv
    end
else
    # When running as script, execute main
    main $argv
end