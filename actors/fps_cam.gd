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
var camera_timeout = [0,0.02]#timer+reset time

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
const neck_bend = 0.08
var yaw = 0.0
var origin = Vector3()

onready var fx_stunt = preload("res://actors/camera_fx/stunt.tres")

func reset_rotary():#currently not used
	print("rset rotary is supposed to be unused")
	rset_rotary_switch = true
	if pending_processes.has("reset_rotary"):
		pass#there was another rotary reset ongoing, 
	else:
		pending_processes["reset_rotary"] = true
#	print("pending process at request: " + str(pending_processes.size()))
	get_node("anim").stop(true)
	if !is_processing():
		set_process(true)

func cinematic_request(request):
#	print("camera got the request")
	if request == "stun":
		camera.set_environment(fx_stunt)
	player.cinematic = true



func end_cinematic():
	camera.set_rotation_deg(Vector3(0, 0, 0))
	camera.set_environment(null)
	rotary.set_rotation_deg(Vector3(0, 0, 0))
	player.cinematic = false

func _process(delta):
	if camera_timeout[0] <= 0:#this update the camera even when there's no mouse input (when camera needs to move for cinematic or other non-interactive stuff)
		camera_timeout[0] = camera_timeout[1]
#		print("updating")
		if player.cinematic:
			update_cine_camera(0,0)
		else:
			update_game_camera()
	else:
		camera_timeout[0] -= 1*delta


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
	
	var turnfix = get_node("../feetpos").get_rotation()
	model.set_rotation(turnfix)
	skeleton_ratio = skeleton.get_parent().get_scale()[0]

func _enter_tree():
	player	= get_node("..")
	base	= get_node("base")
	camera	= get_node("base/rotary/camera")
	raycast	= get_node("base/rotary/camera/ray")
	rotary = get_node("base/rotary")
	get_node("..").camera = self
		


func _exit_tree():
	if player.human_control:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);



func _input(ie):
	if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
		return

	if ie.is_class("InputEventMouseMotion"):
		if player.cinematic:
			var req_pitch = SENSITIVITY*ie.relative.y
			var req_yaw = fmod(SENSITIVITY*ie.relative.x, 360.0)
			update_cine_camera(req_yaw,req_pitch)
		else:
			pitch = clamp(pitch-SENSITIVITY*ie.relative.y, -pitch_limit, pitch_limit)
			yaw = fmod(yaw-SENSITIVITY*ie.relative.x, 360.0)
			update_game_camera()

func update_cine_camera(req_yaw,req_pitch):
	var rot_yaw = rotary.get_rotation_deg().y-req_yaw
	var rot_pitch = camera.get_rotation_deg().x-req_pitch
	rot_yaw = clamp(rot_yaw, -player.cinematic_lock[1], player.cinematic_lock[1])
	rot_pitch = clamp(rot_pitch, -player.cinematic_lock[1], player.cinematic_lock[1])
	if (req_yaw == 0) and (req_pitch == 0):
		rot_yaw = lerp(rot_yaw, 0, 0.1)
		rot_pitch = lerp(rot_pitch, 0, 0.1)
	else:
		camera_timeout[0] = 0.1
	camera.set_rotation_deg(Vector3(rot_pitch, 0, 0))
	rotary.set_rotation_deg(Vector3(0,rot_yaw,0))

	var camerapos = camera.get_transform()
	var eye_position = skeleton.get_bone_global_pose(eye_bone).origin.reflect(Vector3(0,1,0))*skeleton_ratio
	camerapos.origin = camerapos.origin.linear_interpolate(eye_position, 0.1)
	camera.set_transform(camerapos)


func update_game_camera():
	camera_timeout[0] = camera_timeout[1]
	
	base.set_rotation_deg(Vector3(0, yaw, 0))
	player.yaw = yaw
	camera.set_rotation_deg(Vector3(pitch, 0, 0))
	var camerapos = camera.get_transform()

	#fixes for the eyeposition (which is a bone on the armature)
	#1:armature is scaled: fix is *skeleton_ratio
	#2:the model is rotated, but the armature ignore this, apply additional rotation "reflect(Vector3(0,1,0)"
	var eye_position = skeleton.get_bone_global_pose(eye_bone).origin.reflect(Vector3(0,1,0))*skeleton_ratio
	camerapos.origin = camerapos.origin.linear_interpolate(eye_position, 0.1)

	
	if pitch < 0:#simulating the neck bend when someone lock down
#					eyes move slightly forward on y axis when you bend your head down
		var neck_twist = (abs(pitch)/pitch_limit)*neck_bend
		camerapos.origin.z = -neck_twist
	else:
		camerapos.origin.z = 0
	camera.set_transform(camerapos)
