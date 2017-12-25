extends Spatial

var position = Vector3(0,0,0)

var myself
onready var camera = Camera.new()

func _enter_tree():
	set_translation(position)


func _ready():
	if !(is_network_master()):
		var material = SpatialMaterial.new()
#		var material = myself.get_node("mesh").get_surface_material(0)
		var color = material.get_albedo()
		color.r = 255
		material.set_albedo(color)
		get_node("mesh").set_surface_material(0, material)
	_player_creation()
	set_process(true)

func _process(delta):
	var rot = get_rotation()
	rot.y += 1*delta
	set_rotation(rot)
	
func _player_creation():
	camera.set_translation(get_node("campos").get_translation())
	add_child(camera)
	camera.make_current()

func set_player_name(name):#TODO
	gamestate.gui.get_node("ingame/name").set_text(name)
	return
	get_node("player_name").set_text(name)
	get_node("player_name").hide()

func my_initiation():#this is not in sync
	if !(is_network_master()):
		var material = self.get_node("mesh").get_surface_material(0)
		var color = material.get_albedo()
		color.r = 255
		material.set_albedo(color)
	#		hide()

#
#const MOTION_SPEED = 90.0
#
#slave var slave_pos = Vector2()
#slave var slave_motion = Vector2()
#
#export var stunned = false
#
## Use sync because it will be called everywhere
#sync func setup_bomb(name, pos, by_who):
#	var bomb = preload("res://bomb.tscn").instance()
#	bomb.set_name(name) # Ensure unique name for the bomb
#	bomb.position=pos
#	bomb.owner = by_who
#	# No need to set network mode to bomb, will be owned by master by default
#	get_node("../..").add_child(bomb)
#
#var current_anim = ""
#var prev_bombing = false
#var bomb_index = 0
#
#func _fixed_process(delta):
#	var motion = Vector2()
#
#	if (is_network_master()):
#		if (Input.is_action_pressed("move_left")):
#			motion += Vector2(-1, 0)
#		if (Input.is_action_pressed("move_right")):
#			motion += Vector2(1, 0)
#		if (Input.is_action_pressed("move_up")):
#			motion += Vector2(0, -1)
#		if (Input.is_action_pressed("move_down")):
#			motion += Vector2(0, 1)
#
#		var bombing = Input.is_action_pressed("set_bomb")
#
#		if (stunned):
#			bombing = false
#			motion = Vector2()
#
#		if (bombing and not prev_bombing):
#			var bomb_name = get_name() + str(bomb_index)
#			var bomb_pos = position
#			rpc("setup_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())
#
#		prev_bombing = bombing
#
#		rset("slave_motion", motion)
#		rset("slave_pos", position)
#	else:
#		position=slave_pos
#		motion = slave_motion
#
#	var new_anim = "standing"
#	if (motion.y < 0):
#		new_anim = "walk_up"
#	elif (motion.y > 0):
#		new_anim = "walk_down"
#	elif (motion.x < 0):
#		new_anim = "walk_left"
#	elif (motion.x > 0):
#		new_anim = "walk_right"
#
#	if (stunned):
#		new_anim = "stunned"
#
#	if (new_anim != current_anim):
#		current_anim = new_anim
#		get_node("anim").play(current_anim)
#
#	# FIXME: Use move_and_slide
#	move_and_slide(motion*MOTION_SPEED)
#	if (not is_network_master()):
#		slave_pos = position # To avoid jitter
#
#slave func stun():
#	stunned = true
#
#master func exploded(by_who):
#	if (stunned):
#		return
#	rpc("stun") # Stun slaves
#	stun() # Stun master - could use sync to do both at once
#
#
#func _ready():
#	stunned = false
#	slave_pos = position
