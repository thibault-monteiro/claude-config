@RTK.md

# Coding mindset — applies to every session, every project

These four principles bias toward caution over speed. For trivial tasks
(typo fix, version bump, dead import), use judgement.

## 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs. Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- 200 lines that could be 50? Rewrite.

Test: "would a senior engineer call this overcomplicated?" If yes, simplify.

## 3. Surgical changes

Touch only what you must. Every changed line should trace directly to the
user's request.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd do it differently.
- Spotted unrelated dead code? Mention it, don't delete it.
- Your changes orphan an import/var/function? Remove it. Don't remove
  pre-existing dead code unless asked.

## 4. Goal-driven execution

Define success criteria *before* coding. Loop until verified.

Reframe tasks as verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan: `step → verify` for each step.
Strong criteria let you loop independently; weak criteria ("make it work")
keep requiring clarification.

Signs it's working: fewer unnecessary changes in diffs, fewer rewrites
due to overcomplication, clarifying questions *before* implementation
rather than after mistakes.

---

# Investigation rule: never truncate help / list / version output

When inspecting a tool's capabilities to decide what it supports, READ
THE FULL OUTPUT. Truncating with `head -N` or `tail -N` leads to false
"this doesn't exist" claims when the missing item happens to fall in
the omitted zone. This has bitten me at least once already (I filed an
issue against rtk claiming `npm` wasn't supported, then discovered
`rtk npm` was just below my truncation cut-off).

Forbidden:
```bash
some-tool --help | head -40           # ← arbitrary cut, hides things
some-tool list   | head -20
git log --oneline | head -10          # if you're checking "does commit X exist"
```

Allowed:
```bash
some-tool --help                       # full output (default)
some-tool --help | grep -E "node|npm"  # targeted search, hides nothing missed
some-tool --help 2>&1 | wc -l          # check size FIRST, then read intelligently
```

Same rule applies to: `--help` / `-h` / `help` / `man`, subcommand listings
(`<tool> list`), version / capabilities outputs, schema dumps — anything
you're using to answer "does this tool support X?".

If the output is genuinely huge (>500 lines), grep for the specific thing
rather than blindly truncating. If you must truncate, justify it in the
command's `description` field (e.g. "showing last 20 commits for visual
inspection").

Exceptions: known-large outputs (build logs) when scanning for a specific
signal — use `grep` or `tail` *with intent*. Or when the user explicitly
asks for "the first N" of something.

# Multi-agent review — applies to every non-trivial feature

This is principle #4 (goal-driven execution) applied at the team-of-agents
level: slice + verify, then move on. One agent (you, the main thread)
implements; at least one independent subagent reviews each slice before
the next starts.

For any non-trivial feature, refactor, or bug-investigation, work as a
duo by default — not solo. Costs more tokens, and the user has explicitly
accepted that trade-off because the second pair of eyes always finds
something.

The reviewer MUST be spawned via the `Agent` tool with a self-contained
prompt. Don't re-summarise your own work and call it a review — that's
not what "independent review" means. The reviewer must have its own
context window.

### What the reviewer checks (every slice, in order)

1. **Correctness** — does the slice actually do what was asked? Edge
   cases handled? Error paths plausible?
2. **Scope (surgical)** — every changed line traces to the request? No
   adjacent "improvements", no opportunistic refactor?
3. **DRY** — duplication with existing code that should have been reused?
   Helpers that already exist for the same thing?
4. **Design harmony** — does the new code follow the same patterns,
   naming, structure, and abstractions as the surrounding feature?
   (e.g. if every handler uses `syncAndPersistAsset`, the new one should
   too — not a bespoke variant.)
5. **Code consistency** — same style/convention as neighbouring code?
   No mixing of patterns just because the new code was written cold?
6. **No hardcoded values that should be configurable** — especially
   anything the user has previously asked to externalize (prompts,
   feature flags, credit costs, copy strings).

### When to skip

- Trivial one-line fixes (typo, version bump, dead import).
- Read-only questions (no code change).
- Exploratory research turns where nothing is being built yet.

If unsure whether a task qualifies as "non-trivial", default to running
the reviewer. The user prefers burning a few tokens over shipping
something stale or stylistically off.

### What "at each slice" means in practice

A slice is a coherent layer of the feature — typically what you'd
naturally pause on. For "add a new image-generation action":

- Slice 1: types + BO config (prompts, timers, validation)
- Slice 2: Gemini service + builder
- Slice 3: handler in the generation hook
- Slice 4: UI (buttons, modal, propagation through props)

After EACH slice, spawn a reviewer. Do not batch reviews to the end —
the cost of fixing a design issue grows with each subsequent slice that
builds on it.

### Practical pattern

```text
1. Define the slice's success criteria (principle #4)
2. Plan the slice (todo list, files to touch)
3. Implement end-to-end
4. Run typecheck / build / tests if they exist — verify the criteria
5. Spawn Agent({ subagent_type: "general-purpose" or "code-reviewer",
                  description: "Review slice N: <topic>",
                  prompt: <self-contained brief with file paths,
                          what changed, what to check> })
6. If reviewer finds issues: address them (or push back with reasoning
   if you disagree), then move on. Don't just relay the review back to
   the user — synthesize and act.
7. Brief one-line status, then start the next slice.
```

### Anti-patterns

- Spawning the reviewer with "review my work" and no context — useless.
- Spawning multiple reviewers and just picking the one that agrees.
- Letting the reviewer's verdict become a wall of text dumped on the
  user. Act on the review, don't forward it.
