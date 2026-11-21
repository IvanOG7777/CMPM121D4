## Engine adapter: keeps the clock, passes keys to the Session, and draws what it holds.
## It never decides rules: those live in core/session.gd.
extends Node3D

const GRID := Vector2i(12, 12)  # your call: bigger grids make the dragon feel finer
const TICK_SECONDS := 0.1
const CAMERA_OFFSET := Vector3(0, 11, 7.5)  # above and behind the head
const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

var session: Session
var meshes := {}  # kit piece name -> Mesh, shared by everything that shows it (Flyweight)
var segments: Array[MeshInstance3D] = []

var camera := Camera3D.new()
var stage: Stage
var food_instance := MeshInstance3D.new()

var level_paths := PackedStringArray()
var level_index: int = 0
var level_name: String = ""

var hud := CanvasLayer.new()
var score_label := Label.new()
var status_label := Label.new()
var level_label := Label.new()

var _clock := 0.0


func _ready() -> void:
	meshes = Stage.load_kit()
	level_paths = Level.discover()

	add_child(camera)

	food_instance.mesh = meshes["food"]
	add_child(food_instance)

	_build_hud()
	_start_level()


func _start_level() -> void:
	if stage != null:
		remove_child(stage)
		stage.queue_free()

	var level: Level = null

	if not level_paths.is_empty():
		level = Level.load_level(level_paths[level_index])

	if level == null:
		session = Session.new(GRID, 121)
		level_name = "Default Level"
	else:
		session = Session.new(level.board.size, 121, level.board)
		level_name = level.name

	stage = Stage.new(session.board.tiles, meshes)
	add_child(stage)

	_clock = 0.0

	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET
	camera.look_at(camera.position - CAMERA_OFFSET)

	_draw_dragon()
	_draw_food()
	_update_hud()


func _next_level() -> void:
	if level_paths.is_empty():
		return

	level_index = (level_index + 1) % level_paths.size()
	_start_level()


## Input arrives as events, so even a tap shorter than one frame is never missed.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				_start_level()
				return

			if event.keycode == KEY_N:
				_next_level()
				return

	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			session.turn(DIRECTIONS[action])


func _process(delta: float) -> void:
	_clock += delta

	while _clock >= TICK_SECONDS:
		_clock -= TICK_SECONDS

		session.tick()

		_draw_dragon()
		_draw_food()
		_update_hud()

	_follow(delta)


## Ease toward the head each frame, so the camera glides while the dragon steps.
func _follow(delta: float) -> void:
	var target := _center(session.dragon.body[0]) + CAMERA_OFFSET

	camera.position = camera.position.lerp(target, 1 - exp(-3 * delta))
	camera.look_at(camera.position - CAMERA_OFFSET)


func _draw_dragon() -> void:
	var body := session.dragon.body

	while segments.size() < body.size():
		var segment := MeshInstance3D.new()
		add_child(segment)
		segments.append(segment)

	var placed := Kit.layout(body)

	for i in segments.size():
		var segment := segments[i]

		segment.visible = i < body.size()

		if not segment.visible:
			continue

		var cell := body[i]

		segment.mesh = meshes[Kit.Piece.keys()[placed[i][0]].to_lower()]
		segment.position = _center(cell)
		segment.rotation.y = placed[i][1] * PI / 2


func _draw_food() -> void:
	food_instance.visible = session.food != Session.NO_FOOD

	if food_instance.visible:
		food_instance.position = _center(session.food)


func _build_hud() -> void:
	add_child(hud)

	level_label.position = Vector2(20, 15)
	level_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(level_label)

	score_label.position = Vector2(20, 50)
	score_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(score_label)

	status_label.position = Vector2(20, 85)
	status_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(status_label)


func _update_hud() -> void:
	level_label.text = "Level: " + level_name
	score_label.text = "Score: %d" % session.score

	if session.won:
		status_label.text = "You win! Press R to restart or N for next level."
	elif session.game_over:
		status_label.text = "Game Over! Press R to restart or N for next level."
	elif not session.started:
		status_label.text = "Press an arrow key to start. N: next level."
	else:
		status_label.text = "Arrow keys: move | R: restart | N: next level"


func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)
