# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.

---

## Agent rules — applies to every session, every project

These are MANDATORY behaviors to maximize the RTK hook's rewrite rate.
The hook rewrites simple commands transparently, but a few habits sabotage it.

### Rule 1: NEVER prepend `cd <project-dir> && ...`

> ⚠️ **Most-violated rule** — 487 occurrences on the bot-git-caz audit
> window (7d). Apply the checklist below BEFORE every Bash call.

**Pre-flight checklist (mental, every Bash call):**

```
□ Does my command START with `cd ` ?
  ├─ Followed by `git ...`     → REWRITE as `git -C <path> ...`
  ├─ Followed by a script/.sh  → cwd Bash is already correct, DROP the `cd`
  └─ Followed by something else → ask yourself if absolute paths would work
```

The Bash tool's working directory is **already set to the project root**.
Compound commands like `cd C:/Projets/foo && git status` waste tokens AND
make the rewrite less reliable. Just call the command directly:

```bash
# BAD (very common — kills hook rewrite, resets Shell cwd)
cd C:/Projets/bricksCheck && git status
cd /c/Projets/cuisineaz-nextgen && git log --oneline -5
cd "$repo" && npm test

# GOOD
git status                                          # cwd is already correct
git -C /c/Projets/cuisineaz-nextgen log --oneline -5  # work in another repo
npm test
```

**`git -C <path>` is the canonical replacement** when you need to operate
on a different repo from a worktree of another project. It is routed by
the hook (same handler as `git <cmd>`).

Exception: if you genuinely need a different directory (e.g., a subdirectory
inside a monorepo) AND no absolute-path form works, use a single `cd`
followed by the real work — but this should be rare and intentional.

### Rule 2: For file exploration AND file writing, ALWAYS use Claude Code tools over shell

This is mandatory, not a preference. The 7-day audit (bot-git-caz) showed:
- **407 `cat <file>` calls** (should be `Read`)
- **35 `grep -r` calls** (should be `Grep`)
- plus uncounted `cat > file << 'EOF'` heredocs (should be `Write`)

**Pre-flight checklist (mental, every Bash call):**

```
□ Does my command READ a file?
  ├─ `cat <file>`            → Read tool
  ├─ `head -N <file>`        → Read tool with `limit`
  ├─ `tail -N <file>`        → Read tool with `offset`
  └─ `less` / `more`         → Read tool

□ Does my command WRITE a file?
  ├─ `cat > <file> << 'EOF'` → Write tool (NEVER heredoc, even for JSON state files)
  ├─ `echo "..." > <file>`   → Write tool
  └─ Appending? `>>`         → Read + Write tool (rewrite whole file)

□ Does my command SEARCH?
  ├─ `find . -name "*.ts"`   → Glob tool
  ├─ `grep -r "foo" src/`    → Grep tool
  └─ `ls -la <path>`         → Glob tool (for exploration)
```

| Misuse                       | Replacement                                      |
|------------------------------|--------------------------------------------------|
| `cat <file>`                 | the `Read` tool                                  |
| `cat > <file> << 'EOF'`      | the `Write` tool (heredoc is NOT routed at all)  |
| `find . -name "*.ts"`        | the `Glob` tool                                  |
| `grep -r "foo" src/`         | the `Grep` tool                                  |
| `ls -la <path>`              | for exploration, the `Glob` tool                 |
| `head -N <file>`             | the `Read` tool with `limit`/`offset`            |
| `tail -N <file>`             | the `Read` tool with `offset`                    |

These tools are already token-optimal AND don't even cross the Bash
boundary, so they don't need RTK at all. Falling back to `cat` / `find`
/ `grep` from Bash silently bypasses both RTK and Claude's built-in
optimizations.

**Heredoc trap specifically**: `cat > file << 'EOF' ... EOF` is **100%
unrouted** — the hook can't parse the body, and the whole literal payload
goes through Bash. For state files updated repeatedly (e.g.
`state/current-run.json`), this multiplies the cost. ALWAYS use `Write`.

Exceptions (Bash is the right call):
- Byte-level inspection: `od`, `hexdump`, `xxd`
- Stream-only utilities: `wc -l`, `awk`, `sed` for in-line transformation
- Appending a single short line to a log (`echo X >> log`) — too small to matter
- Anything the tools can't express (very rare)

Heavy pipe chains (`cmd1 | cmd2 | cmd3 | head`) ALSO bypass RTK
rewriting. Same rule: use the dedicated tools above before reaching for
a pipeline.

### Rule 3: Batch related commands properly

- Independent commands → one message with multiple `Bash` tool calls
  (parallel execution, each individually routable through RTK).
- Dependent commands → a single `Bash` call with `&&`. The hook still
  rewrites known sub-commands inside compounds, so this is fine.

### Rule 4: Periodically check `rtk gain`

When the user asks "how much did we save?", run `rtk gain`. Treat that
number — not `rtk discover` — as the truth. `discover` parses the
typed-in command from the transcript and over-counts "misses" because
it doesn't see post-hook rewrites.

### Rule 5: For Windows shells

`PowerShell` and `cmd.exe` invocations are NOT yet routed through RTK
(no handler). Prefer the `Bash` tool for git, ls, grep, node, npm — even
on Windows — to benefit from the hook.

**Inline `-Command "..."` threshold (objective):**

Distinguish "obligatory" vs "ad-hoc evitable":

- ✅ **Obligatory**: `powershell.exe -NoProfile -File <script>.ps1 [args...]`
  — invoking a committed script. OK, keep as-is.
- 🟠 **Borderline**: `powershell.exe -NoProfile -Command "<short single
  cmdlet>"` (< 60 chars, no pipe). Tolerable for one-shots.
- 🔴 **Forbidden**: `powershell.exe -NoProfile -Command "<...>"` that
  contains **either** a pipe `|` **or** is longer than 60 chars. These
  are ad-hoc scripts that ship token-by-token unrouted.

**Pre-flight checklist (every PS call):**

```
□ Is this `-File <script>.ps1` ?           → OK, keep
□ Is this `-Command "..."` ?
  ├─ Contains `|` (pipe)?                  → STOP. Save as scripts/.tmp/<name>.ps1
  ├─ Longer than ~60 chars?                → STOP. Same: save as .ps1
  └─ Short, no pipe                        → OK, but reconsider if repeated
```

The cost grows fast: 164 inline `-Command` calls on the 7-day audit
window (bot-git-caz). Saving them as `.ps1` makes them reusable AND
caches the literal between invocations.

### What this looks like in practice

```text
Wrong:  cd C:/Projets/x && git status && git log --oneline -5
Better: git status                  (single call, hook rewrites)
        git log --oneline -5        (or one Bash with two ; -separated lines)
```
