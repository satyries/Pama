extends Control

var end_condition
var timeout = 0
var message = ""
func _enter_tree():
	if end_condition == 2:
		get_node("message").text = message
	set_process(true)
	

func _process(delta):
	if end_condition != 0:
		is_not_end(delta)
		return

	var opacity = get_modulate()
	opacity.a -= 1*delta
	if opacity.a < 0:
		queue_free()
	else:
		set_modulate(opacity)



func is_not_end(delta):
	if end_condition == 1:
		print("processing problem")
		if TranslationServer.get_locale() == "en":
			var msg = TranslationServer.translate("SYS_WARN_TRANSLATION")
			get_node("message").text = msg
			end_condition = 0
		
	elif end_condition == 2:#just basic timeout
		timeout -= 1*delta
		if timeout <= 0:
			end_condition = 0
