extends Node

#this node is spawned as child of the node (emplyer) who need being updated.

var task = 0
var employer


var delay = 0
const timeout = 10


const idx_task = {
			"ready"				:0,
			"nymph_request"		:1,
			"satyr_register"	:2,
			"end"				:3
			}

func _enter_tree():
	set_process(true)

func update(stuff):
	print("reset becouse we got something")
	delay = timeout*2#we got what we need, reset the timeout
	if task == idx_task["nymph_request"]:
		for i in range(employer.ny_srv_list.get_child_count()):#cleanup the list
			print("eliminating one")
			employer.ny_srv_list.get_child(i).queue_free()
		
#		var target = employer.get_node("server_list/container/listing_core")
#		print("target count: " +str(target.get_child_count()))
		for i in stuff:
			if i.has("ip"):
				if !i["ip"].is_valid_ip_address():
					continue
			else:
				continue
#			var button = employer.ny_select.get_node("sample_button").duplicate(DUPLICATE_SCRIPTS)
			var button = employer.ny_select.get_node("sample_button").duplicate(DUPLICATE_SCRIPTS)
			button.set_text(str(i))
			button.content = i
			button.show()
			button.set_anchor(MARGIN_RIGHT ,1)
			employer.ny_srv_list.add_child(button)
		employer.ny_srv_list.queue_sort()

func die():
	print("we're done")
	queue_free()

func _process(delta):
	if gamestate.active_tool != self:#
		queue_free()
	if delay <= 0:
		gamestate.ms.retrieve_server()
		delay = timeout
	else:
		delay -=1*delta
