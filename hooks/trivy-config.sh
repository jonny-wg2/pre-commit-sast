#!/bin/bash

# Initialize a variable for additional Trivy arguments
TRIVY_ARGS=""

# Function to add arguments to TRIVY_ARGS
add_arg() {
    local key=$1
    local value=$2
    TRIVY_ARGS+=" $key $value"
}

# Loop through arguments to build TRIVY_ARGS
while [[ $# -gt 0 ]]; do
    case "$1" in
        --args=*)
            IFS='=' read -r _ value <<< "$1"
            # Split the value into two parts: key and value
            IFS=' ' read -r key arg_value <<< "$value"
            add_arg "$key" "$arg_value"
            ;;
        *)
            # Assume it's a file path
            break
            ;;
    esac
    shift
done

# Apply ionice if available (Linux only) and not already running under it
if [[ -z "${IONICE_RUNNING}" ]] && command -v ionice >/dev/null 2>&1; then
    export IONICE_RUNNING=1
    exec ionice -c 2 -n 7 "$0" "$@"
fi

# Auto-detect ignore files only if not already specified
if [[ "$TRIVY_ARGS" != *"--ignorefile"* ]]; then
    if [[ -f ".trivyignore.yaml" ]]; then
        TRIVY_ARGS+=" --ignorefile .trivyignore.yaml"
    elif [[ -f ".trivyignore" ]]; then
        TRIVY_ARGS+=" --ignorefile .trivyignore"
    fi
fi

# Check for custom policy files only if not already specified
if [[ "$TRIVY_ARGS" != *"--config-check"* ]] && [[ -f "trivy-policy.rego" ]]; then
    TRIVY_ARGS+=" --config-check trivy-policy.rego"
fi

OVERALL_EXIT_STATUS=0

# Ensure the cache is valid and clear it if corrupted
# This handles the case where ~/.cache/trivy exists but policy/content is missing
if [[ -d "${HOME}/.cache/trivy" ]] && ! [[ -d "${HOME}/.cache/trivy/policy/content" ]]; then
    echo "Detected corrupted Trivy cache, cleaning..."
    trivy clean --all
fi

# Run individual file scans (trivy conf doesn't support batch scanning)
for file in "$@"; do
    if [[ -f "$file" ]]; then
        echo "Scanning file: $file"
        EXIT_STATUS=0
        # shellcheck disable=SC2086
        trivy conf $TRIVY_ARGS --exit-code 1 "$file" || EXIT_STATUS=$?
        if [ "$EXIT_STATUS" -ne 0 ]; then
            OVERALL_EXIT_STATUS=$EXIT_STATUS
        fi
    fi
done

exit $OVERALL_EXIT_STATUS
