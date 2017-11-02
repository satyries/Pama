extends RigidBody

#server will set for us
#var my_class
#identity and data


#TODO 1: (determine who get the score):
#satyr in charge mode colliding with nymph = send server "gamestate.nymph_captured()"
#	the check is directly done by the server/player (satyr)
#satyr in stun mode colliding withg nymph = send server "gamestate.satyr_captured()"
#	the check is done in the dummy (nymph) player on the server.

#TODO 2: (process of the cinamatic mode):
#	this draft is still not designed, it looks like will get very complicated with the main design
#main design of the cinematic mode.
#
#this will always involve only TWO people: the satyr and the nymph.
#	TWO different FPV camera in which will always involve the server (satyr's camera)
#	the two locked players (satyr and nymph) will not able to move, so WASD input are ignored
#	yaw and pitch for the camera will be limited (trough interpolation and hard limits) so the two will be forced to see each others

#the rest of the players (expected to be all nymph) will see the TWO as dummies


var position
onready var name = get_name()
var my_class
var my_cd = {}
var player = false
var satyr = false

#body building
var head
var skin#to be removed
var model
var body_animation#if dummy the model is 
var next_sync = 0.0

var human_control = false#on server every "player frame" is considered under human control

var SPEED = [2, 2, 6]#processing speed[0], normal speed[1], (satyr) charge speed[2]
const satyr_basespeed = 1
const nymph_basespeed = 2

#status
var charging = [false, 0]#[0]is charging?true/false [1] cooldown time
var charge_timeout = 4#when charge reach this time, it cooldown
var charge_delay = [0,4]
var charge_collide = false#detect if the satyr is colliding against something (two rays)

var cinematic = false#while this status is in effect, all features related to normal gameplay are disabled
var cinematic_lock = [10,20]

var stun_delay = [0, 5]
sync var status = 0
const idx_stat = {	
				"idle"		:0,#satyr/nymph
				"walking"	:1,#satyr
				"stealth"	:2,#nymph
				"running"	:3,#nymph
				"charging"	:4,#satyr
				"stunned"	:5#satyr
				}

sync var anim = 0
var old_anim = 0

const idx_anim = {
#general
					"idle"		:0,#
#satyr
					"walk"		:11,
					"charge"	:12,
					"crash"		:13,
#nymph
					"stealth"	:30,
					"run"		:31,
#close index
					"tail":99
				}

var idx_anim_db = []



var respawn_switch = false

onready var body		= get_node("body")
onready var raycast		= get_node("ray")
onready var chargeray_l	= get_node("body/chargeray_l")
onready var chargeray_r	= get_node("body/chargeray_r")

var camera
var hv = Vector3()
#var jumping = false

sync var yaw = 0.0
sync var pos = Vector3()
var old_pos = Vector3()

sync var l_velocity = Vector3()
slave var dir = Vector3()
slave var input = [0, 0]

var old_status = 0

#debug stuff
var label_text = ""
var billboard

func anim_head(anim):
	return
	if anim == "stop":
		camera.reset_rotary()
		return
	camera.get_node("anim").play(anim)

func anim_body(anim):

#	print("we got a request of: " +str(anim))
#	camera.model.get_node("AnimationPlayer").play(anim)
	
	body_animation.play(anim)
	if is_network_master():
		rset_unreliable("anim", idx_anim[anim])
	old_anim = idx_anim[anim]

func set_camera_body(bodymodel):
	if bodymodel.get_node("rig/Skeleton/head") != null:#model4fps: there's an head? let's cut it!
		bodymodel.get_node("rig/Skeleton/head").queue_free()
	camera.model = bodymodel
	camera.skeleton = bodymodel.get_node("rig/Skeleton")
	camera.base.add_child(bodymodel)
	body_animation = bodymodel.get_node("AnimationPlayer")

func set_nymph_local():#set skin, clothes and for the nymph player (fps)
	var skin_id = my_cd["nymph_skin"]
	var skin_db = gamestate.main.skin_nymph
	if !skin_db.has(model):
		model = "default"
	set_camera_body(load(skin_db[model]).instance())

func set_satyr_local():#set skin, clothes and for the satyr player (fps)
#	print(str(get_name()) + " is satyr player")
	var model = my_cd["satyr_skin"]
	var skin_db = gamestate.main.skin_satyr
	if !skin_db.has(model):
		model = "default"
	set_camera_body(load(skin_db[model]).instance())

func set_satyr_remote():#set skin, clothes and for the satyr dummy (players we see)
#	print(str(get_name()) + " is satyr dummy")
	var model = my_cd["satyr_skin"]
	var skin_db = gamestate.main.skin_satyr
	if !skin_db.has(model):
		model = "default"
	model = load(skin_db[model]).instance()
	model.set_rotation_deg(Vector3(0,180,0))
	get_node("body").add_child(model)
	body_animation = model.get_node("AnimationPlayer")




func set_nymph_remote():#set skin, clothes and for the nymph dummy (players we see)
#	print(str(get_name()) + " is nymph dummy")
#	print(my_cd["nymph_skin"])
	var model = my_cd["nymph_skin"]
	var skin_db = gamestate.main.skin_nymph
	if !skin_db.has(model):
		model = "default"
	model = load(skin_db[model]).instance()
	model.set_rotation_deg(Vector3(0,180,0))
	get_node("body").add_child(model)
	body_animation = model.get_node("AnimationPlayer")

func _enter_tree():
	
	#initiate animation database
	var anim_db_size = 0
	for i in idx_anim:
#		print(i)
		if anim_db_size < idx_anim[i]:
#			print("resizing the db to: " +str(idx_anim[i]))
			idx_anim_db.resize(idx_anim[i]+1)
			anim_db_size = idx_anim[i]+1
		idx_anim_db[idx_anim[i]] = i
	if (get_name() == "1" ) and is_network_master():
		satyr = true
		SPEED[1] = satyr_basespeed
		
	else:#not a satyr: assume it's a nymph
		set_meta("nymph", 0)
#	set_fixed_process(true)#was renamed 1st october
	set_translation(position)
	skin = SpatialMaterial.new()
	skin.set_albedo(my_cd["color"])
	if get_name() == str(get_tree().get_network_unique_id()):#hey,that's me!
		human_control = true
		set_fps_cam()
		if get_name() == "1":
			set_satyr_local()
		else:
			set_nymph_local()
	else:
		if get_name() == "1":
			set_satyr_remote()
		else:
			set_nymph_remote()

	get_node("body/mesh").set_surface_material(0, skin)
	get_node("body/head").set_surface_material(0, skin)
	get_node("body/head2").set_surface_material(0, skin)
	
	set_process(true);
	set_physics_process(true)

func set_status(req_status,strafe):
	if player:
		player_switch(status, idx_stat[req_status], strafe)
	else:
		dummy_switch(status, idx_stat[req_status], strafe)
	rset_unreliable("status", idx_stat[req_status])



func player_switch(from, to, strafe):
	if satyr:
		if (from == idx_stat["walking"]) or (from == idx_stat["idle"]):
			if to == idx_stat["charging"]:
				anim_head("charging")
				anim_body("charge")
			elif to == idx_stat["walking"]:
				anim_body("walk")
			else:
				anim_body("idle")
		elif from == idx_stat["charging"]:
			if to == idx_stat["stunned"]:
				anim_head("stunned")
				anim_body("crash")
				camera.cinematic_request("stun")
#				cinematic_lock = [yaw, 30]
#				cinematic = true
#				camera.cinematic_request()
			else:
				anim_body("idle")
				anim_head("stop")
		elif from == idx_stat["stunned"]:
			anim_head("stop")
	else:
		if (from == idx_stat["running"]) or (from == idx_stat["idle"]):
			if to == idx_stat["running"]:
				anim_body("run")
			else:
				anim_body("idle")

#
#		if (to == idx_stat["running"]) and (from != to):
#			anim_body("run" + str(strafe))

func dummy_switch(from, to, strafe):
	if my_class == "satyr":
		if status == idx_stat["walking"]:
			pass
	else:
		if status == idx_stat["running"]:
			pass
#	print("dummy switched from: " +str(from) + " to " + str(to))

func dummy_process(delta):
	if my_class == "satyr":
		if status == idx_stat["stunned"]:
			skin = SpatialMaterial.new()
			skin.set_albedo(Color(randf(),randf(),randf(),1))
			get_node("body/mesh").set_surface_material(0, skin)
			get_node("body/head").set_surface_material(0, skin)
			get_node("body/head2").set_surface_material(0, skin)
	else:
		pass
		
	if old_status != status:
#		print("status changed for dummy")
		pass
	old_status = status
#func dummy_switch(from,to):#called everytime status switch from/to something
#	if from == idx_stat["stunned"]:
#		skin = SpatialMaterial.new()
#		skin.set_albedo(my_cd["color"])
#		get_node("body/mesh").set_surface_material(0, skin)
#		get_node("body/head").set_surface_material(0, skin)
#		get_node("body/head2").set_surface_material(0, skin)



func _process(delta):

	if !player:
		dummy_process(delta)
	if satyr:
		satyr_process(delta)

	if old_anim != anim:
		if idx_anim_db[anim] != null:
			body_animation.play(idx_anim_db[anim])
		else:
			print("there's a wrong request for animation")
	old_anim = anim


func satyr_charging(delta):
	if charge_delay[0] > charge_delay[1]:#charge ended with no result
		charge_delay[0] = 0
		set_status("idle", "")
		charge_collide = false
		SPEED[0] = SPEED[1]#speed return normal
	else:#continous
		if chargeray_l.is_colliding() or chargeray_r.is_colliding():
			var collide_r = chargeray_r.get_collider()
			var collide_l = chargeray_l.get_collider()
			if collide_r != null:
#				print(collide_r.get_meta_list())
				if collide_r.has_meta("nymph"):
#					print("it's a nymph!")
					set_status("idle", "")
					charge_delay[0] = 0
					charge_collide = false
					SPEED[0] = SPEED[1]#speed return normal
					gamestate.nymph_captured(collide_r)
					return
			if collide_l != null:
				if collide_l.has_meta("nymph"):
					print("it's a nymph!")
					set_status("idle", "")
					charge_delay[0] = 0
					charge_collide = false
					SPEED[0] = SPEED[1]#speed return normal
					gamestate.nymph_captured(collide_l)
					return
			set_status("stunned", "")
			charge_delay[0] = 0
			charge_collide = false
			SPEED[0] = SPEED[1]#speed return normal
		charge_delay[0] +=1*delta

func satyr_process(delta):
	
	
#	print("pos: " +str()
	if status == idx_stat["stunned"]:
#		print("cinlock is: " + str(cinematic_lock[0])+"x"+str(cinematic_lock[1])+ ": :" + str(abs(yaw)))
		if stun_delay[0] > stun_delay[1]:#stun ended
			stun_delay[0] = 0
			set_status("idle", "")
			camera.end_cinematic()
			anim_body("idle")
			SPEED[0] = SPEED[1]#speed return normal
		else:
			stun_delay[0] +=1*delta

	elif status == idx_stat["charging"]:
		satyr_charging(delta)
	elif (status == idx_stat["idle"]) or (status == idx_stat["walking"]):
		if input[0] and !gamestate.main.menu:
			set_status("charging", "")
			charge_delay[0] = 0
			SPEED[0] = SPEED[2]#speed goes rabid (charge mode)




func set_fps_cam():
	player = true
	head = load("res://actors/fps_cam.tscn").instance()
#	head.set_translation(get_node("headpos").get_translation())
#	head.get_node("base/arms").set_surface_material(0, skin)
#	head.get_node("base/arms/hand").set_surface_material(0, skin)
	get_node("body").hide()#I don't need to see my own "external" body
	add_child(head)




func _ready():
	if (get_tree().is_network_server()):
		raycast.add_exception(self)
	if satyr:
		chargeray_l.set_enabled(true)
		chargeray_r.set_enabled(true)

func _physics_process(delta):
	if is_network_master():
		var cam_trans = camera.camera.get_global_transform();
#		raydir = [
#			cam_trans.origin,
#			(cam_trans.xform(Vector3(0, 0, -1))-cam_trans.origin).normalized()
#		];
#		rset_unreliable("raydir", raydir);
#
		input[0] = Input.is_action_pressed("skill_a");
		input[1] = Input.is_action_pressed("skill_b");

		rset_unreliable("input", input);

		rset_unreliable("yaw", camera.yaw);

#	if get_tree().is_network_server():#set animations.. will come handy later
#		if (is_alive()):
#			if (is_moving()):
#				set_playerAnimation("run");
#			else:
#				set_playerAnimation("idle");
#
#
#		else:
#			set_playerAnimation("die");
#
#		if (player_curAni != player_ani):
#			rpc("set_playerAnimation", player_ani, true);
#			player_curAni = player_ani;

	if body != null:
#		if cinematic:
#			print("cinlock is: " +str(cinematic_lock[0]))
#			body.set_rotation(Vector3(0, deg2rad(cinematic_lock[0]), 0))
#		else:
#			body.set_rotation(Vector3(0, deg2rad(yaw), 0))
		body.set_rotation(Vector3(0, deg2rad(yaw), 0))
	if get_tree().is_network_server():
		rset_unreliable("pos", get_translation())
	else:#my guess: we don't just apply the body rotation, we "smooth" also
		var delta_pos = pos-get_translation()
		if (delta_pos.length() <= 1.0 || delta_pos.length() > 10.0):
			set_translation(pos)
		else:
			set_translation(get_translation().linear_interpolate(pos, 10*delta))




func satyr_if(state):#inegrate forces for satyr
	var delta = state.get_step();
	var lv = get_linear_velocity()
	var strafe = ""
	var request_status = null#insted of costantly set_status("stuf") for each case.. we just set a request ticket
	if is_network_master():
		assert(get_tree().is_network_server())
		var basis = camera.camera.get_global_transform().basis;
		dir = Vector3()
		if status == idx_stat["charging"]:
			dir -= basis[2]
		elif (status == idx_stat["idle"]) or (status == idx_stat["walking"]):
			var moving = false#we assume no directional key was press...
			if Input.is_action_pressed("walk_forward"):
				moving = true
				dir -= basis[2]
			if Input.is_action_pressed("walk_backward"):
				moving = true
				dir += basis[2];
			if Input.is_action_pressed("walk_strafeleft"):
				moving = true
				dir -= basis[0]
			if Input.is_action_pressed("walk_straferight"):
				moving = true
				dir += basis[0]
			if moving:#...we assumed wrong
				request_status = "walking"
			else:#indeed wasn't moving, so...
				request_status = "idle"
		dir.y = 0
		dir = dir.normalized()
		rset_unreliable("dir", dir);

#		if (request_status == "walking") and !is_moving():
#			request_status = "idle"
	
	if (get_tree().is_network_server()):
		if (typeof(dir) != TYPE_VECTOR3):
			dir = Vector3();
		dir = dir.normalized();
		dir *= SPEED[0];
	
		hv = hv.linear_interpolate(dir, 10*delta);
		lv.x = hv.x;
		lv.z = hv.z;
		set_linear_velocity(lv);
		rset_unreliable("l_velocity", lv);
#		print("request is: " + str(request_status))
	if request_status == null:
		return
	if status != idx_stat[str(request_status)]:
##		set_status_id(request_status)
		set_status(request_status, strafe)



func nymph_if(state):#integrate forces for nymph
	var delta = state.get_step();
	var lv = get_linear_velocity()
	var request_status = null#insted of costantly set_status("stuf") for each case.. we just set a request ticket
	var strafe = ""
	if is_network_master():
		var basis = camera.camera.get_global_transform().basis;
		dir = Vector3()
		if  0 == 0:#for now nymph always move.. this will help us sort things later
			var moving = false#we assume no directional key was press...
			
			if Input.is_action_pressed("walk_forward"):
				moving = true
				dir -= basis[2]
			if Input.is_action_pressed("walk_backward"):
				moving = true
				dir += basis[2];
			if Input.is_action_pressed("walk_strafeleft"):
				moving = true
				strafe = ".l"
				dir -= basis[0]
			if Input.is_action_pressed("walk_straferight"):
				moving = true
				strafe = ".r"
				dir += basis[0]
			if moving:#...we assumed wrong
				if Input.is_action_pressed("stealth_mode"):
					request_status = "stealth"
				else:
					request_status = "running"
			else:#indeed wasn't moving, so...
				request_status = "idle"
#			print("player nymph will request" + str(request_status))
		dir.y = 0
		dir = dir.normalized()
		rset_unreliable("dir", dir);

	if (get_tree().is_network_server()):
		if (typeof(dir) != TYPE_VECTOR3):
			dir = Vector3();
		dir = dir.normalized();
		dir *= SPEED[0];
	
		hv = hv.linear_interpolate(dir, 10*delta);
		lv.x = hv.x;
		lv.z = hv.z;
		set_linear_velocity(lv);
		rset_unreliable("l_velocity", lv);



	if request_status == null:
		return
	if status != idx_stat[str(request_status)]:
		set_status(request_status, strafe)



func _integrate_forces(state):
	if get_name() == "1":
		satyr_if(state)
		return
	else:
		nymph_if(state)
		return
	


func is_moving():
	return l_velocity.length() > 0.5;


func die():
	set_process(false)
	set_physics_process(false)
	set_name("dyieng"+str(randi()%99))
	queue_free()
















#######backup from origianl OpenCombat


#
##const SPEED = 4.5;#original speed
##const SPEED = 3.5#minotaur setting
#var SPEED = 1#walking
#
#onready var game	= get_node("/root/game");
#
#onready var body	= get_node("body");
#onready var raycast	= get_node("ray");
#
#
##onready var pfb_fpsCam = load("res://prefabs/fpsCam.tscn");
#var pfb_fpsCam
#onready var pfb_deathCam = load("res://prefabs/deathCam.tscn");
##onready var pfb_gunDecal = load("res://prefabs/gunDecal.tscn");
#
#var player_class = null
#var textlabel = ""
#
#var camera;
#var hv = Vector3();
#var jumping = false;
#
#
#
#sync var yaw = 0.0;
#sync var pos = Vector3();
#sync var linear_velocity = Vector3();
#
#slave var dir = Vector3();
#slave var input = [0, 0];
#slave var raydir = [Vector3(), Vector3()];
#
#var playerAnimation;
##var weaponAnimation;
#
#var player_id = -1;
#var player_name = "";
#var player_health = 100.0;
#var player_lastHit = 0.0;
#var player_ani = "";
#var player_curAni = "";
#var player_nextSpawn = 0.0;
#var player_nextClientDataSync = 0.0;
#
##var wpn_ani = "";
##var wpn_curAni = "";
##var wpn_clip = 30;
##var wpn_maxclip = wpn_clip;
##var wpn_ammo = 360;
##var wpn_damage = [12.0, 18.0];
##var wpn_firing = false;
##var wpn_reloading = false;
##var wpn_nextIdle = 0.0;
##var wpn_nextShoot = 0.0;
#
#
#
#func _enter_tree():

#
#	var model = load("res://models/players/minotaur/minotaur.scn").instance()
#	pfb_fpsCam = load("res://prefabs/satyrCam.tscn")#.instance()
#
#	model.set_rotation(Vector3(0,135,0))
#	model.set_name("models")
#	get_node("body").add_child(model)
#
#
#func _ready():
#	player_health = 100.0;
#
#	if (get_tree().is_network_server()):
#		raycast.add_exception(self);
#
##		game.gui.ui_scoreBoard.rpc("add_item", player_id, player_name, 0, 0);
#
##	if (!is_network_master()):
##		game.gui.ui_minimap.add_object(self);
#
#	playerAnimation = body.get_node("models").find_node("AnimationPlayer");
#
#	rpc("player_spawned");
#
#	set_process(true);
#	set_fixed_process(true);
#
#func attachFPSCam():
#	if (camera != null):
#		camera.queue_free();
#		camera = null;
#
#	camera = pfb_fpsCam.instance()
#	camera.set_name("camera");
#	camera.set_translation(get_node("camPos").get_translation());
#	add_child(camera);
#
##	weaponAnimation	= camera.weapon.find_node("AnimationPlayer");
#
#	body.hide();
#
#func attachDeathCam(target = null):
#	if (camera != null):
#		camera.queue_free();
#		camera = null;
#
#	camera = pfb_deathCam.instance();
#	camera.set_name("camera");
#	camera.target = target;
#	camera.startPos = get_node("camPos").get_translation();
#	add_child(camera);
#
#	body.show();
#
##func _exit_tree():
##	if (get_tree().is_network_server()):
##		game.gui.ui_scoreBoard.rpc("remove_item", player_id);
#
##	if (!is_network_master()):
##		game.gui.ui_minimap.remove_object(self);
#
#func _process(delta):
#
#
#	if (get_tree().is_network_server()):
#		respawn();
#
#		if (game.time > player_nextClientDataSync):
#			var cl_data = [
#				player_health,
##				wpn_clip,
##				wpn_ammo
#			];
#			rpc_unreliable("client_data", cl_data);
#			player_nextClientDataSync = game.time+1/30.0;
#
#func can_spawn():
#	return !is_alive() && game.time > player_nextSpawn;
#
#func respawn():
#	if (!can_spawn()):
#		return;
#	player_health = 100.0;
#	set_translation(Vector3(0,1,0));
#
#	rpc("player_spawned");
#
#func _fixed_process(delta):
#	if (is_network_master() && is_alive()):
#		var cam_trans = camera.camera.get_global_transform();
#		raydir = [
#			cam_trans.origin,
#			(cam_trans.xform(Vector3(0, 0, -1))-cam_trans.origin).normalized()
#		];
#		rset_unreliable("raydir", raydir);
#
#		input[0] = Input.is_action_pressed("shoot");
#		input[1] = Input.is_action_pressed("reload");
#
#		rset_unreliable("input", input);
#		rset_unreliable("yaw", camera.yaw);
#
#	if (get_tree().is_network_server()):
#		if (is_alive()):
#			if (is_moving()):
#				set_playerAnimation("run");
#			else:
#				set_playerAnimation("idle");
#
#
#		else:
#			set_playerAnimation("die");
#
#		if (player_curAni != player_ani):
#			rpc("set_playerAnimation", player_ani, true);
#			player_curAni = player_ani;
#
#	if (is_alive() && body != null):
#		body.set_rotation(Vector3(0, deg2rad(yaw), 0));
#
#	if (get_tree().is_network_server()):
#		rset_unreliable("pos", get_translation());
#	else:
#		var delta_pos = pos-get_translation();
#		if (delta_pos.length() <= 1.0 || delta_pos.length() > 10.0):
#			set_translation(pos);
#		else:
#			set_translation(get_translation().linear_interpolate(pos, 10*delta));
#
#func _integrate_forces(state):
#	var delta = state.get_step();
#	var lv = get_linear_velocity();
#
#	if (is_network_master() && is_alive()):
#		var basis = camera.camera.get_global_transform().basis;
#		dir = Vector3();
#
#		if (Input.is_key_pressed(KEY_W)):
#			dir -= basis[2];
#		if (Input.is_key_pressed(KEY_S)):
#			dir += basis[2];
#		if (Input.is_key_pressed(KEY_A)):
#			dir -= basis[0];
#		if (Input.is_key_pressed(KEY_D)):
#			dir += basis[0];
#
#		dir.y = 0;
#		dir = dir.normalized();
#
#		rset_unreliable("dir", dir);
#
#		if (Input.is_action_just_pressed("jump")):
#			rpc("jump");
#
#	if (get_tree().is_network_server()):
#		if (typeof(dir) != TYPE_VECTOR3):
#			dir = Vector3();
#		dir = dir.normalized();
#		dir *= SPEED;
#
#		if (!is_alive()):
#			dir *= 0.0;
#		elif (!raycast.is_colliding() || game.time < player_lastHit):
#			dir *= 0.5;
##		elif (is_firing()):
##			dir *= 0.8;
#
#		hv = hv.linear_interpolate(dir, 10*delta);
#
#		lv.x = hv.x;
#		lv.z = hv.z;
#
#		if (jumping && is_alive()):
#			if (raycast.is_colliding()):
#				lv.y = 6.0;
#			jumping = false;
#
#		set_linear_velocity(lv);
#		rset_unreliable("linear_velocity", lv);
#
#func is_alive():
#	return player_health > 0.0;
#
#
#
#sync func set_playerAnimation(ani = player_ani, force = false):
#	player_ani = ani;
#
#	if (playerAnimation.get_current_animation() != ani || force):
#		playerAnimation.play(ani);
#
#
#
#
#sync func jump():
#	if (!get_tree().is_network_server()):
#		return;
#	jumping = true;
#
#master func apply_clientfx(recoil):
#	if (!is_network_master()):
#		return;
#
#	camera.give_recoil(recoil);
#	game.gui.ui_crosshair.apply_firing();
#
#master func client_data(cl_data):
#	if (!is_network_master()):
#		return;
#
#
#
#	player_health = cl_data[0];
##	wpn_clip = cl_data[1];
##	wpn_ammo = cl_data[2];
#
#	game.gui.ui_lblHealth.set_text(str(int(player_health)).pad_zeros(3));
##	game.gui.ui_lblAmmo.set_text(str(int(wpn_clip)).pad_zeros(3) + "/" + str(int(wpn_ammo)).pad_zeros(3));
#
#
#
#sync func set_targetable():
#	set_mode(MODE_CHARACTER);
#
#	for i in range(0, get_shape_count()):
#		set_shape_as_trigger(i, false);
#
#sync func set_untargetable():
#	set_mode(MODE_STATIC);
#
#	for i in range(0, get_shape_count()):
#		set_shape_as_trigger(i, true);
#
#sync func player_killed(killer):
#	if (get_tree().is_network_server()):
#		player_nextSpawn = game.time+3.0;
#		rpc("drawSpawnBar", 3.0);
#
#		game.gui.ui_scoreBoard.increase_kill(killer, 1);
#		game.gui.ui_scoreBoard.increase_death(player_id, 1);
#
#		rpc("set_untargetable");
#
#	if (is_network_master()):
#		player_health = 0;
#		attachDeathCam(game.playerByID(killer));
#
#sync func player_spawned():
#	if (get_tree().is_network_server()):
#		rpc("set_targetable");
#
#	if (is_network_master()):
#		attachFPSCam();
#
#		rpc("player_ready");
#
#
#sync func drawSpawnBar(time):
#	if (!is_network_master()):
#		return;
#
#	game.gui.ui_spawnBar.draw_spawnBar(time);



##########################trashcode
#	if pos != old_pos:
#		print(str(get_name()) + " is moving ")
#	else:
#		print("standing")
#	old_pos = pos
#func satyr_process_before_rewrite(delta):
#	if status == idx_stat["stunned"]:
#		return
#	if charging[0]:
#		if charging[1] > charge_timeout:#reset
#			charging[0] = false
#			charge_collide = false
#			charging[1] = 0
#			SPEED[0] = SPEED[1]#speed return normal
#		else:#continous
#			if chargeray_l.is_colliding() or chargeray_r.is_colliding():
#				set_status("stunned")
#				charging[0] = false
#				charge_collide = false
#				charging[1] = 0
#				SPEED[0] = SPEED[1]#speed return normal
#			charging[1] +=1*delta
#	elif input[0]:
#		charging[0] = true
#		charging[1] = 0
#		SPEED[0] = SPEED[2]#speed goes rabid (charge mode)
##	if pos != old_pos:
##		print(str(get_name()) + " is moving ")
##	else:
##		print("standing")
##	old_pos = pos



#func _fake_intrgrated_forces(state):
#	var delta = state.get_step();
#	var lv = get_linear_velocity()
#
#	if is_network_master():
#		var basis = camera.camera.get_global_transform().basis;
#		dir = Vector3()
#
#
#
#		if satyr and charging[0]:
#			dir -= basis[2]
#		else:
#			if Input.is_action_pressed("walk_forward"):
#				dir -= basis[2]
#			if Input.is_action_pressed("walk_backward"):
#				dir += basis[2];
#			if Input.is_action_pressed("walk_strafeleft"):
#				dir -= basis[0]
#			if Input.is_action_pressed("walk_straferight"):
#				dir += basis[0]
#
#
#		dir.y = 0
#		dir = dir.normalized()
#
#		rset_unreliable("dir", dir);
#
##		if (Input.is_action_just_pressed("jump")):
##			rpc("jump");
#
#	if (get_tree().is_network_server()):
#		if (typeof(dir) != TYPE_VECTOR3):
#			dir = Vector3();
#		dir = dir.normalized();
#		dir *= SPEED[0];
#
##		if (!is_alive()):
##			dir *= 0.0;
##		elif (!raycast.is_colliding() || game.time < player_lastHit):
##			dir *= 0.5;
##		elif (is_firing()):
##			dir *= 0.8;
#
#		hv = hv.linear_interpolate(dir, 10*delta);
#
#		lv.x = hv.x;
#		lv.z = hv.z;
#
##		if (jumping && is_alive()):
##			if (raycast.is_colliding()):
##				lv.y = 6.0;
##			jumping = false;
#
#		set_linear_velocity(lv);
#		rset_unreliable("l_velocity", lv);
