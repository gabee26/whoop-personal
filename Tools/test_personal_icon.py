"""Offline validation of artwork identity and required iOS icon properties."""
import struct
import unittest
from prepare_personal_icon import APP_ID, artwork_url, validate_png


class PersonalIconTests(unittest.TestCase):
    def test_selects_requested_app_and_full_size(self):
        result = artwork_url({"results": [{"trackId": APP_ID, "artworkUrl512":
            "https://is1-ssl.mzstatic.com/image/thumb/icon/512x512bb.jpg"}]})
        self.assertTrue(result.endswith("/1024x1024bb.jpg"))

    def test_rejects_other_apps_and_hosts(self):
        for rows in [[], [{"trackId": 1}], [{"trackId": APP_ID, "artworkUrl512": "https://example.com/icon.png"}],
                     [{"trackId": APP_ID, "artworkUrl512": "https://mzstatic.com.example.com/icon.png"}]]:
            with self.assertRaises(ValueError):
                artwork_url({"results": rows})

    def header(self, width=1024, color=2):
        return b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + struct.pack(">IIBBBBB", width, 1024, 8, color, 0, 0, 0) + bytes(4)

    def test_accepts_required_opaque_dimensions(self):
        validate_png(self.header())

    def test_rejects_alpha_wrong_size_and_non_png(self):
        for data in [self.header(color=6), self.header(width=512), b"not an image"]:
            with self.assertRaises(ValueError):
                validate_png(data)


if __name__ == "__main__":
    unittest.main()
