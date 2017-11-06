extends Control

var alert_message
var status = 0
var button_switch
var custom_field

var delay = 0
const timeout = 3
var character_count = 0


func btn_toggled():
	if button_switch.pressed:
		custom_field.show()
	else:
		custom_field.hide()
		

func _enter_tree():
	alert_message = get_node("alert")
	set_process(false)
	button_switch = get_node("TabContainer/Server/srv_switch")
	custom_field = get_node("TabContainer/Server/custom")
	button_switch.connect("pressed", self, "btn_toggled")
#	button_switch.connect("button_up", self, "srv_switch_up")
#	var name = get_node("connect/name").text
#	gamestate.join_game(ip, name)
#	get_node("players/desc_nymph").show()
#	get_node("players/ip_data").hide()
#	get_node("players/desc_satyr").hide()
#	get_node("players/satus").set_text("LOBBY_NY_WA")


func _process(delta):
	if status == 1:#initiate show message
		character_count = alert_message.get_total_character_count()
		print("character count is: " +str(character_count))
		alert_message.show()
		status = 2
		return
	elif status == 2:#place letters
		var visible_chars = alert_message.get_visible_characters()+1
		alert_message.set_visible_characters(visible_chars)
		if visible_chars >= character_count:
			status = 3
			delay = 0
			return
	elif status == 3:#wait
		delay += 1*delta
		if delay >= timeout:
			status = 4
			return
	elif status == 4:#fade away
		var opacity = alert_message.get_modulate()
		opacity.a -= 0.4*delta
		if opacity.a <= 0:
			print("done opacity ")
			alert_message.hide()
			opacity.a = 1
			status = 0
		alert_message.set_modulate(opacity)

	

func alert(text):
	alert_message.hide()
	alert_message.set_modulate(Color(1,1,1,1))
	alert_message.set_visible_characters(0)
	alert_message.set_text(text)
#	character_count = text.length()
#	print("character size is: " + str(character_count))
	status = 1
	set_process(true)

func _on_join_pressed():
#	print(TranslationServer.translate("NY_SELECT_IN_NAME"))


	var ip = get_node("TabContainer/Server/custom/ip").get_text()
	var name = get_node("in_name").text
	if !ip.is_valid_ip_address():
		alert("NY_SELECT_ERROR_A")#Select a valid server to connect first
		return
	if name == "":
		alert("CON_ERR_A")#Invalid name!
		return
	if name == "default":
		name = TranslationServer.translate("NY_SELECT_IN_NAME")
	if gamestate.active_tool != null:
		if gamestate.active_tool.task == gamestate.active_tool.idx_task["nymph_request"]:
			gamestate.active_tool.die()#if the active tool is working for us... let it knows can "rest"
	
	gamestate.gui_lobby.get_node("players").show()
	gamestate.gui_lobby.get_node("players/desc_nymph").show()
	gamestate.gui_lobby.get_node("players/start").hide()
	gamestate.gui_lobby.get_node("players/ip_data").hide()
	gamestate.gui_lobby.get_node("players/desc_satyr").hide()
	gamestate.gui_lobby.get_node("players/satus").set_text("LOBBY_NY_WA")
	hide()
	gamestate.join_game(ip, name)
#	get_node("connect/error_label").text=("")#Connection attempt to IP address
#	get_node("connect/host").disabled=true
#	get_node("connect/join").disabled=true
#
#	var name = get_node("connect/name").text
#	gamestate.join_game(ip, name)
#	get_node("players/desc_nymph").show()
#	get_node("players/ip_data").hide()
#	get_node("players/desc_satyr").hide()
#	get_node("players/satus").set_text("LOBBY_NY_WA")




