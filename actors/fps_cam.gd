extends Spatial

const SENSITIVITY = 0.3;
#to do:
#reset_rotary switch = separate task in process.stop animation, interpolate vector3 of rotary
#animation set from cubic frame
#onready var player	= get_node("..")
#onready var base	= get_node("base")
#onready var camera	= get_node("base/rotary/camera")
#onready var raycast	= get_node("base/rotary/camera/ray")
#onready var rotary = get_node("base/rotary")
var player
var base
var camera
var camera_timeout = [0,0.3]#timer+reset time

var raycast
var rotary
var skin
var model
var skeleton
var skeleton_ratio
var eye_bone

var rset_rotary_switch = false

var pending_processes = {}

var pitch = 0.0
const pitch_limit = 80
const neck_bend = 0.1
var yaw = 0.0
var origin = Vector3()

onready var fx_stunt = preload("res://actors/camera_fx/stunt.tres")

func reset_rotary():
	rset_rotary_switch = true
	if pending_processes.has("reset_rotary"):
		pass#there was another rotary reset ongoing, 
	else:
		pending_processes["reset_rotary"] = true
#	print("pending process at request: " + str(pending_processes.size()))
	get_node("anim").stop(true)
	if !is_processing():
		set_process(true)


func _process(delta):
	
	
	if camera_timeout[0] >= 0:
		camera_timeout[0] = camera_timeout[1]
		update_camera()
	else:
		camera_timeout[0] += 1*delta
	
	if rset_rotary_switch:
		
		var straight = Vector3(0,0,0)
		var rota_deg = rotary.get_rotation_deg()
		
		if rota_deg.distance_to(straight) > 0.01:#riduci
			rota_deg = rota_deg.linear_interpolate(straight, 0.1)

			rotary.set_rotation_deg(rota_deg) 
		else:
			camera.set_environment(null)
			rotary.set_rotation_deg(straight)
			rset_rotary_switch = false
#			if pending_processes.has("reset_rotary"):
#				pending_processes.erase("reset_rotary")
#			set_process(false)
#	if pending_processes.size() <= 0:#nothing else to do
#		set_process(false)



func _ready():

#	skin.set_global_transform(get_node("../feetpos").get_global_transform())
#	skin.set_rotation_deg(get_node("../feetpos").get_rotation_deg())

	if (typeof(player) == TYPE_NODE_PATH):
		player = get_node(player)
	if (typeof(base) == TYPE_NODE_PATH):
		base = get_node(base)
	if (typeof(camera) == TYPE_NODE_PATH):
		camera = get_node(camera)
	if (typeof(raycast) == TYPE_NODE_PATH):
		raycast = get_node(raycast)
	raycast.add_exception(player)
	pitch = camera.get_rotation_deg().x
	yaw = base.get_rotation_deg().y
	camera.make_current()
	set_process(true)
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if gamestate.main.menu:
		gamestate.main.menu = false
	if skeleton != null:
		eye_bone = skeleton.find_bone("eyepos")
	
#	model.set_transform(modeltransf)
#	model.global_rotate(Vector3(0,1,0), 180)
#	var model_adjust = model.get_global_transform()
#	model_adjust.origin = get_node("../feetpos").get_global_transform().origin
#	model.set_global_transform(get_node("../feetpos").get_global_transform())
	var turnfix = get_node("../feetpos").get_rotation()
	model.set_rotation(turnfix)
#	skeleton.set_rotation(turnfix)
	skeleton_ratio = skeleton.get_parent().get_scale()[0]

func _enter_tree():
	player	= get_node("..")
	base	= get_node("base")
	camera	= get_node("base/rotary/camera")
	raycast	= get_node("base/rotary/camera/ray")
	rotary = get_node("base/rotary")
	get_node("..").camera = self
		
#	skeleton = skin.get_node("rig/Skeleton")
#	eye_bone = skeleton.find_bone("eyepos")

#	eyepos = camera.skin.get_node("rig/Skeleton").find_bone("eyepos")
#	var eye_pos = camera.skin.get_node("rig/Skeleton").get_bone_global_pose(eyepos)


func _exit_tree():
	if player.human_control:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);



func _input(ie):
	if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
		return

	if ie.is_class("InputEventMouseMotion"):
#		pitch = clamp(pitch-SENSITIVITY*ie.relative.y, -89, 89)
		pitch = clamp(pitch-SENSITIVITY*ie.relative.y, -pitch_limit, pitch_limit)
		yaw = fmod(yaw-SENSITIVITY*ie.relative.x, 360.0)
#		origin.x = clamp(origin.x-(SENSITIVITY*ie.relative_x*bob_length), -bob_length*3.0, bob_length*3.0)
#		origin.y = clamp(origin.y+(SENSITIVITY*ie.relative_y*bob_length), -bob_length*3.0, bob_length*3.0);
		update_camera()

func update_camera():
	camera_timeout[0] = camera_timeout[1]
	player.yaw = yaw
	base.set_rotation_deg(Vector3(0, yaw, 0))
	camera.set_rotation_deg(Vector3(pitch, 0, 0))

#soft approach
	var camerapos = camera.get_transform()
	
	#fixes for the eyeposition (which is a bone on the armature)
	#1:armature is scaled: fix is *skeleton_ratio
	#2:the model is rotated, but the armature ignore this, apply additional rotation "reflect(Vector3(0,1,0)"
	var eye_position = skeleton.get_bone_global_pose(eye_bone).origin.reflect(Vector3(0,1,0))*skeleton_ratio

	camerapos.origin = camerapos.origin.linear_interpolate(eye_position, 0.1)
#	camerapos = camerapos.rotate_x(pitch)
	
	camera.set_transform(camerapos)
#working approach
#	var eye_position = skeleton.get_bone_global_pose(eye_bone)
#	eye_position.origin = eye_position.origin.reflect(Vector3(0,1,0))*skeleton_ratio
#	camera.set_transform(eye_position)


#
#
#
#	var eyepos_debug = skeleton.get_bone_transform(eye_bone).origin#relative
##	eyepos_debug = str(eyepos_debug) +"\nscale: " + str(skeleton.get_parent().get_scale())
##	eyepos_debug = str(eyepos_debug) +"\ncustompose: " + str(skeleton.get_bone_custom_pose(eye_bone))
#	eyepos_debug = str(eyepos_debug) +"\nglobalpose: " + str(skeleton.get_bone_global_pose(eye_bone)[0])
#	eyepos_debug = str(eyepos_debug) +"\nglobalpose: " + str(skeleton.get_bone_global_pose(eye_bone)[1])
#	eyepos_debug = str(eyepos_debug) +"\nglobalpose: " + str(skeleton.get_bone_global_pose(eye_bone)[2])
##	eyepos_debug = str(eyepos_debug) +"\nbone pose: " + str(skeleton.get_bone_pose(eye_bone))
##	eyepos_debug = str(eyepos_debug) +"\nbone rest: " + str(skeleton.get_bone_rest(eye_bone))
#	eyepos_debug = str(eyepos_debug) +"\nbone using: " + str(eye_position)
#
#
#	gamestate.gui.get_node("ingame/name").set_text(str(eyepos_debug))
#	var d = skeleton.get_bone_transform(eye_bone).origin#.basis[0]
#	gamestate.gui.get_node("ingame/name").set_text(str(d))
#	var pos = camera.get_transform()
	
#	pos.origin = pos.origin.linear_interpolate(skeleton.get_bone_transform(eye_bone).origin, 0.1)
#	pos.origin += pos.origin.linear_interpolate(skeleton.get_bone_transform(eye_bone).origin, 0.1)
#	camera.set_global_transform(pos)
#	var eyes = Transform()
#	transform.origin = skeleton.get_bone_global_pose(eye_bone).origin
#	camera.set_global_transform(eyes)


#	var bonepose = skeleton.get_bone_pose(eye_bone)
#	camera.set_transform(skeleton.get_bone_pose(eye_bone).basis)
#	var a = skeleton.get_bone_pose(eye_bone)
#	var b = skeleton.get_bone_custom_pose(eye_bone)
#	var c = skeleton.get_bone_rest(eye_bone).basis
#	var d = skeleton.get_bone_transform(eye_bone).basis
#	print("a: " + str(a)+ "\nb :" + str(b)+ "\nc :" + str(c)+ "\nd :" + str(d))
#	print("c :" + str(c)+ "\nd :" + str(d))
#	print("\nd :" + str(d))
	
#	camera.set_transform(bonepose)
#	eyepos = camera.skin.get_node("rig/Skeleton").find_bone("eyepos")
#	var eye_pos = camera.skin.get_node("rig/Skeleton").get_bone_global_pose(eyepos)

	if pitch < 0:
		var neck_twist = (abs(pitch)/pitch_limit)*neck_bend
#		camera.set_translation(Vector3(0,0, -neck_twist))
		
#		print("player is looking down")
#	rset_unreliable("yaw", yaw);

#
#const SENSITIVITY = 0.3;
#
#onready var player	= get_node("..");
#onready var base	= get_node("base");
#onready var camera	= get_node("base/camera");
#onready var raycast	= get_node("base/camera/ray");
##onready var weapon	= get_node("base/camera/wpn");
#
#var pitch = 0.0;
#var yaw = 0.0;
#var origin = Vector3();
#
#var bob_length = 0.01;
#var bob_angle = 0.0;
#var bob_speed = 1.4;
#
#func _ready():
#	if (typeof(player) == TYPE_NODE_PATH):
#		player = get_node(player);
#	if (typeof(base) == TYPE_NODE_PATH):
#		base = get_node(base);
#	if (typeof(camera) == TYPE_NODE_PATH):
#		camera = get_node(camera);
#	if (typeof(raycast) == TYPE_NODE_PATH):
#		raycast = get_node(raycast);
##	if (typeof(weapon) == TYPE_NODE_PATH):
##		weapon = get_node(weapon);
#
#	raycast.add_exception(player);
#	pitch = camera.get_rotation_deg().x;
#	yaw = base.get_rotation_deg().y;
#
#	camera.make_current();
#
#	set_process(true);
#	set_process_input(true);
#
#func _enter_tree():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
#
#func _exit_tree():
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
#
#func _process(delta):
##	if (player.is_firing()):
##		origin = Vector3();
##	else:
##		origin = origin.linear_interpolate(Vector3(), 10*delta);
#	var wpn_pos = origin;
#
##	if (player.is_firing()):
##		bob_angle = 0.0;
#
#	if (player.is_moving()):
#		bob_angle = fmod(bob_angle+(2*PI*delta*bob_speed), 2*PI);
#		wpn_pos.x += sin(bob_angle)*bob_length;
#		wpn_pos.y += -abs(cos(bob_angle))*bob_length;
#
#	else:
#		bob_angle = fmod(bob_angle+(2*PI*delta*0.25), 2*PI);
#		wpn_pos.y += sin(bob_angle)*bob_length*0.4;
#
##	wpn_pos = weapon.get_translation().linear_interpolate(wpn_pos, 5*delta);
##	weapon.set_translation(wpn_pos);
#
#func _input(ie):
#	if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
#		return;
#
#	if (ie.type == InputEvent.MOUSE_MOTION):
#		pitch = clamp(pitch-SENSITIVITY*ie.relative_y, -89, 89);
#		yaw = fmod(yaw-SENSITIVITY*ie.relative_x, 360.0);
#
#		origin.x = clamp(origin.x-(SENSITIVITY*ie.relative_x*bob_length), -bob_length*3.0, bob_length*3.0)
#		origin.y = clamp(origin.y+(SENSITIVITY*ie.relative_y*bob_length), -bob_length*3.0, bob_length*3.0);
#
#		update_camera();
#
#func give_recoil(recoil):
#	pitch += recoil.y;
#	yaw += recoil.x;
#
#	update_camera();
#
#func update_camera():
#	base.set_rotation_deg(Vector3(0, yaw, 0));
#	camera.set_rotation_deg(Vector3(pitch, 0, 0));
