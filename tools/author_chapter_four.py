"""Author packaged stages 31–50. Writes content only; does not run Godot or tests."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/samples'
DATA = ROOT / 'PuzzleEngine/PuzzleData'
P = 'res://assets/samples/'
BACKGROUND_OVERRIDES = {
    32: 'courtyard_night_lit', 33: 'winter_room_day', 36: 'fruit_market_day',
    37: 'room_overhead_background', 39: 'tea_house_night_lit',
    43: 'kitchen_counter_background_light', 45: 'calendar_desk_background_light',
    47: 'grid_notebook_background', 48: 'sheepfold_day', 50: 'caravanserai_night_lit',
}


def svg(name, body, w=240, h=200):
    (ASSETS / (name + '.svg')).write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
        '<g stroke="#48575d" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">'
        + body + '</g></svg>\n', encoding='utf-8')


# New vector assets supply the missing silhouettes and physical clues only.
svg('match_unlit', '<path d="M50 160 180 40" stroke="#c9a26e" stroke-width="18"/><path d="m170 50 18-17" stroke="#b95e50" stroke-width="23"/><rect x="20" y="165" width="200" height="18" rx="8" fill="#936b56"/>')
svg('match_lit', '<path d="M50 160 180 40" stroke="#c9a26e" stroke-width="18"/><path d="M180 59Q134 22 185 5Q179 28 202 34Q215 66 180 59Z" fill="#ffc956"/><path d="M180 55Q170 35 189 29Q202 48 180 55" fill="#ff8b47"/><rect x="20" y="165" width="200" height="18" rx="8" fill="#936b56"/>')
svg('empty_lighter', '<rect x="65" y="65" width="110" height="120" rx="18" fill="#9cb9bc"/><rect x="78" y="40" width="84" height="35" fill="#c1c8bc"/><circle cx="136" cy="35" r="16" fill="#899394"/>')
svg('wall_switch', '<rect x="50" y="15" width="140" height="170" rx="16" fill="#f2e6cb"/><rect x="89" y="55" width="62" height="85" rx="8" fill="#9bbfbb"/><path d="M105 72H135"/>')
svg('room_heater', '<rect x="20" y="20" width="200" height="150" rx="18" fill="#a4b4ad"/><path d="M55 50v90m32-90v90m33-90v90m33-90v90m32-90v90M52 175v15m136-15v15" fill="none" stroke-width="10"/>')
svg('promise_joined', '<path d="m10 72 70-30 40 25 40-25 70 30-20 68-58-6-32 24-32-24-58 6Z" fill="#e6b28f"/><path d="m78 72 34 37q12 12 24-3l21-25M90 124l28 22M110 111l30 26" fill="none"/><path d="M100 35q-28-27-26-5q0 16 26 30 26-14 26-30 2-22-26 5Z" fill="#d99189"/>', 240, 180)
svg('promise_broken', '<path d="M80 38Q32-7 31 35q0 31 49 60 49-29 49-60 0-42-49 3Z" fill="#d99189"/><path d="m84 13-15 30 22 9-18 38" fill="none" stroke="#fff0d8" stroke-width="9"/>', 160, 110)
svg('window_open_cold', '<rect x="10" y="10" width="340" height="230" rx="12" fill="#c19569"/><rect x="25" y="25" width="310" height="200" fill="#c7e5ed"/><path d="m25 25 94 35v126l-94 39Zm310 0-94 35v126l94 39Z" fill="#f4e6ca"/><path d="M130 87q49-30 92 0M130 125q49-30 92 0M130 163q49-30 92 0" fill="none" stroke="#6da9bc"/>', 360, 250)
svg('thermometer_cold', '<rect x="82" y="12" width="42" height="135" rx="20" fill="#f8efd9"/><circle cx="103" cy="154" r="28" fill="#76b8d3"/><path d="M103 147V113" stroke="#76b8d3" stroke-width="17"/><path d="M138 40h22m-22 30h22m-22 30h22"/>', 200, 200)
svg('toy_car', '<path d="M20 96 60 85 85 46h82l30 45 27 11v50H20Z" fill="#e3a56b"/><path d="M95 57h59l25 33H76Z" fill="#c7e3e5"/><circle cx="64" cy="154" r="24" fill="#626b6b"/><circle cx="181" cy="154" r="24" fill="#626b6b"/>')
svg('goldfish_bowl', '<path d="M52 35h136l-18 24q62 103-50 112Q8 162 70 59Z" fill="#d1e9eb"/><path d="M51 102q70 17 138 0" fill="none" stroke="#71b3c1"/><path d="m135 106 33-26v52Z" fill="#e49454"/><ellipse cx="113" cy="105" rx="37" ry="23" fill="#ed8662"/><circle cx="95" cy="100" r="4" fill="#48575d"/>')
svg('pomegranate', '<path d="m100 38-9-25 26 10 24-10-3 25Q205 53 194 125q-8 63-75 63T45 125Q34 55 100 38Z" fill="#cd7974"/><path d="M70 93q0-29 27-34" fill="none" stroke="#edb0a0" stroke-width="9"/>')
svg('weighing_scale', '<path d="M120 24v130M75 180h90M30 80h180" fill="none" stroke="#a68a5c" stroke-width="12"/><path d="m44 80-25 60h76L70 80m100 0-25 60h76l-25-60" fill="#c6d7c8"/>')
svg('floor_hatch', '<rect x="12" y="15" width="256" height="150" rx="10" fill="#846e56"/><rect x="27" y="29" width="226" height="120" fill="#3f5960"/><path d="M99 43v93m70-93v93m-70-71h70m-70 32h70m-70 28h70" stroke="#d1b284" stroke-width="8"/>', 280, 180)
for name, teeth in [('toothed_key_a', '140,107 140,132 158,132 158,116 178,116 178,132 198,132 198,93'), ('toothed_key_b', '140,107 140,132 158,132 158,93 178,93 178,116 198,116 198,93'), ('toothed_key_c', '140,107 140,116 158,116 158,132 178,132 178,93 198,93')]:
    svg(name, '<circle cx="57" cy="93" r="36" fill="#d8bb77"/><circle cx="57" cy="93" r="17" fill="#f8ecd3"/><path d="M93 93H211" stroke="#d8bb77" stroke-width="16"/>' + f'<polygon points="{teeth}" fill="#d8bb77"/>')
svg('chest_closed', '<path d="M20 82Q20 20 130 20T240 82v113H20Z" fill="#b28b60"/><path d="M20 83h220M64 36v159M195 36v159" fill="none" stroke="#d9ba7b" stroke-width="12"/><rect x="99" y="74" width="64" height="59" rx="8" fill="#d9ba7b"/>', 260, 210)
svg('chest_open', '<path d="M20 95h220v100H20Z" fill="#b28b60"/><path d="M20 80V22h220v58Z" fill="#d6b575"/><path d="M34 105h192v55H34Z" fill="#4c6864"/><circle cx="100" cy="131" r="18" fill="#f7d37b"/><circle cx="142" cy="131" r="18" fill="#f7d37b"/>', 260, 210)
svg('key_profile', '<circle cx="57" cy="93" r="36" fill="#61797b"/><circle cx="57" cy="93" r="17" fill="#f8ecd3"/><path d="M93 93H211" stroke="#61797b" stroke-width="16"/><polygon points="140,107 140,132 158,132 158,93 178,93 178,116 198,116 198,93" fill="#61797b"/>')
svg('samovar', '<ellipse cx="120" cy="110" rx="70" ry="66" fill="#c6ac74"/><path d="M66 40h108M90 24h60M120 178v10M80 192h80M184 120h37v-22M51 70Q9 60 26 116" fill="none" stroke="#b49a65" stroke-width="12"/><ellipse cx="120" cy="47" rx="58" ry="12" fill="#dfc998"/>')
svg('steam_plume', '<path d="M35 126q-30-25 0-46t0-51M80 126q-30-25 0-46t0-51M125 126q-30-25 0-46t0-51" stroke="#79aab0" stroke-width="10" fill="none"/>', 160, 150)
svg('water_jug', '<path d="M76 28h88v32q55 34 39 95-11 40-83 40t-83-40Q21 94 76 60Z" fill="#c4a47e"/><ellipse cx="120" cy="28" rx="44" ry="14" fill="#726b59"/><path d="M195 81q49-7 31 52l-23 9" fill="none" stroke-width="12"/>', 260, 210)
svg('bird_cage', '<path d="M20 185V75Q20 10 120 10T220 75v110Z" fill="none" stroke="#a78c61" stroke-width="10"/><path d="M50 48v137M85 25v160M120 12v173M155 25v160M190 48v137M20 90h200" fill="none"/><rect x="80" y="85" width="80" height="100" rx="7" fill="none"/><path d="M8 189h224" stroke-width="13"/>')
svg('cage_back_open', '<path d="M20 185V75Q20 10 120 10T220 75v110M8 189h224M50 48v137M190 48v137" fill="none" stroke="#a78c61" stroke-width="10"/><path d="M80 185V75h80v110l65-40V42l-65 33" fill="none" stroke="#5c9b9c"/>')
svg('bulb_cold', '<path d="M80 147Q32 113 49 67q17-43 71-43t71 43q17 46-31 80v23H80Z" fill="#e4e7d9"/><path d="M85 175h70m-65 12h60M97 137l-9-51 32 21 32-21-9 51" fill="none"/>')
svg('bulb_lit', '<path d="M80 147Q32 113 49 67q17-43 71-43t71 43q17 46-31 80v23H80Z" fill="#ffe591"/><path d="M85 175h70m-65 12h60M120 3v13M23 45l16 9m162 0 16-9M10 111h20m180 0h20M97 137l-9-51 32 21 32-21-9 51" fill="none" stroke="#bc975d"/>')
svg('heat_lines', '<path d="M30 80q-20-18 0-36t0-35m45 71q-20-18 0-36t0-35m45 71q-20-18 0-36t0-35" fill="none" stroke="#c48668" stroke-width="8"/>', 150, 100)
svg('sheep_alive', '<path d="M55 124v43m69-43v43" stroke-width="13"/><path d="M36 111Q3 90 28 70 16 37 49 36 64 9 91 31q32-17 45 9 35-5 38 28l-8 49Z" fill="#f4ead5"/><ellipse cx="168" cy="102" rx="31" ry="37" fill="#c4b6a0"/><circle cx="176" cy="94" r="4" fill="#48575d"/>', 220, 180)
svg('sheep_dead', '<path d="M27 132q-14-38 18-49 0-30 36-24 22-26 45 0 36-7 42 23l9 50Z" fill="#e0d8c8"/><ellipse cx="175" cy="116" rx="30" ry="25" fill="#b8b1a1"/><path d="m168 106 15 14m-15 0 15-14M47 150h115" fill="none"/>', 220, 180)
svg('footprints_right', '<ellipse cx="45" cy="43" rx="22" ry="33" fill="#a68f73" transform="rotate(-30 45 43)"/><ellipse cx="109" cy="91" rx="22" ry="33" fill="#a68f73" transform="rotate(-30 109 91)"/><path d="m160 43 51 37-51 37" fill="none" stroke="#a68f73" stroke-width="11"/>', 240, 150)
svg('footprint_trail', '<path d="m990 400-280-50-270-90-250-60-80-90" fill="none" stroke="#a68f73" stroke-width="15" stroke-dasharray="12 23" opacity="0.55"/>',1100,500)
svg('shoe_stamp', '<rect x="64" y="70" width="110" height="94" rx="10" fill="#c2a477"/><path d="M120 75V29" stroke-width="22"/><ellipse cx="120" cy="26" rx="33" ry="15" fill="#876e55"/>')
svg('flashlight', '<path d="m35 88 123-28 35 113-123 28Z" fill="#9eb9ac"/><path d="m151 60 44-32 41 137-43 8Z" fill="#e4c38a"/>')
svg('snowball', '<circle cx="120" cy="100" r="72" fill="#e5f1ed"/><path d="M73 72q18-28 43-25m-31 89 45 9" fill="none" stroke="#bad6d5"/>')
svg('hyacinth', '<path d="M120 174V42M120 157q-52-3-56-44 43 0 56 44m0-18q48-13 48-42-37 3-48 42" fill="#8bab78"/><path d="M83 180h74l-8 19H91Z" fill="#b78d68"/>' + ''.join(f'<circle cx="{x}" cy="{y}" r="15" fill="#ac9cbf"/>' for x,y in [(105,32),(130,32),(99,58),(127,58),(107,83),(134,83)]))
svg('garlic', '<path d="M120 31Q51 57 53 126q3 55 67 55t67-55Q189 57 120 31Z" fill="#eee1c8"/><path d="M120 31q-33 76 0 150m0-150q33 76 0 150M120 31l10-20" fill="none" stroke="#c8b99f"/>')
svg('green_sprouts', '<path d="M45 158h150l-17 30H62Z" fill="#c1d5cd"/><path d="M70 155V63m20 92V36m22 119V60m22 95V25m22 130V50m20 105V73" stroke="#83a66a" stroke-width="13"/>')
svg('broom', '<path d="m135 15-33 110" stroke="#a88960" stroke-width="13"/><path d="m75 109 57 17 15 65-97-27Z" fill="#d1b579"/><path d="m89 127-17 40m36-34-8 42m24-35 2 42" stroke="#a98d5c"/>')
svg('ribbon', '<path d="M120 83Q25-10 22 63q0 64 98 20 98 44 98-20-3-73-98 20Zm-9 12-39 87 48-16 29 16-18-87" fill="#cf8e82"/>')
svg('hammer', '<path d="M118 70v115" stroke="#ad8b65" stroke-width="20"/><rect x="49" y="32" width="144" height="50" rx="10" fill="#9aafad"/>')
for name,color in [('sumac_bowl','#af665e'),('samanu_bowl','#9e7352')]:
    svg(name, f'<path d="M25 80h190q-8 92-95 92T25 80Z" fill="#b5cfca"/><ellipse cx="120" cy="80" rx="95" ry="24" fill="{color}"/>')
svg('oleaster_bowl','<path d="M25 100h190q-8 72-95 72T25 100Z" fill="#b5cfca"/>'+''.join(f'<ellipse cx="{x}" cy="{y}" rx="22" ry="15" fill="#b48f60"/>' for x,y in [(65,91),(107,88),(150,94),(177,84),(83,68),(132,62)]))
svg('bowl_lid','<path d="M12 65q108-90 216 0Z" fill="#bdcfc4"/><path d="M110 19h20" stroke-width="14"/>',240,80)
svg('agreement_folded','<path d="M30 25h180v150H30Z" fill="#eadfc7"/><path d="M30 25 120 95l90-70M30 175l90-80 90 80" fill="#f7ecd7"/><path d="M54 132h41m50 0h40" fill="none"/>')
svg('dust_motes','<path d="M30 65q20-31 50-4 26-42 56-7 34-25 58 18Z" fill="#b8a28a" stroke="none"/><circle cx="38" cy="26" r="7" fill="#b8a28a"/><circle cx="163" cy="25" r="9" fill="#b8a28a"/>',220,100)
svg('chest_handle','<path d="M40 120V85q0-45 80-45t80 45v35" fill="none" stroke="#c5a66a" stroke-width="21"/><circle cx="40" cy="130" r="19" fill="#e0c283"/><circle cx="200" cy="130" r="19" fill="#e0c283"/>')
svg('seed_bowl','<path d="M25 100h190q-8 72-95 72T25 100Z" fill="#b5cfca"/>'+''.join(f'<ellipse cx="{x}" cy="{y}" rx="10" ry="5" fill="#d7b579"/>' for x,y in [(48,92),(78,87),(109,93),(138,83),(174,92),(74,70),(107,67),(142,62)]))
svg('puzzle_tile','<rect x="7" y="7" width="266" height="96" rx="16" fill="#f5e9cc"/><path d="M24 25h232" stroke="#d1b078"/>',280,110)
svg('decorative_measure','<path d="M35 33h136v145H35Z" fill="#d2e6dd"/><path d="M171 53q58-9 44 66h-44M55 52h48m-48 31h27m-27 14h48m-48 45h27" fill="none"/>')
svg('height_ruler','<rect x="10" y="10" width="70" height="220" rx="7" fill="#e4c790"/><path d="M12 30h40m-40 22h22m-22 22h40m-40 22h22m-22 22h40m-40 22h22m-22 22h40m-40 22h22m-22 22h40" fill="none"/>',90,240)


def var(name, value=True, op='eq'):
    return dict(type='variable', name=name, operator=op, value=value)


def setv(name, value=True, operation='assign'):
    return dict(type='set_variable', name=name, value=value, operation=operation)


def act(kind, target, **kw):
    return dict(type=kind, target=target, **kw)


def show(target): return act('show', target)
def hide(target): return act('hide', target)
def move(target, x, y): return act('move', target, position=[x, y])
def replace(target, sprite): return act('replace_sprite', target, sprite=P+sprite+'.svg')
def feedback(target): return act('play_animation', target, animation='chapter_two/rattle', wait=False)
def sound(): return dict(type='play_sound', sound='res://assets/sounds/ui_click.wav', wait=False)


class Level:
    def __init__(self, number, hint, background='bright_room'):
        background = BACKGROUND_OVERRIDES.get(number, background)
        row = next(line.split('|')[1:-1] for line in (ROOT/'docs/100_interactive_persian_puzzles.md').read_text(encoding='utf-8').splitlines() if line.startswith(f'| {number} |'))
        self.d = dict(schema_version=1, id=number, question=row[1].strip(), hint=hint,
                      answer=row[2].strip(), time_limit_seconds=int(row[5]), base_score=int(row[6]),
                      background=P+background+'.svg', success=dict(result_delay_seconds=1),
                      variables=dict(solved=False), objects=[], rules=[], win_condition=var('solved'))
    def variable(self, **kw): self.d['variables'].update(kw)
    def image(self, id, sprite, x, y, inputs=(), **kw):
        self.d['objects'].append(dict(id=id, scene='ClickableObject' if inputs else 'ImageObject', sprite=P+sprite+'.svg', position=[x,y], interactions=list(inputs), **kw))
    def text(self, id, text, x, y, inputs=(), **kw):
        self.d['objects'].append(dict(id=id, scene='TextObject', text=text.translate(str.maketrans('0123456789','۰۱۲۳۴۵۶۷۸۹')), position=[x,y], hit_size=[300,70], text_color='#354f54', interactions=list(inputs), **kw))
    def drag(self, id, sprite, x, y, extra=(), bounds=(200,460,1500,450), **kw):
        self.image(id, sprite, x,y, [dict(type='drag', bounds=list(bounds), return_on_invalid=True), 'drop_on', *extra], z_index=5, **kw)
    def card(self, id, text, x,y):
        self.text(id,text,x,y,[dict(type='drag',bounds=[200,460,1500,440],return_on_invalid=True),'drop_on'])
        self.d['objects'][-1].update(sprite=P+'puzzle_tile.svg',hit_size=[300,110])
    def zone(self, id, x,y, sources, size=(260,150)):
        self.d['objects'].append(dict(id=id,scene='DropZone',position=[x,y],hit_size=list(size),accepted_sources=list(sources),z_index=-1))
    def rule(self,event,source,actions,conditions=(),target=None,once=False):
        r=dict(id=f'r{len(self.d["rules"]):04}',event=event,source=source,conditions=list(conditions),actions=actions,once=once)
        if target is not None: r['target']=target
        self.d['rules'].append(r)
    def drop(self,source,target,actions,conditions=(),once=False): self.rule('drop_on',source,actions,conditions,target,once)
    def win(self,event,source,actions=(),conditions=(),target=None): self.rule(event,source,[*actions,setv('solved')],conditions,target)
    def note(self,text):
        self.text('instructions',text,960,350)
        self.d['objects'][-1]['hit_size']=[1500,100]
    def save(self): (DATA/f'{self.d["id"]:03}.json').write_text(json.dumps(self.d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


# 31: the scene is dim because darkness is part of the question; HUD is separate.
l=Level(31,'پیش از روشن‌کردن هر وسیله، کبریت را روی سطح زبر بکش.','room_lighting')
l.image('shade','room_shade_2',960,540,z_index=-5)
l.image('match','match_unlit',960,650,['swipe'])
l.image('lamp','lamp_off',600,580,['tap']); l.image('candle','candle_body',1320,590,['tap'])
l.image('heater','room_heater',1530,770,['tap'])
l.image('lighter','empty_lighter',400,830,['tap']); l.image('switch','wall_switch',1500,480,['tap'])
l.image('spark','camera_flash',400,710,visible=False,scale=[.4,.4])
l.rule('tap','lighter',[show('spark'),act('play_animation','spark',animation='chapter_two/flash',wait=False),sound()])
l.rule('tap','switch',[feedback('switch'),sound()])
for obj in ['lamp','candle','heater']: l.rule('tap',obj,[feedback(obj)])
l.win('swipe','match',[replace('match','match_lit')]); l.save()

l=Level(32,'دست‌های دو نفر را از هم دور کن؛ شکستن قول صدا ندارد.')
l.image('person_a','man',670,610,scale=[.6,.6]); l.image('person_b','man',1250,610,scale=[.6,.6])
l.image('joined','promise_joined',960,640)
l.drag('hand','hand_dry',1030,650,bounds=(700,520,800,250),scale=[.6,.6])
l.image('broken','promise_broken',960,570,visible=False)
l.image('glass','cup',440,830,['tap']); l.image('agreement','paper',1490,800,[dict(type='swipe',direction='down')])
l.rule('tap','glass',[feedback('glass'),sound()]); l.rule('swipe','agreement',[replace('agreement','agreement_folded')])
l.win('drag_end','hand',[hide('joined'),show('broken'),move('hand',1260,670)],[dict(type='moved_distance_at_least',value=180)])
l.save()

l=Level(33,'پنجره را باز کن و به دما و لرزیدن شخصیت دقت کن.')
l.image('window','window_winter_closed',960,530,['tap']); l.image('person','man',960,820,scale=[.6,.6])
l.image('cold','thermometer_cold',1220,700,visible=False)
l.drag('snowball','snowball',450,750,scale=[.7,.7]); l.image('basket','basket_empty',500,500); l.zone('basket_zone',500,500,['snowball'])
l.image('blanket','towel_dry',1500,760,['hold'])
l.drop('snowball','basket_zone',[move('snowball',450,750),feedback('basket')]); l.rule('hold','blanket',[act('scale','blanket',value=[.7,.7])])
l.variable(opened=False)
l.rule('tap','window',[replace('window','window_winter_open'),show('cold'),setv('opened'),feedback('person')],once=True)
l.win('custom:animation_finished','person',conditions=[var('opened')]); l.save()

l=Level(34,'بدنهٔ ساعت ثابت می‌ماند؛ عقربه را لمس کن.')
l.image('clock','clock_face',960,600,scale=[1.6,1.6]); l.image('hands','clock_hands',960,600,['tap'],scale=[1.6,1.6],z_index=2)
l.drag('car','toy_car',450,850); l.image('photo','clock_face',1480,760,[dict(type='swipe',direction='right')],scale=[.7,.7])
l.rule('drag_end','car',[move('car',450,850)])
l.rule('swipe','photo',[replace('photo','alarm_clock')])
l.win('tap','hands',[act('rotate','hands',degrees=90)]); l.save()

l=Level(35,'نام چیزهای سفره را در نظر بگیر؛ همهٔ آن‌ها جزو هفت سین نیستند.')
l.image('mat','woven_mat',960,650,scale=[5,3],z_index=-3)
for id,sprite,x,y,label in [('apple','apple',520,520,'سیب'),('garlic','garlic',810,520,'سیر'),('sprouts','green_sprouts',1100,520,'سبزه'),('vinegar','bottle',1400,520,'سرکه'),('sumac','sumac_bowl',520,790,'سماق'),('oleaster','oleaster_bowl',810,790,'سنجد'),('samanu','samanu_bowl',1100,790,'سمنو')]:
    l.image(id,sprite,x,y,['hold'] if id=='samanu' else ['tap'],scale=[.65,.65]); l.text(id+'_name',label,x,y+85)
l.image('fish','goldfish_bowl',1400,780,['tap'])
l.image('samanu_lid','bowl_lid',1100,750,scale=[.65,.65])
l.image('flower','hyacinth',1670,640,[dict(type='swipe',direction='up')])
l.rule('hold','samanu',[hide('samanu_lid'),feedback('samanu')]); l.rule('swipe','flower',[feedback('flower')]); l.win('tap','fish',[feedback('fish')]); l.save()

l=Level(36,'هر سه انار را وزن کن و بعد سبک‌ترین را لمس کن.')
l.variable(weighed_a=False,weighed_b=False,weighed_c=False)
l.image('scale','weighing_scale',960,550); l.zone('pan',960,550,['fruit_a','fruit_b','fruit_c'])
for i,letter in enumerate('abc'):
    x=550+i*400
    l.drag('fruit_'+letter,'pomegranate',x,820,extra=['tap'],scale=[.8,.8])
    l.image('weight_'+letter,'selection_check',x,690,visible=False,scale=[.4,.4])
    l.text('reading_'+letter,'۶۰ گرم' if letter=='c' else '۱۰۰ گرم',960,420,visible=False)
    l.drop('fruit_'+letter,'pan',[*[hide('reading_'+other) for other in 'abc'],show('reading_'+letter),show('weight_'+letter),act('rotate','scale',degrees=3 if letter=='c' else 9),move('fruit_'+letter,x,820),setv('weighed_'+letter)])
l.drag('ribbon','ribbon',300,770,scale=[.6,.6]); l.zone('base',960,690,['ribbon'])
l.drop('ribbon','base',[move('ribbon',300,770),feedback('ribbon')]); l.image('hammer','hammer',1630,780,['tap'],scale=[.65,.65]); l.rule('tap','hammer',[sound(),feedback('hammer')])
l.win('tap','fruit_c',conditions=[var('weighed_'+a) for a in 'abc']); l.save()

l=Level(37,'قالیچه‌ها را کنار بکش؛ دریچهٔ آشکارشده را لمس کن.')
l.image('hatch','floor_hatch',960,600,['tap'],visible=False)
for i in range(3):
    x=480+i*480; l.drag('rug_'+str(i),'woven_mat',x,600,bounds=(220,480,1450,400),scale=[1.4,1.4])
    l.d['objects'][-1]['interactions'][0]['return_on_invalid']=False
    l.rule('drag_end','rug_'+str(i),[move('rug_'+str(i),x,830)]+([show('hatch')] if i==1 else []),[dict(type='moved_distance_at_least',value=150)])
l.drag('doormat','woven_mat',300,890,scale=[.6,.6]); l.rule('drag_end','doormat',[move('doormat',450,900)])
l.image('dust','dust_motes',1510,900,scale=[.5,.5])
l.image('broom','broom',1600,850,[dict(type='swipe',direction='right')]); l.rule('swipe','broom',[hide('dust'),feedback('broom')]); l.win('tap','hatch'); l.save()

l=Level(38,'دندانه‌های کلید را با شیار روی صندوق مقایسه کن.')
l.image('chest','chest_closed',960,560,scale=[1.2,1.2]); l.image('profile','key_profile',960,690,scale=[.8,.8]); l.zone('lock',960,560,['key_a','key_b','key_c'])
for i,letter in enumerate('abc'):
    x=550+i*400; l.drag('key_'+letter,'toothed_key_'+letter,x,850)
    if letter=='b': l.win('drop_on','key_b',[hide('key_b'),replace('chest','chest_open')],target='lock')
    else: l.drop('key_'+letter,'lock',[move('key_'+letter,x,850),feedback('chest')])
l.image('shine','camera_flash',1150,550,visible=False,scale=[.5,.5])
l.drag('oil','bottle',300,720,scale=[.6,.6]); l.zone('hinge',1150,550,['oil']); l.drop('oil','hinge',[move('oil',300,720),show('shine'),act('play_animation','shine',animation='chapter_two/flash',wait=False)])
l.image('handle','chest_handle',1600,720,['hold']); l.rule('hold','handle',[feedback('handle')]); l.save()

l=Level(39,'درِ سماورها را نگه دار؛ بعد سماوری را انتخاب کن که بخار آزاد می‌کند.')
l.variable(hot_seen=False)
for i,x in enumerate([520,960,1400]):
    l.image('samovar_'+str(i),'samovar',x,650,['hold','tap'])
    l.image('steam_'+str(i),'steam_plume',x,470,visible=False)
    l.rule('hold','samovar_'+str(i),[show('steam_1'),setv('hot_seen')] if i==1 else [feedback('samovar_'+str(i))])
l.image('glass','cup',350,860,['tap']); l.image('glass_steam','steam_plume',350,750,scale=[.5,.5])
l.rule('tap','glass',[hide('glass_steam')]); l.drag('cloth','towel_dry',1550,860,scale=[.6,.6]); l.image('tray_image','test_tray',1220,900,scale=[.65,.65]); l.image('stain','dust_motes',1220,900,scale=[.5,.5]); l.zone('tray',1220,900,['cloth']); l.drop('cloth','tray',[move('cloth',1550,860),hide('stain'),feedback('cloth')])
l.win('tap','samovar_1',conditions=[var('hot_seen')]); l.save()

l=Level(40,'کوزه‌ها را با حرکت سریع تکان بده؛ موج آب را ببین و همان کوزه را لمس کن.')
l.variable(water_seen=False)
for i,x in enumerate([520,960,1400]):
    l.image('jug_'+str(i),'water_jug',x,630,['swipe','tap'])
    l.image('waves_'+str(i),'milk_ripple',x,480,visible=False,scale=[.5,.5])
    l.rule('swipe','jug_'+str(i),[feedback('jug_'+str(i))]+([show('waves_2'),dict(type='play_sound',sound=P+'water_slosh.wav',wait=False),setv('water_seen')] if i==2 else []))
l.image('pebbles','shopping_bag',350,850,['hold'],scale=[.65,.65]); l.rule('hold','pebbles',[sound(),feedback('pebbles')])
l.image('pebble_a','stone',330,830,scale=[.25,.25]); l.image('pebble_b','stone',370,850,scale=[.2,.2])
l.image('lid','bottle_cap',1570,840,['tap']); l.rule('tap','lid',[act('rotate','lid',degrees=45)])
l.win('tap','jug_2',conditions=[var('water_seen')]); l.save()

l=Level(41,'قفل جلو لازم نیست باز شود؛ قفس را کنار بکش و پشت آن را ببین.')
l.image('bird','bird_perched',960,640,scale=[.6,.6]); l.drag('cage','bird_cage',960,610,bounds=(650,460,800,400),scale=[1.5,1.5])
l.image('lock','closed_padlock',960,740,scale=[.3,.3]); l.zone('front_lock',960,740,['key'],size=(130,100)); l.drag('key','toothed_key_a',450,820,scale=[.7,.7])
l.drop('key','front_lock',[move('key',450,820),feedback('lock')]); l.image('seed','seed_bowl',1500,830,['tap'],scale=[.6,.6]); l.rule('tap','seed',[feedback('bird')])
l.win('drag_end','cage',[move('cage',1320,620),move('lock',1320,750),replace('cage','cage_back_open'),move('bird',650,520)],[dict(type='moved_distance_at_least',value=200)]); l.save()

# 42: two explicit phases; premature cards always return to their tray.
l=Level(42,'یک کلید را ۳ ثانیه نگه دار و خاموش کن؛ دیگری را روشن بگذار. داخل اتاق نور و گرما را مقایسه کن.','room_lighting')
l.d['question']='با یک بار ورود، کلید هر لامپ را پیدا کن.'
l.variable(entered=False,toggled=False, switch_0=False,switch_1=False,switch_2=False,warm_0=False,warm_1=False,warm_2=False, inspected_0=False,inspected_1=False,inspected_2=False,map_0=False,map_1=False,map_2=False,assigned_0=False,assigned_1=False,assigned_2=False)

def stage42_text(id,text,x,y,width=1440,height=80,visible=True,inputs=()):
    l.text(id,text,x,y,inputs,visible=visible)
    l.d['objects'][-1]['hit_size']=[width,height]

def stage42_button(id,text,x,y,visible=True):
    stage42_text(id,text,x,y,300,110,visible,['tap'])
    l.d['objects'][-1]['sprite']=P+'puzzle_tile.svg'

stage42_text('phase_outside','۱. بیرون اتاق: کلیدها را آماده کن',960,350,height=60)
stage42_text('instructions','سه لامپ رشته‌ای داخل اتاق‌اند. لمس کلید: روشن/خاموش\n۳ ثانیه نگه‌داشتن: ۵ دقیقه روشن‌بودن و گرم‌شدن',960,420,height=100)
stage42_text('phase_inside','۲. داخل اتاق: لامپ‌ها را بررسی و کلیدها را مشخص کن',960,350,height=60,visible=False)
stage42_text('inside_help','هر لامپ را لمس کن تا نور و گرمایش معلوم شود.\nسپس کارت کلید مربوط را از پایین روی همان لامپ بکش و تأیید کن.',960,420,height=100,visible=False)
stage42_text('entry_warning','با این تنظیم، سه لامپ از هم قابل تشخیص نیستند؛ کلیدها را دوباره تنظیم کن.',960,1010,height=90,visible=False)
stage42_text('visit_note','فقط یک بار وارد می‌شوی؛ پس از ورود دیگر به کلیدها دسترسی نداری.',960,1010,height=70)
warnings=['inspect_first','missing_mapping','wrong_mapping']
stage42_text('inspect_first','اول لامپ را لمس کن، سپس کارت کلید را روی آن بکش.',900,1020,1050,65,False)
stage42_text('missing_mapping','هنوز برای هر سه لامپ کلید انتخاب نکرده‌ای.',900,1020,1050,65,False)
stage42_text('wrong_mapping','تطبیق درست نیست؛ نور و گرما را با وضعیت کلیدها مقایسه کن.',900,1020,1050,65,False)
evidence=dict(type='any',conditions=[dict(type='all',conditions=[var('switch_'+str(on)),var('switch_'+str(warm),False),var('warm_'+str(warm)),var('switch_'+str(cold),False),var('warm_'+str(cold),False)]) for on in range(3) for warm in range(3) for cold in range(3) if len({on,warm,cold})==3])
for i,x in enumerate([520,960,1400]):
    sid='switch_'+str(i)
    l.image(sid,'wall_switch',x,570,['tap',dict(type='hold',duration=3)])
    stage42_text('switch_name_'+str(i),'کلید '+str(i+1),x,705,300,60)
    stage42_text('off_'+str(i),'خاموش',x,765,300,60)
    stage42_text('on_'+str(i),'روشن',x,765,300,60,False)
    stage42_text('heat_ready_'+str(i),'گرما ذخیره شد',x,825,300,60,False)
    off_actions=[setv(sid,False),setv('toggled'),act('rotate',sid,degrees=0),show('off_'+str(i)),hide('on_'+str(i)),hide('entry_warning'),show('visit_note')]
    on_actions=[setv(sid),act('rotate',sid,degrees=180),hide('off_'+str(i)),show('on_'+str(i)),hide('entry_warning'),show('visit_note')]
    l.rule('tap',sid,off_actions,[var('entered',False),var(sid)])
    l.rule('tap',sid,on_actions,[var('entered',False),var(sid,False),var('toggled',False)])
    l.rule('tap',sid,[setv('toggled',False)])
    l.rule('hold',sid,[*on_actions,setv('warm_'+str(i)),show('heat_ready_'+str(i))],[var('entered',False)])
stage42_button('enter','ورود به اتاق',960,920)
l.rule('tap','enter',[hide('visit_note'),show('entry_warning')],[var('entered',False),dict(type='not',condition=evidence)])
enter_actions=[setv('entered'),hide('enter'),hide('instructions'),hide('phase_outside'),hide('visit_note'),hide('entry_warning'),show('phase_inside'),show('inside_help'),show('confirm')]
for i in range(3):
    enter_actions += [hide('switch_'+str(i)),hide('switch_name_'+str(i)),hide('on_'+str(i)),hide('off_'+str(i)),hide('heat_ready_'+str(i)),show('lamp_'+str(i)),show('lamp_name_'+str(i)),show('choice_'+str(i)),show('lamp_target_'+str(i)),show('unassigned_'+str(i))]
l.rule('tap','enter',enter_actions,[var('entered',False),evidence],once=True)
# Wiring is fixed, but any warm/lit/cold preparation can establish the evidence.
for bulb,switch in enumerate([1,2,0]):
    x=520+440*bulb
    l.image('lamp_target_'+str(bulb),'puzzle_tile',x,570,scale=[1.1,2.0],visible=False,z_index=-2)
    l.image('lamp_'+str(bulb),'bulb_cold',x,570,['tap'],visible=False)
    stage42_text('lamp_name_'+str(bulb),'لامپ '+str(bulb+1),x,705,300,60,False)
    l.image('heat_'+str(bulb),'heat_lines',x+150,570,scale=[.65,.65],visible=False)
    for state,text in [('cold','خاموش و سرد'),('light','روشن'),('warm','خاموش و گرم')]:
        stage42_text(state+'_'+str(bulb),text,x,765,300,60,False)
    stage42_text('unassigned_'+str(bulb),'کلید: انتخاب نشده',x,825,300,60,False)
    l.card('choice_'+str(bulb),'کلید '+str(bulb+1),x,910)
    l.d['objects'][-1].update(visible=False,z_index=5)
    l.d['objects'][-1]['interactions'][0]['bounds']=[200,490,1520,450]
    l.zone('lamp_zone_'+str(bulb),x,570,['choice_0','choice_1','choice_2'],size=(310,240))
    l.rule('tap','lamp_'+str(bulb),[replace('lamp_'+str(bulb),'bulb_lit'),show('light_'+str(bulb)),setv('inspected_'+str(bulb)),hide('inspect_first')],[var('entered'),var('switch_'+str(switch))])
    l.rule('tap','enter',[replace('lamp_'+str(bulb),'bulb_lit')],[var('entered'),var('switch_'+str(switch))])
    l.rule('tap','lamp_'+str(bulb),[show('heat_'+str(bulb)),show('warm_'+str(bulb)),setv('inspected_'+str(bulb)),hide('inspect_first')],[var('entered'),var('switch_'+str(switch),False),var('warm_'+str(switch))])
    l.rule('tap','lamp_'+str(bulb),[show('cold_'+str(bulb)),setv('inspected_'+str(bulb)),hide('inspect_first')],[var('entered'),var('switch_'+str(switch),False),var('warm_'+str(switch),False)])
    for card in range(3):
        label=f'mapping_{bulb}_{card}'
        stage42_text(label,'انتخاب: کلید '+str(card+1),x,825,300,60,False)
        l.drop('choice_'+str(card),'lamp_zone_'+str(bulb),[setv('assigned_'+str(bulb)),setv('map_'+str(bulb),card==switch),hide('unassigned_'+str(bulb)),*[hide(f'mapping_{bulb}_{other}') for other in range(3)],show(label),*[hide(warning) for warning in warnings]],[var('entered'),var('inspected_'+str(bulb))])
        l.drop('choice_'+str(card),'lamp_zone_'+str(bulb),[hide('missing_mapping'),hide('wrong_mapping'),show('inspect_first')],[var('entered'),var('inspected_'+str(bulb),False)])
        # A valid Drop with unmet evidence must not leave a card covering the bulb.
        l.drop('choice_'+str(card),'lamp_zone_'+str(bulb),[move('choice_'+str(card),520+440*card,910)])
stage42_button('confirm','تأیید پاسخ',1740,1015,False)
all_seen=dict(type='all',conditions=[var('inspected_'+str(i)) for i in range(3)])
all_assigned=dict(type='all',conditions=[var('assigned_'+str(i)) for i in range(3)])
all_correct=dict(type='all',conditions=[var('map_'+str(i)) for i in range(3)])
l.rule('tap','confirm',[*[hide(warning) for warning in warnings],show('inspect_first')],[dict(type='not',condition=all_seen)])
l.rule('tap','confirm',[*[hide(warning) for warning in warnings],show('missing_mapping')],[all_seen,dict(type='not',condition=all_assigned)])
l.rule('tap','confirm',[*[hide(warning) for warning in warnings],show('wrong_mapping')],[all_seen,all_assigned,dict(type='not',condition=all_correct)])
l.win('tap','confirm',conditions=[all_seen,all_assigned,all_correct])
l.image('torch','flashlight',200,820,['hold'],scale=[.5,.5])
l.image('local_light','camera_flash',200,700,visible=False,scale=[.5,.5])
l.rule('hold','torch',[show('local_light'),act('play_animation','local_light',animation='chapter_two/flash',wait=False)])
l.drag('color_label','day_card',1730,560,scale=[.35,.35])
l.d['objects'][-1]['interactions'][0]['bounds']=[250,490,1530,420]
l.zone('guess',1730,800,['color_label'],size=(180,100))
stage42_text('guess_label','حدس رنگی',1730,800,180,100)
l.drop('color_label','guess',[move('color_label',1730,560),feedback('color_label')])
l.save()

# 43: select a vessel, then choose one of three explicit operations.
# New transparent vessels expose volume; the older opaque jug stays unchanged.
for capacity in [5,3]:
    for volume in range(capacity+1):
        height=210*volume/capacity
        fill=(f'<rect x="57" y="{278-height}" width="184" height="{height}" fill="#75bdd2"/>'
              f'<path d="M60 {278-height}Q95 {268-height} 130 {278-height}T238 {278-height}" fill="none" stroke="#cceef0" stroke-width="4"/>') if volume else ''
        ticks=''.join(f'<path d="M72 {278-210*n/capacity}h23"/>' for n in range(1,capacity+1))
        svg(f'measuring_jug_{capacity}_{volume}',
            '<defs><clipPath id="interior"><path d="M57 48H241V259Q241 278 222 278H76Q57 278 57 259Z"/></clipPath></defs>'
            '<path d="M54 32H247L270 53H247V263Q247 290 220 290H75Q45 290 45 263V32Z" fill="#ecf5ea"/>'
            f'<g clip-path="url(#interior)" stroke="none">{fill}</g>'
            '<path d="M247 88H279Q307 88 307 119V186Q307 217 279 217H247" fill="none" stroke="#7c9f9c" stroke-width="10"/>'
            '<path d="M54 32H247L270 53H247V263Q247 290 220 290H75Q45 290 45 263V32Z" fill="none" stroke="#739794"/>'
            f'<g stroke="#527d7d" stroke-width="3">{ticks}</g>'
            '<path d="M111 55V262" stroke="#ffffff" stroke-width="10" opacity=".5"/>',320,320)
svg('faucet_fill','<path d="M52 174V75Q52 44 83 44H165V104H110V174Z" fill="#a7c9c3"/><path d="M80 44V21M52 20H111" fill="none" stroke-width="12"/><path d="M145 117q-17 25 0 25t0-25m0 39q-17 25 0 25t0-25" fill="#7abbd1" stroke="#649aa9"/>',200,200)
svg('sink_drain','<ellipse cx="100" cy="110" rx="84" ry="58" fill="#b4c7c0"/><ellipse cx="100" cy="110" rx="54" ry="36" fill="#677e7a"/><path d="M60 93h80m-89 19h98m-83 18h68M83 78v65m32-65v65" stroke="#d1ded0" stroke-width="5"/>',200,200)

l=Level(43,'۵ لیتری را پر کن و با آن ۳ لیتری را پر کن. ۳ لیتری را خالی کن و ۲ لیترِ باقی‌مانده را در آن بریز. دوباره ۵ لیتری را پر کن؛ حالا برای پرکردن ۳ لیتری فقط ۱ لیتر لازم است.')
l.variable(five=0,three=0,selected='',next_five=0,next_three=0,transferred=False)
l.note('۱. ظرف را لمس کن. ۲. دکمهٔ پرکردن، خالی‌کردن یا ریختن را بزن.')
messages={
    'choose_first':'اول یکی از دو ظرف را لمس کن.',
    'filled':'ظرف انتخاب‌شده از شیر پر شد.',
    'emptied':'ظرف انتخاب‌شده خالی شد.',
    'poured':'آب تا پرشدن ظرف دیگر یا خالی‌شدن ظرف انتخابی ریخته شد.',
    'source_empty':'ظرف انتخاب‌شده خالی است؛ اول آن را پر کن.',
    'destination_full':'ظرف دیگر پر است؛ اول آن را خالی کن.',
    'already_full':'ظرف انتخاب‌شده از قبل پر است.',
    'already_empty':'ظرف انتخاب‌شده از قبل خالی است.',
    'invalid_measure':'خط‌های این پیمانه معتبر نیست؛ از دو ظرف اصلی استفاده کن.',
    'height_only':'خط‌کش ارتفاع را نشان می‌دهد؛ حجم با ارتفاع یکی نیست.',
}
for id,text in messages.items():
    l.text(id,text,960,1035,visible=False)
    l.d['objects'][-1]['hit_size']=[1500,65]

def stage43_message(id):
    return [*[hide(other) for other in messages],show(id)]

for name,capacity,x in [('five',5,680),('three',3,1220)]:
    other='three' if name=='five' else 'five'
    l.text(name+'_title','ظرف '+str(capacity)+' لیتری',x,450)
    l.image(name,f'measuring_jug_{capacity}_0',x,630,['tap'])
    l.image(name+'_selected','selection_check',x-185,520,visible=False)
    l.text(name+'_selected_label','انتخاب‌شده',x,870,visible=False)
    l.d['objects'][-1]['hit_size']=[300,50]
    l.rule('tap',name,[setv('selected',name),show(name+'_selected'),show(name+'_selected_label'),hide(other+'_selected'),hide(other+'_selected_label'),*[hide(id) for id in messages]])
    for n in range(capacity+1):
        l.text(name+'_reading_'+str(n),str(n)+' از '+str(capacity)+' لیتر',x,805,visible=n==0)
        l.rule('variable_changed','$level',[replace(name,f'measuring_jug_{capacity}_{n}'),*[hide(name+'_reading_'+str(k)) for k in range(capacity+1)],show(name+'_reading_'+str(n))],[var(name,n)])
    # No-op feedback comes first, so a real fill/empty keeps its own message.
    l.rule('tap','fill',stage43_message('already_full'),[var('selected',name),var(name,capacity)])
    l.rule('tap','empty',stage43_message('already_empty'),[var('selected',name),var(name,0)])
    l.rule('tap','fill',[setv(name,capacity),*stage43_message('filled')],[var('selected',name),var(name,capacity,'lt')])
    l.rule('tap','empty',[setv(name,0),*stage43_message('emptied')],[var('selected',name),var(name,0,'gt')])
    l.rule('tap','pour',stage43_message('source_empty'),[var('selected',name),var(name,0)])
    l.rule('tap','pour',stage43_message('destination_full'),[var('selected',name),var(name,0,'gt'),var(other,3 if name=='five' else 5)])

for id,text,x in [('fill','پرکردن از شیر',500),('empty','خالی‌کردن',960),('pour','ریختن در ظرف دیگر',1420)]:
    l.text(id,text,x,960,['tap'])
    l.d['objects'][-1].update(sprite=P+'puzzle_tile.svg',hit_size=[300,110])
    l.rule('tap',id,stage43_message('choose_first'),[var('selected','')])
for a in range(6):
    for b in range(4):
        for src,amount in [('five',min(a,3-b)),('three',min(b,5-a))]:
            if amount:
                na,nb=(a-amount,b+amount) if src=='five' else (a+amount,b-amount)
                l.rule('tap','pour',[setv('next_five',na),setv('next_three',nb),setv('transferred')],[var('selected',src),var('five',a),var('three',b),var('transferred',False)])
for a in range(6):
    for b in range(4):
        l.rule('tap','pour',[setv('five',a),setv('three',b)],[var('transferred'),var('next_five',a),var('next_three',b)])
l.rule('tap','pour',stage43_message('poured'),[var('transferred')])
l.rule('tap','pour',[setv('transferred',False)])
l.image('tap','faucet_fill',300,540,scale=[.8,.8]); l.zone('tap_zone',300,540,['measure'],size=(200,160))
l.text('tap_label','شیر آب',300,665)
l.image('drain','sink_drain',1660,540,scale=[.8,.8]); l.text('drain_label','تخلیه',1660,665)
l.drag('measure','decorative_measure',280,800,scale=[.7,.7])
l.drop('measure','tap_zone',[move('measure',280,800),feedback('measure'),*stage43_message('invalid_measure')])
l.image('ruler','height_ruler',1660,800,['hold'],scale=[.75,.75])
l.rule('hold','ruler',[feedback('ruler'),*stage43_message('height_only')])
l.win('variable_changed','$level',conditions=[var('five',4)])
l.save()

# 44: explicit count buttons reveal both inclusive ranges; no hidden Drop targets.
svg('queue_count_front','<rect x="4" y="4" width="54" height="122" rx="14" fill="#b1d9ca" fill-opacity=".6" stroke="#66998c" stroke-width="3"/>',62,130)
svg('queue_count_back','<rect x="4" y="4" width="54" height="122" rx="14" fill="#ead2ab" fill-opacity=".6" stroke="#b69a70" stroke-width="3"/>',62,130)
svg('queue_target','<rect x="4" y="4" width="70" height="138" rx="18" fill="#f5e2ad" stroke="#a98242" stroke-width="5"/>',78,146)
svg('queue_flag','<path d="M30 22v166m0-153q64-27 116 4v75q-52-31-116-4" fill="#d2a165"/><path d="M12 190h52" fill="none"/>',170,200)
l=Level(44,'خودت در هر دو شمارش آمده‌ای؛ ۱۰ و ۱۵ را جمع کن و یک نفر مشترک را کم کن.','stream_garden_background_light')
l.variable(front=False,back=False)
l.note('۱. دو دکمهٔ شمارش را لمس کن. ۲. تعداد کل افراد صف را از پایین انتخاب کن.')

def stage44_text(id,text,x,y,width=300,height=60,visible=True,inputs=()):
    l.text(id,text,x,y,inputs,visible=visible)
    l.d['objects'][-1]['hit_size']=[width,height]

def stage44_button(id,text,x,y):
    stage44_text(id,text,x,y,300,110,True,['tap'])
    l.d['objects'][-1]['sprite']=P+'puzzle_tile.svg'

stage44_text('front_label','جلوی صف',270,460,180)
stage44_text('back_label','پشت صف',1650,460,180)
stage44_text('you_label','شما',810,460,130)
l.image('front_arrow','left_arrow',180,620,scale=[.5,.5],rotation_degrees=180)
l.image('back_arrow','left_arrow',1740,620,scale=[.5,.5])
for i in range(24):
    x=270+60*i
    if i<=9:
        l.image('front_mark_'+str(i),'queue_count_front',x,620,visible=False,z_index=-3)
        stage44_text('front_number_'+str(i),str(i+1),x,540,60,50,False)
    if i>=9:
        l.image('back_mark_'+str(i),'queue_count_back',x,620,visible=False,z_index=-2)
        stage44_text('back_number_'+str(i),str(24-i),x,700,60,50,False)
    if i==9:
        l.image('target_mark','queue_target',x,620,z_index=-1)
    l.image('person_'+str(i),'walking_person',x,620,scale=[.28,.28])
stage44_text('front_check','با شما: ۱۰ نفر',550,460,340,60,False)
stage44_text('back_check','با شما: ۱۵ نفر',1370,460,340,60,False)
stage44_text('answer_label','تعداد کل افراد صف؟',960,850,450)
stage44_text('shared_note','نشان «شما» در هر دو شمارش حضور دارد.',960,760,1000,50,False)
stage44_text('count_first','ابتدا هر دو دکمهٔ شمارش را لمس کن.',960,1030,1400,65,False)
stage44_text('wrong_answer','فرد مشترک را دوبار شمرده‌ای؛ نشان «شما» را در دو شمارش ببین.',960,1030,1400,65,False)
stage44_text('flag_feedback','جابه‌جایی پرچم، جای افراد صف را عوض نمی‌کند.',960,1030,1400,65,False)
for id,text,x in [('front_counter','شمارش از جلو',550),('back_counter','شمارش از عقب',1370)]:
    stage44_button(id,text,x,840)
front_actions=[setv('front'),show('front_check'),hide('count_first'),hide('wrong_answer'),hide('flag_feedback')]
back_actions=[setv('back'),show('back_check'),hide('count_first'),hide('wrong_answer'),hide('flag_feedback')]
for i in range(10): front_actions += [show('front_mark_'+str(i)),show('front_number_'+str(i))]
for i in range(9,24): back_actions += [show('back_mark_'+str(i)),show('back_number_'+str(i))]
l.rule('tap','front_counter',front_actions)
l.rule('tap','back_counter',back_actions)
counted=dict(type='all',conditions=[var('front'),var('back')])
for id in ['front_counter','back_counter']:
    l.rule('tap',id,[show('shared_note')],[counted])
stage44_button('answer24','۲۴ نفر',750,950)
stage44_button('answer25','۲۵ نفر',1170,950)
l.rule('tap','answer24',[show('count_first'),hide('wrong_answer'),hide('flag_feedback')],[dict(type='not',condition=counted)])
l.rule('tap','answer25',[show('wrong_answer'),hide('count_first'),hide('flag_feedback')])
l.win('tap','answer24',[hide('count_first'),hide('wrong_answer'),hide('flag_feedback')],[counted])
l.drag('flag','queue_flag',1670,930,bounds=(1550,820,220,170),scale=[.5,.5])
l.rule('drag_end','flag',[move('flag',1670,930),hide('count_first'),hide('wrong_answer'),show('flag_feedback')])
l.save()

# 45: fixed day displays with previous/next controls, rather than movable cards.
def fixed_text(id,text,x,y,width=300,height=70,visible=True,inputs=()):
    l.text(id,text,x,y,inputs,visible=visible)
    l.d['objects'][-1]['hit_size']=[width,height]

def fixed_button(id,text,x,y,small=False):
    fixed_text(id,text,x,y,160 if small else 300,110,True,['tap'])
    l.d['objects'][-1]['sprite']=P+('stepper_button.svg' if small else 'puzzle_tile.svg')

def cycle_control(source,name,amount,size):
    # The latch prevents a changed value matching another rule on this same tap.
    for old in range(size):
        l.rule('tap',source,[setv(name,(old+amount)%size),setv('adjusted')],[var(name,old),var('adjusted',False)])
    l.rule('tap',source,[setv('adjusted',False)])

l=Level(45,'فردای شنبه، یکشنبه است؛ دیروز را یکشنبه بگذار و امروز را یک روز جلوتر تنظیم کن.')
l.variable(yesterday=0,today=0,adjusted=False)
l.note('با فلش‌های روز قبل و روز بعد، «دیروز» و «امروز» را تنظیم کن؛ سپس تأیید کن.')
days=['شنبه','یکشنبه','دوشنبه','سه‌شنبه','چهارشنبه','پنجشنبه','جمعه']
fixed_text('reference_label','روز مرجع',520,435,300,60)
l.image('reference_page','calendar_page',520,580,scale=[.5,.5])
fixed_text('saturday','شنبه',520,590)
for name,x,label in [('yesterday',960,'دیروز'),('today',1400,'امروز')]:
    fixed_text(name+'_label',label,x,435,300,60)
    l.image(name+'_page','calendar_page',x,580,scale=[.5,.5])
    for i,day in enumerate(days):
        fixed_text(name+'_day_'+str(i),day,x,590,240,70,i==0)
        l.rule('variable_changed','$level',[*[hide(name+'_day_'+str(n)) for n in range(7)],show(name+'_day_'+str(i)),hide('yesterday_error'),hide('today_error'),hide('clock_feedback')],[var(name,i)])
    for suffix,amount,dx,rotation in [('previous',-1,-110,0),('next',1,110,180)]:
        source=name+'_'+suffix
        l.image(source,'left_arrow',x+dx,755,['tap'],rotation_degrees=rotation,hit_size=[180,110])
        fixed_text(source+'_label','روز قبل' if amount<0 else 'روز بعد',x+dx,845,180,55)
        cycle_control(source,name,amount,7)
l.image('relation_arrow','left_arrow',740,580,scale=[.5,.5],rotation_degrees=180)
l.image('next_day_arrow','left_arrow',1180,580,scale=[.5,.5],rotation_degrees=180)
fixed_text('yesterday_error','دیروز باید فردای شنبه باشد؛ روزِ دیروز را اصلاح کن.',960,1030,1450,65,False)
fixed_text('today_error','امروز باید یک روز بعد از دیروز باشد.',960,1030,1450,65,False)
fixed_text('clock_feedback','چرخاندن ساعت، روز هفته را تغییر نمی‌دهد.',960,1030,1450,65,False)
fixed_button('confirm','تأیید روزها',960,945)
l.rule('tap','confirm',[show('yesterday_error'),hide('today_error'),hide('clock_feedback')],[var('yesterday',1,'ne')])
l.rule('tap','confirm',[show('today_error'),hide('yesterday_error'),hide('clock_feedback')],[var('yesterday',1),var('today',2,'ne')])
l.win('tap','confirm',[hide('yesterday_error'),hide('today_error'),hide('clock_feedback')],[var('yesterday',1),var('today',2)])
l.image('clock','clock_face',300,825,['tap'],scale=[.6,.6])
l.rule('tap','clock',[act('rotate','clock',degrees=90),show('clock_feedback'),hide('yesterday_error'),hide('today_error')])
l.save()

# 46 retains its existing authored drag interaction.
for number,sequence,correct,wrong,hint in [(46,'۲، ۶، ۱۲، ۲۰، ۳۰، ؟','۴۲','۴۰','هر جمله حاصل ضرب دو عدد پیاپی است.')]:
    l=Level(number,hint); l.text('sequence',sequence,960,470); l.d['objects'][-1]['hit_size']=[1100,80]
    l.zone('answer',1320,620,['right','wrong','other']); l.text('blank','؟',1320,620)
    l.card('right',correct,650,820); l.card('wrong',wrong,960,820); l.card('other','۵۴' if number==47 else '۴۴',1270,820)
    l.win('drop_on','right',[move('right',1320,620),hide('blank')],target='answer')
    for id,x in [('wrong',960),('other',1270)]: l.drop(id,'answer',[move(id,x,820),feedback(id)])
    if number==46:
        l.text('decoy','جدول جمع ۱۰',400,660,['hold']); l.text('decoy_result','۳۰ + ۱۰ = ۴۰',400,750,visible=False); l.rule('hold','decoy',[show('decoy_result')])
    l.save()

# 47: reveal differences and enter the answer with two digit steppers.
svg('stepper_button','<rect x="6" y="6" width="138" height="98" rx="18" fill="#f5e9cc"/><path d="M22 24H128" stroke="#d1b078"/>',150,110)
l=Level(47,'اختلاف جمله‌های پشت سر هم ۳، ۵، ۷ و ۹ است؛ اختلاف بعدی دو واحد بیشتر می‌شود.')
l.variable(tens=0,units=0,adjusted=False)
l.note('فاصله‌های بین عددها را لمس کن؛ پاسخ را با دکمه‌های + و − بساز و تأیید کن.')
fixed_text('sequence','۳، ۶، ۱۱، ۱۸، ۲۷، ؟',960,440,1250,80)
for i,(x,difference) in enumerate([(540,3),(800,5),(1060,7),(1320,9)]):
    fixed_button('difference_'+str(i),'+ ؟',x,550,True)
    fixed_text('diff_value_'+str(i),'+'+str(difference),x,550,160,110,False)
    l.rule('tap','difference_'+str(i),[hide('difference_'+str(i)),show('diff_value_'+str(i))])
fixed_text('entry_label','عدد بعدی را وارد کن',960,665,700,60)
for name,x,label in [('tens',700,'دهگان'),('units',1250,'یکان')]:
    fixed_text(name+'_label',label,x,720,250,50)
    for n in range(10):
        fixed_text(name+'_digit_'+str(n),str(n),x,810,120,80,n==0)
        l.rule('variable_changed','$level',[*[hide(name+'_digit_'+str(k)) for k in range(10)],show(name+'_digit_'+str(n)),hide('wrong_difference'),hide('wrong_rule')],[var(name,n)])
    for suffix,amount,dx in [('minus',-1,-180),('plus',1,180)]:
        source=name+'_'+suffix
        fixed_button(source,'−' if amount<0 else '+',x+dx,810,True)
        cycle_control(source,name,amount,10)
fixed_button('confirm','تأیید عدد',960,940)
fixed_text('wrong_difference','اختلاف قبلی را تکرار نکن؛ اختلاف‌ها هر بار دو واحد بیشتر می‌شوند.',960,1030,1450,65,False)
fixed_text('wrong_rule','این عدد با اختلاف‌های دنباله سازگار نیست؛ فاصله‌ها را بررسی کن.',960,1030,1450,65,False)
is_36=dict(type='all',conditions=[var('tens',3),var('units',6)])
is_38=dict(type='all',conditions=[var('tens',3),var('units',8)])
l.rule('tap','confirm',[show('wrong_difference'),hide('wrong_rule')],[is_36])
l.rule('tap','confirm',[show('wrong_rule'),hide('wrong_difference')],[dict(type='not',condition=is_36),dict(type='not',condition=is_38)])
l.win('tap','confirm',[hide('wrong_rule'),hide('wrong_difference')],[is_38])
fixed_text('double','دوبرابرکردن',1650,860,250,110,True,[dict(type='swipe',direction='right')])
fixed_text('double_result','۲۷ × ۲ = ۵۴',1650,965,260,80,False)
l.rule('swipe','double',[show('double_result')])
l.save()

# 48: count the living animals directly; each animal contributes at most once.
l=Level(48,'«همه به‌جز ۹ تا» یعنی ۹ گوسفند زنده‌اند؛ فقط گوسفندهای ایستاده را بشمار.')
l.variable(removed=0,living=0,**{'counted_'+str(i):False for i in range(9)})
l.note('هر گوسفند زنده را یک‌بار لمس کن تا علامت بخورد؛ سپس شمارش را تأیید کن.')
messages48={
    'incomplete':'هنوز همهٔ گوسفندهای زنده را علامت نزده‌ای.',
    'already_counted':'این گوسفند قبلاً شمرده شده است.',
    'dead_feedback':'این گوسفند زنده نیست؛ به شمارش زنده‌ها اضافه نمی‌شود.',
    'wrong_eight':'۸ تعداد گوسفندهای مرده است؛ گوسفندهای زنده را بشمار.',
    'gate_feedback':'باز و بسته‌شدن در، تعداد گوسفندها را تغییر نمی‌دهد.',
}
for id,text in messages48.items(): fixed_text(id,text,960,1030,1450,65,False)

def stage48_message(id):
    return [*[hide(other) for other in messages48],show(id)]

for slot,i in enumerate([9,0,1,10,2,11,3,4,12,5,13,6,7,14,8,15,16]):
    x=370+(slot%9)*145; y=520+(slot//9)*210
    l.image('sheep_'+str(i),'sheep_alive' if i<9 else 'sheep_dead',x,y,['tap'],scale=[.6,.6])
    if i<9:
        l.image('marked_'+str(i),'selection_check',x,y-65,visible=False,scale=[.55,.55])
        l.rule('tap','sheep_'+str(i),stage48_message('already_counted'),[var('counted_'+str(i))])
        l.rule('tap','sheep_'+str(i),[setv('counted_'+str(i)),setv('living',1,'increment'),show('marked_'+str(i)),*[hide(id) for id in messages48]],[var('counted_'+str(i),False)])
    else:
        l.rule('tap','sheep_'+str(i),[hide('sheep_'+str(i)),setv('removed',1,'increment'),*stage48_message('dead_feedback')],once=True)
for n in range(10):
    fixed_text('living_reading_'+str(n),'زنده‌های شمرده‌شده: '+str(n),960,845,750,70,n==0)
    l.rule('variable_changed','$level',[*[hide('living_reading_'+str(k)) for k in range(10)],show('living_reading_'+str(n))],[var('living',n)])
fixed_button('confirm','تأیید شمارش',1050,950)
fixed_button('eight','۸ تا مانده',470,950)
l.rule('tap','eight',stage48_message('wrong_eight'))
l.rule('tap','confirm',stage48_message('incomplete'),[var('living',9,'lt')])
l.win('tap','confirm',[*[hide(id) for id in messages48]],[var('living',9)])
l.image('gate','stream_gate',1650,800,[dict(type='swipe',direction='left')],scale=[.6,.6])
l.rule('swipe','gate',[feedback('gate'),*stage48_message('gate_feedback')])
l.save()

l=Level(49,'هر دو شرط را بررسی کن: مجموع رقم‌ها و اختلاف عدد با وارونهٔ آن.')
l.variable(tens=0,units=0)
l.note('عدد اصلی − وارونه = ۲۷؛ مجموع دو رقم = ۹')
for id,x,label in [('tens',790,'دهگان'),('units',1130,'یکان')]:
    l.zone(id,x,580,['six','three','four','five']); l.text(id+'_label',label,x,470)
    for n in [3,4,5,6]: l.text(id+'_'+str(n),str(n),x,580,visible=False)
for id,digit,x in [('six',6,450),('three',3,790),('four',4,1130),('five',5,1470)]:
    l.card(id,str(digit),x,840)
    for zone in ['tens','units']:
        l.drop(id,zone,[setv(zone,digit),move(id,x,840),*[hide(zone+'_'+str(n)) for n in [3,4,5,6]],show(zone+'_'+str(digit))])
l.text('partial','مجموع ۹؛ اختلاف ۹ است',960,700,visible=False)
l.rule('variable_changed','$level',[hide('partial')])
l.rule('variable_changed','$level',[show('partial')],[dict(type='any',conditions=[dict(type='all',conditions=[var('tens',4),var('units',5)]),dict(type='all',conditions=[var('tens',5),var('units',4)])])])
l.text('confirm','بررسی دو شرط',960,940,['tap']); l.text('reversed','۶۳ − ۳۶ = ۲۷؛ ۶ + ۳ = ۹',960,700,visible=False)
l.win('tap','confirm',[show('reversed')],conditions=[var('tens',6),var('units',3)])
l.image('mirror','mirror_frame',1630,570,['tap'],scale=[.5,.5]); l.rule('tap','mirror',[feedback('mirror')]); l.save()

l=Level(50,'ردپا را از آغاز قدم‌به‌قدم دنبال کن؛ مقصد رد واقعی را انتخاب کن.')
l.variable(trail=0)
for i,x in enumerate([520,960,1400]): l.image('chest_'+str(i),'chest_closed',x,530,['tap'])
l.image('connected_trail','footprint_trail',960,700,z_index=-2)
# A connected, bent trail leads from the lower right to the left chest.
for i,(x,y,angle) in enumerate([(1400,850,-155),(1120,800,-160),(850,710,-150),(600,650,-100)]):
    l.image('trail_'+str(i),'footprints_right',x,y,['swipe'],rotation_degrees=angle,scale=[.65,.65])
    l.image('trail_check_'+str(i),'selection_check',x,y,visible=False,scale=[.3,.3])
    l.rule('swipe','trail_'+str(i),[show('trail_check_'+str(i)),setv('trail',i+1)],[var('trail',i)],once=True)
l.text('trail_start','شروع رد',1570,900)
l.image('swipe_left_arrow','left_arrow',960,990)
l.text('swipe_left_label','روی ردپا به چپ بکش',1260,990)
l.d['objects'][-1]['hit_size']=[400,70]
# Reuse the existing coin texture by explicit path (outside samples).
l.d['objects'].append(dict(id='coin',scene='DraggableObject',sprite='res://assets/ui/score.png',position=[300,840],scale=[1.25,1.25],interactions=[dict(type='drag',bounds=[200,460,1500,450],return_on_invalid=True),'drop_on']))
l.zone('right_chest',1400,530,['coin']); l.drop('coin','right_chest',[move('coin',300,840),feedback('chest_2')])
l.drag('stamp','shoe_stamp',1650,530,scale=[.6,.6]); l.image('paper','paper',1650,760,scale=[.5,.5]); l.zone('paper_zone',1650,760,['stamp']); l.image('false_print','footprints_right',1650,760,visible=False,rotation_degrees=180,scale=[.4,.4])
l.drop('stamp','paper_zone',[move('stamp',1650,530),show('false_print')]); l.win('tap','chest_0',[replace('chest_0','chest_open')],conditions=[var('trail',4)]); l.save()

# The manifest is appended, while the existing thirty definitions remain intact.
manifest=json.loads((DATA/'manifest.json').read_text(encoding='utf-8'))
manifest['manifest_version']=8
manifest['levels']=[dict(id=i,path=f'res://PuzzleEngine/PuzzleData/{i:03}.json') for i in range(1,51)]
(DATA/'manifest.json').write_text('{\n  "schema_version": 1,\n  "manifest_version": 8,\n  "levels": [\n'+',\n'.join('    { '+json.dumps(entry)[1:-1]+' }' for entry in manifest['levels'])+'\n  ]\n}\n',encoding='utf-8')

# Distinct local water feedback; a matching visible ripple is shown by the rule.
import math
import random
import struct
import wave
rng=random.Random(40)
samples=[]
for i in range(15435):
    t=i/22050
    envelope=math.sin(math.pi*t/.7)**2
    samples.append(int(6500*envelope*(.55*math.sin(2*math.pi*(210*t+35*math.sin(15*t)))+.25*rng.uniform(-1,1))))
with wave.open(str(ASSETS/'water_slosh.wav'),'wb') as stream:
    stream.setparams((1,2,22050,0,'NONE','not compressed'))
    stream.writeframes(struct.pack('<'+'h'*len(samples),*samples))
