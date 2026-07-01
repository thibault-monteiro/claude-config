#!/usr/bin/env bash
# ~/.claude/sync-private.sh — synchro des données PRIVÉES entre postes
#
# Ce que sync.sh (public → claude-config) ne peut PAS porter, car sensible :
#   - mémoires projet : projects/*/memory/**   (contiennent des secrets, ex. clé Kinsta)
#   - skills custom    : skills/**             (référencent de l'infra interne)
#
# Dépôt PRIVÉ DÉDIÉ, isolé par construction :
#   - git-dir séparé  : ~/.claude/.private.git   (ne collisionne pas avec le .git public)
#   - work-tree       : ~/.claude                (les fichiers restent en place)
#   - remote UNIQUE   : claude-conf (privé)      → AUCUN remote public → fuite impossible
#
# Usage :
#   ./sync-private.sh setup           # 1re fois sur un poste : init + remote + récupère la branche 'private'
#   ./sync-private.sh push ["<msg>"]  # add mémoires+skills, commit, push
#   ./sync-private.sh pull            # récupère les dernières mémoires depuis claude-conf
#   ./sync-private.sh status          # état

set -e

GD="$HOME/.claude/.private.git"
WT="$HOME/.claude"
REMOTE="https://github.com/thibault-monteiro/claude-conf.git"

# Un seul cd, intentionnel : les pathspecs et globs ci-dessous se résolvent
# par rapport au work-tree. (cf. RTK.md — exception « sous-répertoire nécessaire »)
cd "$WT"

pg() { git --git-dir="$GD" --work-tree="$WT" "$@"; }

# Ajoute UNIQUEMENT les mémoires et les skills (jamais les transcripts *.jsonl).
# -f : la .gitignore publique (/*) couvre tout le work-tree ; on force donc
# l'ajout des seuls chemins explicitement listés ici (aucun risque d'élargir).
stage_private() {
  local dirs=(skills)
  for d in projects/*/memory; do [[ -d "$d" ]] && dirs+=("$d"); done
  pg add -f -A -- "${dirs[@]}"
}

case "${1:-status}" in
  setup)
    if [[ -d "$GD" ]]; then
      echo "→ déjà initialisé ($GD)"
    else
      pg init -q
      pg checkout -q -b private 2>/dev/null || true
      pg remote add origin "$REMOTE"
      pg config status.showUntrackedFiles no   # ignore les transcripts non suivis dans `status`
      echo "→ init OK (git-dir dédié, remote privé uniquement)"
    fi
    echo "→ fetch claude-conf"
    pg fetch origin -q || true
    if pg rev-parse --verify -q origin/private >/dev/null; then
      pg checkout -B private origin/private
      echo "→ mémoires + skills récupérés depuis claude-conf (branche 'private')"
    else
      echo "→ pas encore de branche 'private' sur claude-conf."
      echo "  Lance d'abord un './sync-private.sh push' depuis le poste qui a les mémoires."
    fi
    ;;

  push)
    msg="${2:-sync private: mémoires projet + skills}"
    stage_private
    if pg diff --cached --quiet; then
      echo "→ rien de nouveau à committer"
    else
      pg commit -q -m "$msg"
      echo "→ commit OK"
    fi
    pg push -u origin HEAD:private
    echo "→ push OK (claude-conf, branche 'private')"
    ;;

  pull)
    pg fetch origin -q
    pg checkout -B private origin/private
    echo "→ pull OK (mémoires + skills à jour)"
    ;;

  status)
    if [[ -d "$GD" ]]; then
      pg status -sb
    else
      echo "pas encore initialisé — lance : ./sync-private.sh setup"
    fi
    ;;

  *)
    echo "usage: ./sync-private.sh {setup|push [msg]|pull|status}"
    exit 1
    ;;
esac
