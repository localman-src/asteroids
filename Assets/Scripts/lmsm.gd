class_name LMSM extends Resource

#region LMSM Inner Classes
class State:
	var __name: String
	var __events: Array[Event]
	func _init(_name: String) -> void:
		__name = _name

	func add(_event: String, _func: Callable, _defined: LMSM.EVENT = LMSM.EVENT.DEFAULT) -> State:
		__events.push_back(Event.new(_event, _defined, _func))
		return self

	func set_event(_event: String, _func: Callable) -> State:
		var ev: Event = __get_event(_event)
		ev.__func = _func
		ev.__exists = LMSM.EVENT.DEFINED
		return self
		
	func __get_event(_name: String) -> Event:
		for ev: Event in __events:
			if ev.__name == _name:
				return ev
		return null

	func event(_name: String) -> Event:
			return __get_event(_name)

class Event:
	var __name: String
	var __exists: LMSM.EVENT
	var __func: Callable

	func _init(_name: String, _exists: LMSM.EVENT = LMSM.EVENT.NOT_DEFINED, _function: Callable = func() -> void: return) -> void:
		__name = _name
		__exists = _exists
		__func = _function

class Transition:
	var name: String
	var from: String
	var to: String
	var condition: Callable
	var exists: LMSM.TRIGGER
	var leave: Callable
	var enter: Callable

	func _init(_name: String, _from: String, _to: String, _condition: Callable, _exists: LMSM.TRIGGER, _leave: Callable, _enter: Callable) -> void:
		name = _name
		from = _from
		to = _to
		condition = _condition
		exists = _exists
		leave = _leave
		enter = _enter
#endregion

#region LMSM Error Strings
const warn_state_already_defined: String = "State '%s' has been defined already. Replacing the previous definition"
const warn_state_parent_dne: String = "State '%s' has no parent"

const error_state_name_invalid: String = "State name '%s' is invalid. (Cannot be blank, '=', or '*')"
#endregion

enum EVENT {
	NOT_DEFINED = 0,
	DEFINED = 1,
	DEFAULT = 2,
	INHERITED = 4
}

enum TRIGGER {
	NOT_DEFINED = 0,
	DEFINED = 1
}

const WILDCARD_TRANSITION_NAME: String = "*"
const REFLEXIVE_TRANSITION_NAME: String = "="

var __owner: Object
var __states: Array[State]
var __events: Array[String] = ["enter", "step", "leave"]
var __curr_event: String
var __transitions: Array[Transition]
var __wild_transitions: Array[Transition]
var __parent: Dictionary
var __child_queue: Array[String]
var __init_state: String
var __exec_enter: bool
var __state_start_time: int
var __history: Array[String]
var __history_max_size: int = 2
var __invalid_state_names: Array[String]
var __default_func: Callable = func(_delta: float) -> void: return

func _init(_owner: Object, _init_state: String, _exec_enter: bool = true) -> void:
	__owner = _owner
	__init_state = _init_state
	__exec_enter = _exec_enter
	__invalid_state_names.push_back(REFLEXIVE_TRANSITION_NAME)
	__invalid_state_names.push_back(WILDCARD_TRANSITION_NAME)
	__invalid_state_names.push_back("")
	
	if __state_name_valid(__init_state):
		__history_add(__init_state)

#region Event Definitions
func enter(_args: Array[Variant] = []) -> void:
	__state_start_time = get_current_time()
	__execute("enter", _args)
	
func step(_args: Array[Variant] = []) -> void:
	__execute("step", _args)

func leave(_args: Array[Variant] = []) -> void:
	__execute("leave", _args)
#endregion

func add(_name: String, _events: Dictionary = {}) -> LMSM:
	if !__state_name_valid(_name):
		print("[LMSM] ", error_state_name_invalid % _name)
		return null
		
	if __state_is_defined(_name):
		print("[LMSM] ", warn_state_already_defined % _name)
		
	__add(_name, _events, false)
	return self

func add_child(_parent: String, _name: String, _events: Dictionary = {}) -> LMSM:
	if !__state_name_valid(_name):
		return null
	if !__state_name_valid(_parent):
		return null
	
	if __state_is_defined(_name):
		print("[LMSM] ", warn_state_already_defined % _name)
	
	__parent[_name] = _parent
	__add(_name, _events, true)
	return self
	
func __add(_name: String, _events: Dictionary, _has_parent: bool) -> void:
	var _state: State = state(_name)
	if _state == null && __state_name_valid(__init_state):
		_state = State.new(_name)
		for event: String in __events:
			if !_events.has(event):
				_state.add(event, __default_func)
			else:
				_state.add(event, _events[event], LMSM.EVENT.DEFINED)
		__states.push_back(_state)
	
	if _has_parent:
		var _parent: State = state(__parent[_name])
		for event: Event in _parent.__events:
			if _state.__get_event(event.__name).__exists == LMSM.EVENT.DEFINED:
				continue
			var _exists: LMSM.EVENT = EVENT.NOT_DEFINED
			match event.__exists:
				EVENT.DEFINED: _exists = EVENT.INHERITED
				EVENT.INHERITED: _exists = EVENT.INHERITED
				EVENT.DEFAULT: _exists = EVENT.DEFAULT
			
			_state.set_event(event.__name, event.__func)
		
	if _name == __init_state:
		enter()
	pass

func inherit() -> LMSM:
	var _state: String =__get_current_state()
	if !__parent.has(_state):
		print(warn_state_parent_dne % _state)
		return self
	
	__child_queue.push_front(_state)
	_state = __parent[_state]
	__history[0] = _state
	__execute(__curr_event)
	if __child_queue.size() > 0:
		__history[0] = __child_queue.pop_front()
	return self
		
func state(_name: String) -> State:
	for st: State in __states:
		if st.__name == _name:
			return st
	return null

func get_current_time() -> int:
	return Time.get_ticks_usec()
	
func __execute(_event: String, _args: Array[Variant] = []) -> void:
	__curr_event = _event
	state(__get_current_state()).event(_event).__func.callv(_args)
	
func __state_name_valid(_name: String) -> bool:
	for st: String in __invalid_state_names:
		if st == _name:
			return false
	return true

func __state_is_defined(_name: String) -> bool:
	for st: State in __states:
		if st.__name == _name:
			return true
	return false
	
func __history_add(_state: String) -> LMSM:
	__history.push_front(_state)
	__history.resize(__history_max_size)
	return self

func __get_current_state() -> String:
	if __history.size() > 0:
		return __history[0]
	return ""

#region Transitions
func add_transition(_name: String, _source: String, _dest: String, _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> LMSM:
	var transition: Transition = Transition.new(_name, _source, _dest, _condition, TRIGGER.DEFINED, _leave, _enter)
	if transition.from == WILDCARD_TRANSITION_NAME:
		__wild_transitions.push_back(transition)
		return self
	if __transition_exists(_name, _source):
		return self
	__transitions.push_back(transition)
	return self

func add_reflexive_transition(_name: String, _source: String, _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> LMSM:
	return add_transition(_name, _source, REFLEXIVE_TRANSITION_NAME, _condition, _leave, _enter)

func add_wildcard_transition(_name: String, _dest: String, _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> LMSM:
	return add_transition(_name, WILDCARD_TRANSITION_NAME, _dest, _condition, _leave, _enter)

func __transition_exists(_name: String, _source: String) -> bool:
	for transition: Transition in __transitions:
		if transition.name == _name && transition.from == _source:
			return true
	return false

func __wild_transition_exists(_name: String) -> bool:
	for transition: Transition in __wild_transitions:
		if transition.name == _name:
			return true
	return false
	
func __try_trigger(_transition: Transition, _source: String, _args: Array[Variant]) -> bool:
	var _dest: String = _transition.to
	if _dest == REFLEXIVE_TRANSITION_NAME:
		_dest = _source
	if _transition.condition.callv(_args):
		_transition.leave.callv(_args)
		__history_add(_dest)
		_transition.enter.callv(_args)
		return true
	return false

func __get_transition(_name: String, _source: String) -> Transition:
	for transition: Transition in __transitions:
		if transition.name == _name && transition.from == _source:
			return transition
	return null
func __get_wild_transition(_name: String) -> Transition:
	for transition: Transition in __wild_transitions:
		if transition.name == _name:
			return transition
	return null

func trigger(_name: String, _args: Array[Variant] = []) -> bool:
	var current_state: String = __get_current_state()
	if __transition_exists(_name, current_state):
		return __try_trigger(__get_transition(_name, current_state), current_state, _args)
	if __wild_transition_exists(_name):
		return __try_trigger(__get_wild_transition(_name), current_state, _args)
	return false
#endregion

