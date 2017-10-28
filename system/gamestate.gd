extends Node

#nodes
var main #main node will place itself here
var world #main node will place world container here
var roster#
var gui #main gui will place itself here
var gui_lobby# gui lobby (child of gui) will place itself here
var activeworld


#clients data
var my_cd = {}#nymph_skin_id/satyr_skin_id/color/name
sync var client_data = {}


#system
var time = 0.0
var ingame = false


#queue list for players ready
var players_ready = []

# Default game port
const DEFAULT_PORT = 6969

# Max number of players
const MAX_PEERS = 4

# Name for my player
var player_name = "Entity"

# Names for remote players in id:name format
var players = {}

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


#tools and various stuff
var external_ip = null
var ip_tool = load("res://system/ipdetect.tscn")
var echo_ip


func respawn_request():
	if !ingame:
		return
	if is_network_master():
		pass
	else:
		print("nymph here")

func _enter_tree():
	set_process(true)

func _process(delta):
	time += delta


# Callback from SceneTree
func _player_connected(id):
# This is not used in this demo, because _connected_ok is called for clients
# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/world")): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():#the server doesn't use this
# Registration of a client beings here, tell everyone that we are here
	var my_nui = get_tree().get_network_unique_id()
	rpc("register_player", my_nui, player_name, my_cd)
	client_data[my_nui] = my_cd
	
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

# Lobby management functions

remote func register_player(id, name, its_cd):
	if (get_tree().is_network_server()):
		client_data[id] = its_cd
#		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name, my_cd) # Send myself to new dude

		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id], client_data[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, name, its_cd) # Send new dude to player
	client_data[id] = its_cd
	players[id] = name
	emit_signal("player_list_changed")



remote func unregister_player(id):
	players.erase(id)
	client_data.erase(id)
	emit_signal("player_list_changed")


remote func post_start_game():
	time = 0.0
	get_tree().set_pause(false) # Unpause and unleash the game!

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if (not id in players_ready):
		players_ready.append(id)

	if (players_ready.size() == players.size()):
		for p in players:
			rpc_id(p, "post_start_game")

func host_game(name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	client_data[1] = my_cd#

func join_game(ip, name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)
func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func nymph_captured(nymph):
	if !get_tree().is_network_server():
		return
	#check if is a nymph that actually exist
	var nymph_id = nymph.get_name()
	if nymph_id != "1":
		print("captured is not the satry")
	if roster.get_node(nymph_id) != null:
		print("captured nymph acutally exist")
	
#	is_captured(nymph.get_name())

#	print("nymph \""+ str(nymph)+"\" was captured")
#	print("her name is: " +str(nymph_id))
#	print("captured nymph and satyr are lock in cinematic mode")
#	print("show other player")
	for p in players:#telling nymphs one of them is captured
#						also to the one who's actually captured
		rpc_id(p, "is_captured", nymph_id)
	is_captured(nymph_id)

func satyr_captured():
	if !get_tree().is_network_server():
		return
	print("the satyr is caputred")
	print("telling all other players")
	print("captured satyr and winning nymph are lock in cinematic mode")

remote func is_captured(who):
	print("captured player...")
	if who == str(get_tree().get_network_unique_id()):
		print("that's me")
	pass

func get_world_spawnpoints():
	#reset spawnpos
	var spawnpos = {}
	for i in 5:
		spawnpos[i] = Vector3(0,0,0)

	var world_poslist = get_node("/root/main/world").get_child(0).get_node("pos")
	if world_poslist == null:
		return spawnpos

	#if the world is already loaded with a "pos" node
	#(supposedly cointain other empty spatial), we use it

	var pos_idx = 0#if no masterspawnpoint will be found
#					it'll just take the 1st
	if world_poslist.has_node("master"):#master spawnpoint belong to master
		spawnpos[0] = world_poslist.get_node("master").get_translation()
		pos_idx = 1#1st spawnpoint is taken by master
		print("master spawn is at: " +str(world_poslist.get_node("master").get_translation()))
	for i in 5:
		var trsn_node = world_poslist.get_child(i)
		if (trsn_node.get_name() != "master") or (trsn_node == null):
			#if "master spawn" exist, or child don't exist at all
			#we ignore this cycle
			spawnpos[pos_idx] = trsn_node.get_translation()
			pos_idx+=1
	print(spawnpos)
	return spawnpos

func begin_game():
	assert(get_tree().is_network_server())#only the server should do this; otherwise.. fell free to crash
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
#	# Call to pre-start game with the spawn points

	for p in players:#the "players" Dictionary contain *all other* players (not own self)
		rpc_id(p, "pre_start_game", spawn_points)
	pre_start_game(spawn_points)

remote func kill_everyone():
	if is_network_master():
		return
	for i in range(roster.get_child_count()):
		roster.get_child(i).human_control =false
		roster.get_child(i).die()

func respawn():#
	if !is_network_master():#check if server is asking respawn
		return
	for i in players:#every player (not us, server) kills its player and dummies
		rpc_id(i, "kill_everyone")
	for i in range(roster.get_child_count()):# I (server) kill my child
		roster.get_child(i).human_control =false
		roster.get_child(i).die()
		
	begin_game()#once the roster of player is cleared, we lauch a "new" game
		
#func begin_game():
#	assert(get_tree().is_network_server())
#
#	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing
#	var spawn_points = {}
#	spawn_points[1] = 0 # Server in spawn point 0
#	var spawn_point_idx = 1
#	for p in players:
#		spawn_points[p] = spawn_point_idx
#		spawn_point_idx += 1
#	# Call to pre-start game with the spawn points
#	print("spawn points are : " + str(spawn_points))
#	for p in players:
#		rpc_id(p, "pre_start_game", spawn_points)
#
#	pre_start_game(spawn_points)



remote func pre_start_game(spawn_points):

	#	TODO: load the request world map /root/main/world 
	#	(map has to be chosed and paradigm must be set beofore)
	gui_lobby.hide()
	gui.get_node("ingame").show()
	var spawn_translations = get_world_spawnpoints()

	var player_frame = load("res://actors/player_frame.tscn")
	var index = 1
#	print("spawnlist is : " +str(spawn_points))
	for p_id in spawn_points:
		var player = player_frame.instance()
		player.set_name(str(p_id)) # Use unique ID as node name
		player.my_cd = client_data[p_id]
		player.set_network_master(p_id) #set unique id as master
		if p_id == 1:
			player.my_class = "satyr"
			player.position = spawn_translations[0]
		else:
			player.my_class = "nymph"
			player.position = spawn_translations[index]
			index += 1
		roster.add_child(player)
		
	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()
	ingame=true




	# Change scene
#	var world = load("res://world.tscn").instance()
#	get_tree().get_root().add_child(world)

#	get_tree().get_root().get_node("lobby").hide()

#	var player_scene = load("res://player.tscn")

#	for p_id in spawn_points:
#		var spawn_pos = world.get_node("spawn_points/" + str(spawn_points[p_id])).position
#		var player = player_scene.instance()

#		player.set_name(str(p_id)) # Use unique ID as node name
#		player.position=spawn_pos
#		player.set_network_master(p_id) #set unique id as master

#		if (p_id == get_tree().get_network_unique_id()):
#			# If node for this peer id, set name
#			player.set_player_name(player_name)
#		else:
#			# Otherwise set name from peer
#			player.set_player_name(players[p_id])

#		world.get_node("players").add_child(player)

	# Set up score
#	world.get_node("score").add_player(get_tree().get_network_unique_id(), player_name)
#	for pn in players:
#		world.get_node("score").add_player(pn, players[pn])
#
#	if (not get_tree().is_network_server()):
#		# Tell server we are ready to start
#		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
#	elif players.size() == 0:
#		post_start_game()



func end_game():
	if (has_node("/root/main/world")): # Game is in progress
#		# End it
		get_node("/root/main/world").queue_free()
#
	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking
#
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	update_external_ip(true)

##tools
func update_external_ip(force):
	if (external_ip != null) and !force:#there's already a external ip, if there isn't a "forced request", just abot abort 
		return

	if echo_ip != null:
		echo_ip.queue_free()
	echo_ip = ip_tool.instance()
	echo_ip.node_requesting = self

	if gui_lobby.get_node("players/ip_data") != null:
		echo_ip.target_label = gui_lobby.get_node("players/ip_data")
	#echo_ip.target_label = where
	add_child(echo_ip)




##############################backups

#remote func pre_start_game(spawn_points):
	# Change scene
#	var world = load("res://world.tscn").instance()
#	get_tree().get_root().add_child(world)

#	get_tree().get_root().get_node("lobby").hide()

#	var player_scene = load("res://player.tscn")

#	for p_id in spawn_points:
#		var spawn_pos = world.get_node("spawn_points/" + str(spawn_points[p_id])).position
#		var player = player_scene.instance()

#		player.set_name(str(p_id)) # Use unique ID as node name
#		player.position=spawn_pos
#		player.set_network_master(p_id) #set unique id as master

#		if (p_id == get_tree().get_network_unique_id()):
#			# If node for this peer id, set name
#			player.set_player_name(player_name)
#		else:
#			# Otherwise set name from peer
#			player.set_player_name(players[p_id])

#		world.get_node("players").add_child(player)

	# Set up score
#	world.get_node("score").add_player(get_tree().get_network_unique_id(), player_name)
#	for pn in players:
#		world.get_node("score").add_player(pn, players[pn])
#
#	if (not get_tree().is_network_server()):
#		# Tell server we are ready to start
#		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
#	elif players.size() == 0:
#		post_start_game()

