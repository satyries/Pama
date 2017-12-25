tool # needed so it runs in editor
extends EditorScenePostImport

func post_import(scene):
	# do your stuff here

	var anim_player = scene.get_node("AnimationPlayer")
	var anim_list = anim_player.get_animation_list()
#	for anim in anim_player.get_animation_list():
#
#		print("anim is: " +str(anim))
	if anim_player.has_animation("idle"):
		anim_player.get_animation("idle").set_loop(true)
		anim_player.set_autoplay("idle")

	if anim_player.has_animation("run"):
		anim_player.get_animation("run").set_loop(true)
	if anim_player.has_animation("sneak"):
		anim_player.get_animation("sneak").set_loop(true)
#

#	for child in scene.get_children():
#		print("child is: " + str(child))
	return scene # remember to return the imported scene
