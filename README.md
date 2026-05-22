# claude-conf

Mes dotfiles pour Claude Code, synchronisés entre 2 postes.

## Contenu tracké

- **`CLAUDE.md`** — instructions globales (chargées sur tous les projets) : règles
  d'investigation (pas de truncate `--help`), multi-agent review systématique sur
  features non-triviales.
- **`RTK.md`** — règles agent pour maximiser le hit-rate du hook RTK (Rust Token
  Killer). 5 règles + checklists préalables, durcies après audit du 2026-05-23.
- **`settings.json`** — permissions allow/deny + hook RTK `PreToolUse` sur matcher
  Bash. ⚠️ `.credentials.json` reste local sur chaque poste (gitignored).
- **`projects/<projet>/memory/*.md`** — mémoires auto-générées par projet (feedback,
  user profile, references). Tout le reste de `projects/` (transcripts, state,
  sous-agents) est gitignored.
- **`sync.sh`** — script de synchronisation pull/commit/push idempotent.

## Setup sur un nouveau poste

```bash
# 1. Sauvegarde
mv "$HOME/.claude" "$HOME/.claude.backup"

# 2. Clone
git clone https://github.com/thibault-monteiro/claude-conf.git "$HOME/.claude"

# 3. Restaure les credentials (local par poste)
cp "$HOME/.claude.backup/.credentials.json" "$HOME/.claude/"

# 4. (optionnel) Plugins déjà installés
cp -r "$HOME/.claude.backup/plugins" "$HOME/.claude/"
```

## Usage quotidien

```bash
bash ~/.claude/sync.sh                          # pull
bash ~/.claude/sync.sh "<msg conventional>"     # add + commit + pull --rebase + push
bash ~/.claude/sync.sh status                   # short status
```

Optionnel — alias à ajouter dans `~/.bashrc` :

```bash
alias claude-sync='bash ~/.claude/sync.sh'
```

## Ce qui n'est PAS synchronisé (volontairement)

- `.credentials.json` — tokens API, propres à chaque poste
- `history.jsonl`, `telemetry/`, `sessions/` — vie privée + state
- `cache/`, `shell-snapshots/`, `session-env/` — runtime
- `projects/*/[uuid].jsonl` — transcripts (volumineux + propres au poste)
- `todos/`, `tasks/` — state de session
- `plugins/` — réinstallables (passer par `cp -r` à la première sync si voulu)
