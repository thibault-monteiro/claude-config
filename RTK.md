# RTK — Rust Token Killer : réflexes outils

Proxy CLI d'économie de tokens. Le hook réécrit les commandes simples
(`git status` → `rtk git status`, 0 token). Ces réflexes, appliqués à **chaque** appel
outil, maximisent son taux de réécriture. Détail complet, meta-commandes (`rtk gain` /
`discover` / `proxy`), vérif install et collision de nom → skill **`rtk-reference`**.

**Rule 1 — Jamais `cd <dir> && …`.** Le cwd du Bash tool est déjà le repo.
- `cd … && git …` → `git -C <path> …` (routé, même handler).
- `cd … && <script>` → drop le `cd` (cwd déjà bon).
- Exception rare : sous-dossier de monorepo sans forme en chemin absolu → un seul `cd`.

**Rule 2 — Fichiers : outils Claude Code, pas le shell** (ils court-circuitent Bash ET sont déjà token-optimaux) :

| Shell | → Outil |
|---|---|
| `cat` / `head` / `tail` / `less` | `Read` (avec `limit` / `offset`) |
| `cat > f << EOF` / `echo >` / `>>` | `Write` (JAMAIS de heredoc : 100 % non routé) |
| `find` / `ls -la` (exploration) | `Glob` |
| `grep -r` | `Grep` |

Exceptions Bash : `od`/`hexdump`/`xxd`, `wc`/`awk`/`sed` (flux), append d'une ligne
courte en log. Les pipes lourds (`a | b | c`) contournent aussi RTK → même règle.

**Rule 3 — Batcher.** Commandes indépendantes → plusieurs `Bash` dans un message
(parallèle, chacune routée). Dépendantes → un seul `Bash` avec `&&`.

**Rule 5 — Windows.** PowerShell/cmd non routés → préférer le Bash tool (git, ls, grep,
node, npm). Pour PowerShell :
- ✅ `-File <script>.ps1` (script commité) → garder.
- 🔴 `-Command "…"` avec un pipe `|` **ou** > ~60 chars → sauver en `.ps1` d'abord.
- 🟠 `-Command "<court, sans pipe>"` → toléré pour un one-shot.
