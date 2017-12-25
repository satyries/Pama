extends Node

var node_requesting#node_requesting must have "echo_ip" with ourselves. otherwise we will suicide
var target_label#
var stage = 0
var death_timeout = 15#if in 15 sec we didn't our job, we're probably forgotten = die
var status = 0

onready var err = 0
onready var http = HTTPClient.new()
onready var headers=["User-Agent: Pirulo/1.0 (Godot)","Accept: */*"]
onready var rb = PoolByteArray()

var delay = [0.2, 0.2]
var delay_switch = false


func _ready():
	err = http.connect_to_host("ipecho.net", 80, false)
	if err!=OK:
		queue_free()
	stage = 1
	set_process(true)
	delay_switch = true


func processing(delta):
#	var status = http.get_status()
	http.poll()
	if (stage == 1) and !delay_switch:
		delay_switch = true
		if status==HTTPClient.STATUS_CONNECTED:
			stage = 2
			err = http.request(HTTPClient.METHOD_GET,"/plain",headers) # Request a page from the site (this one was chunked..)
			if err!=OK:
				die()
	elif (stage == 2) and !delay_switch:
		delay_switch = true
		if status == HTTPClient.STATUS_BODY:
			stage = 3
	elif (stage == 3) and !delay_switch:
		delay_switch = true
		var chunk = http.read_response_body_chunk() # Get a chunk
		if (chunk.size()!=0):
			rb = rb + chunk # Append to read buffer
		if status == HTTPClient.STATUS_CONNECTED:
			var text = rb.get_string_from_ascii()
			if text.is_valid_ip_address():
				node_requesting.external_ip = text
				if target_label != null:
					target_label.set_text(text)
			die()



func _process(delta):
	status = http.get_status()

	if delay_switch:
		if delay[0] <= 0:#countdown to zero = reset and disable the delay switch
			delay_switch = false
			delay[0] = delay[1]
		else:
			delay[0] -= 1*delta
	else:
		processing(delta)
	if death_timeout >= 0:
		death_timeout -=1*delta
	else:
		die()
	if node_requesting.echo_ip != self:
		die()
	if status == HTTPClient.STATUS_CANT_RESOLVE:
		die()
	if status == HTTPClient.STATUS_CANT_CONNECT:
		die()
	if status == HTTPClient.STATUS_CANT_CONNECT:
		die()

func die():
	if node_requesting.echo_ip == self:
		node_requesting.echo_ip = null
	
#	target_label.set_text("127.0.0.1")
	queue_free()