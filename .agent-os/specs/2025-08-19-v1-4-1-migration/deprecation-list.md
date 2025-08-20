# Deprecation List

> Scripts and files ready for deletion after migration
> Last Updated: 2025-08-20

## Files Ready for Deletion

### After PR 1 Merge

#### deploy-claude-code-sandbox.sh
- **Location**: `/deploy-claude-code-sandbox.sh` (root)
- **Reason**: Functionality moved to sandbox extension
- **Replaced by**: `extensions/sandbox/install.sh` and `extensions/sandbox/launcher.sh`
- **Verification before deletion**:
  - Confirm sandbox extension installs profile correctly
  - Confirm launcher script is installed and symlinked
  - Confirm all functionality is preserved
- **Status**: ✅ Ready for deletion

### After PR 2 Merge

_No files identified yet_

### After Full Migration Complete

#### setup.sh (if refactored)
- **Location**: `/setup.sh` (root)
- **Reason**: To be refactored to use extension system
- **Replaced by**: Refactored version using extension loader
- **Verification before deletion**:
  - Test refactored script maintains all functionality
  - Ensure backward compatibility if needed
- **Status**: ⏳ Pending refactoring (Task 5.1)

#### setup-claude-code.sh (if refactored)
- **Location**: `/setup-claude-code.sh` (root)
- **Reason**: To be refactored to use extension loader
- **Replaced by**: Refactored version using extension system
- **Verification before deletion**:
  - Test refactored script maintains all functionality
  - Ensure all Claude Code specific setup is preserved
- **Status**: ⏳ Pending refactoring (Task 5.2)

## Deletion Process

1. Verify replacement functionality is working
2. Run verification checklist for each file
3. Create backup commit before deletion
4. Delete files in a dedicated cleanup commit
5. Update documentation to remove references

## Notes

- Files marked with ✅ have been fully migrated and tested
- Files marked with ⏳ are pending migration tasks
- Always verify in a clean environment before deletion
- Keep this list updated as more files are migrated