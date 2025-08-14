# Spec Requirements Document

> Spec: PEER Agents Declarative Transformation
> Created: 2025-08-05

## Overview

Transform the four PEER subagents (peer-planner, peer-executor, peer-express, peer-review) from script-based implementations to declarative process flows following Agent OS instruction patterns. This builds upon the peer.md transformation to create a completely script-free PEER pattern execution environment.

## User Stories

### Agent OS Developer Script-Free Subagents

As an Agent OS developer, I want the PEER subagents to use declarative patterns instead of bash scripts and temp files, so that subagent execution is reliable and doesn't depend on shell environment or filesystem state.

When peer-planner analyzes an instruction, it should gather context and create plans through structured process flows with XML-like step definitions, eliminating the current dependency on `/tmp/peer_*.txt` files and bash command execution for NATS operations.

### Agent OS Developer Unified State Management

As an Agent OS developer, I want PEER subagents to manage state through a single NATS KV entry per cycle with optimistic locking, so that concurrent access is handled gracefully and state consistency is maintained.

When multiple phases need to update cycle state, the system should use sequence-based optimistic locking to prevent race conditions and data corruption, replacing the current fragmented state management across temp files and multiple KV entries.

## Spec Scope

1. **peer-planner Transformation** - Convert from bash-driven analysis to declarative context gathering and plan creation
2. **peer-executor Transformation** - Replace script delegation with structured instruction execution patterns  
3. **peer-express Transformation** - Transform from bash-based formatting to declarative presentation logic
4. **peer-review Transformation** - Convert script-based assessment to structured evaluation processes
5. **Unified State Schema** - Define single KV entry structure with phase data and sequence numbers
6. **Optimistic Locking Pattern** - Implement sequence-based state updates to prevent corruption
7. **Declarative NATS Operations** - Replace bash NATS CLI calls with structured operation blocks

## Out of Scope

- Changes to peer.md instruction file (covered by existing 2025-08-05-peer-pattern-reliability-fix spec)
- Modifications to NATS server configuration or bucket setup
- Changes to Agent OS instruction patterns or other subagent implementations
- New PEER pattern features beyond declarative transformation

## Expected Deliverable

1. Four transformed subagent files using declarative patterns without bash dependencies
2. Single unified KV state schema supporting all PEER phases with optimistic locking
3. Declarative NATS operation blocks replacing direct CLI command execution
4. Process flows following Agent OS XML-like step patterns with proper validation
5. Comprehensive phase transition logic ensuring state consistency across subagents

## Implementation Approach

This spec follows a simplified v1 approach as detailed in the alignment requirements document. The v1 implementation removes all optimistic locking complexity and focuses on proving the unified state concept with simple read/write operations.

### Backwards Compatibility Note

Backwards compatibility with existing cycles is NOT a concern for this implementation. This allows for clean architectural corrections without migration complexity.

### Critical Bug Fix (Phase 8.5)

During testing, a critical issue was discovered where `create-spec` instructions would incorrectly use `peer.global` as the key prefix instead of `peer.spec.[SPEC_NAME]`. This occurs because spec name determination happened after KEY_PREFIX was already set. The fix involves moving spec name determination logic into Step 4 of peer.md, before KEY_PREFIX is finalized.

### Architectural Corrections (Phase 15.5)

Two critical architectural issues have been identified that require correction:
1. **Express Phase Violation**: The Express phase adds a `result` field at the root level, violating phase ownership principles
2. **Hidden Insights**: The Review phase generates valuable insights that are never displayed to users

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/sub-specs/technical-spec.md
- Alignment Requirements: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/implementation/peer-md-alignment-requirements.md
- Wrapper Script Enhancement: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/sub-specs/wrapper-script-enhancement.md
- Refine-Spec Integration: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/sub-specs/refine-spec-integration.md
- Architectural Corrections: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/sub-specs/architectural-corrections.md