#!/usr/bin/env python3
"""Write docs/src/palette.html from colors.toml so the specimen cannot drift."""

import html
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLORS = tomllib.loads((ROOT / "colors.toml").read_text(encoding="utf-8"))
OUT = ROOT / "docs" / "src" / "palette.html"

SECTIONS = [
    (
        "Surfaces",
        [
            ("darker_background", "deeper floor"),
            ("dark_background", "under the bench"),
            ("background", "shop floor"),
            ("lighter_background", "raised iron"),
            ("selection", "selection"),
        ],
    ),
    (
        "Text",
        [
            ("dark_foreground", "muted"),
            ("foreground", "350°F body"),
            ("light_foreground", "lifted straw"),
            ("bright_foreground", "spark"),
        ],
    ),
    (
        "Jewelry",
        [
            ("accent", "590°F temper blue"),
            ("blue", "deep blue"),
            ("cyan", "scale teal"),
            ("bright_cyan", "bright teal"),
        ],
    ),
    (
        "Hot scale",
        [
            ("red", "oxide"),
            ("bright_red", "hot oxide"),
            ("brown", "scale brown"),
            ("orange", "bronze"),
            ("yellow", "pale straw"),
            ("bright_yellow", "hot straw"),
        ],
    ),
    (
        "Cool scale",
        [
            ("green", "greened teal"),
            ("bright_green", "bright green"),
            ("magenta", "violet"),
            ("bright_magenta", "bright violet"),
        ],
    ),
]


def chip(key: str, role: str | None) -> str:
    value = COLORS[key]
    role_html = f'<p class="role">{html.escape(role)}</p>' if role else ""
    return (
        '<article class="card">'
        f'<p class="key">{html.escape(key)}</p>'
        f'<div class="chip" style="background:{html.escape(value)}"></div>'
        f'<p class="hex">{html.escape(value)}</p>'
        f"{role_html}"
        "</article>"
    )


def section(title: str, items: list[tuple[str, str]], columns: int) -> str:
    cards = "\n".join(chip(key, role) for key, role in items)
    return (
        f'<section><h2>{html.escape(title)}</h2>'
        f'<div class="grid" style="grid-template-columns:repeat({columns}, 1fr)">'
        f"{cards}</div></section>"
    )


def ansi_rows() -> str:
    cards = "\n".join(chip(f"color{i}", None) for i in range(16))
    return (
        "<section><h2>ANSI 0–15</h2>"
        '<div class="grid ansi" style="grid-template-columns:repeat(8, 1fr)">'
        f"{cards}</div></section>"
    )


def main() -> None:
    accent = COLORS["accent"]
    parts = [
        section("Surfaces", SECTIONS[0][1], 5),
        section("Text", SECTIONS[1][1], 4),
        section("Jewelry", SECTIONS[2][1], 4),
        section("Hot scale", SECTIONS[3][1], 6),
        section("Cool scale", SECTIONS[4][1], 4),
        ansi_rows(),
    ]
    body = "\n".join(parts)
    document = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Yakiiro palette</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  html, body {{ background: #14131A; }}
  .sheet {{
    width: 1280px;
    background: #14131A;
    color: #E4E0D6;
    padding: 48px 48px 40px;
    font-family: "Noto Sans", "Liberation Sans", sans-serif;
  }}
  header {{ margin-bottom: 28px; }}
  .eyebrow {{
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.42em;
    color: #7A7368;
  }}
  h1 {{
    margin-top: 10px;
    font-family: "Noto Serif", "Liberation Serif", serif;
    font-size: 48px;
    font-weight: 560;
    letter-spacing: 0.06em;
  }}
  .lede {{
    margin-top: 10px;
    max-width: 760px;
    font-family: "Noto Serif", "Liberation Serif", serif;
    font-size: 18px;
    line-height: 1.45;
    color: #C4C1B8;
  }}
  section {{ margin-top: 26px; }}
  h2 {{
    margin-bottom: 12px;
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.28em;
    text-transform: uppercase;
    color: #4A8AB0;
  }}
  .grid {{ display: grid; gap: 14px 12px; }}
  .card {{ min-width: 0; }}
  .key {{
    font-family: "Liberation Mono", monospace;
    font-size: 12px;
    letter-spacing: 0.01em;
    color: #C4C1B8;
    white-space: nowrap;
  }}
  .chip {{
    margin-top: 6px;
    height: 48px;
    border-radius: 3px;
    box-shadow: inset 0 0 0 1px rgba(228, 224, 214, 0.16);
  }}
  .hex {{
    margin-top: 6px;
    font-family: "Liberation Mono", monospace;
    font-size: 13px;
    letter-spacing: 0.04em;
    color: #E4E0D6;
  }}
  .role {{
    margin-top: 2px;
    font-size: 12px;
    color: #7A7368;
  }}
  .ansi .chip {{ height: 36px; }}
  footer {{
    margin-top: 28px;
    padding-top: 16px;
    border-top: 1px solid #221F2A;
    font-family: "Liberation Mono", monospace;
    font-size: 13px;
    line-height: 1.5;
    color: #7A7368;
  }}
  footer b {{ color: #C4B48A; font-weight: 500; }}
  .end {{
    margin-top: 22px;
    height: 4px;
    background: #4A8AB0;
  }}
</style>
</head>
<body>
  <div class="sheet">
    <header>
      <p class="eyebrow">COLORS.TOML</p>
      <h1>Palette</h1>
      <p class="lede">Ground is a near-black shop floor. Accent is 590°F temper blue. Body text is 350°F pale straw. Traffic lights stay inside the scale.</p>
    </header>
    {body}
    <footer>
      accent, cursor, bright_blue, color12, and hyprland_active_border are <b>{html.escape(accent)}</b>.
      mode is dark.
    </footer>
    <div class="end"></div>
  </div>
</body>
</html>
"""
    OUT.write_text(document, encoding="utf-8")
    print(OUT)


if __name__ == "__main__":
    main()
