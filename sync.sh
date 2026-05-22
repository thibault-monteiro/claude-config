#!/usr/bin/env bash
# ~/.claude/sync.sh — synchronisation rapide entre postes
#
# Usage:
#   ./sync.sh                   # pull only
#   ./sync.sh "<msg>"           # add+commit+pull(rebase)+push
#   ./sync.sh status            # short status
#
# Le repo vit dans ~/.claude/. Pas besoin de cd, le script utilise
# git -C avec un chemin absolu (cf. RTK.md Rule 1).

set -e

REPO="$HOME/.claude"
G="git -C $REPO"

case "${1:-pull}" in
  status)
    $G status --short --branch
    echo
    $G log --oneline -5
    exit 0
    ;;

  pull)
    echo "→ pull --rebase"
    $G pull --rebase --autostash
    exit 0
    ;;

  *)
    # Arg = commit message → flow complet
    msg="$1"

    if [[ -n "$($G status --porcelain)" ]]; then
      echo "→ add + commit"
      $G add -A
      $G commit -m "$msg

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
    else
      echo "→ rien à committer localement"
    fi

    echo "→ pull --rebase (réconcilier avec l'autre poste)"
    $G pull --rebase --autostash

    if [[ -n "$($G log @{u}..HEAD --oneline 2>/dev/null)" ]]; then
      echo "→ push"
      $G push
    else
      echo "→ rien à pousser, on est à jour"
    fi
    ;;
esac
