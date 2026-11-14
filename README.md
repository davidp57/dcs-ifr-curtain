# DCS IFR curtain

Un rideau de vol aux instruments pour DCS World : une touche le ferme, l'élève ne voit plus que l'intérieur du cockpit, une autre touche le rouvre.
L'instructeur, dans un autre avion ou en vue extérieure, n'est pas concerné.

**État : réglé et validé sur le A-10C II, le seul avion équipé pour l'instant.**
Les autres modules n'ont pas le rideau tant qu'ils ne sont pas réglés (voir *Ajouter ou régler un avion*).

## Principe

Une bulle opaque, en toile froissée, entoure la tête du pilote juste au-delà de la verrière.
DCS dessine cet écran de cockpit avec le test de profondeur : tout ce qui est dans le cockpit (planche, HUD, montants, siège) est plus proche que la bulle et reste visible ; l'extérieur, plus loin, est caché.

La bulle est une boîte aux arêtes arrondies (une superellipsoïde) qui touche six murs réglés par avion.
Elle est faite d'environ 500 facettes plates, chacune placée puis orientée par deux pivots emboîtés (lacet, puis tangage), sans baisse d'images par seconde constatée en vol sur le A-10C II.
Chaque facette prend la texture vue du côté de la boîte vers lequel elle est tournée (dessus, côté, face), à partir d'une seule image qui couvre toute la bulle.

Le HUD reste visible sous le rideau : pour s'en passer, l'éteindre dans le cockpit.

## Au démarrage : ouvert ou fermé

Au démarrage de la mission, le rideau regarde si ses commandes existent :

| Situation | Au démarrage |
|---|---|
| l'injecteur de Quaggles est installé et le fichier de commandes injecté de l'avion contient « IFR curtain: toggle » (paquet Custom_Keybinds à jour) | **ouvert** ; la touche le ferme et le rouvre |
| sinon (rideau installé seul) | **fermé**, pour toute la mission |
| la vérification échoue | **fermé**, par prudence |

La raison est écrite dans `dcs.log` (lignes `IFR_CURTAIN`).
« Existe » veut dire « figure dans la liste des commandes », pas « assignée à une touche » : avec Custom_Keybinds à jour mais rien d'assigné, le rideau démarre ouvert.
Aucune fonction du Lua d'un cockpit ne dit si une commande existe, d'où la lecture du fichier (`Saved Games\DCS\InputCommands\<input>\keyboard\default.lua`, `input` étant réglé par avion dans `shapes.lua`).

## Installer avec Open Mod Manager

Les deux premiers paquets suffisent pour un rideau toujours fermé ; les deux autres ajoutent les touches :

| Paquet | Canal | Rôle |
|---|---|---|
| `Cockpit_Mods_Hook_v<version>.ozp` | Game files (`DCS World`) | l'accroche partagée des mods de cockpit ([dcs-cockpit-mods](https://github.com/davidp57/dcs-cockpit-mods)) |
| `IFR_Curtain_v<version>.ozp` (2.0.0 ou plus récente) | Game files | le rideau |
| `Quaggles_Injector` | Game files | permet d'ajouter des commandes sans toucher aux fichiers des modules |
| `Custom_Keybinds` (version du 2026-11-12 ou plus récente) | User files (`Saved Games\DCS`) | les commandes du rideau, avec les autres commandes de [dcs-community-keybinds](https://github.com/davidp57/dcs-community-keybinds) |

Puis dans DCS : Options > Commandes > A-10C II, catégorie « IFR curtain », assigner « IFR curtain: toggle » (ou « close » / « open »).

Le paquet du rideau contient le dossier `IFR_CURTAIN` et sa déclaration, `COCKPIT_MODS\IFR_CURTAIN.lua`, que l'accroche exécute ; il ne remplace aucun fichier de DCS.
C'est le paquet de l'accroche qui remplace `KNEEBOARD\declare_kneeboard_device.lua`, pour tous les mods de cockpit qui s'en servent : Open Mod Manager ne laisse qu'un paquet remplacer un même fichier.

**Venant d'une version 1.x** : elle remplaçait elle-même le fichier du kneeboard.
Désinstaller l'ancien paquet du rideau avant d'installer l'accroche, sinon Open Mod Manager signale un conflit sur ce fichier.

Construire le paquet (dans `dist\`) :

```powershell
python "D:\dev\_dcs-other\dcs-ifr-curtain\tools\build_omm.py" 2.0.0
```

## Contenu

- `mod/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/` : la liste des avions équipés et la forme de leur bulle (`shapes.lua`), le module Lua (`device.lua`), l'écran de cockpit (`indicator.lua`, `page.lua`), la texture (`curtain.tga`) et leur déclaration (`declare.lua`).
  La déclaration ne déclare le rideau que pour les avions de `shapes.lua`, et s'abstient si l'identifiant d'équipement 250 est déjà pris.
- `mod/Scripts/Aircrafts/_Common/Cockpit/COCKPIT_MODS/IFR_CURTAIN.lua` : la ligne qui lance cette déclaration, exécutée par l'accroche depuis le fichier du kneeboard, chargé par la plupart des modules.
- `tools/build_omm.py` : construit le paquet Open Mod Manager.
- `tools/make_curtain_texture.py` : génère `curtain.tga` (Python, `numpy` et `Pillow`).
- `install.ps1` : installation de développement, sans Open Mod Manager (voir plus bas).

Les commandes du rideau (`down` 3001 à 3003 sur l'équipement 250) sont ajoutées aux fichiers A-10C II de dcs-community-keybinds, y compris les profils HOTAS Warthog et Saitek X52.

## Installation de développement

Pour modifier le mod et l'essayer sans repasser par Open Mod Manager (ne pas installer les paquets en même temps).
L'accroche d'abord, depuis dcs-cockpit-mods :

```powershell
& "D:\dev\_dcs-other\dcs-cockpit-mods\install.ps1" -Part Hook
```

Puis le rideau :

```powershell
& "D:\dev\_dcs-other\dcs-ifr-curtain\install.ps1"
```

```powershell
& "D:\dev\_dcs-other\dcs-ifr-curtain\install.ps1" -Uninstall
```

Pour une autre installation de DCS : `-DcsPath "D:\DCS World"`.

Le script copie `IFR_CURTAIN` et `COCKPIT_MODS\IFR_CURTAIN.lua` ; il refuse si l'accroche n'est pas installée.
Les versions 1.x ajoutaient leur propre ligne au fichier du kneeboard, entre `-- IFR-CURTAIN BEGIN` et `-- IFR-CURTAIN END` : l'installation et la désinstallation la retirent, et remettent le fichier d'origine depuis sa sauvegarde `.ifr-curtain.bak` quand rien d'autre n'a changé.
Sans cette sauvegarde, la ligne vient d'un paquet `IFR_Curtain` 1.x : le script s'arrête et demande de désinstaller ce paquet dans Open Mod Manager, qui remet lui-même le fichier d'origine.
Comme l'accroche refuse de s'installer tant que cette ligne est là, passer d'une 1.x à la 2.0 se fait en trois temps : retirer la 1.x (paquet dans Open Mod Manager, ou `install.ps1 -Uninstall` du rideau), puis installer l'accroche, puis le rideau.
Les commandes viennent toujours de Custom_Keybinds.

## Limites

- **L'IC échoue** : des scripts de DCS sont modifiés. Utilisable en solo et sur les serveurs qui ne vérifient pas les scripts.
- **Une mise à jour ou une réparation de DCS écrase le fichier du kneeboard** : l'accroche, et avec elle le rideau, disparaît. Réinstaller le paquet de l'accroche (le reconstruire si la mise à jour a changé ce fichier), ou relancer son `install.ps1 -Part Hook`.
- **Le rideau ne fait pas d'ombre** : le soleil éclaire toujours la planche, et les ombres des montants tournent quand l'avion vire, ce qui trahit la position du soleil.
  Pour l'exercice, voler sous une couche nuageuse épaisse (pas de soleil direct) ou de nuit.
- **Les arêtes se devinent encore un peu**, là où une facette passe d'une projection de la texture à une autre, au milieu des arrondis.

## Ajouter ou régler un avion

La bulle se règle dans `shapes.lua` : pour chaque avion, la distance en mètres de l'origine du repère à chaque mur (`left`, `right`, `up`, `down`, `front`, `back`, toutes au-dessus de 0) et l'arrondi (`squareness`, au-dessus de 1 : 2 pour un ellipsoïde, plus pour une boîte aux arêtes plus vives).
L'avion est reconnu par un morceau du chemin de ses scripts de cockpit (`A-10C_2` pour `Mods/aircraft/A-10C_2/...`).
Un avion absent de `shapes.lua` n'a pas de rideau du tout.
Pour lui donner les touches, ajouter les trois commandes du rideau à ses fichiers dans dcs-community-keybinds (`InputCommands/<module>/Input/...`), comme pour le A-10C II, puis reconstruire Custom_Keybinds.
Un nouvel avion n'a que le A-10C II comme point de départ : commencer large (2 m partout), puis rapprocher mur par mur.

L'origine n'est pas la tête du pilote : sur le A-10C II elle est en avant, vers la planche.
Un mur trop proche coupe une partie du cockpit ; trop loin, il laisse voir l'extérieur entre la verrière et lui.
Un arrondi plus fort (`squareness` plus petit) estompe les arêtes mais fait rentrer la bulle dans les coins du cockpit.

Pour régler, `page.lua`, `DEBUG_COLOURS = true` met les facettes en damier de deux couleurs, sans texture.
Sans les touches (Custom_Keybinds absent ou sans l'avion), le rideau démarre fermé : c'est le plus simple pour régler la bulle d'un nouvel avion.

Relancer `install.ps1` après chaque modification, puis relancer la mission : les scripts du cockpit sont relus à chaque démarrage de mission, sans redémarrer DCS.
Pour le plafond, regarder vers l'avant la tête au plus haut, verrière fermée.

Réglages connus :

| Avion | gauche | droite | haut | bas | devant | derrière | arrondi |
|---|---|---|---|---|---|---|---|
| A-10C II | 1,0 | 1,0 | 0,3 | 1,5 | 1,2 | 1,6 | 3,0 |

## Texture

`curtain.tga` est une image de 1024 × 1024 pixels qui couvre 3 m de toile (la taille de la bulle du A-10C II ; elle s'étire un peu sur une bulle plus grande).
Pour la refaire, par exemple avec une autre couleur (`BASE_COLOUR`) ou des plis plus ou moins marqués :

```powershell
python "D:\dev\_dcs-other\dcs-ifr-curtain\tools\make_curtain_texture.py" "D:\dev\_dcs-other\dcs-ifr-curtain\mod\Scripts\Aircrafts\_Common\Cockpit\IFR_CURTAIN\curtain.tga"
```

DCS rend ces surfaces bien plus claires que leurs pixels : la luminosité finale se règle dans `page.lua`, `CURTAIN_TINT`.
