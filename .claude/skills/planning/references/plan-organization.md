# Plan Creation & Organization

## Directory Structure

### Plan Location
Save plans in `./plans` directory with timestamp and descriptive name.

**Format:** `plans/YYYYMMDD-HHmm-your-plan-name/`

**Example:** `plans/20251101-1505-authentication-and-profile-implementation/`

### File Organization

```
plans/
├── 20251101-1505-authentication-and-profile-implementation/
    ├── research/
    │   ├── researcher-XX-report.md
    │   └── ...
│   ├── reports/
│   │   ├── scout-report.md
│   │   ├── researcher-report.md
│   │   └── ...
│   ├── plan.md                                # Overview access point
│   ├── phase-01-setup-environment.md          # Setup environment
│   ├── phase-02-implement-database.md         # Database models
│   ├── phase-03-implement-api-endpoints.md    # API endpoints
│   ├── phase-04-implement-ui-components.md    # UI components
│   ├── phase-05-implement-authentication.md   # Auth & authorization
│   ├── phase-06-implement-profile.md          # Profile page
│   └── phase-07-write-tests.md                # Tests
└── ...
```

### Active Plan State Tracking

**State File:** `<WORKING-DIR>/.claude/active-plan`

`<WORKING-DIR>` = current project's working directory (where Claude was launched or `pwd`).

- Contains path to current working plan (e.g., `plans/20251128-1654-feature-name`)
- All agents read this file to determine report output location
- Commands check this file before creating new plan folders

**Pre-Creation Check:**
```bash
# Before creating any plan folder:
if [ -f "<WORKING-DIR>/.claude/active-plan" ]; then
  ACTIVE=$(cat <WORKING-DIR>/.claude/active-plan)
  if [ -d "$ACTIVE" ]; then
    # Ask user: "Continue with existing plan? [Y/n]"
    # Y → reuse $ACTIVE
    # n → create new, update active-plan
  fi
fi
```

**Report Output Rules:**
1. Read `<WORKING-DIR>/.claude/active-plan` to get plan path
2. Write reports to `{plan-path}/reports/`
3. Use naming: `{agent}-{YYMMDD}-{slug}.md`
4. Fallback: `plans/reports/` if no active-plan exists

## File Structure

### Overview Plan (plan.md)
- Keep generic and under 80 lines
- List each phase with status/progress
- Link to detailed phase files
- Key dependencies

### Phase Files (phase-XX-name.md)
Fully respect the `./docs/development-rules.md` file.
Each phase file should contain:

**Context Links**
- Links to related reports, files, documentation

**Overview**
- Priority
- Current status
- Brief description

**Key Insights**
- Important findings from research
- Critical considerations

**Requirements**
- Functional requirements
- Non-functional requirements

**Architecture**
- System design
- Component interactions
- Data flow

**Related Code Files**
- List of files to modify
- List of files to create
- List of files to delete

**Implementation Steps**
- Detailed, numbered steps
- Specific instructions

**Todo List**
- Checkbox list for tracking

**Success Criteria**
- Definition of done
- Validation methods

**Risk Assessment**
- Potential issues
- Mitigation strategies

**Security Considerations**
- Auth/authorization
- Data protection

**Next Steps**
- Dependencies
- Follow-up tasks
