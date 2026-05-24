#!/usr/bin/env bash
# fix-goal-output.sh
# Deterministically set changed_files in goal-output.md from git state
# This script eliminates LLM involvement in changed_files generation

set -e

ARTIFACT="${1:-.agents/dev-protocol/goal-output.md}"

# Verify artifact exists
if [ ! -f "$ARTIFACT" ]; then
    echo "Error: Artifact not found: $ARTIFACT" >&2
    echo "Error: Run this script after creating goal-output.md" >&2
    exit 1
fi

# Get authoritative file list from git (sorted for determinism)
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | sort)

if [ -z "$CHANGED_FILES" ]; then
    echo "Warning: No files changed in HEAD commit" >&2
    echo "Warning: Cannot fix changed_files section" >&2
    exit 0
fi

# Count files for reporting
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

# Build the replacement section
REPLACEMENT="## Changed Files

$(echo "$CHANGED_FILES" | sed 's/^/- /')"

# Use awk to replace the Changed Files section
# Logic:
# - Print everything before "## Changed Files"
# - Insert the replacement section
# - Skip the old Changed Files section
# - Print everything after the next "## " heading
TEMP_FILE=$(mktemp)

awk -v replacement="$REPLACEMENT" '
    /^## Changed Files$/ {
        print replacement
        in_section = 1
        next
    }
    in_section && /^## / {
        in_section = 0
    }
    !in_section {
        print
    }
' "$ARTIFACT" > "$TEMP_FILE"

# Check if replacement happened
if ! grep -q "^## Changed Files$" "$TEMP_FILE"; then
    echo "Warning: No '## Changed Files' section found in $ARTIFACT" >&2
    echo "Warning: File unchanged" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi

# Replace original file
mv "$TEMP_FILE" "$ARTIFACT"

echo "Fixed changed_files in $ARTIFACT"
echo "Files included: $FILE_COUNT"
echo ""
echo "Changed files:"
echo "$CHANGED_FILES" | sed 's/^/  - /'
