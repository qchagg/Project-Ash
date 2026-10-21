class_name CardArt
extends Control
## A hero's portrait in its tier frame, with the element sigil. Name plates sit below it, never on it.

var hero := ""
var stars := 1
## Draw the filigree corners from the menus (hero sheet only; tiles stay clean).
var ornate := false
## Extra marks (squad pennant, copy count) drawn on top of the card.
var overlay := Callable()
var _tex: Texture2D
var _t := 0.0


func setup(hero_key: String, star_count: int) -> CardArt:
	hero = hero_key
	stars = star_count
	_tex = load(Data.hero(hero).portrait.src)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _process(delta: float) -> void:
	if stars == 4:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var h := Data.hero(hero)
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#1f1812"))
	Forge.portrait(self, _tex, r.grow(-3), h.portrait)
	Forge.card_frame(self, r, stars, h.elem, _t)
	if ornate:
		Forge.filigree(self, r, Color("#d9a777"), 60.0)
	var s := minf(size.x * 0.16, 56.0)
	var c := Vector2(s * 0.5 + 16, s * 0.5 + 16)
	draw_circle(c, s * 0.5 + 4, Forge.INK)
	draw_circle(c, s * 0.5 + 2, Forge.GOLD)
	draw_circle(c, s * 0.5 - 1, Forge.ELEM[h.elem])
	draw_texture_rect(Forge.sigil(h.elem), Rect2(c - Vector2(s, s) * 0.3, Vector2(s, s) * 0.6), false, Forge.INK)
	if overlay.is_valid():
		overlay.call(self)
