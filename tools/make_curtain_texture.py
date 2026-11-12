"""Generates the curtain texture: dark crumpled canvas, with no main direction.

One image covers the whole bubble (page.lua projects it on each facet from the side of
the box the facet faces), so it never repeats. It is drawn for METERS meters across, the
size page.lua gives it on the A-10C; other aircraft stretch or shrink it a little.
With no main direction, the lines where a facet's projection changes side hardly show.

Usage: python tools/make_curtain_texture.py [output.tga] [preview.png]
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 1024
METERS = 3.0  # width of the image in meters, on the A-10C
BASE_COLOUR = np.array([62.0, 60.0, 56.0])  # dark warm grey canvas, before shading
SEED = 7


def band_noise(rng, size, wavelength):
    """Smooth noise around one wavelength (pixels): white noise filtered by FFT.

    Normalised to roughly -1..1. Filtering in frequency space treats the image as
    periodic, so the result also wraps around with no seam.
    """
    white = rng.standard_normal((size, size))
    f = np.fft.fftfreq(size)
    radius = np.sqrt(f[None, :] ** 2 + f[:, None] ** 2)
    centre = 1 / wavelength
    band = np.exp(-((radius - centre) / (0.5 * centre)) ** 2)
    n = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
    return n / (2.5 * n.std())


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "mod/Scripts/Aircrafts/_Common/Cockpit/IFR_CURTAIN/curtain.tga")
    preview = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    rng = np.random.default_rng(SEED)
    px_per_m = SIZE / METERS

    # Height of the cloth: ridged noise (sharp creases along the zero lines), from folds of
    # about 35 cm down to small wrinkles of 4 cm.
    height = np.zeros((SIZE, SIZE))
    for metres, weight in ((0.35, 0.6), (0.18, 0.45), (0.09, 0.22), (0.045, 0.08)):
        n = band_noise(rng, SIZE, metres * px_per_m)
        height += weight * (1 - np.abs(n)) ** 2

    # Light from the upper left: shade by the slope of the cloth.
    dx = np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)
    dy = np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)
    slope = (-dx - dy) * px_per_m / 32
    shading = 0.72 + 0.11 * np.tanh(slope)

    # Grain of the canvas (finer than a weave the image could resolve).
    shading += 0.05 * band_noise(rng, SIZE, 3)

    rgb = np.clip(BASE_COLOUR[None, None, :] * shading[:, :, None], 0, 255).astype(np.uint8)
    image = Image.fromarray(rgb, "RGB")
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out)
    print(f"Written: {out} ({SIZE}x{SIZE}, {METERS} m)")

    if preview:
        # Brightened, to check the look.
        Image.fromarray(rgb, "RGB").point(lambda v: min(255, v * 3)).save(preview)
        print(f"Preview: {preview}")


if __name__ == "__main__":
    main()
