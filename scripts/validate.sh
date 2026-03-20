#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-output/.github}"
ERRORS=0

echo "=== Validating transformed files ==="

# Allowed frontmatter keys for agents
AGENT_ALLOWED_KEYS="name|description|tools|user-invocable"
# Allowed frontmatter keys for skills
SKILL_ALLOWED_KEYS="name|description|user-invocable|argument-hint|tools"
# Allowed tool names in Copilot
ALLOWED_TOOLS="read|edit|search|agent|execute|runInTerminal"

# Function: extract frontmatter from a markdown file (lines between first and second ---)
extract_frontmatter() {
  sed -n '/^---$/,/^---$/p' "$1" | sed '1d;$d'
}

# Function: extract body from a markdown file (everything after second ---)
extract_body() {
  sed '1,/^---$/d; 1,/^---$/d' "$1"
}

# Function: validate a single file
validate_file() {
  local file="$1"
  local file_type="$2"  # "agent" or "skill"
  local allowed_keys="$3"
  local file_errors=0

  echo ""
  echo "Checking: $file"

  local frontmatter
  frontmatter=$(extract_frontmatter "$file")

  local body
  body=$(extract_body "$file")

  # Check 1-3: Forbidden frontmatter keys
  for forbidden_key in "model:" "memory:" "allowed-tools:"; do
    if echo "$frontmatter" | grep -q "^${forbidden_key}"; then
      echo "  FAIL: Frontmatter contains forbidden key '$forbidden_key'"
      file_errors=$((file_errors + 1))
    fi
  done

  # Check 4: Frontmatter keys from allowed set only
  local keys
  keys=$(echo "$frontmatter" | grep -oP '^\w[\w-]*(?=:)' || true)
  for key in $keys; do
    if ! echo "$key" | grep -qP "^($allowed_keys)$"; then
      echo "  FAIL: Unexpected frontmatter key '$key'"
      file_errors=$((file_errors + 1))
    fi
  done

  # Check 5: Tool names from allowed set
  local tools_line
  tools_line=$(echo "$frontmatter" | grep "^tools:" || true)
  if [ -n "$tools_line" ]; then
    local tool_names
    tool_names=$(echo "$tools_line" | grep -oP "'[^']+'" | tr -d "'" || true)
    for tool in $tool_names; do
      if [[ "$tool" == mcp__* ]]; then
        continue  # MCP tools are allowed
      fi
      if ! echo "$tool" | grep -qP "^($ALLOWED_TOOLS)$"; then
        echo "  FAIL: Invalid tool name '$tool'"
        file_errors=$((file_errors + 1))
      fi
    done
  fi

  # Check 6: No Bash( pattern
  if echo "$frontmatter" "$body" | grep -qP 'Bash\([^)]*\)'; then
    echo "  FAIL: Contains 'Bash(...)' pattern"
    file_errors=$((file_errors + 1))
  fi

  # Check 7: No Task( invocation pattern in body
  if echo "$body" | grep -qP '^\s*Task\('; then
    echo "  FAIL: Body contains 'Task(' invocation pattern"
    file_errors=$((file_errors + 1))
  fi

  # Check 8: No subagent_type= in body
  if echo "$body" | grep -qP 'subagent_type='; then
    echo "  FAIL: Body contains 'subagent_type=' pattern"
    file_errors=$((file_errors + 1))
  fi

  # Check 9: No .claude/ path references in body
  if echo "$body" | grep -qP '\.claude/'; then
    echo "  FAIL: Body contains '.claude/' path reference"
    file_errors=$((file_errors + 1))
  fi

  if [ $file_errors -eq 0 ]; then
    echo "  PASS"
  fi

  ERRORS=$((ERRORS + file_errors))
}

# Validate agent files
AGENT_COUNT=0
for file in "$OUTPUT_DIR"/agents/*.md; do
  validate_file "$file" "agent" "$AGENT_ALLOWED_KEYS"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done

# Validate skill files
SKILL_COUNT=0
for file in "$OUTPUT_DIR"/skills/*/SKILL.md; do
  validate_file "$file" "skill" "$SKILL_ALLOWED_KEYS"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

# Check 10: Expected file counts
echo ""
echo "=== File count check ==="
EXPECTED_AGENTS=7   # 6 transformed + 1 static
EXPECTED_SKILLS=3

echo "Agents: found $AGENT_COUNT, expected $EXPECTED_AGENTS"
if [ "$AGENT_COUNT" -ne "$EXPECTED_AGENTS" ]; then
  echo "  FAIL: Agent count mismatch"
  ERRORS=$((ERRORS + 1))
fi

echo "Skills: found $SKILL_COUNT, expected $EXPECTED_SKILLS"
if [ "$SKILL_COUNT" -ne "$EXPECTED_SKILLS" ]; then
  echo "  FAIL: Skill count mismatch"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -gt 0 ]; then
  echo "=== VALIDATION FAILED: $ERRORS error(s) found ==="
  exit 1
else
  echo "=== VALIDATION PASSED ==="
  exit 0
fi
