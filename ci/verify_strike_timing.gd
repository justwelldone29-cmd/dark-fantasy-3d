extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	main.get_node("Player").set_physics_process(false)
	var visual := main.get_node("Player/Visual")
	var contacts: Array[float] = []
	visual.attack_contact.connect(func(): contacts.append(visual.strike_length - visual.strike_remaining))
	visual.swing()
	var body_works := false
	for i in range(160):
		visual.animate_motion(1.0 / 120, 0.0)
		if visual.full_body_weight > .8: body_works = true
	if contacts.size() != 1 or absf(contacts[0] - visual.strike_length * visual.CONTACT_PHASE) > .02 or not body_works:
		push_error("Неверное время контакта, повторный урон или неподвижный корпус")
		quit(1)
		return
	visual.swing()
	visual.animate_motion(.1, 0)
	visual.set_equipped_weapon("steel_sword")
	visual.animate_motion(2, 0)
	if contacts.size() != 1:
		push_error("Смена оружия не отменила удар")
		quit(1)
		return
	print("STRIKE_CONTACT_ONCE_AT_PHASE_AND_FULL_BODY_OK")
	quit()
