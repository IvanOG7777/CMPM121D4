## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.

class_name Session
extends RefCounted

signal ate
signal crashed
signal completed

const NO_FOOD := Vector2i(-1, -1)

var board: Board
var dragon: Dragon

var food: Vector2i = NO_FOOD
var score: int = 0
var started: bool = false
var game_over: bool = false
var won: bool = false

var seed_value: int
var rng := RandomNumberGenerator.new()


## function that initalizes game
func _init(grid_size: Vector2i, game_seed: int = 121, level_board: Board = null) -> void:
	seed_value = game_seed
	rng.seed = seed_value

	if level_board == null:
		board = Board.bordered(grid_size)
	else:
		board = level_board

	dragon = Dragon.new(board.size)

	spawn_food()


## function that will spawn food in map
func spawn_food() -> void:
	var available: Array[Vector2i] = []

	for y in board.size.y:
		for x in board.size.x:
			var cell := Vector2i(x, y)

			## if on solid or snake body skip
			if board.is_solid(cell):
				continue

			if cell in dragon.body:
				continue

			available.append(cell)

	if available.is_empty():
		food = NO_FOOD
		game_over = true
		won = true
		completed.emit()
		return

	var index := rng.randi_range(0, available.size() - 1)
	food = available[index]


func turn(direction: Vector2i) -> void:
	if game_over:
		return

	started = true
	dragon.turn(direction)


func hits_body(cell: Vector2i, growing: bool) -> bool:
	var limit := dragon.body.size()

	if not growing:
		limit -= 1

	for i in limit:
		if dragon.body[i] == cell:
			return true

	return false


func finish_run() -> void:
	game_over = true
	crashed.emit()


## One step of the rules. TODO for D4: food, growth, and collisions with the dragon's
## own body and with solid tiles (board.is_solid). Each needs the dragon and something
## else, which is why they go here rather than in Dragon.tick.
func tick() -> void:
	if not started or game_over:
		return

	var next := dragon.next_head()
	var growing := next == food

	if board.is_solid(next):
		finish_run()
		return

	if hits_body(next, growing):
		finish_run()
		return

	dragon.tick(growing)

	if growing:
		score += 1
		ate.emit()
		spawn_food()
