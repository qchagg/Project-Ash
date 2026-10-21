class_name BattleScreen
extends Screen
## The battle prototype: the foes' grid on top, the round strip as the front line, your squad's grid below, and the
## selected hero's actions at the foot. Set the formation, then plan each round: tap a hero, an action, then a lit
## tile; queued skills chain. The studs button commits (begin, fight, fight again). Reach is on: single-target melee
## must stand at the front of a lane with an enemy across it, so moving is how you line up a hit.
## Nothing here assumes four heroes: grids, chips and the panel size from the battle's own rows, columns and units.

const GAP := 8.0
const TILE_H := 88.0
## How long each beat of a resolving round stays on screen.
const BEAT := 0.42

var b: Battle
## The board as currently shown (unit id -> snapshot); it trails the engine during playback.
var view := {}
var sel_id := ""
var sel_act := ""
var _hint := ""
var _playing := false
## Embers paid to the town for this fight's win, so the reward is paid once.
var _paid := 0
## The augment this win dropped into the loose pile ("" until paid).
var _spoils := ""
## Where an area skill is being previewed: tap a tile to place its shape, tap it again to cast. (-1, -1) when unset.
var _aim_at := Vector2i(-1, -1)
var _aim_side := ""
var _tiles := {}
var _tex := {}
var _round: Label
var _phase: Label
var _chips: HFlowContainer
var _go: Button
var _panel: VBoxContainer
var _log: Label


func _init() -> void:
	tab = "battle"
	title = "battle"


func _build() -> void:
	body.add_theme_constant_override("separation", 14)
	_new_fight()
	_round = Forge.sc("", 22, Forge.LABEL)
	head_right.add_child(_round)
	body.add_child(_grid("E"))
	body.add_child(_strip())
	body.add_child(_grid("P"))
	_panel = Forge.vbox(10)
	body.add_child(_panel)
	refresh()
	_intro.call_deferred()


## The squads march onto the field: foes from the top, heroes from the bottom, one after another.
func _intro() -> void:
	var i := 0
	for side in ["E", "P"]:
		for r in b.rows:
			for c in b.cols:
				var t: BattleTile = _tiles["%s%d%d" % [side, r, c]]
				if not unit_view(side, r, c).is_empty():
					t.intro(0.1 + i * 0.09, Vector2(0, -520 if side == "E" else 520))
					i += 1


## A fresh fight with the squad on the field, standing where the formation left them. Reach is on here.
func _new_fight() -> void:
	_paid = 0
	_spoils = ""
	_aim_at = Vector2i(-1, -1)
	b = Battle.new()
	b.rules.reach = true
	b.rules.ground = true
	var heroes := []
	var pos := {}
	for uid in app.col.squad:
		heroes.append(Battle.card_unit(app.col, uid, b))
		pos[uid] = app.col.tile(uid)
	b.start(heroes, pos)
	b.phase = "form"
	view = b.snapshot()
	sel_id = b.living("P")[0].id
	sel_act = ""
	_hint = ""


# ---------- layout ----------

## A side's grid. The foes' front row sits at the bottom of theirs and yours at the top, so the fronts face across the strip.
func _grid(side: String) -> Control:
	var g := Control.new()
	var tw := (632.0 - GAP * (b.cols - 1)) / b.cols
	g.custom_minimum_size = Vector2(632, b.rows * TILE_H + (b.rows - 1) * GAP)
	for r in b.rows:
		for c in b.cols:
			var t := BattleTile.new()
			t.screen = self
			t.side = side
			t.r = r
			t.c = c
			var row := b.rows - 1 - r if side == "E" else r
			t.position = Vector2(c * (tw + GAP), row * (TILE_H + GAP))
			t.size = Vector2(tw, TILE_H)
			g.add_child(t)
			_tiles["%s%d%d" % [side, r, c]] = t
	return g


## The front line between the grids: round and phase, the queued actions in order, and the one commit button.
func _strip() -> Control:
	var v := Forge.vbox(8)
	v.add_child(Forge.rule())
	var row := Forge.hbox(16)
	v.add_child(row)
	var words := Forge.vbox(0)
	words.size_flags_horizontal = SIZE_EXPAND_FILL
	words.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(words)
	_phase = Forge.label("", 22, Forge.MUTED, Forge.SANS_ITALIC)
	words.add_child(_phase)
	_go = Forge.studs("fight", true, 64)
	_go.custom_minimum_size.x = 220
	_go.pressed.connect(_commit)
	row.add_child(_go)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 8)
	_chips.add_theme_constant_override("v_separation", 8)
	v.add_child(_chips)
	# What just happened, line by line, while a round plays out.
	_log = Forge.label("", 20, Forge.PARCHMENT, Forge.SANS_ITALIC)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size.x = 632
	v.add_child(_log)
	v.add_child(Forge.rule())
	return v


func refresh() -> void:
	for t in _tiles.values():
		t.queue_redraw()
	var phase := "run" if _playing else b.phase
	_round.text = ("formation" if phase == "form" else "round %d" % b.round_num).to_lower()
	_phase.text = {"form": "Tap a hero, then a tile, to set your formation.", "plan": "Plan the round: queued skills chain.",
		"run": "Resolving…", "over": ""}[phase]
	_go.text = {"form": "begin", "plan": "fight", "run": "fight", "over": "fight again"}[phase]
	_go.disabled = _playing
	_log.visible = _playing or b.phase == "over"
	_fill_chips()
	_fill_panel()


func _fill_chips() -> void:
	for ch in _chips.get_children():
		ch.queue_free()
	var chain := 0
	for i in b.queue.size():
		var q: Dictionary = b.queue[i]
		var u := b.unit(q.id)
		var a := b.act(u, q.key)
		var links := chain if a.is_skill else 0
		chain = Battle.next_chain(chain, a)
		var bonus := " +%d%%" % roundi(b.tune.chain * links * 100) if a.is_skill and a.kind == "dmg" and links > 0 else ""
		var chip := Forge.link("%d %s · %s%s" % [i + 1, Battle.name_of(u), a.name, bonus], "", 18)
		chip.custom_minimum_size.y = 40
		chip.tooltip_text = "Tap to take it out of the queue"
		chip.disabled = b.phase != "plan" or _playing
		chip.pressed.connect(func():
			b.dequeue(q.id)
			sel_id = q.id
			refresh())
		_chips.add_child(chip)
	if b.queue.is_empty() and b.phase == "plan" and not _playing:
		_chips.add_child(Forge.label("Nothing queued. Unqueued heroes basic attack after the queue.", 20, Forge.DIM, Forge.SANS_ITALIC))


## The selected hero: name, where they stand, their actions, and what to do next. Or the result, once it's over.
func _fill_panel() -> void:
	for ch in _panel.get_children():
		ch.queue_free()
	if b.phase == "over":
		var win := b.result == "win"
		_panel.add_child(Forge.sc("victory" if win else "defeat", 44, Forge.GOLD if win else Forge.MUTED, true, 0.16))
		_panel.add_child(Forge.label("%s on round %d. Your squad dealt %d and took %d." % ["Cleared" if win else "Wiped", b.round_num, b.dealt, b.taken],
			24, Forge.PARCHMENT, Forge.SANS_ITALIC))
		if win:
			if _paid == 0:
				_paid = app.town.battle_reward()
				app.town.earn(_paid)
			_panel.add_child(Forge.sc("+%d embers to the town" % _paid, 22, Forge.GAIN))
			if _spoils == "":
				var keys := Data.AUGS.keys()
				_spoils = keys[randi() % keys.size()]
				app.col.loose.append(_spoils)
			var aug: Dictionary = Data.AUGS[_spoils]
			var row := Forge.hbox(10)
			row.add_child(Forge.glyph("augment", 22, Forge.ELEM[aug.fam]))
			row.add_child(Forge.sc("+1 augment · %s" % aug.name, 22, Forge.GAIN))
			row.tooltip_text = aug.desc
			_panel.add_child(row)
		return
	var u := b.unit(sel_id)
	if u.is_empty() or not u.alive:
		var alive := b.living("P")
		if alive.is_empty():
			return
		u = alive[0]
		sel_id = u.id
	var head := Forge.hbox(14)
	_panel.add_child(head)
	var g := Forge.glyph("elem_" + u.elem, 28, Forge.ELEM[u.elem])
	head.add_child(g)
	head.add_child(Forge.sc(Battle.name_of(u), 30, Forge.GOLD, true, 0.12))
	var where := Forge.sc("%s · %s · %s" % [Data.ELEMS[u.elem].label, u.range, b.lane(u.r, u.c)], 18, Forge.LABEL)
	where.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(where)
	if Forge.has_role(u.skills, "healer"):
		head.add_child(Forge.role_tag("healer", true, 18))
	if b.phase == "form":
		_note("Front-row heroes shield their lane from melee. Deeper rows take less from ranged attacks. Reach is on: single-target melee only hits across its own lane, from the front row.")
		return
	var skills := Forge.hbox(10)
	_panel.add_child(skills)
	for i in u.skills.size():
		skills.add_child(_act_button(u, "s%d" % i, 64))
	var basics := Forge.hbox(10)
	_panel.add_child(basics)
	for k in ["basic", "move", "guard"]:
		basics.add_child(_act_button(u, k, 56))
	if sel_act.begins_with("s"):
		_panel.add_child(_armed(u, b.act(u, sel_act)))
	var hint := _hint
	if hint == "":
		if u.st.stun > 0:
			hint = "Stunned: %s loses the next action." % Battle.name_of(u)
		elif sel_act != "":
			var a := b.act(u, sel_act)
			if a.kind == "move":
				hint = "Tap a lit empty tile to step there."
			elif b.reach_blocked(u, a):
				hint = "Reach: only the enemy across this lane."
			elif b.aims_ground(a):
				hint = "Tap any enemy tile to place the %s, then tap it again to cast. Empty tiles count: aim between foes." % b.shape_name(a.pattern).to_lower() if _aim_at.x < 0 else "Tap the same tile again to cast, or another tile to move it."
			else:
				hint = "Tap a lit tile."
		else:
			for i in u.skills.size():
				var why := b.blocked_reason(u, b.act(u, "s%d" % i))
				if why != "" and u.cd[i] == 0:
					hint = "%s: %s" % [u.skills[i].name, why.to_lower()]
					break
	if hint == "":
		hint = "Each skill in an unbroken run adds %d%% to the next damaging skill." % roundi(b.tune.chain * 100)
	_note(hint)


func _act_button(u: Dictionary, key: String, h: int) -> Button:
	var a := b.act(u, key)
	var text: String = a.name
	if a.is_skill:
		var left: float = u.cd[a.idx]
		if left == INF:
			text += " · locked"
		elif left > 0:
			text += " · %d" % roundi(left)
	var bt := Forge.ember("" if a.is_skill else text, h)
	bt.size_flags_horizontal = SIZE_EXPAND_FILL
	bt.add_theme_font_size_override("font_size", 20)
	if a.is_skill:
		# Skill buttons carry the skill's icon and its name; the icon shows ranged, physical or support.
		var row := Forge.hbox(10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(Forge.skill_icon(a, u.elem, h - 12))
		var l := Forge.sc(text, 20, Forge.PARCHMENT)
		l.size_flags_vertical = SIZE_SHRINK_CENTER
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(l)
		bt.add_child(row)
		row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 6)
		row.offset_left = 10
		row.offset_right = -10
	elif a.kind != "move":
		bt.icon = Forge.icon("type_" + Forge.skill_type(a))
		bt.add_theme_constant_override("icon_max_width", 22)
		for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			bt.add_theme_color_override(k, Forge.LABEL)
	bt.toggle_mode = true
	bt.button_pressed = sel_act == key
	bt.disabled = _playing or b.phase != "plan" or u.st.stun > 0 or (a.is_skill and u.cd[a.idx] > 0) or b.blocked_reason(u, a) != ""
	bt.tooltip_text = a.get("desc", "")
	bt.pressed.connect(func():
		Burst.on(bt, Forge.ELEM[u.elem] if a.is_skill else Forge.GOLD, 54 if a.is_skill else 34, 10 if a.is_skill else 6)
		_on_action(key))
	return bt


## The armed skill, spelled out: its icon, the shape it hits on the grid, its numbers and its type.
func _armed(u: Dictionary, a: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.ELEM[u.elem], 0.6), 2, Vector4(18, 12, 18, 12)))
	var row := Forge.hbox(16)
	p.add_child(row)
	row.add_child(Forge.skill_icon(a, u.elem, 60))
	var words := Forge.vbox(2)
	words.size_flags_horizontal = SIZE_EXPAND_FILL
	words.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(words)
	var top := Forge.hbox(10)
	words.add_child(top)
	top.add_child(Forge.sc(a.name, 22, Forge.GOLD))
	top.add_child(Forge.type_glyph(a, 20))
	top.add_child(Forge.sc(Forge.TYPE_NAME[Forge.skill_type(a)], 16, Forge.LABEL))
	var m := Forge.label(HeroSheet.meta(a) + ("" if a.pattern in ["single", "all"] else " · " + b.shape_name(a.pattern)), 20, Forge.MUTED)
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(m)
	row.add_child(HeroSheet.pattern_grid(a.pattern, Forge.ELEM[u.elem]))
	return p


func _note(text: String) -> void:
	var l := Forge.label(text, 21, Forge.MUTED, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 632
	_panel.add_child(l)


# ---------- what tiles ask ----------

func tex(src: String) -> Texture2D:
	if not _tex.has(src):
		_tex[src] = load(src)
	return _tex[src]


## The unit standing on a tile as currently shown, with its view: the living one, else the fallen one.
func unit_view(side: String, r: int, c: int) -> Dictionary:
	var fallen := {}
	for u in b.units:
		var s: Dictionary = view.get(u.id, {})
		if s.is_empty() or u.side != side or s.r != r or s.c != c:
			continue
		var out := {"id": u.id, "name": u.name, "elem": u.elem, "max_hp": u.max_hp, "view": s}
		if u.has("short"): out.short = u.short
		if u.has("portrait"): out.portrait = u.portrait
		if s.alive:
			return out
		fallen = out
	return fallen


func _aim() -> Dictionary:
	if _playing or b.phase != "plan" or sel_act == "":
		return {}
	var u := b.unit(sel_id)
	return {} if u.is_empty() else b.aim_tiles(u, b.act(u, sel_act))


func is_lit(side: String, r: int, c: int) -> bool:
	if b.phase == "form" and not _playing:
		var u := b.unit(sel_id)
		return side == "P" and not u.is_empty() and (u.r != r or u.c != c)
	var tg := _aim()
	return not tg.is_empty() and tg.side == side and Vector2i(r, c) in tg.tiles


## The previewed shape: where an area skill would land if cast on the tile being aimed at.
func in_area(side: String, r: int, c: int) -> bool:
	var tg := _aim()
	if tg.is_empty() or tg.side != side or _aim_at.x < 0 or _aim_side != side:
		return false
	var a := b.act(b.unit(sel_id), sel_act)
	return Vector2i(r, c) in b.area_of(a, _aim_at.x, _aim_at.y)


## Whether an armed action places a shape (a lane, a row, a cross), so a tap previews before it casts.
func _places_shape() -> bool:
	if sel_act == "" or b.phase != "plan" or _playing:
		return false
	var a := b.act(b.unit(sel_id), sel_act)
	return a.get("pattern", "single") in ["cross", "sweep", "pierce"]


## Hovering a tile with a mouse previews the shape there; a tap does the same on a phone.
func on_hover(side: String, r: int, c: int) -> void:
	if not _places_shape():
		return
	var tg := _aim()
	if tg.is_empty() or tg.side != side or not Vector2i(r, c) in tg.tiles:
		return
	_aim_at = Vector2i(r, c)
	_aim_side = side
	for t in _tiles.values():
		t.queue_redraw()


func is_selected(u: Dictionary) -> bool:
	return u.id == sel_id and not _playing and (b.phase == "plan" or b.phase == "form")


func queue_index(u: Dictionary) -> int:
	for i in b.queue.size():
		if b.queue[i].id == u.id:
			return i
	return -1


## "weak" or "resists" on a foe while aiming a damaging action at it.
func edge_note(u: Dictionary) -> String:
	if u.id.begins_with("P") or sel_act == "" or _aim().is_empty():
		return ""
	var me := b.unit(sel_id)
	if b.act(me, sel_act).kind != "dmg":
		return ""
	var m := b.elem_mult(me.elem, u.elem)
	return "weak" if m > 1 else "resists" if m < 1 else ""


# ---------- input ----------

func on_tile(side: String, r: int, c: int) -> void:
	if _playing:
		return
	_hint = ""
	if b.phase == "form":
		if side != "P":
			return
		var there := b.at("P", r, c)
		var u := b.unit(sel_id)
		if not there.is_empty() and there.id != sel_id:
			sel_id = there.id
		elif not u.is_empty():
			b.place_hero(sel_id, r, c)
			_keep_formation()
		view = b.snapshot()
		refresh()
		return
	if b.phase != "plan":
		return
	var u := b.unit(sel_id)
	if sel_act != "" and not u.is_empty():
		var a := b.act(u, sel_act)
		var tg := b.aim_tiles(u, a)
		if tg.side == side and Vector2i(r, c) in tg.tiles:
			var tile: BattleTile = _tiles["%s%d%d" % [side, r, c]]
			if _places_shape() and (_aim_at != Vector2i(r, c) or _aim_side != side):
				# First tap places the shape; the second on the same tile casts.
				_aim_at = Vector2i(r, c)
				_aim_side = side
				Burst.on(tile, Forge.GOLD, 30, 6)
				refresh()
				return
			for v in b.area_of(a, r, c) if _places_shape() else [Vector2i(r, c)]:
				Burst.on(_tiles["%s%d%d" % [side, v.x, v.y]], Forge.ELEM[u.elem], 44, 8)
			b.enqueue(u.id, sel_act, r, c)
			_next_hero()
			refresh()
			return
	var t := b.at(side, r, c)
	if side == "P" and not t.is_empty():
		sel_id = t.id
		sel_act = ""
		_aim_at = Vector2i(-1, -1)
	refresh()


func _on_action(key: String) -> void:
	if _playing or b.phase != "plan":
		return
	var u := b.unit(sel_id)
	if u.is_empty() or u.st.stun > 0:
		return
	var a := b.act(u, key)
	_hint = b.blocked_reason(u, a)
	if _hint != "":
		refresh()
		return
	if a.kind == "guard" or a.get("pattern", "") == "all":
		b.enqueue(u.id, key, u.r, u.c)
		_next_hero()
	else:
		sel_act = "" if sel_act == key else key
		_aim_at = Vector2i(-1, -1)
	refresh()


## After queueing, the next hero who still needs orders.
func _next_hero() -> void:
	sel_act = ""
	_aim_at = Vector2i(-1, -1)
	for u in b.living("P"):
		if u.st.stun == 0 and queue_index(u) < 0:
			sel_id = u.id
			return


func _keep_formation() -> void:
	for u in b.units:
		if u.side == "P":
			app.col.formation[u.key] = Vector2i(u.r, u.c)


## The studs button: begin the fight, resolve the planned round, or start again.
func _commit() -> void:
	if _playing:
		return
	_hint = ""
	sel_act = ""
	match b.phase:
		"form":
			_keep_formation()
			_playing = true
			refresh()
			await Banner.play(app, "battle start", "round 1").finished
			_playing = false
			b.phase = "plan"
			if b.run_openers() and b.over():
				b._finish()
			await _play()
		"plan":
			b.run_round()
			await _play()
		"over":
			_new_fight()
			b.phase = "plan"
			_log.text = ""
			refresh()
			_intro()


## Plays back what the engine just resolved, a beat at a time, then settles on the board as it stands.
func _play() -> void:
	_playing = true
	refresh()
	var pending := []
	for e in b.take_events():
		match e.t:
			"flash", "float":
				pending.append(e)
			"log":
				_log.text = e.text
			"phase":
				var words := {"opening": ["opening volley", "celerity strikes first"], "ally": ["ally turn", "round %d" % b.round_num],
					"enemy": ["enemy turn", ""]}
				var w: Array = words.get(e.name, [e.name, ""])
				await Banner.play(app, w[0], w[1], Forge.GOLD if e.name != "enemy" else Color("#e86a5a")).finished
				if not is_inside_tree():
					return
			"cutin":
				await CutIn.play(app, e.src).finished
				if not is_inside_tree():
					return
			"step":
				view = e.snap
				for t in _tiles.values():
					t.queue_redraw()
				for p in pending:
					var tile: BattleTile = _tiles.get("%s%d%d" % [p.side, p.r, p.c])
					if tile == null:
						continue
					if p.t == "flash":
						tile.flash()
						Burst.on(tile, Forge.GOLD_LIGHT, 30, 5)
					else:
						tile.float_text(p.txt, p.cls)
				pending = []
				await get_tree().create_timer(BEAT).timeout
				if not is_inside_tree():
					return
	view = b.snapshot()
	if b.phase == "over":
		var win := b.result == "win"
		await Banner.play(app, "victory" if win else "defeat", "round %d" % b.round_num, Forge.GOLD if win else Forge.MUTED).finished
	_playing = false
	var first := b.living("P").filter(func(u): return u.st.stun == 0)
	if first.size():
		sel_id = first[0].id
	refresh()
