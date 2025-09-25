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

# Auto-detect ignore files and add them to TRIVY_ARGS
if [[ -f ".trivyignore.yaml" ]]; then
    TRIVY_ARGS+=" --ignorefile .trivyignore.yaml"
elif [[ -f ".trivyignore" ]]; then
    TRIVY_ARGS+=" --ignorefile .trivyignore"
fi

# Check for custom policy files
if [[ -f "trivy-policy.yaml" ]]; then
    TRIVY_ARGS+=" --config-policy trivy-policy.yaml"
fi

# Apply ionice if available and not already running under it
if [[ -z "${IONICE_RUNNING}" ]] && command -v ionice >/dev/null 2>&1; then
    export IONICE_RUNNING=1
    exec ionice -c 2 -n 7 "$0" "$@"
fi

# Collect all valid files
VALID_FILES=()
for file in "$@"; do
    if [[ -f "$file" ]]; then
        VALID_FILES+=("$file")
    else
        echo "Warning: File not found or not a regular file: $file"
    fi
done

# Exit early if no valid files
if [[ ${#VALID_FILES[@]} -eq 0 ]]; then
    echo "No valid files to scan"
    exit 0
fi

echo "Scanning ${#VALID_FILES[@]} files with Trivy..."

# Run batch scan (all files in one Trivy invocation)
echo " Running with TRIVY_ARGS: $TRIVY_ARGS"
trivy conf "$TRIVY_ARGS" --exit-code 1 "${VALID_FILES[@]}"
