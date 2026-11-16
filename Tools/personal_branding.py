"""Build-only display branding; identifiers, formats and upstream attribution stay intact."""
from copy import deepcopy
import re

PROTECTED = re.compile(r"copyright|polyform|trademark|affiliat|endorse|sponsor|contributor|license|licence|terms|liab|unofficial project|github|https?://|noop[_./]|\.noop|\.txt|\.csv", re.I)


def personal_catalog(catalog):
    result = deepcopy(catalog)
    for key, entry in result.get("strings", {}).items():
        if "NOOP" not in key or PROTECTED.search(key):
            continue
        locales = entry.setdefault("localizations", {})
        locales.setdefault("en", {"stringUnit": {"state": "translated", "value": key}})
        def visit(node):
            if isinstance(node, dict):
                unit = node.get("stringUnit")
                if isinstance(unit, dict) and isinstance(unit.get("value"), str):
                    unit["value"] = re.sub(r"\bNOOP\b", "WHOOP", unit["value"])
                for name, child in node.items():
                    if name != "stringUnit":
                        visit(child)
            elif isinstance(node, list):
                for child in node:
                    visit(child)
        visit(locales)
    return result
