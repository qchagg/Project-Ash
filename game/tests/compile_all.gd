extends SceneTree
## Compiles every script in core/ and ui/, so a parse error in a screen fails the checks rather than the browser.


func _init() -> void:
	var bad := []
	var n := 0
	for dir in ["res://core", "res://ui"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			n += 1
			var s: GDScript = load("%s/%s" % [dir, f])
			if s == null or not s.can_instantiate():
				bad.append(f)
	print("[compile] %d/%d scripts compile%s" % [n - bad.size(), n, "" if bad.is_empty() else ": broken " + ", ".join(bad)])
	quit(1 if bad else 0)
