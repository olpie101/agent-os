---
description: Spec Refinement Rules for Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Spec Refinement Rules

## Overview

Refine existing spec documentation based on user requirements, review recommendations, or implementation discoveries while preserving completed work.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" subagent="context-fetcher" name="spec_identification">

### Step 1: Spec Identification

Use the context-fetcher subagent to identify which spec to refine by extracting from --spec flag, user input, or finding the most recent spec.

<spec_selection>
  <parameter_check>
    IF --spec flag provided:
      USE: Spec name from --spec parameter
    ELSE IF user mentions specific spec:
      EXTRACT: Spec name from user input
    ELSE IF user asks for "latest" or "most recent":
      FIND: Most recent spec folder by date prefix
    ELSE:
      ERROR: "Please specify which spec to refine"
      STOP execution
  </parameter_check>
</spec_selection>

<spec_validation>
  <folder_check>
    VERIFY: .agent-os/specs/YYYY-MM-DD-[SPEC_NAME] exists
    IF not exists:
      ERROR: "Spec folder not found: [SPEC_PATH]"
      PROVIDE: List of available specs
      STOP execution
  </folder_check>
</spec_validation>

<instructions>
  ACTION: Determine spec to refine
  VALIDATE: Spec folder exists
  STORE: Spec path for subsequent steps
</instructions>

</step>

<step number="2" subagent="context-fetcher" name="load_spec_files">

### Step 2: Load Spec Files and Establish Boundaries

Use the context-fetcher subagent to load all spec files including dynamically discovered sub-specs, and establish strict file modification boundaries.

<required_files>
  - spec.md (main requirements)
  - spec-lite.md (condensed version)
  - technical-spec.md (technical implementation)
  - tasks.md (task breakdown)
</required_files>

<dynamic_loading>
  <sub_specs_scan>
    SCAN: sub-specs/ directory
    FIND: All .md files
    LOAD: Each discovered sub-spec file
    TRACK: Which sub-specs exist (database-schema.md, api-spec.md, etc.)
  </sub_specs_scan>
</dynamic_loading>

<modification_boundaries>
  STORE: SPEC_FOLDER_PATH = .agent-os/specs/YYYY-MM-DD-[SPEC_NAME]/
  
  ALLOWED_MODIFICATIONS:
    - Files within [SPEC_FOLDER_PATH] only
    - Only .md documentation files
    - No implementation files ever
  
  ENFORCEMENT_DIRECTIVE:
    - ALL subsequent file-creator invocations MUST include these constraints
    - ANY attempt to modify files outside SPEC_FOLDER_PATH must be rejected
    - This is a spec refinement - ONLY documentation updates allowed
</modification_boundaries>

<instructions>
  ACTION: Load all spec documentation
  INCLUDE: Dynamically discovered sub-specs
  ESTABLISH: File modification boundaries for all subsequent steps
  STORE: SPEC_FOLDER_PATH for constraint enforcement
  PREPARE: Context for refinement decisions
</instructions>

</step>

<step number="3" name="gather_refinement_requirements">

### Step 3: Gather Refinement Requirements

Analyze the source and nature of refinement needs to understand what changes are required.

<refinement_sources>
  <user_requested>
    - Scope changes
    - Feature additions/removals
    - Priority adjustments
    - Technical approach changes
  </user_requested>
  <review_recommendations>
    - From PEER review phase
    - Quality improvements
    - Completeness issues
    - Clarity enhancements
  </review_recommendations>
  <implementation_discoveries>
    - Technical constraints found
    - Better solutions identified
    - Dependencies discovered
    - Performance considerations
  </implementation_discoveries>
</refinement_sources>

<requirements_analysis>
  IDENTIFY: Type of refinement needed
  ASSESS: Impact on existing documentation
  DETERMINE: Which files need updates
  PRESERVE: Completed work where possible
</requirements_analysis>

<instructions>
  ACTION: Understand refinement requirements
  CLASSIFY: Source and type of changes
  PLAN: Update strategy for each file
</instructions>

</step>

<step number="4" subagent="file-creator" name="update_spec_md">

### Step 4: Update spec.md (Conditional)

Use the file-creator subagent to update spec.md only if requirements or scope changes affect it.

<conditional_execution>
  IF refinement affects requirements, scope, or deliverables:
    UPDATE: spec.md with changes
  ELSE:
    SKIP this step
    PROCEED to step 5
</conditional_execution>

<update_sections>
  <overview>Update if goals/objectives change</overview>
  <user_stories>Modify if user workflows change</user_stories>
  <spec_scope>Add/remove features as needed</spec_scope>
  <out_of_scope>Update exclusions if scope changes</out_of_scope>
  <expected_deliverable>Adjust if outcomes change</expected_deliverable>
</update_sections>

<preservation_rules>
  - Keep unchanged sections intact
  - Preserve formatting and structure
  - Add refinement note if significant changes
</preservation_rules>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Update spec.md at [SPEC_FOLDER_PATH]/spec.md
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify this specific file: [SPEC_FOLDER_PATH]/spec.md
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - You MUST NOT modify any implementation files
            - This is a spec refinement - only documentation updates allowed
            
            Updates needed: [SPECIFIC_CHANGES]"
  VALIDATE: Changes only affect spec.md
  PRESERVE: Unchanged content
  DOCUMENT: Significant changes
</instructions>

<post_step_validation>
  VERIFY: Modified file is within [SPEC_FOLDER_PATH]
  CHECK: No implementation files were modified
  IF violation detected:
    ERROR: "File modification outside spec folder attempted"
    STOP: Refinement process
</post_step_validation>

</step>

<step number="5" subagent="file-creator" name="regenerate_spec_lite">

### Step 5: Regenerate spec-lite.md (Conditional)

Use the file-creator subagent to regenerate spec-lite.md only if spec.md was updated.

<conditional_execution>
  IF spec.md was updated in Step 4:
    REGENERATE: spec-lite.md from updated spec.md
  ELSE:
    SKIP this step
    PROCEED to step 6
</conditional_execution>

<regeneration_process>
  EXTRACT: Overview from updated spec.md
  CONDENSE: Into 1-3 sentences
  MAINTAIN: Consistency with spec.md changes
</regeneration_process>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Regenerate spec-lite.md at [SPEC_FOLDER_PATH]/spec-lite.md
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify this specific file: [SPEC_FOLDER_PATH]/spec-lite.md
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - You MUST NOT modify any implementation files
            
            Source content from: [SPEC_FOLDER_PATH]/spec.md"
  VALIDATE: Changes only affect spec-lite.md
  ENSURE: Consistency with spec.md
  KEEP: Concise format
</instructions>

<post_step_validation>
  VERIFY: Modified file is within [SPEC_FOLDER_PATH]
  CHECK: No implementation files were modified
</post_step_validation>

</step>

<step number="6" subagent="file-creator" name="update_technical_spec">

### Step 6: Update technical-spec.md

Use the file-creator subagent to update technical specifications based on refinement requirements.

<update_areas>
  <technical_requirements>
    - Implementation approach changes
    - New technical constraints
    - Performance optimizations
    - Security enhancements
  </technical_requirements>
  <external_dependencies>
    - Add new dependencies if needed
    - Remove obsolete dependencies
    - Update version requirements
  </external_dependencies>
</update_areas>

<technical_preservation>
  - Keep working implementation details
  - Update only affected sections
  - Document reasons for technical changes
</technical_preservation>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Update technical-spec.md at [SPEC_FOLDER_PATH]/sub-specs/technical-spec.md
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify this specific file: [SPEC_FOLDER_PATH]/sub-specs/technical-spec.md
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - You MUST NOT modify any implementation files
            - This is documentation only - no code changes
            
            Technical updates needed: [SPECIFIC_CHANGES]"
  VALIDATE: Changes only affect technical-spec.md
  FOCUS: Technical implementation changes
  PRESERVE: Working approaches
</instructions>

<post_step_validation>
  VERIFY: Modified file is within [SPEC_FOLDER_PATH]
  CHECK: No implementation files were modified
</post_step_validation>

</step>

<step number="7" subagent="file-creator" name="update_sub_specs">

### Step 7: Update Sub-Specs (Conditional)

Use the file-creator subagent to update any sub-specs affected by refinements.

<conditional_updates>
  FOR each sub-spec in sub-specs/ directory:
    IF refinement affects this sub-spec:
      UPDATE: Relevant sections
    ELSE:
      SKIP: Leave unchanged
</conditional_updates>

<sub_spec_types>
  <database_schema>Update if data model changes</database_schema>
  <api_spec>Update if endpoints change</api_spec>
  <other_specs>Update as needed based on type</other_specs>
</sub_spec_types>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Update sub-specs at [SPEC_FOLDER_PATH]/sub-specs/
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify .md files within: [SPEC_FOLDER_PATH]/sub-specs/
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - You MUST NOT modify any implementation files
            - Only documentation updates allowed
            
            Sub-specs to update: [LIST_OF_SUB_SPECS]"
  VALIDATE: All changes within sub-specs directory
  SKIP: Unaffected sub-specs
  MAINTAIN: Consistency across specs
</instructions>

<post_step_validation>
  VERIFY: All modified files are within [SPEC_FOLDER_PATH]/sub-specs/
  CHECK: No implementation files were modified
</post_step_validation>

</step>

<step number="8" subagent="file-creator" name="update_tasks_md">

### Step 8: Update tasks.md with Preservation Rules

Use the file-creator subagent to update tasks while preserving completed work appropriately.

<task_preservation_rules>
  <no_tasks_completed>
    IF no tasks marked as completed ([x]):
      - Freely modify all tasks
      - Restructure as needed
      - No preservation required
  </no_tasks_completed>
  
  <some_tasks_completed>
    IF some tasks marked as completed ([x]):
      - PRESERVE: Checkmark status for completed tasks
      - ADD: ~~strikethrough~~ to completed tasks that are now obsolete
      - KEEP: Completed tasks that remain relevant
      - ADD: New tasks as needed
      - MODIFY: Uncompleted tasks freely
  </some_tasks_completed>
  
  <all_tasks_completed>
    IF all tasks marked as completed ([x]):
      - PRESERVE: All completion history
      - ADD: New phase or section for refinements
      - LABEL: "## Refinement Tasks (Added [DATE])"
  </all_tasks_completed>
</task_preservation_rules>

<task_modification_examples>
  # Obsolete completed task (scope removed):
  - [x] ~~1.3 Implement removed feature~~
  
  # Relevant completed task (keep as-is):
  - [x] 1.4 Implement core functionality
  
  # New task added:
  - [ ] 1.5 Implement new requirement
</task_modification_examples>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Update tasks.md at [SPEC_FOLDER_PATH]/tasks.md
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify this specific file: [SPEC_FOLDER_PATH]/tasks.md
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - You MUST NOT modify any implementation files
            - Preserve completion status of tasks as specified
            
            Task updates with preservation rules: [SPECIFIC_CHANGES]"
  VALIDATE: Changes only affect tasks.md
  PRESERVE: Completed work appropriately
  ADD: New tasks for refinements
  DOCUMENT: Significant task changes
</instructions>

<post_step_validation>
  VERIFY: Modified file is within [SPEC_FOLDER_PATH]
  CHECK: No implementation files were modified
</post_step_validation>

</step>

<step number="9" subagent="file-creator" name="create_refinement_log">

### Step 9: Create/Update Refinement Log

Use the file-creator subagent to document the refinement in refinement-log.md.

<log_location>
  FILE: .agent-os/specs/[SPEC_FOLDER]/refinement-log.md
  ACTION: Create if doesn't exist, append if exists
</log_location>

<log_entry_template>
  ## [CURRENT_DATE]: [REFINEMENT_TITLE]

  **Source:** [user_request | review_recommendation | implementation_discovery]
  **Refinement Type:** [scope_change | technical_update | clarification | enhancement]

  ### Changes Made

  - **spec.md:** [CHANGES or "No changes"]
  - **technical-spec.md:** [CHANGES or "No changes"]
  - **tasks.md:** [CHANGES or "No changes"]
  - **Other:** [LIST any sub-spec changes]

  ### Rationale

  [EXPLANATION of why refinements were needed]

  ### Impact

  - **Completed Work:** [preserved | partially obsolete | remains valid]
  - **Timeline:** [no impact | extended | reduced]
  - **Complexity:** [no change | increased | decreased]
</log_entry_template>

<instructions>
  ACTION: Use file-creator subagent
  REQUEST: "Create/update refinement-log.md at [SPEC_FOLDER_PATH]/refinement-log.md
            
            CRITICAL CONSTRAINTS:
            - You may ONLY modify this specific file: [SPEC_FOLDER_PATH]/refinement-log.md
            - You MUST NOT modify any files outside of [SPEC_FOLDER_PATH]
            - Append new entry if file exists, create if not
            
            Log entry: [REFINEMENT_ENTRY]"
  VALIDATE: Changes only affect refinement-log.md
  INCLUDE: All changes made
  EXPLAIN: Rationale and impact
</instructions>

<post_step_validation>
  VERIFY: Modified file is within [SPEC_FOLDER_PATH]
  CHECK: No implementation files were modified
</post_step_validation>

</step>

<step number="10" name="refinement_summary">

### Step 10: Refinement Summary

Provide a clear summary of refinements made and their impact on the spec.

<summary_template>
  ## ✅ Spec Refinement Complete

  **Spec:** [SPEC_NAME]
  **Refinement Source:** [SOURCE]
  
  ### Changes Applied
  
  [LIST key changes made to each file]
  
  ### Preserved Work
  
  - Completed tasks: [X of Y preserved]
  - Obsolete tasks: [N marked with strikethrough]
  - New tasks added: [M new tasks]
  
  ### Next Steps
  
  1. Review updated documentation
  2. Continue with implementation of new/modified tasks
  3. Consider running PEER review for validation
  
  Refinement has been logged in: refinement-log.md
</summary_template>

<instructions>
  ACTION: Provide comprehensive summary
  HIGHLIGHT: Key changes and preserved work
  SUGGEST: Next steps for user
</instructions>

</step>

</process_flow>

## Execution Standards

<standards>
  <preserve>
    - Completed work where possible
    - Documentation structure
    - Task completion history
  </preserve>
  <document>
    - All refinements in log
    - Rationale for changes
    - Impact on timeline/scope
  </document>
  <maintain>
    - Consistency across all spec files
    - Clear traceability of changes
    - Professional documentation quality
  </maintain>
  <enforce_boundaries>
    - CRITICAL: Only modify files within SPEC_FOLDER_PATH
    - CRITICAL: Never modify implementation files (.js, .ts, .py, .go, etc.)
    - CRITICAL: All file-creator invocations must include explicit path constraints
    - CRITICAL: Reject any attempts to modify files outside spec directory
    - VALIDATION: Verify all changes are within allowed boundaries after each step
  </enforce_boundaries>
</standards>

<final_checklist>
  <verify>
    - [ ] Spec identified correctly
    - [ ] All files loaded and analyzed
    - [ ] Requirements understood
    - [ ] Appropriate files updated
    - [ ] Task preservation rules applied
    - [ ] Refinement logged
    - [ ] Summary provided
    - [ ] ✅ NO implementation files modified
    - [ ] ✅ ALL changes contained within [SPEC_FOLDER_PATH]
    - [ ] ✅ File-creator constraints enforced in all steps
  </verify>
</final_checklist>