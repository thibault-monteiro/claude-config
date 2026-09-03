# `team/` : la config à installer chez un collègue

Ce dossier est la **charge utile d'équipe**. Il est volontairement séparé de la racine du
dépôt : à la racine vivent les fichiers personnels de Thibault (identité de commit, règles de
mail, `statusLine` en chemin absolu, préférences), qui ne se recopient chez personne.

L'installation est pilotée par un prompt unique, à coller dans une session Claude Code sur le
poste à équiper. Ce prompt sauvegarde l'existant, fusionne au lieu de remplacer, et est
réentrant. Le demander à Thibault Monteiro.

| Fichier | Ce qu'il devient sur le poste |
|---|---|
| `CLAUDE.dpp.md` | copié verbatim, marqueurs compris, dans `~/.claude/CLAUDE.md` |
| `RTK.md` | remplace tout `~/.claude/RTK.md` (celui que `rtk init` vient d'écrire) |
| `permissions.json` | ses listes `allow` / `deny` sont **unies** à celles de `~/.claude/settings.json` |

Trois couches au total, dont deux ne sont pas dans ce dossier parce qu'elles s'installent par
commande : le binaire `rtk` (allège ce que Claude **lit**) et le plugin `caveman` (allège ce
qu'il **écrit**).

## Modifier ce dossier

`CLAUDE.dpp.md` porte les marqueurs `<!-- BEGIN bonnes-pratiques-dpp -->` et
`<!-- END bonnes-pratiques-dpp -->` : c'est ce qui permet à une réinstallation de remplacer
le bloc sans toucher au reste du `CLAUDE.md` de la personne. **Ne pas les retirer.**

Ce dépôt est **public**. Rien de ce dossier ne doit contenir un hôte interne, une adresse IP,
un nom de compte, un chemin de poste ou un token. Les identifiants concrets se transmettent
en interne, pas ici.
