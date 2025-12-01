---
description: ⚡⚡⚡ Intelligent plan creation with prompt enhancement
argument-hint: [task]
---

## Your mission
<task>
$ARGUMENTS
</task>

## Pre-Creation Check (Active Plan Detection)

Before delegating to plan subcommands, check for existing active plan:

1. **Check state file:** If `<WORKING-DIR>/.claude/active-plan` exists and points to valid directory:
   - Ask user: "Active plan found: {path}. Continue with this? [Y/n]"
   - If Y (default): Pass existing plan path to subcommand, skip folder creation
   - If n: Proceed to create new plan (subcommand handles)

2. **Pass plan path explicitly** when delegating to `/plan:fast` or `/plan:hard`

`<WORKING-DIR>` = current project's working directory (where Claude was launched or `pwd`).

## Workflow
- Analyze the given task and ask for more details if needed.
- Decide to use `/plan:fast` or `/plan:hard` SlashCommands based on the complexity.
- Execute SlashCommand: `/plan:fast <detailed-instructions-prompt>` or `/plan:hard <detailed-instructions-prompt>`
- Activate `planning` skill.
- Note: `detailed-instructions-prompt` is **an enhanced prompt** that describes the task in detail based on the provided task description.

## Important Notes
**IMPORTANT:** Analyze the skills catalog and activate the skills that are needed for the task during the process.
**IMPORTANT:** Sacrifice grammar for the sake of concision when writing reports.
**IMPORTANT:** Ensure token efficiency while maintaining high quality.
**IMPORTANT:** In reports, list any unresolved questions at the end, if any.
**IMPORTANT**: **Do not** start implementing.
