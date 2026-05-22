@RTK.md

# Agent investigation rules — applies to every session, every project

## Rule: NEVER truncate help / list / version output during investigation

When inspecting a tool's capabilities to decide what it supports, READ
THE FULL OUTPUT. Truncating with `head -N` or `tail -N` leads to false
"this doesn't exist" claims when the missing item happens to fall in
the omitted zone. This has bitten us at least once already (filed an
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

Same rule applies to:
- `--help`, `-h`, `help`, `man <cmd>`
- Subcommand listings (`<tool> list`, `<tool> commands`)
- Version / about / capabilities outputs
- Schema / registry dumps
- Anything you're using to answer "does this tool support X?"

If the output is genuinely huge (>500 lines), grep for the specific
thing you're looking for rather than blindly truncating. If you must
truncate, justify it in the command's `description` field
(e.g. "showing last 20 commits for visual inspection").

This rule does NOT apply when:
- The output is known to be very large (e.g. a build log) AND you're
  looking for a specific signal (errors, summary). Use `grep` or `tail`
  with intent.
- The user explicitly asks for "the first N" of something.

# Multi-agent review — applies to every feature build, every project

## Rule: every non-trivial feature ships through a builder + reviewer pair

For any non-trivial feature, refactor, or bug-investigation, work as a
duo by default — not solo. One agent (you, the main thread) implements;
at least one independent subagent reviews. At each natural slice
(service layer done, UI layer done, wiring done, etc.), spawn a review
agent and ask for a consensus before moving on. Costs more tokens — and
the user has explicitly accepted that trade-off because the second pair
of eyes always finds something.

The review agent MUST be spawned via the `Agent` tool with a
self-contained prompt. Don't re-summarise your own work and call it a
review — that's not what "independent review" means. The reviewer must
have its own context window.

### What the reviewer checks (every slice, in order)

1. **Correctness** — does the slice actually do what was asked? Edge
   cases handled? Error paths plausible?
2. **DRY** — duplication with existing code that should have been
   reused? Helpers that already exist for the same thing?
3. **Design harmony** — does the new code follow the same patterns,
   naming, structure, and abstractions as the surrounding feature?
   (e.g. if every handler in the file uses `syncAndPersistAsset`,
   the new one should too — not a bespoke variant.)
4. **Code consistency** — same style/convention as neighbouring code?
   No mixing of patterns just because the new code was written cold?
5. **No hardcoded values that should be configurable** — especially
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
naturally pause on. For a feature like "add a new image-generation
action":

- Slice 1: types + BO config (prompts, timers, validation)
- Slice 2: Gemini service + builder
- Slice 3: handler in the generation hook
- Slice 4: UI (buttons, modal, propagation through props)

After EACH slice, spawn a reviewer. Do not batch all reviews to the
end — the cost of fixing a design issue grows with each subsequent
slice that builds on it.

### Practical pattern

```text
1. Plan the slice (todo list, files to touch)
2. Implement the slice end-to-end
3. Run typecheck / build / tests if they exist
4. Spawn Agent({ subagent_type: "general-purpose" or "code-reviewer",
                  description: "Review slice N: <topic>",
                  prompt: <self-contained brief with file paths,
                          what changed, what to check> })
5. If reviewer finds issues: address them (or push back with reasoning
   if you disagree), then move on. Do not just relay the review back
   to the user — synthesize and act.
6. Brief one-line status to the user, then start the next slice.
```

### Anti-patterns

- Spawning the reviewer with "review my work" and no context — useless.
- Spawning multiple reviewers and just picking the one that agrees.
- Letting the reviewer's verdict become a wall of text dumped on the
  user. The user wants you to act on the review, not to forward it.
