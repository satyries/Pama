tool
extends EditorImportPlugin
func get_importer_name():
	return "my.special.plugin"

func get_visible_name():
	return "Special Mesh Importer"

func get_recognized_extensions():
	return ["special", "spec"]

func get_save_extension():
	return "mesh"

func get_resource_type():
	return "Mesh"

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_optons(i):
	return [{"name": "my_option", "default_value": false}]

func load(src, dst, opts, r_platform_variants, r_gen_files):
	var f = File.new()
	if f.open(src, File.READ) != OK:
		return FAILED

	var mesh = Mesh.new()

	var save = dst + "." + get_save_extension()
	ResourceSaver.save(file, mesh)
	return OK
