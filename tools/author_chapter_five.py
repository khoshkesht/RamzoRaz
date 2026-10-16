"""Author stages 51–70 and missing vector assets. Does not run/import the game.

Existing sources are reused by path. New silhouettes, connections and scene
backgrounds have independent names; earlier chapter authors are not imported.
"""
import itertools
import json
import random
import subprocess
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/samples'
DATA = ROOT / 'PuzzleEngine/PuzzleData'
P = 'res://assets/samples/'
NEW_ASSETS = set()


def svg(name, body, w=240, h=200):
    NEW_ASSETS.add(P+name+'.svg')
    (ASSETS / (name + '.svg')).write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
        '<g stroke="#48575d" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">'
        + body + '</g></svg>\n', encoding='utf-8')


def var(name, value=True, op='eq'): return dict(type='variable', name=name, operator=op, value=value)
def setv(name, value=True, operation='assign'): return dict(type='set_variable', name=name, value=value, operation=operation)
def inc(name, value=1): return setv(name, value, 'increment')
def act(kind, target, **kw): return dict(type=kind, target=target, **kw)
def show(target): return act('show', target)
def hide(target): return act('hide', target)
def move(target, x, y): return act('move', target, position=[x, y])
def replace(target, sprite): return act('replace_sprite', target, sprite=P+sprite+'.svg')
def anim(target, name): return act('play_animation', target, animation='chapter_five/'+name, wait=False)
def feedback(target): return act('play_animation', target, animation='chapter_two/rattle', wait=False)
FAIL = dict(type='fail_level')


class Level:
    def __init__(self, number, hint, background):
        if background in ['puzzle_workbench_day','puzzle_workbench_night']:
            background=random.Random(5170+number).choice(['puzzle_workbench_day','puzzle_workbench_night'])
        row = next(line.split('|')[1:-1] for line in (ROOT/'docs/100_interactive_persian_puzzles.md').read_text(encoding='utf-8').splitlines() if line.startswith(f'| {number} |'))
        self.d = dict(schema_version=1, id=number, question=row[1].strip(), hint=hint,
                      answer=row[2].strip(), time_limit_seconds=int(row[5]), base_score=int(row[6]),
                      background=P+background+'.svg', success=dict(result_delay_seconds=1),
                      variables=dict(solved=False), objects=[], rules=[], win_condition=var('solved'))
    def variable(self, **kw): self.d['variables'].update(kw)
    def image(self, id, sprite, x, y, inputs=(), **kw):
        self.d['objects'].append(dict(id=id, scene='ClickableObject' if inputs else 'ImageObject', sprite=P+sprite+'.svg', position=[x,y], interactions=list(inputs), **kw))
    def text(self, id, text, x, y, inputs=(), size=(300,70), **kw):
        self.d['objects'].append(dict(id=id, scene='TextObject', text=text.translate(str.maketrans('0123456789','۰۱۲۳۴۵۶۷۸۹')), position=[x,y], hit_size=list(size), text_color='#354f54', interactions=list(inputs), **kw))
    def button(self, id, text, x, y, inputs=('tap',), size=(300,110)):
        self.text(id,text,x,y,inputs,size,sprite=P+'puzzle_tile.svg')
    def drag(self, id, sprite, x, y, extra=(), bounds=(160,460,1600,510), **kw):
        self.image(id,sprite,x,y,[dict(type='drag',bounds=list(bounds),return_on_invalid=True),'drop_on',*extra],z_index=5,**kw)
    def zone(self, id, x, y, sources, size=(230,160)):
        self.d['objects'].append(dict(id=id,scene='DropZone',position=[x,y],hit_size=list(size),accepted_sources=list(sources),z_index=-1))
    def rule(self,event,source,actions,conditions=(),target=None,once=False):
        r=dict(id=f'r{len(self.d["rules"]):04}',event=event,source=source,conditions=list(conditions),actions=list(actions),once=once)
        if target is not None: r['target']=target
        self.d['rules'].append(r)
    def drop(self,source,target,actions,conditions=(),once=False): self.rule('drop_on',source,actions,conditions,target,once)
    def win(self,event,source,actions=(),conditions=(),target=None): self.rule(event,source,[*actions,setv('solved')],conditions,target)
    def note(self,text): self.text('instructions',text,960,430,size=(1550,90))
    def counter(self,label,name,target): self.d.setdefault('counters',[]).append(dict(label=label,variable=name,target=target))
    def save(self): (DATA/f'{self.d["id"]:03}.json').write_text(json.dumps(self.d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def author_assets():
    svg('bridge_lantern_lit','<ellipse cx="120" cy="111" rx="108" ry="87" fill="#ffe39a" opacity=".12" stroke="none"/><ellipse cx="120" cy="111" rx="80" ry="69" fill="#ffe39a" opacity=".18" stroke="none"/><path d="M87 39V25Q120-10 153 25V39" fill="none" stroke="#d4bb7f" stroke-width="9"/><rect x="75" y="36" width="90" height="133" rx="14" fill="#c4a86e"/><path d="M85 52H155V148H85Z" fill="#ffe6a0"/><path d="M120 132Q93 112 121 81Q119 99 134 105Q147 125 120 132Z" fill="#efa24e" stroke="#d58c46" stroke-width="3"/><path d="M88 40V165M152 40V165M72 172H168M104 150H136" fill="none" stroke="#8b7753" stroke-width="7"/>')
    for name,night in [('five_window_room_day',False),('library_room_night',True),('library_room_day',False)]:
        svg(name,f'<rect width="1920" height="1080" fill="{"#a1a9aa" if night else "#e9e2cc"}"/><path d="M0 880H1920V1080H0Z" fill="#c2a681"/><path d="M0 875H1920" stroke="#917e63" stroke-width="14"/>'
            + ('<circle cx="1700" cy="260" r="45" fill="#ffe4a0"/><ellipse cx="960" cy="700" rx="860" ry="330" fill="#ffe6b4" opacity=".15"/>' if night else ''),1920,1080)
    # New workbench and river environments: no answer objects baked into them.
    for name, night in [('puzzle_workbench_day',False),('puzzle_workbench_night',True)]:
        svg(name, f'<rect width="1920" height="1080" fill="{"#86939f" if night else "#e9e3ce"}"/>'
            '<path d="M0 475H1920V1080H0Z" fill="#decca9"/><path d="M0 490H1920M0 1000H1920" stroke="#b29673" stroke-width="16"/>'
            + ('<circle cx="1770" cy="170" r="55" fill="#ffedb2"/><ellipse cx="960" cy="740" rx="900" ry="350" fill="#ffedb2" opacity=".18"/>' if night else ''),1920,1080)
    for name, night, bridge in [('river_crossing_day',False,False),('bridge_crossing_night',True,True)]:
        svg(name,f'<rect width="1920" height="1080" fill="{"#698399" if night else "#c7e4e5"}"/>'
            '<path d="M0 450H1920V1080H0Z" fill="#9fb391"/><path d="M680 440H1240L1380 1080H540Z" fill="#76afbf"/>'
            '<path d="M790 530h240m-300 150h420m-440 180h370m-400 140h510" stroke="#d0e4da" stroke-width="10"/>'
            + ('<path d="M500 650H1420V790H500Z" fill="#b79c77"/><path d="M500 650H1420M500 790H1420" stroke="#756950" stroke-width="15"/>' if bridge else ''),1920,1080)
    svg('wind_arrow','<path d="M20 50h165l-30-24m30 24-30 24M20 106h120m-120 40h170" fill="none" stroke="#779daa" stroke-width="9"/>')
    svg('oil_lamp_unlit','<ellipse cx="120" cy="160" rx="70" ry="30" fill="#b89c6f"/><path d="M80 135V30h80v105" fill="#d3e4de"/><path d="M60 138h120M104 135V109h32v26" fill="none" stroke="#8e7e60" stroke-width="12"/>')
    svg('lantern_unlit','<path d="M80 35V20q40-35 80 0v15" fill="none"/><rect x="60" y="38" width="120" height="140" rx="15" fill="#b4bdb1"/><path d="M80 55h80v98H80Z" fill="#d5e4df"/><path d="M120 55v98M55 178h130" stroke="#80765f" stroke-width="10"/>')
    svg('guard_opaque','<path d="M29 25H151V180Q90 220 29 180Z" fill="#a2b4b9"/><ellipse cx="90" cy="25" rx="61" ry="17" fill="#c2ccca"/>',180,220)
    svg('window_living','<rect x="8" y="8" width="224" height="184" fill="#b48d67"/><rect x="20" y="20" width="200" height="160" fill="#b7e2e5"/><path d="M20 135Q70 95 120 136T220 120V180H20Z" fill="#9eb77b"/><circle cx="184" cy="54" r="22" fill="#ffe8a0"/><path d="M120 25V180M20 98H220" stroke="#f5e7c9" stroke-width="9"/>')
    svg('window_painted','<rect x="8" y="8" width="224" height="184" fill="#b48d67"/><rect x="20" y="20" width="200" height="160" fill="#d3c9b4"/><path d="m30 170 65-75 50 37 42-45 25 83" fill="#a9bbaa"/><path d="M120 25V180M20 98H220" stroke="#f5e7c9" stroke-width="9"/>')
    svg('leaf_pair','<path d="M100 160V40M100 80Q30 20 25 90q45 20 75-10m0 35q60-65 90-10-25 47-90 10" fill="#7ca267"/>',220,180)
    # Edge signatures N/E/S/W are encoded in both geometry and resource report.
    colors=['#ce8573','#7da6b6','#a28bb4','#b89b54']
    for i,edges in enumerate([(0,1,2,3),(0,1,2,3),(1,0,2,3),(0,3,2,1)]):
        paths=['M110 8V110','M212 110H110','M110 212V110','M8 110H110']
        if i==1: paths[3]='M8 110H65M88 110H110'
        svg(f'pattern_tile_{i}','<rect x="5" y="5" width="210" height="210" rx="8" fill="#dfdcc1"/>'+''.join(f'<path d="{path}" fill="none" stroke="{colors[edge]}" stroke-width="16"/>' for path,edge in zip(paths,edges)),220,220)
    svg('tile_surround','<rect x="5" y="5" width="330" height="330" fill="#e4dcc1"/><rect x="60" y="60" width="220" height="220" fill="#7e8c89"/>'+''.join(f'<path d="{path}" stroke="{colors[i]}" stroke-width="16"/>' for i,path in enumerate(['M170 8V60','M280 170H332','M170 280V332','M8 170H60'])),340,340)
    svg('tile_stencil','<path d="M15 15H205V205" fill="none" stroke="#849fa4" stroke-width="15"/>',220,220)
    svg('jug_body_leak','<path d="m34 25-12 22 18 21-16 15" fill="none" stroke="#617e83"/><path d="M39 85q-24 26 0 35 24-9 0-35" fill="#8bbeca"/>',80,140)
    for filled in [False,True]:
        svg('tea_glass_full' if filled else 'tea_glass_empty','<path d="M25 20h110l-12 150H37Z" fill="#dae7df" fill-opacity=".8"/>' + ('<path d="M32 75h96l-7 92H39Z" fill="#b58656"/>' if filled else '')+'<ellipse cx="80" cy="20" rx="55" ry="10" fill="#f0ead8"/>',160,190)
    svg('bookshelf','<rect x="8" y="8" width="264" height="324" fill="#ad8c66"/>'+''.join(f'<path d="M22 {y}h236v12H22Z" fill="#745f4b"/>' for y in [108,212,316])+''.join(f'<rect x="{x}" y="{y}" width="27" height="78" fill="{c}"/>' for y in [25,126,230] for x,c in [(30,'#8baba4'),(65,'#d8b477'),(100,'#b5837b'),(135,'#87a2b3'),(170,'#d8b477'),(205,'#8baba4')]),280,340)
    svg('floor_scrape','<path d="M15 20h220M25 40h210M10 60h225" stroke="#9b8167" stroke-width="7"/>',250,80)
    svg('hidden_door','<path d="M10 10H270V320H10Z" fill="#425e61"/><path d="M45 315V55h190v260" fill="#2b404b"/><circle cx="207" cy="190" r="8" fill="#dfc383"/>',280,340)
    svg('family_grandfather','<path d="M30 190V110Q100 65 170 110v80Z" fill="#b3b8a9"/><circle cx="100" cy="62" r="46" fill="#dfb997"/><path d="M62 70q38 90 76 0" fill="#eee4cf"/><path d="M66 30q34-24 68 0" fill="none" stroke="#eee4cf" stroke-width="16"/>',200,200)
    svg('family_son','<path d="M40 195V125Q100 90 160 125v70Z" fill="#91b6ba"/><circle cx="100" cy="78" r="40" fill="#e4b28c"/><path d="M63 59q35-50 74 0" fill="#685c51"/>',200,200)
    svg('family_link','<path d="M10 50H210l-35-25m35 25-35 25" fill="none" stroke="#739b93" stroke-width="12"/>',220,100)
    svg('brothers_portrait','<rect x="5" y="5" width="230" height="190" fill="#ead9b5"/><path d="M20 180v-60q45-30 90 0v60Zm110 0v-60q45-30 90 0v60Z" fill="#92b0aa"/><circle cx="65" cy="72" r="34" fill="#ddb693"/><circle cx="175" cy="72" r="34" fill="#ddb693"/>')
    svg('library_map_old','<rect x="5" y="5" width="230" height="190" fill="#e0d0aa"/><path d="M30 35h180v130H30Z" fill="none"/><path d="M40 55h45v90H40Z" fill="#b79a70"/><path d="m100 100-40-20m40 20-38 27" fill="none" stroke="#b87c6e" stroke-width="9"/>')
    svg('tea_spoon','<ellipse cx="120" cy="35" rx="27" ry="30" fill="#b9c9c6"/><path d="M120 60v125" stroke="#a0b1ad" stroke-width="13"/>')
    svg('cup_red_label','<path d="M135 49Q180 39 169 99Q165 120 134 117" fill="none" stroke-width="12"/><path d="M19 40H137L126 150Q80 173 31 150Z" fill="#e9c485"/><ellipse cx="78" cy="40" rx="59" ry="15" fill="#fff0d5"/><path d="M45 75h63v35H45Z" fill="#bc7770"/>',180,180)
    svg('fruit_crate','<rect x="8" y="15" width="244" height="160" fill="#bb9a6c"/><path d="M8 55h244M8 115h244M45 15v160M215 15v160" stroke="#8b7357" stroke-width="9"/>',260,190)
    svg('orange_fruit','<circle cx="100" cy="100" r="75" fill="#e7a85e"/><path d="M100 25q10-29 48-14-15 23-48 14" fill="#8fac7a"/>',200,200)
    svg('boat_empty','<path d="M10 30h310l-45 85H55Z" fill="#b59870"/><path d="M85 21 215 139" stroke="#806f55" stroke-width="15"/>',330,150)
    svg('bridge_broken','<path d="M10 45h85l-20 35 25 35H10Zm220 0h-85l20 35-25 35h90Z" fill="#b59870"/><path d="M10 30h75m70 0h75" stroke="#806f55" stroke-width="10"/>')
    svg('wooden_shield','<path d="M35 25Q120 5 205 25v90q-5 45-85 78-80-33-85-78Z" fill="#b59870"/><path d="M90 22v140m60-140v140" stroke="#816d56" stroke-width="8"/>')
    svg('shield_crack','<path d="m120 25-25 45 38 20-24 55 30 35" fill="none" stroke="#63594b" stroke-width="8"/>')
    svg('magnifying_glass','<circle cx="100" cy="78" r="56" fill="#d3e4e2"/><path d="m142 119 60 60" stroke="#997c5b" stroke-width="20"/>')
    svg('wolf','<path d="M20 150 40 65 80 35l30 38h75l32-33-8 70-26 55H55Z" fill="#9faeaa"/><path d="m40 65-3-45 43 15m95 130v25m-104-25v25" fill="#9faeaa"/><circle cx="68" cy="71" r="5" fill="#48575d"/>')
    svg('goat','<path d="M50 150V75h125l35 30-30 55H50Z" fill="#dfd7bf"/><path d="m174 75-5-45m23 49 17-42M70 152v35m90-35v35" fill="none" stroke="#ad9a77" stroke-width="11"/><circle cx="185" cy="103" r="5" fill="#48575d"/>')
    svg('cabbage','<circle cx="120" cy="105" r="80" fill="#a1b783"/><path d="M120 180Q20 60 100 35m20 145q100-120 20-145M45 99q75-55 150 0M70 151q50-45 100 0" fill="none" stroke="#7e9b70" stroke-width="8"/>')
    svg('door_fire','<path d="M25 10h190v185H25Z" fill="#9a7d5d"/><path d="M75 172Q20 115 110 55q-2 50 38 15 75 88-13 102Z" fill="#e8a35f"/>')
    svg('door_killer','<path d="M25 10h190v185H25Z" fill="#9a7d5d"/><path d="m100 55 65 70-25 25-65-70Z" fill="#c4ceca"/><path d="m69 67-22-23" stroke="#78624f" stroke-width="18"/>')
    svg('door_lion','<path d="M25 10h190v185H25Z" fill="#9a7d5d"/><circle cx="120" cy="105" r="65" fill="#b79762"/><ellipse cx="120" cy="114" rx="40" ry="37" fill="#d8bc87"/><path d="m95 105 12 9m-12 0 12-9m26 0 12 9m-12 0 12-9" fill="none"/>')
    svg('sand_upper','<path d="M5 5h90Q85 30 50 45 15 30 5 5Z" fill="#d5b880" stroke="none"/>',100,50)
    svg('sand_lower','<path d="m5 45 45-40 45 40Z" fill="#d5b880" stroke="none"/>',100,50)
    svg('hourglass_clear','<path d="M40 15h160M40 185h160M55 20q0 65 65 80-65 15-65 80h130q0-65-65-80 65-15 65-80Z" fill="#deebe4"/>')
    svg('loose_brick','<rect x="8" y="8" width="224" height="134" rx="8" fill="#b98e72"/><path d="M15 143h210m-180 15h80m22-2h50" stroke="#c1af8e" stroke-width="8"/>',240,170)
    svg('fixed_brick','<rect x="8" y="8" width="224" height="134" rx="8" fill="#b98e72"/>',240,170)
    svg('inverted_book','<rect x="15" y="5" width="90" height="190" fill="#8da6aa"/><path d="M28 180H92M28 20H92" stroke="#dfc58e" stroke-width="8"/><path d="m45 135 15 25 15-25Z" fill="#dfc58e"/>',120,200)
    svg('upright_book','<rect x="15" y="5" width="90" height="190" fill="#8da6aa"/><path d="M28 180H92M28 20H92" stroke="#dfc58e" stroke-width="8"/><path d="m45 65 15-25 15 25Z" fill="#dfc58e"/>',120,200)
    for i, (neck,handle) in enumerate([(50,True),(85,True),(50,False)]):
        svg(f'shadow_jug_{i}',f'<path d="M{120-neck/2} 15h{neck}v48q80 26 65 100-10 30-65 30t-65-30q-15-74 65-100Z" fill="#bca17a"/>' + ('<path d="M183 78q52-8 31 58l-16 8" fill="none" stroke-width="13"/>' if handle else ''))
    svg('jug_shadow_target','<path d="M95 15h50v48q80 26 65 100-10 30-65 30t-65-30q-15-74 65-100Z" fill="#566264"/><path d="M183 78q52-8 31 58l-16 8" fill="none" stroke="#566264" stroke-width="13"/>')
    motif='<path d="m30 5 20 30-20 20-20-20Z" fill="#d7bc7b"/><circle cx="30" cy="34" r="7" fill="#8aaeb1"/>'
    svg('rug_motif',motif,60,60)
    svg('rug_motif_reversed','<g transform="rotate(180 30 30)">'+motif+'</g>',60,60)
    for missing in [False,True]:
        svg('rug_missing' if missing else 'rug_symmetric','<rect x="5" y="5" width="310" height="330" fill="#aa7c76"/><rect x="25" y="25" width="270" height="290" fill="#7d9c9d"/>'+''.join(f'<g transform="translate({x} {y})">{motif}</g>' for x,y in [(55,60),(205,60),(55,210)]+([] if missing else [(205,210)])),320,340)
    # Explicitly crossing paths; intersections carry overpass gaps, not junctions.
    svg('bell_rope_paths','<path d="M100 12C100 100 520 100 520 260S100 340 100 480M500 12C500 100 300 150 300 250S300 360 300 480M300 12C300 95 80 150 80 250S500 360 500 480" fill="none" stroke="#c0a273" stroke-width="14"/><path d="M284 233h32M284 260h32" stroke="#ede0c4" stroke-width="22"/><path d="M300 224v47" stroke="#c0a273" stroke-width="14"/>',600,500)
    svg('rope_pull','<path d="M65 5v120" stroke="#c0a273" stroke-width="14"/><ellipse cx="65" cy="146" rx="32" ry="25" fill="#c0a273"/>',130,180)


    # Floor latch states for the hidden passage in stage 56.
    latch_base='<rect x="12" y="8" width="96" height="124" rx="12" fill="#a4b1a7"/><path d="M60 30V110" stroke="#526b6d" stroke-width="20"/><path d="M60 32V108" stroke="#e2cf97" stroke-width="10"/><circle cx="26" cy="22" r="4" fill="#586d6b"/><circle cx="94" cy="118" r="4" fill="#586d6b"/>'
    svg('floor_latch_closed',latch_base+'<rect x="31" y="32" width="58" height="25" rx="7" fill="#dfbd75"/><path d="m41 79 19 19 19-19" fill="none" stroke="#f1e6c9" stroke-width="7"/>',120,140)
    svg('floor_latch_open',latch_base+'<rect x="31" y="83" width="58" height="25" rx="7" fill="#dfbd75"/>',120,140)
    # Separate glass bowls for stage 54; measuring jugs and earlier assets stay intact.
    glass_base='<defs><clipPath id="bowl"><path d="M70 54C30 100 20 165 40 218C57 270 107 291 160 291C213 291 263 270 280 218C300 165 290 100 250 54Z"/></clipPath></defs><ellipse cx="160" cy="291" rx="73" ry="10" fill="#5b7476" opacity=".18" stroke="none"/><path d="M70 54C30 100 20 165 40 218C57 270 107 291 160 291C213 291 263 270 280 218C300 165 290 100 250 54Z" fill="#d5eff0" fill-opacity=".2" stroke="#668b8d" stroke-width="5"/>'
    glass_water='<g clip-path="url(#bowl)" stroke="none"><path d="M20 104H300V300H20Z" fill="#72bed4" fill-opacity=".9"/><ellipse cx="160" cy="104" rx="121" ry="15" fill="#b4e4ec"/><path d="M39 104Q160 132 281 104" fill="none" stroke="#e0f6f4" stroke-width="3"/></g>'
    glass_finish='<path d="M70 54C30 100 20 165 40 218C57 270 107 291 160 291C213 291 263 270 280 218C300 165 290 100 250 54Z" fill="none" stroke="#668b8d" stroke-width="5"/><ellipse cx="160" cy="54" rx="90" ry="17" fill="#d4e9e4" fill-opacity=".35" stroke="#668b8d" stroke-width="5"/><ellipse cx="160" cy="54" rx="76" ry="9" fill="none" stroke="#effaf3" stroke-width="3"/><path d="M71 98Q41 158 61 207" fill="none" stroke="#f4fff9" stroke-width="12" opacity=".8"/><path d="M79 229Q108 261 146 264M253 112Q268 155 259 188" fill="none" stroke="#e7f8f1" stroke-width="6" opacity=".65"/><path d="M116 284Q160 293 204 284" fill="none" stroke="#aacaca" stroke-width="7"/>'
    for full in [False,True]:
        svg('glass_bowl_'+('full' if full else 'empty'),glass_base+(glass_water if full else '')+glass_finish,320,320)


def author_animations():
    (ASSETS/'bridge_lantern_feedback.tres').write_text("[gd_resource type=\"AnimationLibrary\" load_steps=5 format=3]\n\n[sub_resource type=\"Animation\" id=\"walk_right\"]\nresource_name = \"walk_right\"\nlength = 0.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.899, 0.9),\n\"transitions\": PackedFloat32Array(1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(1155.5555555555554, 0), Vector2(0, 0)]\n}\n\n[sub_resource type=\"Animation\" id=\"walk_left\"]\nresource_name = \"walk_left\"\nlength = 0.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.899, 0.9),\n\"transitions\": PackedFloat32Array(1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(-1155.5555555555554, 0), Vector2(0, 0)]\n}\n\n[sub_resource type=\"Animation\" id=\"lamp_right\"]\nresource_name = \"lamp_right\"\nlength = 0.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.899, 0.9),\n\"transitions\": PackedFloat32Array(1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(945.4545454545454, 0), Vector2(0, 0)]\n}\n\n[sub_resource type=\"Animation\" id=\"lamp_left\"]\nresource_name = \"lamp_left\"\nlength = 0.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.899, 0.9),\n\"transitions\": PackedFloat32Array(1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(-945.4545454545454, 0), Vector2(0, 0)]\n}\n\n[resource]\n_data = {\n\"walk_right\": SubResource(\"walk_right\"),\n\"walk_left\": SubResource(\"walk_left\"),\n\"lamp_right\": SubResource(\"lamp_right\"),\n\"lamp_left\": SubResource(\"lamp_left\")\n}\n",encoding='utf-8')
    (ASSETS/'cup_challenge_feedback.tres').write_text("[gd_resource type=\"AnimationLibrary\" load_steps=4 format=3]\n\n[sub_resource type=\"Animation\" id=\"shuffle_a\"]\nresource_name = \"shuffle_a\"\nlength = 2.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.29, 0.58, 0.87, 1.16, 1.45, 1.74, 2.03, 2.32, 2.61, 2.899, 2.9),\n\"transitions\": PackedFloat32Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(200, -105), Vector2(400, 0), Vector2(600, -105), Vector2(800, 0), Vector2(400, 105), Vector2(0, 0), Vector2(200, -105), Vector2(400, 0), Vector2(600, -105), Vector2(800, 0), Vector2(0, 0)]\n}\n\n[sub_resource type=\"Animation\" id=\"shuffle_b\"]\nresource_name = \"shuffle_b\"\nlength = 2.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.29, 0.58, 0.87, 1.16, 1.45, 1.74, 2.03, 2.32, 2.61, 2.899, 2.9),\n\"transitions\": PackedFloat32Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(-200, 105), Vector2(-400, 0), Vector2(-400, 0), Vector2(-400, 0), Vector2(0, -105), Vector2(400, 0), Vector2(400, 0), Vector2(400, 0), Vector2(200, 105), Vector2(0, 0), Vector2(0, 0)]\n}\n\n[sub_resource type=\"Animation\" id=\"shuffle_c\"]\nresource_name = \"shuffle_c\"\nlength = 2.9\ntracks/0/type = \"value\"\ntracks/0/path = NodePath(\"Sprite:position\")\ntracks/0/interp = 1\ntracks/0/keys = {\n\"times\": PackedFloat32Array(0, 0.29, 0.58, 0.87, 1.16, 1.45, 1.74, 2.03, 2.32, 2.61, 2.899, 2.9),\n\"transitions\": PackedFloat32Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),\n\"update\": 0,\n\"values\": [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(-200, 105), Vector2(-400, 0), Vector2(-400, 0), Vector2(-400, 0), Vector2(-600, 105), Vector2(-800, 0), Vector2(-800, 0), Vector2(-800, 0), Vector2(0, 0)]\n}\n\n[resource]\n_data = {\n\"shuffle_a\": SubResource(\"shuffle_a\"),\n\"shuffle_b\": SubResource(\"shuffle_b\"),\n\"shuffle_c\": SubResource(\"shuffle_c\")\n}\n",encoding='utf-8')
    # All animations run through ActionRunner's pause/cancel/run guard.
    animations = {
        'wind': (10, 'Sprite:rotation', [0,10], [0.,0.]),
        'leaves': (1.4, 'Sprite:rotation', [0,.7,1.4], [-.12,.12,-.12]),
        'shuffle_a': (2., 'Sprite:position', [0,1,1.999,2.], ['Vector2(0, 0)','Vector2(400, -50)','Vector2(800, 0)','Vector2(0, 0)']),
        'shuffle_b': (2., 'Sprite:position', [0,1,1.999,2.], ['Vector2(0, 0)','Vector2(-400, 50)','Vector2(-400, 0)','Vector2(0, 0)']),
        'shuffle_c': (2., 'Sprite:position', [0,1,1.999,2.], ['Vector2(0, 0)','Vector2(0, 0)','Vector2(-400, 0)','Vector2(0, 0)']),
    }
    text=f'[gd_resource type="AnimationLibrary" load_steps={len(animations)+1} format=3]\n'
    for name,(duration,path,times,values) in animations.items():
        text+=f'\n[sub_resource type="Animation" id="{name}"]\nresource_name = "{name}"\nlength = {duration}\n'
        if name=='leaves': text+='loop_mode = 1\n'
        text+=f'tracks/0/type = "value"\ntracks/0/path = NodePath("{path}")\ntracks/0/interp = 1\ntracks/0/keys = {{\n"times": PackedFloat32Array('+', '.join(map(str,times))+'),\n"transitions": PackedFloat32Array('+', '.join('1' for _ in times)+'),\n"update": 0,\n"values": ['+', '.join(map(str,values))+']\n}\n'
    text+='\n[resource]\n_data = {\n'+',\n'.join(f'"{n}": SubResource("{n}")' for n in animations)+'\n}\n'
    (ASSETS/'chapter_five_feedback.tres').write_text(text,encoding='utf-8')


def author_simple_levels():
    l=Level(51,'فقط شمع روشن است؛ محافظ شفاف را پیش از ده ثانیه روی شعله بگذار.','courtyard_night_lit')
    l.image('lamp','oil_lamp_unlit',520,650); l.image('lantern','lantern_unlit',1400,650)
    l.image('candle','candle_body',960,720); l.image('flame','candle_flame',960,590)
    l.image('wind','wind_arrow',950,490)
    l.drag('guard','glass_wind_guard',500,880); l.zone('candle_zone',960,640,['guard'],(210,230))
    l.drag('opaque','guard_opaque',1450,880); l.zone('lantern_zone',1400,650,['opaque'])
    l.image('vane','wind_arrow',1700,590,[dict(type='swipe',direction='down')],scale=[.65,.65])
    l.note('شعله تا ده ثانیه دیگر خاموش می‌شود؛ محافظ را جابه‌جا کن.')
    l.rule('level_started','$level',[anim('wind','wind')])
    l.rule('custom:animation_finished','wind',[hide('flame'),FAIL])
    l.drop('opaque','lantern_zone',[move('opaque',1400,650)])
    l.rule('swipe','vane',[act('rotate','vane',degrees=90)])
    l.win('drop_on','guard',[move('guard',960,640)],target='candle_zone'); l.save()

    l=Level(52,'پرده را کنار بزن؛ برگ‌های پنجرهٔ سمت راست زنده حرکت می‌کنند.','five_window_room_day')
    l.note('پرده‌ها را به کنار بکش، سپس پنجرهٔ واقعی را لمس کن.')
    for i in range(5):
        x=[340,650,1580,1270,960][i]; l.variable(**{f'open_{i}':False})
        l.image(f'window_{i}','window_living' if i==2 else 'window_painted',x,650,['tap'])
        if i==2: l.image('leaves','leaf_pair',x,650,scale=[.55,.55],visible=False)
        l.image(f'curtain_{i}','curtains_closed',x,650,['swipe'],scale=[.65,.65],z_index=2)
        l.rule('swipe',f'curtain_{i}',[hide(f'curtain_{i}'),setv(f'open_{i}'),*([show('leaves'),anim('leaves','leaves')] if i==2 else [])])
        if i==2: l.win('tap',f'window_{i}',conditions=[var('open_2')])
        else: l.rule('tap',f'window_{i}',[feedback(f'window_{i}')])
    l.image('yellow_light','lamp_off',450,900,['tap'],scale=[.6,.6]); l.rule('tap','yellow_light',[replace('yellow_light','lamp_on')])
    l.image('photo','window_painted',1450,900,['hold'],scale=[.65,.65]); l.rule('hold','photo',[act('scale','photo',value=[.75,.75])]); l.save()

    l=Level(53,'ادامهٔ چهار خط رنگی را با چهار لبهٔ قطعه تطبیق بده.','puzzle_workbench_day')
    l.image('frame','tile_surround',960,620); l.zone('gap',960,620,[f'tile_{i}' for i in range(4)],(225,225))
    for i,x in enumerate([390,770,1150,1530]):
        l.drag(f'tile_{i}',f'pattern_tile_{i}',x,900,scale=[.75,.75])
        if i==0: l.win('drop_on','tile_0',[move('tile_0',960,620),act('scale','tile_0',value=[1,1])],target='gap')
        else: l.drop(f'tile_{i}','gap',[move(f'tile_{i}',x,900),feedback('frame')])
    l.image('stencil','tile_stencil',1500,590,['hold'],scale=[.7,.7]); l.rule('hold','stencil',[feedback('stencil')]); l.save()

    l=Level(54,'پارچ آبِ سمت چپ را روی هر سه تنگ بکش و رها کن؛ آب آبی و نوشتهٔ «پر شد» پر شدن را نشان می‌دهند. سپس انگشتت را روی خودِ دکمهٔ «آزمایش نشتی» پایین صفحه، ۳ ثانیه بدون رها کردن نگه دار. بعد از ظاهر شدن ترک و قطره از بدنهٔ تنگ میانی، همان تنگ را لمس کن.','puzzle_workbench_night')
    l.variable(tested=False)
    l.drag('water','water_jug',300,850,scale=[.65,.65])
    l.text('water_label','پارچ آب؛ بکش و بریز',300,965,size=(430,70))
    for i,x in enumerate([600,960,1320]):
        l.variable(**{f'filled_{i}':False})
        l.image(f'jug_{i}','glass_bowl_empty',x,650,['tap'],scale=[.8,.8])
        l.zone(f'fill_{i}',x,650,['water'])
        l.drop('water',f'fill_{i}',[move('water',300,850),replace(f'jug_{i}','glass_bowl_full'),setv(f'filled_{i}'),hide(f'empty_{i}'),show(f'water_{i}')])
        l.text(f'empty_{i}','خالی',x,815,size=(300,60))
        l.text(f'water_{i}','پر شد',x,815,size=(300,60),visible=False)
    l.image('leak','jug_body_leak',1050,730,visible=False,scale=[.65,.65])
    l.image('test_frame','puzzle_tile',960,930,scale=[2.25,1.25],z_index=-1)
    l.text('test','آزمایش نشتی\nاینجا را ۳ ثانیه نگه دار',960,930,[dict(type='hold',duration=3.)],size=(620,110))
    l.rule('hold','test',[setv('tested'),show('leak')],[var(f'filled_{i}') for i in range(3)])
    l.win('tap','jug_1',conditions=[var('tested')])
    for i in [0,2]: l.rule('tap',f'jug_{i}',[feedback(f'jug_{i}')])
    l.drag('cloth','towel_wet',1600,850,scale=[.5,.5]); l.zone('floor',650,790,['cloth']); l.image('puddle','water_drops',650,790,visible=False)
    l.drop('cloth','floor',[move('cloth',1600,850),show('puddle')])
    l.image('cap','bottle_cap',1600,550,['tap']); l.image('mouth_drop','water_drops',1380,580,visible=False,scale=[.4,.4]); l.rule('tap','cap',[show('mouth_drop')]); l.save()

    l=Level(55,'سه نسل داریم؛ فرد میانی هم پسرِ پدربزرگ است و هم پدرِ پسر.','family_picnic_background')
    for i,(x,sprite,label) in enumerate([(560,'family_grandfather','پدربزرگ'),(960,'man','پدر'),(1360,'family_son','پسر')]):
        l.image(f'person_{i}',sprite,x,650,scale=[.7,.7] if i==1 else [1,1]); l.text(f'name_{i}',label,x,790)
        l.drag(f'hat_{i}','hat',470+i*430,950,scale=[.55,.55]); l.zone(f'head_{i}',x,535,[f'hat_{j}' for j in range(4)],(200,100))
        l.variable(**{f'hatted_{i}':False})
        for j in range(3): l.drop(f'hat_{j}',f'head_{i}',[move(f'hat_{j}',x,535),hide(f'hat_{j}'),show(f'worn_{i}'),setv(f'hatted_{i}')],[var(f'hatted_{i}',False)])
        l.image(f'worn_{i}','hat',x,535,visible=False,scale=[.55,.55])
    for i,x in enumerate([760,1160]):
        l.drag(f'link_{i}','family_link',x,860,scale=[.7,.7]); l.zone(f'relation_{i}',x,650,[f'link_{i}'],(160,170)); l.variable(**{f'linked_{i}':False})
        l.drop(f'link_{i}',f'relation_{i}',[move(f'link_{i}',x,650),hide(f'link_{i}'),show(f'connected_{i}'),setv(f'linked_{i}')])
        l.image(f'connected_{i}','family_link',x,650,visible=False,scale=[.7,.7]); l.text(f'role_{i}','پدر ← پسر',x,565,size=(220,60))
    l.drag('hat_3','hat',1660,900,scale=[.5,.5]); l.zone('empty_person',1650,650,['hat_3']); l.drop('hat_3','empty_person',[move('hat_3',1660,900),feedback('hat_3')])
    l.image('brothers','brothers_portrait',290,620,['hold'],scale=[.6,.6]); l.text('brothers_label','دو برادر',290,750); l.rule('hold','brothers',[feedback('brothers')])
    l.win('variable_changed','$level',conditions=[*[var(f'hatted_{i}') for i in range(3)],var('linked_0'),var('linked_1')]); l.save()

    l=Level(56,'لبهٔ قالیچهٔ جلوی قفسهٔ راست را به چپ بکش تا رد ساییدگی و ضامن کف آشکار شوند. ضامن را به پایین بکش تا قفسه آزاد شود. سپس قفسهٔ راست را تا انتهای رد به راست بکش و ورودی آشکارشده را لمس کن. نقشهٔ قدیمی، وضعیت امروز اتاق را نشان نمی‌دهد.','library_room_night')
    l.variable(unlocked=False,opened=False)
    l.image('door','hidden_door',1250,650,['tap'],visible=False,z_index=-3)
    l.image('scrape','floor_scrape',1320,900,visible=False,z_index=-2)
    l.image('latch','floor_latch_closed',1120,900,[dict(type='swipe',direction='down')],visible=False,hit_size=[150,150])
    l.image('rug','rug_symmetric',1250,900,[dict(type='swipe',direction='left')],scale=[1.8,.4],z_index=6)
    l.rule('swipe','rug',[move('rug',850,950),act('scale','rug',value=[.5,.3]),show('latch'),show('scrape')],once=True)
    l.rule('swipe','latch',[setv('unlocked'),replace('latch','floor_latch_open'),hide('jammed')],once=True)
    l.text('jammed','قفسه به کف گیر دارد؛ اول ضامنش را پیدا کن.',960,380,size=(1500,80),visible=False)
    l.drag('shelf_left','bookshelf',600,650,bounds=(350,520,400,260))
    l.image('shelf_right','bookshelf',1250,650,[dict(type='drag',axis='x',bounds=[1050,650,540,1],return_on_invalid=False)],z_index=5)
    l.zone('slide_end',1590,650,[],(120,340))
    l.rule('drag_end','shelf_right',[move('shelf_right',1250,650),show('jammed')],[var('unlocked',False)])
    at_end=dict(type='inside',target='shelf_right',zone='slide_end')
    l.rule('drag_end','shelf_right',[move('shelf_right',1250,650)],[var('unlocked'),var('opened',False),dict(type='not',condition=at_end)])
    l.rule('drag_end','shelf_right',[move('shelf_right',1590,650),show('door'),setv('opened')],[var('unlocked'),var('opened',False),at_end])
    l.rule('drag_end','shelf_right',[move('shelf_right',1590,650)],[var('opened')])
    l.win('tap','door',conditions=[var('opened'),var('unlocked')])
    l.rule('drag_end','shelf_left',[move('shelf_left',600,650)])
    l.drag('chest','chest_closed',320,900,scale=[.55,.55]); l.rule('drag_end','chest',[move('chest',320,900)])
    l.image('old_map','library_map_old',1630,900,[dict(type='swipe',direction='up')],scale=[.6,.6]); l.rule('swipe','old_map',[act('scale','old_map',value=[.85,.85])]); l.save()

    l=Level(57,'استکان دوم را روی پنجم ببر تا چای بریزد و بدنه به جای قبلی برگردد.','tea_house_night_lit')
    l.variable(lifts=0); l.counter('برداشتن استکان','lifts',1)
    l.note('شش استکان از چپ به راست؛ تنها یک استکان را می‌توانی برداری.')
    for i in range(6):
        x=350+i*240
        l.drag(f'glass_{i}','tea_glass_full' if i<3 else 'tea_glass_empty',x,650)
        l.zone(f'glass_zone_{i}',x,650,[f'glass_{j}' for j in range(6) if j!=i],(160,190))
        l.text(f'index_{i}',str(i+1),x,800)
        l.rule('drag_start',f'glass_{i}',[inc('lifts')])
        l.rule('drag_start',f'glass_{i}',[FAIL],[var('lifts',1,'gt')])
        for j in range(6):
            if j==i: continue
            if i==1 and j==4:
                l.win('drop_on','glass_1',[move('glass_1',590,650),replace('glass_1','tea_glass_empty'),replace('glass_4','tea_glass_full')],[var('lifts',1)],f'glass_zone_{j}')
            else: l.drop(f'glass_{i}',f'glass_zone_{j}',[move(f'glass_{i}',x,650),FAIL])
    l.drag('coaster','puzzle_tile',520,950,scale=[.5,.5]); l.d['objects'][-1].update(scene='TextObject',text='۲',text_color='#354f54',hit_size=[280,110])
    l.zone('coaster_zone',1110,850,['coaster']); l.drop('coaster','coaster_zone',[move('coaster',1110,850)])
    l.drag('spoon','tea_spoon',1450,950,scale=[.6,.6]); l.zone('spoon_zone',590,650,['spoon'],(160,190)); l.drop('spoon','spoon_zone',[move('spoon',1450,950),feedback('glass_1')]); l.save()

    author_bridge()
    author_boxes()
    author_coins()
    author_river()
    author_hourglasses()
    author_remaining()


def author_bridge():
    l=Level(58,'پل تاریک است؛ هر بار یک یا دو نفر باید چراغ را همراه ببرند. فقط افرادِ سمت چراغ می‌توانند عبور کنند و تا وقتی کسی جا مانده، یک نفر باید چراغ را برگرداند. زمان هر عبور برابر زمان نفر کندتر است. راه حل: ۱ و ۲ بروند، ۱ با چراغ برگردد، ۷ و ۱۰ بروند، ۲ با چراغ برگردد، سپس ۱ و ۲ بروند؛ مجموع ۱۷ دقیقه.','bridge_crossing_night')
    l.variable(bank=0,people=0,aboard=0,selection=0,minutes=0,transition=False,crossing=False)
    l.counter('دقیقهٔ شبیه‌سازی','minutes',17)
    times=[1,2,7,10]
    for slot,x in enumerate([850,1070]):
        l.image(f'slot_{slot}','puzzle_tile',x,650,scale=[.65,1.9],z_index=-1)
    for i in range(4):
        l.image(f'person_{i}','walking_person',370,500+i*145,['tap'],scale=[.45,.45],hit_size=[280,300],z_index=5)
        l.text(f'time_{i}',str(times[i])+' دقیقه',225,500+i*145,['tap'],size=(180,70))
        l.image(f'selected_{i}','selection_check',905,600,visible=False,scale=[.6,.6],z_index=6)
    l.image('lamp','bridge_lantern_lit',520,730,scale=[.55,.55],z_index=7)
    l.image('cross_frame','puzzle_tile',960,930,scale=[1.5,1.18],z_index=-1)
    l.text('cross_idle','عبور',960,930,size=(420,130))
    l.d['objects'][-1]['text_color']='#78807a'
    l.text('cross','عبور',960,930,['tap'],size=(420,130),visible=False)
    l.image('direction','left_arrow',1100,930,rotation_degrees=180,scale=[.4,.4],visible=False)
    for cost in times:
        l.text(f'cost_{cost}',str(cost)+' دقیقه',960,835,size=(500,60),visible=False)
    # One tap toggles a traveller; a latch prevents matching another state on that tap.
    for bank,mask,selection in itertools.product(range(2),range(16),range(16)):
        selected=[i for i in range(4) if selection>>i&1]
        if len(selected)>2 or any((mask>>i&1)!=bank for i in selected): continue
        cond=[var('bank',bank),var('people',mask),var('selection',selection)]
        for i in range(4):
            if (mask>>i&1)!=bank or (i not in selected and len(selected)==2): continue
            next_selection=selection^(1<<i)
            actions=[setv('selection',next_selection),setv('aboard',next_selection.bit_count()),setv('transition')]
            for source in [f'person_{i}',f'time_{i}']:
                l.rule('tap',source,actions,[*cond,var('transition',False),var('crossing',False)])
        if selected:
            dest=1-bank
            direction='left' if bank else 'right'
            crossing=[setv('transition'),setv('crossing'),hide('cross'),hide('cross_idle'),hide('cross_frame'),hide('direction'),*[hide(f'cost_{cost}') for cost in times]]
            for slot,i in enumerate(selected):
                crossing += [move(f'person_{i}',1270-slot*200 if bank else 650+slot*200,690),hide(f'time_{i}'),hide(f'selected_{i}'),act('play_animation',f'person_{i}',animation='bridge_lantern/walk_'+direction,wait=False)]
            crossing += [move('lamp',1170 if bank else 750,730),act('play_animation','lamp',animation='bridge_lantern/lamp_'+direction,wait=False)]
            l.rule('tap','cross',crossing,[*cond,var('transition',False),var('crossing',False)])
            l.rule('custom:animation_finished','lamp',[setv('transition'),setv('people',mask^selection),setv('bank',dest),setv('selection',0),setv('aboard',0),inc('minutes',max(times[i] for i in selected)),setv('crossing',False)],[*cond,var('transition',False),var('crossing'),dict(type='event_value',field='animation',operator='eq',value='bridge_lantern/lamp_'+direction)])
    l.rule('tap','$level',[setv('transition',False)])
    l.d['rules'][-1].pop('source')
    l.rule('custom:animation_finished','lamp',[setv('transition',False)])
    # Refresh independent pieces without duplicating every combination of banks.
    def refresh(actions,conditions):
        l.rule('tap','$level',actions,[*conditions,var('crossing',False)])
        l.d['rules'][-1].pop('source')
        l.rule('custom:animation_finished','lamp',actions,[*conditions,var('crossing',False)])
    for bank in range(2):
        refresh([move('lamp',1400 if bank else 520,730),act('rotate','direction',degrees=0 if bank else 180)],[var('bank',bank)])
    for selection in range(16):
        selected=[i for i in range(4) if selection>>i&1]
        if len(selected)>2: continue
        view=[show('cross'),hide('cross_idle'),show('direction')] if selected else [hide('cross'),show('cross_idle'),hide('direction')]
        for cost in times: view.append(show(f'cost_{cost}') if selected and cost==max(times[i] for i in selected) else hide(f'cost_{cost}'))
        for i in range(4):
            if i in selected:
                x=850+selected.index(i)*220
                view += [move(f'person_{i}',x,650),move(f'time_{i}',x,760),move(f'selected_{i}',x+55,600),show(f'selected_{i}')]
            else: view.append(hide(f'selected_{i}'))
        view=[show('cross_frame'),*[show(f'time_{i}') for i in range(4)],*view]
        if selected: view.append(move('lamp',960,690))
        refresh(view,[var('selection',selection)])
    for i in range(4):
        unselected=dict(type='any',conditions=[var('selection',n) for n in range(16) if n.bit_count()<=2 and not (n>>i&1)])
        for right in range(2):
            side=dict(type='any',conditions=[var('people',mask) for mask in range(16) if (mask>>i&1)==right])
            refresh([move(f'person_{i}',1550 if right else 370,500+i*145),move(f'time_{i}',1700 if right else 225,500+i*145)],[side,unselected])
    l.win('variable_changed','$level',conditions=[var('people',15),var('minutes',17)])
    l.rule('variable_changed','$level',[FAIL],[var('minutes',17,'gt')])
    l.save()


def author_boxes():
    l=Level(59,'همهٔ برچسب‌ها غلط‌اند؛ پس جعبهٔ «مخلوط» نمی‌تواند مخلوط باشد و فقط یک نوع میوه دارد.\n۱. پیش از جابه‌جایی برچسب‌ها، جعبهٔ «مخلوط» در سمت راست را لمس کن؛ سیب بیرون می‌آید، پس این جعبه فقط سیب دارد.\n۲. برچسب «سیب» را روی جعبهٔ سمت راست بکش و رها کن.\n۳. برچسب «مخلوط» را روی جعبهٔ وسط بگذار: این جعبه ابتدا «پرتقال» نوشته بود، پس پرتقال نیست؛ سیب هم در جعبهٔ راست است، بنابراین وسط مخلوط است.\n۴. برچسب «پرتقال» را روی جعبهٔ سمت چپ بگذار؛ این تنها حالت باقی‌مانده است.','fruit_market_day')
    l.variable(drawn=False,evidence=False)
    labels=['سیب','پرتقال','مخلوط']
    for i,x in enumerate([550,960,1370]):
        l.image(f'box_{i}','fruit_crate',x,620,['tap'])
        l.variable(**{f'label_{i}':i})
        l.button(f'label_{i}',labels[i],x,850,[dict(type='drag',bounds=[300,550,1350,410],return_on_invalid=True),'drop_on'],(280,110))
        l.zone(f'label_zone_{i}',x,620,[f'label_{j}' for j in range(3)]+['unknown'])
        l.image(f'drawn_{i}','apple' if i==2 else 'orange_fruit',x,510,visible=False,scale=[.4,.4])
        l.rule('tap',f'box_{i}',[setv('drawn'),setv('evidence',i==2),show(f'drawn_{i}'),*([FAIL] if i!=2 else [])],[var('drawn',False)])
    for src,dest in itertools.product(range(3),repeat=2):
        l.drop(f'label_{src}',f'label_zone_{dest}',[move(f'label_{src}',[550,960,1370][dest],740),setv(f'label_{src}',dest)],[var('drawn')])
    l.win('variable_changed','$level',conditions=[var('evidence'),var('label_0',2),var('label_1',0),var('label_2',1)])
    l.button('unknown','نامعلوم',320,950,[dict(type='drag',bounds=[200,500,1500,480],return_on_invalid=True),'drop_on'])
    for i in range(3): l.drop('unknown',f'label_zone_{i}',[move('unknown',320,950),feedback(f'box_{i}')])
    l.image('color_stamp','pomegranate',1650,900,['tap'],scale=[.5,.5]); l.rule('tap','color_stamp',[feedback('color_stamp')]); l.save()


def author_coins():
    l=Level(60,'سه سکه را با سه سکه بسنج؛ سپس از گروه مشکوک یکی را با یکی بسنج.','puzzle_workbench_day')
    l.variable(balance=0,count_diff=0,weighings=0,candidates=9,outcome=99,recording=False,placing=False)
    l.counter('وزن‌کشی','weighings',2)
    l.note('هر تأیید یک توزین است؛ تعداد برابر روی کفه‌ها اطلاعات می‌دهد. لمس سکه یعنی انتخاب.')
    l.image('scale','weighing_scale',960,650,scale=[2,2])
    for name,x in [('left',700),('right',1220),('tray',960)]: l.zone(name,x,620 if name!='tray' else 920,[f'coin_{i}' for i in range(9)],(360,180))
    for i in range(9):
        x=360+i*150
        l.drag(f'coin_{i}','puzzle_tile',x,920,extra=['tap'],hit_size=[100,100])
        l.d['objects'][-1].update(scene='TextObject',sprite='res://assets/ui/score.png',text=str(i+1).translate(str.maketrans('0123456789','۰۱۲۳۴۵۶۷۸۹')),text_color='#354f54')
        l.variable(**{f'side_{i}':0,f'candidate_{i}':True})
        weight=9 if i==6 else 10
        for old,new in itertools.product([-1,0,1],repeat=2):
            if old==new: continue
            target={-1:'left',0:'tray',1:'right'}[new]
            pos=[700+(i%3-1)*95,560+(i//3)*60] if new==-1 else [1220+(i%3-1)*95,560+(i//3)*60] if new==1 else [x,920]
            l.drop(f'coin_{i}',target,[setv('placing'),inc('balance',(new-old)*weight),inc('count_diff',new-old),setv(f'side_{i}',new),move(f'coin_{i}',*pos)], [var(f'side_{i}',old),var('placing',False)])
        l.rule('drop_on',f'coin_{i}',[setv('placing',False)],[var('placing')])
        # Unique inference is required; merely tapping known packaged coin seven fails.
        l.win('tap',f'coin_{i}',conditions=[var('weighings',0,'gt'),var('candidates',1),var(f'candidate_{i}'),var('recording',False)])
    l.button('weigh','توزین',960,800)
    for outcome,op in [(-1,'gt'),(0,'eq'),(1,'lt')]:
        # balance = right mass - left mass: positive means left lighter.
        l.rule('tap','weigh',[setv('recording'),setv('outcome',outcome),inc('weighings')],[var('weighings',2,'lt'),var('count_diff',0),var('balance',0,op)])
    l.text('unequal_counts','تعداد دو کفه نابرابر است؛ سکهٔ سبک مشخص نمی‌شود.',960,480,visible=False,size=(1150,70))
    l.rule('tap','weigh',[inc('weighings'),show('unequal_counts'),*[hide(n) for n in ['left_light','equal','right_light']]],[var('weighings',2,'lt'),var('count_diff',0,'ne')])
    for i in range(9):
        for outcome in [-1,0,1]:
            for side in [-1,0,1]:
                survives=(side==outcome) if outcome else (side==0)
                if not survives:
                    l.rule('tap','weigh',[setv(f'candidate_{i}',False),inc('candidates',-1)],[var('recording'),var('outcome',outcome),var(f'side_{i}',side),var(f'candidate_{i}')])
    for outcome,name in [(-1,'left_light'),(0,'equal'),(1,'right_light')]:
        l.text(name,{-1:'کفهٔ چپ سبک‌تر',0:'دو کفه برابر',1:'کفهٔ راست سبک‌تر'}[outcome],960,480,visible=False,size=(700,70))
        l.rule('tap','weigh',[*[hide(n) for n in ['left_light','equal','right_light','unequal_counts']],show(name)],[var('recording'),var('outcome',outcome)])
    l.rule('tap','weigh',[setv('recording',False)],[var('recording')])
    l.image('magnifier','magnifying_glass',280,550,['hold'],scale=[.6,.6]); l.rule('hold','magnifier',[feedback('magnifier')])
    l.drag('souvenir','puzzle_tile',1640,550,scale=[1.5,1.5]); l.d['objects'][-1]['sprite']='res://assets/ui/score.png'
    l.image('decorative_tray','test_tray',1630,760,scale=[.6,.6]); l.zone('decoration',1630,760,['souvenir']); l.drop('souvenir','decoration',[move('souvenir',1630,760),feedback('souvenir')]); l.save()


def author_river():
    l=Level(61,'بز را ببر؛ گرگ را ببر و بز را برگردان؛ کلم را ببر و در پایان بز را منتقل کن.','river_crossing_day')
    l.variable(bank=0,mask=0,cargo=-1,transition=False)
    l.note('یک محموله را داخل قایق بگذار؛ قایق را به ساحل دیگر بکش. قایق خالی هم برمی‌گردد.')
    for i,sprite in enumerate(['wolf','goat','cabbage']): l.drag(f'cargo_{i}',sprite,380,550+i*160,scale=[.65,.65])
    l.drag('boat','boat_empty',590,940,scale=[.8,.8]); l.zone('boat_load',590,940,[f'cargo_{i}' for i in range(3)],(270,140))
    l.zone('left_bank',590,940,['boat'],(300,160)); l.zone('right_bank',1330,940,['boat'],(300,160))
    # Two alternative load zones follow the boat through show/hide actions.
    l.zone('boat_load_right',1330,940,[f'cargo_{i}' for i in range(3)],(270,140)); l.d['objects'][-1]['visible']=False
    for i in range(3):
        l.rule('drag_start',f'cargo_{i}',[setv('cargo',-1)],[var('cargo',i)])
        for mask in range(8):
            l.rule('drag_end',f'cargo_{i}',[move(f'cargo_{i}',1530 if mask>>i&1 else 380,550+i*160)],[var('mask',mask)])
    for bank,mask in itertools.product(range(2),range(8)):
        for cargo in [-1,0,1,2]:
            if cargo>=0 and (mask>>cargo&1)!=bank: continue
            cond=[var('bank',bank),var('mask',mask),var('cargo',cargo),var('transition',False)]
            if cargo==-1:
                for i in range(3):
                    if (mask>>i&1)==bank:
                        l.drop(f'cargo_{i}','boat_load_right' if bank else 'boat_load',[setv('cargo',i),move(f'cargo_{i}',1330 if bank else 590,875)],cond)
            newmask=mask if cargo==-1 else mask^(1<<cargo); dest=1-bank
            unsafe=any(all((newmask>>i&1)==bank for i in pair) for pair in [(0,1),(1,2)])
            actions=[setv('transition'),setv('bank',dest),setv('mask',newmask),setv('cargo',-1),move('boat',1330 if dest else 590,940),hide('boat_load' if dest else 'boat_load_right'),show('boat_load_right' if dest else 'boat_load')]
            if cargo>=0: actions.append(move(f'cargo_{cargo}',1530 if dest else 380,550+cargo*160))
            if unsafe: actions.append(FAIL)
            l.drop('boat','right_bank' if dest else 'left_bank',actions,cond)
    l.rule('drop_on','boat',[setv('transition',False)],[var('transition')])
    l.win('variable_changed','$level',conditions=[var('mask',7),var('bank',1)])
    l.button('unload','خالی‌کردن قایق',960,500)
    for mask in range(8): l.rule('tap','unload',[setv('cargo',-1),*[move(f'cargo_{i}',1530 if mask>>i&1 else 380,550+i*160) for i in range(3)]],[var('mask',mask)])
    l.drag('bush','bush',1700,530,scale=[.5,.5]); l.zone('goat_trap',370,710,['bush']); l.drop('bush','goat_trap',[move('bush',1700,530),feedback('cargo_1')])
    l.drag('broken_bridge','bridge_broken',960,800,scale=[.7,.7]); l.rule('drag_end','broken_bridge',[move('broken_bridge',960,800),feedback('broken_bridge')]); l.save()


def author_hourglasses():
    l=Level(63,'همزمان شروع کن؛ در دقیقهٔ هفت و یازده ساعت هفت‌دقیقه‌ای را برگردان.','puzzle_workbench_day')
    l.variable(simulation='ready',minutes=0,remaining7=0,remaining11=0,transition=False)
    l.counter('دقیقهٔ داستانی','minutes',15)
    l.note('با شروع، هر دو ساعت برمی‌گردند. «رویداد بعدی» زمان را تا خالی‌شدن یک ساعت جلو می‌برد.')
    l.image('glass7','hourglass_clear',650,670,['swipe']); l.image('glass11','hourglass_clear',1270,670,['swipe'])
    for x,suffix in [(650,'7'),(1270,'11')]:
        l.image('upper'+suffix,'sand_upper',x,630,visible=False,z_index=2)
        l.image('lower'+suffix,'sand_lower',x,720,z_index=2)
    l.text('label7','۷ دقیقه',650,830); l.text('label11','۱۱ دقیقه',1270,830)
    l.button('start','شروع همزمان',960,540); l.button('next','تا رویداد بعدی',960,940)
    l.button('confirm','پایان اندازه‌گیری',1550,940)
    def key(s): return ','.join(map(str,s))
    def transition(s):
        t,a,b=s
        return [setv('transition'),setv('simulation',key(s)),setv('minutes',t),setv('remaining7',a),setv('remaining11',b)]
    l.rule('tap','start',transition((0,7,11)),[var('simulation','ready')])
    # Reachable event-boundary states. No fixed correct-sequence gate: actual sand
    # remaining determines the duration after a flip, including wrong turns.
    queue=deque([(0,7,11)]); seen=set()
    while queue:
        s=queue.popleft()
        if s in seen: continue
        seen.add(s); t,a,b=s
        cond=[var('simulation',key(s)),var('transition',False)]
        for obj,dest in [('glass7',(t,7-a,b)),('glass11',(t,a,11-b))]:
            l.rule('swipe',obj,transition(dest)+[feedback(obj)],cond)
            if dest not in seen: queue.append(dest)
        nonzero=[r for r in [a,b] if r>0]
        if nonzero:
            dt=min(nonzero); dest=(t+dt,max(0,a-dt),max(0,b-dt))
            if dest[0]<=15:
                l.rule('tap','next',transition(dest),cond)
                if dest not in seen: queue.append(dest)
            else: l.rule('tap','next',[FAIL],cond)
        if t==15 and a==0: l.win('tap','confirm',conditions=cond)
    for event,source in [('tap','start'),('tap','next'),('swipe','glass7'),('swipe','glass11')]:
        l.rule(event,source,[setv('transition',False)],[var('transition')])
    # Sand remaining is always visible; zero and partially running are distinct.
    for obj,name,total,x in [('glass7','remaining7',7,650),('glass11','remaining11',11,1270)]:
        for amount in range(total+1):
            l.text(f'{name}_{amount}',f'شن باقی‌مانده: {amount} دقیقه',x,880,visible=amount==0,size=(480,55))
            suffix=str(total)
            sand=[show('upper'+suffix),act('scale','upper'+suffix,value=[1,max(1/total,amount/total)])] if amount else [hide('upper'+suffix)]
            sand += [show('lower'+suffix),act('scale','lower'+suffix,value=[1,max(1/total,(total-amount)/total)])] if amount<total else [hide('lower'+suffix)]
            l.rule('variable_changed','$level',[*[hide(f'{name}_{n}') for n in range(total+1)],show(f'{name}_{amount}'),*sand],[var(name,amount)])
    l.image('clock_frame','clock_face',300,650,['tap'],scale=[.5,.5]); l.rule('tap','clock_frame',[feedback('clock_frame')])
    l.drag('ruler','height_ruler',1660,650,scale=[.6,.6]); l.rule('drag_end','ruler',[move('ruler',1660,650),feedback('ruler')]); l.save()


def author_remaining():
    l=Level(62,'بی‌حرکتی شیر و نوشتهٔ سه سال بی‌غذایی را بررسی کن؛ سپس در همان قفس را باز کن.','caravanserai_night_lit')
    l.variable(lion_seen=False)
    for i,sprite in enumerate(['door_fire','door_killer','door_lion']):
        x=550+i*410; l.image(f'door_{i}',sprite,x,650,['hold','swipe'],scale=[1.3,1.3])
        l.text(f'clue_{i}',['آتش هنوز شعله دارد','قاتل بیدار و مسلح است','سه سال بی‌غذا؛ هیچ حرکتی ندارد'][i],x,850,visible=False,size=(380,110))
        l.rule('hold',f'door_{i}',[show(f'clue_{i}'),*([setv('lion_seen')] if i==2 else [])])
    l.win('swipe','door_2',[replace('door_2','hidden_door')],[var('lion_seen')])
    for i in [0,1]: l.rule('swipe',f'door_{i}',[feedback(f'door_{i}')])
    l.drag('water','water_bowl',320,930,scale=[.5,.5]); l.zone('fire_zone',550,650,['water']); l.image('steam','steam_plume',550,610,visible=False); l.drop('water','fire_zone',[move('water',320,930),show('steam'),act('play_animation','steam',animation='chapter_two/flash',wait=False)])
    l.rule('custom:animation_finished','steam',[hide('steam')])
    l.image('shield','wooden_shield',1650,930,['hold'],scale=[.7,.7]); l.image('crack','shield_crack',1650,930,visible=False,scale=[.7,.7]); l.rule('hold','shield',[show('crack')]); l.save()

    l=Level(64,'گردِ زیر آجر لق را ببین و همان آجر را نگه دار تا فرو برود.','caravanserai_night_lit')
    l.image('door','hidden_door',960,670,visible=False,z_index=-4)
    for i in range(9):
        x=650+(i%3)*310; y=550+(i//3)*170
        l.image(f'brick_{i}','loose_brick' if i==4 else 'fixed_brick',x,y,['tap','hold'])
        if i==4: l.win('hold','brick_4',[act('scale','brick_4',value=[.7,.7]),show('door'),hide('brick_4')])
        else: l.rule('hold',f'brick_{i}',[feedback(f'brick_{i}')])
        l.rule('tap',f'brick_{i}',[feedback(f'brick_{i}')])
    l.image('painted_dust','dust_motes',650,605,visible=False,scale=[.5,.5]); l.rule('tap','brick_0',[show('painted_dust')])
    l.image('brush','broom',1600,850,[dict(type='swipe',direction='right')],scale=[.6,.6]); l.rule('swipe','brush',[hide('painted_dust')]); l.save()

    l=Level(65,'سکه همراه فنجانِ آغازین حرکت می‌کند. پنج بار جای دو فنجان عوض می‌شود؛ مسیر همان فنجان را در هر عبور دنبال کن، نه جای اولیه یا نزدیک‌ترین فنجان را. تا پایان حرکت‌ها صبر کن؛ فقط یک انتخاب داری و انتخاب اشتباه نیاز به تلاش دوباره دارد.','puzzle_workbench_night')
    l.variable(ready=False,started=False)
    l.note('پنج جابه‌جایی، فقط یک انتخاب؛ برای آغاز، سکهٔ زیر فنجان چپ را لمس کن.')
    l.text('tracking','فنجانِ حامل سکه را دنبال کن؛ تا پایان حرکت‌ها صبر کن.',960,430,size=(1550,90),visible=False)
    l.text('choose','سکه کجاست؟ فقط یک فنجان را انتخاب کن.',960,430,size=(1550,90),visible=False)
    for i,letter in enumerate('abc'): l.image('cup_'+letter,'cup',560+i*400,690,['tap'],scale=[1,1])
    l.image('coin','puzzle_tile',560,850,['tap']); l.d['objects'][-1]['sprite']='res://assets/ui/score.png'
    l.rule('tap','coin',[setv('started'),hide('instructions'),show('tracking'),hide('coin'),*[act('play_animation','cup_'+letter,animation='cup_challenge/shuffle_'+letter,wait=False) for letter in 'abc']],[var('started',False)],once=True)
    l.rule('custom:animation_finished','cup_a',[move('cup_a',1360,690),move('cup_b',960,690),move('cup_c',560,690),setv('ready'),hide('tracking'),show('choose')],[var('started'),var('ready',False),dict(type='event_value',field='animation',operator='eq',value='cup_challenge/shuffle_a')])
    l.win('tap','cup_a',[show('coin'),move('coin',1360,780)],conditions=[var('ready')])
    for letter in 'bc': l.rule('tap','cup_'+letter,[FAIL],[var('ready')])
    l.save()

    l=Level(66,'مسیر طناب‌ها را تا زنگ اصلی دنبال کن؛ طناب وسط را به پایین بکش.','puzzle_workbench_day')
    l.image('paths','bell_rope_paths',960,680,scale=[.8,.8])
    l.image('main_bell','bell',1120,500,scale=[.6,.6]); l.image('left_weight','stone',800,500,scale=[.4,.4]); l.image('right_weight','stone',960,500,scale=[.4,.4])
    for i in range(3):
        x=800+i*160
        l.drag(f'rope_{i}','rope_pull',x,930,bounds=(x,870,1,140),scale=[.65,.65])
        l.d['objects'][-1]['interactions'][0]['axis']='y'
        if i==1: l.win('drag_end','rope_1',[feedback('main_bell'),dict(type='play_sound',sound='res://assets/samples/radio_chime.wav',wait=False)],[dict(type='moved_distance_at_least',value=80)])
        else: l.rule('drag_end',f'rope_{i}',[move(f'rope_{i}',x,930),feedback('left_weight' if i==0 else 'right_weight')])
    l.image('pulley','clock_hands',1540,620,[dict(type='swipe',direction='right')],scale=[.5,.5]); l.rule('swipe','pulley',[act('rotate','pulley',degrees=90)])
    l.image('small_bell','bell',370,900,['tap'],scale=[.4,.4]); l.rule('tap','small_bell',[feedback('small_bell'),dict(type='play_sound',sound='res://assets/samples/radio_chime.wav',wait=False)]); l.save()

    l=Level(67,'گردن باریک و دستهٔ سمت راست باید هر دو با سایهٔ هدف منطبق باشند.','puzzle_workbench_night')
    l.image('target','jug_shadow_target',960,620); l.zone('light_position',960,620,[f'jug_{i}' for i in range(4)],(245,220)); l.image('lamp','lamp_on',500,600)
    for i,x in enumerate([450,800,1150,1500]):
        l.drag(f'jug_{i}',f'shadow_jug_{i if i<3 else 1}',x,900,scale=[.7,.7] if i<3 else [.45,.45])
        if i==0: l.win('drop_on','jug_0',[move('jug_0',960,620),act('scale','jug_0',value=[1,1])],target='light_position')
        else: l.drop(f'jug_{i}','light_position',[move(f'jug_{i}',x,900),feedback('target')])
    l.image('lever','wall_switch',1550,560,[dict(type='swipe',direction='up')],scale=[.5,.5]); l.image('test_shadow','jug_shadow_target',1560,690,visible=False,scale=[.4,.7]); l.rule('swipe','lever',[show('test_shadow')]); l.save()

    l=Level(68,'نشانِ کتاب وارونه را پیدا کن؛ همان کتاب را از قفسه بیرون بکش.','library_room_day')
    l.image('door','hidden_door',960,650,visible=False,z_index=-3); l.image('shelf','bookshelf',960,650,scale=[1.8,1.2])
    for i,x in enumerate([800,960,1120]):
        l.drag(f'book_{i}','inverted_book' if i==1 else 'upright_book',x,650,bounds=(500,550,1100,380),scale=[.7,.7])
        if i==1: l.win('drag_end','book_1',[move('shelf',1500,680),hide('book_0'),hide('book_2'),show('door'),act('rotate','shelf',degrees=80)],[dict(type='moved_distance_at_least',value=170)])
        else: l.rule('drag_end',f'book_{i}',[move(f'book_{i}',x,650),feedback(f'book_{i}')])
    l.image('frame','face_frame',1500,800,['hold'],scale=[.65,.65]); l.image('door_sketch','hidden_door',1500,800,visible=False,scale=[.3,.3]); l.rule('hold','frame',[show('door_sketch')]); l.save()

    l=Level(69,'نقش پایینِ سمت راستِ فرش میانی کم است؛ جهت نقش را هم بررسی کن.','puzzle_workbench_day')
    for i,x in enumerate([490,960,1430]):
        l.image(f'rug_{i}','rug_missing' if i==1 else 'rug_symmetric',x,660)
        l.zone(f'rug_gap_{i}',x+75,730,['piece','false_piece'],(90,90))
    l.drag('piece','rug_motif',730,950,scale=[1.4,1.4]); l.drag('false_piece','rug_motif_reversed',1170,950,scale=[1.4,1.4])
    l.win('drop_on','piece',[move('piece',1035,730),act('scale','piece',value=[1,1])],target='rug_gap_1')
    for i in range(3):
        l.drop('false_piece',f'rug_gap_{i}',[move('false_piece',1170,950),feedback(f'rug_{i}')])
        if i!=1: l.drop('piece',f'rug_gap_{i}',[move('piece',730,950),feedback(f'rug_{i}')])
    l.image('axis_stencil','height_ruler',1700,900,['tap'],scale=[.6,.6]); l.rule('tap','axis_stencil',[act('rotate','axis_stencil',degrees=45)]); l.save()

    l=Level(70,'باید هم صدادارِ ناقض و هم فردِ پشتِ عدد فرد را بررسی کنی: A و ۷.','puzzle_workbench_night')
    l.variable(flips=0); l.counter('کارت برگشته','flips',2)
    l.note('قانون: صدادار ← عدد زوج. فقط دو کارت را می‌توانی برگردانی.')
    for i,(front,back,x) in enumerate([('A','۳',420),('D','۴',780),('۴','A',1140),('۷','D',1500)]):
        l.variable(**{f'flipped_{i}':False})
        l.button(f'card_{i}',front,x,660,['swipe'],(280,150))
        l.button(f'back_{i}',back,x,660,(),(280,150)); l.d['objects'][-1]['visible']=False
        l.rule('swipe',f'card_{i}',[setv(f'flipped_{i}'),inc('flips'),hide(f'card_{i}'),show(f'back_{i}')],[var('flips',2,'lt')],once=True)
    l.win('variable_changed','$level',conditions=[var('flips',2),var('flipped_0'),var('flipped_3')])
    l.rule('variable_changed','$level',[FAIL],[var('flips',2),dict(type='not',condition=dict(type='all',conditions=[var('flipped_0'),var('flipped_3')]))])
    l.button('reverse_rule','زوج ← صدادار؟',570,930,['hold'],(430,110)); l.rule('hold','reverse_rule',[feedback('reverse_rule')])
    l.image('stamp','postal_seal',1440,930,['tap'],scale=[.6,.6]); l.rule('tap','stamp',[feedback('stamp')]); l.save()


def write_asset_report():
    purposes = {
        'puzzle_workbench': 'میز آزمون خالیِ روز/شب با سطح کار روشن؛ زمینهٔ متناسب برای معماهای رومیزی موجود نبود.',
        'five_window_room': 'اتاق بدون پنجرهٔ تزئینی اضافی برای دقیقاً پنج قابِ تعاملی.',
        'library_room': 'محیط کتابخانهٔ روز/شب بدون قفسه یا ورودی ثابت؛ سرنخ‌ها اشیای مستقل‌اند.',
        'library_map': 'نقشهٔ قدیمی با نشانهٔ قفسهٔ چپ، متمایز از رد فعلیِ قفسهٔ راست.',
        'river_crossing': 'دو ساحل و رود با عرض کافی برای قایق و محموله؛ محیط مناسب موجود نبود.',
        'bridge_lantern': 'فانوس روشن قابل حمل و همراه گروه؛ چراغ‌های موجود خاموش یا رومیزی بودند.',
        'bridge_crossing': 'رود و پل دوطرفهٔ شبانه با سطح عبور روشن؛ محیط مناسب موجود نبود.',
        'wind_arrow': 'جهت باد و بادسنجِ قابل تشخیص برای مهلت حفاظت شعله.',
        'oil_lamp': 'چراغ نفتی خاموش؛ چراغ برقی موجود جای این وسیله را نمی‌گیرد.',
        'lantern': 'فانوس خاموش با دسته و قاب؛ نمونهٔ مناسب موجود نبود.',
        'guard_opaque': 'محافظ ماتِ دام؛ محافظ شفاف موجود بدون تغییر بازاستفاده می‌شود.',
        'window_': 'دو قاب هم‌اندازه با منظرهٔ زنده و منظرهٔ نقاشی‌شده؛ تمایز هندسی سرنخ.',
        'leaf_': 'برگ مستقل برای حرکت زندهٔ قاب سمت راست، بدون تغییر تصویر پنجره‌های قبلی.',
        'pattern_tile': 'اتصال چهار لبه و قطع پیوستگی خط؛ منابع قبلی جدول اتصال نداشتند.',
        'tile_': 'محیط چهار لبه یا شابلون دو لبهٔ کاشی؛ هندسه با گزینه‌ها هماهنگ است.',
        'glass_bowl': 'تنگ شیشه‌ای گرد بدون دسته و درجه‌بندی در دو حالت خالی و پر؛ منابع موجود ظرف مدرج یا تنگ دارای ماهی بودند.',
        'floor_latch': 'ضامن کف با دستگیره و جهت کشیدن در دو حالت بسته و آزاد؛ دارایی ضامن مناسب موجود نبود.',
        'jug_body': 'ترک و قطرهٔ بدنه، مستقل از قطرهٔ دهانه و لکهٔ کف.',
        'family_': 'تمایز سه نسل و پیوند والد/فرزند برای فرد مشترک؛ منبع مناسب موجود نبود.',
        'brothers_': 'عکس دو برادر برای نسبت دام، متمایز از زنجیرهٔ نسل‌ها.',
        'tea_': 'بدنه‌های شفافِ هم‌اندازهٔ پُر/خالی یا قاشق؛ فنجان مات و قلم مناسب نبودند.',
        'bookshelf': 'قفسهٔ مستقلِ قابل حرکت و چرخش برای راه مخفی.',
        'floor_scrape': 'رد ساییدگی واقعی زیر قفسه، مستقل از پس‌زمینه.',
        'hidden_door': 'ورودی پشت قفسه/آجر که ابتدا مخفی است؛ دریچهٔ کف مناسب نبود.',
        'fruit_crate': 'سه جعبهٔ میوهٔ هم‌شکل با برچسب مستقل؛ منبع مناسب موجود نبود.',
        'orange_': 'پرتقالِ نمونه‌برداری؛ سیب موجود بدون تغییر بازاستفاده شد.',
        'boat_': 'قایق قابل جابه‌جایی با یک جای محموله؛ منبع مناسب موجود نبود.',
        'bridge_broken': 'پل شکستهٔ دام با شکاف روشن؛ مسیر قابل عبور نیست.',
        'wolf': 'هویت گرگ در مسئلهٔ رود؛ حیوان موجود نقش گرگ را پوشش نمی‌داد.',
        'goat': 'هویت بز در مسئلهٔ رود؛ گوسفند موجود نقش بز را پوشش نمی‌داد.',
        'cabbage': 'هویت کلم به‌عنوان محمولهٔ خوراکی؛ منبع مناسب موجود نبود.',
        'door_': 'سه در با خطر آتش/قاتل/شیرِ بی‌حرکت و نشانه‌های متمایز.',
        'wooden_shield': 'سپر چوبیِ دام؛ درپوش ظرف شکل و نقش سپر را ندارد.',
        'shield_crack': 'حالت ترکِ سپر مستقل از منبع پایه.',
        'magnifying_': 'ذره‌بین آزمایش سکه‌ها؛ عینکِ دوچشمی مناسب این عمل نبود.',
        'hourglass_': 'محفظهٔ شفاف بدون شن ثابت برای نمایش مقدار واقعی باقی‌مانده.',
        'sand_': 'شن مستقلِ بالا/پایین که با زمان شبیه‌سازی تغییر می‌کند.',
        'loose_brick': 'آجر لق با غبار زیر لبه؛ نیازمند سرنخ مستقل از دیوار بود.',
        'fixed_brick': 'آجر ثابتِ هم‌اندازه با آجر لق، بدون غبار لبه.',
        'inverted_book': 'کتاب وارونه با جهت نشان قابل تشخیص برای اهرم.',
        'upright_book': 'کتاب هم‌رنگ با نشانِ مستقیم برای مقایسهٔ جهت.',
        'shadow_jug': 'پروفایل گردن/دسته با معیار ثابت؛ کوزهٔ قبلی این گزینه‌ها را نداشت.',
        'jug_shadow': 'سایهٔ هدف منطبق با هندسهٔ کوزهٔ درست.',
        'rug_': 'تقارن، خانهٔ خالی و جهت نقشِ مستقل؛ منابع قبلی جدول انطباق نداشتند.',
        'bell_rope': 'اتصال آشکار طناب‌های درهم با تقاطع فاقد اتصال.',
        'rope_pull': 'دستهٔ قابل کشیدن طناب، مستقل از مسیر ثابت بالا.',
        'cup_red': 'همان شکل فنجان با برچسب قرمزِ دام، بدون تغییر هویت حامل سکه.',
    }
    new = {path: next(reason for prefix,reason in purposes.items() if Path(path).stem.startswith(prefix)) for path in sorted(NEW_ASSETS)}
    new[P+'bridge_lantern_feedback.tres']='حرکت هم‌زمان گروه و چراغ در دو جهت با پایان مشترک و پشتیبانی مکث/لغو؛ منبع مناسب موجود نبود.'
    new[P+'cup_challenge_feedback.tres']='پنج تعویض سریع با مسیر جدا برای سه فنجان و هویت پایدار؛ انیمیشن قبلی فقط دو تعویض داشت.'
    new[P+'chapter_five_feedback.tres']='مهلت باد، حرکت برگ و دو تعویض هویتی فنجان؛ انیمیشن‌های موجود این مسیرها را نداشتند.'
    redesign=json.loads((ROOT/'docs/chapter-five-redesign-assets.json').read_text(encoding='utf-8'))
    new.update(redesign['new_assets'])
    def resources(value):
        if isinstance(value,str): return {value} if value.startswith('res://') else set()
        if isinstance(value,list): return set().union(*(resources(v) for v in value))
        if isinstance(value,dict): return set().union(*(resources(v) for v in value.values()))
        return set()
    stages={}
    for number in range(51,71):
        level=json.loads((DATA/f'{number:03}.json').read_text(encoding='utf-8'))
        paths=resources(level)
        paths.add('res://PuzzleEngine/Objects/PuzzleObject.tscn')
        paths.update('res://PuzzleEngine/Objects/'+obj['scene']+'.tscn' for obj in level['objects'])
        for rule in level['rules']:
            for action in rule['actions']:
                if action['type']=='play_animation':
                    library=action['animation'].split('/')[0]
                    if library in ['chapter_five','chapter_two','cup_challenge','bridge_lantern']:
                        paths.add(P+library+'_feedback.tres')
        stages[str(number)]=dict(background=level['background'],lighting='night_lit' if 'night' in level['background'] else 'day',reused=sorted(paths-set(new)),new=sorted(paths&set(new)))
    report=dict(note='گزارش نویسندگی و منابع؛ تأیید اجرایی یا آزمون تصویری نیست. فایل‌های تصویری و صوتی قبلی تغییر نکردند.',new_assets=new,stages=stages,
                matching=dict(tile_53=dict(order='N,E,S,W',target=[0,1,2,3],options=[dict(id=0,edges=[0,1,2,3],continuous=True),dict(id=1,edges=[0,1,2,3],continuous=False,break_edge='W'),dict(id=2,edges=[1,0,2,3],continuous=True),dict(id=3,edges=[0,3,2,1],continuous=True)]),
                              rug_69=dict(axis='vertical',missing_rug=1,rows=[540,650,760],target_angles=[0,0,0],initial_angles=[270,0,180]),
                              shadow_67=dict(body_required=True,neck_width=50,handle='right',light_test_required=True),
                              cards_70=dict(fronts=['A','E','D','K','4','8','7','9'],backs=['3','2','4','7','A','D','D','E'],required=[0,1,6,7],budget=4)))
    (ROOT/'docs/chapter-five-assets.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


if __name__ == '__main__':
    author_assets()
    author_animations()
    author_simple_levels()
    subprocess.run(['node',str(ROOT/'tools/redesign_chapter_five.mjs')],check=True,cwd=ROOT)
    write_asset_report()
    manifest=dict(schema_version=1,manifest_version=9,levels=[dict(id=i,path=f'res://PuzzleEngine/PuzzleData/{i:03}.json') for i in range(1,71)])
    (DATA/'manifest.json').write_text('{\n  "schema_version": 1,\n  "manifest_version": 9,\n  "levels": [\n'+',\n'.join('    { '+json.dumps(entry)[1:-1]+' }' for entry in manifest['levels'])+'\n  ]\n}\n',encoding='utf-8')
