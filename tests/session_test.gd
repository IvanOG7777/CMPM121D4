extends "res://tests/test_case.gd"


func test_a_tick_moves_the_dragon_head() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.turn(Vector2i.RIGHT)
	session.tick()

	assert_eq(session.dragon.body[0], Vector2i(6, 5))


func test_the_dragon_starts_on_open_floor_inside_a_wall() -> void:
	var session := Session.new(Vector2i(10, 10))

	assert_true(session.board.is_solid(Vector2i(0, 0)))
	assert_true(not session.board.is_solid(session.dragon.body[0]))


func test_eating_food_grows_dragon() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.food = Vector2i(6, 5)

	session.turn(Vector2i.RIGHT)
	session.tick()

	assert_eq(session.dragon.body.size(), 5)


func test_eating_food_increases_score() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.food = Vector2i(6, 5)

	session.turn(Vector2i.RIGHT)
	session.tick()

	assert_eq(session.score, 1)


func test_food_never_spawns_on_body() -> void:
	var session := Session.new(Vector2i(10, 10))

	for i in 100:
		session.spawn_food()

		assert_true(not session.food in session.dragon.body)


func test_food_never_spawns_on_wall() -> void:
	var session := Session.new(Vector2i(10, 10))

	for i in 100:
		session.spawn_food()

		assert_true(not session.board.is_solid(session.food))


func test_seeded_food_is_deterministic() -> void:
	var first := Session.new(Vector2i(10, 10), 123)
	var second := Session.new(Vector2i(10, 10), 123)

	for i in 20:
		assert_eq(first.food, second.food)

		first.spawn_food()
		second.spawn_food()


func test_wall_collision_ends_run() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.dragon.body = [
		Vector2i(8, 5),
		Vector2i(7, 5),
		Vector2i(6, 5),
		Vector2i(5, 5),
	]

	session.food = Vector2i(2, 2)

	session.turn(Vector2i.RIGHT)
	session.tick()

	assert_true(session.game_over)


func test_body_collision_ends_run() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.dragon.body = [
		Vector2i(3, 3),
		Vector2i(3, 4),
		Vector2i(2, 4),
		Vector2i(2, 3),
		Vector2i(2, 2),
	]

	session.dragon.heading = Vector2i.UP
	session.food = Vector2i(7, 7)

	session.turn(Vector2i.LEFT)
	session.tick()

	assert_true(session.game_over)


func test_entering_vacating_tail_is_safe() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.dragon.body = [
		Vector2i(3, 3),
		Vector2i(3, 4),
		Vector2i(2, 4),
		Vector2i(2, 3),
	]

	session.dragon.heading = Vector2i.UP
	session.food = Vector2i(7, 7)

	session.turn(Vector2i.LEFT)
	session.tick()

	assert_true(not session.game_over)
	assert_eq(session.dragon.body[0], Vector2i(2, 3))
	assert_eq(session.dragon.body.size(), 4)


func test_waits_for_first_arrow_key() -> void:
	var session := Session.new(Vector2i(10, 10))
	var original := session.dragon.body.duplicate()

	for i in 10:
		session.tick()

	assert_eq(session.dragon.body, original)
	assert_true(not session.started)


func test_does_not_move_after_crash() -> void:
	var session := Session.new(Vector2i(10, 10))

	session.turn(Vector2i.RIGHT)
	session.finish_run()

	var original := session.dragon.body.duplicate()

	for i in 10:
		session.tick()

	assert_eq(session.dragon.body, original)
