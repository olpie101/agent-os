---
description: Commit Plan Validation Workflows for PEER Pattern
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Commit Plan Validation

## Overview

Declarative XML workflows for validating commit plan files in both JSON and Markdown formats. These patterns ensure plan integrity, format compatibility, and structural correctness before execution begins.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

## Plan File Location and Format Detection

<file_detection_workflow>
  
  <step number="1" name="locate_plan_file">
    
    ### Step 1: Locate Plan File
    
    <file_location_validation>
      <directory_check>
        VERIFY: .agent-os/commit-plan/ directory exists
        IF not exists:
          CREATE: directory with proper permissions
          INFORM: user of directory creation
      </directory_check>
      
      <file_existence_check>
        CHECK: specified plan file exists in .agent-os/commit-plan/
        ACCEPT: both .json and .md extensions
        ERROR: if file not found with clear alternatives list
      </file_existence_check>
      
      <file_accessibility>
        VERIFY: file is readable
        CHECK: file size is reasonable (< 1MB)
        VALIDATE: file permissions allow reading
      </file_accessibility>
    </file_location_validation>
    
  </step>
  
  <step number="2" name="detect_file_format">
    
    ### Step 2: Detect File Format
    
    <format_detection_logic>
      <extension_based_detection>
        <json_extension>
          IF file extension equals '.json':
            SET: initial_format = 'json'
            PROCEED: to content validation
        </json_extension>
        
        <markdown_extension>
          IF file extension equals '.md':
            SET: initial_format = 'markdown'  
            PROCEED: to content validation
        </markdown_extension>
        
        <no_extension>
          IF no extension present:
            PROCEED: to content-based detection
        </no_extension>
      </extension_based_detection>
      
      <content_based_detection>
        <read_file_content>
          READ: complete file content
          TRIM: leading and trailing whitespace
          STORE: raw content for analysis
        </read_file_content>
        
        <json_content_detection>
          <structure_check>
            CHECK: content starts with '{' AND ends with '}'
            ATTEMPT: JSON.parse() on content
            IF successful: SET format = 'json'
            IF failed: CONTINUE to markdown detection
          </structure_check>
        </json_content_detection>
        
        <markdown_content_detection>
          <pattern_matching>
            SEARCH for markdown indicators:
              - Lines starting with "# Multi-Commit Plan"
              - Lines starting with "## Commit Groups"  
              - Lines starting with "### Branch:"
              - Lines starting with "#### Commit"
            IF patterns found: SET format = 'markdown'
            IF no patterns: DEFAULT to 'markdown' (safe fallback)
          </pattern_matching>
        </markdown_content_detection>
      </content_based_detection>
    </format_detection_logic>
    
  </step>
  
</file_detection_workflow>

## JSON Plan Validation

<json_validation_workflow>
  
  <step number="1" name="parse_json_structure">
    
    ### Step 1: Parse JSON Structure
    
    <json_parsing>
      <syntax_validation>
        ATTEMPT: JSON.parse() on file content
        IF parsing fails:
          ERROR: "Invalid JSON syntax in plan file"
          PROVIDE: specific error location and description
          STOP: validation workflow
      </syntax_validation>
      
      <structure_extraction>
        EXTRACT: parsed JSON object
        VERIFY: object is not null or empty
        STORE: parsed structure for field validation
      </structure_extraction>
    </json_parsing>
    
  </step>
  
  <step number="2" name="validate_json_schema">
    
    ### Step 2: Validate JSON Schema
    
    <schema_validation>
      <required_root_fields>
        VALIDATE: presence of required fields:
          - version: must equal 1
          - plan_id: must be non-empty string
          - metadata: must be object
          - execution_plan: must be object
        
        IF missing required fields:
          ERROR: "Missing required fields: [list_missing_fields]"
          REFERENCE: "@~/.agent-os/instructions/meta/commit-plan-schema.md"
          STOP: validation workflow
      </required_root_fields>
      
      <metadata_validation>
        WITHIN metadata object:
          REQUIRE: created_at (ISO 8601 timestamp)
          REQUIRE: instruction (must equal "git-commit")
          OPTIONAL: user_intent (string)
        
        VALIDATE: created_at is valid ISO 8601 format
        IF invalid timestamp:
          ERROR: "Invalid timestamp format in metadata.created_at"
          PROVIDE: "Expected ISO 8601 format like 2025-08-13T17:30:00Z"
      </metadata_validation>
      
      <execution_plan_validation>
        WITHIN execution_plan object:
          REQUIRE: commits (must be array)
          VALIDATE: commits array is not empty
          
        IF commits array empty:
          ERROR: "Execution plan must contain at least one commit"
          STOP: validation workflow
      </execution_plan_validation>
    </schema_validation>
    
  </step>
  
  <step number="3" name="validate_commits_array">
    
    ### Step 3: Validate Commits Array
    
    <commit_validation>
      <commit_structure_check>
        FOR each commit in commits array:
          REQUIRE: branch (non-empty string)
          REQUIRE: message (non-empty string)  
          REQUIRE: files (array)
          OPTIONAL: requires_branches (array)
          OPTIONAL: deletions (array)
        
        IF missing required commit fields:
          ERROR: "Commit [index] missing required fields: [list]"
          STOP: validation workflow
      </commit_structure_check>
      
      <file_array_validation>
        FOR each commit:
          VALIDATE: files array contains only strings
          CHECK: file paths are reasonable (not empty, no dangerous patterns)
          WARN: if files array is empty (unusual but not invalid)
          
        IF deletions array present:
          VALIDATE: deletions array contains only strings
          CHECK: deletion paths are reasonable
      </file_array_validation>
      
      <branch_consistency_check>
        EXTRACT: all branch names from commits
        VALIDATE: branch names follow git naming conventions
        CHECK: no branch name conflicts or dangerous characters
        RECORD: unique branches for dependency analysis
      </branch_consistency_check>
    </commit_validation>
    
  </step>
  
</json_validation_workflow>

## Markdown Plan Validation

<markdown_validation_workflow>
  
  <step number="1" name="parse_markdown_structure">
    
    ### Step 1: Parse Markdown Structure
    
    <markdown_parsing>
      <content_preparation>
        SPLIT: content by newline characters
        TRIM: whitespace from each line
        FILTER: remove empty lines for processing
        CREATE: line-by-line processing context
      </content_preparation>
      
      <header_validation>
        SEARCH: for main header "# Multi-Commit Plan"
        IF not found:
          WARN: "Missing standard header, but proceeding with validation"
        
        SEARCH: for "## Commit Groups" section
        IF not found:
          ERROR: "Missing required '## Commit Groups' section"
          PROVIDE: "Markdown plans must contain a Commit Groups section"
          STOP: validation workflow
      </header_validation>
    </markdown_parsing>
    
  </step>
  
  <step number="2" name="validate_branch_sections">
    
    ### Step 2: Validate Branch Sections
    
    <branch_structure_validation>
      <branch_header_detection>
        SEARCH: for lines matching "### Branch: [branch-name]"
        EXTRACT: branch names from headers
        VALIDATE: at least one branch section exists
        
        IF no branch sections found:
          ERROR: "No branch sections found in markdown plan"
          PROVIDE: "Use format: ### Branch: branch-name"
          STOP: validation workflow
      </branch_header_detection>
      
      <branch_name_validation>
        FOR each detected branch name:
          VALIDATE: branch name is not empty
          CHECK: follows git branch naming conventions
          VALIDATE: no dangerous characters or patterns
          RECORD: for commit validation
      </branch_name_validation>
    </branch_structure_validation>
    
  </step>
  
  <step number="3" name="validate_commit_sections">
    
    ### Step 3: Validate Commit Sections
    
    <commit_structure_validation>
      <commit_header_detection>
        SEARCH: for lines matching "#### Commit N: [emoji] [message]"
        EXTRACT: commit messages and sequence numbers
        VALIDATE: at least one commit exists per branch
        
        IF no commit headers found:
          ERROR: "No commit sections found in markdown plan"  
          PROVIDE: "Use format: #### Commit N: 🎯 commit message"
          STOP: validation workflow
      </commit_header_detection>
      
      <commit_content_validation>
        FOR each commit section:
          SEARCH: for "**Files:**" subsection
          EXTRACT: file list following files header
          VALIDATE: at least one file per commit (unless deletion-only)
          
          CHECK: for optional "**Rationale:**" sections
          VALIDATE: file paths are reasonable and safe
      </commit_content_validation>
      
      <file_list_validation>
        WITHIN each commit's file list:
          IDENTIFY: lines starting with "- [filepath]"
          DETECT: deletion markers "(DELETE)"
          EXTRACT: file paths and operation types
          VALIDATE: file paths are not empty
          CHECK: no dangerous path patterns (../, absolute paths with system dirs)
      </file_list_validation>
    </commit_structure_validation>
    
  </step>
  
</markdown_validation_workflow>

## Cross-Format Validation

<cross_format_validation>
  
  <step number="1" name="logical_consistency_check">
    
    ### Step 1: Logical Consistency Check
    
    <consistency_validation>
      <branch_dependency_analysis>
        IF requires_branches specified in any commit:
          VALIDATE: referenced branches exist in plan
          CHECK: no circular dependencies between branches
          WARN: if complex dependency chains detected
      </branch_dependency_analysis>
      
      <file_conflict_detection>
        IDENTIFY: files that appear in multiple commits
        ANALYZE: potential conflicts between branches
        DETECT: files being both added and deleted
        RECORD: dependency information for user decision prompts
      </file_conflict_detection>
      
      <commit_sequence_validation>
        VERIFY: commit sequence makes logical sense
        CHECK: branch creation order aligns with dependencies
        VALIDATE: no impossible git operations
      </commit_sequence_validation>
    </consistency_validation>
    
  </step>
  
  <step number="2" name="execution_feasibility_check">
    
    ### Step 2: Execution Feasibility Check
    
    <feasibility_analysis>
      <git_operation_validation>
        FOR each planned commit:
          SIMULATE: git operations required
          VALIDATE: branch switching is possible
          CHECK: file operations are feasible
          DETECT: potential merge conflicts
      </git_operation_validation>
      
      <repository_state_check>
        VERIFY: current repository state supports execution
        CHECK: working directory is clean (or can be stashed)
        VALIDATE: remote repository accessibility if needed
        CONFIRM: user has necessary git permissions
      </repository_state_check>
      
      <resource_requirements>
        ESTIMATE: execution complexity and time
        CHECK: disk space requirements for stashing
        VALIDATE: network connectivity for remote operations
        WARN: if execution may take significant time
      </resource_requirements>
    </feasibility_analysis>
    
  </step>
  
</cross_format_validation>

## Conversion Validation

<conversion_validation_workflow>
  
  <step number="1" name="pre_conversion_validation">
    
    ### Step 1: Pre-Conversion Validation (Markdown Only)
    
    <pre_conversion_check>
      <structure_completeness>
        VERIFY: all required markdown sections present
        CHECK: branch and commit structures are well-formed
        VALIDATE: file lists are properly formatted
        CONFIRM: no malformed content that would break conversion
      </structure_completeness>
      
      <conversion_requirements>
        ENSURE: all data needed for JSON format is present
        VERIFY: timestamp can be extracted from filename
        CHECK: commit messages and file lists are complete
        VALIDATE: branch information is sufficient
      </conversion_requirements>
    </pre_conversion_check>
    
  </step>
  
  <step number="2" name="post_conversion_validation">
    
    ### Step 2: Post-Conversion Validation (Markdown Only)
    
    <conversion_verification>
      <json_structure_check>
        VALIDATE: converted JSON passes all JSON validation rules
        VERIFY: no data loss during conversion process
        CHECK: all commits and files are preserved
        CONFIRM: metadata fields are properly generated
      </json_structure_check>
      
      <consistency_verification>
        COMPARE: original markdown content with converted JSON
        VERIFY: commit count matches between formats
        CHECK: file lists are identical
        VALIDATE: branch names and messages preserved
      </consistency_verification>
      
      <execution_equivalence>
        CONFIRM: converted plan would produce same git operations
        VERIFY: execution feasibility is unchanged
        CHECK: dependency relationships are preserved
        VALIDATE: file operations remain valid
      </execution_equivalence>
    </conversion_verification>
    
  </step>
  
</conversion_validation_workflow>

## Error Messages and Recovery

<error_handling>
  
  <validation_error_patterns>
    <file_not_found>
      MESSAGE: "Commit plan file '[filename]' not found in .agent-os/commit-plan/"
      ACTIONS: 
        LIST: available plan files in directory
        SUGGEST: check filename spelling and extension
        PROVIDE: example of correct file path
    </file_not_found>
    
    <invalid_json_syntax>
      MESSAGE: "Invalid JSON syntax in plan file"
      ACTIONS:
        PROVIDE: specific error line and character position
        SUGGEST: using online JSON validator
        REFERENCE: valid JSON structure example
    </invalid_json_syntax>
    
    <missing_required_fields>
      MESSAGE: "Plan file missing required fields: [field_list]"
      ACTIONS:
        REFERENCE: "@~/.agent-os/instructions/meta/commit-plan-schema.md"
        PROVIDE: example of complete plan structure
        LIST: specific fields that need to be added
    </missing_required_fields>
    
    <invalid_markdown_structure>
      MESSAGE: "Markdown plan missing required sections"
      ACTIONS:
        IDENTIFY: missing section types
        PROVIDE: template for correct markdown structure
        REFERENCE: working example file
    </invalid_markdown_structure>
    
    <logical_inconsistency>
      MESSAGE: "Plan contains logical inconsistencies"
      ACTIONS:
        DESCRIBE: specific consistency problems found
        SUGGEST: corrections for dependency issues
        WARN: about potential execution problems
    </logical_inconsistency>
  </validation_error_patterns>
  
  <recovery_procedures>
    <partial_validation_failure>
      CONTINUE: validation where possible
      COLLECT: all validation errors before stopping
      PROVIDE: comprehensive error report
      SUGGEST: prioritized fix order
    </partial_validation_failure>
    
    <format_conversion_failure>
      PRESERVE: original file content
      LOG: conversion errors with details
      PROVIDE: manual conversion guidance
      SUGGEST: alternative approaches
    </format_conversion_failure>
  </recovery_procedures>
  
</error_handling>

## Integration Points

<integration>
  <with_git_commit_instruction>
    CALLED: from git-commit.md plan file processing steps
    PROVIDES: validated plan structure for execution
    RETURNS: format-normalized plan data
  </with_git_commit_instruction>
  
  <with_commit_plan_schema>
    REFERENCES: @~/.agent-os/instructions/meta/commit-plan-schema.md
    VALIDATES: against official schema requirements
    MAINTAINS: compatibility with schema evolution
  </with_commit_plan_schema>
  
  <with_markdown_conversion>
    COORDINATES: with conversion workflows
    VALIDATES: both pre and post conversion
    ENSURES: conversion fidelity and correctness
  </with_markdown_conversion>
</integration>

## Performance Considerations

<performance>
  <file_size_limits>
    MAXIMUM: 1MB per plan file (reasonable for commit plans)
    OPTIMIZE: parsing for large files if needed
    WARN: if file size approaches limits
  </file_size_limits>
  
  <validation_efficiency>
    EARLY_EXIT: on critical errors to save processing time
    BATCH: related validations together
    CACHE: repeated validations where appropriate
  </validation_efficiency>
  
  <memory_usage>
    STREAM: large file processing where possible
    CLEANUP: temporary data structures after use
    LIMIT: in-memory content size for very large plans
  </memory_usage>
</performance>

## Notes

- Validation workflows support both JSON and Markdown plan formats
- All error messages include specific guidance for resolution
- Cross-format validation ensures consistent execution regardless of input format
- Performance optimizations prevent issues with large or complex plans
- Integration points maintain clean separation of concerns with other workflows
- Validation preserves original file content for error recovery and debugging