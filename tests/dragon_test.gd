extends "res://tests/test_case.gd"


func test_moves_one_cell_per_tick() -> void:
	var dragon := Dragon.new(Vector2i(10, 10), 3)

	dragon.tick()

	assert_eq(dragon.body, [Vector2i(6, 5), Vector2i(5, 5), Vector2i(4, 5)])


func test_reversing_into_the_neck_is_ignored() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))

	dragon.turn(Vector2i.LEFT)
	dragon.tick()

	assert_eq(dragon.heading, Vector2i.RIGHT)


func test_two_quick_turns_apply_on_successive_ticks() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))

	dragon.turn(Vector2i.UP)
	dragon.turn(Vector2i.LEFT)

	dragon.tick()
	assert_eq(dragon.heading, Vector2i.UP)

	dragon.tick()
	assert_eq(dragon.heading, Vector2i.LEFT)


func test_does_not_wrap_at_the_edge() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))

	for i in 5:
		dragon.tick()

	assert_eq(dragon.body[0], Vector2i(10, 5))


func test_growing_retains_the_tail() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))

	var old_tail: Vector2i = dragon.body.back()

	dragon.tick(true)

	assert_eq(dragon.body.size(), 5)
	assert_eq(dragon.body.back(), old_tail)


func test_normal_movement_preserves_length() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))

	dragon.tick(true)
	dragon.tick()

	assert_eq(dragon.body.size(), 5)


func test_next_head_does_not_move_dragon() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	var original := dragon.body.duplicate()

	dragon.turn(Vector2i.UP)

	assert_eq(dragon.next_head(), Vector2i(5, 4))
	assert_eq(dragon.body, original)

	dragon.tick()

	assert_eq(dragon.body[0], Vector2i(5, 4))
