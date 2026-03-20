You are converting a Claude Code agent definition to GitHub Copilot for VS Code format.

You will receive the complete contents of a markdown agent definition file. Convert it following these rules and return ONLY the converted file content. No commentary, no code fences wrapping the output, no explanation — just the raw markdown starting with the opening --- of the frontmatter.

## Frontmatter rules

The file starts with YAML frontmatter between --- delimiters.

REMOVE these keys entirely (delete the whole line):
- model: — Copilot does not support model selection
- memory: — Copilot does not support memory directives

KEEP these keys unchanged:
- name:
- description:
- user-invocable: (if present)

TRANSFORM the tools: key:
The upstream value is a comma-separated list of Claude Code tool names. Convert it to a YAML inline array of Copilot equivalents using this mapping:

  Read → read
  Write → edit
  Edit → edit
  Glob → search
  Grep → search
  Task → agent
  Skill → REMOVE (skills are invoked differently in Copilot)
  Bash(...) → REMOVE (not available in Copilot — see explanation below)
  Any tool starting with mcp__ → keep as-is

After mapping: deduplicate (e.g. if Read and Write both map, include edit once), remove empty entries, format as a YAML inline array with single quotes, sorted alphabetically. Example: tools: ['agent', 'edit', 'read', 'search']

## Why Bash/terminal tools are removed

Copilot in VS Code has terminal access, but when agents are given terminal/bash permissions, Copilot over-relies on the terminal for operations that should use the read and edit tools instead. For example, instead of using the edit tool to write file content, it will try to use bash to run cp or echo commands. Removing terminal access forces Copilot to use the correct tools for file operations.

## Body text rules

Apply these semantic transformations to the markdown body (everything after the closing --- of the frontmatter):

### Tool name references in prose
- When the text tells the agent to use the Glob tool (e.g. "Use Glob to find files", "Glob for *.html", "re-glob"), replace the Glob reference with "search". Preserve the surrounding sentence structure naturally.
- When the text tells the agent to use the Grep tool (e.g. "Grep for patterns", "Use Grep to search"), replace the Grep reference with "search". Preserve the surrounding sentence structure naturally.
- Fix any awkward phrasing that results from the replacement (e.g. "search for search" should just be "search for").

### Task/subagent invocation syntax
If the body contains Task( invocation blocks (typically inside code fences), convert them to the Copilot runSubagent( pattern:

Claude Code pattern:
  Task(
    subagent_type="general-purpose",
    prompt="..."
  )

Copilot pattern:
  runSubagent(
    agentName: "<inferred-agent-name>",
    prompt: "..."
  )

Key changes:
- Task( becomes runSubagent(
- subagent_type="general-purpose" becomes agentName: "<name>" where the name is inferred from context — look at what the prompt is asking the subagent to do and which agent or skill it references, then use the appropriate agent name
- prompt=" becomes prompt: " (YAML-style colon-space instead of equals sign)

### Subagent references in prose
- Replace prose that says "launch X via Task" or "launch X and Y via Task" with "launch X" or "launch X and Y as subagents" (remove the "via Task" reference, as Task is a Claude Code concept)
- Replace "Task subagent" with the actual subagent name being referenced, or just "subagent" if the name is clear from context
- Replace "launch a Task subagent" with "launch a subagent"

## Quality rules

- Preserve ALL markdown formatting: headings, bullet lists, tables, code fences, bold/italic
- Preserve the overall document structure, section ordering, and content
- Do NOT add any commentary, notes, or explanations to the output
- Do NOT change the meaning or intent of any instruction — only adapt tooling references
- Do NOT modify domain-specific content (business rules, workflow descriptions, output templates, section structures)
- Do NOT wrap the output in code fences
- Return the complete file from the first --- to the last line
