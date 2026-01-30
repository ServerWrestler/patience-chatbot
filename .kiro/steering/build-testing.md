---
inclusion: always
---

# Build Testing Requirements

## Critical Rule: Always Build After Code Changes

**MANDATORY**: After making ANY code changes to Swift files, you MUST run a build test to verify the changes compile successfully.

### When to Build Test

Build test is required after:
- ✅ Any Swift file modifications (`.swift` files)
- ✅ Adding/removing files from the project
- ✅ Changing project structure or dependencies
- ✅ Modifying enums, structs, classes, or protocols
- ✅ Adding/removing function parameters or return types
- ✅ Changing property names or types

### How to Build Test

Use this exact command:
```bash
xcodebuild -project Patience.xcodeproj -scheme Patience build
```

### Build Test Workflow

1. **Make code changes**
2. **Immediately run build test** - don't wait or skip this step
3. **Fix any compilation errors** before proceeding
4. **Confirm successful build** before considering the task complete

### Why This Matters

- Swift has strict type checking that catches errors at compile time
- Small changes can have cascading effects across the codebase
- Build failures are easier to fix immediately than after multiple changes
- Prevents delivering broken code to the user

### Build Failure Response

If the build fails:
1. **Read the error messages carefully** - Swift errors are usually precise
2. **Fix the immediate compilation errors** first
3. **Run build test again** to verify the fix
4. **Don't make additional changes** until build succeeds

### Exception

The ONLY exception is when making non-code changes like:
- Documentation updates (`.md` files)
- Configuration files that don't affect compilation
- Asset files (images, etc.)

## Remember

**No code change is complete until it builds successfully.**