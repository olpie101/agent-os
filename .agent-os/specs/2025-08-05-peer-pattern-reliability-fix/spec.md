# Spec Requirements Document

> Spec: PEER Pattern Process Redesign
> Created: 2025-08-05

## Overview

Redesign the PEER pattern instruction (peer.md) from brittle script-based orchestration to robust process-based coordination following the established Agent OS instruction pattern. This will eliminate script failures, race conditions, and coordination issues while enabling reliable execution of the PEER (Plan, Execute, Express, Review) workflow.

## User Stories

### Agent OS Developer Reliable Process Coordination

As an Agent OS developer, I want the PEER pattern to coordinate subagents through a process workflow like other Agent OS instructions, so that execution is predictable and doesn't depend on external scripts.

When I run `/peer --instruction=create-spec`, the system should follow the same process pattern as execute-tasks.md and create-spec.md - using XML-like step definitions that delegate to peer-planner, peer-executor, peer-express, and peer-review subagents with proper validation and error handling built into the process logic.

### Agent OS Developer Flexible Process Flow

As an Agent OS developer, I want the PEER pattern to handle runtime issues through process logic rather than script dependencies, so that the system can adapt to different conditions and recover from failures gracefully.

When NATS connectivity issues occur or phase validation fails, the process should handle these conditions through conditional logic and decision trees rather than relying on external scripts that can fail unpredictably.

## Spec Scope

1. **Process Flow Redesign** - Convert peer.md from script orchestration to XML-like process flow with numbered steps
2. **Subagent Coordination** - Define proper step delegation to peer-planner, peer-executor, peer-express, peer-review subagents  
3. **Validation Logic Integration** - Add phase validation through conditional blocks and decision trees in the process flow
4. **NATS CLI Reference** - Include minimal NATS command examples for reference (like notification_command pattern)
5. **Script Dependency Removal** - Eliminate all calls to external shell scripts in ~/.agent-os/scripts/peer/

## Out of Scope

- Changes to subagent implementations (peer-planner.md, peer-executor.md, etc.)
- Modifications to NATS KV schema or data structures  
- New PEER pattern features beyond reliability fixes
- Changes to other Agent OS instruction files

## Expected Deliverable

1. peer.md redesigned to follow Agent OS process pattern with XML-like step definitions
2. All script dependencies removed - no calls to ~/.agent-os/scripts/peer/*.sh files
3. Process validation through conditional logic prevents Execute phase skipping and false success reporting
4. Proper subagent coordination following established Agent OS instruction patterns
5. Flexible process flow that can adapt to runtime conditions through decision trees and validation logic