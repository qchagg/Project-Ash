class_name Stand
extends Control
## A hero standing in a pool of their element's light: the landscape build's way of showing who you have, where the
## phone build shows a card. The pool's ring is the tier: bronze, silver or gold, and a 4★ ring turns through the
## element's colours like a 4★ card's rim. `health` (0..1) shows a bar under the feet and greys a fallen hero.

var hero := ""
var stars := 1
## Health on the road, or -1 to hide the bar.
var health := -1.0
## How tall the fighter stands against the control's height.
var tall := 0.78
var _t := 0.0


func setup(hero_key: String, star_count: int, hp := -1.0) -> Stand:
	hero = hero_key
	stars = star_count
	health = hp
	_t = randf() * 4.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var h := Data.hero(hero)
	var spr := Data.sprite_for({"hero": hero})
	var elem: String = h.elem
	var fallen := health == 0.0
	var foot := Vector2(size.x / 2, size.y - (26.0 if health >= 0.0 else 12.0))
	var rx := size.x * 0.42
	# The pool of light, then the tier ring round it.
	draw_set_transform(foot, 0, Vector2(1, 0.26))
	if not fallen:
		for i in 8:
			var k := 1.0 - i / 8.0
			draw_circle(Vector2.ZERO, rx * k, Color(Forge.ELEM[elem], 0.05))
	if stars == 4 and not fallen:
		var pal: Array = Rim.elem(elem)
		var n := 64
		for i in n:
			var a0 := TAU * i / n
			var k := fposmod(float(i) / n * pal.size() - _t * 0.6, float(pal.size()))
			var col: Color = (pal[int(k) % pal.size()] as Color).lerp(pal[(int(k) + 1) % pal.size()], k - floorf(k))
			draw_arc(Vector2.ZERO, rx, a0, a0 + TAU / n + 0.01, 3, col, 4.0, true)
	else:
		draw_arc(Vector2.ZERO, rx, 0, TAU, 64, Color(Data.TIER_COLORS[stars], 0.35 if fallen else 0.8), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	var height := Figure.height(spr, size.y * tall)
	Figure.draw(self, spr, foot, height, {"t": _t, "breathe": 0.0 if fallen else 1.0, "flip": true,
		"modulate": Color(0.45, 0.42, 0.4, 0.55) if fallen else Color.WHITE})
	if health >= 0.0:
		var bar := Rect2(foot.x - rx * 0.8, foot.y + 12, rx * 1.6, 6)
		draw_rect(bar, Color(0, 0, 0, 0.85))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * health, bar.size.y)), BattleTile.HP_LOW if health < 0.35 else Forge.GAIN)
