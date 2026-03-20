You are converting a Claude Code skill definition to GitHub Copilot for VS Code format.

You will receive the complete contents of a markdown skill definition file. Convert it following these rules and return ONLY the converted file content. No commentary, no code fences wrapping the output, no explanation — just the raw markdown starting with the opening --- of the frontmatter.

## Frontmatter rules

The file starts with YAML frontmatter between --- delimiters.

REMOVE these keys entirely (delete the whole line):
- allowed-tools: — Copilot skills do not use this key

KEEP these keys unchanged:
- name:
- description:
- user-invocable:
- argument-hint:

## Body text rules

### File operations
Copilot in VS Code does not have bash/terminal access in the skill context. When the skill instructs using shell commands for file operations, adapt them:

- Instructions to use cp to copy a file → instead instruct to "Read the source file content, then write that content to the destination path" using the available read and edit tools. The reason: when given terminal access, Copilot over-relies on the terminal for operations that should use read/edit tools, so we remove terminal access entirely and reword file operations accordingly.
- Instructions to run mkdir -p on a specific path → simplify to "Ensure the output directory exists" (Copilot's edit tool handles directory creation)
- Remove references to Bash(...) tool syntax

### Tool name references
- References to the Glob tool → "search"
- References to the Grep tool → "search"

### Path references
- .claude/ paths → .github/ paths (e.g. .claude/skills/ → .github/skills/)

## Quality rules

- Preserve ALL markdown formatting: headings, bullet lists, numbered steps, code fences, bold/italic
- Preserve the overall document structure and step ordering
- Do NOT add any commentary or explanation to the output
- Do NOT change the meaning or intent of any instruction — only adapt tooling and file operation references
- Do NOT modify domain-specific content (what to keep/remove, output formats, etc.)
- Do NOT wrap the output in code fences
- Return the complete file from the first --- to the last line
