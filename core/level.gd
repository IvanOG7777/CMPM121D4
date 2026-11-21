class_name Level
extends RefCounted

const LEGEND := {
	".": "floor",
	"#": "wall",
}

const LEVEL_DIRECTORY := "res://levels/"

var name: String
var board: Board


static func discover() -> PackedStringArray:
	var paths := PackedStringArray()

	for file in DirAccess.get_files_at(LEVEL_DIRECTORY):
		if file.ends_with(".txt"):
			paths.append(LEVEL_DIRECTORY + file)

	paths.sort()
	return paths


static func load_level(path: String) -> Level:
	if not FileAccess.file_exists(path):
		return null

	var content := FileAccess.get_file_as_string(path)
	return parse(content, path.get_file().get_basename())


static func parse(content: String, level_name: String = "") -> Level:
	var text := content.replace("\r", "").strip_edges()

	if text.is_empty():
		return null

	var rows := text.split("\n")
	var width := rows[0].length()
	var height := rows.size()

	var level := Level.new()
	level.name = level_name
	level.board = Board.new()
	level.board.size = Vector2i(width, height)

	for y in height:
		if rows[y].length() != width:
			return null

		for x in width:
			var character := rows[y][x]

			if not LEGEND.has(character):
				return null

			level.board.tiles[Vector2i(x, y)] = LEGEND[character]

	if not level.has_clear_start():
		return null

	return level


func has_clear_start() -> bool:
	var dragon := Dragon.new(board.size)

	for cell in dragon.body:
		if board.is_solid(cell):
			return false

	return not board.is_solid(dragon.next_head())
