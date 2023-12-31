#This state machine is a GDscript port of SnowState by Sohom Sahaun.
#SnowState is available at https://github.com/sohomsahaun/SnowState
#under the MIT License:
#
#MIT License
#
#Copyright (c) 2020 Sohom Sahaun
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

class_name LMSM extends Resource

#region LMSM Inner Classes
class State:
	var __name: String
	var __events: Array[Event]
	func _init(_name: String) -> void:
		__name = _name

	func add_event(_event: String, _func: Callable, _defined: LMSM.EVENT = LMSM.EVENT.DEFAULT) -> void:
		__events.push_back(Event.new(_event, _defined, _func))

	func set_event(_event: String, _func: Callable, _defined: LMSM.EVENT = LMSM.EVENT.DEFINED) -> void:
		var ev: Event = __get_event(_event)
		ev.__func = _func
		ev.__exists = _defined
		
	func __get_event(_name: String) -> Event:
		for _event: Event in __events:
			if _event.__name == _name:
				return _event
		return null
	
	func __has_event(_name: String) -> bool:
		for _event: Event in __events:
			if _event.__name == _name:
				return true
		return false
		
	func event(_name: String) -> Event:
			return __get_event(_name)

class Event:
	var __name: String
	var __exists: LMSM.EVENT
	var __func: Callable

	func _init(_name: String, _exists: LMSM.EVENT = LMSM.EVENT.DEFAULT, _function: Callable = __default_event_function) -> void:
		__name = _name
		__exists = _exists
		__func = _function
	
	func __default_event_function() -> void:
		pass

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
const warn_state_already_defined: String = "State '%s' has been defined already. This definition will do nothing."
const warn_state_parent_dne: String = "State '%s' has no parent"

const error_state_name_invalid: String = "State name '%s' is invalid. (Cannot be blank, '=', or '*')"
const error_state_dne: String = "State '%s' is not defined"
#endregion

#region LMSM Constants
enum EVENT {
	NOT_DEFINED = 0,
	DEFINED = 1,
	DEFAULT = 2,
	INHERITED = 4
}

enum TRIGGER {
	NOT_DEFINED = 0,
	DEFINED = 1,
	INHERITED = 2,
	INVALID = 4
}

const WILDCARD_TRANSITION_NAME: String = "*"
const REFLEXIVE_TRANSITION_NAME: String = "="
#endregion

var __owner: Object
var __states: Array[State]
var __events: Array[String] = ["enter", "step", "leave"]
var __curr_event: String
var __transitions: Dictionary
var __wild_transitions: Dictionary
var __parent: Dictionary
var __child_stack: Array[String]
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

func event(_name: String, _args: Array[Variant] = []) -> void:
	assert(__events.has(_name), "No event with name '%s' has been defined" % _name)
	__execute(_name, _args)
	
func enter(_args: Array[Variant] = []) -> void:
	__state_start_time = __get_current_time()
	__execute("enter", _args)

func leave(_args: Array[Variant] = []) -> void:
	__execute("leave", _args)
#endregion

#region States and Events
func add(_name: String, _events: Dictionary) -> void:
	assert(__state_name_valid(_name), error_state_name_invalid % _name)
	if __state_is_defined(_name):
		print("[LMSM]:", warn_state_already_defined % _name)
		return
	__add(_name, _events, false)

func add_child(_parent: String, _name: String, _events: Dictionary) -> void:
	assert(__state_name_valid(_name), error_state_name_invalid % _name)
	assert(__state_is_defined(_parent), error_state_dne % _parent)
	__parent[_name] = _parent
	__add(_name, _events, true)

func inherit(_args: Array[Variant] = []) -> void:
	var _state: String = __history[0]
	if !__parent.has(_state):
		print(warn_state_parent_dne % _state)
		return
	
	__child_stack.push_front(_state)
	_state = __parent[_state]
	__history[0] = _state
	__execute(__curr_event, _args)
	if __child_stack.size() > 0:
		__history[0] = __child_stack.pop_front()

func __add(_name: String, _events: Dictionary, _has_parent: bool) -> void:
	__update_fsm_events(_events)
	var _state: State = __get_state_by_name(_name)
	if _state == null:
		_state = State.new(_name)
		for _event: String in __events:
			if !_events.has(_event):
				_state.add_event(_event, __default_func, LMSM.EVENT.DEFAULT)
			else:
				_state.add_event(_event, _events[_event], LMSM.EVENT.DEFINED)
	__update_all_state_events()
	__states.push_back(_state)
	
	if _has_parent:
		var _parent: State = __get_state_by_name(__parent[_name])
		for _event: Event in _parent.__events:
			if _state.__get_event(_event.__name).__exists == LMSM.EVENT.DEFINED:
				continue
			var _exists: LMSM.EVENT = EVENT.NOT_DEFINED
			match _event.__exists:
				EVENT.DEFINED: _exists = EVENT.INHERITED
				EVENT.INHERITED: _exists = EVENT.INHERITED
				EVENT.DEFAULT: _exists = EVENT.DEFAULT
			_state.set_event(_event.__name, _event.__func, _exists)
	if _name == __init_state:
		enter()
	
func __execute(_event: String, _args: Array[Variant], _state: State = null) -> void:
	__curr_event = _event
	if _state == null:
		_state = __get_current_state()
	_state.__get_event(_event).__func.callv(_args)

func __get_current_time() -> int:
	return Time.get_ticks_usec()

func __get_current_state() -> State:
	return __get_state_by_name(__history[0])

func __get_state_by_name(_name: String) -> State:
	for _state: State in __states:
		if _state.__name == _name:
			return _state
	return null

func __state_is_defined(_name: String) -> bool:
	if _name == REFLEXIVE_TRANSITION_NAME || _name == WILDCARD_TRANSITION_NAME:
		return true
	for _state: State in __states:
		if _name == _state.__name:
			return true
	return false
	
func __update_fsm_events(_events: Dictionary) -> void:
	for _event: String in _events.keys():
		if !__events.has(_event):
			__events.push_back(_event)

func __update_all_state_events() -> void:
	for _state: State in __states:
		for _event: String in __events:
			if !_state.__has_event(_event):
				_state.add_event(_event, __default_func, LMSM.EVENT.DEFAULT)
	
func __state_name_valid(_name: String) -> bool:
	for __name: String in __invalid_state_names:
		if _name == __name:
			return false
	return true

func __history_add(_name: String) -> void:
	__history.push_front(_name)
	__history.resize(__history_max_size)
#endregion

#region Transitions
func add_transition(_name: String, _source: Array[String], _dest: String, _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> void:
	assert(__transition_name_valid(_name), "Transition must have a non-blank name.")
	assert(_dest != WILDCARD_TRANSITION_NAME, "Destination state cannot be wildcard transition name")
	assert(_dest != "", "Destination state cannot be blank")
	assert(__state_is_defined(_dest))
	for __source: String in _source:
		assert(__source != "", "Destination state cannot be blank")
		assert(__source != REFLEXIVE_TRANSITION_NAME, "Source state cannot be reflexive transition name")
		assert(__state_is_defined(__source))
		var transition: Transition = Transition.new(_name, __source, _dest, _condition, TRIGGER.DEFINED, _leave, _enter)
		__add_transition(transition)

func add_wildcard_transition(_name: String, _dest: String, _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> void:
	add_transition(_name, [WILDCARD_TRANSITION_NAME], _dest, _condition, _leave, _enter)

func add_reflexive_transition(_name: String, _source: Array[String], _condition: Callable = func() -> bool: return true, _leave: Callable = leave, _enter: Callable = enter) -> void:
	add_transition(_name, _source, REFLEXIVE_TRANSITION_NAME, _condition, _leave, _enter)

func transition_exists(_name: String, _source: String) -> TRIGGER:
	if !__transition_name_valid(_name):
		print("[LMSM] ", "Transition name: '_name' is not valid" % _name)
		return TRIGGER.INVALID
		
	return __transition_exists(_name, _source)

func trigger(_name: String, _args: Array = []) -> bool:
	assert(__transition_name_valid(_name), "Transition name: '_name' is not valid")
	
	var _current_state: String = __history[0]
	var _source: String = _current_state
	
	if __transition_exists(_name, _source) == TRIGGER.DEFINED:
		if __try_triggers(__transitions[_source][_name], _current_state, _args):
			return true
	
	if __transition_exists(_name, WILDCARD_TRANSITION_NAME) == TRIGGER.DEFINED:
		if __try_triggers(__wild_transitions[_name], _current_state, _args):
			return true
	
	while __parent.has(_source):
		_source = __parent[_source]
		if __transition_exists(_name, _source) == TRIGGER.DEFINED:
			if __try_triggers(__transitions[_source][_name], _current_state, _args):
				return true
				
	return false

func __try_triggers(_transitions: Array[Transition], _source: String, _args: Array) -> bool:
	for _transition: Transition in _transitions:
		var _dest: String = _transition.to
		if _dest == REFLEXIVE_TRANSITION_NAME:
			_dest = _source
		if _transition.condition.callv(_args):
			_transition.leave.callv(_args)
			__state_start_time = Time.get_ticks_usec()
			__history_add(_dest)
			_transition.enter.callv(_args)
			return true
	return false
	
func trigger_ext(_names: Array[String], _args: Array) -> bool:
	for _name: String in _names:
		return trigger(_name, _args)
	return false
	
func __transition_exists(_name: String, _source: String) -> TRIGGER:
	if _source == WILDCARD_TRANSITION_NAME:
		if __wild_transitions.has(_source):
			return TRIGGER.DEFINED
	if __transitions.has(_source):
		var temp_dict: Dictionary = __transitions[_source]
		if temp_dict.has(_name):
			return TRIGGER.DEFINED
	while __parent.has(_source):
		_source = __parent[_source]
		if __transitions.has(_source):
			var temp_dict: Dictionary = __transitions[_source]
			if temp_dict.has(_name):
				return TRIGGER.INHERITED
	return TRIGGER.NOT_DEFINED
	
func __add_transition(_transition: Transition) -> void:
	if _transition.from == WILDCARD_TRANSITION_NAME:
		if !__wild_transitions.has(_transition.name):
			var temp_array: Array[Transition] = []
			__wild_transitions[_transition.name] = temp_array
		var wild_transition_array: Array[Transition] = __wild_transitions[_transition.name]
		wild_transition_array.push_back(_transition)
		return
	if !__transitions.has(_transition.from):
		__transitions[_transition.from] = {}
	var transition_dict: Dictionary = __transitions[_transition.from]
	if !transition_dict.has(_transition.name):
		var temp_array: Array[Transition] = []
		transition_dict[_transition.name] = temp_array
	var transition_array: Array[Transition] = transition_dict[_transition.name]
	transition_array.push_back(_transition)

func __transition_name_valid(_name: String) -> bool:
	if _name == "":
		return false
	return true
#endregion
