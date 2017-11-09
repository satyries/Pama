extends Node

var menu = false

const public = true

var locales = ["en","es","de","it","ja","ko"]

var models = {"nymph_base":"res://sources/characters/nymph.tscn", "satyr_base":"res://sources/characters/nymph.tscn"}

var skin_nymph = {"default":"res://sources/characters/nymph.tscn", "nymph_extra":"res://noneyet"}
var skin_satyr = {"default":"res://sources/characters/satyr.tscn", "satyr_extra":"res://noneyet"}

#tools
var ms_updater
#var active_tool = null


func hardfix_bugs():#small annoying issues fixed
	get_node("world/sun").set_rotation_deg(Vector3(-35.5,179.4,30))#weird problem Godot have, probably fixed in future
	

func activate_tool(where=null,what=null):
#The tool is added as child to the node who need be updated
#The tool contact the masterservernode (MSn) node with the request the parent need
#MSn gives the result (server list) to the tool
#The tool, child of node who need update, set its parent as per its given task
	if where == null:
		return
	if gamestate.active_tool != null:#there can be only one tool active: cleanup
		gamestate.ms.cancel_request()
		gamestate.ms.currentTask = gamestate.ms.TASK_NONE
		gamestate.active_tool.die()

	if what == "nymph_server_request":#request come from /lobby/ny_select
		gamestate.active_tool = ms_updater.instance()
		gamestate.active_tool.employer = where#we know it's /lobby/ny_select, but its safer if the node itself told us
		gamestate.active_tool.task = gamestate.active_tool.idx_task["nymph_request"]
		where.add_child(gamestate.active_tool)
	elif what == "main_debug":
		gamestate.active_tool = ms_updater.instance()
		gamestate.active_tool.employer = self
		gamestate.active_tool.task = gamestate.active_tool.idx_task["satyr_register"]
		where.add_child(gamestate.active_tool)



func _ready():
	hardfix_bugs()#hopefully we'll remove this
	return
	if public and !OS.get_locale().begins_with("en"):
		print("not english")
		gamestate.run_alert(1, "SYS_WARN_TRANSLATION")



func _enter_tree():
#	Engine.set_target_fps(13)
#	var lang = OS.get_locale()
#	for i in locales:
#		if lang.begins_with(i):
#			TranslationServer.set_locale(i)
	TranslationServer.set_locale("en")
	ms_updater = preload("res://system/tools/MS_updater.tscn")
	
#	TranslationServer.set_locale("en")
	randomize()
	get_node("gui").add_child(load("res://ui/lobby.tscn").instance())
	gamestate.main = self
	gamestate.gui = get_node("gui")
	gamestate.world = get_node("world")
	gamestate.roster = get_node("world/roster")

	if public:

		gamestate.activeworld = load("res://draft/temptst/publicmap.tscn").instance()
	else:
#		Engine.set_target_fps(13)
		gamestate.activeworld = load("res://draft/temptst/publicmap.tscn").instance()
#		gamestate.activeworld = load("res://draft/map.tscn").instance()
	gamestate.world.add_child(gamestate.activeworld)
#	gamestate.activeworld = get_node("world").get_child(0)


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

		if (ie.scancode == KEY_F5):
			print("masterservr")
			get_node("masterServer").register_server(00, "satyr")
		if (ie.scancode == KEY_F6):
			get_node("masterServer").retrieve_server()
			print("debug")
		if (ie.scancode == KEY_F7):
			activate_tool(self,"main_debug")
		if (ie.scancode == KEY_F9):
			if get_tree().is_network_server():
				var p = gamestate.roster.get_node("1")
				p.set_status("stunned", "")
				p.anim_head("stunned")
				p.anim_body("crash")
				p.camera.cinematic_request("stun")
			



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
