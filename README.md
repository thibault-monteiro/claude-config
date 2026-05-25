# claude-conf 🧠

<div align="center">

**Mon Claude. Cadré pour penser comme un senior, taper comme un dev sobre, apprendre au fil des sessions.**

Configuration personnelle de Claude Code — dotfiles, mindset, mémoires, sync multi-postes.

![Claude Code](https://img.shields.io/badge/Claude_Code-Config-8A5CF6?style=for-the-badge&logo=anthropic&logoColor=white)
![RTK](https://img.shields.io/badge/RTK-token--optim-FC6D26?style=for-the-badge)
![Sync](https://img.shields.io/badge/Sync-2_postes-22C55E?style=for-the-badge&logo=git&logoColor=white)

</div>

---

## ✨ Pourquoi ce repo existe

Claude Code est puissant brut, mais sans cadrage il finit par sur-coder,
inventer des fichiers, ou faire perdre du temps en allers-retours. Ce
repo est mon `~/.claude` versionné : la couche qui transforme Claude
générique en **mon Claude** — celui qui pense avant de coder, taille au
plus juste, et capitalise sur les sessions passées.

L'idée n'est pas de produire un assistant générique, c'est de poser des
**garde-fous battle-tested** au-dessus de Claude :

- un mindset clair, hérité d'un CLAUDE.md partagé par un fondateur
  d'Anthropic — *think before coding, simplicity first, surgical
  changes, goal-driven execution* ;
- des règles d'investigation issues de vrais ratés (j'ai déjà ouvert un
  faux bug parce que j'avais `head -40` un `--help`) ;
- du multi-agent systématique sur les features non-triviales (builder +
  reviewer indépendant) ;
- un proxy CLI (`rtk`) qui économise 60-90% de tokens sur les opérations
  dev courantes ;
- une mémoire per-project qui s'enrichit silencieusement à chaque
  session.

> Le cap : **moins de diff inutile, moins de réécriture, plus de
> questions posées AVANT plutôt qu'après l'erreur.**

## 🧭 Sommaire

- [Ce qu'il y a dedans](#ce-quil-y-a-dedans)
- [Setup nouveau poste](#setup-nouveau-poste)
- [Sync quotidienne](#sync-quotidienne)
- [Structure](#structure)
- [Ce qui n'est PAS sync](#ce-qui-nest-pas-sync)
- [Adapter à ton workflow](#adapter-à-ton-workflow)

<a id="ce-quil-y-a-dedans"></a>

## 🧠 Ce qu'il y a dedans

Trois piliers, chargés automatiquement par Claude Code sur tous les projets :

| Pilier | Fichier | Rôle |
|---|---|---|
| **Mindset** | `CLAUDE.md` | 4 principes haut niveau + investigation + multi-agent review |
| **Tokens** | `RTK.md` | 5 règles agent pour maximiser le hit-rate du hook RTK |
| **Mémoire** | `projects/*/memory/*.md` | Apprentissages auto-générés par projet |

### Le mindset (`CLAUDE.md`)

Quatre principes condensés, inspirés du CLAUDE.md d'un fondateur
d'Anthropic — biaisés vers la prudence et la simplicité :

| # | Principe | En une ligne |
|---|---|---|
| 1 | Think before coding | Pose les assomptions, demande si flou, présente les tradeoffs |
| 2 | Simplicity first | Le minimum qui résout le problème — rien de spéculatif |
| 3 | Surgical changes | Chaque ligne modifiée doit tracer au besoin exprimé |
| 4 | Goal-driven execution | Définir les critères de succès AVANT d'écrire le code |

Plus deux règles opérationnelles battle-tested :

- 🔍 **Ne jamais tronquer `--help`** — lire la sortie complète avant de
  conclure qu'une feature n'existe pas (origine : faux bug ouvert
  contre `rtk` parce qu'un `head -40` masquait la commande recherchée).
- 👥 **Multi-agent review** sur toute feature non-triviale — un agent
  implémente, un autre review chaque slice avec un context window
  indépendant. Coûte plus de tokens, trouve toujours quelque chose.

### Le proxy tokens (`RTK.md`)

RTK (Rust Token Killer) intercepte les commandes Bash via un hook
`PreToolUse` et les réécrit en versions token-optimales (proxy CLI maison). Les 5 règles agent
expliquent comment ne PAS saboter le hook :

| # | Règle | Économie type |
|---|---|---|
| 1 | Pas de `cd <projet> && ...` (utiliser `git -C <path>`) | 487 occurrences évitées sur 7 jours |
| 2 | Outils Claude (`Read`/`Write`/`Glob`/`Grep`) > shell (`cat`/`find`/`grep`) | 407 `cat` évités sur 7 jours |
| 3 | Batcher correctement (parallèle vs `&&`) | hook plus fiable |
| 4 | Lire `rtk gain` (pas `rtk discover`) pour les vrais chiffres | confiance dans la mesure |
| 5 | PowerShell ad-hoc → fichier `.ps1` si pipe ou >60 chars | 164 inline `-Command` évités sur 7 jours |

### La mémoire (`projects/*/memory/`)

Claude écrit des fichiers `feedback_*.md`, `reference_*.md`,
`project_*.md`, `user_*.md` au fil des sessions, indexés dans
`MEMORY.md`. Au prochain démarrage sur le même projet, ces faits sont
rechargés — la collaboration ne repart pas de zéro.

Seuls les `.md` de mémoire sont commités ; les transcripts, state et
runtime restent locaux (cf. [Ce qui n'est PAS sync](#ce-qui-nest-pas-sync)).

<a id="setup-nouveau-poste"></a>

## 🚀 Setup nouveau poste

```bash
# 1. Sauvegarde l'existant
mv "$HOME/.claude" "$HOME/.claude.backup"

# 2. Clone
git clone https://github.com/thibault-monteiro/claude-conf.git "$HOME/.claude"

# 3. Restaure les credentials (jamais commités — propres à chaque poste)
cp "$HOME/.claude.backup/.credentials.json" "$HOME/.claude/"

# 4. (optionnel) Plugins déjà installés
cp -r "$HOME/.claude.backup/plugins" "$HOME/.claude/"
```

Alias pratique à ajouter dans `~/.bashrc` :

```bash
alias claude-sync='bash ~/.claude/sync.sh'
```

<a id="sync-quotidienne"></a>

## 🔁 Sync quotidienne

```bash
bash ~/.claude/sync.sh                          # pull --rebase
bash ~/.claude/sync.sh "<msg conventional>"     # add + commit + pull --rebase + push
bash ~/.claude/sync.sh status                   # short status + 5 derniers commits
```

Idempotent — relancer ne fait rien si tout est à jour.

<a id="structure"></a>

## 🏛️ Structure

```text
~/.claude/
├── CLAUDE.md           # mindset + investigation + multi-agent review
├── RTK.md              # 5 règles agent token-optim
├── settings.json       # permissions allow/deny + hook PreToolUse rtk
├── README.md           # ce fichier
├── sync.sh             # script de sync pull/commit/push
├── .credentials.json   # ⛔ jamais commité (par poste)
└── projects/
    └── <projet>/
        └── memory/
            ├── MEMORY.md           # index
            ├── feedback_*.md       # corrections + validations utilisateur
            ├── reference_*.md      # pointeurs externes (repos, dashboards)
            ├── project_*.md        # contexte projet vivant
            └── user_*.md           # profil utilisateur
```

<a id="ce-qui-nest-pas-sync"></a>

## 🚫 Ce qui n'est PAS sync (volontairement)

| Chemin | Pourquoi |
|---|---|
| `.credentials.json` | Tokens API — propres à chaque poste |
| `history.jsonl`, `telemetry/`, `sessions/` | Vie privée + state runtime |
| `cache/`, `shell-snapshots/`, `session-env/` | Runtime éphémère |
| `projects/*/[uuid].jsonl` | Transcripts volumineux + propres au poste |
| `todos/`, `tasks/` | State de session |
| `plugins/` | Réinstallables (passer par `cp -r` à la première sync si voulu) |

<a id="adapter-à-ton-workflow"></a>

## 🎯 Adapter à ton workflow

Ce repo est public mais c'est **mon** Claude — pas un standard. Fork
librement et tord-le à ton workflow :

- **Tu n'utilises pas RTK ?** Vire `@RTK.md` en ligne 1 de `CLAUDE.md`
  + supprime `RTK.md` + retire le hook de `settings.json`. Les 4
  principes mindset tiennent debout sans.
- **Tu codes sur Linux/Mac ?** La règle 5 de RTK (PowerShell) ne te
  concerne pas, tout le reste s'applique.
- **Tu n'as qu'un poste ?** Pas besoin de `sync.sh` ni de remote — ça
  reste un dossier `.claude/` qui marche local.
- **Tu veux des principes plus stricts ou plus permissifs ?** Édite
  `CLAUDE.md`. Claude le lit au chargement, pas de redémarrage.

Source d'inspiration pour les 4 principes : un CLAUDE.md partagé
publiquement par un fondateur d'Anthropic. Le reste vient de mes propres
audits (RTK), incidents (no-truncate `--help`) et préférences workflow
(multi-agent review).

---

<div align="center">

**Claude générique est rapide. Mon Claude est rapide *et* sobre.**

</div>
