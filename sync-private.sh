#!/usr/bin/env bash
# ~/.claude/sync-private.sh — synchro des données PRIVÉES entre postes
#
# Ce que sync.sh (public → claude-config) ne peut PAS porter, car sensible :
#   - mémoires projet  : projects/*/memory/**  (contiennent des secrets, ex. clé Kinsta)
#   - skills custom    : skills/**             (référencent de l'infra interne)
#   - tâches planifiées : scheduled-tasks/**    (prompts citant campagnes, chemins, ids)
#   - restauration      : restauration/**       (inventaire du poste : où vit quoi)
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
# Chemins ajoutés conditionnellement : un poste vierge n'a ni skills/ ni mémoires,
# et `git add` d'un pathspec inexistant renvoie rc=128 → tuerait set -e.
stage_private() {
  local dirs=()
  [[ -d skills ]] && dirs+=(skills)
  [[ -d scheduled-tasks ]] && dirs+=(scheduled-tasks)
  [[ -d restauration ]] && dirs+=(restauration)
  for d in projects/*/memory; do [[ -d "$d" ]] && dirs+=("$d"); done
  if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "→ rien à indexer (aucun contenu privé sur ce poste)"
    return 0
  fi
  pg add -f -A -- "${dirs[@]}"
}

# Récupère origin/private SANS écraser des commits locaux non poussés.
# (checkout -B brut ferait perdre des commits locaux en cas de divergence.)
safe_pull_private() {
  if ! pg rev-parse --verify -q origin/private >/dev/null; then
    echo "→ pas de branche 'private' sur claude-conf — rien à récupérer."
    echo "  Lance './sync-private.sh push' depuis le poste qui a les mémoires."
    return 0
  fi
  if pg show-ref --verify -q refs/heads/private; then
    local ahead
    ahead=$(pg rev-list --count origin/private..private 2>/dev/null || echo 0)
    if [[ "$ahead" -gt 0 ]]; then
      echo "⛔ $ahead commit(s) local(aux) non poussé(s) sur 'private'."
      echo "  Lance './sync-private.sh push' d'abord (sinon ils seraient perdus)."
      exit 1
    fi
    pg checkout -q private 2>/dev/null || true
    pg merge --ff-only origin/private
  else
    pg checkout -B private origin/private
  fi
  echo "→ mémoires + skills à jour depuis claude-conf"
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
    safe_pull_private
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
    safe_pull_private
    ;;

  status)
    if [[ -d "$GD" ]]; then
      pg status -sb
      # showUntrackedFiles=no masque les nouvelles mémoires : on les liste explicitement.
      dirs=(); [[ -d skills ]] && dirs+=(skills)
      [[ -d scheduled-tasks ]] && dirs+=(scheduled-tasks)
      [[ -d restauration ]] && dirs+=(restauration)
      for d in projects/*/memory; do [[ -d "$d" ]] && dirs+=("$d"); done
      if [[ ${#dirs[@]} -gt 0 ]]; then
        new=$(pg -c status.showUntrackedFiles=normal status -s -- "${dirs[@]}" | grep -c '^??' || true)
        [[ "$new" -gt 0 ]] && echo "→ $new fichier(s) privé(s) non encore suivi(s) — un 'push' les prendra"
      fi
    else
      echo "pas encore initialisé — lance : ./sync-private.sh setup"
    fi
    ;;

  *)
    echo "usage: ./sync-private.sh {setup|push [msg]|pull|status}"
    exit 1
    ;;
esac
