class_name BattleScreen
extends Screen
## The battle prototype: the foes' grid on top, the round strip as the front line, your squad's grid below, and the
## selected hero's actions at the foot. Set the formation, then plan each round: tap a hero, an action, then a lit
## tile; queued skills chain. The studs button commits (begin, fight, fight again). Reach is on: single-target melee
## must stand at the front of a lane with an enemy across it, so moving is how you line up a hit.
## Nothing here assumes four heroes: grids, chips and the panel size from the battle's own rows, columns and units.

const GAP := 8.0
## Tile height: taller on the 3-row grid a four-hero squad fights on, so the board fills the screen.
const TILE_H := {3: 112.0, 4: 88.0}
## How long each beat of a resolving round stays on screen.
const BEAT := 0.42
## The open action panel's height: the hero line, two rows of buttons, the armed skill and a two-line hint.
const PANEL_H := 300.0
## The freeze before a heavy hit's shake, in seconds.
const HIT_STOP := 0.09
## The strip's middle: the queue chips, the forecast bar or the round's log, whichever is showing.
const MID_H := 104.0
const HEAD := 100.0
## A tile on the wide (landscape) board, where the grids stand side by side.
const WIDE_TILE := Vector2(132, 118)

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
## Where the armed action is aimed: it starts on the best target, a tap moves it, a second tap on it casts.
## (-1, -1) when nothing is armed.
var _aim_at := Vector2i(-1, -1)
var _aim_side := ""
## What the aimed action would do, target by target (Battle.forecast), and which target the forecast bar shows.
var _fc: Array = []
var _fc_i := 0
## Danger view: each foe's intended action and the tiles it threatens.
var _danger := false
var _intents: Array = []
var _danger_btn: Button
var _retreat: Button
var _tiles := {}
var _tex := {}
var _round: Label
var _phase: Label
var _chips: HFlowContainer
var _mid: Control
var _forecast: Control
var _go: Button
var _panel: VBoxContainer
var _log: Label


func _init() -> void:
	tab = "expedition"
	title = "battle"


func setup(a: App) -> Screen:
	super.setup(a)
	# On an expedition the fight is named for its node: a skirmish, an elite, the warden.
	if a.run and a.run.at.x >= 0:
		title = Expedition.NODES[a.run.node(a.run.at).type].name
	return self


func _build() -> void:
	body.add_theme_constant_override("separation", 14)
	_new_fight()
	_round = Forge.sc("", 22, Forge.LABEL)
	head_right.add_child(_round)
	_retreat = Forge.link("retreat", "back", 20)
	_retreat.custom_minimum_size.y = 44
	_retreat.tooltip_text = "Leave this fight and start over from the formation"
	_retreat.pressed.connect(func():
		if _playing:
			return
		_new_fight()
		_log.text = ""
		refresh()
		_intro())
	head_right.add_child(_retreat)
	if Forge.wide():
		# Side on: your squad on the left facing right, the foes on the right facing left, the round and the actions
		# in a column beside them.
		var row := Forge.hbox(24)
		body.add_child(row)
		row.add_child(_grid("P"))
		row.add_child(_grid("E"))
		var side := Forge.vbox(12)
		side.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(side)
		side.add_child(_strip())
		side.add_child(_dock())
	else:
		body.add_child(_grid("E"))
		body.add_child(_strip())
		body.add_child(_grid("P"))
		# The selected hero's actions dock at the foot, outside the scroll.
		var root := body.get_parent().get_parent().get_parent()
		root.add_child(_dock())
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
					var from := Vector2(700 if side == "E" else -700, 0) if Forge.wide() else Vector2(0, -520 if side == "E" else 520)
					t.intro(0.1 + i * 0.09, from)
					i += 1


## A fresh fight with the squad on the field, standing where the formation left them. Reach is on here.
func _new_fight() -> void:
	_paid = 0
	_spoils = ""
	_aim_at = Vector2i(-1, -1)
	_fc = []
	b = Battle.new()
	b.rules.reach = true
	b.rules.ground = true
	# Three rows for a four-hero squad; the fourth comes back if squads grow to five.
	b.rows = Collection.ROWS
	b.cols = Collection.COLS
	var heroes := []
	var pos := {}
	var run := app.run
	for uid in app.col.squad:
		if run and run.fallen(uid):
			continue
		var u := Battle.card_unit(app.col, uid, b)
		if run:
			run.boost(u)
			u.hp = maxi(1, roundi(u.max_hp * run.health(uid)))
		heroes.append(u)
		pos[uid] = app.col.tile(uid)
	if run and run.at.x >= 0:
		var foes := run.foes_for(run.at)
		b.start(heroes, pos, foes.keys, foes.scale)
	else:
		b.start(heroes, pos)
	b.phase = "form"
	view = b.snapshot()
	sel_id = b.living("P")[0].id
	sel_act = ""
	_hint = ""


# ---------- layout ----------

## A side's grid. The foes' front row sits at the bottom of theirs and yours at the top, so the fronts face across the strip.
## On a wide screen the grids turn on their side: lanes run down, and the two front rows meet in the middle.
func _grid(side: String) -> Control:
	var g := Control.new()
	var wide := Forge.wide()
	var tw := WIDE_TILE.x if wide else (632.0 - GAP * (b.cols - 1)) / b.cols
	var th: float = WIDE_TILE.y if wide else TILE_H.get(b.rows, 88.0)
	if wide:
		g.custom_minimum_size = Vector2(b.rows * tw + (b.rows - 1) * GAP, b.cols * th + (b.cols - 1) * GAP)
	else:
		g.custom_minimum_size = Vector2(632, b.rows * th + (b.rows - 1) * GAP)
	for r in b.rows:
		for c in b.cols:
			var t := BattleTile.new()
			t.screen = self
			t.side = side
			t.r = r
			t.c = c
			var row := b.rows - 1 - r if side == "E" else r
			if wide:
				var depth := r if side == "E" else b.rows - 1 - r
				t.position = Vector2(depth * (tw + GAP), c * (th + GAP))
			else:
				t.position = Vector2(c * (tw + GAP), row * (th + GAP))
			t.size = Vector2(tw, th)
			g.add_child(t)
			_tiles["%s%d%d" % [side, r, c]] = t
	return g


## The docked action panel: a handle (the hero's name and a chevron) over the actions. Tap the handle to fold it.
func _dock() -> Control:
	var p := PanelContainer.new()
	var pad := 24 if Forge.wide() else 44
	var st := Forge.flat(Color(Forge.PLAQUE_DEEP, 0.97), Color(Forge.GOLD_DEEP, 0.8), 0, Vector4(pad, 18, pad, 28))
	st.border_width_top = 2
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 16
	p.add_theme_stylebox_override("panel", st)
	_panel = Forge.vbox(10)
	# One fixed height, so the buttons never slide under a thumb as hints or skill details come and go.
	_panel.custom_minimum_size.y = PANEL_H
	p.add_child(_panel)
	return p


## The front line between the grids: round and phase, the danger toggle and the one commit button; under them either
## the queue or, while aiming, the forecast. That middle keeps one height so the board never moves.
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
	_phase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(_phase)
	_danger_btn = Forge.link("danger", "", 20)
	_danger_btn.custom_minimum_size.y = 56
	_danger_btn.tooltip_text = "Show what each foe means to do this round"
	_danger_btn.pressed.connect(func():
		_danger = not _danger
		refresh())
	row.add_child(_danger_btn)
	_go = Forge.studs("fight", true, 64)
	_go.custom_minimum_size.x = 200
	_go.pressed.connect(_commit)
	row.add_child(_go)
	_mid = Control.new()
	_mid.custom_minimum_size = Vector2(0 if Forge.wide() else 632, MID_H)
	v.add_child(_mid)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 8)
	_chips.add_theme_constant_override("v_separation", 8)
	_chips.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mid.add_child(_chips)
	_forecast = Forge.vbox(0)
	_forecast.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mid.add_child(_forecast)
	# What just happened, line by line, while a round plays out.
	_log = Forge.label("", 20, Forge.PARCHMENT, Forge.SANS_ITALIC)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mid.add_child(_log)
	v.add_child(Forge.rule())
	return v


func refresh() -> void:
	for t in _tiles.values():
		t.queue_redraw()
	var phase := "run" if _playing else b.phase
	_round.text = ("formation" if phase == "form" else "round %d" % b.round_num).to_lower()
	_phase.text = {"form": "Tap a hero, then a tile, to set your formation.", "plan": "Plan the round: queued skills chain.",
		"run": "Resolving…", "over": ""}[phase]
	_go.text = {"form": "begin", "plan": "fight", "run": "fight", "over": "back to the road" if app.run else "fight again"}[phase]
	_go.disabled = _playing
	_log.visible = _playing or b.phase == "over"
	if not _playing and b.phase == "plan":
		view = _plan_view()
	_intents = b.intents() if _danger and b.phase == "plan" and not _playing else []
	_danger_btn.visible = b.phase == "plan" and not _playing
	_danger_btn.add_theme_color_override("font_color", Forge.HARM if _danger else Forge.DIM)
	_fill_forecast()
	_chips.visible = not _log.visible and _fc.is_empty()
	_forecast.visible = not _log.visible and not _fc.is_empty()
	_fill_chips()
	_fill_panel()
	var fighting: bool = _playing or b.phase in ["plan", "run"]
	app.show_nav(not fighting)
	# The panel keeps one height only while fighting, when its buttons are in use.
	_panel.custom_minimum_size.y = PANEL_H if b.phase == "plan" else 0.0
	_retreat.visible = b.phase == "plan" and not _playing


## The board while planning: heroes stand where their planned step takes them.
func _plan_view() -> Dictionary:
	var v := b.snapshot()
	for id in b.steps:
		v[id].r = b.steps[id].x
		v[id].c = b.steps[id].y
	return v


## While planning, the hero who will step away from this tile: drawn as a faded ghost where they stand now.
func ghost_at(side: String, r: int, c: int) -> Dictionary:
	if _playing or b.phase != "plan" or side != "P":
		return {}
	for id in b.steps:
		var u := b.unit(id)
		if u.r == r and u.c == c:
			return u
	return {}


## While planning with no action armed, the empty tiles the selected hero can step to.
func is_step(side: String, r: int, c: int) -> bool:
	if _playing or b.phase != "plan" or sel_act != "" or side != "P":
		return false
	var u := b.unit(sel_id)
	if u.is_empty() or not u.alive or u.st.stun > 0:
		return false
	var v := Vector2i(r, c)
	var shown: Dictionary = view.get(sel_id, {})
	return v in b.step_tiles(u) and (shown.is_empty() or v != Vector2i(shown.r, shown.c)) and unit_view(side, r, c).is_empty()


## The forecast bar, Fire Emblem style: the acting hero's headshot faces the target's across the numbers, with the
## target's HP before and after between them. With several targets in the shape, the arrows (or a tap on a numbered
## tile) step through them.
func _fill_forecast() -> void:
	for ch in _forecast.get_children():
		ch.queue_free()
	if _fc.is_empty():
		return
	_fc_i = clampi(_fc_i, 0, _fc.size() - 1)
	var e: Dictionary = _fc[_fc_i]
	var me := b.unit(sel_id)
	var a := b.act(me, sel_act)
	var t := b.unit(e.id)
	var tint: Color = Forge.MEND if e.kind != "dmg" else Forge.HARM
	var row := Forge.hbox(10)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	_forecast.add_child(row)
	var mine := _headshot(me, Forge.GOLD_LIGHT)
	Rim.on(mine, "comet", [Color("#fff1c4")], 3.0)
	var icon := Forge.skill_icon(a, me.elem, 40)
	icon.position = Vector2(HEAD - 30, -8)
	mine.add_child(icon)
	row.add_child(mine)
	var mid := Forge.vbox(2)
	mid.size_flags_horizontal = SIZE_EXPAND_FILL
	mid.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(mid)
	var tags := Forge.hbox(8)
	mid.add_child(tags)
	var an := Forge.sc(a.name + "  →", 20, Forge.GOLD)
	an.clip_text = true
	an.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	an.size_flags_horizontal = SIZE_EXPAND_FILL
	tags.add_child(an)
	var nums := Forge.hbox(8)
	mid.add_child(nums)
	if e.kind == "shield":
		nums.add_child(Forge.sc("shield +%d" % e.shield, 26, Forge.MEND, true, 0.04))
	else:
		nums.add_child(Forge.sc("hp %d" % e.before, 20, Forge.MUTED, false, 0.04))
		nums.add_child(Forge.sc("→ %d" % e.after, 28, tint, true, 0.04))
		nums.add_child(Forge.sc("(%+d)" % (e.after - e.before), 18, Forge.MUTED, false, 0.04))
	mid.add_child(_hp_bar(e))
	if e.edge != "":
		tags.add_child(Forge.sc(e.edge, 16, Forge.GAIN if e.edge == "weak" else Forge.MUTED))
	if e.ko:
		tags.add_child(Forge.sc("knocked out", 16, Forge.HARM, true))
	# Several targets: the count sits on the target's headshot and the arrows either side step through them.
	var theirs := _headshot(t, tint, e.ko, "%d/%d" % [_fc_i + 1, _fc.size()] if _fc.size() > 1 else "")
	Rim.on(theirs, "flow", [tint.darkened(0.3), tint, tint.lightened(0.4), tint], 3.0)
	var cyc := Forge.hbox(0)
	cyc.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(cyc)
	for d in [-1, 1]:
		if d > 0:
			cyc.add_child(theirs)
		if _fc.size() < 2:
			continue
		var bt := Forge.link("‹" if d < 0 else "›", "", 30)
		bt.custom_minimum_size = Vector2(34, 64)
		bt.pressed.connect(func():
			_fc_i = (_fc_i + d + _fc.size()) % _fc.size()
			_fill_forecast()
			_redraw_tiles())
		cyc.add_child(bt)


## A unit's face, cropped by the portrait's eye line, framed in `edge`, with the name across the bottom. Foes without
## art show their element. A knocked-out forecast greys the face and marks it with a skull; `badge` is a corner count.
func _headshot(u: Dictionary, edge: Color, ko := false, badge := "") -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(HEAD, HEAD)
	c.size_flags_vertical = SIZE_SHRINK_CENTER
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, c.size)
		c.draw_rect(r, Color(Forge.ELEM[u.elem], 0.25))
		if u.has("portrait"):
			Forge.portrait(c, tex(u.portrait.src), r.grow(-2), u.portrait, 0.85, "face")
		else:
			c.draw_texture_rect(Forge.sigil(u.elem), Rect2(r.get_center() - Vector2(26, 34), Vector2(52, 52)), false, Forge.GOLD)
		c.draw_polygon(PackedVector2Array([Vector2(0, HEAD * 0.55), Vector2(HEAD, HEAD * 0.55), Vector2(HEAD, HEAD), Vector2(0, HEAD)]),
			PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Color(Forge.INK, 0.92), Color(Forge.INK, 0.92)]))
		if ko:
			c.draw_rect(r, Color(Forge.INK, 0.5))
			BattleTile.skull(c, r.get_center() + Vector2(0, -8), 1.6)
		c.draw_string(Forge.tracked(Forge.SC, 1), Vector2(0, HEAD - 8), Battle.name_of(u).to_lower(), HORIZONTAL_ALIGNMENT_CENTER, HEAD, 16, Forge.PARCHMENT)
		if badge != "":
			c.draw_rect(Rect2(HEAD - 40, 0, 40, 22), Color(Forge.INK, 0.9))
			c.draw_string(Forge.SC, Vector2(HEAD - 40, 17), badge, HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Forge.PARCHMENT)
		c.draw_rect(r, edge, false, 3.0))
	return c


## An HP bar showing the part an attack takes (red) or a heal restores (green).
func _hp_bar(e: Dictionary) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.draw.connect(func():
		var w := bar.size.x
		var mx := float(e.max_hp)
		bar.draw_rect(Rect2(0, 0, w, 8), Color(Forge.INK, 0.9))
		var lo := minf(e.before, e.after) / mx
		var hi := maxf(e.before, e.after) / mx
		bar.draw_rect(Rect2(0, 0, w * lo, 8), Forge.GAIN if lo > 0.35 else BattleTile.HP_LOW)
		bar.draw_rect(Rect2(w * lo, 0, w * (hi - lo), 8), Forge.HARM if e.after < e.before else Forge.MEND))
	return bar


## A short, sharp shake of the whole screen that settles back where it was.
func _shake(strength := 10.0) -> void:
	var home := position
	var t := create_tween()
	for i in 6:
		var k := strength * (1.0 - i / 6.0)
		t.tween_property(self, "position", home + Vector2(randf_range(-k, k), randf_range(-k, k)), 0.035)
	t.tween_property(self, "position", home, 0.05)


func _redraw_tiles() -> void:
	for t in _tiles.values():
		t.queue_redraw()


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
		if app.run:
			_settle_run(win)
			if win:
				_panel.add_child(Forge.sc("+%d embers gathered · %d on the road" % [_paid, app.run.embers], 22, Forge.GAIN))
		elif win:
			if _paid == 0:
				_paid = app.town.battle_reward()
				app.town.earn(_paid)
			_panel.add_child(Forge.sc("+%d embers to the town" % _paid, 22, Forge.GAIN))
		if win:
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
	for k in ["basic", "guard"]:
		basics.add_child(_act_button(u, k, 56))
	var hint := _hint
	if hint == "":
		if u.st.stun > 0:
			hint = "Stunned: %s loses the next action." % Battle.name_of(u)
		elif sel_act != "":
			var a := b.act(u, sel_act)
			if a.kind == "move":
				hint = "Tap a lit empty tile to step there."
			elif b.reach_blocked(b.as_planned(u), a):
				hint = "Reach: only the enemy across this lane."
			elif b.aims_ground(a):
				hint = "Aimed at the best spot. Tap any enemy tile to move the %s (empty tiles count), then tap it or the skill again to cast." % b.shape_name(a.pattern).to_lower()
			elif a.get("pattern", "") == "all":
				hint = "Covers the whole grid. Tap the skill again to cast."
			else:
				hint = "Aimed at the best target. Tap another to switch, then tap it or the skill again to cast."
		else:
			for i in u.skills.size():
				var why := b.blocked_reason(b.as_planned(u), b.act(u, "s%d" % i))
				if why != "" and u.cd[i] == 0:
					hint = "%s: %s" % [u.skills[i].name, why.to_lower()]
					break
	if hint == "" and sel_act == "" and b.steps.has(u.id):
		hint = "Stepping to %s first, then acting. Tap the faded spot to stay put." % b.lane(b.steps[u.id].x, b.steps[u.id].y)
	if hint == "" and sel_act == "" and b.queued(u.id).is_empty():
		hint = "Blue tiles: step up to %d tiles first, if you like. Then pick a skill: it plays out in the order you queue it." % b.tune.step
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
	var q := b.queued(u.id)
	var is_queued: bool = q.get("key", "") == key
	if is_queued:
		text = "%s · #%d" % [a.name, queue_index(u) + 1]
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
	bt.button_pressed = sel_act == key or is_queued
	bt.disabled = _playing or b.phase != "plan" or u.st.stun > 0 or (a.is_skill and u.cd[a.idx] > 0) or b.blocked_reason(b.as_planned(u), a) != ""
	bt.tooltip_text = "Queued. Tap to take it back." if is_queued else a.get("desc", "")
	bt.pressed.connect(func():
		if is_queued:
			# Already queued: tapping it again takes it back out of the queue.
			b.dequeue(u.id)
			_disarm()
			refresh()
			return
		Burst.on(bt, Forge.ELEM[u.elem] if a.is_skill else Forge.GOLD, 54 if a.is_skill else 34, 10 if a.is_skill else 6)
		if sel_act == key and _aim_at.x >= 0:
			# Armed already: a second tap casts where it is aimed.
			_cast(u, _aim_side, _aim_at)
			return
		_on_action(key))
	return bt


func _note(text: String) -> void:
	var l := Forge.label(text, 21, Forge.MUTED, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 0 if Forge.wide() else 632
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
	return {} if u.is_empty() else b.aim_tiles(b.as_planned(u), b.act(u, sel_act))


func _armed_act() -> Dictionary:
	return b.act(b.unit(sel_id), sel_act) if sel_act != "" and not b.unit(sel_id).is_empty() else {}


## Tiles the armed action can be aimed at: a thin outline in the action's colour.
func is_lit(side: String, r: int, c: int) -> bool:
	if b.phase == "form" and not _playing:
		var u := b.unit(sel_id)
		return side == "P" and not u.is_empty() and (u.r != r or u.c != c)
	var tg := _aim()
	return not tg.is_empty() and tg.side == side and Vector2i(r, c) in tg.tiles


## The colour an armed action paints a tile it would cover: "harm" for attacks, "mend" for heals and shields, else "".
func area_kind(side: String, r: int, c: int) -> String:
	if _aim_at.x < 0 or _aim_side != side or _aim().is_empty():
		return ""
	var a := _armed_act()
	var hit: bool = a.get("pattern", "") == "all" or Vector2i(r, c) in b.area_of(a, _aim_at.x, _aim_at.y)
	return ("harm" if a.kind == "dmg" else "mend") if hit else ""


func aim_center(side: String, r: int, c: int) -> bool:
	return _aim_side == side and _aim_at == Vector2i(r, c) and _armed_act().get("pattern", "") != "all"


## The forecast for the unit shown on a tile, and whether it is the one the bar is showing.
func preview_at(side: String, r: int, c: int) -> Dictionary:
	for i in _fc.size():
		var e: Dictionary = _fc[i]
		var shown: Dictionary = view.get(e.id, {})
		if e.side == side and not shown.is_empty() and shown.r == r and shown.c == c:
			var out := e.duplicate()
			out.current = i == _fc_i
			return out
	return {}


## Danger view: how many foes' intended attacks cover this tile.
func threat_at(side: String, r: int, c: int) -> int:
	var n := 0
	for i in _intents:
		if not i.stunned and i.kind == "dmg" and i.side == side and Vector2i(r, c) in i.tiles:
			n += 1
	return n


func intent_of(id: String) -> Dictionary:
	for i in _intents:
		if i.id == id:
			return i
	return {}


## Arms an action: aimed straight away at the best target (the AI's own pick), its area painted and forecast shown.
func _arm(key: String) -> void:
	sel_act = key
	var u := b.unit(sel_id)
	var a := b.act(u, key)
	var me := b.as_planned(u)
	var tg := b.aim_tiles(me, a)
	_aim_side = tg.side
	if a.get("pattern", "") == "all":
		_aim_at = Vector2i(me.r, me.c)
	else:
		var p: Variant = b.pick(me, a)
		_aim_at = p if p != null else (tg.tiles[0] if tg.tiles.size() else Vector2i(-1, -1))
	_update_forecast()


func _update_forecast() -> void:
	_fc = []
	_fc_i = 0
	if sel_act == "" or _aim_at.x < 0:
		return
	_fc = b.forecast(sel_id, sel_act, _aim_at.x, _aim_at.y)


func _disarm() -> void:
	sel_act = ""
	_aim_at = Vector2i(-1, -1)
	_fc = []


## Hovering a tile with a mouse moves the aim there (a tap does the same on a phone); the forecast follows.
func on_hover(side: String, r: int, c: int) -> void:
	var tg := _aim()
	if tg.is_empty() or tg.side != side or not Vector2i(r, c) in tg.tiles or _armed_act().get("pattern", "") == "all":
		return
	if _aim_at == Vector2i(r, c) and _aim_side == side:
		return
	_aim_at = Vector2i(r, c)
	_aim_side = side
	_update_forecast()
	_fill_forecast()
	_chips.visible = _fc.is_empty()
	_forecast.visible = not _fc.is_empty()
	_redraw_tiles()


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
		var tg := b.aim_tiles(b.as_planned(u), a)
		if tg.side == side and Vector2i(r, c) in tg.tiles:
			var whole: bool = a.get("pattern", "") == "all"
			if not whole and (_aim_at != Vector2i(r, c) or _aim_side != side):
				# A tap elsewhere moves the aim; a tap on the aimed tile casts.
				_aim_at = Vector2i(r, c)
				_aim_side = side
				_update_forecast()
				Burst.on(_tiles["%s%d%d" % [side, r, c]], Forge.GOLD, 30, 6)
				refresh()
				return
			_cast(u, side, _aim_at)
			return
	# Planning a step: an empty lit tile on your grid, or the faded spot to stay put.
	if side == "P" and sel_act == "" and not u.is_empty():
		var ghost := ghost_at(side, r, c)
		if is_step(side, r, c) or (not ghost.is_empty() and ghost.id == sel_id):
			b.plan_step(sel_id, Vector2i(r, c))
			Burst.on(_tiles["P%d%d" % [r, c]], Forge.GOLD, 34, 6)
			refresh()
			return
	var shown := unit_view(side, r, c)
	if side == "P" and not shown.is_empty() and shown.view.alive:
		sel_id = shown.id
		_disarm()
	elif side == "P" and not ghost_at(side, r, c).is_empty():
		sel_id = ghost_at(side, r, c).id
		_disarm()
	refresh()


## Queues the armed action where it is aimed, with a spark on every tile it covers.
func _cast(u: Dictionary, side: String, at: Vector2i) -> void:
	var a := b.act(u, sel_act)
	var cover: Array = b.all_tiles() if a.get("pattern", "") == "all" else b.area_of(a, at.x, at.y)
	for v in cover:
		var t: BattleTile = _tiles.get("%s%d%d" % [side, v.x, v.y])
		if t:
			Burst.on(t, Forge.HARM if a.kind == "dmg" else Forge.MEND, 44, 8)
	b.enqueue(u.id, sel_act, at.x, at.y)
	_next_hero()
	refresh()


func _on_action(key: String) -> void:
	if _playing or b.phase != "plan":
		return
	var u := b.unit(sel_id)
	if u.is_empty() or u.st.stun > 0:
		return
	var a := b.act(u, key)
	_hint = b.blocked_reason(b.as_planned(u), a)
	if _hint != "":
		refresh()
		return
	if a.kind == "guard":
		b.enqueue(u.id, key, u.r, u.c)
		_next_hero()
	else:
		_arm(key)
	refresh()


## After queueing, the next hero who still needs orders.
func _next_hero() -> void:
	_disarm()
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
	_disarm()
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
			# Play back from the board as it stands, not as planned: steps happen during the round.
			view = b.snapshot()
			b.run_round()
			await _play()
		"over":
			if app.run:
				app.show_tab("expedition")
				return
			_new_fight()
			b.phase = "plan"
			_log.text = ""
			refresh()
			_intro()


## Hands the fight's outcome to the expedition once: each hero's health carries on (the fallen stay down).
func _settle_run(win: bool) -> void:
	if _paid != 0 or app.run.over != "":
		return
	var before := app.run.embers
	var health := {}
	for u in b.units:
		if u.side == "P":
			health[u.key] = float(u.hp) / u.max_hp if u.alive else 0.0
	app.run.finish_fight(win, health)
	_paid = maxi(1, app.run.embers - before)


## Plays back what the engine just resolved, a beat at a time, then settles on the board as it stands.
func _play() -> void:
	_playing = true
	refresh()
	var pending := []
	var walks := []
	for e in b.take_events():
		match e.t:
			"flash", "float":
				pending.append(e)
			"log":
				_log.text = e.text
			"walk":
				var was: Dictionary = view.get(e.id, {})
				if not was.is_empty():
					walks.append({"side": e.id.left(1), "from": Vector2i(was.r, was.c), "to": Vector2i(e.r, e.c)})
			"phase":
				var words := {"opening": ["opening volley", "celerity strikes first"], "ally": ["ally turn", "round %d" % b.round_num],
					"enemy": ["enemy turn", ""]}
				var w: Array = words.get(e.name, [e.name, ""])
				await Banner.play(app, w[0], w[1], Forge.GOLD if e.name != "enemy" else Color("#e86a5a")).finished
				if not is_inside_tree():
					return
			"cutin":
				var who := b.unit(e.id)
				await CutIn.pop(app, e.src, e.name, Battle.name_of(who), who.elem).finished
				if not is_inside_tree():
					return
			"step":
				# A hit on a weakness or a knockout lands with weight: a beat of freeze, then the screen shakes.
				var heavy: bool = pending.any(func(p): return p.t == "float" and p.cls == "crit")
				for id in e.snap:
					if view.get(id, {}).get("alive", false) and not e.snap[id].alive:
						heavy = true
				view = e.snap
				for t in _tiles.values():
					t.queue_redraw()
				# A hero who stepped walks across from their old tile.
				for w in walks:
					var to: BattleTile = _tiles["%s%d%d" % [w.side, w.to.x, w.to.y]]
					var from: BattleTile = _tiles["%s%d%d" % [w.side, w.from.x, w.from.y]]
					to.intro(0.0, from.position - to.position)
				walks = []
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
				if heavy:
					await get_tree().create_timer(HIT_STOP).timeout
					_shake()
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
