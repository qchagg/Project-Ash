class_name NavBar
extends RefCounted
## The places of the game as a row of plain links along the foot, the same on every screen and in both layouts. The place
## you are in is lit, with a small diamond under it. Home sets the row on its painting; the app gives every other screen a
## quiet strip for it.

## The places: the link's words and their App.show_tab key.
const PLACES := [["home", "menu"], ["road", "expedition"], ["heroes", "heroes"], ["party", "party"], ["caravan", "town"], ["graces", "graces"], ["travel log", "log"], ["archive", "archive"]]
const LINK_H := 44.0
const GAP_WIDE := 40
const GAP_PHONE := 26


## The strip the app puts under a screen.
static func make(app: App, screen: Control) -> Control:
	var wide := Forge.wide()
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Forge.flat(Forge.INK, Color.TRANSPARENT, 0, Vector4(56 if wide else 30, 8, 40 if wide else 30, 8)))
	bar.add_child(links(app, place_of(screen)))
	return bar


## The row itself. `here` is the App.show_tab key of the place you are in.
static func links(app: App, here: String) -> Control:
	var wide := Forge.wide()
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_BEGIN if wide else FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", GAP_WIDE if wide else GAP_PHONE)
	for place in PLACES:
		var b := Forge.link(place[0], "", 20)
		b.custom_minimum_size.y = LINK_H
		if place[1] == here:
			for k in ["font_color", "font_hover_color"]:
				b.add_theme_color_override(k, Forge.GOLD_LIGHT)
			b.draw.connect(func(): Forge.diamond(b, Vector2(b.size.x / 2.0, b.size.y - 2.0), 4, Forge.GOLD))
		else:
			b.add_theme_color_override("font_color", Forge.PARCHMENT)
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
