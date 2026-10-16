extends "res://tests/test_chapter_five.gd"
## Isolated saves and real pointer input; this file does not run during authoring.

func _trace(c: PuzzleController, points: Array, pen: String = "pen") -> void:
	_press(c,pen)
	for point: Vector2 in points:
		c.interaction_manager.pointer_moved(c.interaction_manager.stage_to_viewport(point),0)
	c.interaction_manager.pointer_released(c.interaction_manager.stage_to_viewport(points[-1]),0)

func _weigh(c: PuzzleController, left: Array, right: Array, n: int) -> void:
	for i in range(n): _drop(c,"coin%d"%i,"tray")
	for i: int in left: _drop(c,"coin%d"%i,"left")
	for i: int in right: _drop(c,"coin%d"%i,"right")
	_tap(c,"weigh")

func _hanoi_route(c: PuzzleController, n: int, source: int, destination: int, spare: int) -> void:
	if n==0: return
	_hanoi_route(c,n-1,source,spare,destination)
	_drop(c,"ring%d"%(n-1),"rod%d"%destination)
	_hanoi_route(c,n-1,spare,destination,source)

func _solve(c: PuzzleController, id: int) -> void:
	match id:
		71:
			for i in range(4): _tap(c,"clock%d"%i)
			_hold(c,"clock1")
		72:
			_weigh(c,[0,1,2,3],[4,5,6,7],12)
			_weigh(c,[8,9,10],[0,1,2],12)
			_weigh(c,[8],[9],12)
			_drop(c,"coin9","identify"); _tap(c,"heavy")
		73:
			_drop(c,"question","guardzone0"); _swipe(c,"door0",Vector2(-120,0))
		74:
			for i in range(4): _drop(c,"person%d"%i,"boys")
			for i in range(5,8): _drop(c,"person%d"%i,"girls")
		75:
			for i in range(6): _drop(c,"digit%d"%i,"group%d"%(0 if i<3 else 1 if i<5 else 2))
			for i in range(3): _drop(c,"out%d"%i,"slot%d"%i)
		76:
			_drop(c,"battery","battery_out"); _swipe(c,"cycle"); _swipe(c,"cycle")
		77:
			var page := 0
			for floor_number: int in [14,27,39,50,60,69,77,84,90,95,99,100]:
				while page!=(floor_number-1)/20:
					_swipe(c,"floor_page"); page=(page+1)%5
				_drop(c,"egg","floorzone%d"%floor_number)
		78:
			_hold(c,"black"); _hold(c,"white"); _drop(c,"domino","pair"); _drop(c,"domino","residue")
		79:
			for i in range(10): _drop(c,"bag%d"%i,"sample")
			_tap(c,"weigh"); _hold(c,"bag6")
		80:
			_trace(c,[Vector2(1070,500),Vector2(650,920),Vector2(650,500),Vector2(930,780)])
		81: _hanoi_route(c,4,0,2,1)
		82:
			var permutation := [2,3,4,5,1,7,8,9,10,6]
			for prisoner_id in range(1,11):
				var box := prisoner_id
				for visit in range(5):
					_tap(c,"box%d"%(box-1)); box=permutation[box-1]
					if box==prisoner_id: break
		83:
			# Explicit identity construction is independent of sprite filenames.
			var index := 0
			for x in range(3):
				for y in range(3):
					for z in range(3):
						var faces := int(x in [0,2])+int(y in [0,2])+int(z in [0,2])
						if faces==0: continue
						if faces==2: _tap(c,"cube%d"%index)
						index+=1
		84:
			for i in range(6): _drop(c,"layer%d"%i,"tray")
			for i in range(8): _tap(c,"cube%d"%i)
		85:
			for side in range(1,9): _trace(c,[Vector2(650+side*52,480+side*52)])
		86:
			_drag(c,"clip0_0",Vector2(650,600)); _drag(c,"clip0_1",Vector2(1066,600))
			_drag(c,"clip1_0",Vector2(850,480)); _drag(c,"clip1_1",Vector2(850,896))
			_hold(c,"combinations")
		87:
			for pair: Array in [[0,1],[1,2],[2,0],[1,2],[0,1],[1,2],[2,0]]:
				_drop(c,"jug%d"%pair[0],"jugzone%d"%pair[1])
		88: _trace(c,[Vector2(1150,520),Vector2(1150,880),Vector2(650,880),Vector2(650,520),Vector2(1150,880)])
		89:
			_drop(c,"piece0","slot0"); _drop(c,"piece1","slot1"); _tap(c,"switch")
		90:
			for i in range(3): _tap(c,"piece1")
			_drop(c,"piece1","slot0")
		91:
			for pair: Array in [[0,1],[2,3],[1,3],[0,2],[3,2]]: _weigh(c,[pair[0]],[pair[1]],4)
			for i in range(4): _drop(c,"coin%d"%[1,3,2,0][i],"order%d"%i)
		92:
			for i in range(4): _drop(c,"piece%d"%[2,1,3,0][i],"slot%d"%i)
			_tap(c,"switch")
		93:
			_drop(c,"piece3","workbench"); _drop(c,"piece5","slot5"); _drop(c,"piece3","slot3")
		94:
			_drop(c,"mirror0","slot0"); _drop(c,"mirror2","slot2"); _tap(c,"light")
		95: _trace(c,[Vector2(1010,500),Vector2(1010,680),Vector2(650,680),Vector2(650,860),Vector2(1010,860)])
		96:
			_weigh(c,[0,1,2],[3,4,5],9); _weigh(c,[3],[4],9); _drop(c,"coin4","identify")
		97:
			for i in range(3): _tap(c,"piece2")
			_drop(c,"piece2","slot0")
		98:
			for i in range(4):
				for j in range([3,2,1,3][i]): _tap(c,"piece%d"%i)
				_drop(c,"piece%d"%i,"slot%d"%i)
		99:
			for i in range(9):
				for j in range(4-[1,2,3,1,2,3,1,2,3][i]): _tap(c,"pipe%d"%i)
			_tap(c,"water")
		100:
			for i in range(3): _drop(c,"piece%d"%[2,1,0][i],"slot%d"%i)
		101:
			var fixed := [1,0,0,4,0,3,4,0,0,4,1,0,4,0,0,3]
			for i in range(16):
				if fixed[i]==0: _drop(c,"number%d"%((i/4+i%4)%4+1),"cellzone%d"%i)

func _traps(c: PuzzleController) -> void:
	for object: PuzzleObject in c.object_nodes.values():
		if not object.object_id.begins_with("trap") or object.object_id.begins_with("trap_lab"): continue
		var id := object.object_id
		if object.has_interaction("drag"): _drop(c,id,"trap_lab")
		elif object.has_interaction("hold"): _hold(c,id)
		elif object.has_interaction("swipe"): _swipe(c,id)
		elif object.has_interaction("tap"): _tap(c,id)
		check(c.run_status=="PLAYING","Distraction cannot solve or corrupt stage %d: %s"%[c.state.level_id,id])

func _run() -> void:
	var c := _controller()
	await process_frame
	_actions_validation(c)
	for id in range(71,102):
		check(c.load_level_index(id-1),"Stage %d loads"%id)
		_traps(c)
		_solve(c,id)
		check(c.run_status=="COMPLETED","Actual pointer route solves stage %d after all distractions"%id)
		check(c.current_result.get("level_id")==id,"Shared result path records stage %d"%id)
		c.load_level_index(id-1)
		check(c.run_status=="PLAYING" and not c.state.variables.solved,"Reload resets stage %d"%id)
	await _invalid_routes(c)
	_context_lifetime(c)
	_all_coin_hypotheses()
	_latin_uniqueness()
	_migration()
	c.free()
	await _final_progression()
	_finish()

func _actions_validation(c: PuzzleController) -> void:
	c.load_level_index(98)
	var run := c.state.run_id
	var result := c.action_runner.run_action({"type":"set_text","target":"feedback","text":"آزمایش"},run)
	check(result.ok and c.state.objects.feedback.text=="آزمایش" and c.object_nodes.feedback.text_label.text=="آزمایش","Text action synchronizes presentation and state")
	result=c.action_runner.run_action({"type":"set_lines","target":"diagram","segments":[[[750,540],[890,540]]]},run)
	check(result.ok and c.object_nodes.diagram.get_node("PuzzleLines").get_child_count()==1,"Line action draws under the stage object")
	var invalid := c.current_definition.duplicate(true)
	invalid.rules.append({"id":"invalid_text_target","event":"level_started","actions":[{"type":"set_text","target":"pipe0","text":"invalid"}]})
	check(not PuzzleValidator.new().validate_level(invalid).ok,"Text action rejects an image target")
	invalid=c.current_definition.duplicate(true)
	invalid.rules.append({"id":"invalid_line_points","event":"level_started","actions":[{"type":"set_lines","target":"diagram","segments":[[[0],[1,2]]]}]})
	check(not PuzzleValidator.new().validate_level(invalid).ok,"Line action rejects malformed coordinates")
	invalid=c.current_definition.duplicate(true)
	invalid.objects[0]["tint"]="invalid"
	check(not PuzzleValidator.new().validate_level(invalid).ok,"Instance lighting rejects malformed colors")

func _invalid_routes(c: PuzzleController) -> void:
	c.load_level_index(79)
	_trace(c,[Vector2(930,500),Vector2(930,780),Vector2(650,780),Vector2(650,500)])
	check(c.run_status=="PLAYING","Four border lines miss the center")
	c.load_level_index(87)
	_trace(c,[Vector2(1150,880),Vector2(1150,520),Vector2(650,880)])
	check(c.run_status=="PLAYING","Off-edge shortcuts and incomplete Euler trails fail")
	c.load_level_index(94)
	_trace(c,[Vector2(1010,860)])
	check(c.run_status=="PLAYING","Diagonal Hamilton shortcut fails")
	c.load_level_index(80)
	_drop(c,"ring3","rod2")
	check(c.object_nodes.ring3.position==Vector2(500,840),"Buried Hanoi ring returns")
	c.load_level_index(86)
	_drop(c,"jug1","jugzone0")
	check(c.run_status=="PLAYING","Empty pour cannot create water or solve")
	c.load_level_index(95)
	_drop(c,"coin4","identify")
	check(c.run_status=="PLAYING","Correct guess without weighing evidence fails")
	_weigh(c,[0],[1],9); _weigh(c,[0],[1],9)
	check(c.run_status=="FAILED","Inconclusive two-weighing budget fails without a result")
	c.retry_level()
	check(c.run_status=="PLAYING" and c.current_result.is_empty(),"Retry reconstructs custom model and budget")
	c.load_level_index(100)
	_drop(c,"number5","cellzone1")
	check(c.object_nodes.cell1.text_label.text=="·","Latin digit five is rejected")
	_drop(c,"number1","cellzone1")
	check(c.object_nodes.cell1.text_label.text.contains("×") and c.run_status=="PLAYING","Latin duplicates show feedback without completion")
	c.load_level_index(93)
	_tap(c,"light")
	check(c.run_status=="PLAYING","Initial ray geometry does not light all targets")
	var handler: Variant = c.rule_evaluator.custom_handler
	check(handler._trace_rays([0,1,2]).size()==3,"Two changed mirror positions construct all three target hits")
	c.load_level_index(72)
	_drop(c,"direct","guardzone0")
	check(c.run_status=="FAILED" and c.current_result.is_empty(),"Direct question consumes the declared single-question opportunity")
	c.retry_level(); _solve(c,73)
	check(c.run_status=="COMPLETED","Retry restores the question card and safe-door route")
	c.load_level_index(88)
	_drop(c,"piece2","slot0"); _drop(c,"piece1","slot1"); _tap(c,"switch")
	check(c.run_status=="PLAYING" and c.object_nodes.lamp.definition.sprite.ends_with("bulb_cold.svg"),"Broken wire cannot power the target lamp")
	c.load_level_index(70)
	_hold(c,"clock1")
	check(c.run_status=="PLAYING","Clock selection requires comparative observations")
	c.load_level_index(87)
	_trace(c,[Vector2(650,520),Vector2(650,880),Vector2(1150,880),Vector2(1150,520),Vector2(650,520)],"pen_c")
	check(c.run_status=="COMPLETED","A reversed Euler route can start at C")
	c.load_level_index(71)
	_weigh(c,[4,5,6,7],[0,1,2,3],12)
	_weigh(c,[0,1,2],[8,9,10],12)
	_weigh(c,[9],[8],12)
	_drop(c,"coin9","identify"); _tap(c,"heavy")
	check(c.run_status=="COMPLETED","Reversing the weighing pans preserves the logical strategy")
	await process_frame

func _context_lifetime(c: PuzzleController) -> void:
	c.load_level_index(86)
	var old := c.rule_evaluator.custom_context
	c.load_level_index(100)
	old.request_success()
	old.emit_custom_event("custom:late","$level")
	old.run_actions([{"type":"set_variable","name":"solved","operation":"assign","value":true}])
	check(not old.valid() and old._actions.is_empty() and old._events.is_empty() and c.run_status=="PLAYING","Old contexts cannot mutate or finish the replacement stage")
	c.clock.set_paused("test",true)
	var manager := c.interaction_manager
	check(not manager.pointer_pressed(manager.stage_to_viewport(c.object_nodes.number2.position),0),"Pause blocks custom-stage pointer input")
	c.clock.set_paused("test",false)

func _all_coin_hypotheses() -> void:
	var definition := PuzzleLoader.new().load_level({"id":72,"path":"res://PuzzleEngine/PuzzleData/072.json"})["data"] as Dictionary
	var signatures: Dictionary = {}
	for identity in range(12):
		for direction: int in [-1,1]:
			var state := PuzzleState.new(); state.initialize(definition)
			var context := PuzzleCustomContext.new(state)
			var handler: Variant = load(definition.custom_handler).new()
			handler.setup(context)
			handler.m.masses.fill(10)
			handler.m.masses[identity]=10+direction
			for step in range(3):
				var pans: Array=handler._twelve_coin_plan()
				handler.places.fill(2)
				for i: int in pans[0]: handler.places[i]=0
				for i: int in pans[1]: handler.places[i]=1
				handler.on_event({"type":"tap","source":"weigh"},context)
			check(handler.candidates==[[identity,direction]],"Three weighings separate identity %d, direction %d"%[identity+1,direction])
			var signature := ""
			for entry: Dictionary in handler.history: signature+=str(entry.outcome)+"/"
			check(not signatures.has(signature),"Each counterfeit hypothesis has a distinct leaf")
			signatures[signature]=true
			context.invalidate(); handler.teardown()

func _latin_uniqueness() -> void:
	var fixed := [1,0,0,4,0,3,4,0,0,4,1,0,4,0,0,3]
	check(_latin_solutions(fixed,0)==1,"The exact packaged Latin clues have one solution")

func _latin_solutions(board: Array, index: int) -> int:
	while index<16 and int(board[index])!=0: index+=1
	if index==16: return 1
	var total := 0
	for value in range(1,5):
		var legal := true
		for i in range(4):
			if board[(index/4)*4+i]==value or board[i*4+index%4]==value: legal=false
		if legal:
			board[index]=value; total+=_latin_solutions(board,index+1); board[index]=0
	return total

func _migration() -> void:
	var store := PuzzleProgressStore.new()
	store.manifest=PuzzleLoader.new().load_manifest()["data"]
	store.persistent=false
	for pending: bool in [false,true]:
		var old := _old_progress(9,70,pending)
		var next := store._migrate_main_progress(old)
		check(store.valid(next) and next.manifest_version==10,"Seventy-stage progress migrates to version ten")
		check(next.results==old.results and next.unlocked_hints==old.unlocked_hints,"Migration preserves results and hints")
		store.data=next
		if pending:
			check(store.data.current_level_id==70,"Pending seventieth result remains pending")
			check(store.advance(),"Only Continue advances the migrated pending result")
		check(store.data.current_level_id==71,"Expanded catalog resumes at seventy-one")

func _final_progression() -> void:
	var c := _controller()
	await process_frame
	c.allow_development_loading=false
	check(c.progress_store.commit(c.progress_store._migrate_main_progress(_old_progress(9,70))),"Seed completed seventy-stage progress in memory")
	check(c.load_level_index(70),"Normal play enters stage seventy-one")
	for id in range(71,102):
		check(c.state.level_id==id,"Normal progression reaches stage %d"%id)
		_solve(c,id)
		check(c.progress_store.data.pending_result_level_id==id,"Result remains pending until Continue at %d"%id)
		c._process(1.1)
		c.continue_to_next_level()
	check(c.progress_store.data.current_level_id==null and c.progress_store.data.results.size()==101,"Continue after stage 101 finishes the catalog")
	check(not c.load_level_index(100),"Completed final stage cannot be replayed in normal play")
	c.free()

func _finish() -> void:
	for failure: String in failures: printerr(failure)
	print("FINAL CHAPTERS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
