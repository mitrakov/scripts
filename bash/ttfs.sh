#!/bin/bash
set -e
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Initialize default values
NOW=$(date +%Y-%m-%dT%H:%M:%S)
YEAR=$(date +%Y)
ORIGIN="inet"
LOCATION="home"
PERSON="me"
TAGS="no-tag"
FILENAME=""
EXTENSION=""

# Function to display help
function show_help() {
    echo "Usage:   $0 [OPTIONS] <single-file>"
    echo "Example: $0 --origin iphone --location london --person wife --tags my-kids IMG_3832.JPG"
    echo
    echo "┌──────────────────┬────────────────────────────┬─────────┬─────────────────┐"
    echo "│ Option           │ Description                │ Default │ Example         │"
    echo "├──────────────────┼────────────────────────────┼─────────┼─────────────────┤"
    echo "│ --origin ORIGIN  │ File origin (inet, fb, vk) │ inet    │ --origin iphone │"
    echo "│ --location PLACE │ Place, city or country     │ home    │ --location work │"
    echo "│ --person PERSON  │ Person or group of people  │ me      │ --person wife   │"
    echo "│ --tags TAG1-TAG2 │ Dash-separated-tags        │ no-tag  │ --tags my-kids  │"
    echo "│ --help           │ Show this help message     │         │ --help          │"
    echo "│ --               │ End of options marker      │         │ --              │"
    echo "└──────────────────┴────────────────────────────┴─────────┴─────────────────┘"
}


# Show help if no arguments provided
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --origin)
            if [[ -n $2 && $2 != --* ]]; then
                ORIGIN="$2"
                shift 2
            else
                echo "Error: --output requires a value" >&2
                exit 1
            fi
            ;;
        --location)
            if [[ -n $2 && $2 != --* ]]; then
                LOCATION="$2"
                shift 2
            else
                echo "Error: --location requires a value" >&2
                exit 2
            fi
            ;;
        --person)
            if [[ -n $2 && $2 != --* ]]; then
                PERSON="$2"
                shift 2
            else
                echo "Error: --person requires a value" >&2
                exit 3
            fi
            ;;
        --tags)
            if [[ -n $2 && $2 != --* ]]; then
                TAGS="$2"
                shift 2
            else
                echo "Error: --tags requires a value" >&2
                exit 4
            fi
            ;;
        --help)
            show_help
            exit 0
            ;;
        --)
            # End of options marker
            shift
            break
            ;;
        --*)
            echo "Error: Unknown option $1" >&2
            exit 1
            ;;
        *)
            # Non-option argument - treat as positional argument
            break
            ;;
    esac
done

# Extract remaining positional argument
if [[ $# == 1 ]]; then
    FILENAME="$1"
    if [[ -s "$FILENAME" ]]; then                                      # -s = std non-empty file
        EXTENSION="${FILENAME##*.}"
        EXTENSION=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')    # toLowerCase
    else
        echo "Error: File is empty or missing: $1" >&2
        show_help
        exit 5
    fi
else
    echo "Error: Too many arguments: $@" >&2
    show_help
    exit 6
fi

# Debug variables
echo "  File:        $FILENAME"
echo "  --origin:    $ORIGIN"
echo "  --location:  $LOCATION"
echo "  --person:    $PERSON"
echo "  --tags:      $TAGS"

# Main Logic
mkdir -p "$SCRIPT_DIR/$YEAR"
mv -v "$FILENAME" "$SCRIPT_DIR/$YEAR/${NOW}_${ORIGIN}_${LOCATION}_${PERSON}_${TAGS}.$EXTENSION"
