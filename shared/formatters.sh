#!/bin/sh

#
# GitHub GraphQL API Rate Limit Monitor - Output Formatters
#
# POSIX-compatible output formatting functions
# These functions handle all output formatting across different modes
#

# Colors are defined in core.sh and available here

#
# Output formatting functions
#
format_table_output() {
    _data="${1}"

    _viewer_login="" _limit="" _remaining="" _used="" _reset_at="" _cost=""
    _viewer_login=$(echo "${_data}" | jq -r '.data.viewer.login')
    _limit=$(echo "${_data}" | jq -r '.data.rateLimit.limit')
    _remaining=$(echo "${_data}" | jq -r '.data.rateLimit.remaining')
    _used=$(echo "${_data}" | jq -r '.data.rateLimit.used')
    _reset_at=$(echo "${_data}" | jq -r '.data.rateLimit.resetAt')
    _cost=$(echo "${_data}" | jq -r '.data.rateLimit.cost')

    _usage_percentage=""
    _usage_percentage=$(calculate_usage_percentage "${_used}" "${_limit}")

    _reset_formatted=""
    _reset_formatted=$(format_timestamp "${_reset_at}")

    _time_remaining=""
    _time_remaining=$(calculate_time_remaining "${_reset_at}")

    _usage_status=""
    _usage_status=$(get_usage_status "${_usage_percentage}")

    printf "\n"
    printf "%bGitHub GraphQL API Rate Limit Status%b\n" "${BOLD}" "${NC}"
    printf "%b=====================================%b\n" "${BOLD}" "${NC}"
    printf "\n"
    printf "%-20s %b%s%b\n" "User:" "${CYAN}" "${_viewer_login}" "${NC}"
    printf "%-20s %s\n" "Current Time:" "$(date '+%Y-%m-%d %H:%M:%S UTC')"
    printf "\n"
    printf "%b%bRate Limit Information:%b\n" "${BOLD}" "" "${NC}"
    printf "%-20s %s\n" "Limit:" "${_limit} points/hour"
    printf "%-20s %s\n" "Used:" "${_used} points (${_usage_percentage}%)"
    printf "%-20s %s\n" "Remaining:" "${_remaining} points"
    printf "%-20s %b\n" "Status:" "${_usage_status}${NC}"
    printf "%-20s %s\n" "Query Cost:" "${_cost} points"
    printf "\n"
    printf "%b%bReset Information:%b\n" "${BOLD}" "" "${NC}"
    printf "%-20s %s\n" "Reset Time:" "${_reset_formatted}"
    printf "%-20s %s\n" "Time Remaining:" "${_time_remaining}"

    # Add recommendations
    printf "\n"
    printf "%b%bRecommendations:%b\n" "${BOLD}" "" "${NC}"
    if echo "${_usage_percentage}" | awk '{exit !($1 >= 90)}'; then
        printf "%b⚠%b  Critical usage! Consider:\n" "${RED}" "${NC}"
        printf "   • Pause non-essential API calls\n"
        printf "   • Wait for rate limit reset\n"
        printf "   • Optimize queries to use fewer points\n"
    elif echo "${_usage_percentage}" | awk '{exit !($1 >= 75)}'; then
        printf "%b⚠%b  High usage. Consider:\n" "${YELLOW}" "${NC}"
        printf "   • Monitor usage closely\n"
        printf "   • Reduce query complexity\n"
        printf "   • Use smaller page sizes\n"
    else
        printf "%b✓%b  Usage is within normal limits\n" "${GREEN}" "${NC}"
    fi

    printf "\n"
    printf "For more information, visit:\n"
    printf "https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api\n"
}

format_json_output() {
    _data="${1}"

    _timestamp=""
    _timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    _enhanced_data=""
    _enhanced_data=$(echo "${_data}" | jq --arg timestamp "${_timestamp}" '
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

    echo "${_enhanced_data}"
}

format_compact_output() {
    _data="${1}"

    _viewer_login="" _limit="" _remaining="" _used=""
    _viewer_login=$(echo "${_data}" | jq -r '.data.viewer.login')
    _limit=$(echo "${_data}" | jq -r '.data.rateLimit.limit')
    _remaining=$(echo "${_data}" | jq -r '.data.rateLimit.remaining')
    _used=$(echo "${_data}" | jq -r '.data.rateLimit.used')

    _usage_percentage=""
    _usage_percentage=$(calculate_usage_percentage "${_used}" "${_limit}")

    printf "%s: %s/%s (%s%%) - %s remaining\n" \
        "${_viewer_login}" "${_used}" "${_limit}" "${_usage_percentage}" "${_remaining}"
}

#
# Main monitoring function
#
monitor_once() {
    log_debug "Fetching rate limit information..."

    _response=""
    _response=$(get_rate_limit_info)
    _api_exit_code=$?

    if [ ${_api_exit_code} -ne 0 ]; then
        return ${_api_exit_code}
    fi

    case "${OUTPUT_FORMAT}" in
        "json")
            format_json_output "${_response}"
            ;;
        "compact")
            format_compact_output "${_response}"
            ;;
        "table"|*)
            format_table_output "${_response}"
            ;;
    esac
}

monitor_continuous() {
    log_info "Starting continuous monitoring (refresh every ${REFRESH_INTERVAL}s)"
    log_info "Press Ctrl+C to stop"

    # Set up signal handling
    setup_signal_handling

    while true; do
        if [ "${OUTPUT_FORMAT}" = "table" ]; then
            clear
        fi

        monitor_once

        if [ "${OUTPUT_FORMAT}" != "table" ]; then
            printf "---\n"
        fi

        sleep "${REFRESH_INTERVAL}"
    done
}