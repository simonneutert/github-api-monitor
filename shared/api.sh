#!/bin/sh

#
# GitHub GraphQL API Rate Limit Monitor - API Functions
#
# POSIX-compatible API interaction functions
# These functions handle all GitHub API communication
#

#
# API interaction functions
#
make_graphql_request() {
    _query="${1}"
    _temp_file=""

    # Create temporary file for headers
    if ! _temp_file=$(mktemp); then
        log_error "Failed to create temporary file"
        return 5
    fi

    # Prepare JSON payload
    _json_payload=""
    _json_payload=$(printf '%s' "${_query}" | jq -R .)
    _jq_exit_code=$?
    if [ ${_jq_exit_code} -ne 0 ]; then
        log_error "Failed to prepare JSON payload"
        rm -f "${_temp_file}"
        return 5
    fi

    log_debug "Making GraphQL request to ${GITHUB_API_URL}"

    # Make the API request with proper escaping
    _response=""
    _response=$(curl \
        --silent \
        --show-error \
        --fail \
        --header "Authorization: Bearer ${GITHUB_TOKEN}" \
        --header "Content-Type: application/json" \
        --header "User-Agent: github-api-monitor/1.0.0" \
        --dump-header "${_temp_file}" \
        --data "{\"query\": ${_json_payload}}" \
        "${GITHUB_API_URL}" 2>&1)
    _curl_exit_code=$?

    if [ ${_curl_exit_code} -eq 0 ]; then
        # Extract headers if requested
        if [ "${SHOW_HEADERS}" = "true" ]; then
            printf "\n%bHTTP Headers:%b\n" "${BOLD}" "${NC}"
            cat "${_temp_file}"
            printf "\n"
        fi

        # Check for GraphQL errors
        if echo "${_response}" | jq -e '.errors' >/dev/null 2>&1; then
            log_error "GraphQL API returned errors:"
            echo "${_response}" | jq -r '.errors[] | "  - \(.message)"'
            rm -f "${_temp_file}"
            return 5
        fi

        rm -f "${_temp_file}"
        echo "${_response}"
        return 0
    else
        log_error "Failed to make API request: ${_response}"
        rm -f "${_temp_file}"
        return 5
    fi
}

get_rate_limit_info() {
    _query='query { viewer { login } rateLimit { limit remaining used resetAt cost } }'
    make_graphql_request "${_query}"
}