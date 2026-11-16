"""Square-crop a generated 16:9 picture around its subject (512×512 PNG).

Run: python3 tools/square_picture.py <in.png> <out.png>
If the subject is wider than the image is tall, the picture is padded above and
below with the background colour, fading softly so no seam shows.
"""
import sys
import numpy as np
from PIL import Image, ImageChops


def square(src: str, dst: str) -> None:
    im = Image.open(src).convert("RGB")
    bg = Image.new("RGB", im.size, im.getpixel((10, 10)))
    mask = ImageChops.difference(im, bg).convert("L").point(lambda v: 255 if v > 28 else 0)
    l, t, r, b = mask.getbbox() or (0, 0, im.width, im.height)
    h = im.height
    cx = (l + r) // 2
    need = (r - l) + 80
    a = np.array(im).astype(float)
    if need <= h:
        x0 = max(0, min(im.width - h, cx - h // 2))
        sq = a[:, x0:x0 + h]
    else:
        x0 = max(0, cx - need // 2)
        crop = a[:, x0:min(im.width, x0 + need)]
        w = crop.shape[1]
        top = np.median(crop[:30].reshape(-1, 3), axis=0)
        bot = np.median(crop[-30:].reshape(-1, 3), axis=0)
        for i in range(60):
            k = 1 - i / 60
            crop[i] = crop[i] * (1 - k) + top * k
            crop[h - 1 - i] = crop[h - 1 - i] * (1 - k) + bot * k
        pad = (w - h) // 2
        sq = np.zeros((w, w, 3))
        sq[:pad] = top
        sq[pad + h:] = bot
        sq[pad:pad + h] = crop
    Image.fromarray(sq.clip(0, 255).astype(np.uint8)).resize((512, 512), Image.LANCZOS).save(dst, optimize=True)


if __name__ == "__main__":
    square(sys.argv[1], sys.argv[2])
