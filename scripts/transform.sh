#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-output/.github}"
AGENT_PROMPT_FILE="prompts/transform-agent.md"
SKILL_PROMPT_FILE="prompts/transform-skill.md"

# Create output directories
mkdir -p "$OUTPUT_DIR/agents" "$OUTPUT_DIR/skills"

# Read prompts
AGENT_PROMPT=$(cat "$AGENT_PROMPT_FILE")
SKILL_PROMPT=$(cat "$SKILL_PROMPT_FILE")

# Transform each agent file
for agent_file in agents/*.md; do
  filename=$(basename "$agent_file")
  echo "Transforming agent: $filename"

  file_content=$(cat "$agent_file")
  full_prompt="${AGENT_PROMPT}

---

Here is the file to convert:

${file_content}"

  copilot -p "$full_prompt" \
    --allow-tool=write \
    --no-ask-user \
    > "$OUTPUT_DIR/agents/$filename"
done

# Transform each skill file
for skill_dir in skills/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$OUTPUT_DIR/skills/$skill_name"
  echo "Transforming skill: $skill_name"

  file_content=$(cat "$skill_dir/SKILL.md")
  full_prompt="${SKILL_PROMPT}

---

Here is the file to convert:

${file_content}"

  copilot -p "$full_prompt" \
    --allow-tool=write \
    --no-ask-user \
    > "$OUTPUT_DIR/skills/$skill_name/SKILL.md"
done

# Copy static file (digital-content-processor has no upstream equivalent)
cp static/agents/digital-content-processor.md "$OUTPUT_DIR/agents/digital-content-processor.md"
echo "Copied static: digital-content-processor.md"

echo ""
echo "=== Transformation complete ==="
