extends Node

func is_valid():
	var state_labels = get_tree().get_nodes_in_group('state_label')
	var n = len(state_labels)
	
	if n == 0:
		Signals.popup.emit('No states found.')
		return false
	
	var has_start = false
	var has_final = false
	var are_transitions_valid = true
	
	for state_label in state_labels:
		if state_label.node.is_start:
			has_start = true
		if state_label.node.is_final:
			has_final = true
		
		if has_start and has_final:
			break
	
	var transition_labels = get_tree().get_nodes_in_group('transition_label')
	for transition_label in transition_labels:
		if transition_label.input.get_text().is_empty():
			are_transitions_valid = false
			break
	
	var text = ''
	if not has_start:
		text += 'No start state found.\n'
	
	if not has_final:
		text += 'No final state found.\n'
	
	if not are_transitions_valid:
		text += 'Empty transitions are not allowed.\n'
	
	if has_start and has_final and len(get_test_strings()) == 0:
		text += 'No path from start state to final state.'
	
	if text.is_empty():
		return true
	else:
		Signals.popup.emit(text)
		return false

func get_state_label_by_name(node_name):
	var state_labels = get_tree().get_nodes_in_group('state_label')
	return state_labels.filter(func(state_label): return state_label.node.get_name() == node_name)[0]

func serialize_fa():
	var fa = {}
	var start = 0
	
	for state_label in get_tree().get_nodes_in_group('state_label'):
		var state_node = state_label.node
		
		if state_node.is_start:
			start = state_node.id
		
		fa[state_node.id] = {
			'is_final': state_node.is_final,
			'transitions': []
		}
	
	for transition in get_tree().get_nodes_in_group('transition_label'):
		var from_id = transition.from_state_label.node.id
		var to_id = transition.to_state_label.node.id
		var input = transition.get_input()
		fa[from_id]['transitions'].append({
			'to': to_id,
			'input': input
		})
	
	return [start, fa]

func generate_test_strings(start, fa):
	var keys = len(fa.keys())
	var max_depth = keys * 2
	var strings = []
	
	_generate_test_strings(start, fa, 0, max_depth, '', strings)
	
	return strings

func _generate_test_strings(start, fa, depth, max_depth, current, strings):
	if depth < max_depth:
		depth += 1
		
		if fa[start]['is_final']:
			strings.append(current)
		
		var transitions = fa[start]['transitions']
		
		for transition in transitions:
			var to = transition['to']
			var input = transition['input']
			var new_current = current + input
			_generate_test_strings(to, fa, depth, max_depth, new_current, strings)
		

func test(start, fa, input):
	var current_state = start
	var path = [start]

	for c in input:
		var flag = false
		for transition in fa[current_state]['transitions']:
			if transition['input'] == c:
				current_state = transition['to']
				path.append(current_state)
				flag = true
				break  
		
		if not flag:
			return [false, path]
		
		if current_state not in fa:
			return [false, path]

	if fa[current_state]['is_final']:
		return [true, path]
	else:
		return [false, path]

func evaluate(inputs):
	var serialized = serialize_fa()
	var start = serialized[0]
	var fa = serialized[1]
	var results = []
	
	for input in inputs:
		results.append(test(start, fa, input))
	
	return results

func get_test_strings():
	var serialized = serialize_fa()
	var start = serialized[0]
	var fa = serialized[1]
	var strings = generate_test_strings(start, fa)
	var unique_strings = []
	
	for string in strings:
		if not unique_strings.has(string):
			unique_strings.append(string)
	
	unique_strings.sort_custom(sort_strings)
	
	if len(unique_strings) > 0:
		if len(unique_strings[0]) == 0:
			unique_strings[0] = 'ε'
	
	return unique_strings

func sort_strings(a, b):
	if len(a) == len(b):
		return a.naturalnocasecmp_to(b) < 0
	else:
		return len(a) < len(b)
