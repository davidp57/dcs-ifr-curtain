"""Builds the Open Mod Manager package of the IFR curtain, for the "Game files" channel.

The package (a .ozp zip) holds:
- modpack.xml and readme.md, as Open Mod Manager expects;
- <name>/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/...: the mod itself;
- <name>/Scripts/Aircrafts/_Common/Cockpit/COCKPIT_MODS/IFR_CURTAIN.lua: its declaration,
  run by the shared cockpit mods hook (Cockpit_Mods_Hook package, dcs-cockpit-mods).

It no longer replaces any DCS file: the hook package holds the patched kneeboard file.

Usage: python tools/build_omm.py VERSION [output folder]
       python tools/build_omm.py 2.0.0 dist
"""

import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

REPO = Path(__file__).resolve().parent.parent
MOD = REPO / "mod"

CATEGORY = "COMMUN - Amélioration"
DESCRIPTION = """Rideau de vol aux instruments : une touche ferme une bulle opaque en toile autour de la tête du pilote, juste au-delà de la verrière. Le cockpit reste visible, l'extérieur est caché. L'instructeur n'est pas concerné.

Avions équipés : A-10C II.

Demande le paquet Cockpit_Mods_Hook (« game files »). Touches (catégorie « IFR curtain ») : fournies par Custom_Keybinds (« user files »), avec Quaggles Injector (« game files »). Avec elles, le rideau démarre ouvert et la touche le ferme ; sans elles, il reste fermé toute la mission.

Ne passe pas l'IC.

Source : https://github.com/davidp57/dcs-ifr-curtain"""

README = """# IFR curtain

Rideau de vol aux instruments pour DCS World : une touche ferme une bulle opaque en toile autour de la tête du pilote, juste au-delà de la verrière.
Le cockpit (planche, HUD, montants) reste visible, l'extérieur est caché.

- Avions équipés : A-10C II.
- Demande le paquet Cockpit_Mods_Hook, l'accroche partagée des mods de cockpit.
- Touches : « IFR curtain: toggle / close / open », catégorie « IFR curtain », fournies par le paquet Custom_Keybinds avec Quaggles Injector.
  Avec elles, le rideau démarre ouvert et la touche le ferme ; sans elles, il reste fermé toute la mission.
- Ne passe pas l'IC : solo et serveurs qui ne vérifient pas les scripts.

Source et documentation : https://github.com/davidp57/dcs-ifr-curtain
"""


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    version = sys.argv[1]
    out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else REPO / "dist"

    name = f"IFR_Curtain_v{version}"
    out_dir.mkdir(parents=True, exist_ok=True)
    package = out_dir / f"{name}.ozp"

    modpack = (
        "<Open_Mod_Manager_Package>\n"
        f"\t<install>{name}</install>\n"
        f"\t<category>{CATEGORY}</category>\n"
        f"\t<description>{escape(DESCRIPTION)}</description>\n"
        "</Open_Mod_Manager_Package>\n"
    )
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("modpack.xml", modpack.encode("utf-8"))
        z.writestr("readme.md", README.encode("utf-8"))
        for f in sorted(MOD.rglob("*")):
            if f.is_file():
                z.write(f, f"{name}/{f.relative_to(MOD).as_posix()}")

    print(f"Written: {package}")
    with zipfile.ZipFile(package) as z:
        for n in z.namelist():
            print("  ", n)


if __name__ == "__main__":
    main()
