extends Spatial

const SENSITIVITY = 0.3;
#to do:
#reset_rotary switch = separate task in process.stop animation, interpolate vector3 of rotary
#animation set from cubic frame
onready var player	= get_node("..")
onready var base	= get_node("base")
onready var camera	= get_node("base/rotary/camera")
onready var raycast	= get_node("base/rotary/camera/ray")
onready var rotary = get_node("base/rotary")
#onready var camera	= get_node("base/camera")
#onready var raycast	= get_node("base/camera/ray")

var rset_rotary_switch = false

var pending_processes = {}

var pitch = 0.0;
var yaw = 0.0;
var origin = Vector3();


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
#	print("pending process each cycle: " + str(pending_processes.size()))
	if rset_rotary_switch:
		var straight = Vector3(0,0,0)
		var rota_deg = rotary.get_rotation_deg()
		
		if rota_deg.distance_to(straight) > 0.01:#riduci
			rota_deg = rota_deg.linear_interpolate(straight, 0.1)

			rotary.set_rotation_deg(rota_deg) 
		else:
			rotary.set_rotation_deg(straight)
			rset_rotary_switch = false
			if pending_processes.has("reset_rotary"):
				print("erasing the request")
				pending_processes.erase("reset_rotary")
#			print("last check: " + str(pending_processes.size()))
			set_process(false)
	if pending_processes.size() <= 0:#nothing else to do
#		print("stopped for no operations")
		set_process(false)



func _ready():
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


func _enter_tree():
	get_node("..").camera = self

func _exit_tree():
	if player.human_control:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);



func _input(ie):
	if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
		return

	if ie.is_class("InputEventMouseMotion"):
#		pitch = clamp(pitch-SENSITIVITY*ie.relative.y, -89, 89)
		pitch = clamp(pitch-SENSITIVITY*ie.relative.y, -80, 80)
		yaw = fmod(yaw-SENSITIVITY*ie.relative.x, 360.0)

#		origin.x = clamp(origin.x-(SENSITIVITY*ie.relative_x*bob_length), -bob_length*3.0, bob_length*3.0)
#		origin.y = clamp(origin.y+(SENSITIVITY*ie.relative_y*bob_length), -bob_length*3.0, bob_length*3.0);
		update_camera()

func update_camera():
	player.yaw = yaw
	base.set_rotation_deg(Vector3(0, yaw, 0));
	camera.set_rotation_deg(Vector3(pitch, 0, 0));
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
