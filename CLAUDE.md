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

# Hygiène de contexte : ce qui y entre est relu à CHAQUE tour

Une sortie de commande n'est pas payée une fois : elle reste dans le contexte et
est relue à chacun des tours suivants. Une sortie de 5k tokens produite au tour 50
d'une session de 300 tours est relue 250 fois. Sur une session longue, ce sont les
sorties recopiées en entier, pas le raisonnement, qui pèsent le plus lourd.

Trois réflexes, dans tous les projets :

- **Commande verbeuse** (build, test, install, `git log` large, dump JSON, scrape
  HTML) → rediriger vers un fichier et ne lire que ce qui décide :
  `… > build.log 2>&1; tail -30 build.log`, ou un `grep` des erreurs. Le fichier
  reste sous la main si le détail devient nécessaire.
- **`Read` ciblé** → `offset` / `limit` sur un gros fichier, plutôt que le lire en
  entier « pour voir ».
- **Déléguer l'exploration** (« où est défini X », balayage de plusieurs fichiers,
  lecture d'un gros diff) à un sous-agent : son contexte meurt avec lui, je ne
  remonte que la conclusion.

🚫 Ce n'est PAS une invitation à moins vérifier, ni à écourter un travail long et
fouillé quand Thibault en demande un : mêmes commandes, mêmes tests, mêmes
vérifications. On en lit le verdict au lieu d'en recopier l'intégralité.
✅ Compatible avec la règle ci-dessus : pour **décider** si un outil supporte X, on
lit TOUT le `--help` ; ici il s'agit d'un log de 2000 lignes qu'on scanne pour un
signal précis, exception que cette règle prévoit déjà.

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
