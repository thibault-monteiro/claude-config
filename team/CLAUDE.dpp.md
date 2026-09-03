<!-- BEGIN bonnes-pratiques-dpp -->
## Bonnes pratiques (config d'équipe)

Bloc maintenu dans <https://github.com/thibault-monteiro/claude-config>, dossier `team/`.
Version du 03/09/2026. Une question, un problème : Thibault Monteiro.
Pour retirer ces règles : supprimer tout ce qui est entre les deux marqueurs `bonnes-pratiques-dpp`.

### Langue

Réponds en français. Tout texte adressé à un humain (messages, résumés, plans, questions,
statuts, rapports de fin de tâche) est en français.

- Ne traduis PAS le code, les noms de variables, les messages de commit ni les termes
  techniques d'usage (cloud, merge, build, commit) : ils suivent les règles du dépôt.
- Terme technique sans bon équivalent : garde l'anglais et explique-le en français.

### Ponctuation : pas de tiret cadratin

Convention maison. Aucun « — » (ni « – ») dans ce qui est écrit pour un humain : terminal,
mail, résumé, document, commentaire de merge request. Le remplacement par défaut est « : ».

- Quand « : » ne passe pas grammaticalement, reformuler plutôt que forcer. Une incise entre
  deux tirets devient des virgules ou des parenthèses.
- Pas de double deux-points dans une même proposition : si la phrase en a déjà un, reformuler.
- Ne s'applique pas au contenu repris tel quel (citation, chaîne existante, données d'un
  fichier source).

### Ne jamais tronquer une sortie help / list / version

Pour décider si un outil supporte X, LIS TOUTE la sortie de `--help` / `list` / `version`,
ou un `grep` ciblé qui ne cache rien. Pas de `head -N` / `tail -N` arbitraire : ça produit
de faux « ça n'existe pas » quand l'élément cherché tombe dans la zone coupée.

Exceptions : une sortie énorme (log de build) scannée pour un signal précis avec un `grep`
ou un `tail` intentionnel, et « les N premiers » quand c'est ce qui est demandé.

### Hygiène de contexte : ce qui y entre est relu à CHAQUE tour

Une sortie de commande n'est pas payée une fois : elle reste dans le contexte et est relue
à chacun des tours suivants. Une sortie de 5 000 tokens produite au tour 50 d'une session
qui en fait 300 est relue 250 fois. Sur une session longue, ce sont les sorties recopiées
en entier, pas le raisonnement, qui pèsent le plus lourd.

Trois réflexes :

- **Commande verbeuse** (build, test, install, `git log` large, dump JSON, scrape HTML) :
  rediriger vers un fichier et ne lire que ce qui décide, par exemple
  `… > build.log 2>&1; tail -30 build.log`, ou un `grep` des erreurs. Le fichier reste sous
  la main si le détail devient nécessaire.
- **`Read` ciblé** : `offset` / `limit` sur un gros fichier, plutôt que le lire en entier
  « pour voir ».
- **Déléguer l'exploration** (« où est défini X », balayage de plusieurs fichiers, lecture
  d'un gros diff) à un sous-agent : son contexte meurt avec lui, seule la conclusion remonte.

Ce n'est PAS une invitation à moins vérifier, ni à écourter un travail fouillé quand il est
demandé : mêmes commandes, mêmes tests, mêmes vérifications. On en lit le verdict au lieu
d'en recopier l'intégralité.

### Discipline d'ingénierie

À appliquer sur toute tâche de code non triviale : implémenter une feature, refactorer,
corriger un bug, toute modification au-delà d'un one-liner. À ignorer pour le trivial (typo,
bump de version, import mort) et les questions en lecture seule.

**1. Réfléchir avant de coder.** Ne pas supposer, ne pas masquer une confusion.
- Énoncer les hypothèses. En cas de doute, demander.
- Plusieurs interprétations possibles : les présenter, ne pas en choisir une en silence.
- Une approche plus simple existe : le dire, quitte à contredire la demande.

**2. Simplicité d'abord.** Le minimum de code qui résout le problème, rien de spéculatif.
- Aucune feature au-delà de ce qui est demandé, aucune abstraction pour un usage unique.
- Aucune « flexibilité » non demandée, aucune gestion d'erreur pour un cas impossible.
- 200 lignes qui pourraient en faire 50 : réécrire.
- Test : « un senior dirait-il que c'est surcompliqué ? » Si oui, simplifier.

**3. Changements chirurgicaux.** Chaque ligne modifiée doit tracer à la demande.
- Ne pas « améliorer » le code, les commentaires ou le formatage alentour.
- Ne pas refactorer ce qui n'est pas cassé. Suivre le style existant, même si on ferait
  autrement.
- Du code mort repéré au passage : le signaler, ne pas le supprimer.
- Si le changement orpheline un import ou une variable, la retirer : c'est le seul ménage
  qui va de soi.

**4. Exécution pilotée par un objectif vérifiable.** Définir les critères de succès AVANT
de coder, puis boucler jusqu'à vérification.
- « Ajouter une validation » devient « écrire les tests des entrées invalides, puis les
  faire passer ».
- « Corriger le bug » devient « écrire un test qui le reproduit, puis le faire passer ».
- Pour une tâche en plusieurs étapes, annoncer un plan court : `étape → vérification`.

**Relecture par un sous-agent indépendant, à chaque tranche.** Pour toute feature ou
refactor non trivial, travailler en duo plutôt que seul : le fil principal implémente, un
sous-agent lancé via l'outil `Agent` relit chaque tranche avant que la suivante commence.

- Le relecteur doit avoir **son propre contexte** et un brief autoportant (chemins des
  fichiers, ce qui a changé, ce qu'il faut vérifier). Se relire soi-même et appeler ça une
  relecture indépendante ne compte pas.
- Ce qu'il vérifie, dans cet ordre : exactitude, respect du périmètre, duplication avec du
  code existant, harmonie avec les patterns du module, cohérence de style, valeurs en dur
  qui devraient être configurables.
- Une tranche est une couche cohérente de la feature, le point où l'on ferait naturellement
  une pause. Ne pas repousser toutes les relectures à la fin : le coût d'un défaut de
  conception grandit avec chaque tranche construite dessus.
- Agir sur la relecture, ne pas la recopier à l'humain.

### caveman : ce qui est comprimé, et ce qui ne l'est jamais

Le plugin `caveman` comprime **ce que Claude écrit** dans le chat (fin du remplissage et des
reformulations), environ 65 % de tokens de sortie en moins. Il est actif au **démarrage d'une
nouvelle session**, jamais en cours de conversation.

- `/caveman lite|full|ultra` règle l'intensité, `/caveman off` le coupe.
- Un fichier `.caveman.json` à la racine d'un dépôt fixe le défaut de ce dépôt, par exemple
  `{"defaultMode":"off"}` sur un projet dont la sortie est de la prose destinée à un humain.

Deux garanties, et ce sont des règles, pas des effets de bord :

- **La langue est préservée.** C'est le style qui est comprimé, pas la langue : les réponses
  restent en français.
- **Rien n'est comprimé hors du chat.** Messages de commit, documentation, descriptions de
  merge request, tickets, mémoires et tout texte destiné à un autre humain restent en prose
  normale. La compression s'arrête au bord de la conversation.

### L'environnement de l'équipe

Ce qui est vrai chez nous et qui ne se devine pas :

- **Le code vit sur un GitLab auto-hébergé**, pas sur GitHub : les merge requests, les
  pipelines et les registres y sont. Les commandes `gh` ne servent à rien ici, c'est
  l'API GitLab ou `glab`.
- **La preprod de certains projets se déclenche par un TAG git, jamais par une merge
  request.** Dans la pipeline d'un tag, le job `delivery` déploie la preprod, le job
  `production` déploie la prod et reste **manuel**. Règle « 1 tag = 1 mise en prod » : si le
  dernier tag n'est pas parti en prod, on le **recycle** (on le supprime et on recrée le même
  numéro sur le commit à déployer, pour ne pas trouer la suite de versions) ; s'il y est
  parti, on **incrémente**. On ne supprime JAMAIS un tag allé en prod.
- **La preprod est exclusive** : un seul tag déployé à la fois, qui peut embarquer plusieurs
  US. Avant de la reprendre, vérifier qui l'occupe déjà, sinon on décharge le travail d'un
  collègue sans le savoir.
- **Une partie des ressources n'est joignable que par le VPN d'entreprise** (bases,
  back-office, serveurs de preprod). Une commande qui échoue en timeout réseau est le plus
  souvent un VPN coupé, pas un bug : le vérifier avant d'ouvrir une enquête.
- **Les identifiants concrets ne sont pas dans ce dépôt public** : hôte GitLab, adresses des
  passerelles VPN, noms de profils, tokens d'API. À demander à l'équipe, et à garder hors de
  tout dépôt public.
<!-- END bonnes-pratiques-dpp -->
