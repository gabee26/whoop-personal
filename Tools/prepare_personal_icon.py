"""Fetch the user-requested App Store artwork for this private personal iOS build."""
from pathlib import Path
import hashlib
import json
import platform
import re
import struct
import subprocess
import tempfile
from urllib.parse import urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
APP_ID = 933944389
LOOKUP = f"https://itunes.apple.com/lookup?id={APP_ID}&country=pt"
ICON_SETS = ("AppIcon.appiconset", "AppIcon-Navy.appiconset")


def artwork_url(metadata):
    matches = [row for row in metadata.get("results", []) if row.get("trackId") == APP_ID]
    if len(matches) != 1:
        raise ValueError("Expected exactly one matching WHOOP App Store entry")
    url = matches[0].get("artworkUrl512", "")
    parsed = urlparse(url)
    if parsed.scheme != "https" or not (parsed.hostname or "").endswith(".mzstatic.com"):
        raise ValueError("Expected HTTPS artwork hosted by Apple's image CDN")
    return re.sub(r"/\d+x\d+bb\.(jpg|jpeg|png)$", r"/1024x1024bb.\1", url)


def fetch(url, limit):
    request = Request(url, headers={"User-Agent": "Personal-iOS-Build/1.0"})
    with urlopen(request, timeout=45) as response:
        data = response.read(limit + 1)
    if not data or len(data) > limit:
        raise ValueError("Empty or oversized icon response")
    return data


def validate_png(data):
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Icon must be a PNG")
    width, height, depth, color = struct.unpack(">IIBB", data[16:26])
    if (width, height) != (1024, 1024) or depth != 8 or color not in (0, 2):
        raise ValueError("Icon must be opaque, 8-bit, 1024x1024 PNG")


def main():
    if platform.system() != "Darwin":
        raise RuntimeError("Run icon preparation on the macOS iOS build runner")
    metadata = json.loads(fetch(LOOKUP, 2_000_000))
    url = artwork_url(metadata)
    source = fetch(url, 15_000_000)
    with tempfile.TemporaryDirectory(prefix="personal-icon-") as folder:
        source_path = Path(folder) / "source-image"
        opaque_path = Path(folder) / "opaque.jpg"
        output = Path(folder) / "icon.png"
        source_path.write_bytes(source)
        # Native format conversion removes alpha and supplies the required asset dimensions.
        subprocess.run(["/usr/bin/sips", "-s", "format", "jpeg", str(source_path), "--out", str(opaque_path)], check=True, capture_output=True)
        subprocess.run(["/usr/bin/sips", "-s", "format", "png", "-z", "1024", "1024", str(opaque_path), "--out", str(output)], check=True, capture_output=True)
        png = output.read_bytes()
        validate_png(png)
    assets = ROOT / "StrandiOS/Resources/Assets.xcassets"
    for name in ICON_SETS:
        (assets / name / "icon_1024.png").write_bytes(png)
    manifest = {"app_store_id": APP_ID, "lookup_url": LOOKUP, "artwork_url": url,
                "source_sha256": hashlib.sha256(source).hexdigest(),
                "png_sha256": hashlib.sha256(png).hexdigest(), "icon_sets": list(ICON_SETS)}
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    (build / "personal-icon-provenance.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("Prepared both personal iPhone icons from the WHOOP App Store listing.")


if __name__ == "__main__":
    main()
