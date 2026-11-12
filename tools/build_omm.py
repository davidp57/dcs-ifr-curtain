"""Builds the Open Mod Manager package of the IFR curtain, for the "Game files" channel.

The package (a .ozp zip) holds:
- modpack.xml and readme.md, as Open Mod Manager expects;
- <name>/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/...: the mod itself;
- <name>/Scripts/Aircrafts/_Common/Cockpit/KNEEBOARD/declare_kneeboard_device.lua: a full
  copy of the DCS file with one line added, since Open Mod Manager can only replace whole
  files (it backs up the original and puts it back on uninstall).

The kneeboard file is taken from the DCS install given, so the package matches that DCS
version: rebuild it after a DCS update that changes the file.

Usage: python tools/build_omm.py VERSION [DCS path] [output folder]
       python tools/build_omm.py 1.0.0 "C:/jeux/DCS World" dist
"""

import re
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MOD = REPO / "mod" / "Scripts" / "Aircrafts" / "_Common" / "Cockpit" / "IFR_CURTAIN"
KNEEBOARD = Path("Scripts/Aircrafts/_Common/Cockpit/KNEEBOARD/declare_kneeboard_device.lua")
HOOK = 'dofile(LockOn_Options.common_script_path.."IFR_CURTAIN/declare.lua")'
MARKER = "IFR-CURTAIN"

CATEGORY = "COMMUN - Amélioration"
DESCRIPTION = """Rideau de vol aux instruments : une touche ferme une bulle opaque en toile autour de la tête du pilote, juste au-delà de la verrière. Le cockpit reste visible, l'extérieur est caché. L'instructeur n'est pas concerné.

Avions équipés : A-10C II.

Touches (catégorie « IFR curtain ») : fournies par Custom_Keybinds (« user files »), avec Quaggles Injector (« game files »). Avec elles, le rideau démarre ouvert et la touche le ferme ; sans elles, il reste fermé toute la mission.

Remplace Scripts\\Aircrafts\\_Common\\Cockpit\\KNEEBOARD\\declare_kneeboard_device.lua (une ligne ajoutée) : à reconstruire si une mise à jour de DCS modifie ce fichier. Ne passe pas l'IC.

Source : https://github.com/davidp57/dcs-ifr-curtain"""

README = """# IFR curtain

Rideau de vol aux instruments pour DCS World : une touche ferme une bulle opaque en toile autour de la tête du pilote, juste au-delà de la verrière.
Le cockpit (planche, HUD, montants) reste visible, l'extérieur est caché.

- Avions équipés : A-10C II.
- Touches : « IFR curtain: toggle / close / open », catégorie « IFR curtain », fournies par le paquet Custom_Keybinds avec Quaggles Injector.
  Avec elles, le rideau démarre ouvert et la touche le ferme ; sans elles, il reste fermé toute la mission.
- Remplace `declare_kneeboard_device.lua` (une ligne ajoutée) : à reconstruire si une mise à jour de DCS modifie ce fichier.
- Ne passe pas l'IC : solo et serveurs qui ne vérifient pas les scripts.

Source et documentation : https://github.com/davidp57/dcs-ifr-curtain
"""


def pristine_kneeboard(dcs: Path) -> str:
    """The DCS kneeboard declaration, without any curtain block left by a dev install."""
    text = (dcs / KNEEBOARD).read_bytes().decode("utf-8")
    return re.sub(rf"(?ms)^[ \t]*-- {MARKER} BEGIN.*?-- {MARKER} END[ \t]*(\r?\n|\Z)", "", text)


def hooked_kneeboard(text: str) -> str:
    nl = "\r\n" if "\r\n" in text else "\n"
    if not text.endswith("\n"):
        text += nl
    return text + f"-- {MARKER} BEGIN{nl}{HOOK}{nl}-- {MARKER} END{nl}"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    version = sys.argv[1]
    dcs = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("C:/jeux/DCS World")
    out_dir = Path(sys.argv[3]) if len(sys.argv) > 3 else REPO / "dist"

    name = f"IFR_Curtain_v{version}"
    out_dir.mkdir(parents=True, exist_ok=True)
    package = out_dir / f"{name}.ozp"

    modpack = (
        "<Open_Mod_Manager_Package>\n"
        f"\t<install>{name}</install>\n"
        f"\t<category>{CATEGORY}</category>\n"
        f"\t<description>{DESCRIPTION}</description>\n"
        "</Open_Mod_Manager_Package>\n"
    )
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("modpack.xml", modpack.encode("utf-8"))
        z.writestr("readme.md", README.encode("utf-8"))
        for f in sorted(MOD.iterdir()):
            if f.is_file():
                z.write(f, f"{name}/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/{f.name}")
        z.writestr(f"{name}/{KNEEBOARD.as_posix()}", hooked_kneeboard(pristine_kneeboard(dcs)).encode("utf-8"))

    print(f"Written: {package}")
    with zipfile.ZipFile(package) as z:
        for n in z.namelist():
            print("  ", n)


if __name__ == "__main__":
    main()
