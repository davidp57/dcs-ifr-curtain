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

Le rideau démarre ouvert. Le HUD reste visible sous le rideau : pour s'en passer, l'éteindre dans le cockpit.

## Installer avec Open Mod Manager

Trois paquets, dans deux canaux :

| Paquet | Canal | Rôle |
|---|---|---|
| `IFR_Curtain_v<version>.ozp` | Game files (`DCS World`) | le rideau |
| `Quaggles_Injector` | Game files | permet d'ajouter des commandes sans toucher aux fichiers des modules |
| `Custom_Keybinds` (version du 2026-11-12 ou plus récente) | User files (`Saved Games\DCS`) | les commandes du rideau, avec les autres commandes de [dcs-community-keybinds](https://github.com/davidp57/dcs-community-keybinds) |

Puis dans DCS : Options > Commandes > A-10C II, catégorie « IFR curtain », assigner « IFR curtain: toggle » (ou « close » / « open »).

Le paquet du rideau contient le dossier `IFR_CURTAIN` et une copie complète de `KNEEBOARD\declare_kneeboard_device.lua` avec une ligne ajoutée : Open Mod Manager ne sait que remplacer des fichiers entiers, il sauvegarde l'original et le remet à la désinstallation.
Cette copie est prise sur la version de DCS installée au moment de construire le paquet.

Construire le paquet (dans `dist\`) :

```powershell
python "D:\dev\_dcs-other\dcs-ifr-curtain\tools\build_omm.py" 1.0.0 "C:\jeux\DCS World"
```

## Contenu

- `mod/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/` : la liste des avions équipés et la forme de leur bulle (`shapes.lua`), le module Lua (`device.lua`), l'écran de cockpit (`indicator.lua`, `page.lua`), la texture (`curtain.tga`) et leur déclaration (`declare.lua`).
  Ajoutée au fichier du kneeboard, chargé par la plupart des modules, la déclaration ne déclare le rideau que pour les avions de `shapes.lua`, et s'abstient si l'identifiant d'équipement 250 est déjà pris.
- `tools/build_omm.py` : construit le paquet Open Mod Manager.
- `tools/make_curtain_texture.py` : génère `curtain.tga` (Python, `numpy` et `Pillow`).
- `install.ps1` : installation de développement, sans Open Mod Manager (voir plus bas).

Les commandes du rideau (`down` 3001 à 3003 sur l'équipement 250) sont ajoutées aux fichiers A-10C II de dcs-community-keybinds, y compris les profils HOTAS Warthog et Saitek X52.

## Installation de développement

Pour modifier le mod et l'essayer sans repasser par Open Mod Manager (ne pas installer le paquet en même temps) :

```powershell
& "D:\dev\_dcs-other\dcs-ifr-curtain\install.ps1"
```

```powershell
& "D:\dev\_dcs-other\dcs-ifr-curtain\install.ps1" -Uninstall
```

Pour une autre installation de DCS : `-DcsPath "D:\DCS World"`.

Le script copie `IFR_CURTAIN` et ajoute la ligne d'accroche au fichier du kneeboard, encadrée par `-- IFR-CURTAIN BEGIN` / `-- IFR-CURTAIN END`.
Le fichier est sauvegardé en `.ifr-curtain.bak` avant la modification, sauvegarde reprise chaque fois qu'il est trouvé sans le rideau (après une mise à jour de DCS, par exemple).
La désinstallation le rend identique à l'original et supprime la sauvegarde ; un fichier qui n'est pas en UTF-8 valide est refusé plutôt que réécrit.
Les commandes viennent toujours de Custom_Keybinds.

## Limites

- **L'IC échoue** : des scripts de DCS sont modifiés. Utilisable en solo et sur les serveurs qui ne vérifient pas les scripts.
- **Une mise à jour ou une réparation de DCS écrase le fichier du kneeboard** : le rideau disparaît. Réinstaller le paquet (le reconstruire si la mise à jour a changé ce fichier), ou relancer `install.ps1`.
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

Pour régler, deux interrupteurs de mise au point :

- `page.lua`, `DEBUG_COLOURS = true` : facettes en damier de deux couleurs, sans texture ;
- `device.lua`, `START_CLOSED = true` : le rideau démarre fermé.

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
