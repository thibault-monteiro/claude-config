@RTK.md

# Langue de communication — RÈGLE PRIORITAIRE

Réponds **TOUJOURS en français** à Thibault (il ne lit pas l'anglais). Tout texte
qui lui est adressé — messages, résumés, explications, questions, plans, statuts,
rapports de fin de tâche — est en français.

- Ne traduis PAS le code, les noms de variables, les messages de commit ni les
  termes techniques d'usage (cloud, merge…) — ils suivent les règles du repo.
- Terme technique sans bon équivalent → garde l'anglais et explique-le en français.

# Réflexe : ne jamais tronquer une sortie help / list / version

Pour décider si un outil supporte X, LIS TOUTE la sortie de `--help` / `list` /
`version` (ou `| grep` ciblé qui ne cache rien). Pas de `head -N` / `tail -N`
arbitraire → ça produit de faux « ça n'existe pas » quand l'élément cherché tombe
dans la zone coupée. Exceptions : sorties énormes (build logs) scannées pour un
signal précis avec `grep`/`tail` *intentionnel*, ou « les N premiers » demandés.

# Mails : j'écris le HTML, je ne touche JAMAIS à Gmail

« Réponds à ce mail » = **produis le corps du message en HTML**, que Thibault relit
puis copie-colle lui-même. Interdit de prendre la main sur sa boîte : pas de
brouillon créé, pas d'envoi, pas de libellé, aucune écriture via les outils Gmail
(MCP ou navigateur). Lire le fil pour le contexte : OK.

- HTML simple compatible Gmail (`p`, `strong`, `ul`, `a`, styles inline, rien
  d'externe), écrit dans un fichier du scratchpad puis livré en rendu
  (`SendUserFile`, `display: "render"`) pour qu'il copie depuis le visuel.
- Pas de bloc signature : Gmail ajoute le sien.

# Discipline d'ingénierie — toute tâche de code non triviale

Dès qu'on implémente / ajoute une feature / refactor / corrige un bug (au-delà d'un
one-liner), **charge et applique le skill `engineering-discipline`** : réfléchir avant
de coder, simplicité d'abord, changements chirurgicaux, exécution pilotée par objectif
vérifiable, + relecture par sous-agent indépendant à chaque tranche. À ignorer pour le
trivial (typo, bump de version, import mort) et les questions en lecture seule.
