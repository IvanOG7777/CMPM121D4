extends "res://tests/test_case.gd"


func test_at_least_three_levels_exist() -> void:
	var paths := Level.discover()

	assert_true(paths.size() >= 3)


func test_all_levels_load() -> void:
	var paths := Level.discover()

	for path in paths:
		var level := Level.load_level(path)

		assert_true(level != null)


func test_all_levels_have_clear_start() -> void:
	for path in Level.discover():
		var level := Level.load_level(path)

		assert_true(level != null)

		if level == null:
			continue

		assert_true(level.has_clear_start())


func test_level_dimensions() -> void:
	for path in Level.discover():
		var level := Level.load_level(path)

		assert_true(level != null)

		if level == null:
			continue

		var content := FileAccess.get_file_as_string(path)
		var rows := content.replace("\r", "").strip_edges().split("\n")

		assert_eq(level.board.size, Vector2i(rows[0].length(), rows.size()))


func test_legend_translates_tiles() -> void:
	var paths := Level.discover()

	assert_true(not paths.is_empty())

	if paths.is_empty():
		return

	var level := Level.load_level(paths[0])

	assert_true(level != null)

	if level == null:
		return

	assert_eq(level.board.kind_at(Vector2i(0, 0)), "wall")
	assert_eq(level.board.kind_at(Vector2i(1, 1)), "floor")


func test_rejects_unknown_character() -> void:
	var level := Level.parse("####\n#X.#\n####")

	assert_eq(level, null)


func test_rejects_inconsistent_row_width() -> void:
	var level := Level.parse("####\n#.#\n####")

	assert_eq(level, null)


func test_rejects_empty_level() -> void:
	var level := Level.parse("")

	assert_eq(level, null)


func test_session_uses_loaded_board() -> void:
	var paths := Level.discover()

	if paths.is_empty():
		assert_true(false)
		return

	var level := Level.load_level(paths[0])

	if level == null:
		assert_true(false)
		return

	var session := Session.new(level.board.size, 121, level.board)

	assert_eq(session.board, level.board)
	assert_true(not session.board.is_solid(session.food))
