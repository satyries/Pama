extends Node

var menu = false

var locales = ["en","es","de","it","ja","ko"]

var models = {"nymph_base":"res://sources/characters/nymph.tscn", "satyr_base":"res://sources/characters/nymph.tscn"}

var skin_nymph = {"default":"res://sources/characters/nymph.tscn", "nymph_extra":"res://noneyet"}
var skin_satyr = {"default":"res://sources/characters/satyr.tscn", "satyr_extra":"res://noneyet"}

func _enter_tree():
#	Engine.set_target_fps(15)
	TranslationServer.set_locale("en")
	randomize()
	get_node("gui").add_child(load("res://ui/lobby.tscn").instance())
	gamestate.main = self
	gamestate.gui = get_node("gui")
	gamestate.world = get_node("world")
	gamestate.activeworld = get_node("world").get_child(0)
	gamestate.roster = get_node("world/roster")
	set_process_input(true)


func _input(ie):
	if !ie.is_class("InputEventKey"):
		return

	if ie.is_pressed():
		if (ie.scancode == KEY_ESCAPE):
			if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				menu = true
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				menu = false
		if (ie.scancode == KEY_F1):
			OS.set_window_fullscreen(!OS.is_window_fullscreen())
		if (ie.scancode == KEY_F2):
			OS.set_window_maximized(!OS.is_window_maximized())
		if (ie.scancode == KEY_F3):
#			rpc_id
#			gamestate.respawn_request()
			gamestate.respawn()

		if (ie.scancode == KEY_F4):
			switch_locale()

func respawn_button():
	if is_network_master():
		gamestate.respawn_request()

func switch_locale():
	var locale = TranslationServer.get_locale()
	if locale == locales.back():
		TranslationServer.set_locale(locales.front())
		return
	for i in range(locales.size()):
		if locale == locales[i]:
			TranslationServer.set_locale(locales[i+1])
#			return
#	TranslationServer.set_locale("en")
#	print(locales.back())
#	var size =locales.size()
#	set_locale(value)Getter: get_locale()
#	for i in locales:
#		print(locales[i])
