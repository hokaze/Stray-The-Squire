extends Node

onready var loading_scene = preload("res://screens/loading.tscn")

func _ready():
	load_scene("res://main.tscn")

func load_scene(next_screen) -> void:
	# add loading scene to the root then start loading the next screen
	var loading_inst = loading_scene.instance()
	get_tree().get_root().call_deferred("add_child", loading_inst)
	var loader = ResourceLoader.load_interactive(next_screen)
	
	if loader == null:
		print("loading.load_scene: loader is null")
		return

	#current_screen.queue_free()
	
	# brief delay to let loading screen itself load + appear
	yield(get_tree().create_timer(0.1),"timeout")
	var loading_bar = loading_inst.get_node("LoadingBar")
	var loading_amount = loading_inst.get_node("LoadingBar/HBox/Amount")

	# use poll() to grab chunks of data for the next scene
	while true:
		var error = loader.poll()
		# when we get a chunk of data
		if error == OK:
			# update the loading bar
			var progress = float(loader.get_stage())/loader.get_stage_count() * 100
			loading_bar.value = progress
			loading_amount.text = str(progress)
			yield(get_tree().create_timer(0.01),"timeout") # artifical wait time to test loading bar actually progresses
		# end of file, means we're done loading
		elif error == ERR_FILE_EOF:
			# load scene instance, add to root and remove the loading screen
			var scene = loader.get_resource().instance()
			get_tree().get_root().call_deferred("add_child",scene)
			loading_inst.queue_free()
			return
		else:
			# handle your error
			print('error occurred while loading chunks of data')
			return
