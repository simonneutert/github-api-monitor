# Fish shell completion for github-api-monitor.fish

# Main completion definition
complete -c github-api-monitor.fish -f

# Token option
complete -c github-api-monitor.fish -s t -l token -x -d "GitHub personal access token"

# Format option with choices
complete -c github-api-monitor.fish -s f -l format -x -a "table json compact" -d "Output format"

# Config file option with file completion
complete -c github-api-monitor.fish -s c -l config -F -d "Configuration file path"

# Watch mode (no argument)
complete -c github-api-monitor.fish -s w -l watch -d "Continuous monitoring mode"

# Interval option with common values
complete -c github-api-monitor.fish -s i -l interval -x -a "30 60 120 300 600" -d "Refresh interval in seconds"

# Headers option (no argument)
complete -c github-api-monitor.fish -s H -l headers -d "Show raw HTTP headers"

# Verbose option (no argument)
complete -c github-api-monitor.fish -s v -l verbose -d "Enable verbose output"

# Help option (no argument)
complete -c github-api-monitor.fish -s h -l help -d "Show help message"

# Version option (no argument)
complete -c github-api-monitor.fish -l version -d "Show version information"

# Setup Fish integration (no argument)
complete -c github-api-monitor.fish -l setup-fish -d "Add Fish shell abbreviations for convenience"

# Prevent completion after help, version, or setup-fish flags
complete -c github-api-monitor.fish -n "__fish_contains_opt --help -h --version --setup-fish" -f

# Dynamic completion for format based on what's already typed
complete -c github-api-monitor.fish -n "__fish_contains_opt format f" -x -a "table json compact"