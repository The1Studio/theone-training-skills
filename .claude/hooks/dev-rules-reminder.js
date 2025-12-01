#!/usr/bin/env node

/**
 * Development Rules Reminder - PreToolUse Hook
 *
 * Injects modularization reminders before Write/Edit operations.
 * Uses transcript checking to inject only once per ~50 messages for token efficiency.
 *
 * Exit Codes:
 *   0 - Success (non-blocking, allows continuation)
 */

import fs from 'fs';
import os from 'os';

/**
 * Check if reminder was recently injected by scanning transcript
 */
function wasRecentlyInjected(transcriptPath) {
  try {
    if (!transcriptPath || !fs.existsSync(transcriptPath)) {
      // Transcript doesn't exist - inject reminder
      return false;
    }

    const transcript = fs.readFileSync(transcriptPath, 'utf-8');
    const lines = transcript.split('\n');

    // Check last 50 lines for reminder marker
    const recentLines = lines.slice(-50);
    const wasInjected = recentLines.some(line => line.includes('**[IMPORTANT]** Consider Modularization'));

    return wasInjected;

  } catch (error) {
    // If we can't read transcript, assume not injected (fail-open)
    return false;
  }
}

/**
 * Main hook execution
 */
async function main() {
  try {
    // Read hook payload from stdin
    const stdin = fs.readFileSync(0, 'utf-8').trim();

    if (!stdin) {
      process.exit(0);
    }

    const payload = JSON.parse(stdin);
    const toolName = payload.tool_name;

    // Check if reminder was recently injected
    if (wasRecentlyInjected(payload.transcript_path)) {
      process.exit(0);
    }

    const memUsed = Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
    const memTotal = Math.round(os.totalmem() / 1024 / 1024);
    const memPercent = Math.round((memUsed / memTotal) * 100);

    const cpuUsage = Math.round((process.cpuUsage().user / 1000000) * 100);
    const cpuSystem = Math.round((process.cpuUsage().system / 1000000) * 100);

    const reminder = [
      `## Current environment`,
      `- Date time: ${new Date().toLocaleString()}`,
      `- Timezone: ${Intl.DateTimeFormat().resolvedOptions().timeZone}`,
      `- Working directory: ${process.cwd()}`,
      `- OS: ${process.platform}`,
      `- User: ${process.env.USERNAME}`,
      `- Locale: ${process.env.LANG}`,
      `- Memory usage: ${memUsed}MB/${memTotal}MB (${memPercent}%)`,
      `- CPU usage: ${cpuUsage}% user / ${cpuSystem}% system`,
      `- IMPORTANT: Include these environment information when prompting subagents to perform tasks.`,
      ``,
      `## Rules`,
      `- Read and follow development rules: ".claude/workflows/development-rules.md"`,
      `- Read and follow documentation management: ".claude/workflows/documentation-management.md"`,
      `- Markdown files are organized in: Plans → "plans/" directory, Docs → "docs/" directory`,
      `- Report markdown files in the same directory as the plan file`,
      `- IMPORTANT: DO NOT create markdown files out of "plans/" or "docs/" directories UNLESS the user explicitly requests it.`,
      `- Activate skills: Run \`python .claude/scripts/generate_catalogs.py --skills\` to generate a skills catalog and analyze it, then activate the relevant skills that are needed for the task during the process.`,
      `- Execute commands: Run \`python .claude/scripts/generate_catalogs.py --commands\` to generate a commands catalog and analyze it, then execute the relevant SlashCommands that are needed for the task during the process.`,
      `- When skills' scripts are failed to execute, always fix them and run again, repeat until success.`,
      `- Follow **YANGI (You Aren't Gonna Need It) - KISS (Keep It Simple, Stupid) - DRY (Don't Repeat Yourself)** principles`,
      `- Sacrifice grammar for the sake of concision when writing reports.`,
      `- In reports, list any unresolved questions at the end, if any.`,
      `- IMPORTANT: Ensure token consumption efficiency while maintaining high quality.`,
      `- IMPORTANT: Include these rules when prompting subagents to perform tasks.`,
      ``,
      `## **[IMPORTANT] Consider Modularization:**`,
      `- Check existing modules before creating new`,
      `- Analyze logical separation boundaries (functions, classes, concerns)`,
      `- Use kebab-case naming with descriptive names, it's fine if the file name is long because this ensures file names are self-documenting for LLM tools (Grep, Glob, Search)`,
      `- Write descriptive code comments`,
      `- After modularization, continue with main task`,
      `- When not to modularize: Markdown files, plain text files, bash scripts, configuration files, environment variables files, etc.`,
      `- IMPORTANT: Include these considerations when prompting subagents to perform tasks.`,
    ].join('\n');

    console.log(reminder);
    process.exit(0);

  } catch (error) {
    // Fail-open: log error but allow operation to continue
    console.error(`Dev rules hook error: ${error.message}`);
    process.exit(0);
  }
}

main();
