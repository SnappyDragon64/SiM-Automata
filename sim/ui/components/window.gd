extends GraphEdit

var state_preload := preload('res://sim/element/state.tscn')
var current_state = 0
var animation_active = false

func _ready():
	get_zoom_hbox().set_visible(false)
	Signals.grid.connect(_on_grid)
	Signals.redraw_transitions.connect(_on_redraw_transitions)
	Signals.state_label_deleted.connect(_on_state_label_deleted)
	Signals.animation_started.connect(_on_animation_started)
	Signals.animation_exited.connect(_on_animation_exited)


func _on_connection_request(from_node, from_port, to_node, to_port):
	if not animation_active:
		connect_node(from_node, from_port, to_node, to_port)
		Signals.transition_created.emit(from_node, to_node)

func _on_grid(flag):
	set_use_snap(flag)

func _on_redraw_transitions():
	clear_connections()
	
	for transition in get_tree().get_nodes_in_group('transition_label'):
		if is_instance_valid(transition.from_state_label) and is_instance_valid(transition.to_state_label):
			var to_state = transition.to_state_label.node_name
			var from_state = transition.from_state_label.node_name
			
			connect_node(from_state, 0, to_state, 0)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Globals.CURSOR_MODE == Globals.CURSOR_MODES.CREATE:
				var state_instance = state_preload.instantiate()
				state_instance.set_position_offset(event.get_position())
				state_instance.id = current_state
				current_state += 1
				add_child(state_instance)

func _on_state_label_deleted():
	current_state -= 1

func _on_animation_started():
	animation_active = true
	set_mouse_filter(MOUSE_FILTER_IGNORE)

func _on_animation_exited():
	animation_active = false
	set_mouse_filter(MOUSE_FILTER_STOP)
