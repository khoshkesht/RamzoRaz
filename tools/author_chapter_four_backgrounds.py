"""Author the requested background variants, without importing or running the game."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/samples'
BACKGROUNDS = {
    32: 'courtyard_night_lit',
    33: 'winter_room_day',
    36: 'fruit_market_day',
    37: 'room_overhead_background',
    39: 'tea_house_night_lit',
    43: 'kitchen_counter_background_light',
    45: 'calendar_desk_background_light',
    47: 'grid_notebook_background',
    48: 'sheepfold_day',
    50: 'caravanserai_night_lit',
}


def write_svg(name, body, defs='', width=1920, height=1080):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
           f'viewBox="0 0 {width} {height}">\n<defs>{defs}</defs>\n{body}\n</svg>\n')
    (ASSETS / f'{name}.svg').write_text(svg, encoding='utf-8')


def stars():
    return ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#f7e6bc" opacity=".8"/>'
                   for x, y, r in [(180,155,3),(450,230,3),(700,175,2),(1080,210,3),(1410,150,2),(1740,265,3)])


def lantern(x, y):
    return f'''<g transform="translate({x} {y})">
    <ellipse cy="60" rx="135" ry="160" fill="#ffe6a4" opacity=".12"/>
    <path d="M0-60V-20" stroke="#716d62" stroke-width="8"/>
    <rect x="-26" y="-20" width="52" height="82" rx="10" fill="#ffe2a0" stroke="#8a755a" stroke-width="6"/>
    <path d="M-34-22H34M-34 63H34M0-20V62" stroke="#8a755a" stroke-width="6"/>
    </g>'''


def author():
    # New night scenes keep the foreground warm and bright; no baked answer props.
    write_svg('courtyard_night_lit', f'''
    <rect width="1920" height="1080" fill="url(#sky)"/>{stars()}
    <circle cx="1610" cy="185" r="46" fill="#f8edcf"/>
    <path d="M0 370 160 348 160 294H325V370H540V325H770V370H1030V310H1210V370H1470V330H1700V370H1920V790H0Z" fill="#818c99"/>
    <path d="M0 465H1920V760H0Z" fill="#d5bfa0"/>
    <path d="M0 530H1920M0 602H1920M0 674H1920" stroke="#c3aa87" stroke-width="3"/>
    <path d="M0 744H1920V1080H0Z" fill="url(#ground)"/>
    <path d="M0 750H1920" stroke="#b79974" stroke-width="14"/>
    <path d="M0 881H1920M0 1016H1920M330 750 170 1080M1590 750 1750 1080" stroke="#c6b18e" stroke-width="3" opacity=".5"/>
    <g fill="#bca07b" stroke="#a38968" stroke-width="5"><path d="M70 455H150V748H70ZM1770 455H1850V748H1770Z"/></g>
    <path d="M154 705H410V740H154ZM179 740V805M381 740V805" fill="#a68864" stroke="#8c7357" stroke-width="7"/>
    {lantern(110,420)}{lantern(1810,420)}
    ''', '<linearGradient id="sky" x2="0" y2="1"><stop stop-color="#34495f"/><stop offset="1" stop-color="#8499a8"/></linearGradient><linearGradient id="ground" x2="0" y2="1"><stop stop-color="#ead8b5"/><stop offset="1" stop-color="#d5c19d"/></linearGradient>')

    write_svg('winter_room_day', '''
    <rect width="1920" height="1080" fill="url(#wall)"/>
    <path d="M0 300H1920M0 360H1920" stroke="#d6d9ce" stroke-width="3"/>
    <path d="M0 845H1920V1080H0Z" fill="#d4b993"/>
    <path d="M0 844H1920" stroke="#a58f71" stroke-width="15"/>
    <path d="M0 925H1920M0 1010H1920M310 845 220 1080M1600 845 1700 1080" stroke="#bda07d" stroke-width="3"/>
    <path d="M731 378H1189" stroke="#a58b6d" stroke-width="12" stroke-linecap="round"/>
    <path d="M729 390H776L756 700H713ZM1144 390H1191L1208 700H1163Z" fill="#a4b9bb" stroke="#7f9c9e" stroke-width="5"/>
    <rect x="100" y="650" width="210" height="158" rx="14" fill="#e6dfce" stroke="#b7b7a5" stroke-width="5"/>
    <path d="M132 669V788M173 669V788M214 669V788M255 669V788" stroke="#c8c5b4" stroke-width="10"/>
    <rect x="1540" y="390" width="180" height="130" rx="9" fill="#d7bf9d" stroke="#a48c6d" stroke-width="6"/>
    <path d="m1560 495 45-52 38 34 27-20 30 38Z" fill="#b6c7bb"/>
    ''', '<linearGradient id="wall" x2="0" y2="1"><stop stop-color="#eff0e3"/><stop offset="1" stop-color="#e3e2d4"/></linearGradient>')

    snow = '''<rect x="25" y="25" width="310" height="200" fill="#cde3eb"/>
    <path d="M25 154Q100 118 180 155T335 145V225H25Z" fill="#f6f9ef"/>
    <path d="M72 167V73m0 18-18 31h36Zm0 27-27 35h54Z" fill="#abc1bc" stroke="#829f9d" stroke-width="3"/>
    <path d="M278 160V65m0 20-23 33h46Zm0 29-30 38h60Z" fill="#abc1bc" stroke="#829f9d" stroke-width="3"/>
    <g fill="#fffdf1"><circle cx="118" cy="62" r="4"/><circle cx="211" cy="93" r="4"/><circle cx="171" cy="45" r="4"/><circle cx="315" cy="110" r="4"/></g>'''
    frame = '<rect x="10" y="10" width="340" height="230" rx="12" fill="#c19569" stroke="#48575d" stroke-width="5"/>'
    write_svg('window_winter_closed', frame + snow + '''<path d="M180 25V225M25 128H335" stroke="#fff2d8" stroke-width="12"/>
    <path d="m43 43 33-10m-33 26 55-17m212 157-34 10" stroke="#f2faf4" stroke-width="6" opacity=".8"/>''', width=360, height=250)
    write_svg('window_winter_open', frame + snow + '''<path d="m25 25 94 35v126l-94 39Zm310 0-94 35v126l94 39Z" fill="#f4e6ca" stroke="#48575d" stroke-width="5"/>
    <path d="M130 87q49-30 92 0M130 125q49-30 92 0M130 163q49-30 92 0" fill="none" stroke="#6da9bc" stroke-width="5" stroke-linecap="round"/>''', width=360, height=250)

    awning = ''.join(f'<path d="M{x} 230h120l30 160H{x-30}Z" fill="{color}"/>' for x,color in [(i,'#b77965' if (i//120)%2 else '#f1dfb8') for i in range(0,1920,120)])
    write_svg('fruit_market_day', f'''
    <rect width="1920" height="1080" fill="#d9e9e2"/>
    <path d="M0 340H1920V1080H0Z" fill="#e9d8ba"/>
    <path d="M0 425H1920M0 495H1920" stroke="#d6c19c" stroke-width="4"/>
    {awning}<path d="M0 390H1920" stroke="#99785e" stroke-width="10"/>
    <path d="M150 380H195V1080H150ZM1725 380H1770V1080H1725Z" fill="#ad8b66" stroke="#8d765c" stroke-width="5"/>
    <path d="M340 440H1580L1820 1008H100Z" fill="url(#wood)" stroke="#a58764" stroke-width="7"/>
    <path d="M100 1008H1820V1080H100Z" fill="#bc9670"/>
    <path d="M320 705H1600M235 875H1680" stroke="#c6a57d" stroke-width="3" opacity=".6"/>
    <path d="M0 1040H100M1820 1040H1920" stroke="#cbb897" stroke-width="8"/>
    ''', '<linearGradient id="wood" x2="0" y2="1"><stop stop-color="#ead6ad"/><stop offset="1" stop-color="#ddbd8f"/></linearGradient>')

    write_svg('tea_house_night_lit', f'''
    <rect width="1920" height="1080" fill="#eee0c3"/>
    <path d="M0 235H1920V260H0Z" fill="#bd9e6d"/>
    <g stroke="#8c9f91" stroke-width="6">
      <path d="M72 520V340Q72 240 207 240T342 340V520Z" fill="#3e556d"/>
      <path d="M1578 520V340Q1578 240 1713 240T1848 340V520Z" fill="#3e556d"/>
      <path d="M207 250V520M80 392H334M1713 250V520M1586 392H1840"/>
    </g>
    <circle cx="1765" cy="318" r="29" fill="#f9e9b5"/>
    <path d="M0 560H1920V610H0Z" fill="url(#tiles)"/>
    <path d="M0 620H1920V970H0Z" fill="url(#counter)"/>
    <path d="M0 970H1920V1080H0Z" fill="#a8b8a2"/>
    <path d="M0 620H1920M0 970H1920" stroke="#b59b77" stroke-width="12"/>
    <path d="M90 1025H1830" stroke="#8fa58f" stroke-width="3"/>
    {lantern(420,310)}{lantern(1500,310)}
    ''', '<pattern id="tiles" width="64" height="50" patternUnits="userSpaceOnUse"><rect width="64" height="50" fill="#9bb7aa"/><path d="m32 8 20 17-20 17-20-17Z" fill="none" stroke="#dce5cb" stroke-width="3"/></pattern><linearGradient id="counter" x2="0" y2="1"><stop stop-color="#f1e3c5"/><stop offset="1" stop-color="#dfc7a1"/></linearGradient>')

    write_svg('grid_notebook_background', '''
    <rect width="1920" height="1080" fill="#d2bd98"/>
    <path d="M0 250H1920M0 1035H1920" stroke="#bba17c" stroke-width="4"/>
    <rect x="238" y="367" width="1510" height="652" rx="20" fill="#9c8c70" opacity=".16"/>
    <rect x="220" y="349" width="1510" height="652" rx="20" fill="#f7f2df" stroke="#d5c9ac" stroke-width="4"/>
    <path d="M242 400H1710V978H242Z" fill="url(#grid)"/>
    <path d="M354 376V980" stroke="#d5aaa0" stroke-width="3"/>
    <path d="M220 385H1730" stroke="#d6c9ad" stroke-width="4"/>
    <g fill="#e1d4b5" stroke="#a59b83" stroke-width="4">
      <rect x="440" y="325" width="26" height="75" rx="12"/>
      <rect x="1495" y="325" width="26" height="75" rx="12"/>
    </g>
    ''', '<pattern id="grid" width="48" height="48" patternUnits="userSpaceOnUse"><path d="M48 0H0V48" fill="none" stroke="#ccd9ce" stroke-width="1.5"/></pattern>')

    fence = ''.join(f'<path d="M{x} 390v110"/>' for x in range(350,1920,110))
    write_svg('sheepfold_day', f'''
    <rect width="1920" height="1080" fill="#d8ebeb"/>
    <path d="M0 390Q500 250 1000 390T1920 350V1080H0Z" fill="#bfd3a3"/>
    <path d="M0 470Q460 424 960 470T1920 450V1080H0Z" fill="#d7d4ac"/>
    <path d="M0 780Q530 725 1000 800T1920 760V1080H0Z" fill="#c4ca99"/>
    <g fill="none" stroke="#b29770" stroke-width="12" stroke-linecap="round">{fence}<path d="M350 423H1920M350 474H1920"/></g>
    <path d="M40 350 185 248 330 350Z" fill="#bc8d75" stroke="#9d7d63" stroke-width="6"/>
    <path d="M64 350H306V514H64Z" fill="#e3c29a" stroke="#ac916f" stroke-width="5"/>
    <path d="M98 390H270V514H98Z" fill="#a99d80"/>
    <path d="M64 378H306M64 438H98M270 438H306" stroke="#ceb087" stroke-width="3"/>
    <g fill="none" stroke="#a2b17e" stroke-width="4" stroke-linecap="round"><path d="m80 890 9-26 11 27 15-20m1620 52 8-24 11 25 14-18M175 1040l10-28 12 29"/></g>
    ''')

    arches = ''.join(f'<path d="M{x} 482V330Q{x} 225 {x+120} 225T{x+240} 330V482Z" fill="#526779" stroke="#b8a17f" stroke-width="12"/>' for x in [80,460,840,1220,1600])
    write_svg('caravanserai_night_lit', f'''
    <rect width="1920" height="1080" fill="#41566c"/>{stars()}
    <path d="M0 220H1920V535H0Z" fill="#d4bd97"/>
    {arches}<circle cx="1740" cy="300" r="28" fill="#f6e7c2"/>
    <path d="M0 490H1920V1080H0Z" fill="url(#sand)"/>
    <path d="M0 490H1920" stroke="#b59c77" stroke-width="13"/>
    <path d="M0 510H1920" stroke="#f0dfba" stroke-width="5"/>
    <path d="M0 220H1920" stroke="#ae9270" stroke-width="12"/>
    {lantern(372,350)}{lantern(1548,350)}
    <path d="M40 1040h170m1490 0h170" stroke="#ccb68e" stroke-width="3" opacity=".5"/>
    ''', '<linearGradient id="sand" x2="0" y2="1"><stop stop-color="#eee0bd"/><stop offset="1" stop-color="#dfc89f"/></linearGradient>')

    for number, background in BACKGROUNDS.items():
        path = ROOT / f'PuzzleEngine/PuzzleData/{number:03}.json'
        content = path.read_text(encoding='utf-8')
        content = re.sub(r'("background"\s*:\s*")[^"]+', r'\g<1>res://assets/samples/' + background + '.svg', content, count=1)
        if number == 33:
            content = content.replace('res://assets/samples/window_daylight.svg', 'res://assets/samples/window_winter_closed.svg')
            content = content.replace('res://assets/samples/window_open_cold.svg', 'res://assets/samples/window_winter_open.svg')
        path.write_text(content, encoding='utf-8')


if __name__ == '__main__':
    author()
