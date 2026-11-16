"""Generate the personal iOS build specification without editing upstream sources."""
from pathlib import Path
import hashlib
import json
import re
from personal_branding import personal_catalog

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "com.gabriel.whooppersonal"


def main():
    source = ROOT / "project.yml"
    original = source.read_text(encoding="utf-8")
    version = re.search(r'MARKETING_VERSION: "([^"]+)"', original).group(1)
    build = re.search(r'CURRENT_PROJECT_VERSION: "([^"]+)"', original).group(1)
    generated, schemes = original.replace("$(BUNDLE_ID_PREFIX)", PREFIX).split("\nschemes:", 1)
    # Keep product/module names and source paths intact; only the displayed name changes.
    for target in ("NOOPiOS", "NOOPiOSWidgets", "NOOPWatch", "NOOPWatchComplications"):
        pattern = rf"(?ms)^  {target}:\n.*?(?=^  [A-Za-z][A-Za-z0-9_]*:\n|^schemes:|\Z)"
        matches = list(re.finditer(pattern, generated))
        if len(matches) != 1:
            raise RuntimeError(f"Expected exactly one target block for {target}")
        match = matches[0]
        block = match.group().replace("CFBundleDisplayName: NOOP", "CFBundleDisplayName: WHOOP")
        block = block.replace("CFBundleName: NOOP", "CFBundleName: WHOOP")
        block = block.replace('"NOOP ', '"WHOOP ')
        if target == "NOOPiOS":
            block = block.replace('- "Resources/Info.plist"', '- "Resources/Info.plist"\n          - "Resources/Localizable.xcstrings"', 1)
            block = block.replace("UILaunchScreen: {}", "UILaunchScreen: {UIColorName: PersonalLaunchBackground}")
        block = block.replace("CFBundleURLSchemes: [noop]", "CFBundleURLSchemes: [personal-whoop-personal]")
        generated = generated[:match.start()] + block + generated[match.end():]
    generated += "\nschemes:" + schemes
    catalog = json.loads((ROOT / "Strand/Resources/Localizable.xcstrings").read_text(encoding="utf-8"))
    generated_resources = ROOT / "StrandiOS/Resources/PersonalGenerated"
    generated_resources.mkdir(parents=True, exist_ok=True)
    (generated_resources / "Localizable.xcstrings").write_text(
        json.dumps(personal_catalog(catalog), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    output = ROOT / "project.personal-whoop.generated.yml"
    output.write_text(generated, encoding="utf-8")
    manifest = {
        "name": "WHOOP", "upstream_version": version, "upstream_build": build,
        "upstream_commit": None,
        "source_note": "User-provided main-branch ZIP; exact upstream commit not established.",
        "project_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "bundle_id": PREFIX + ".noop", "widget_bundle_id": PREFIX + ".noop.widgets",
        "app_group": "group." + PREFIX + ".noop.staging",
        "scope": "Personal iOS identity and screenshot-based presentation; upstream BLE, storage and analytics unchanged.",
    }
    (ROOT / "personal-whoop-build-manifest.generated.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
