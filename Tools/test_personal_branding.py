"""Regression tests for build-time display branding and protected provenance."""
import unittest
from personal_branding import personal_catalog

class BrandingTests(unittest.TestCase):
    def test_display_names_and_placeholders(self):
        original = {"strings": {"NOOP received %lld days": {"localizations": {"pt-PT": {"stringUnit": {"value": "NOOP recebeu %lld dias"}}}}}}
        result = personal_catalog(original)
        row = result["strings"]["NOOP received %lld days"]["localizations"]
        self.assertEqual(row["pt-PT"]["stringUnit"]["value"], "WHOOP recebeu %lld dias")
        self.assertEqual(row["en"]["stringUnit"]["value"], "WHOOP received %lld days")
        self.assertNotIn("en", original["strings"]["NOOP received %lld days"]["localizations"])

    def test_technical_and_legal_strings_unchanged(self):
        for key in ["NOOP contributors", "NOOP trademark", "NOOP Terms of Use", "NOOP writes noop_sync.txt", "NOOP https://example.com", "NOOP .noopbak"]:
            original = {"strings": {key: {"localizations": {"en": {"stringUnit": {"value": key}}}}}}
            self.assertEqual(personal_catalog(original), original)

    def test_variants_keep_plural_structure(self):
        original = {"strings": {"NOOP %lld days": {"localizations": {"pt-PT": {"variations": {"plural": {"one": {"stringUnit": {"value": "NOOP %lld dia"}}, "other": {"stringUnit": {"value": "NOOP %lld dias"}}}}}}}}}
        result = personal_catalog(original)
        plural = result["strings"]["NOOP %lld days"]["localizations"]["pt-PT"]["variations"]["plural"]
        self.assertEqual(plural["one"]["stringUnit"]["value"], "WHOOP %lld dia")
        self.assertEqual(plural["other"]["stringUnit"]["value"], "WHOOP %lld dias")

if __name__ == "__main__":
    unittest.main()
