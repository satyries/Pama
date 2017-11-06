extends Control

var colorlist

var lobby_state = 0
const idx_state = {
			"idle"			:0,#no request, stop processing
			"sa_update_ms"	:1,#satyr is updating the ms
			"ny_get_list"	:2#nymph is getting the list
			}
var timeout = [0,10]

#nodes
var ny_select#main screen after nymph selection
var ny_srv_list#serverlist container for the nymph

var sa_select#main screen after satyr selection





func _enter_tree():
	colorlist = get_node("intro/colors")
	gamestate.gui_lobby = self
	get_node("intro").show()
	get_node("players").hide()
	get_node("connect").hide()
	get_node("ny_select").hide()
	get_viewport().connect("size_changed", self, "resize_window")


	ny_select = get_node("ny_select")
	ny_srv_list = get_node("ny_select/server_list/container/listing_core")




func resize_window():
	var size =get_viewport().size
	set_global_position(Vector2(0,0))
	rect_size = size





func _process(delta):
	if timeout[0] >= timeout[1]:
		run_lobby_request()
		timeout[0] = 0#reset timeout
	else:
		timeout[0] += 1*delta

	if lobby_state == idx_state["idle"]:#time to put at sleep this process
		timeout[0] = 0
		set_process(false)

func run_lobby_request():
	if lobby_state == idx_state["sa_update_ms"]:
		print("updating the satyr register")
		var name = get_node("connect/name").text
		var players = gamestate.get_player_list().size()
		gamestate.ms.register_server(00,name,players)

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	colorlist.add_item("INTRO_COL_RED",1)
	colorlist.add_item("INTRO_COL_BLUE",2)
	colorlist.add_item("INTRO_COL_GREEN",3)
	set_process(false)

func _on_host_pressed():
	if (get_node("connect/name").text == ""):
		get_node("connect/error_label").text="CON_ERR_A"#Invalid name!
		return

	if (get_node("connect/name").text == "default"):
		get_node("connect/name").set_text("Satyr")
	get_node("players/start").show()
	if gamestate.external_ip != null:
		get_node("players/ip_data").set_text(gamestate.external_ip)
	get_node("connect").hide()
	get_node("players").show()
	get_node("players/desc_nymph").hide()
	get_node("players/desc_satyr").show()
	get_node("players/ip_data").show()
	get_node("connect/error_label").text=""

	var name = get_node("connect/name").text
	gamestate.host_game(name)
	get_node("players/satus").set_text("LOBBY_SA_IP")
	set_process(true)
	lobby_state = idx_state["sa_update_ms"]
	refresh_lobby()



func _on_join_pressed():
	if (get_node("connect/name").text == ""):
		get_node("connect/error_label").text="CON_ERR_A"#Invalid name!
		return
	if (get_node("connect/name").text == "default"):
		get_node("connect/name").set_text("Nymph"+str(randi()%50))

	var ip = get_node("connect/ip").text
	if (not ip.is_valid_ip_address()):
		get_node("connect/error_label").text="CON_ERR_B"#Invalid IPv4 address!
		return
	

	get_node("players/start").hide()

	get_node("connect/error_label").text=("")#Connection attempt to IP address
	get_node("connect/host").disabled=true
	get_node("connect/join").disabled=true

	var name = get_node("connect/name").text
	gamestate.join_game(ip, name)
	get_node("players/desc_nymph").show()
	get_node("players/ip_data").hide()
	get_node("players/desc_satyr").hide()
	get_node("players/satus").set_text("LOBBY_NY_WA")
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("connect").hide()
	get_node("players").show()

func _on_connection_failed():
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled=false
	get_node("connect/error_label").set_text("CON_ERR_D")#Connection failed.

func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("players").hide()
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled

func _on_game_error(errtxt):
	get_node("error").set_text(str(errtxt))
	get_node("error").popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("players/list").clear()
	get_node("players/list").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("players/list").add_item(p)

	get_node("players/start").disabled=not get_tree().is_network_server()
#	if get_tree().is_network_server() and players.size() >= 4:
	if get_tree().is_network_server() and players.size() >= 4:
#		_on_start_pressed()
		gamestate.begin_game()


func _on_start_pressed():
#	lobby_state = idx_state["idle"]
	gamestate.begin_game()


func _on_pick_satyr_pressed():

	if !gamestate.my_cd.has("satyr_skin"):
		gamestate.my_cd = {"satyr_skin":"default"}
#	if gamestate.external_ip != null:
#		get_node("players/satyr_info").set_text(str(gamestate.external_ip))
#	else:
#		get_node("connect/ip").set_text("127.0.0.1")
	get_node("connect/ip_label").hide()
	get_node("connect/ip").hide()
	get_node("connect/join").hide()
	get_node("connect/host").show()
	get_node("intro").hide()
	get_node("connect").show()
	
	get_node("connect/error_label").set_text("CON_DESC_SA")#CON_DESC

	
	set_my_color()
	

#func _on_pick_nymph_pressed():
#	get_node("connect/ip").set_text("127.0.0.1")
#	get_node("connect/ip").show()
#
#	if !gamestate.my_cd.has("nymph_skin"):
#		gamestate.my_cd = {"nymph_skin":"default"}
#	get_node("connect/ip_label").show()
#	get_node("connect/join").show()
#	get_node("connect/host").hide()
#	get_node("intro").hide()
#	get_node("connect").show()
#	get_node("connect/error_label").set_text("CON_DESC_SA")
#	set_my_color()

func _on_pick_nymph_pressed():
	if !gamestate.my_cd.has("nymph_skin"):
		gamestate.my_cd = {"nymph_skin":"default"}
	get_node("connect/ip").set_text("127.0.0.1")
	get_node("connect/ip").show()
	get_node("connect/host").hide()
	get_node("intro").hide()
	get_node("ny_select").show()
	gamestate.main.activate_tool(self,"nymph_server_request")
#	if !gamestate.my_cd.has("nymph_skin"):
#		gamestate.my_cd = {"nymph_skin":"default"}
#	get_node("connect/ip_label").show()
#	get_node("connect/join").show()
#	get_node("connect").show()
#	get_node("connect/error_label").set_text("CON_DESC_SA")
#	set_my_color()


func set_my_color():
	var pickt = colorlist.get_selected_id()
	print(pickt)
	if pickt == 1:
		gamestate.my_cd["color"] = Color(255,0,0)
	elif pickt == 2:
		gamestate.my_cd["color"] = Color(0,0,255)
	else:
		gamestate.my_cd["color"] = Color(0,255,0)
	get_node("colorpick").set_modulate(gamestate.my_cd["color"])


func _on_back_pressed():
	set_process(false)
	get_node("connect/ip").set_text("127.0.0.1")
	get_node("intro").show()
	get_node("connect").hide()
	get_node("connect/host").set_disabled(false)
	get_node("connect/join").set_disabled(false)
	get_node("connect/name").set_text("default")
	get_tree().set_network_peer(null)
	get_node("connect/join").show()
	get_node("connect/host").show()



func _on_discord_invite_pressed():
	OS.shell_open("https://discord.gg/F6VrSMF")
	get_node("discord_invite").queue_free()
