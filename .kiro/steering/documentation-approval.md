---
inclusion: always
---

# Documentation Change Approval Required

## Critical Rule: Always Ask Permission for Documentation Changes

**MANDATORY**: Before making ANY changes to documentation files, you MUST ask the user for explicit permission and explain exactly what you plan to change and why.

### Files Requiring Approval

Documentation files that require permission before modification:
- `README.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `DOCUMENTATION.md`
- `SECURITY.md`
- `AI_ASSISTANT_GUIDE.md`
- Any `.md` files in the `docs/` directory
- Any other markdown files that serve as project documentation

### Required Process

1. **Stop before making changes** - Do not modify documentation files automatically
2. **Ask for permission** - Clearly state you want to modify a documentation file
3. **Explain the changes** - Detail exactly what you plan to change and why
4. **Wait for approval** - Only proceed after receiving explicit user consent
5. **Make changes only after approval** - Never assume permission is granted

### Example Request Format

```
I would like to update [FILENAME] to [BRIEF DESCRIPTION OF CHANGE].

Specifically, I plan to:
- [Detailed change 1]
- [Detailed change 2]
- [etc.]

Reason: [Why this change is needed]

May I proceed with these changes?
```

### Exceptions

The ONLY exceptions are:
- Code comments within source files (`.swift`, `.js`, etc.)
- Steering files in `.kiro/steering/` (when explicitly requested by user)
- Configuration files that are not documentation

### Why This Matters

- Documentation represents the project's public face
- Changes affect how users and contributors understand the project
- User maintains editorial control over project messaging
- Prevents unwanted or incorrect documentation updates

## Remember

**Always ask first, explain clearly, wait for approval.**