extends PuzzleCustomHandler
## Finite puzzle models; all mutations and completion go through the run context.

var m: Dictionary
var ctx: PuzzleCustomContext
var places: Array = []
var turns: Array = []
var candidates: Array = []
var used: int = 0
var selected: int = -1
var history: Array = []
var counts: Array = []
var visited: Dictionary = {}
var prisoner: int = 1
var next_box: int = 1
var stacks: Array = [[3,2,1,0],[],[]]
var volumes: Array = []
var grid: Array = []
var measured: bool = false
var _ray_segments: Array = []
var floor_page: int = 0
var bundles: Array = [1,2,3,4,5,6,7,8,9,10]

func setup(context: PuzzleCustomContext) -> void:
	ctx = context
	m = JSON.parse_string(str(ctx.get_variable("model")))
	turns = m.get("angles", m.get("turns", [])).duplicate()
	places = m.get("initial", []).duplicate()
	volumes = m.get("volumes", []).duplicate()
	grid = m.get("fixed", []).duplicate()
	if m.kind == "balance":
		places.resize(int(m.n)); places.fill(-1)
		if int(m.level) == 91:
			_permutations([], [0,1,2,3])
		else:
			for i in range(int(m.n)):
				candidates.append([i,1])
				if int(m.level) == 72:
					candidates.append([i,-1])
	elif m.kind == "bags":
		counts.resize(10); counts.fill(0)
	elif m.kind == "rectangles":
		places = [-1,-1,-1,-1]
	elif m.kind in ["fit","exchange"] and turns.is_empty():
		turns.resize(m.pieces.size()); turns.fill(0)
	elif m.kind == "prisoners":
		next_box = 1

func teardown() -> void:
	ctx = null
	visited.clear()
	history.clear()
	candidates.clear()

func _act(actions: Array) -> void:
	ctx.run_actions(actions)

func _say(value: String) -> void:
	_label("feedback", value)

func _label(id: String, value: String) -> void:
	var translated := value
	for i in range(10):
		translated = translated.replace(str(i), "۰۱۲۳۴۵۶۷۸۹"[i])
	_act([{"type":"set_text","target":id,"text":translated}])

func _move(id: String, point: Array) -> void:
	_act([{"type":"move","target":id,"position":point}])

func _rotate(id: String, angle: float) -> void:
	_act([{"type":"rotate","target":id,"degrees":angle}])

func _lines(segments: Array, color: String = "#e4ba57") -> void:
	_act([{"type":"set_lines","target":"diagram","segments":segments,"color":color}])

func _win() -> void:
	ctx.request_success()

func _fail(message: String) -> void:
	_say(message)
	_act([{"type":"fail_level"}])

func on_event(e: Dictionary, _context: PuzzleCustomContext) -> void:
	if e.type not in ["tap","hold","swipe","drop_on","drag_end","level_started"]:
		return
	var s: String = e.source
	var t: String = e.get("target", "")
	match str(m.kind):
		"balance": _balance(e,s,t)
		"fit", "swap", "exchange": _fit(e,s,t)
		"path":
			if s in ["pen","pen_c"] and e.type == "drag_end":
				if e.payload.get("path_overflow",false):
					_say("مسیر بیش از حد طولانی شد؛ دوباره از ابتدا بکش.")
					_move(s,m.origin if int(m.level)==85 else m.points[2 if s=="pen_c" else 0])
					return
				_path(e.payload.get("path", []))
		"hanoi": _hanoi(e,s,t)
		"pour": _pour(e,s,t)
		"eggs": _eggs(e,s,t)
		"bags": _bags(e,s,t)
		"prisoners": _prisoners(e,s)
		"rectangles": _rectangles(e,s)
		"rays": _rays(e,s,t)
		"pipes": _pipes(e,s)
		"latin": _latin(e,s,t)

func _permutations(prefix: Array, remaining: Array) -> void:
	if remaining.is_empty():
		candidates.append(prefix.duplicate()); return
	for v: int in remaining:
		var rest := remaining.duplicate(); rest.erase(v)
		_permutations(prefix + [v], rest)

func _balance(e: Dictionary, s: String, t: String) -> void:
	var n := int(m.n)
	if e.type == "drop_on" and s.begins_with("coin"):
		var i := s.trim_prefix("coin").to_int()
		if t in ["left","right","tray"]:
			if selected==i: selected=-1
			places[i] = ["left","right","tray"].find(t)
			for j in range(n):
				var side := int(places[j])
				var rank := 0
				for k in range(j):
					if places[k] == side: rank += 1
				var point: Array = [280+j*1360.0/maxi(1,n-1),850]
				if side in [0,1]: point=[450+(rank%4)*90+(640 if side==1 else 0),540+(rank/4)*85]
				elif side>=3: point=[620+(side-3)*220,720]
				elif side==-2: point=[1600,740]
				_move("coin%d"%j,point)
		elif t == "identify":
			if selected>=0 and selected!=i:
				places[selected]=2; _move("coin%d"%selected,[280+selected*1360.0/maxi(1,n-1),850])
			selected = i
			places[i]=-2
			_move(s,[1600,740])
			_say("الآن سبک یا سنگین را مشخص کن." if int(m.level)==72 else "شناسه با نتایج ثبت‌شده بررسی شد.")
			if int(m.level)==96:
				if candidates.size()==1 and int(candidates[0][0])==i: _win()
				else: _say("برای شناسایی، باید فقط یک نامزد از توزین‌ها باقی بماند.")
		elif t.begins_with("order") and int(m.level)==91:
			var slot := t.trim_prefix("order").to_int()
			places[i] = slot+3
			for j in range(n):
				if j!=i and places[j]==slot+3:
					places[j]=-1; _move("coin%d"%j,[280+j*1360.0/3,850])
			_move(s,[620+slot*220,720])
			if candidates.size()==1:
				var valid := true
				for j in range(4):
					if places[int(candidates[0][j])] != j+3: valid=false
				if valid: _win()
	elif e.type=="tap" and s=="weigh":
		if used>=int(m.budget): _say("بودجهٔ توزین تمام شده است؛ از نتیجه‌ها استفاده کن."); return
		var left: Array = []; var right: Array = []
		for i in range(n):
			if places[i]==0: left.append(i)
			if places[i]==1: right.append(i)
		if left.is_empty() or left.size()!=right.size() or (int(m.level)==91 and left.size()!=1):
			_say("تعداد برابر روی دو کفه لازم است." if int(m.level)!=91 else "در هر مقایسه فقط یک وزنه روی هر کفه بگذار."); return
		var delta := 0.0
		var reversed_pans := false
		if int(m.level)==72:
			var plan := _twelve_coin_plan()
			var a := left.duplicate(); var b := right.duplicate(); a.sort(); b.sort()
			var expected_left: Array=plan[0]; var expected_right: Array=plan[1]
			expected_left.sort(); expected_right.sort()
			if a==expected_right and b==expected_left: reversed_pans=true
			elif a!=expected_left or b!=expected_right:
				_say("راهبرد باید هر۲۴حالت را جدا کند؛ کفه‌ها را طبق درخت راهنما بچین."); return
		for i: int in left: delta += float(m.masses[i])
		for i: int in right: delta -= float(m.masses[i])
		var outcome := signf(delta)
		var kept: Array = []
		for candidate: Array in candidates:
			var prediction := 0.0
			if int(m.level)==91:
				prediction = signf(float(candidate.find(left[0])-candidate.find(right[0])))
			else:
				prediction = float(candidate[1]) * (1 if int(candidate[0]) in left else -1 if int(candidate[0]) in right else 0)
			if prediction==outcome: kept.append(candidate)
		candidates=kept; used+=1
		history.append({"left":left,"right":right,"outcome":-outcome if reversed_pans else outcome})
		_say("%s | توزین %d/%d | %d نامزد" % ["برابر" if outcome==0 else "چپ سنگین" if outcome>0 else "راست سنگین",used,int(m.budget),candidates.size()])
		if used==int(m.budget) and candidates.size()!=1: _fail("بودجه تمام شد و شناسایی یکتا نیست؛ راهبرد را دوباره امتحان کن.")
	elif e.type=="tap" and s in ["heavy","light"] and selected>=0:
		var direction := 1 if s=="heavy" else -1
		if candidates.size()==1 and int(candidates[0][0])==selected and int(candidates[0][1])==direction: _win()
		else: _say("هویت و جهت تقلب باید با همهٔ توزین‌ها یکتا باشد.")

func _twelve_coin_plan() -> Array:
	if history.is_empty(): return [[0,1,2,3],[4,5,6,7]]
	if float(history[0].outcome)==0:
		if history.size()==1: return [[8,9,10],[0,1,2]]
		return [[11],[0]] if float(history[1].outcome)==0 else [[8],[9]]
	var plan: Array
	if history.size()==1: plan=[[0,1,4],[2,5,8]]
	elif float(history[1].outcome)>0: plan=[[0],[1]]
	elif float(history[1].outcome)<0: plan=[[2],[8]]
	else: plan=[[6],[7]]
	if float(history[0].outcome)<0:
		for pan: Array in plan:
			for i in range(pan.size()):
				var identity := int(pan[i])
				pan[i]=identity+4 if identity<4 else identity-4 if identity<8 else identity
	return plan

func _fit(e: Dictionary, s: String, t: String) -> void:
	if s.begins_with("piece"):
		var i := s.trim_prefix("piece").to_int()
		if m.kind=="exchange" and e.type=="drop_on":
			var old := int(places[i])
			var restore: Array = m.slots[old] if old>=0 else m.tray
			if t=="workbench":
				if -1 in places and old!=-1: _move(s,restore); _say("سینی یک کاشی جا دارد."); return
				places[i]=-1; _move(s,m.tray)
			elif t.begins_with("slot"):
				var slot := t.trim_prefix("slot").to_int()
				if slot in places and places[i]!=slot: _move(s,restore); _say("جایگاه پر است؛ ابتدا یکی را روی سینی بگذار."); return
				places[i]=slot; _move(s,m.slots[slot]); _check_fit()
			return
		if e.type=="tap" and m.kind=="fit" and int(m.level) in [90,97,98]:
			turns[i] = (int(turns[i])+90)%360; _rotate(s,float(turns[i]))
			_check_fit()
		elif e.type=="drop_on" and t.begins_with("slot"):
			var slot := t.trim_prefix("slot").to_int()
			if m.kind=="swap":
				var old := places.find(i)
				var other := int(places[slot]); places[slot]=i; places[old]=other
				_move("piece%d"%other,m.slots[old]); _move(s,m.slots[slot])
			else:
				for j in range(places.size()):
					if j!=i and places[j]==slot:
						places[j]=-1; _move("piece%d"%j,m.pieces[j])
				places[i]=slot; _move(s,m.slots[slot])
			for j in range(m.pieces.size()):
				if int(m.level)==93 or (int(m.level)==97 and j==0): continue
				var slot_index := places.find(j) if m.kind=="swap" else int(places[j])
				var pos: Array = m.slots[slot_index] if slot_index>=0 else m.pieces[j]
				_move("name%d"%j,[pos[0],float(pos[1])+(100 if int(m.level)==90 else 60)])
				if int(m.level)==98:
					_act([{"type":"show" if slot_index<0 else "hide","target":"name%d"%j}])
			if not m.get("requires_switch",false): _check_fit()
	elif e.type=="tap" and s=="switch":
		_check_fit()

func _check_fit() -> void:
	var correct := 0
	if int(m.level)==89:
		correct=2 if places[0] in [0,1] and places[1] in [0,1] and places[0]!=places[1] and places[2]==-1 else 0
		if correct==2:
			_act([{"type":"replace_sprite","target":"lamp","sprite":"res://assets/samples/bulb_lit.svg"}])
			_lines([[[470,650],[960,650]],[[960,650],[1480,650]]])
			_say("مدار بسته؛ لامپ هدف روشن شد."); _win()
		else: _say("دو سیم سالم و مسیر باتری→کلید→لامپ→باتری لازم است.")
		return
	for slot in range(m.target.size()):
		var piece := int(m.target[slot])
		var at_slot := int(places[slot])==piece if m.kind=="swap" else int(places[piece])==slot
		if at_slot and (m.kind=="swap" or int(turns[piece])%360==0): correct+=1
	if correct==m.target.size():
		if int(m.level)==89: _say("مدار بسته؛ لامپ هدف روشن شد.")
		_win()
	else:
		_say("%d جایگاه درست"%correct if int(m.level)==92 else "جهت و همهٔ اتصال‌ها هنوز منطبق نیستند.")

func _hanoi(e: Dictionary, s: String, t: String) -> void:
	if e.type!="drop_on" or not s.begins_with("ring") or not t.begins_with("rod"): return
	var ring := s.trim_prefix("ring").to_int()
	var dest := t.trim_prefix("rod").to_int()
	var origin := -1
	for i in range(3):
		if ring in stacks[i]: origin=i
	if origin<0: return
	if stacks[origin][-1]!=ring or (not stacks[dest].is_empty() and int(stacks[dest][-1])<ring):
		_say("فقط حلقهٔ بالایی؛ بزرگ روی کوچک مجاز نیست.")
	else:
		stacks[origin].pop_back(); stacks[dest].append(ring); used+=1
	for i in range(3):
		for j in range(stacks[i].size()): _move("ring%d"%int(stacks[i][j]),[500+i*460,840-j*55])
	if stacks[2].size()==4: _win()

func _pour(e: Dictionary, s: String, t: String) -> void:
	if e.type!="drop_on" or not s.begins_with("jug") or not t.begins_with("jugzone"): return
	var a := s.trim_prefix("jug").to_int(); var b := t.trim_prefix("jugzone").to_int()
	var amount := mini(int(volumes[a]),int(m.capacities[b])-int(volumes[b]))
	volumes[a]=int(volumes[a])-amount; volumes[b]=int(volumes[b])+amount
	_move(s,[500+a*460,670])
	for i in range(3):
		_label("volume%d"%i,"%d / %d"%[int(volumes[i]),int(m.capacities[i])])
		var sprite := "res://assets/samples/final_jug8_%d.svg"%int(volumes[i]) if i==0 else "res://assets/samples/measuring_jug_%d_%d.svg"%[int(m.capacities[i]),int(volumes[i])]
		_act([{"type":"replace_sprite","target":"jug%d"%i,"sprite":sprite}])
	_say("انتقال %d لیتر؛ مجموع۸لیتر حفظ شد."%amount)
	if volumes==[4,4,0]: _win()

func _eggs(e: Dictionary, s: String, t: String) -> void:
	if e.type=="swipe" and s=="floor_page":
		for i in range(floor_page*20+1,floor_page*20+21):
			_act([{"type":"hide","target":"floor%d"%i},{"type":"hide","target":"floorzone%d"%i}])
		floor_page=(floor_page+1)%5
		for i in range(floor_page*20+1,floor_page*20+21):
			_act([{"type":"show","target":"floor%d"%i},{"type":"show","target":"floorzone%d"%i}])
		_label("floor_page","%d تا%d ↔"%[floor_page*20+1,floor_page*20+20]); return
	if e.type!="drop_on" or s!="egg" or not t.begins_with("floorzone"): return
	var floor_number := t.trim_prefix("floorzone").to_int()
	if not history.is_empty() and floor_number<=int(history[-1]):
		_say("طبقات تخم‌مرغ اول باید صعودی باشند."); _move(s,[1650,680]); return
	history.append(floor_number); _move(s,[1650,680])
	_label("program",str(history))
	if floor_number!=100: return
	var worst := 0
	for threshold in range(101):
		var throws := 0; var low := 0
		for f: int in history:
			throws+=1
			if f>threshold:
				# Second egg walks the unknown interval, stopping at first break.
				throws+=mini(threshold+1,f-1)-low
				break
			low=f
		worst=maxi(worst,throws)
	_say("بدترین حالت در همهٔ۱۰۱آستانه: %d پرتاب"%worst)
	if worst<=14: _win()
	else:
		history.clear(); _label("program","برنامه را از ابتدا بساز")

func _bags(e: Dictionary, s: String, t: String) -> void:
	if s.begins_with("bag"):
		var i := s.trim_prefix("bag").to_int()
		if e.type=="drop_on" and t=="sample" and not measured:
			counts[i]=int(bundles[i]); _move(s,[350+(i%5)*290,590+(i/5)*220])
		elif e.type=="tap" and not measured: bundles[i]=int(bundles[i])%10+1
		elif e.type=="hold" and measured:
			if candidates.size()==1 and int(candidates[0])==i: _win()
			else: _say("این نمونه‌برداری شماره کیسه را یکتا نمی‌کند.")
		_label("count%d"%i,"%d → %d"%[int(bundles[i]),int(counts[i])])
		if not measured:
			var sampled := 0
			for count: int in counts: sampled+=count
			_label("sample_count","%d\nسکه"%sampled)
	elif e.type=="tap" and s=="weigh" and not measured:
		var total := 0
		for c: int in counts: total+=c
		if total==0: return
		measured=true
		var deficit := int(counts[6]); candidates.clear()
		for i in range(10):
			if counts[i]==deficit: candidates.append(i)
		_say("%d گرم؛ سالم %d؛ کمبود %d؛ %d نامزد"%[total*10-deficit,total*10,deficit,candidates.size()])
		_label("sample_count","%d\nگرم"%(total*10-deficit))
		if counts!=[1,2,3,4,5,6,7,8,9,10] or candidates.size()!=1:
			_fail("تنها توزین مصرف شد؛ برنامهٔ کاملِ۱تا۱۰برای همهٔ کیسه‌ها لازم است.")

func _prisoners(e: Dictionary, s: String) -> void:
	if e.type!="tap" or not s.begins_with("box"): return
	var box := s.trim_prefix("box").to_int()+1
	if box!=next_box:
		_say("شمارهٔ داخل جعبهٔ قبلی را دنبال کن؛ شروع هر نفر از شمارهٔ خودش است."); return
	if used>=5: _fail("بیش از۵جعبه برای یک نفر مجاز نیست."); return
	used+=1; next_box=int(m.permutation[box-1]); _label(s,str(next_box))
	if next_box==prisoner:
		prisoner+=1; used=0; next_box=prisoner
		if prisoner==11: _win(); return
		for i in range(10): _label("box%d"%i,str(i+1))
	_label("prisoner","نفر%d؛ جعبهٔ بعدی%d؛ %d/5"%[prisoner,next_box,used])

func _rectangles(e: Dictionary, s: String) -> void:
	if e.type=="drag_end" and s.begins_with("clip"):
		var axis := int(s[4]); var index := int(s[6])
		var end: Array = e.payload.end_position
		if not Rect2(625,455,470,470).has_point(Vector2(end[0],end[1])):
			_restore_clip(s,axis,index); _say("گیره باید روی خط‌های خود شبکه رها شود."); return
		var coordinate := float(end[axis])
		var base := 650.0 if axis==0 else 480.0
		var line := roundi((coordinate-base)/52.0)
		if line<0 or line>8 or absf(coordinate-(base+line*52))>26:
			_restore_clip(s,axis,index); _say("گیره را روی یکی از۹خط قرار بده."); return
		places[axis*2+index]=line
		_move(s,[base+line*52,900] if axis==0 else [1140,base+line*52])
	elif e.type=="hold" and s=="combinations":
		if -1 in places or places[0]==places[1] or places[2]==places[3]:
			_say("دو خط متمایز از هر جهت لازم است."); return
		var n := int(m.get("line_count",9))
		var pairs := n*(n-1)/2
		_say("%d×%d÷۲ = %d؛ %d×%d = %d، شامل مربع‌ها"%[n,n-1,pairs,pairs,pairs,pairs*pairs])
		_win()

func _restore_clip(s: String, axis: int, index: int) -> void:
	var previous := int(places[axis*2+index])
	if previous<0: _move(s,[1350+index*160,600+axis*180])
	else: _move(s,[650+previous*52,900] if axis==0 else [1140,480+previous*52])

func _rays(e: Dictionary, s: String, t: String) -> void:
	if e.type=="drop_on" and s.begins_with("mirror") and t.begins_with("slot"):
		var i := s.trim_prefix("mirror").to_int(); var slot := t.trim_prefix("slot").to_int()
		if slot in places:
			_move(s,m.slots[int(places[i])]); _say("جایگاه اشغال است."); return
		places[i]=slot; _move(s,m.slots[slot])
		_lines([])
		for j in range(3): _label("lit%d"%j,"○")
	elif e.type=="tap" and s=="light":
		var hits := _trace_rays(places)
		var visible_segments := _ray_segments.duplicate(true)
		for i in range(3): _label("lit%d"%i,"●" if i in hits else "○")
		var minimum := 4
		for a in range(m.slots.size()):
			for b in range(m.slots.size()):
				for c in range(m.slots.size()):
					if a==b or a==c or b==c: continue
					if _trace_rays([a,b,c]).size()==3:
						var cost := int(a!=int(m.initial[0]))+int(b!=int(m.initial[1]))+int(c!=int(m.initial[2]))
						minimum=mini(minimum,cost)
		var changed := 0
		for i in range(3): changed+=int(places[i]!=m.initial[i])
		_say("%d هدف؛ %d تغییر جایگاه؛ کمینهٔ هندسی%d"%[hits.size(),changed,minimum])
		_lines(visible_segments)
		if hits.size()==3 and changed==minimum: _win()

func _trace_rays(configuration: Array) -> Array:
	var hits: Array = []
	_ray_segments.clear()
	for lantern: Array in m.lanterns:
		var pos := Vector2(lantern[0],lantern[1]); var direction := Vector2(lantern[2],lantern[3])
		var seen: Dictionary = {}
		for bounce in range(8):
			var nearest := INF; var mirror := -1; var target := -1
			for j in range(3):
				var raw: Array = m.slots[int(configuration[j])]
				var delta := Vector2(raw[0],raw[1])-pos
				if absf(delta.cross(direction))<1 and delta.dot(direction)>1 and delta.length()<nearest:
					nearest=delta.length(); mirror=j; target=-1
			for j in range(3):
				var raw: Array = m.targets[j]; var delta := Vector2(raw[0],raw[1])-pos
				if absf(delta.cross(direction))<1 and delta.dot(direction)>1 and delta.length()<nearest:
					nearest=delta.length(); mirror=-1; target=j
			if target>=0:
				_ray_segments.append([[pos.x,pos.y],[pos.x+direction.x*nearest,pos.y+direction.y*nearest]])
				if target not in hits: hits.append(target)
				break
			if mirror<0 or seen.has([mirror,direction]): break
			seen[[mirror,direction]]=true
			_ray_segments.append([[pos.x,pos.y],[pos.x+direction.x*nearest,pos.y+direction.y*nearest]])
			pos+=direction*nearest
			direction=Vector2(-direction.y,-direction.x) if m.orientations[mirror]=="/" else Vector2(direction.y,direction.x)
	return hits

func _pipes(e: Dictionary, s: String) -> void:
	if e.type=="tap" and s.begins_with("pipe"):
		var i := s.trim_prefix("pipe").to_int(); turns[i]=(int(turns[i])+1)%4; _rotate(s,int(turns[i])*90+int(m.base_angles[i]))
		_lines([])
	elif e.type=="tap" and s=="water":
		var masks: Array = []
		for i in range(9):
			var mask := int(m.target[i])
			for j in range(int(turns[i])): mask=((mask<<1)&15)|((mask>>3)&1)
			masks.append(mask)
		var queue: Array = [0]; var reached: Dictionary = {}; var leaks := 0; var flow: Array = []
		if (int(masks[0])&8)==0: _say("ورودی به آب‌انبار وصل نیست."); return
		while not queue.is_empty():
			var i: int = queue.pop_front()
			if reached.has(i): continue
			reached[i]=true
			for d in range(4):
				if (int(masks[i])&(1<<d))==0: continue
				if (i==0 and d==3) or (i==8 and d==1): continue
				flow.append([[750+(i%3)*140,540+(i/3)*140],[750+(i%3)*140+int([0,1,0,-1][d])*70,540+(i/3)*140+int([-1,0,1,0][d])*70]])
				var row: int = i/3 + int([-1,0,1,0][d]); var col: int = i%3 + int([0,1,0,-1][d])
				if row<0 or row>2 or col<0 or col>2: leaks+=1; continue
				var j := int(row)*3+int(col)
				if (int(masks[j])&(1<<((d+2)%4)))==0: leaks+=1
				else: queue.append(j)
		_say("%d لوله در جریان؛ %d نشتی"%[reached.size(),leaks])
		_lines(flow,"#398db5")
		if reached.has(8) and (int(masks[8])&2)!=0 and leaks==0: _win()

func _latin(e: Dictionary, s: String, t: String) -> void:
	if e.type!="drop_on" or not s.begins_with("number") or not t.begins_with("cellzone"): return
	var value := s.trim_prefix("number").to_int(); var cell := t.trim_prefix("cellzone").to_int()
	_move(s,[600+value*190,920])
	if value<1 or value>4 or int(m.fixed[cell])!=0: _say("فقط۱تا۴و خانهٔ غیرفیکس مجاز است."); return
	grid[cell]=value
	var complete := true
	for i in range(16):
		var duplicate := false
		for j in range(16):
			if i!=j and int(grid[i])>0 and grid[i]==grid[j] and (i/4==j/4 or i%4==j%4): duplicate=true
		if int(grid[i])==0 or duplicate: complete=false
		_label("cell%d"%i,"%s%s"%[str(grid[i]) if int(grid[i])>0 else "·"," ×" if duplicate else ""])
	if complete: _win()

func _path(raw: Array) -> void:
	if raw.size()<2: return
	var points: Array[Vector2] = []
	for p: Array in raw:
		var v := Vector2(p[0],p[1])
		if not Rect2(200,440,1520,600).has_point(v): _say("مسیر باید داخل صفحهٔ معما بماند."); return
		points.append(v)
	if int(m.level)==85:
		var origin := Vector2(m.origin[0],m.origin[1])
		var delta: Vector2 = points[-1]-origin
		var side := roundi(delta.x/float(m.spacing))
		if points[0].distance_to(origin)>28 or side<1 or side>8 or absf(delta.y-side*float(m.spacing))>20:
			_say("از گوشهٔ بالاچپ تا قطر یک مربع بکش؛ عرض و ارتفاع برابر."); _move("pen",m.origin); return
		visited[side]=(9-side)*(9-side)
		var x := origin.x+side*float(m.spacing); var y := origin.y+side*float(m.spacing)
		_lines([[[origin.x,origin.y],[x,origin.y]],[[x,origin.y],[x,y]],[[x,y],[origin.x,y]],[[origin.x,y],[origin.x,origin.y]]],"#398db5")
		var total := 0
		for value: int in visited.values(): total+=value
		_say("ضلع%d: %d جایگاه؛ جمع%d؛ %dاز۸اندازه"%[side,int(visited[side]),total,visited.size()])
		_move("pen",m.origin)
		if visited.size()==8 and total==204: _win()
		return
	if int(m.level)==80:
		var reduced := _simplify(points,float(m.segment_tolerance))
		if reduced.size()!=5: _say("چهار خط راستِ متصل لازم است؛ مسیر تازه را از ابتدا بکش."); _reset_pen(); return
		var covered := 0
		for p: Array in m.points:
			for i in range(4):
				if _segment_distance(Vector2(p[0],p[1]),reduced[i],reduced[i+1])<=float(m.tolerance): covered+=1; break
		_say("%dاز۹نقطه با۴خط"%covered)
		if covered==9: _win()
		else: _reset_pen()
		return
	var sequence: Array = []
	var sampled: Array[Vector2] = []
	# Interpolate between pointer samples so sparse events cannot skip a cell/node.
	for i in range(points.size()-1):
		var steps := maxi(1,ceili(points[i].distance_to(points[i+1])/8.0))
		for k in range(steps+1):
			var p := points[i].lerp(points[i+1],float(k)/steps)
			sampled.append(p)
			if sampled.size()>32768:
				_say("مسیر طولانی است؛ از ابتدا و بدون دور اضافه بکش."); _reset_pen(); return
			var node := _nearest_node(p)
			if node>=0 and (sequence.is_empty() or sequence[-1]!=node): sequence.append(node)
	if int(m.level)==95:
		var unique: Dictionary = {}; var valid := sequence.size()==9 and sequence[0]==0 and sequence[-1]==8
		for i in range(sequence.size()):
			var node := int(sequence[i])
			if unique.has(node): valid=false
			unique[node]=true
			if i>0:
				var prev := int(sequence[i-1])
				if absi(node/3-prev/3)+absi(node%3-prev%3)!=1: valid=false
		# Follow the actual chosen lanes; visiting the nodes via an outside loop fails.
		for p: Vector2 in sampled:
			var on_route := false
			for j in range(sequence.size()-1):
				var a: Array=m.points[int(sequence[j])]; var b: Array=m.points[int(sequence[j+1])]
				if _segment_distance(p,Vector2(a[0],a[1]),Vector2(b[0],b[1]))<=float(m.tolerance): on_route=true
			if not on_route: valid=false
		if valid: _win()
		else: _say("۹خانهٔ یکتا، همسایهٔ افقی/عمودی، از۱تا۹لازم است."); _reset_pen()
	else:
		var edges: Dictionary = {}; var valid := sequence.size()==6
		var allowed := [[0,1],[1,2],[2,3],[0,3],[0,2]]
		for i in range(sequence.size()-1):
			var edge: Array = [mini(int(sequence[i]),int(sequence[i+1])),maxi(int(sequence[i]),int(sequence[i+1]))]
			if edge not in allowed or edges.has(str(edge)): valid=false
			edges[str(edge)]=true
		# Every sample must follow the actual edge segment, not a curved shortcut.
		for p: Vector2 in sampled:
			var near := false
			for edge: Array in allowed:
				var a: Array=m.points[int(edge[0])]; var b: Array=m.points[int(edge[1])]
				if _segment_distance(p,Vector2(a[0],a[1]),Vector2(b[0],b[1]))<=float(m.tolerance): near=true
			if not near: valid=false
		if valid and edges.size()==5: _win()
		else: _say("هر۵یال واقعی دقیقاً یک بار؛ شروعAیاC."); _reset_pen()

func _reset_pen() -> void:
	_move("pen",m.points[0])

func _nearest_node(p: Vector2) -> int:
	for i in range(m.points.size()):
		var a: Array=m.points[i]
		if p.distance_to(Vector2(a[0],a[1]))<=float(m.tolerance): return i
	return -1

func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b-a
	return p.distance_to(a+delta*clampf((p-a).dot(delta)/maxf(.001,delta.length_squared()),0,1))

func _simplify(points: Array[Vector2], tolerance: float) -> Array[Vector2]:
	var kept: Array[int] = [0,points.size()-1]
	var stack: Array = [[0,points.size()-1]]
	while not stack.is_empty():
		var span: Array = stack.pop_back()
		var first := int(span[0]); var last := int(span[1])
		var greatest := 0.0; var split := first
		for i in range(first+1,last):
			var distance := _segment_distance(points[i],points[first],points[last])
			if distance>greatest: greatest=distance; split=i
		if greatest>tolerance:
			kept.append(split)
			if kept.size()>5: break # More than four segments already disproves this stroke.
			stack.append([first,split]); stack.append([split,last])
	kept.sort()
	var result: Array[Vector2] = []
	for index: int in kept: result.append(points[index])
	return result
