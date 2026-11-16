extends SceneTree
## Preview / export generated bubble levels.
##
##   godot --headless -s tools/bubble_levels.gd                 # summary of levels 1-12
##   godot --headless -s tools/bubble_levels.gd -- --export 20  # writes data/levels/bubbles_generated.json

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var export_n := 0
	var i := args.find("--export")
	if i >= 0 and i + 1 < args.size():
		export_n = int(args[i + 1])
	if export_n > 0:
		var levels := []
		for n in range(1, export_n + 1):
			levels.append(BubbleLevelGenerator.generate(n))
		var f := FileAccess.open("res://data/levels/bubbles_generated.json", FileAccess.WRITE)
		f.store_string(JSON.stringify({"levels": levels}, "  "))
		print("Wrote %d levels to data/levels/bubbles_generated.json" % export_n)
	else:
		print("level | goal | on screen | radius | speed px/s | gap s | colours")
		for n in range(1, 13):
			var p := BubbleLevelGenerator.params(n)
			print("%5d | %4d | %9d | %6.0f | %10.0f | %5.2f | %d" % [n, p.goal, p.max_on_screen, p.radius, p.speed, p.gap, p.colors])
		# Determinism check
		var a := JSON.stringify(BubbleLevelGenerator.generate(3))
		var b := JSON.stringify(BubbleLevelGenerator.generate(3))
		print("deterministic: ", a == b)
	quit()
