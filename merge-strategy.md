# Upstream Merge Strategy - v1.4.1

## Steps 5+ (After Preservation and Backup)

### Step 5: Perform the Merge
```bash
# Perform merge without committing
git merge upstream/main --no-commit

# Review conflicts
git status
```

### Step 6: Selective Conflict Resolution
```bash
# Keep your custom setup scripts during conflicts
git checkout HEAD -- setup.sh setup-claude-code.sh setup-cursor.sh

# Accept upstream changes for all other files
git add -A

# Complete the merge
git commit -m "Merge upstream v1.4.1 keeping custom setup scripts"
```

### Step 7: Post-Merge Validation
```bash
# Verify merge completeness
git log --oneline -5

# Check for any remaining conflicts
git diff --check

# List modified files
git diff HEAD~1 --name-only
```

### Step 8: Create Modular Structure
```bash
# Create extensions directory for custom code
mkdir -p setup/extensions

# Move custom logic to extension modules
# (Details in implementation section below)
```

### Step 9: Test Installation Scripts
```bash
# Test base installation
./setup/base.sh --help

# Test custom installations
./setup.sh --test

# Verify hooks installation
ls -la ~/.claude/hooks/
```

### Step 10: Update Documentation
- Update CHANGELOG with merge notes
- Document custom extensions
- Update README with new structure

## Post-Merge Implementation Tasks

1. Modularize custom setup code
2. Update path references in instructions
3. Test all custom features
4. Create new spec for tracking
5. Push to origin