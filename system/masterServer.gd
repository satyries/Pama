extends HTTPRequest

const idx_srv = {
		"name"		: 0,#name of the satyr/server
		"ip"		: 1,#it's ip
		"ut"		: 2#the unix time of the contact (www server manage this)
		}



signal server_registered()
signal server_retrieved(servers)

const MS_URL = "http://localhost:8000/"
#const MS_URL = "http://pama.mygamesonline.org/ms/"

const TASK_NONE = 0
const TASK_RETRIEVE = 1
const TASK_REGISTER = 2

var currentTask = TASK_NONE

func _enter_tree():
	gamestate.ms = self

func _ready():
	set_use_threads(true)
	connect("request_completed", self, "on_request_completed")


func register_server(port, name, con_players):
	currentTask = TASK_REGISTER
	cancel_request()
	request(MS_URL+"?do=register&name="+str(name)+"&players="+str(con_players))


func unregister_server():
	currentTask = TASK_NONE
	cancel_request()
	request(MS_URL+"?do=ingame")

func retrieve_server():
	currentTask = TASK_RETRIEVE
	
	cancel_request()
	print(MS_URL+"index.php?do=lists")
#	request(MS_URL+"?do=lists&search="+str(filter).percent_encode());
#	print(MS_URL + "?do=list&search=" + str("").percent_encode())
#	request(MS_URL+"index.php?do=lists")
	request(MS_URL+"index.php?do=lists")


func failed_retrieve():
	print("something went wrong while retrieving list")

func on_request_completed(result, response_code, headers, body):
	if (result != HTTPRequest.RESULT_SUCCESS):
		return
	

	if (currentTask == TASK_RETRIEVE):
		var string = parse_json(body.get_string_from_utf8())
		for i in string:
			print(i["ip"])
#			print("ip is: " +str(i))
#			print("content is: " +str(string[i]))
	
	return

	if (currentTask == TASK_RETRIEVE):
		var string = parse_json(body.get_string_from_utf8())
		var servers = []
		for i in string:
			if str(i[idx_srv["ip"]]).is_valid_ip_address():
				var size = servers.size()
				servers.resize(size+1)
				servers[size] = i
			else:
				print("the other string is not valid")
#		var sub_value = []
#		for i in servers
#		var sub_value = 

#		for i in range(servers.size()):
#
#			for a in range(string[i].size()):
#				print("i is: " +str(i))
#				print("a is: " +str(a))

#		print("string: " +str(string[3]))
#		print("servers: " +str(servers))
#		print("servers: " +str(servers[0]))
#		print("size of servers: " +str(servers.size()))
#		print("ip: " +str(servers["ip"]))
#		for s in servers:
#			print(servers[s])
#			print("this: "+ str(s))
#		print(servers["name"])
#		emit_signal("server_retrieved", servers)
	
	if (currentTask == TASK_REGISTER):
		emit_signal("server_registered")
