#!/usr/bin/env python3
"""Convert bcbooks/scriptures-json into the compact files bundled with the app.

Usage:
    python3 Scripts/build_scriptures.py <folder with the bcbooks JSON files>

Source: https://github.com/bcbooks/scriptures-json (public domain).
Reads the five volume files and writes one file per volume to
Versed/Resources/Scriptures/. Verse numbers are not stored: verse N is
item N-1 in its chapter's list. Footnotes, chapter summaries, Psalm
superscriptions, and Book of Mormon chapter headings are left out.
"""

import json
import sys
from pathlib import Path

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "Versed" / "Resources" / "Scriptures"

# (source file, volume id, display title)
VOLUMES = [
    ("old-testament.json", "ot", "Old Testament"),
    ("new-testament.json", "nt", "New Testament"),
    ("book-of-mormon.json", "bofm", "Book of Mormon"),
    ("doctrine-and-covenants.json", "dc", "Doctrine and Covenants"),
    ("pearl-of-great-price.json", "pgp", "Pearl of Great Price"),
]


def chapter_texts(chapter):
    verses = chapter["verses"]
    for number, verse in enumerate(verses, start=1):
        if verse["verse"] != number:
            raise ValueError(f"Verse numbers skip at {verse['reference']}")
    return [verse["text"] for verse in verses]


def convert_books(source):
    books = []
    for book in source["books"]:
        books.append({
            "id": book["lds_slug"],
            "name": book["book"],
            "chapters": [chapter_texts(chapter) for chapter in book["chapters"]],
        })
    return books


def convert_doctrine_and_covenants(source):
    # D&C has sections instead of books, so it becomes one book.
    return [{
        "id": "dc",
        "name": "Doctrine and Covenants",
        "shortName": "D&C",
        "chapterLabel": "Section",
        "chapters": [chapter_texts(section) for section in source["sections"]],
    }]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source_dir = Path(sys.argv[1])
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for filename, volume_id, title in VOLUMES:
        source = json.loads((source_dir / filename).read_text(encoding="utf-8"))
        if volume_id == "dc":
            books = convert_doctrine_and_covenants(source)
        else:
            books = convert_books(source)

        volume = {"id": volume_id, "title": title, "books": books}
        output = OUTPUT_DIR / f"{volume_id}.json"
        output.write_text(
            json.dumps(volume, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        verse_count = sum(len(c) for b in books for c in b["chapters"])
        print(f"{output.name}: {len(books)} books, {verse_count} verses")


if __name__ == "__main__":
    main()
