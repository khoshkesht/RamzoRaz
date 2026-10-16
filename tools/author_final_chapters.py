"""Author 71–101 only. Writes content; never launches Godot or runs checks."""
import json
import math
import random
from pathlib import Path
from author_chapter_five import Level, var, setv, inc, move, show, hide, act, P

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/samples'
DATA = ROOT / 'PuzzleEngine/PuzzleData'
NEW = {}
REPORT = {}


def svg(name, body, w=120, h=120, reason=''):
    path = P + name + '.svg'
    (ASSETS / (name + '.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n', encoding='utf-8')
    NEW[path] = reason
    return name


def text(target, value):
    return dict(type='set_text', target=target, text=str(value).translate(str.maketrans('0123456789', '۰۱۲۳۴۵۶۷۸۹')))


# Each original distraction has its own event and explanatory local response.
# The laboratory is visibly separate and never changes the puzzle's model.
TRAPS = {
71:[('drop_on','کارت۳:۱۵','۳:۱۵درست است؛ ساعت۳:۳۰هنوز ساعت‌شمار ناسازگار دارد.'),('swipe','پیچ قاب','چرخاندن قاب، اختلاف نسبی عقربه‌ها و زمان را رفع نمی‌کند.')],
72:[('hold','سکه تاج‌دار','وزن این سکه معلوم نیست؛ مرجع تضمین‌شده نداریم.'),('drop_on','۶ در برابر۶','در شاخه نامتعادل هنوز هویت و سبک/سنگین مبهم است.'),('swipe','پیچ تراز','چرخاندن پیچ نمایشی، جرم کفه‌ها و نتیجه ثبت‌شده را عوض نمی‌کند.')],
73:[('hold','آینه نگهبان','برعکس‌کردن تصویر اشاره، پاسخ نگهبان دیگر را شبیه‌سازی نمی‌کند.'),('swipe','سکه انتخاب','پیشنهاد شانسی دلیل انتخاب در امن نیست.')],
74:[('drop_on','خانواده۴+۴','برای پسر۳برادر و۴خواهر؛ رابطه اول نادرست است.'),('drop_on','خانواده۳+۲','برای دختر۳برادر و۱خواهر؛ دوبرابر بودن برقرار نیست.'),('tap','شمارش خودم','خود فرد در تعداد خواهر و برادرش شمرده نمی‌شود.')],
75:[('drop_on','۲۲۲۴۴۲','دوبرابرکردن رقم‌ها، توصیف گروه‌های پشت سر هم نیست.'),('hold','مهر جمع','جمع رقم‌ها۸است؛ جمله بعد، تعداد و خود هر رقم را توصیف می‌کند.'),('swipe','۱۱۲۲۱۱','این نوار تعداد۱های ابتدای۱۱۱۲۲۱را نادرست می‌خواند.')],
76:[('drop_on','باتری ضعیف','ساعت کند به‌تدریج عقب می‌افتد؛ دو تطابق روزانه تضمین نمی‌شود.'),('swipe','پیچ سرعت','کندشدن با توقف کامل فرق دارد.'),('tap','قاب۲۴ساعته','ساعت متوقف۲۴ساعته روزی یک بار درست نشان می‌دهد.')],
77:[('drop_on','شروع۵۰','اگر تخم‌مرغ اول در۵۰بشکند، آزمایش خطیِ زیر آن بیش از۱۴پرتاب می‌خواهد.'),('drop_on','گام۱۰','گام ثابت۱۰در بدترین حالت از۱۴پرتاب بیشتر می‌شود.'),('hold','بالشتک','پوشش نرم، قانون شکست و اطلاعات پرتاب را عوض نمی‌کند.')],
78:[('drop_on','دومینو مورب','دومینو فقط دو همسایه افقی یا عمودی را می‌پوشاند.'),('tap','سطل رنگ','رنگ تزئینی قاب، رنگ‌بندی منطقی خانه‌ها را تغییر نمی‌دهد.'),('hold','۳۱قطعه','مساحت۶۲برابر است؛ اما دو تعداد رنگ هم باید برابر باشند.')],
79:[('drop_on','یکی از هرکیسه','کمبود۱گرم فقط وجود کیسه تقلبی را نشان می‌دهد؛ شماره معلوم نمی‌شود.'),('hold','کیسه سبک‌نما','حجم و ظاهر کیسه، جرم تک‌سکه را معلوم نمی‌کند.'),('drop_on','آهنربا','جنس سکه‌ها یکسان است؛ واکنش مغناطیسی شماره کیسه را جدا نمی‌کند.')],
80:[('drop_on','قاب مربع','مرز فرضی محدودیت نیست؛ خط‌ها می‌توانند بیرون مربع ادامه یابند.'),('hold','خط‌کش۵خط','پنج خط از سقف چهار خط بیشتر است.'),('swipe','پاک‌کن','پاک‌کردن پیش‌نمایش، قطع یک گرفتن قلم را پیوسته نمی‌کند.')],
81:[('drop_on','میله کوتاه','این میله مقصد قانونی برج نیست؛ حلقه به مبدأ برمی‌گردد.'),('hold','حلقه بدل','این حلقه عضو چهار حلقهٔ هدف نیست؛ رنگ، قطر را ثابت نمی‌کند.'),('drop_on','انتقال دسته‌ای','هر حرکت فقط یک حلقهٔ بالایی را منتقل می‌کند.')],
82:[('drop_on','انتخاب تصادفی','موفقیت شانسی یک نفر، راهبرد مشترکِ دنبال‌کردن چرخه‌ها نیست.'),('tap','رنگ مشترک','رنگ جعبه شمارهٔ داخل آن را تعیین نمی‌کند.'),('hold','یادداشت قبلی','اطلاعات میان نوبت‌ها منتقل نمی‌شود؛ هر نفر از شمارهٔ خودش شروع می‌کند.')],
83:[('tap','۸گوشه','هر گوشه سه وجه رنگی دارد؛ دو وجه نیست.'),('drop_on','۶مرکزوجه','وسط هر وجه تنها یک وجه رنگی دارد.'),('swipe','رنگ‌پاش','شمارش بر اساس رنگ اولیهٔ مکعب است، نه روکش تازه.')],
84:[('hold','قالب۳×۳×۳','این قالب هسته۱تایی دارد؛ مکعب مسئله۴×۴×۴است.'),('drop_on','۲۴لبه','مکعبچه لبه دست‌کم یک وجه رنگی دارد.'),('drop_on','روکش سفید','پوشاندن رنگ، بی‌رنگ‌بودن اولیه را ثابت نمی‌کند.')],
85:[('drop_on','۶۴خانه','۶۴فقط مربع‌های ضلع۱است؛ هفت اندازه دیگر هم داریم.'),('drop_on','مستطیل۲×۳','عرض و ارتفاع برابر نیست؛ مربع محسوب نمی‌شود.'),('hold','۱۲۹۶','۱۲۹۶تعداد همه مستطیل‌هاست؛ شرط مربع را اعمال نکرده است.')],
86:[('drop_on','۲۰۴','۲۰۴فقط مربع‌هاست؛ سایر مستطیل‌ها هم باید شمرده شوند.'),('drop_on','۴۰۹۶','جفت خانه‌ها مستطیل را مشخص نمی‌کنند؛ دو خط از هر جهت لازم است.'),('hold','حذف مربع','مربع هم مستطیل است؛ حذف آن شمارش را به۱۰۹۲کاهش می‌دهد.')],
87:[('drop_on','نصف‌نما','نشان۴لیتر فقط ظاهر است؛ حجم آب باید واقعاً منتقل شود.'),('hold','ظرف ترک‌دار','خارج‌کردن آب از مجموعه مجاز نیست؛ مجموع باید۸بماند.'),('swipe','قیف نامعتبر','درجه نمایشی ظرفیت واقعی۸،۵،۳را تغییر نمی‌دهد.')],
88:[('drop_on','شروعB','Bدرجه زوج دارد؛ مسیر باز کامل باید ازAیاCشروع شود.'),('hold','پلB–D','خط کم‌رنگ تزئینی یال گراف نیست.'),('tap','عبور مجدد','هیچ مهر یا میان‌بُری تکرار یال را قانونی نمی‌کند.')],
89:[('drop_on','پل اتصال‌کوتاه','اتصال مستقیم قطب‌ها از لامپ نمی‌گذرد؛ مدار هدف کامل نیست.'),('tap','لامپ نمایشی','باتری داخلی این لامپ، شاهد جریان مدار هدف نیست.')],
90:[('tap','چرخش۱۸۰','چرخش۱۸۰درجه، بازتاب نقش نامتقارن نیست.'),('drop_on','روکش شفاف','پنهان‌کردن یک لبه، اتصال غلط زیر آن را اصلاح نمی‌کند.'),('hold','آینه کج','محور واقعی بازتاب عمودی است؛ پیش‌نمایش مایل معیار نیست.')],
91:[('hold','برچسب اندازه','چگالی متفاوت است؛ اندازهٔ وزنه جرمش را مشخص نمی‌کند.'),('drop_on','دو گروه','مقایسهٔ مجموع دوگروه، ترتیب همهٔ تک‌وزنه‌ها را معلوم نمی‌کند.'),('drop_on','مرجع نامعلوم','وزنهٔ مرجع نامعلوم اطلاعات تضمین‌شده اضافه نمی‌کند.')],
92:[('drop_on','۴۷۲۱','۲پیش از۷نیست؛ مجموع۱۴به‌تنهایی ترتیب را تعیین نمی‌کند.'),('tap','آینه سرنخ','جهت خواندن و جایگاه اول/آخر ثابت است.'),('hold','مجموع۱۴','هر جایگشت همین مجموع را دارد؛ سرنخ‌های ترتیب هم لازم‌اند.')],
93:[('drop_on','کاشی هم‌رنگ','رنگ مشابه کافی نیست؛ خطوط باید در هر مرز متصل باشند.'),('drop_on','محور مورب','محور اعلام‌شده عمودی است؛ تطابق مورب پاسخ نیست.'),('hold','تقارن رنگ','قالب فقط رنگ‌ها را می‌سنجد و قطع مسیر را پنهان می‌کند.')],
94:[('drop_on','صفحه مات','برق سطح به معنی بازتاب پرتو تا گیرنده نیست.'),('hold','راه کوتاه','روشن‌شدن یک هدف کافی نیست؛ هر سه هدف لازم‌اند.'),('tap','منشور','پرتو رنگی نمایشی در محاسبهٔ گیرنده‌ها دخالت ندارد.')],
95:[('drop_on','راه مورب','همسایه فقط افقی یا عمودی است؛ قطر مجاز نیست.'),('tap','پایان زودهنگام','پایان با خانه‌های نرفته، پوشش کامل نیست.'),('hold','دورحلقه','دورزدن مرز، خانهٔ وسط را جا می‌گذارد یا تکرار می‌خواهد.')],
96:[('hold','مهره توخالی','این مهره عضو مجموعه۹تایی نیست؛ بزرگی ظاهر دلیل جرم نیست.'),('drop_on','۴ در برابر۴','در شاخهٔ نامتعادل۴نامزد می‌ماند؛ یک توزین کافی نیست.'),('swipe','آویز ترازو','تکان‌دادن آویز جرم کفه‌ها را عوض نمی‌کند.')],
97:[('drop_on','نقش آینه‌ای','بازتاب نقش نامتقارن با چرخش منطبق نمی‌شود.'),('hold','روکش گل','پنهان‌کردن اختلاف گل، خود نقش زیر آن را عوض نمی‌کند.'),('tap','زاویه۴۵','زاویه‌های مجاز۰،۹۰،۱۸۰،۲۷۰درجه‌اند؛ این حلقه راهنمای آزمایشی است.')],
98:[('drop_on','چسب نواری','پوشاندن شکاف، اتصال منطقی مرز را برقرار نمی‌کند.'),('tap','چرخش کل','نشان جهت مرجع ثابت است؛ چرخاندن پیش‌نمایش پاسخ نیست.')],
99:[('tap','لوله بن‌بست','بن‌بست براق خروجی را می‌بندد و مسیر کامل آب نیست.'),('drop_on','درپوش آزمایش','قطره تزئینی قطع شد؛ نشتی اتصال‌های شبکه هنوز باید محاسبه شود.'),('hold','شیر میان‌بُر','پرشدن حوض نمایشی، اتصال آب‌انبار هدف را ثابت نمی‌کند.')],
100:[('drop_on','کلید ترکیبی','این کلید عضو سه کلید خورشید،ماه،ستاره نیست.'),('hold','ماه→A','این برچسب سرنخ ماه≠Aرا نقض می‌کند.'),('drop_on','قاب تعویض','هویت صندوقA/B/Cثابت است؛ جابه‌جایی برچسب، قفل را عوض نمی‌کند.')],
101:[('hold','قانون۲×۲','این معما مربع لاتین است؛ فقط سطر و ستون قیدند.'),('drop_on','روکش ثابت','خانه‌های داده‌شده تغییر نمی‌کنند؛ پاسخ باید آن‌ها را حفظ کند.')],
}


def add_traps(l):
    descriptors=TRAPS[l.d['id']]
    sources=[f'trap{i}' for i,(event,_,_) in enumerate(descriptors) if event=='drop_on']
    if sources:
        l.socket('trap_lab',135,450,sources,(155,80))
        l.text('trap_lab_label','آزمایش',135,450,size=(140,60))
    for i,(event,name,message) in enumerate(descriptors):
        x,y=135,525+i*165
        l.tile(f'trap{i}','↥' if event=='drop_on' else '↔' if event=='swipe' else '؟',x,y,event=='drop_on',size=(90,75))
        obj=l.d['objects'][-1]
        if event!='drop_on':obj['interactions']=[dict(type='swipe',direction='any',min_distance=55)] if event=='swipe' else [event]
        else:obj['interactions'][0]['bounds']=[85,455,1640,450]
        l.text(f'trap_label{i}',name,x,y+65,size=(240,65))
        actions=[text('feedback',message)]
        if event=='drop_on':actions.insert(0,move(f'trap{i}',x,y))
        l.rule(event,f'trap{i}',actions,target='trap_lab' if event=='drop_on' else None)


class Stage(Level):
    def __init__(self, number, hint, background=None, model=None):
        super().__init__(number, hint, background or random.Random(number+7101).choice(['puzzle_workbench_day', 'puzzle_workbench_night']))
        self.text('feedback', ' ', 960, 990, size=(1650, 70))
        if model is not None:
            self.d['custom_handler'] = 'res://PuzzleEngine/Custom/FinalChapterHandler.gd'
            self.variable(model=json.dumps(dict(model, level=number), ensure_ascii=False))
            if number in [85,89,94,99]:self.text('diagram','\u200b',960,700,size=(1,1),z_index=2)

    def text(self,id,value,x,y,inputs=(),size=(300,70),**kw):
        super().text(id,value if str(value).strip() else '—',x,y,inputs,size,**kw)

    def drag(self, id, sprite, x, y, extra=(), **kw):
        super().drag(id, sprite, x, y, extra, bounds=(250, 480, 1420, 420), **kw)

    def tile(self, id, value, x, y, drag=False, size=(100,100), **kw):
        kw.setdefault('z_index',5 if drag else 0)
        inputs = [dict(type='drag', bounds=[230,460,1460,450], return_on_invalid=True), 'drop_on'] if drag else ['tap']
        # A text token needs one moving image; use aspect-specific reusable art.
        name=f'final_token_{size[0]}_{size[1]}'
        if P+name+'.svg' not in NEW:
            svg(name,f'<rect x="3" y="3" width="{size[0]-6}" height="{size[1]-6}" rx="10" fill="#e0d2b1" stroke="#526b71" stroke-width="5"/>',*size,reason='Token silhouette matching the real hit rectangle without scaling its Persian text.')
        self.text(id, str(value), x, y, inputs, size=size, sprite=P+name+'.svg', **kw)

    def socket(self, id, x, y, sources, size=(115,115)):
        self.image(id+'_frame', 'final_socket', x, y, scale=[size[0]/120,size[1]/120])
        self.zone(id,x,y,sources,size)

    def trap(self, id, sprite, x, y, message):
        self.image(id,sprite,x,y,['hold'],scale=[.55,.55])
        self.rule('hold',id,[text('feedback',message)])

    def save(self):
        add_traps(self)
        # World objects use one shared stage space; labels never capture drags.
        # Preserve exact old assets; lighting is local to the new stage instances.
        for obj in self.d['objects']:
            if 'night' in self.d['background']:obj['tint']='#d6e1f0'
            if obj['scene']=='TextObject' and not obj.get('interactions'):
                obj['interactive']=False
        super().save()
        paths = {self.d['background']}
        paths.update(o['sprite'] for o in self.d['objects'] if 'sprite' in o)
        paths.update(a['sprite'] for r in self.d['rules'] for a in r['actions'] if 'sprite' in a)
        if self.d['id']==87:
            paths.update(P+f'measuring_jug_{cap}_{v}.svg' for cap in [3,5] for v in range(cap+1))
            paths.update(P+f'final_jug8_{v}.svg' for v in range(9))
        if self.d['id']==89:paths.add(P+'bulb_lit.svg')
        REPORT[str(self.d['id'])] = dict(background=self.d['background'], lighting='night_lit: cool instance tint #d6e1f0 under existing ambient light' if 'night' in self.d['background'] else 'day', reused=sorted(paths-NEW.keys()), new={p:NEW[p] for p in paths if p in NEW}, required_actions='See authored rules/model and complete Persian hint; balance requires play evidence.', interaction_review='Two necessary operations (one question, opposite door); high reasoning load, score/time acceptance remains open.' if self.d['id']==73 else 'Content operations implemented; play evidence required before accepting time/score.')


def assets():
    svg('final_cell','<rect x="4" y="4" width="112" height="112" rx="14" fill="#e0d2b1" stroke="#526b71" stroke-width="6"/>',reason='Small square number token; existing puzzle_tile has a different aspect and oversized artwork.')
    svg('final_socket','<rect x="5" y="5" width="110" height="110" rx="12" fill="#b3c0b8" fill-opacity=".5" stroke="#47636b" stroke-width="5" stroke-dasharray="10 8"/>',reason='Visible square insertion destination matching token extent.')
    svg('final_dot','<circle cx="20" cy="20" r="14" fill="#3d6572" stroke="#ead7a8" stroke-width="5"/>',40,40,'Distinct high contrast tracing node.')
    svg('final_trace_pen','<path d="M70 70L18 42 42 18Z" fill="#6d9f9f" stroke="#3f5d6b" stroke-width="5"/><path d="M70 70L52 60 60 52Z" fill="#3f5d6b"/><circle cx="70" cy="70" r="5" fill="#3f5d6b"/>',140,140,'Nib tip coincides with the registered center and has a square touch region; the existing long pen has an offset nib and a thin hit area.')
    svg('final_battery','<rect x="8" y="12" width="96" height="45" rx="8" fill="#698d80" stroke="#40575e" stroke-width="5"/><path d="M105 25h10v20h-10M23 34h22m-11-11v22M70 34h20" stroke="#f3dda8" stroke-width="5"/>',120,70,'Removable clock battery and polarity, no matching source.')
    svg('final_domino','<rect x="4" y="4" width="152" height="72" rx="8" fill="#e1d5b5" stroke="#3b5960" stroke-width="6"/><path d="M80 4v72" stroke="#3b5960" stroke-width="4"/><circle cx="40" cy="40" r="9" fill="#3b5960"/><circle cx="120" cy="40" r="9" fill="#3b5960"/>',160,80,'Two adjacent board cells in one legal domino.')
    for name,color in [('dark','#49636c'),('light','#dfcdab')]:
        svg('final_board_'+name,f'<rect x="3" y="3" width="114" height="114" fill="{color}" stroke="#78928e" stroke-width="4"/>',reason='Original two checkerboard colors; removed diagonal corners are both dark.')
    svg('final_fixed_cell','<rect x="3" y="3" width="99" height="89" rx="8" fill="#9db4ad" stroke="#526b71" stroke-width="5"/><path d="M83 4H101V22Z" fill="#526b71"/>',105,95,'Locked Latin clue cells have a persistent corner mark distinct from entered numbers.')
    for i in range(4):
        svg('final_ring_'+str(i),f'<rect x="5" y="5" width="{110+i*45}" height="36" rx="17" fill="{["#c77d67","#b6a266","#7ca5a0","#928bb0"][i]}" stroke="#425963" stroke-width="5"/>',120+i*45,46,'Four ordered Hanoi ring diameters; existing sources are not rings.')
    svg('final_peg','<path d="M100 10v330M10 345h180" fill="none" stroke="#715c4b" stroke-width="15"/>',200,360,'Hanoi destination peg.')
    for volume in range(9):
        body='<path d="M30 20H210V265Q120 300 30 265Z" fill="#e0e8dd" stroke="#4c7076" stroke-width="6"/>'
        if volume:body+=f'<path d="M37 {268-volume*27}H203V260Q120 288 37 260Z" fill="#6ba5bd"/>'
        body+='<path d="M210 70H245Q280 135 245 200H210" fill="none" stroke="#4c7076" stroke-width="10"/>'
        for tick in range(1,9):body+=f'<path d="M45 {268-tick*27}h25" stroke="#486c73" stroke-width="3"/>'
        svg(f'final_jug8_{volume}',body,300,320,'Graduated eight-liter vessel with conserved volume; existing jug series cover only capacities three and five.')
    svg('final_cube_shell','<rect x="3" y="3" width="114" height="114" fill="#ba855f" stroke="#496571" stroke-width="5"/>'+''.join(f'<path d="M{j*30} 3v114M3 {j*30}h114" stroke="#496571" stroke-width="3"/>' for j in range(1,4)),reason='Painted 4×4 exterior slab for peeling the six original cube surfaces.')
    svg('final_wire_good','<path d="M5 30H435" stroke="#536f79" stroke-width="14"/><circle cx="10" cy="30" r="8" fill="#c6a258"/><circle cx="430" cy="30" r="8" fill="#c6a258"/>',440,60,'Long supply wire spanning the battery/switch/lamp terminals.')
    svg('final_wire_broken','<path d="M5 30H190M250 30H435" stroke="#536f79" stroke-width="14"/><path d="M190 19l12 22 12-22 12 22 12-22" fill="none" stroke="#bc7d68" stroke-width="5"/>',440,60,'Visible internal break for the faulty supply wire; intact wire asset preserved.')
    svg('final_path_carpet','<rect x="5" y="5" width="530" height="530" rx="15" fill="#c5b9a1" stroke="#526e74" stroke-width="8"/>'+''.join(f'<rect x="{c*180+12}" y="{r*180+12}" width="156" height="156" rx="10" fill="{["#a4bbb4","#dac8ab"][(r+c)%2]}" stroke="#718882" stroke-width="3"/>' for r in range(3) for c in range(3)),540,540,'Nine visible carpet cells aligned with the Hamilton path nodes, below the HUD.')
    # Clock faces contain actual hand geometry; time labels remain live Persian text.
    for i,(h,m,wrong) in enumerate([(1,0,False),(3,30,True),(6,15,False),(9,45,False)]):
        def hand(deg,length):
            a=math.radians(deg-90);return f'{100+length*math.cos(a):.3f},{100+length*math.sin(a):.3f}'
        ticks=''.join(f'<circle cx="{100+83*math.cos(math.radians(j*30))}" cy="{100+83*math.sin(math.radians(j*30))}" r="4" fill="#45616a"/>' for j in range(12))
        svg('final_clock_'+str(i),f'<circle cx="100" cy="100" r="94" fill="#e9ddbb" stroke="#47616a" stroke-width="7"/>{ticks}<path d="M100 100L{hand((h%12)*30+(0 if wrong else m*.5),48)}M100 100L{hand(m*6,73)}" stroke="#324b57" stroke-width="8" stroke-linecap="round"/><circle cx="100" cy="100" r="8" fill="#ba7864"/>',200,200,'Clock hand geometry including the 3:30 hour-hand error; existing clocks cannot encode these times.')
    # Asymmetric motifs encode all four edges and a chiral central branch.
    for i,edges in enumerate([(0,1,2,3),(0,3,2,1),(1,2,3,0),(0,1,3,2)]):
        cols=['#b16f61','#498997','#a18b49','#8c75a2']
        body='<rect x="4" y="4" width="112" height="112" fill="#dfd3b7" stroke="#496571" stroke-width="5"/>'
        for p,e in zip(['M60 0V60','M120 60H60','M60 120V60','M0 60H60'],edges):body+=f'<path d="{p}" stroke="{cols[e]}" stroke-width="12"/>'
        body+='<path d="M45 38L78 44 65 58 83 80 43 73Z" fill="#486a72"'+(' transform="translate(120 0) scale(-1 1)"' if i==1 else '')+'/>'
        svg('final_motif_'+str(i),body,reason='Asymmetric oriented motif with recorded N/E/S/W signatures; preserved old motif sources.')
        bowl='<circle cx="60" cy="60" r="56" fill="#e5dbbf" stroke="#496571" stroke-width="5"/><circle cx="60" cy="60" r="43" fill="none" stroke="#78968f" stroke-width="5"/>'
        bowl+='<path d="M45 30L82 43 65 58 86 83 34 74Z" fill="#486a72"'+(' transform="translate(120 0) scale(-1 1)"' if i==1 else '')+'/>'
        if i==3:bowl+='<circle cx="44" cy="50" r="8" fill="#ba7864"/>'
        if i!=2:svg('final_bowl_'+str(i),bowl,reason='Asymmetric bowl pattern: A/C reuse the same image under rotation, B reflected, D has an extra colored detail.')
    for mask in [6,10]:
        body='<rect x="3" y="3" width="114" height="114" rx="8" fill="#d9c9a5" stroke="#577072" stroke-width="4"/>'
        for bit,p in enumerate(['M60 60V0','M60 60H120','M60 60V120','M60 60H0']):
            if mask & (1<<bit):body+=f'<path d="{p}" stroke="#487f8a" stroke-width="22"/>'
        body+='<circle cx="60" cy="60" r="14" fill="#487f8a"/>'
        svg('final_pipe_'+str(mask),body,reason='Pipe connector bitmask N/E/S/W, including closed unused cells; no matching full connector set.')
    for x in range(3):
        for y in range(3):
            for z in range(3):
                colors=['#bb8560' if v in [0,2] else '#c3c9c3' for v in [x,y,z]]
                body=''.join(f'<path d="{p}" fill="{color}" stroke="#42626d" stroke-width="3"/>' for p,color in zip(['M45 3L85 25 45 47 5 25Z','M5 25L45 47 45 91 5 69Z','M45 47L85 25 85 69 45 91Z'],colors))
                svg(f'final_cube_{x}{y}{z}',body,90,94,'Exploded cubelet: original exterior colors for each axis; gray denotes unpainted internal faces.')
    # Matching data and art share these exact connector signatures.
    connections=[[4,0,1,5],[6,7,2,0],[1,3,8,9],[2,10,11,3],[4,0,1,5]]
    palette=['#a85342','#437c96','#918047','#87709d','#327b66','#aa6a8a','#577ab0','#9b6a3e','#5b8d72','#a16153','#597c80','#876594']
    for i,edges in enumerate(connections):
        body='<rect x="3" y="3" width="114" height="114" fill="#e2d3b2" stroke="#496571" stroke-width="4"/>'
        for p,edge in zip(['M60 0V60','M120 60H60','M60 120V60','M0 60H60'],edges):body+=f'<path d="{p}" stroke="{palette[edge]}" stroke-width="12"/>'
        body+='<path d="M47 36L78 53 62 83 43 65Z" fill="#d5b25f" stroke="#415f66" stroke-width="4"/>' if i!=4 else '<circle cx="60" cy="60" r="20" fill="#d5b25f" stroke="#415f66" stroke-width="4"/>'
        svg(f'final_jigsaw_{i}',body,reason='Unique 2×2 seam signatures and a central reference motif; decoy shares edges but has a wrong center.')
    for i,edges in enumerate([[None,0,1,None],[None,0,None,0],[None,None,1,0],[1,2,3,None],[None,2,None,2],[1,None,3,2],[3,4,None,None],[None,4,None,4],[3,None,None,4]]):
        body='<rect x="3" y="3" width="114" height="114" fill="#dbc9aa" stroke="#486572" stroke-width="4"/>'
        for p,edge in zip(['M60 0V60','M120 60H60','M60 120V60','M0 60H60'],edges):
            if edge is not None:body+=f'<path d="{p}" stroke="{palette[edge]}" stroke-width="12"/>'
        if i%3!=1:body+=f'<path d="M{30 if i%3==0 else 90} 38L60 60 {35 if i%3==0 else 85} 83" fill="none" stroke="#567a73" stroke-width="9"/>'
        svg(f'final_symmetry_{i}',body,reason='3×3 rug path with vertical reflection and explicit N/E/S/W seams; middle left/right begin exchanged.')


def rules_levels():
    l=Stage(71,'هر ساعت را لمس کن و جای ساعت‌شمارش را با دقیقه مقایسه کن. در۳:۳۰ ساعت‌شمار باید نیمهٔ راه۳و۴ باشد؛ پس از بررسی چهار ساعت، ساعت دوم را نگه دار.')
    for i,t in enumerate(['1:00','3:30','6:15','9:45']):
        l.image(f'clock{i}',f'final_clock_{i}',450+i*340,650,['tap','hold'],scale=[1.2,1.2])
        l.text(f'time{i}',t,450+i*340,805,size=(220,65));l.variable(**{f'seen{i}':False})
        l.rule('tap',f'clock{i}',[setv(f'seen{i}'),text('feedback',['ساعت‌شمار روی۱؛ سازگار است.','۳:۳۰؛ ساعت‌شمار هنوز دقیقاً روی۳ است.','ساعت‌شمار کمی از۶گذشته؛ سازگار است.','ساعت‌شمار نزدیک۱۰؛ سازگار است.'][i])])
        l.rule('hold',f'clock{i}',[setv('solved')] if i==1 else [text('feedback','حرکت ساعت‌شمار با دقیقه سازگار است.')],[var(f'seen{j}') for j in range(4)])
    l.save()
    l=Stage(73,'کارت «دیگری کدام در را امن می‌داند؟» را روی یکی از دو نگهبان بکش. هر دو به در راست اشاره می‌کنند؛ در مخالف، یعنی در چپ را به چپ بکش. سؤال مستقیم تضمین ندارد و فرصت یگانه را مصرف می‌کند.','library_room_night')
    l.variable(asked=False,valid=False)
    for i in range(2):
        l.image(f'door{i}','hidden_door',580+760*i,640,[dict(type='swipe',direction='left')],scale=[.8,.8]);l.image(f'guard{i}','walking_person',760+400*i,740,scale=[.6,.6])
        l.socket(f'guardzone{i}',760+400*i,740,['question','direct'],(150,170))
    l.tile('question','دیگری؟',780,885,True,size=(220,90));l.tile('direct','در امن؟',1130,885,True,size=(220,90))
    for i in range(2):
        l.drop('question',f'guardzone{i}',[setv('asked'),setv('valid'),hide('question'),hide('direct'),text('feedback','نگهبان به در راست اشاره می‌کند ← در مخالف را باز کن.')],[var('asked',False)])
        l.drop('direct',f'guardzone{i}',[setv('asked'),text('feedback','پاسخ مستقیم تضمین ندارد؛ فرصت سؤال تمام شد.'),dict(type='fail_level')],[var('asked',False)])
    l.win('swipe','door0',conditions=[var('valid')]);l.rule('swipe','door1',[dict(type='fail_level')],[var('asked')]);l.save()
    l=Stage(74,'کارت‌های پسر را در ردیف بالا و دختر را پایین قرار بده. برای هر فرد خودش را نشمار:۴پسر و۳دختر، برای پسر۳برادر=۳خواهر و برای دختر۴برادر=۲×۲خواهر می‌دهد. افراد اضافه را به بیرون ردیف برگردان.')
    l.variable(boys=0,girls=0)
    ids=[f'person{i}' for i in range(10)]
    l.text('boys_label','پسرها',470,500);l.text('girls_label','دخترها',1430,500)
    l.socket('boys',520,650,ids,(650,220));l.socket('girls',1400,650,ids,(650,220));l.socket('outside',960,865,ids,(1650,120))
    for i in range(10):
        kind='boys' if i<5 else 'girls';l.tile(ids[i],'پسر' if i<5 else 'دختر',300+i*145,865,True,size=(110,85));l.variable(**{ids[i]:False})
        row_x=300+(i%5)*105+(880 if i>=5 else 0)
        l.drop(ids[i],kind,[move(ids[i],row_x,650),setv(ids[i]),inc(kind)],[var(ids[i],False)])
        l.drop(ids[i],kind,[move(ids[i],row_x,650)],[var(ids[i])])
        l.drop(ids[i],'outside',[move(ids[i],300+i*145,865),setv(ids[i],False),inc(kind,-1)],[var(ids[i])])
        l.drop(ids[i],'outside',[move(ids[i],300+i*145,865)],[var(ids[i],False)])
        wrong='girls' if kind=='boys' else 'boys'
        for placed in [False,True]:l.drop(ids[i],wrong,[move(ids[i],row_x if placed else 300+i*145,650 if placed else 865),text('feedback','کارت پسر در ردیف پسر و دختر در ردیف دختر قرار می‌گیرد.')],[var(ids[i],placed)])
    l.d['win_condition']=dict(type='all',conditions=[var('boys',4),var('girls',3)])
    l.counter('پسر','boys',4);l.counter('دختر','girls',3);l.save()
    l=Stage(75,'در۱۱۱۲۲۱ سه۱، سپس دو۲ و سپس یک۱ هست. هر رقم را در گروه هم‌جنس خودش بگذار؛ سپس با مهرهای شمارش و رقم، نوار توصیف را به ترتیب۳،۱،۲،۲،۱،۱ بساز. نوار خروجی، خواندن گروه‌هاست، نه دوبرابرکردن رقم‌ها.')
    for j,ch in enumerate('111221'):
        l.tile(f'digit{j}',ch,440+j*200,540,True);l.variable(**{f'g{j}':False})
    for g,(indices,x) in enumerate([([0,1,2],500),([3,4],960),([5],1420)]):
        l.socket(f'group{g}',x,700,[f'digit{j}' for j in indices],(350,150))
        for k,j in enumerate(indices):l.drop(f'digit{j}',f'group{g}',[move(f'digit{j}',x+(k-(len(indices)-1)/2)*95,700),setv(f'g{j}')])
    for i,value in enumerate(['3تا1','2تا2','1تا1']):
        l.tile(f'out{i}',value,500+i*460,890,True,size=(220,85),visible=False)
        l.socket(f'slot{i}',500+i*460,795,[f'out{i}'],(230,85));l.variable(**{f'o{i}':False})
        indices=[[0,1,2],[3,4],[5]][i]
        l.rule('variable_changed','$level',[show(f'out{i}')],[var(f'g{j}') for j in indices],once=True)
        l.drop(f'out{i}',f'slot{i}',[move(f'out{i}',500+i*460,795),text('feedback','خواندن گروه‌ها: ۳تا۱، ۲تا۲، ۱تا۱ → ۳۱۲۲۱۱'),setv(f'o{i}')],[var(f'g{j}') for j in range(6)])
    l.d['hint']='رقم‌های۱۱۱۲۲۱را در سه گروه جدا بکش: سه۱درچپ،دو۲درمیان،یک۱درراست. هر توصیف فقط پس از کامل‌شدن همان گروه ظاهر می‌شود. توصیف‌ها را در نوار خواندن از چپ به راست بچین:۳تا۱،۲تا۲،۱تا۱؛ پس جمله بعد۳۱۲۲۱۱است.'
    l.d['win_condition']=dict(type='all',conditions=[var(f'o{i}') for i in range(3)]);l.save()
    l=Stage(76,'باتری را از ساعت بیرون بکش تا ساعت روی۱:۰۰ بایستد. کنترل چرخهٔ روز را دو بار به راست بکش؛ هر حرکت۱۲ساعت را شبیه‌سازی می‌کند. در نیمه اول ساعت۱و در نیمه دوم ساعت۱۳تطابق رخ می‌دهد؛ دو تطابق در یک شبانه‌روز.')
    l.variable(stopped=False,hour=0,matches=0)
    l.image('clock','final_clock_0',750,650,scale=[1.5,1.5]);l.drag('battery','final_battery',750,850)
    l.socket('battery_out',1350,830,['battery'],(180,120));l.drop('battery','battery_out',[setv('stopped'),move('battery',1350,830),text('feedback','ساعت متوقف شد؛ چرخهٔ۲۴ساعته را جلو ببر.')])
    l.tile('cycle','۱۲ساعت →',1320,600,size=(270,120));l.d['objects'][-1]['interactions']=[dict(type='swipe',direction='right')]
    l.rule('swipe','cycle',[setv('hour',24),inc('matches'),text('feedback','۱۳،۱۴،۱۵،۱۶،۱۷،۱۸،۱۹،۲۰،۲۱،۲۲،۲۳،۲۴؛ فقط۱۳همان۱است.'),setv('solved')],[var('stopped'),var('hour',12)])
    l.rule('swipe','cycle',[setv('hour',12),inc('matches'),text('feedback','۱،۲،۳،۴،۵،۶،۷،۸،۹،۱۰،۱۱،۱۲؛ فقط ساعت۱تطابق دارد.')],[var('stopped'),var('hour',0)])
    l.counter('تطابق','matches',2);l.save()
    l=Stage(78,'دو گوشهٔ حذف‌شده هم‌رنگ‌اند. دو مجموعهٔ رنگی را نگه دار تا۳۰و۳۲خانه معلوم شود. یک دومینو را روی جفت نمونه قرار بده: همیشه یکی از هر رنگ می‌پوشاند. سپس دومینو را روی دو خانهٔ هم‌رنگ باقی‌مانده ببر؛ نابرابری رنگ‌ها ناممکن‌بودن پوشش را ثابت می‌کند.')
    l.variable(black=False,white=False,pair=False)
    for r in range(8):
        for c in range(8):
            if (r,c) in [(0,0),(7,7)]:continue
            name=f'board{r}_{c}';l.image(name,'final_board_light' if (r+c)%2 else 'final_board_dark',650+c*60,480+r*60,scale=[.45,.45])
    for name,label,x,n in [('black','تیره',1350,30),('white','روشن',1600,32)]:
        l.tile(name,label,x,550,size=(180,100));l.d['objects'][-1]['interactions']=['hold'];l.rule('hold',name,[text(name,f'{label}: {n}'),setv(name),text('feedback',f'{n} خانهٔ {label}')])
    l.drag('domino','final_domino',1380,850);l.socket('pair',1320,710,['domino'],(180,100));l.socket('residue',1600,710,['domino'],(180,100))
    l.text('pair_label','دو رنگ',1320,640,size=(180,60));l.text('residue_label','دو هم‌رنگ',1600,640,size=(200,60))
    l.drop('domino','pair',[setv('pair'),move('domino',1380,850),text('feedback','هر دومینو یک خانه از هر رنگ می‌گیرد.')])
    l.win('drop_on','domino',[move('domino',1380,850),text('feedback','۳۰ ≠ ۳۲؛ دو خانهٔ هم‌رنگ جفت نمی‌شوند.')],[var('black'),var('white'),var('pair')],target='residue');l.save()
    # Geometric selection: all exposed cubelets, identity persists across views.
    for number in [83,84]:
        l=Stage(number,'در مکعب۳×۳×۳ فقط وسط۱۲لبه دو وجه رنگی دارد؛ گوشه‌ها۳ و مرکز وجه‌ها۱وجه دارند. همهٔ۱۲وسط لبه را لمس کن؛ انتخاب اشتباه را دوباره لمس کن.' if number==83 else 'شش پوستهٔ بیرونی مکعب۴×۴×۴ را به سینی کنار بکش. هستهٔ۲×۲×۲ شامل۸مکعبچه بی‌رنگ است؛ هر۸مکعبچهٔ آشکار را لمس کن.')
        l.variable(selected=0,wrong=0,toggle=False)
        if number==84:
            for i in range(6):
                l.drag(f'layer{i}','final_cube_shell',420+i*210,560,scale=[1.3,1.3]);l.variable(**{f'layer{i}':False})
            l.socket('tray',1600,840,[f'layer{i}' for i in range(6)],(230,180))
            for i in range(6):l.drop(f'layer{i}','tray',[hide(f'layer{i}'),setv(f'layer{i}')])
            coords=[(x,y,z) for x in range(2) for y in range(2) for z in range(2)]
        else:coords=[(x,y,z) for x in range(3) for y in range(3) for z in range(3) if x in [0,2] or y in [0,2] or z in [0,2]]
        # Three exploded slices make every identity visible, no hidden-face guessing.
        for i,(x,y,z) in enumerate(coords):
            cx=380+z*500+x*125;cy=680+y*100 if number==84 else 540+y*125
            l.image(f'cube{i}',f'final_cube_{x if number==83 else 1}{y if number==83 else 1}{z if number==83 else 1}',cx,cy,['tap'],visible=number==83)
            l.text(f'mark{i}','✓',cx,cy,size=(65,65),visible=False)
            l.variable(**{f'sel{i}':False})
            correct=number==84 or sum(v in [0,2] for v in [x,y,z])==2
            name='selected' if correct else 'wrong'
            cond=[] if number==83 else [var(f'layer{j}') for j in range(6)]
            l.rule('tap',f'cube{i}',[hide(f'mark{i}'),setv('toggle'),setv(f'sel{i}',False),inc(name,-1)],[var(f'sel{i}'),*cond])
            l.rule('tap',f'cube{i}',[show(f'mark{i}'),setv(f'sel{i}'),inc(name)],[var(f'sel{i}',False),var('toggle',False),*cond])
            l.rule('tap',f'cube{i}',[setv('toggle',False)])
        if number==84:l.rule('variable_changed','$level',[show(f'cube{i}') for i in range(8)],[var(f'layer{j}') for j in range(6)],once=True)
        else:
            l.text('slices','سه برشِ بازشدهٔ مکعب؛ رنگ اولیه روی وجه‌هاست',960,450,size=(1400,65))
            l.tile('view','چرخش ←',1480,920,size=(260,75));l.d['objects'][-1]['interactions']=[dict(type='swipe',direction='left')]
            l.variable(view=0,turning=False)
            for view in range(3):
                actions=[setv('turning'),setv('view',(view+1)%3)]
                for i,(x,y,z) in enumerate(coords):
                    xx,yy,zz=[(x,y,z),(z,y,2-x),(2-x,y,2-z)][(view+1)%3]
                    actions += [move(f'cube{i}',380+zz*500+xx*125,540+yy*125),move(f'mark{i}',380+zz*500+xx*125,540+yy*125),dict(type='replace_sprite',target=f'cube{i}',sprite=P+f'final_cube_{xx}{yy}{zz}.svg')]
                l.rule('swipe','view',actions,[var('view',view),var('turning',False)])
            l.rule('swipe','view',[setv('turning',False)])
        l.d['win_condition']=dict(type='all',conditions=[var('selected',12 if number==83 else 8),var('wrong',0)])
        l.counter('انتخاب','selected',12 if number==83 else 8)
        l.save()


def fit_levels():
    # Each placement is reversible and occupies one logical socket.
    for number in [89,90,92,93,97,98,100]:
        hints={89:'دو سیم سالم را از باتری به کلید و از کلید به لامپ وصل کن؛ سیم برگشت از لامپ به باتری ثابت است. سپس کلید را لمس کن. سیم قطع‌شده و اتصال کوتاه جریان معتبر نمی‌سازند.',90:'قطعهٔ بازتابی با رنگ لبه‌های بالا/راست/پایین/چپ مطابق قاب را پیدا کن. جهت اولیه‌اش۹۰درجه است؛ سه بار لمسش کن تا به جهت۰برگردد، سپس در قاب بگذار. قطعهٔ چرخیده، بازتاب نیست.',92:'سرنخ‌ها می‌گویند۴اول،۱آخر،۲قبل از۷ و مجموع۱۴. چهار مهر را از چپ فیزیکی در جایگاه‌های قفل به ترتیب۴،۲،۷،۱بگذار؛ دستگیره را لمس کن. بازخورد فقط تعداد جایگاه درست است.',93:'محور عمودی و رنگ اتصال‌ها را دنبال کن. دو کاشی وسطِ چپ و راست جابه‌جا شده‌اند؛ آن‌ها را با کشیدن روی یکدیگر عوض کن تا همهٔ مسیرها متصل شوند.',97:'فقط نقش کاسه‌هایAوC با چرخش منطبق است. کاسهC را سه بار۹۰درجه بچرخان و رویA بگذار؛ بازتابB و شاخهٔ متفاوتD جفت نیستند.',98:'چهار قطعه را با توجه به رنگ و مسیر خطوط روی قاب۲×۲ بچین؛ هر لمس۹۰درجه می‌چرخاند. نشان جهت باید بالا بماند. جای درست Aبالاچپ،Bبالاراست،Cپایین‌چپ،Dپایین‌راست است.',100:'خورشید نهA است نهB؛ پسC است. ماه نهA وCپر است، پسB است. ستاره را درA بگذار. هر کلید تنها یک صندوق را باز می‌کند.'}
        # Stateful placement/rotation uses shared constrained matching implementation.
        model=dict(kind='fit',slots=[],pieces=[],target=[],rotations=[],initial=[],clues=[])
        l=Stage(number,hints[number],model=model)
        if number==89:
            model.update(target=[0,1],rotations=[0,0,0],initial=[-1,-1,-1],requires_switch=True)
            for i,(name,x) in enumerate([('باتری → کلید',650),('کلید → لامپ',1250)]):l.text(f'clue{i}',name,x,480,size=(400,65))
            names=['سیم سالم۱','سیم سالم۲','قطع داخلی'];sprites=['final_wire_good','final_wire_good','final_wire_broken']
            l.image('battery','final_battery',470,650)
            l.image('lamp','bulb_cold',1480,650,scale=[.6,.6])
            name=svg('final_circuit_return','<path d="M20 10V110H1030V10" fill="none" stroke="#4d747e" stroke-width="8"/>',1050,130,'Fixed return wire from the target lamp to the battery; two supply gaps remain for real wires.')
            l.image('return',name,975,720,z_index=-2)
        elif number==92:
            model.update(target=[2,1,3,0],rotations=[0]*4,initial=[-1]*4,requires_switch=True)
            names=['1','2','4','7'];sprites=['final_cell']*4
            l.text('clues','۴ اول   |   ۱ آخر   |   ۲ پیش از۷   |   مجموع۱۴',960,480,size=(1450,70))
        elif number==100:
            model.update(target=[2,1,0],rotations=[0]*3,initial=[-1]*3)
            names=['خورشید','ماه','ستاره'];sprites=['toothed_key_a','toothed_key_b','toothed_key_c']
            l.text('clues','خورشید ≠ A,B       ماه ≠ A',960,480,size=(1200,70))
        elif number==93:
            model.update(kind='exchange',target=list(range(9)),initial=[0,1,2,5,4,3,6,7,8],rotations=[0]*9,tray=[1430,710])
            names=list('ABCDEFGHI');sprites=['final_symmetry_'+str(i) for i in range(9)]
            l.text('axis','محور عمودی ↓',945,450,size=(450,65))
            l.socket('workbench',1430,710,[f'piece{j}' for j in range(9)],(145,145));l.text('tray_label','سینی موقت',1430,600,size=(280,65))
            l.d['hint']='دو کاشی میانیِ چپ و راست جابه‌جا شده‌اند. ابتدا کاشی میانیِ راست را روی سینی موقت بگذار؛ کاشی میانیِ چپ را در جای خالی راست ببر؛ سپس کاشی سینی را در جای خالی چپ بگذار. تمام خط‌ها باید از مرزها عبور کنند و دو طرف محور عمودی بازتاب هم شوند.'
        elif number in [90,97]:
            model.update(target=[1],rotations=[0,0,0,0],initial=[-1]*4,angles=[0,90,180,0])
            names=list('ABCD');sprites=['final_motif_0','final_motif_1','final_motif_2','final_motif_3']
            if number==97:model.update(target=[2],angles=[0,0,90,0]);sprites=['final_bowl_0','final_bowl_1','final_bowl_0','final_bowl_3']
        else:
            model.update(target=[0,1,2,3],rotations=[0]*5,initial=[-1]*5,angles=[90,180,270,90,0]);names=list('ABCDE');sprites=['final_jigsaw_'+str(i) for i in range(5)]
        count=len(model['target'])
        for i in range(count):
            x,y=(800+(i%3)*145,540+(i//3)*145) if number==93 else (780+(i%2)*145,570+(i//2)*145) if number==98 else (700+i*520,650) if number==89 else (960,650) if number in [90,97] else (440+i*(1040/max(1,count-1)),650)
            model['slots'].append([x,y]);l.socket(f'slot{i}',x,y,[f'piece{j}' for j in range(len(names))],(145,145) if number in [93,98] else (160,160) if number==90 else (115,115))
            if number==100:l.text(f'box{i}',list('ABC')[i],x,550,size=(110,65))
        for i,name in enumerate(names):
            pos=model['slots'][model['initial'].index(i)] if number==93 else [330+i*(1250/max(1,len(names)-1)),865]
            if number==89:pos=[500+i*500,865]
            if number==90:pos[1]=820
            if number==97 and i==0:pos=model['slots'][0]
            model['pieces'].append(pos)
            l.drag(f'piece{i}',sprites[i],*pos,extra=['tap'] if number in [90,97,98] else [],scale=[1.2,1.2] if number in [93,98] else [1.3,1.3] if number==90 else [.72,.72],rotation_degrees=model.get('angles',[0]*len(names))[i])
            if number==97 and i==0:l.d['objects'][-1]['interactions']=[];l.d['objects'][-1]['z_index']=0
            l.text(f'name{i}',name,pos[0],pos[1]+(100 if number==90 else 60),size=(180,55))
            if number==93:l.d['objects'][-1]['visible']=False
            if number==97 and i==0:l.d['objects'][-1]['position'][1]=550
        if model.get('requires_switch'):
            l.tile('switch','کلید' if number==89 else 'دستگیره',960 if number==89 else 1650,650,size=(140 if number==89 else 200,110))
        if number in [90,98]:
            l.image('reference','final_motif_0' if number==90 else 'final_jigsaw_0',730 if number==90 else 1660,650 if number==90 else 520,scale=[1.3,1.3]);l.text('direction','↑',730 if number==90 else 1660,540 if number==90 else 430,size=(100,60))
            if number==90:
                name=svg('final_reflection_axis','<path d="M5 5V195" stroke="#647e87" stroke-width="4" stroke-dasharray="10 8"/>',10,200,'Fixed vertical axis distinguishes reflection from rotation.')
                l.image('axis',name,845,650)
        model['level']=number;l.variable(model=json.dumps(model,ensure_ascii=False));l.save()


def algorithm_levels():
    for number in [72,77,79,80,81,82,85,86,87,88,91,94,95,96,99,101]:
        hints={72:'هر سکه را روی کفه چپ، راست یا سینی بازگشت بکش؛ فقط دکمه توزین بودجه مصرف می‌کند. ابتدا۱،۲،۳،۴ در برابر۵،۶،۷،۸؛ برابر می‌شوند. سپس۹،۱۰،۱۱ در برابر۱،۲،۳؛ چپ سنگین می‌شود. در آخر۹در برابر۱۰؛ راست سنگین است. سکه۱۰ را در جای تشخیص بگذار و حالت سنگین را لمس کن. این مشاهدات از۲۴فرض تنها۱۰سنگین را باقی می‌گذارد.',77:'طبقات آزمایش تخم‌مرغ اول را به ترتیب۱۴،۲۷،۳۹،۵۰،۶۰،۶۹،۷۷،۸۴،۹۰،۹۵،۹۹،۱۰۰ بساز. هر بار نشانگر را به آن طبقه ببر. اگر اولی بشکند، دومی فاصلهٔ زیر آن را از پایین یک‌به‌یک می‌سنجد. شبیه‌ساز همهٔ۱۰۱آستانه را با همین برنامه و حد۱۴بررسی می‌کند.',79:'سکه سالم۱۰گرم و تقلبی۹گرم است. با هر کشیدن کیسه روی سینی یک نمونه اضافه می‌شود؛ برای کم‌کردن روی کیسه لمس کن. از کیسه۱ یک، کیسه۲ دو، تا کیسه۱۰ ده سکه بردار؛ مجموع۵۵ و وزن سالم۵۵۰است. یک بار توزین کن:۵۴۳، کمبود۷گرم یعنی کیسه۷. آن کیسه را نگه دار.',80:'قلم را در یک گرفتن حرکت بده: از نقطه بالاچپ، افقی تا یک فاصله بیرونِ راست؛ مورب به یک فاصله پایینِ پایین‌چپ؛ عمودی به بالاچپ؛ مورب به پایین‌راست. در هر گوشه مکث کوتاه کن و جهت را عوض کن؛ چهار خط متصل هر۹نقطه را می‌پوشاند. برداشتن قلم مسیر را از نو آغاز می‌کند.',81:'فقط حلقهٔ بالایی را بکش؛ بزرگ روی کوچک نمی‌رود. برای۴حلقه: کوچک چپ→وسط، دوم چپ→راست، کوچک وسط→راست، سوم چپ→وسط، کوچک راست→چپ، دوم راست→وسط، کوچک چپ→وسط، بزرگ چپ→راست؛ سپس سه حلقهٔ وسط را با همین قانون به راست منتقل کن.',82:'هر نفر از جعبهٔ شمارهٔ خودش شروع می‌کند و شمارهٔ داخل را دنبال می‌کند تا شمارهٔ خودش را بیابد. جعبه‌های۱تا۵ چرخهٔ۱→۲→۳→۴→۵→۱ و۶تا۱۰ چرخهٔ۶→۷→۸→۹→۱۰→۶دارند. هر نفر حداکثر۵بار باز می‌کند؛ این کار را برای هر۱۰نفر انجام بده. موفقیت این نمونه تضمین عمومی برای۱۰۰نفر نیست.',85:'قلم را از گوشهٔ بالاچپ شبکه به انتهای قطر مربع‌های ضلع۱تا۸ بکش. برای هر اندازه فقط یک مربع نمونه لازم است؛ تعداد همهٔ جایگاه‌ها (۹−ضلع)² است:۶۴،۴۹،۳۶،۲۵،۱۶،۹،۴،۱. هر۸اندازه را بساز تا جمع۲۰۴به دست آید.',86:'دو خط عمودی متفاوت را با کشیدن گیره‌ها روی خط‌ها انتخاب کن؛ برای افقی‌ها هم همین کار را بکن. سپس خط‌کش ترکیب‌ها را نگه دار: از۹خط،۳۶جفت در هر جهت داریم؛۳۶×۳۶=۱۲۹۶. مربع‌ها هم مستطیل‌اند.',87:'ظرف را روی ظرف دیگر بکش؛ تا پرشدن مقصد یا خالی‌شدن مبدأ منتقل می‌شود. مسیر۸/۵/۳لیتری:۸→۵،۵→۳،۳→۸،۵→۳،۸→۵،۵→۳،۳→۸. حجم‌ها به ترتیب(۳،۵،۰)،(۳،۲،۳)،(۶،۲،۰)،(۶،۰،۲)،(۱،۵،۲)،(۱،۴،۳)،(۴،۴،۰)می‌شوند.',88:'قلم را ازA یاC شروع کن؛ فقط روی خط‌های واقعی حرکت کن و هیچ یال را دوباره نرو. مسیر نمونه A→B→C→D→A→C است. می‌توانی با کشیدن خود قلم بهC، یک مسیر معکوس معتبر هم بسازی؛ همهٔ مسیرهای اویلری پذیرفته‌اند.',91:'حداکثر۵مقایسه داری. هر بار یک وزنه روی هر کفه و سپس توزین. نمونه: AباB،CباD،BباD،AباC،DباC. این پنج نتیجه ترتیبB,D,C,A را ثابت می‌کنند. وزنه‌ها را از چپ سبک به سنگین در چهار جایگاه بچین؛ حدس بدون مقایسه کافی نیست.',94:'هر فانوس یک پرتو افقی به راست می‌فرستد. سه آینهٔ / را به جایگاه‌های هم‌ردیف نور بکش تا پرتو عمودی به نشان بالای آن برسد. فقط دو آینه نیاز به تغییر دارند؛ آینهٔ میانی از ابتدا درست است. آینهٔ اول را جایگاه اول و سومی را جایگاه سوم بگذار؛ جابه‌جایی اضافی را می‌توانی با بازگرداندن اصلاح کنی.',95:'قلم را در یک گرفتن روی همسایه‌های افقی یا عمودی حرکت بده؛ هر خانه یک بار. از بالاچپ سه خانه به راست، یک پایین، دو چپ، یک پایین و دو راست برو تا پایین‌راست؛۹خانه یکتا لازم است و حرکت مورب یا برگشت پذیرفته نیست.',96:'سه مهره۱،۲،۳ را با۴،۵،۶بسنج؛ راست سنگین است. همه را به سینی برگردان؛۴را با۵بسنج، راست سنگین است. مهره۵ را در محل تشخیص بگذار. دو نتیجه فقط۵را باقی می‌گذارند؛ جابه‌جایی مهره‌ها توزین مصرف نمی‌کند.',99:'هر لوله را لمس کن تا۹۰درجه بچرخد. مسیر از ورودیِ چپِ بالاچپ، سطر بالا به راست، سطر وسط به چپ و سطر پایین به راست است و از راستِ پایین‌راست خارج می‌شود. هر اتصال باید همسایهٔ مقابل داشته باشد؛ شیر را لمس کن تا جریان واقعی و نشتی بررسی شود.',101:'مهرهای۱تا۴ پایین جدول را در خانه‌های خالی بگذار؛ مهرها پس از گذاشتن به مخزن برمی‌گردند. از چپ به راست سطرها۱،۲،۳،۴ / ۲،۳،۴،۱ / ۳،۴،۱،۲ / ۴،۱،۲،۳ است. خانه‌های ثابت عوض نمی‌شوند؛ هر تکرار سطر یا ستون علامت می‌گیرد و قابل اصلاح است.'}
        model=dict(level=number)
        l=Stage(number,hints[number],model=model)
        if number in [72,91,96]:
            n=12 if number==72 else 4 if number==91 else 9
            model.update(kind='balance',n=n,budget=5 if number==91 else 3 if number==72 else 2,masses=[40,10,30,20] if number==91 else [11 if i==(9 if number==72 else 4) else 10 for i in range(n)])
            for name,x in [('left',620),('right',1260),('tray',960)]:l.socket(name,x,580 if name!='tray' else 845,[f'coin{i}' for i in range(n)],(1450,140) if name=='tray' else (440,170))
            l.text('left_label','کفهٔ چپ',620,465,size=(280,60));l.text('right_label','کفهٔ راست',1260,465,size=(280,60))
            for i in range(n):l.tile(f'coin{i}',list('ABCD')[i] if number==91 else i+1,280+i*(1360/max(1,n-1)),850,True,size=(85,85))
            l.tile('weigh','توزین',1610,560,size=(180,95))
            if number==91:
                for i in range(4):l.socket(f'order{i}',620+i*220,720,[f'coin{j}' for j in range(n)],(100,100))
                l.text('lightest','سبک',620,650,size=(150,60));l.text('heaviest','سنگین',1280,650,size=(180,60))
            else:
                l.socket('identify',1600,740,[f'coin{i}' for i in range(n)],(130,130))
                if number==72:
                    l.tile('heavy','سنگین',1490,930,size=(160,60));l.tile('light','سبک',1700,930,size=(150,60))
                    l.d['objects'][0]['position'][1]=1015
        elif number in [80,85,88,95]:
            pts=([[650+c*(140 if number==80 else 180),500+r*(140 if number==80 else 180)] for r in range(3) for c in range(3)] if number in [80,95] else [[650,520],[1150,520],[1150,880],[650,880]] if number==88 else [])
            model.update(kind='path',points=pts,tolerance=28,segment_tolerance=12)
            if number==95:l.image('carpet','final_path_carpet',830,680,z_index=-3)
            if number==85:
                model.update(origin=[650,480],spacing=52)
                for j in range(9):
                    for k in range(9):l.image(f'grid{j}_{k}','final_dot',650+j*52,480+k*52,scale=[.22,.22])
            else:
                for i,(x,y) in enumerate(pts):l.image(f'point{i}','final_dot',x,y);l.text(f'label{i}',list('ABCD')[i] if number==88 else str(i+1),x-35,y-30,size=(60,45))
            if number==88:
                for i,(a,b) in enumerate([(0,1),(1,2),(2,3),(3,0),(0,2)]):
                    x,y=pts[a];xx,yy=pts[b];length=math.hypot(xx-x,yy-y)
                    name=svg(f'final_edge{i}',f'<path d="M4 4H{length+4}" stroke="#7d9191" stroke-width="6"/>',int(length+8),8,'Actual graph edge, independent from cosmetic traps.')
                    l.image(f'edge{i}',name,(x+xx)/2,(y+yy)/2,rotation_degrees=math.degrees(math.atan2(yy-y,xx-x)),z_index=-2)
            l.drag('pen','final_trace_pen',650,480 if number==85 else 500 if number!=88 else 520,state=dict(trace=True),scale=[.7,.7])
            l.d['objects'][-1]['interactions'][0]['bounds']=[250,460,1420,560]
            if number==88:l.drag('pen_c','final_trace_pen',1150,880,state=dict(trace=True),scale=[.7,.7])
            if number in [80,95]:l.text('gesture','قلم را پیوسته بکش',1420,530,size=(500,80))
        elif number==81:
            model.update(kind='hanoi')
            for i in range(3):l.image(f'peg{i}','final_peg',500+i*460,690);l.zone(f'rod{i}',500+i*460,690,[f'ring{j}' for j in range(4)],(300,360))
            for i in reversed(range(4)):l.drag(f'ring{i}',f'final_ring_{i}',500,840-(3-i)*55)
        elif number==87:
            model.update(kind='pour',capacities=[8,5,3],volumes=[8,0,0])
            for i,(x,cap) in enumerate(zip([500,960,1420],[8,5,3])):
                l.drag(f'jug{i}','final_jug8_8' if i==0 else f'measuring_jug_{cap}_0',x,670,scale=[.65,.65]);l.socket(f'jugzone{i}',x,670,[f'jug{j}' for j in range(3) if j!=i],(220,220));l.text(f'volume{i}',f'{cap if i==0 else 0} / {cap}',x,850,size=(260,70))
        elif number==77:
            model.update(kind='eggs',floors=[])
            for i in range(1,101):
                x=450+((i-1)%10)*115;y=550+(((i-1)%20)//10)*180
                l.tile(f'floor{i}',str(i),x,y,size=(100,100),visible=i<=20);l.d['objects'][-1]['interactions']=[]
                l.zone(f'floorzone{i}',x,y,['egg'],(100,100));l.d['objects'][-1]['visible']=i<=20
            l.tile('floor_page','۱ تا۲۰ ↔',960,850,size=(350,70));l.d['objects'][-1]['interactions']=[dict(type='swipe',direction='any')]
            l.drag('egg','egg_assumption',1650,680,scale=[.65,.65]);l.text('program',' ',960,925,size=(1500,60))
            l.d['hint']='برای انتخاب طبقه، نوار بازه را به راست بکش تا۲۰طبقهٔ بعد دیده شود. تخم‌مرغ را به ترتیب روی۱۴،۲۷،۳۹،۵۰،۶۰،۶۹،۷۷،۸۴،۹۰،۹۵،۹۹،۱۰۰ببر. اگر اولی بشکند، دومی طبقات ناشناختهٔ زیر آن را از پایین یک‌به‌یک می‌سنجد. شبیه‌ساز همهٔ۱۰۱آستانه را با همین برنامه و حد۱۴بررسی می‌کند.'
        elif number==79:
            model.update(kind='bags')
            l.text('masses','سالم۱۰گرم؛ تقلبی۹گرم',960,450,size=(1000,65))
            for i in range(10):
                l.tile(f'bag{i}',str(i+1),350+(i%5)*290,590+(i//5)*220,True);l.d['objects'][-1]['interactions']+=['tap','hold'];l.text(f'count{i}',f'{i+1} → 0',350+(i%5)*290,660+(i//5)*220,size=(230,60))
            l.socket('sample',1650,700,[f'bag{i}' for i in range(10)],(170,190));l.text('sample_count','0 سکه',1650,700,size=(160,140));l.tile('weigh','توزین',1650,880,size=(180,90))
            l.d['hint']='زیر هر کیسه تعداد سکهٔ بستهٔ برداشت و تعداد نمونهٔ روی ترازو دیده می‌شود. لمس کیسه اندازهٔ بسته را۱تا۱۰تغییر می‌دهد؛ کشیدن آن روی سینی همان بسته را جایگزین نمونهٔ قبلی می‌کند. بسته‌های۱تا۱۰را از کیسه‌های۱تا۱۰بردار.۵۵سکهٔ سالم باید۵۵۰گرم باشد؛ یک توزین۵۴۳نشان می‌دهد. کمبود۷گرم یعنی کیسه۷؛ همان کیسه را نگه دار.'
        elif number==82:
            model.update(kind='prisoners',permutation=[2,3,4,5,1,7,8,9,10,6])
            for i in range(10):l.tile(f'box{i}',i+1,350+(i%5)*290,580+(i//5)*240,size=(150,150))
            l.text('prisoner','نفر۱؛ از جعبه۱شروع کن',960,450,size=(1300,70))
        elif number==86:
            model.update(kind='rectangles',origin=[650,480],spacing=52,line_count=9)
            for axis in range(2):
                for j in range(9):
                    name=svg(f'final_gridline{axis}_{j}',f'<path d="M4 4{("V420" if axis==0 else "H420")}" stroke="#506e75" stroke-width="4"/>',8 if axis==0 else 424,424 if axis==0 else 8,'Grid selection lines with explicit nine-line boundaries.')
                    l.image(f'line{axis}_{j}',name,650+j*52 if axis==0 else 858,688 if axis==0 else 480+j*52)
                for i in range(2):
                    l.tile(f'clip{axis}_{i}','↔' if axis==0 else '↕',1350+i*160,600+axis*180,True)
                    l.d['objects'][-1]['interactions']=l.d['objects'][-1]['interactions'][:1]
                    l.d['objects'][-1]['interactions'][0]['return_on_invalid']=False
            l.tile('combinations','خط‌کش ترکیب‌ها',1450,460,size=(410,90));l.d['objects'][-1]['interactions']=['hold']
        elif number==94:
            model.update(kind='rays',lanterns=[[400,660,1,0],[400,760,1,0],[400,860,1,0]],targets=[[800,500],[1100,500],[1400,500]],slots=[[800,660],[1100,760],[1400,860],[1550,660],[1550,860]],initial=[3,1,4],orientations=['/','/','/'],obstacles=[])
            for i,(x,y) in enumerate(model['targets']):l.image(f'target{i}','final_dot',x,y);l.text(f'lit{i}','○',x,y-55,size=(80,60))
            for i,(x,y,_,_) in enumerate(model['lanterns']):l.image(f'lantern{i}','bridge_lantern_lit',x,y,scale=[.45,.45])
            for i,(x,y) in enumerate(model['slots']):l.socket(f'slot{i}',x,y,[f'mirror{j}' for j in range(3)],(90,90))
            for i,s in enumerate(model['initial']):l.tile(f'mirror{i}','/',*model['slots'][s],True,size=(80,80))
            l.tile('light','روشن‌کردن',1650,500,size=(220,90))
        elif number==99:
            masks=[10,10,12,6,10,9,3,10,10]
            model.update(kind='pipes',target=masks,turns=[1,2,3,1,2,3,1,2,3],base_angles=[{6:0,12:90,9:180,3:270,10:0}[mask] for mask in masks])
            for i,mask in enumerate(masks):
                turns=model['turns'][i];l.image(f'pipe{i}',f'final_pipe_{10 if mask==10 else 6}',750+(i%3)*140,540+(i//3)*140,['tap'],rotation_degrees=(turns*90+model['base_angles'][i])%360)
            l.text('inlet','آب →',480,540,size=(220,70));l.text('outlet','→ حوض',1280,820,size=(220,70));l.tile('water','شیر آب',1450,650,size=(220,110))
        elif number==101:
            model.update(kind='latin',fixed=[1,0,0,4,0,3,4,0,0,4,1,0,4,0,0,3])
            for i,v in enumerate(model['fixed']):
                x,y=650+(i%4)*145,465+(i//4)*115
                l.tile(f'cell{i}',v if v else '·',x,y,size=(105,95));l.d['objects'][-1]['interactions']=[]
                if v:l.d['objects'][-1]['sprite']=P+'final_fixed_cell.svg'
                if not v:l.zone(f'cellzone{i}',x,y,[f'number{j}' for j in range(1,6)],(105,95))
            for j in range(1,6):l.tile(f'number{j}',j,600+j*190,920,True,size=(95,85))
        model['level']=number;l.variable(model=json.dumps(model,ensure_ascii=False));l.save()


def update_scenarios():
    methods={
        71:'هر چهار ساعت را Tap بررسی کن؛ ساعت ناسازگار را با Hold انتخاب کن.',
        72:'سکه‌ها را روی کفه‌ها یا سینی بازگشت Drop کن؛ سه توزین طبق درخت پیوست و حذف نامزدهای۲۴فرض، سپس تعیین هویت و سبک/سنگین.',
        73:'یک کارت پرسش روی نگهبان Drop کن؛ در مخالف اشاره را با Swipe چپ باز کن. پرسش مستقیم فرصت یگانه را مصرف می‌کند.',
        74:'کارت افراد را در دو ردیف پسر/دختر بچین یا به بیرون ردیف برگردان؛ تعداد واقعی اعضا هر دو رابطه را تعیین می‌کند.',
        75:'ارقام۱۱۱۲۲۱را در سه گروه Drag کن؛ توصیف هر گروه پس از تکمیل آشکار می‌شود. سه توصیف حاصل را به ترتیب خواندن کنار هم بگذار.',
        76:'باتری را بیرون بکش؛ دو Swipe راست روی چرخه، دو نیمهٔ۱۲ساعته را با تطابق‌های۱و۱۳بررسی می‌کنند.',
        77:'نوار بازه را Swipe کن تا۲۰طبقهٔ بعدی دیده شود؛ نشانگر تخم‌مرغ را روی طبقات برنامه Drop کن. برنامهٔ منتهی به۱۰۰برای همهٔ۱۰۱آستانه سنجیده می‌شود.',
        78:'شمار هر رنگ را Hold بررسی کن؛ دومینو را روی جفت دورنگ و سپس دو باقی‌ماندهٔ هم‌رنگ آزمایش کن تا نابرابری رنگ‌ها پوشش را رد کند.',
        79:'Tap کیسه اندازه بستهٔ نمونه را تغییر می‌دهد؛ Drag روی سینی همان بسته را منتقل/جایگزین می‌کند. فقط یک توزین و سپس Hold کیسهٔ استنتاج‌شده.',
        80:'با یک Drag قلم، چهار خط پیوسته را حتی بیرون مربع فرضی بکش؛ نمونه‌های مرکز واقعی قلم پوشش نقاط و راست‌بودن خط‌ها را مشخص می‌کنند.',
        81:'هر بار یک حلقه را بین سه میله Drag/Drop کن؛ فقط بالایی و بدون بزرگ‌روی‌کوچک.',
        82:'برای هر۱۰نفر از جعبهٔ شمارهٔ خودش با Tap شروع کن و شمارهٔ داخل را دنبال کن؛ سقف۵بازکردن برای هر نفر.',
        83:'سه برش بازشده همهٔ مکعبچه‌های بیرونی را نشان می‌دهند؛ Swipe کنترل چرخش، نما را با حفظ هویت/انتخاب عوض می‌کند. Tap انتخاب/لغو می‌کند.',
        84:'شش پوستهٔ۴×۴را به سینی کنار بکش؛ هسته پس از برداشتن همهٔ پوسته‌ها آشکار می‌شود. هر۸مکعبچهٔ بی‌رنگ را Tap کن.',
        85:'از گوشهٔ بالاچپ تا قطر مربع‌های ضلع۱تا۸قلم بکش؛ قاب مربع و تعداد جایگاه‌های هر اندازه محاسبه و جمع می‌شود.',
        86:'چهار گیره را روی دو خط عمودی و دو خط افقی متفاوت بکش؛ Hold خط‌کش تعداد جفت خط‌ها و حاصل۳۶×۳۶را محاسبه می‌کند.',
        87:'ظرف را روی ظرف دیگر Drop کن؛ حجم واقعی تا پرشدن مقصد یا خالی‌شدن مبدأ منتقل و سطح آب به‌روز می‌شود.',
        88:'از قلمAیاCدر یک گرفتن روی یال‌ها بکش؛ یال تکراری، حرکت بیرون گراف و پوشش ناقص رد می‌شود.',
        89:'دو سیم سالم را میان باتری→کلید و کلید→لامپ بگذار؛ برگشت ثابت است. Tap کلید مدار سالمِ کامل را روشن می‌کند.',
        90:'Tap قطعه۹۰درجه می‌چرخاند؛ سپس در قاب کنار محور عمودی Drop کن. همهٔ مرزها و نقش نامتقارن باید بازتاب منطبق باشند.',
        91:'هر بار یک وزنه روی هر کفه و Tap توزین؛ سپس ترتیب سبک تا سنگین را بچین. سقف۵مقایسه و یکتایی ترتیب لازم است.',
        92:'مهرهای۱،۲،۴،۷را در چهار جای قفل بچین و دستگیره را لمس کن؛ سرنخ‌ها در صحنه‌اند و بازخورد فقط تعداد جای درست است.',
        93:'یکی از دو کاشی جابه‌جا را روی سینی موقت بگذار، دیگری را در جای خالی و سپس اولی را در جای خالی دوم ببر؛ همهٔ اتصال‌ها و نقش متقارن اصلی لازم‌اند.',
        94:'آینه‌ها را میان جایگاه‌ها Drag کن و فانوس‌ها را روشن کن؛ پرتو واقعی رسم و کمینهٔ تغییر با جست‌وجوی تمام چیدمان‌های مجاز محاسبه می‌شود.',
        95:'قلم را در یک گرفتن روی همسایه‌های افقی/عمودی فرش۳×۳بکش؛۹خانهٔ یکتا، مقصد و مسیر واقعی بین آن‌ها بررسی می‌شود.',
        96:'مهره‌ها را آزادانه میان کفه‌ها و سینی Drag کن؛ فقط توزین بودجه مصرف می‌کند. پس از یکتاشدن نامزد، آن را در محل تشخیص بگذار.',
        97:'Tap کاسه۹۰درجه می‌چرخاند؛ کاسهٔ مطابق را رویAثابت Drop کن. AوCیک تصویر مشترک با جهت اولیه متفاوت دارند.',
        98:'قطعه را با Tap۹۰درجه بچرخان و در قاب۲×۲ Drop کن؛ تمام مرزها، نقش مرکز و نشان جهت باید درست باشند.',
        99:'Tap لوله۹۰درجه می‌چرخاند؛ Tap شیر، اتصال واقعی آب و همهٔ خروجی‌های باز قطعات متصل را می‌سنجد و جریان را نشان می‌دهد.',
        100:'کلیدها را روی قفل صندوق‌هایA/B/Cبکش؛ اشغال یکتا و همهٔ سرنخ‌ها لازم‌اند و انتخاب قابل اصلاح است.',
        101:'مهر عدد را در خانهٔ خالی Drop کن؛ مهر به مخزن برمی‌گردد. ثابت‌ها نشان گوشه دارند و تکرار سطر/ستون بازخورد دیداری دارد.'}
    path=ROOT/'docs/100_interactive_persian_puzzles.md'
    content=path.read_text(encoding='utf-8').rstrip()+'\n'
    lines=[]
    for line in content.splitlines():
        parts=line.split('|')
        if len(parts)>2 and parts[1].strip().isdigit() and int(parts[1].strip()) in methods:
            parts[8]=' '+methods[int(parts[1].strip())]+' '
            line='|'.join(parts)
        lines.append(line)
    content='\n'.join(lines)+'\n'
    content=content.replace('(۸۰۰،۴۵۰)،(۱۱۰۰،۴۵۰)،(۱۴۰۰،۴۵۰)','(۸۰۰،۵۰۰)،(۱۱۰۰،۵۰۰)،(۱۴۰۰،۵۰۰)')
    marker='## تنظیم اجرایی۷۱تا۱۰۱ — 2026-10-16'
    if marker not in content:
        content+='\n'+marker+'\n\nتعامل اجرایی جدول با قواعد محتوایی هماهنگ شد؛ پاسخ‌ها و زمان/امتیاز جدول حفظ شدند.۷۸با شاهد نابرابری رنگ‌ها و۸۵با ساخت هشت اندازه حل می‌شوند؛ کارت پاسخ آماده ندارند. بسته‌های نمونهٔ۷۹قابل تغییرند،۷۷همهٔ آستانه‌ها را می‌سنجد و۸۰/۸۸/۹۵مسیر واقعی یک گرفتن را بررسی می‌کنند.\n\nهندسهٔ۹۴ در متغیر model مرحله ثبت است: فانوس‌های(۴۰۰،۶۶۰)،(۴۰۰،۷۶۰)،(۴۰۰،۸۶۰)به راست؛ هدف‌های(۸۰۰،۴۵۰)،(۱۱۰۰،۴۵۰)،(۱۴۰۰،۴۵۰)؛ جایگاه‌های(۸۰۰،۶۶۰)،(۱۱۰۰،۷۶۰)،(۱۴۰۰،۸۶۰)،(۱۵۵۰،۶۶۰)،(۱۵۵۰،۸۶۰)، سه آینهٔ/و شروع۳،۱،۴با شماره‌گذاری صفر، بدون مانع. حل‌گر کمینه را محاسبه می‌کند؛ آزمونِ سازندهٔ دو تغییر نوشته شده، اجرا نشده است. جدول لبه/نقش۹۰/۹۳/۹۷/۹۸و مسیر منابع در [گزارش منابع](final-chapters-assets.json) است؛ پذیرش محتوا، تعادل و چیدمان تأیید نشده‌اند.\n'
    content=content.replace('(۸۰۰،۴۵۰)،(۱۱۰۰،۴۵۰)،(۱۴۰۰،۴۵۰)','(۸۰۰،۵۰۰)،(۱۱۰۰،۵۰۰)،(۱۴۰۰،۵۰۰)')
    path.write_text(content,encoding='utf-8')
    path=ROOT/'docs/engine-implementation-plan.md'
    content=path.read_text(encoding='utf-8').replace('و۳۱تا۷۰ در 2026-10-15 پیاده‌سازی شده','،۳۱تا۷۰ در 2026-10-15 و۷۱تا۱۰۱ همراه API اختصاصی در 2026-10-16 پیاده‌سازی شده').replace('2026-10-14 ،۳۱','2026-10-14،۳۱')
    path.write_text(content,encoding='utf-8')


def main():
    update_scenarios()
    assets();rules_levels();fit_levels();algorithm_levels()
    manifest=dict(schema_version=1,manifest_version=10,levels=[dict(id=i,path=f'res://PuzzleEngine/PuzzleData/{i:03}.json') for i in range(1,102)])
    (DATA/'manifest.json').write_text('{\n  "schema_version": 1,\n  "manifest_version": 10,\n  "levels": [\n'+',\n'.join('    { '+json.dumps(entry)[1:-1]+' }' for entry in manifest['levels'])+'\n  ]\n}\n',encoding='utf-8')
    (ROOT/'docs/final-chapters-assets.json').write_text(json.dumps(dict(stages=REPORT,new_assets=NEW,matching=dict(order='N,E,S,W',motifs=[[0,1,2,3],[0,3,2,1],[1,2,3,0],[0,1,3,2]],reflection=dict(source=0,target=1,axis='vertical',chiral_center_mirrored=True),bowls=dict(pair=['A','C'],C_initial_angle=90,mirror_decoy='B',detail_decoy='D'),jigsaw=[[4,0,1,5],[6,7,2,0],[1,3,8,9],[2,10,11,3],[4,0,1,5]],jigsaw_center=['diamond','diamond','diamond','diamond','circle'],symmetry=[[None,0,1,None],[None,0,None,0],[None,None,1,0],[1,2,3,None],[None,2,None,2],[1,None,3,2],[3,4,None,None],[None,4,None,4],[3,None,None,4]],symmetry_initial=[0,1,2,5,4,3,6,7,8]),acceptance='Not run; explicit test instruction required.'),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


if __name__=='__main__':main()
