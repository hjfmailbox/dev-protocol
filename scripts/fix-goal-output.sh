#!/usr/bin/env bash
# fix-goal-output.sh
# Deterministically set changed_files in goal-output artifacts from git state.
# Handles both .json and .md formats. Eliminates LLM involvement entirely.

set -e

DIR="${1:-.agents/dev-protocol}"
JSON_PATH="$DIR/goal-output.json"
MD_PATH="$DIR/goal-output.md"

# Get authoritative file list from git (sorted for determinism)
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | sort)

if [ -z "$CHANGED_FILES" ]; then
    echo "Warning: No files changed in HEAD commit" >&2
    exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
FIXED=false

# ── Fix JSON artifact ──────────────────────────────────────────────

if [ -f "$JSON_PATH" ]; then
    if command -v jq >/dev/null 2>&1; then
        # Build JSON array from file list
        FILES_ARRAY=$(echo "$CHANGED_FILES" | jq -R -s 'split("\n") | map(select(. != ""))')
        # Update changed_files field and fix schema
        jq --argjson files "$FILES_ARRAY" '
            .changed_files = $files |
            if (.validation_results | type) == "string" then
                .validation_results = [.validation_results]
            elif (.validation_results | type) != "array" then
                .validation_results = []
            else . end |
            if (.risks_followups | type) == "string" then
                .risks_followups = [.risks_followups]
            elif (.risks_followups | type) != "array" then
                .risks_followups = []
            else . end |
            if (.continuation_handoff | type) != "object" then
                .continuation_handoff = {
                    context: "",
                    boundary: "",
                    next_candidate_goal: "",
                    prompt_seed: ""
                }
            else . end
        ' "$JSON_PATH" > "$JSON_PATH.tmp"
        mv "$JSON_PATH.tmp" "$JSON_PATH"
        FIXED=true
        echo "[JSON] Fixed changed_files and schema in $JSON_PATH"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json, sys
files = '''$CHANGED_FILES'''.strip().split('\n')
with open('$JSON_PATH', 'r') as f:
    data = json.load(f)
data['changed_files'] = files

# Fix schema: validation_results must be array
if isinstance(data.get('validation_results'), str):
    print('[JSON] Fixing validation_results: string -> array', file=sys.stderr)
    data['validation_results'] = [data['validation_results']]
elif not isinstance(data.get('validation_results'), list):
    print('[JSON] Fixing validation_results: missing/invalid -> empty array', file=sys.stderr)
    data['validation_results'] = []

# Fix schema: risks_followups must be array
if isinstance(data.get('risks_followups'), str):
    print('[JSON] Fixing risks_followups: string -> array', file=sys.stderr)
    data['risks_followups'] = [data['risks_followups']]
elif not isinstance(data.get('risks_followups'), list):
    print('[JSON] Fixing risks_followups: missing/invalid -> empty array', file=sys.stderr)
    data['risks_followups'] = []

# Ensure continuation_handoff is an object
if not isinstance(data.get('continuation_handoff'), dict):
    print('[JSON] Fixing continuation_handoff: missing/invalid -> object', file=sys.stderr)
    data['continuation_handoff'] = {
        'context': '',
        'boundary': '',
        'next_candidate_goal': '',
        'prompt_seed': ''
    }

with open('$JSON_PATH', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
        FIXED=true
        echo "[JSON] Fixed changed_files and schema in $JSON_PATH (via python3)"
    else
        echo "Warning: [JSON] Neither jq nor python3 available" >&2
        echo "Warning: [JSON] Deleting $JSON_PATH so test falls back to .md" >&2
        rm -f "$JSON_PATH"
    fi
fi

# ── Fix Markdown artifact ──────────────────────────────────────────

if [ -f "$MD_PATH" ]; then
    # Build the replacement section
    REPLACEMENT="## Changed Files

$(echo "$CHANGED_FILES" | sed 's/^/- /')"

    # Use awk to replace the Changed Files section
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
    ' "$MD_PATH" > "$TEMP_FILE"

    if ! grep -q "^## Changed Files$" "$TEMP_FILE"; then
        echo "Warning: [MD] No '## Changed Files' section found in $MD_PATH" >&2
        rm -f "$TEMP_FILE"
    else
        mv "$TEMP_FILE" "$MD_PATH"
        FIXED=true
        echo "[MD]   Fixed changed_files in $MD_PATH"
    fi
fi

if [ "$FIXED" = false ]; then
    echo "Error: No artifacts found to fix" >&2
    echo "Error: Expected: $JSON_PATH or $MD_PATH" >&2
    exit 1
fi

echo ""
echo "Files included: $FILE_COUNT"
echo ""
echo "Changed files:"
echo "$CHANGED_FILES" | sed 's/^/  - /'
