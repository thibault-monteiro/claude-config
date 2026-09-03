# RTK (Rust Token Killer) : réflexes outils

Proxy CLI d'économie de tokens, 60 à 90 % sur les opérations dev courantes. Un hook
`PreToolUse` réécrit les commandes simples avant exécution (`git status` devient
`rtk git status`), de façon transparente et sans surcoût de tokens. Les réflexes ci-dessous,
appliqués à **chaque** appel d'outil, maximisent son taux de réécriture.

## Meta-commandes (toujours appelées telles quelles)

```bash
rtk gain              # tableau de bord des économies
rtk gain --history    # historique des commandes avec l'économie par commande
rtk discover          # analyse l'historique Claude Code, repère les occasions manquées
rtk proxy <cmd>       # exécute la commande brute, sans filtre (débogage)
```

`rtk gain` est la vérité sur les économies, pas `rtk discover` : `discover` lit la commande
telle qu'elle a été tapée dans le transcript et sur-compte les « ratés », parce qu'il ne voit
pas les réécritures faites par le hook.

## Vérifier l'installation

```bash
rtk --version         # doit afficher : rtk X.Y.Z
rtk gain              # doit répondre (et pas « command not found »)
which rtk             # vérifier que c'est le bon binaire
```

⚠️ **Collision de nom.** Deux projets différents s'appellent `rtk`. Si `rtk --version` répond
mais que `rtk gain` échoue, c'est *Rust Type Kit* (`reachingforthejack/rtk`) qui est installé,
pas *Rust Token Killer* (`rtk-ai/rtk`). Le signaler, ne rien désinstaller de soi-même.

Certains filtres appellent `ripgrep`. L'avertissement `Binary 'rg' not found on PATH` se
supprime en installant `ripgrep` (`brew install ripgrep` sur macOS, le gestionnaire de
paquets de la distribution sur Linux, `winget install BurntSushi.ripgrep.MSVC` sur Windows).

---

## Rule 1 : jamais `cd <dir> && …`

C'est la règle la plus violée. Le répertoire de travail de l'outil Bash est **déjà** la
racine du projet, et une commande composée comme `cd /chemin/du/repo && git status` gaspille
des tokens ET rend la réécriture moins fiable.

Checklist mentale, à chaque appel Bash :

```
□ Ma commande commence-t-elle par `cd ` ?
  ├─ suivie de `git …`        → réécrire en `git -C <chemin> …`
  ├─ suivie d'un script       → le cwd est déjà bon, SUPPRIMER le `cd`
  └─ suivie d'autre chose     → se demander si un chemin absolu suffirait
```

```bash
# MAUVAIS (tue la réécriture, réinitialise le cwd du shell)
cd /chemin/autre-repo && git status
cd "$repo" && npm test

# BON
git status                              # le cwd est déjà le bon
git -C /chemin/autre-repo log --oneline -5   # pour travailler sur un autre dépôt
npm test
```

`git -C <chemin>` est le remplacement canonique quand il faut agir sur un autre dépôt : il
est routé par le hook, exactement comme `git <cmd>`.

Exception rare et intentionnelle : un sous-répertoire de monorepo pour lequel aucune forme en
chemin absolu ne marche. Alors un seul `cd`, suivi du vrai travail.

## Rule 2 : les fichiers passent par les outils Claude Code, pas par le shell

Obligatoire, pas une préférence. Ces outils court-circuitent Bash **et** sont déjà optimaux
en tokens. Retomber sur `cat` / `find` / `grep` depuis Bash contourne silencieusement RTK et
les optimisations intégrées de Claude Code.

Checklist mentale, à chaque appel Bash :

```
□ Ma commande LIT un fichier ?
  ├─ `cat <fichier>`            → outil Read
  ├─ `head -N` / `tail -N`      → outil Read avec `limit` / `offset`
  └─ `less` / `more`            → outil Read

□ Ma commande ÉCRIT un fichier ?
  ├─ `cat > f << 'EOF'`         → outil Write (JAMAIS de heredoc, même pour un JSON d'état)
  ├─ `echo "…" > f`             → outil Write
  └─ un append `>>`             → Read puis Write (réécrire le fichier entier)

□ Ma commande CHERCHE ?
  ├─ `find . -name "*.ts"`      → outil Glob
  ├─ `grep -r "foo" src/`       → outil Grep
  └─ `ls -la <chemin>`          → outil Glob (pour de l'exploration)
```

**Le piège du heredoc.** `cat > fichier << 'EOF' … EOF` est **100 % non routé** : le hook ne
peut pas analyser le corps, et toute la charge utile part littéralement dans Bash. Sur un
fichier d'état réécrit en boucle, le coût se multiplie. Toujours `Write`.

Exceptions où Bash est le bon choix :

- inspection au niveau octet : `od`, `hexdump`, `xxd` ;
- utilitaires de flux : `wc -l`, `awk`, `sed` pour une transformation en ligne ;
- ajouter une ligne courte à un log (`echo X >> log`), trop petit pour compter ;
- ce que les outils ne savent pas exprimer, ce qui est très rare.

Les chaînes de pipes lourdes (`cmd1 | cmd2 | cmd3`) contournent aussi la réécriture : même
règle, les outils dédiés d'abord.

## Rule 3 : batcher correctement

- Commandes **indépendantes** : un seul message avec plusieurs appels `Bash` (exécution
  parallèle, chacun routable individuellement).
- Commandes **dépendantes** : un seul appel `Bash` avec `&&`. Le hook réécrit les
  sous-commandes connues à l'intérieur d'une commande composée, donc c'est sans perte.

## Rule 4 : regarder `rtk gain` de temps en temps

Quand quelqu'un demande « combien on a gagné ? », lancer `rtk gain` et donner ce chiffre. Voir
la nuance avec `rtk discover` plus haut.

## Rule 5 : sur Windows

`PowerShell` et `cmd.exe` ne sont pas routés par RTK (pas de handler). Préférer l'outil Bash
pour git, ls, grep, node, npm, même sur Windows, afin de bénéficier du hook. Sans objet sur
macOS et Linux.

Seuil objectif pour un `-Command "…"` en ligne :

- ✅ **Obligatoire** : `powershell.exe -NoProfile -File <script>.ps1 [args…]`, l'appel d'un
  script commité. À garder tel quel.
- 🟠 **Limite** : `-Command "<une cmdlet courte>"`, moins de 60 caractères et sans pipe.
  Toléré pour un one-shot.
- 🔴 **Interdit** : `-Command "…"` qui contient un pipe `|` **ou** dépasse ~60 caractères.
  C'est un script ad hoc qui part token par token sans être routé : le sauver en `.ps1`
  d'abord, ce qui le rend en plus réutilisable.
