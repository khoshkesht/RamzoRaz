/** Author the interaction redesigns for 60–70. Writes content; never imports or runs Godot. */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const file=p=>path.join(root,p), P='res://assets/samples/';
const read=n=>JSON.parse(fs.readFileSync(file(`PuzzleEngine/PuzzleData/${String(n).padStart(3,'0')}.json`),'utf8'));
const write=d=>fs.writeFileSync(file(`PuzzleEngine/PuzzleData/${String(d.id).padStart(3,'0')}.json`),JSON.stringify(d,null,2)+'\n');
const assets={},changed=[];
function svg(name,body,w,h,reason){fs.writeFileSync(file(`assets/samples/${name}.svg`),`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><g stroke="#48575d" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">${body}</g></svg>\n`);assets[P+name+'.svg']=reason;}
const fa=s=>String(s).replace(/[0-9]/g,n=>'۰۱۲۳۴۵۶۷۸۹'[n]);
const v=(name,value=true,operator='eq')=>({type:'variable',name,value,operator});
const sv=(name,value=true,operation='assign')=>({type:'set_variable',name,value,operation});
const show=target=>({type:'show',target}),hide=target=>({type:'hide',target});
const move=(target,x,y)=>({type:'move',target,position:[x,y]});
const replace=(target,name)=>({type:'replace_sprite',target,sprite:P+name+'.svg'});
const rotate=(target,degrees)=>({type:'rotate',target,degrees});
const scale=(target,x,y=x)=>({type:'scale',target,value:[x,y]});
const inside=(target,zone)=>({type:'inside',target,zone});
const not=condition=>({type:'not',condition});
const fail={type:'fail_level'};
class Stage{
 constructor(n,hint){this.d=read(n);this.d.time_limit_seconds=({62:140,64:130,66:145,67:145,68:130,69:145,70:170})[n]??this.d.time_limit_seconds;this.d.hint=hint;this.d.variables={solved:false};this.d.objects=[];this.d.rules=[];this.d.counters=[];this.d.win_condition=v('solved');}
 vars(x){Object.assign(this.d.variables,x);}
 image(id,name,x,y,inputs=[],extra={}){this.d.objects.push({id,scene:inputs.length?'ClickableObject':'ImageObject',sprite:P+name+'.svg',position:[x,y],interactions:inputs,...extra});}
 text(id,text,x,y,size=[300,70],inputs=[],extra={}){this.d.objects.push({id,scene:'TextObject',text:fa(text),position:[x,y],hit_size:size,text_color:'#354f54',interactions:inputs,...extra});}
 button(id,text,x,y){this.image(id+'_frame','puzzle_tile',x,y,[],{scale:[1.2,1.1],z_index:-2});this.text(id,text,x,y,[336,120],['tap']);}
 drag(id,name,x,y,extra={}){this.image(id,name,x,y,[{type:'drag',bounds:[200,430,1520,500],return_on_invalid:true},'drop_on'],{z_index:7,...extra});}
 zone(id,x,y,sources,size=[200,160],visible=true){this.d.objects.push({id,scene:'DropZone',position:[x,y],hit_size:size,accepted_sources:sources,z_index:-2,visible});}
 rule(event,source,actions,conditions=[],once=false,target){const r={id:'r'+String(this.d.rules.length).padStart(4,'0'),event,actions,conditions,once};if(source!==null)r.source=source;if(target)r.target=target;this.d.rules.push(r);}
 drop(source,target,actions,conditions=[],once=false){this.rule('drop_on',source,actions,conditions,once,target);}
 win(event,source,conditions,actions=[]){this.rule(event,source,[...actions,sv('solved')],conditions);}
 save(){write(this.d);changed.push(this.d.id);}
}

// 60: the entire visible nine-slot mat is the return destination.
{
 const d=read(60),reason='سینی بازگشت با نه جای سکه هم‌مکان با محل اولیه؛ مقصد قبلی تصویر و وسعت کافی نداشت.';
 svg('coin_return_mat','<rect x="5" y="5" width="1370" height="140" rx="28" fill="#e5d7b5" stroke="#a18b61"/>'+Array.from({length:9},(_,i)=>`<circle cx="${90+i*150}" cy="55" r="48" fill="#f5ebd3" stroke="#b39a6c" stroke-dasharray="9 8"/>`).join(''),1380,150,reason);
 const zone=d.objects.find(o=>o.id==='tray');zone.position=[960,940];zone.hit_size=[1380,150];
 d.objects=d.objects.filter(o=>!['instructions','return_mat','return_label'].includes(o.id));
 d.objects.unshift({id:'return_mat',scene:'ImageObject',sprite:P+'coin_return_mat.svg',position:[960,940],interactions:[],z_index:-3});
 d.objects.push({id:'return_label',scene:'TextObject',text:'سینی سکه‌ها',position:[960,1040],hit_size:[450,55],text_color:'#354f54',interactions:[]});
 d.hint='سکه‌ها را از سینی پایین روی دو کفه بکش؛ برای حذف هر سکه از ترازو، آن را به هر قسمت سینیِ نه‌جای پایین برگردان. اول سه سکه را با سه سکه بسنج. اگر برابر شدند، سه سکهٔ بیرون ترازو مشکوک‌اند؛ اگر برابر نشدند، سه سکهٔ کفهٔ سبک‌تر مشکوک‌اند. هر دو کفه را روی سینی خالی کن؛ دو سکه از سه مشکوک را یکی در هر کفه بگذار و «توزین» را لمس کن. اگر برابرند سکهٔ سوم سبک است، وگرنه سکهٔ کفهٔ سبک‌تر پاسخ است. همان سکه را لمس کن.';
 write(d);changed.push(60);
}

// 61: tap a cargo to load/unload; tap the actual boat to travel, empty or loaded.
{
 const s=new Stage(61,'هر محموله را لمس کن تا سوار قایق شود؛ لمس دوباره آن را پیاده می‌کند. خود قایق را لمس کن تا عبور کند؛ قایق خالی هم حرکت می‌کند. ترتیب: بز را ببر، خالی برگرد؛ گرگ را ببر، بز را برگردان؛ کلم را ببر، خالی برگرد؛ بز را ببر. گرگ و بز یا بز و کلم نباید بدون قایقران در یک سمت بمانند.');
 s.vars({bank:0,mask:0,cargo:-1,transition:false});
 ['wolf','goat','cabbage'].forEach((name,i)=>{s.image('cargo_'+i,name,380,520+i*160,['tap'],{scale:[.65,.65],z_index:5});s.image('selected_'+i,'selection_check',650,820,[],{visible:false,scale:[.55,.55],z_index:6});});
 s.image('boat','boat_empty',590,940,['tap'],{scale:[.8,.8],hit_size:[360,170],z_index:3});
 s.image('direction','left_arrow',790,940,[],{scale:[.5,.5],rotation_degrees:180});
 for(let bank=0;bank<2;bank++)for(let mask=0;mask<8;mask++)for(let cargo=-1;cargo<3;cargo++){
  if(cargo>=0&&(mask>>cargo&1)!==bank)continue;
  const c=[v('bank',bank),v('mask',mask),v('cargo',cargo),v('transition',false)];
  for(let i=0;i<3;i++)if((mask>>i&1)===bank&&(cargo===-1||cargo===i))s.rule('tap','cargo_'+i,[sv('cargo',cargo===i?-1:i),sv('transition')],c);
  const dest=1-bank,m=cargo<0?mask:mask^(1<<cargo),unsafe=[[0,1],[1,2]].some(pair=>pair.every(i=>(m>>i&1)===bank));
  s.rule('tap','boat',[sv('transition'),sv('bank',dest),sv('mask',m),sv('cargo',-1),...(unsafe?[fail]:[])],c);
 }
 s.rule('tap',null,[sv('transition',false)]);
 for(let bank=0;bank<2;bank++){
  const bx=bank?1330:590;s.rule('tap',null,[move('boat',bx,940),move('direction',bank?1130:790,940),rotate('direction',bank?0:180)],[v('bank',bank)]);
  for(let cargo=-1;cargo<3;cargo++)for(let mask=0;mask<8;mask++){
   if(cargo>=0&&(mask>>cargo&1)!==bank)continue;
   const a=[];for(let i=0;i<3;i++)a.push(move('cargo_'+i,cargo===i?bx:(mask>>i&1)?1530:380,cargo===i?850:520+i*160),cargo===i?show('selected_'+i):hide('selected_'+i),move('selected_'+i,bx+60,800));
   s.rule('tap',null,a,[v('bank',bank),v('mask',mask),v('cargo',cargo)]);
  }
 }
 s.win('variable_changed','$level',[v('mask',7),v('bank',1)]);s.save();
}

// 62: investigate the dead lion, open its service hatch, unlock and enter the safe door.
{
 const s=new Stage(62,'روی درِ شیر نگه دار تا سرنخ سه سال بی‌غذایی آشکار شود؛ شیر بدون غذا زنده نمی‌ماند. دریچهٔ کوچک پایین همان در را به بالا بکش. کلید پشت دریچه را روی قفل طلایی در بکش و رها کن؛ سپس روی در به کنار بکش تا باز شود و ورودی را لمس کن. درهای آتش و قاتل همچنان خطرناک‌اند.');
 s.vars({lion_seen:false,hatch_open:false,unlocked:false,opened:false});
 svg('lion_service_hatch','<rect x="5" y="5" width="150" height="110" rx="8" fill="#917455"/><path d="M25 20V95M60 20V95M95 20V95M130 20V95" stroke="#c9c3a5" stroke-width="9"/><path d="M58 102H103" stroke="#d9bc78" stroke-width="9"/><path d="M65 45L80 28L95 45" fill="none" stroke="#ffe3a0" stroke-width="7"/>',160,120,'دریچهٔ کشویی کوچک برای دسترسی به کلید، بدون تغییر دارایی درِ شیر.');
 svg('door_keyhole_plate','<rect x="8" y="6" width="74" height="98" rx="13" fill="#d8bc7b"/><circle cx="45" cy="40" r="14" fill="#42575c"/><path d="M39 49H51L57 78H33Z" fill="#42575c"/>',90,110,'قفل طلایی دارای سوراخ کلید برای مقصد قابل تشخیص کلید.');
 ['door_fire','door_killer','door_lion'].forEach((name,i)=>{s.image('door_'+i,name,550+i*410,620,['hold','swipe'],{scale:[1.3,1.3]});s.text('clue_'+i,['آتش روشن','قاتل بیدار','سه سال بی‌غذا'][i],550+i*410,830,[350,70],[],{visible:false});s.rule('hold','door_'+i,[show('clue_'+i),...(i===2?[sv('lion_seen')]:[])]);});
 s.image('hatch','lion_service_hatch',1370,710,[{type:'swipe',direction:'up'}],{z_index:5});
 s.drag('key','toothed_key_b',1370,710,{scale:[.42,.42],visible:false,z_index:8});
 s.image('lock','door_keyhole_plate',1460,580);s.zone('keyhole',1460,580,['key'],[115,140]);
 s.image('passage','hidden_door',1370,620,['tap'],{visible:false,scale:[1.2,1.2]});
 s.rule('swipe','hatch',[hide('hatch'),show('key'),sv('hatch_open')],[v('lion_seen')],true);
 s.drop('key','keyhole',[hide('key'),hide('lock'),sv('unlocked')],[v('hatch_open')],true);
 s.rule('swipe','door_2',[hide('door_2'),hide('clue_2'),show('passage'),sv('opened')],[v('unlocked')],true);
 s.win('tap','passage',[v('opened')]);s.save();
}

// 63: preserve the real sand state model; replace gesture ambiguity with tap-to-flip.
{
 const d=read(63);d.hint='«شروع» را لمس کن تا هر دو ساعت با هم شروع شوند. دکمهٔ تصویریِ ساعت و فلش، زمان اندازه‌گیری را تا خالی‌شدن اولین ساعت جلو می‌برد. آن را بزن تا عدد ۷ دیده شود؛ ساعت ۷دقیقه‌ای را لمس کن تا برگردد. دوباره زمان را جلو ببر تا ۱۱؛ در ساعت۷ هنوز ۳ دقیقه شن مانده است. همان ساعت را لمس کن تا ۴ دقیقه شن در بالا بماند. یک بار دیگر زمان را جلو ببر؛ در ۱۵ دقیقه ساعت۷ خالی می‌شود و مرحله خودکار حل می‌شود.';
 svg('clock_next_boundary','<circle cx="83" cy="80" r="60" fill="#e3dbc1"/><path d="M83 37V81L112 97" fill="none" stroke="#647e7b" stroke-width="9"/><path d="m161 43 35 37-35 37m35-74 35 37-35 37" fill="none" stroke="#b7995e" stroke-width="12"/>',250,160,'کنترل تصویری جلو بردن زمان تا رویداد بعدی، مستقل از Countdown مرحله.');
 d.objects=d.objects.filter(o=>!['instructions','confirm','clock_frame','ruler','elapsed_plate','elapsed_label'].includes(o.id)&&!/^elapsed_\d+$/.test(o.id));
 for(const o of d.objects){if(['glass7','glass11'].includes(o.id))o.interactions=['tap'];if(o.id==='start')o.text='شروع';if(o.id==='next'){delete o.text;delete o.text_color;delete o.hit_size;o.scene='ClickableObject';o.sprite=P+'clock_next_boundary.svg';o.position=[960,960];o.visible=false;}}
 d.objects.push({id:'elapsed_plate',scene:'ImageObject',sprite:P+'puzzle_tile.svg',position:[960,420],scale:[1.7,1.2],interactions:[],z_index:-1},{id:'elapsed_label',scene:'TextObject',text:'زمان اندازه‌گیری',position:[960,330],hit_size:[550,65],text_color:'#354f54',interactions:[]});
 for(let t=0;t<=15;t++)d.objects.push({id:'elapsed_'+t,scene:'TextObject',text:fa(t)+' دقیقه',position:[960,420],hit_size:[450,85],text_color:'#354f54',interactions:[],visible:t===0});
 d.rules=d.rules.filter(r=>r.source!=='confirm'&&!['clock_frame','ruler'].includes(r.source)&&!r.actions.some(a=>a.target?.startsWith('elapsed_'))&&!r.actions.some(a=>a.name==='solved')); 
 for(const r of d.rules){if(r.event==='swipe'&&['glass7','glass11'].includes(r.source))r.event='tap';if(r.source==='start'&&r.actions.some(a=>a.name==='simulation')){r.actions=r.actions.filter(a=>!['start','next'].includes(a.target));r.actions.push(hide('start'),show('next'));}}
 const add=(event,source,actions,conditions)=>d.rules.push({event,source,actions,conditions,once:false});
 for(let t=0;t<=15;t++)add('variable_changed','$level',Array.from({length:16},(_,n)=>n===t?show('elapsed_'+n):hide('elapsed_'+n)),[v('minutes',t)]);
 add('variable_changed','$level',[sv('solved')],[v('minutes',15),v('remaining7',0)]);
 d.rules.forEach((r,i)=>r.id='r'+String(i).padStart(4,'0'));write(d);changed.push(63);
}

// 64: cleaning exposes the loose brick; removing it exposes a mechanical release.
{
 const s=new Stage(64,'برس را روی دیوار بکش و رها کن تا گرد کنار برود و ترک دور آجر وسط دیده شود. آجر میانی را به پایین بیرون بکش؛ پشت آن یک ضامن است. ضامن را به پایین بکش تا پنل دیوار کنار برود؛ سپس ورودی را لمس کن. نگه‌داشتن یا امتحان‌کردن آجرهای دیگر به‌تنهایی قفل را باز نمی‌کند.');
 s.vars({clean:false,removed:false,opened:false});
 svg('wall_dust_cover',Array.from({length:35},(_,i)=>`<ellipse cx="${35+(i*139)%930}" cy="${35+(i*83)%430}" rx="${22+i%4*8}" ry="9" fill="#c7b18a" opacity=".48" stroke="none"/>`).join(''),1000,480,'گردِ سطح دیوار برای پاک‌کردن واقعی با برس و آشکارشدن درز آجر.');
 s.image('door','hidden_door',960,700,['tap'],{visible:false,z_index:0});
 for(let i=0;i<9;i++){
  const x=650+i%3*310,y=550+Math.floor(i/3)*170;
  s.image('brick_'+i,'fixed_brick',x,y,i===4?[{type:'drag',axis:'y',bounds:[960,720,1,210],return_on_invalid:false}]:['tap'],{z_index:3});
 }
 s.image('dust','wall_dust_cover',960,710,[],{z_index:4});
 s.drag('brush','broom',1600,850,{scale:[.65,.65],z_index:8});s.zone('wall',960,710,['brush'],[1000,480]);
 s.drop('brush','wall',[move('brush',1600,850),hide('dust'),replace('brick_4','loose_brick'),sv('clean')],[],true);
 s.image('latch','floor_latch_closed',960,720,[{type:'swipe',direction:'down'}],{visible:false,z_index:5});
 s.rule('drag_end','brick_4',[hide('brick_4'),show('latch'),sv('removed')],[v('clean'),v('removed',false),{type:'moved_distance_at_least',value:110}]);
 s.rule('drag_end','brick_4',[move('brick_4',960,720)],[v('removed',false)]);
 s.rule('swipe','latch',[replace('latch','floor_latch_open'),...Array.from({length:9},(_,i)=>hide('brick_'+i)),hide('latch'),show('door'),sv('opened')],[v('removed')],true);
 s.win('tap','door',[v('opened')]);s.save();
}

// 66: fit three different rope sections into the worn channels, then pull the connected rope.
{
 const s=new Stage(66,'سه قطعهٔ طنابِ سمت چپ را با شکل شیارهای خالی روی مسیر زنگ تطبیق بده و هرکدام را در شیار هم‌شکل رها کن: قطعهٔ شکستهٔ زاویه‌دار بالا، منحنیِ گرد وسط و قطعهٔ پله‌ای پایین. بعد از کامل‌شدن هر سه اتصال، دستهٔ طناب وسط را به پایین بکش تا زنگ اصلی به صدا درآید.');
 s.d.question='مسیر طناب زنگ را کامل کن و زنگ اصلی را به صدا درآور.';
 s.d.answer='سه اتصال مسیر زنگ ترمیم می‌شوند؛ سپس کشیدن طناب میانی زنگ اصلی را فعال می‌کند.';
 s.vars({joined_0:false,joined_1:false,joined_2:false});
 const shapes=['M50 10L24 35L76 65L50 90','M50 10C95 26 95 74 50 90','M50 10V30H25V70H50V90'];
 shapes.forEach((d,i)=>svg('rope_repair_'+i,`<path d="${d}" fill="none" stroke="#b99a68" stroke-width="13"/><path d="${d}" fill="none" stroke="#e2c99a" stroke-width="3"/>`,100,100,'سه قطعهٔ طناب با مسیر متفاوت برای تطبیق با شیار و اتصال فیزیکی زنگ.'));
 const anchors=[[1000,560],[900,690],[1000,820]];
 const paths='<path d="M560 30V70H440V80M440 160V190H340V210M340 290V320H440V340M440 420V460H400V490M240 20V490M680 80V450H560V490" fill="none" stroke="#b99a68" stroke-width="13"/>';
 svg('rope_repair_channels',paths+anchors.map(([x,y],i)=>`<g transform="translate(${x-560-50} ${y-440-50})"><path d="${shapes[i]}" fill="none" stroke="#7e786a" stroke-width="20" opacity=".4"/><path d="${shapes[i]}" fill="none" stroke="#f1dfb5" stroke-width="5" stroke-dasharray="5 8"/></g>`).join(''),800,500,'مسیر زنگ با سه شیار خالیِ متفاوت و دو طناب فرعی متصل به وزنه؛ مسیر پیوستهٔ قبلی مناسب تعمیر نبود.');
 s.image('paths','rope_repair_channels',960,690);s.image('main_bell','bell',1120,460,[],{scale:[.6,.6]});
 s.image('left_weight','stone',800,460,[],{scale:[.4,.4]});s.image('right_weight','stone',1240,520,[],{scale:[.4,.4]});
 anchors.forEach(([x,y],i)=>{s.drag('link_'+i,'rope_repair_'+i,380,530+i*170);s.zone('gap_'+i,x,y,['link_'+i],[110,110]);s.image('fixed_'+i,'rope_repair_'+i,x,y,[],{visible:false,z_index:4});s.drop('link_'+i,'gap_'+i,[hide('link_'+i),show('fixed_'+i),sv('joined_'+i)],[],true);});
 for(let i=0;i<3;i++)s.image('rope_'+i,'rope_pull',800+i*160,930,[{type:'drag',axis:'y',bounds:[800+i*160,900,1,110],return_on_invalid:false}],{scale:[.65,.65],z_index:5});
 const enough=[v('joined_0'),v('joined_1'),v('joined_2'),{type:'moved_distance_at_least',value:60}];
 s.win('drag_end','rope_1',enough,[{type:'play_animation',target:'main_bell',animation:'chapter_two/rattle',wait:false},{type:'play_sound',sound:'res://assets/samples/radio_chime.wav',wait:false}]);
 for(let i=0;i<3;i++)s.rule('drag_end','rope_'+i,[move('rope_'+i,800+i*160,930)]);
 s.save();
}

// 67: construct a jug under the lamp instead of selecting a ready-made answer.
{
 const s=new Stage(67,'بدنهٔ کوزه را از پایینِ سمت چپ روی پایهٔ خالی سمت راست بگذار. از دو گردن، گردن باریک را بالای بدنه نصب کن؛ گردن پهن با سایهٔ هدف جور نیست. دسته را روی لبهٔ راست بدنه قرار بده؛ سایهٔ هدف دستهٔ راست دارد. در آخر خودِ چراغ بالای میز را لمس کن تا سایهٔ کوزهٔ ساخته‌شده با هدف مقایسه شود. اگر گردن یا سمت دسته غلط بود، همان قطعه را جابه‌جا و دوباره چراغ را آزمایش کن.');
 s.d.question='کوزه‌ای بساز که سایه‌اش با نمونهٔ سمت چپ یکی باشد.';s.d.answer='بدنه با گردن باریک و دستهٔ سمت راست، زیر نور همان سایهٔ هدف را می‌سازد.';
 s.vars({body:false,neck:0,handle:0});
 svg('shadow_build_body','<path d="M95 63H145Q225 89 210 163Q200 193 145 193T80 163Q65 89 95 63Z" fill="#bca17a"/>',240,200,'بدنهٔ جدا از گردن و دسته برای ساخت فیزیکی کوزه.');
 for(const width of [50,85])svg('shadow_neck_'+width,`<path d="M${60-width/2} 15H${60+width/2}V90H${60-width/2}Z" fill="#bca17a"/><ellipse cx="60" cy="15" rx="${width/2}" ry="8" fill="#776950"/>`,120,110,'گردن‌های باریک و پهن مستقل برای تطبیق شکل سایه.');
 svg('shadow_build_handle','<path d="M15 22Q95 0 75 91L15 111" fill="none" stroke="#927c61" stroke-width="14"/>',110,130,'دستهٔ جدا برای نصب در سمت چپ یا راست کوزه.');
 s.image('target','jug_shadow_target',470,610);s.image('work_base','puzzle_tile',1250,740,[],{scale:[1.15,.5],z_index:-1});
 s.drag('body','shadow_build_body',450,900);s.zone('body_zone',1250,650,['body'],[260,230]);
 s.drag('neck_narrow','shadow_neck_50',800,900);s.drag('neck_wide','shadow_neck_85',1060,900);
 s.zone('neck_zone',1250,535,['neck_narrow','neck_wide'],[150,120]);
 s.drag('handle','shadow_build_handle',1420,900);s.zone('handle_right',1390,650,['handle'],[130,180]);s.zone('handle_left',1110,650,['handle'],[130,180]);
 s.image('lamp','lamp_off',960,460,['tap'],{scale:[.65,.65]});s.image('cast_shadow','jug_shadow_target',770,610,[],{visible:false});
 s.text('sample_label','نمونه',470,780,[220,60]);s.text('shadow_label','سایه',770,780,[220,60]);
 s.drop('body','body_zone',[move('body',1250,650),sv('body')]);
 for(const [id,value] of [['neck_narrow',1],['neck_wide',2]])s.drop(id,'neck_zone',[move(id,1250,535),sv('neck',value),move(value===1?'neck_wide':'neck_narrow',value===1?1060:800,900),hide('cast_shadow'),replace('lamp','lamp_off')],[v('body')]);
 for(const [zone,value,x,angle] of [['handle_right',1,1390,0],['handle_left',2,1110,180]])s.drop('handle',zone,[move('handle',x,650),rotate('handle',angle),sv('handle',value),hide('cast_shadow'),replace('lamp','lamp_off')],[v('body')]);
 s.rule('drag_start','body',[sv('body',false),hide('cast_shadow'),replace('lamp','lamp_off')]);
 for(const id of ['neck_narrow','neck_wide'])s.rule('drag_start',id,[sv('neck',0),hide('cast_shadow'),replace('lamp','lamp_off')],[v('neck',id==='neck_narrow'?1:2)]);
 s.rule('drag_start','handle',[sv('handle',0),hide('cast_shadow'),replace('lamp','lamp_off')]);
 for(const o of s.d.objects)if(['body','neck_narrow','neck_wide','handle'].includes(o.id))o.interactions[0].return_on_invalid=false;
 s.rule('drag_end','body',[move('body',450,900)],[not(inside('body','body_zone'))]);
 for(const [id,x] of [['neck_narrow',800],['neck_wide',1060]]){
  s.drop(id,'neck_zone',[move(id,x,900)],[v('body',false)]);
  s.rule('drag_end',id,[move(id,x,900)],[not(inside(id,'neck_zone'))]);
 }
 for(const zone of ['handle_left','handle_right'])s.drop('handle',zone,[move('handle',1420,900)],[v('body',false)]);
 s.rule('drag_end','handle',[move('handle',1420,900)],[not({type:'any',conditions:[inside('handle','handle_left'),inside('handle','handle_right')]})]);
 for(let neck=1;neck<=2;neck++)for(let hand=1;hand<=2;hand++){
  const name=neck===1&&hand===1?'jug_shadow_target':'assembled_shadow_'+neck+'_'+hand;
  if(name!=='jug_shadow_target'){
   const w=neck===1?50:85;
   svg(name,'<path d="M'+(120-w/2)+' 15h'+w+'v48q80 26 65 100-10 30-65 30t-65-30q-15-74 65-100Z" fill="#566264"/><path d="'+(hand===1?'M183 78q52-8 31 58l-16 8':'M57 78q-52-8-31 58l16 8')+'" fill="none" stroke="#566264" stroke-width="13"/>',240,200,'سایهٔ واقعی گردن پهن یا دستهٔ چپ برای بازخورد آزمایش ساخت اشتباه.');
  }
  s.rule('tap','lamp',[replace('lamp','lamp_on'),replace('cast_shadow',name),show('cast_shadow')],[v('body'),v('neck',neck),v('handle',hand)]);
 }
 s.win('tap','lamp',[v('body'),v('neck',1),v('handle',1)]);s.save();
}

// 68: the inverted book is a release, not an immediate win.
{
 const s=new Stage(68,'کتاب وارونهٔ وسط را به پایین بیرون بکش تا ضامن پشت آن آشکار شود. ضامن را رو به پایین آزاد کن؛ سپس خودِ قفسه را به راست بکش تا در پنهان نمایان شود. برای پایان، ورودی را لمس کن. کتاب‌های مستقیم به سازوکار قفل وصل نیستند.');
 s.vars({released:false,unlocked:false,opened:false});
 s.image('door','hidden_door',960,650,['tap'],{visible:false,z_index:0});
 s.image('shelf','bookshelf',960,650,[{type:'drag',axis:'x',bounds:[960,650,540,1],return_on_invalid:false}],{scale:[1.8,1.2],z_index:2});
 for(let i=0;i<3;i++)s.image('book_'+i,i===1?'inverted_book':'upright_book',800+i*160,650,[{type:'drag',axis:'y',bounds:[800+i*160,650,1,240],return_on_invalid:false}],{scale:[.7,.7],z_index:5});
 s.image('book_latch','floor_latch_closed',960,650,[{type:'swipe',direction:'down'}],{visible:false,z_index:6});
 s.rule('drag_end','book_1',[hide('book_1'),show('book_latch'),sv('released')],[v('released',false),{type:'moved_distance_at_least',value:150}]);
 for(let i=0;i<3;i++)s.rule('drag_end','book_'+i,[move('book_'+i,800+i*160,650)],i===1?[v('released',false)]:[]);
 s.rule('swipe','book_latch',[replace('book_latch','floor_latch_open'),sv('unlocked')],[v('released')],true);
 s.rule('drag_end','shelf',[move('shelf',1500,650),...Array.from({length:3},(_,i)=>hide('book_'+i)),hide('book_latch'),show('door'),sv('opened')],[v('unlocked'),{type:'moved_distance_at_least',value:350}]);
 s.rule('drag_end','shelf',[move('shelf',960,650)],[v('opened',false)]);
 s.rule('drag_end','shelf',[move('shelf',1500,650)],[v('opened')]);
 s.win('tap','door',[v('opened')]);s.save();
}

// 69: restore three different motifs, with orientation determined by the mirrored left half.
{
 const s=new Stage(69,'فرش میانی سه نقش در نیمهٔ راست کم دارد. سه قطعهٔ پایین صفحه را با نقش‌های همان ردیف در نیمهٔ چپ مقایسه کن. لمس هر قطعه آن را ۹۰ درجه می‌چرخاند. برگ را یک بار و نقش نعلی را دو بار لمس کن؛ لوزی از ابتدا درست است. سپس برگ را در خانهٔ بالاییِ راست، لوزی را در خانهٔ وسطِ راست و نعل را در خانهٔ پایینیِ راستِ فرش میانی بگذار.');
 s.d.question='نقش‌های فرش ناقص را با حفظ تقارن ترمیم کن.';s.d.answer='سه نقشِ درست با جهت صحیح در نیمهٔ راست فرش میانی قرار می‌گیرند.';
 s.vars({placed_0:false,placed_1:false,placed_2:false,angle_0:270,angle_1:0,angle_2:180,turned:false});
 const motifs=['<path d="M30 4Q62 24 30 56Q-2 24 30 4Z" fill="#dbbd75"/><path d="M30 45V16" fill="none" stroke="#718d83"/>','<path d="M30 4L53 30L30 56L7 30Z" fill="#dbbd75"/><circle cx="30" cy="22" r="8" fill="#789d9a"/>','<path d="M12 10V35Q30 61 48 35V10" fill="none" stroke="#dbbd75" stroke-width="13"/>'];
 motifs.forEach((body,i)=>svg('rug_repair_motif_'+i,body,60,60,'نقش‌های متفاوت و جهت‌دار برای ترمیم سه ردیف و تشخیص جهت.'));
 for(const missing of [false,true]){
  let body='<rect x="5" y="5" width="310" height="380" rx="10" fill="#aa7c76"/><rect x="25" y="25" width="270" height="340" fill="#7d9c9d"/><path d="M160 25V365" stroke="#bfc4a3" stroke-width="2" stroke-dasharray="8 10"/>';
  for(let i=0;i<3;i++){body+=`<g transform="translate(55 ${55+i*110})">${motifs[i]}</g>`;body+=missing?`<rect x="205" y="${55+i*110}" width="60" height="60" fill="#a9ab91" stroke="#d8cba3" stroke-dasharray="7 7"/>`:`<g transform="translate(205 ${55+i*110})">${motifs[i]}</g>`;}
  svg('rug_repair_'+(missing?'missing':'complete'),body,320,390,'فرش با سه ردیف نقش و سه جای خالیِ قرینه؛ فرش قبلی فقط یک نقش کم داشت.');
 }
 [490,960,1430].forEach((x,i)=>s.image('rug_'+i,'rug_repair_'+(i===1?'missing':'complete'),x,650));
 const homes=[600,960,1320],angles=[270,0,180];
 for(let i=0;i<3;i++){
  s.drag('piece_'+i,'rug_repair_motif_'+i,homes[i],950,{rotation_degrees:angles[i],hit_size:[100,100]});
  s.d.objects.at(-1).interactions[0].bounds=[250,450,1400,550];s.d.objects.at(-1).interactions.push('tap');
  s.zone('gap_'+i,1035,540+i*110,['piece_'+i],[95,95]);
  for(let old=0;old<360;old+=90)s.rule('tap','piece_'+i,[rotate('piece_'+i,(old+90)%360),sv('angle_'+i,(old+90)%360),sv('turned')],[v('placed_'+i,false),v('angle_'+i,old),v('turned',false)]);
  s.rule('tap','piece_'+i,[sv('turned',false)]);
  s.drop('piece_'+i,'gap_'+i,[move('piece_'+i,1035,540+i*110),sv('placed_'+i)],[v('angle_'+i,0)]);
  s.drop('piece_'+i,'gap_'+i,[move('piece_'+i,homes[i],950)],[v('angle_'+i,0,'ne')]);
  s.rule('drag_end','piece_'+i,[move('piece_'+i,1035,540+i*110)],[v('placed_'+i)]);
 }
 s.win('variable_changed','$level',[v('placed_0'),v('placed_1'),v('placed_2')]);s.save();
}

// 70: flip cards directly in place; reserve one inspection until both halves finish.
{
 assets[P+'card_flip_feedback.tres']='انیمیشن مستقل جمع‌شدن روی کارت و بازشدن پشت آن در همان محل؛ انیمیشن‌های موجود ورق‌زدن کارت را پوشش نمی‌دادند و منابع قبلی حفظ شدند.';
 const s=new Stage(70,'قانون فقط می‌گوید پشت حرف صدادار باید عدد زوج باشد؛ پشت حرف بی‌صدا یا عدد زوج محدودیتی ندارد. کارت‌های A و E را بررسی کن تا ببینی پشتشان زوج است یا نه، و ۷ و ۹ را تا ببینی پشت عدد فرد حرف صدادار هست یا نه. برای برگرداندن هر کارت، روی خودش به چپ بکش و رها کن؛ پشت کارت در همان جا آشکار می‌شود. فقط چهار بررسی داری: A، E، ۷ و ۹؛ ترتیبشان مهم نیست و هر کارت فقط یک بار بررسی می‌شود.');
 s.d.question='کارت‌های A، E، D، K، ۴، ۸، ۷، ۹؛ اگر یک طرف صدادار باشد، طرف دیگر زوج است. کدام چهار کارت باید بررسی شوند؟';
 s.d.answer='A و E و ۷ و ۹؛ صدادارها و عددهای فرد، حالت‌های لازم برای پیدا کردن نقض قانون‌اند.';
 s.vars({scans:0,flipping:-1,...Object.fromEntries(Array.from({length:8},(_,i)=>['inspected_'+i,false]))});
 s.d.counters=[{label:'کارت بررسی‌شده',variable:'scans',target:4}];
 s.text('flip_instruction','فقط ۴ کارت؛ برای ورق‌زدن به چپ بکش',960,700,[1260,70]);
 const fronts=['A','E','D','K','۴','۸','۷','۹'],backs=['۳','۲','۴','۷','A','D','D','E'];
 const animate=(target,animation)=>({type:'play_animation',target,animation:'card_flip/'+animation,wait:false});
 const ended=animation=>({type:'event_value',field:'animation',operator:'eq',value:'card_flip/'+animation});
 for(let i=0;i<8;i++){
  const x=420+i%4*360,y=i<4?500:900;
  s.text('card_'+i,fronts[i],x,y,[260,130],[{type:'swipe',direction:'left',min_distance:60,max_duration:1}],{sprite:P+'puzzle_tile.svg',z_index:5});
  s.text('back_'+i,backs[i],x,y,[260,130],[],{sprite:P+'puzzle_tile.svg',visible:false});
  s.image('check_'+i,'selection_check',x+95,y-45,[],{scale:[.5,.5],visible:false,z_index:7});
  s.rule('swipe','card_'+i,[sv('flipping',i),animate('card_'+i,'close')],[v('flipping',-1),v('scans',4,'lt'),v('inspected_'+i,false)],true);
  s.rule('custom:animation_finished','card_'+i,[hide('card_'+i),show('back_'+i),animate('back_'+i,'open')],[v('flipping',i),ended('close')],true);
  s.rule('custom:animation_finished','back_'+i,[show('check_'+i),sv('inspected_'+i),sv('flipping',-1),sv('scans',1,'increment')],[v('flipping',i),ended('open')],true);
 }
 s.win('variable_changed','$level',[v('scans',4),v('inspected_0'),v('inspected_1'),v('inspected_6'),v('inspected_7')]);
 s.rule('variable_changed','$level',[fail],[v('scans',4),not({type:'all',conditions:[v('inspected_0'),v('inspected_1'),v('inspected_6'),v('inspected_7')]})]);
 s.save();
}

// Resource ownership/reporting is part of authoring, not runtime validation.
const stages={};
function resources(value,out=new Set()){
 if(typeof value==='string'&&value.startsWith('res://'))out.add(value);
 else if(Array.isArray(value))value.forEach(v=>resources(v,out));
 else if(value&&typeof value==='object')Object.values(value).forEach(v=>resources(v,out));return out;
}
for(const n of changed){const d=read(n),paths=resources(d);paths.add('res://PuzzleEngine/Objects/PuzzleObject.tscn');for(const o of d.objects)paths.add('res://PuzzleEngine/Objects/'+o.scene+'.tscn');for(const r of d.rules)for(const a of r.actions){if(a.animation==='chapter_two/rattle')paths.add(P+'chapter_two_feedback.tres');if(a.animation?.startsWith('card_flip/'))paths.add(P+'card_flip_feedback.tres');}stages[n]={background:d.background,lighting:d.background.includes('night')?'night_lit':'day',reused:[...paths].filter(p=>!assets[p]).sort(),new:[...paths].filter(p=>assets[p]).sort()};}
fs.writeFileSync(file('docs/chapter-five-redesign-assets.json'),JSON.stringify({note:'منابع بازطراحی؛ بررسی اجرایی یا تصویری نیست. منابع قبلی حفظ شدند.',new_assets:assets,stages},null,2)+'\n');

const catalogFile=file('docs/chapter-five-assets.json');
const catalog=JSON.parse(fs.readFileSync(catalogFile,'utf8'));
Object.assign(catalog.new_assets,assets);Object.assign(catalog.stages,stages);
for(const n of changed){const entry=catalog.stages[n],paths=[...entry.reused,...entry.new];entry.reused=paths.filter(p=>!catalog.new_assets[p]).sort();entry.new=paths.filter(p=>catalog.new_assets[p]).sort();}
catalog.matching.rug_69={axis:'vertical',missing_rug:1,rows:[540,650,760],target_angles:[0,0,0],initial_angles:[270,0,180]};
catalog.matching.shadow_67={body_required:true,neck_width:50,handle:'right',light_test_required:true};
catalog.matching.cards_70={fronts:['A','E','D','K','4','8','7','9'],backs:['3','2','4','7','A','D','D','E'],required:[0,1,6,7],budget:4,interaction:'swipe_left_in_place'};
fs.writeFileSync(catalogFile,JSON.stringify(catalog,null,2)+'\n');
