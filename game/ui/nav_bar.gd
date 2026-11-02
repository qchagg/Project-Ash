class_name NavBar
extends RefCounted
## The places of the game as a row of small, quiet links along the foot, the same on every screen and in both layouts, so
## the screen's own feature keeps the room. The place you are in is lit, with a small diamond under it. Home is the menu
## itself; the app lays this row along the foot of every other screen with no band behind it.

## The places: the link's words and their App.show_tab key.
const PLACES := [["home", "menu"], ["road", "expedition"], ["heroes", "heroes"], ["party", "party"], ["caravan", "town"], ["graces", "graces"], ["travel log", "log"], ["archive", "archive"]]
const LINK_H := 40.0
const GAP_WIDE := 48
const GAP_PHONE := 26
const TEXT := 16


## The strip the app puts under a screen.
static func make(app: App, screen: Control) -> Control:
	var wide := Forge.wide()
	var bar := PanelContainer.new()
	var side := Screen.SIDE.x if wide else 30.0
	bar.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.0), Color.TRANSPARENT, 0, Vector4(side, 4, side, 10)))
	bar.add_child(links(app, place_of(screen)))
	return bar


## The row itself. `here` is the App.show_tab key of the place you are in.
static func links(app: App, here: String) -> Control:
	var wide := Forge.wide()
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_BEGIN if wide else FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", GAP_WIDE if wide else GAP_PHONE)
	for place in PLACES:
		var b := Forge.link(place[0], "", TEXT)
		b.custom_minimum_size.y = LINK_H
		# A soft dark edge, so the row reads over any painting without a band behind it.
		b.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.85))
		b.add_theme_constant_override("outline_size", 5)
		if place[1] == here:
			for k in ["font_color", "font_hover_color"]:
				b.add_theme_color_override(k, Forge.GOLD_LIGHT)
			b.draw.connect(func(): Forge.diamond(b, Vector2(b.size.x / 2.0, b.size.y - 3.0), 3, Forge.GOLD))
		else:
			b.add_theme_color_override("font_color", Color(Forge.PARCHMENT, 0.62))
			b.add_theme_color_override("font_hover_color", Forge.GOLD_LIGHT)
			b.pressed.connect(app.show_tab.bind(place[1]))
		row.add_child(b)
	return row


## Which place a screen belongs to. Some sit inside another's tab, but each has its own link.
static func place_of(screen: Control) -> String:
	if screen is SquadScreen:
		return "party"
	if screen is CodexScreen:
		return "archive"
	if screen is TravelLog:
		return "log"
	return screen.get("tab")
