"""Session 57: draws the made-up logos for every Plaza shop as SVG files in assets/logos/.

Our own art (simple shapes), never a real brand. Each place gets two files:
  <id>_badge.svg  the round picture on its own (for the sign bands, 256 x 256)
  <id>.svg        the badge plus the name in Baloo 2 (for menu boards, cups and bags)
The name is turned into shapes ("paths") with fontTools, so the SVG needs no font.
Run from anywhere:  python3 tools/make_logos.py
"""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/logos'

# id: (name on the logo, brand colour, light colour, picture)
PLACES = {
    'pizza': ('1000 Pizza', '#d7263d', '#ffd166', 'pizza'),
    'gelato': ('Brain Freeze', '#f06fa4', '#fff0f6', 'cone'),
    'boba': ('Spill the Brew', '#6f4e37', '#f3e3d0', 'cup'),
    'shawarma': ('Shawarma Supreme', '#e89b2e', '#fff3d6', 'spit'),
    'bakery': ('Bread & Zaatar', '#a8742f', '#f7e7c6', 'bread'),
    'market': ('Grand Groceries', '#2e9e4f', '#e6f7ea', 'basket'),
    'thai': ('Tok Tok Thai', '#7b3fa0', '#f1e4fa', 'tuktuk'),
    'sushi': ('Sushi You', '#1f3a68', '#e3ebf7', 'sushi'),
    'tacos': ('Mario Bonito', '#ff6f59', '#fff1dc', 'taco'),
    'burger': ('Burgerology', '#e8559a', '#ffe9f3', 'flask'),
    'bikes': ('Pedal Point', '#1e9a9a', '#e0f6f6', 'wheel'),
    'clothes': ('Dune Drip', '#f28c28', '#fff1de', 'sun'),
    'pharmacy': ('Wahat Pharmacy', '#2ba84a', '#e8f8ec', 'cross'),
}

DARK = '#26323a'
WHITE = '#ffffff'


def picture(kind, main, light):
    """The picture inside the badge, drawn on a 256 x 256 square (centre 128, 128)."""
    if kind == 'pizza':  # a pizza slice in a flame
        return f'''<path d="M128 26 C150 66 196 84 190 146 C186 196 156 222 128 226 C100 222 70 196 66 146 C62 98 98 92 104 56 C116 74 120 52 128 26Z" fill="#f4732b"/>
<path d="M92 92 L164 92 L128 206 Z" fill="#f6c453" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M88 84 Q128 70 168 84 L164 98 Q128 86 92 98 Z" fill="#c8813a"/>
<circle cx="116" cy="114" r="9" fill="{main}"/><circle cx="142" cy="122" r="8" fill="{main}"/><circle cx="127" cy="152" r="8" fill="{main}"/>'''
    if kind == 'cone':  # a dripping ice cream cone
        return f'''<path d="M88 118 L168 118 L128 220 Z" fill="#e0a85a" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M100 140 L150 186 M156 140 L110 186 M120 120 L160 160 M136 120 L96 160" stroke="#b97a33" stroke-width="5"/>
<circle cx="128" cy="92" r="50" fill="{light}" stroke="{DARK}" stroke-width="6"/>
<path d="M80 108 Q90 130 100 112 Q108 140 118 114 Q128 132 138 114 Q148 146 158 112 Q168 128 176 106 L176 100 L80 100 Z" fill="{light}"/>
<circle cx="112" cy="78" r="8" fill="{main}"/><circle cx="146" cy="70" r="6" fill="{main}"/>'''
    if kind == 'cup':  # a coffee cup with a splash
        return f'''<path d="M70 104 L186 104 L172 206 Q128 218 84 206 Z" fill="{light}" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M184 124 Q222 126 212 156 Q204 176 178 172" fill="none" stroke="{DARK}" stroke-width="10"/>
<ellipse cx="128" cy="104" rx="58" ry="12" fill="#4a3022"/>
<path d="M96 100 Q100 52 128 60 Q118 30 150 34 Q140 58 166 66 Q160 90 152 100 Z" fill="#8a5a3c"/>
<circle cx="88" cy="58" r="9" fill="#8a5a3c"/><circle cx="178" cy="46" r="7" fill="#8a5a3c"/><circle cx="70" cy="80" r="6" fill="#8a5a3c"/>'''
    if kind == 'spit':  # a shawarma spit with a crown
        return f'''<rect x="124" y="58" width="8" height="170" fill="{DARK}"/>
<path d="M86 84 L170 84 L156 200 L100 200 Z" fill="#9c5a26" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M92 110 L164 110 M96 140 L160 140 M98 170 L158 170" stroke="#c98a4a" stroke-width="7"/>
<path d="M92 72 L92 34 L110 52 L128 26 L146 52 L164 34 L164 72 Z" fill="#ffd34d" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>'''
    if kind == 'bread':  # a flatbread with a zaatar sprig
        return f'''<ellipse cx="128" cy="150" rx="88" ry="50" fill="#e9c27a" stroke="{DARK}" stroke-width="6"/>
<ellipse cx="128" cy="146" rx="64" ry="32" fill="#c99a45"/>
<circle cx="104" cy="140" r="5" fill="#557a2a"/><circle cx="140" cy="154" r="5" fill="#557a2a"/><circle cx="150" cy="134" r="4" fill="#557a2a"/><circle cx="118" cy="160" r="4" fill="#557a2a"/>
<path d="M128 112 Q132 70 150 34" fill="none" stroke="#3f6a1f" stroke-width="6"/>
<ellipse cx="124" cy="80" rx="16" ry="8" fill="#5f9a2c" transform="rotate(-30 124 80)"/><ellipse cx="156" cy="74" rx="16" ry="8" fill="#5f9a2c" transform="rotate(30 156 74)"/>
<ellipse cx="134" cy="54" rx="14" ry="7" fill="#5f9a2c" transform="rotate(-40 134 54)"/><ellipse cx="160" cy="44" rx="12" ry="6" fill="#5f9a2c" transform="rotate(20 160 44)"/>'''
    if kind == 'basket':  # a shopping basket with fruit
        return f'''<circle cx="100" cy="98" r="22" fill="#e94b3c"/><circle cx="140" cy="92" r="20" fill="#f5a623"/><circle cx="164" cy="104" r="16" fill="#7cc242"/>
<path d="M84 110 Q128 30 172 110" fill="none" stroke="{DARK}" stroke-width="9"/>
<path d="M52 112 L204 112 L184 200 L72 200 Z" fill="{light}" stroke="{DARK}" stroke-width="7" stroke-linejoin="round"/>
<path d="M100 120 L104 192 M128 120 L128 192 M156 120 L152 192 M64 146 L192 146 M68 172 L188 172" stroke="{main}" stroke-width="7"/>'''
    if kind == 'tuktuk':  # a tuk-tuk
        return f'''<path d="M58 172 L58 100 Q60 70 96 66 L176 66 Q196 68 198 96 L202 172 Z" fill="{light}" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M48 64 L208 64 L200 44 L56 44 Z" fill="#ffcc33" stroke="{DARK}" stroke-width="6" stroke-linejoin="round"/>
<rect x="76" y="84" width="46" height="40" rx="6" fill="#9fd3f0"/><rect x="134" y="84" width="46" height="40" rx="6" fill="#9fd3f0"/>
<circle cx="84" cy="182" r="22" fill="{DARK}"/><circle cx="84" cy="182" r="9" fill="#cfd8dc"/><circle cx="178" cy="182" r="22" fill="{DARK}"/><circle cx="178" cy="182" r="9" fill="#cfd8dc"/>'''
    if kind == 'sushi':  # a sushi roll
        return f'''<ellipse cx="128" cy="176" rx="80" ry="26" fill="{DARK}"/>
<rect x="48" y="96" width="160" height="80" fill="{DARK}"/>
<ellipse cx="128" cy="96" rx="80" ry="34" fill="#2b2b2b"/>
<ellipse cx="128" cy="96" rx="68" ry="27" fill="{WHITE}"/>
<ellipse cx="128" cy="96" rx="30" ry="12" fill="#ff8a65"/><ellipse cx="102" cy="100" rx="10" ry="6" fill="#7cc242"/><ellipse cx="154" cy="92" rx="10" ry="6" fill="#ffd54f"/>'''
    if kind == 'taco':  # a smiling taco
        return f'''<path d="M40 176 A88 88 0 0 1 216 176 Z" fill="#f6c453" stroke="{DARK}" stroke-width="7" stroke-linejoin="round"/>
<path d="M58 124 Q72 100 90 112 Q104 90 122 104 Q140 86 156 104 Q176 92 190 118" fill="none" stroke="#7cc242" stroke-width="12" stroke-linecap="round"/>
<circle cx="112" cy="142" r="8" fill="{DARK}"/><circle cx="146" cy="142" r="8" fill="{DARK}"/>
<path d="M108 158 Q129 178 150 158" fill="none" stroke="{DARK}" stroke-width="6" stroke-linecap="round"/>
<circle cx="96" cy="158" r="7" fill="{main}"/><circle cx="162" cy="158" r="7" fill="{main}"/>'''
    if kind == 'flask':  # a burger in a lab flask
        return f'''<path d="M106 34 L150 34 L150 88 L204 200 Q208 214 192 214 L64 214 Q48 214 52 200 L106 88 Z" fill="{light}" stroke="{DARK}" stroke-width="7" stroke-linejoin="round"/>
<path d="M84 160 Q128 112 172 160 Z" fill="#e0a04a"/><rect x="76" y="162" width="104" height="12" rx="5" fill="#7cc242"/>
<rect x="78" y="174" width="100" height="16" rx="6" fill="#6b3a1f"/><path d="M80 192 L176 192 Q172 206 128 206 Q84 206 80 192Z" fill="#e0a04a"/>
<circle cx="112" cy="140" r="3" fill="#fff6dc"/><circle cx="134" cy="134" r="3" fill="#fff6dc"/><circle cx="148" cy="146" r="3" fill="#fff6dc"/>'''
    if kind == 'wheel':  # a bike wheel
        spokes = ''.join(f'<line x1="128" y1="128" x2="{128 + 74 * c:.1f}" y2="{128 + 74 * s:.1f}" stroke="{DARK}" stroke-width="4"/>'
                         for c, s in [(1, 0), (0.707, 0.707), (0, 1), (-0.707, 0.707), (-1, 0), (-0.707, -0.707), (0, -1), (0.707, -0.707)])
        return f'''<circle cx="128" cy="128" r="88" fill="none" stroke="{DARK}" stroke-width="18"/>
<circle cx="128" cy="128" r="76" fill="{light}"/>{spokes}
<circle cx="128" cy="128" r="16" fill="{main}" stroke="{DARK}" stroke-width="5"/>'''
    if kind == 'sun':  # a sun in sunglasses
        rays = ''.join(f'<path d="M128 128 L{128 + 100 * c1:.1f} {128 + 100 * s1:.1f} L{128 + 100 * c2:.1f} {128 + 100 * s2:.1f} Z" fill="#ffcc33"/>'
                       for c1, s1, c2, s2 in [(__import__('math').cos(a - 0.14), __import__('math').sin(a - 0.14), __import__('math').cos(a + 0.14), __import__('math').sin(a + 0.14))
                                              for a in [i * 6.2832 / 12 for i in range(12)]])
        return f'''{rays}<circle cx="128" cy="128" r="62" fill="#ffd34d" stroke="{DARK}" stroke-width="6"/>
<path d="M70 112 L186 112 L182 132 Q168 152 146 140 L138 122 L118 122 L110 140 Q88 152 74 132 Z" fill="{DARK}"/>
<path d="M104 164 Q128 184 152 164" fill="none" stroke="{DARK}" stroke-width="7" stroke-linecap="round"/>'''
    if kind == 'cross':  # a pharmacy cross
        return f'''<path d="M100 44 L156 44 L156 100 L212 100 L212 156 L156 156 L156 212 L100 212 L100 156 L44 156 L44 100 L100 100 Z" fill="{main}" stroke="{WHITE}" stroke-width="8"/>'''
    raise ValueError(kind)


def badge(id, size=256, at=(0, 0)):
    name, main, light, kind = PLACES[id]
    x, y = at
    s = size / 256
    return (f'<g transform="translate({x} {y}) scale({s:g})">'
            f'<circle cx="128" cy="128" r="124" fill="{main}"/>'
            f'<circle cx="128" cy="128" r="112" fill="{WHITE}"/>'
            f'<circle cx="128" cy="128" r="104" fill="{light}"/>'
            f'{picture(kind, main, light)}</g>')


def text_path(font, text, x, baseline, height):
    """The text as one SVG path, `height` px per em, starting at x on the baseline."""
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    scale = height / font['head'].unitsPerEm
    pen = SVGPathPen(glyphs)
    cursor = 0.0
    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if glyph_name is None:
            continue
        # Font units go up; SVG goes down, so flip y.
        moved = TransformPen(pen, (scale, 0, 0, -scale, x + cursor * scale, baseline))
        glyphs[glyph_name].draw(moved)
        cursor += font['hmtx'][glyph_name][0]
    return pen.getCommands(), cursor * scale


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    font = instantiateVariableFont(TTFont(ROOT / 'assets/fonts/Baloo2.ttf'), {'wght': 750})
    for id, (name, main, light, kind) in PLACES.items():
        (OUT / f'{id}_badge.svg').write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{badge(id)}</svg>\n')
        # Full logo: badge on the left, the name to the right, on a white rounded card.
        height = 150
        commands, width = text_path(font, name, 0, 0, height)
        while width > 1150 - 300 and height > 60:
            height -= 6
            commands, width = text_path(font, name, 0, 0, height)
        total = int(300 + width + 50)
        commands, width = text_path(font, name, 290, 128 + height * 0.3, height)
        (OUT / f'{id}.svg').write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{total}" height="256" viewBox="0 0 {total} 256">'
            f'<rect x="4" y="4" width="{total - 8}" height="248" rx="124" fill="{WHITE}"/>'
            f'{badge(id, 232, (12, 12))}<path d="{commands}" fill="{main}"/></svg>\n')
    print('Made', len(PLACES) * 2, 'logo files in', OUT)


if __name__ == '__main__':
    main()
