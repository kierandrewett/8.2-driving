extends Window

var input: LineEdit = null
var output: RichTextLabel = null

var history = []
var history_index = 0

func _ready():
	input = get_node("ConsoleContainer/ConsoleInput")
	output = get_node("ConsoleContainer/ConsoleTextContainer/ConsoleText")

	input.text = ""
	output.text = ""
	
	history.append(input.text)
	
	self.close()

func _process(delta):
	if Input.is_action_just_pressed("console"):
		if self.visible:
			self.close()
			GameUI.visible = false
		else:
			self.open()
			GameUI.visible = true

func open():
	self.visible = true
	input.grab_focus()

func close():
	self.visible = false

func log(msg):
	print(msg)
	output.text = output.text + str(msg) + "\n"

func execute_command(cmd):
	self.log("] %s" % [cmd])
	
	var command = cmd
	var args = []
	
	if cmd.find(" "):
		command = cmd.split(" ")[0]
		args = cmd.split(" ").slice(1)
		
	var i = 0
	for item in args:
		if item.length() == 0:
			args.remove_at(i)
		i = i + 1
		
	if command == "ent_fire":
		if args.size() < 1:
			self.log("Usage:\n    ent_fire <target> [action] [value] ")
			return
		
		var target = args[0]
		var action = null
		var values = []

		if args.size() > 1:
			action = args[1]
		
		values = args.slice(2)
			
		var targeted_node = Utils.get_node_by_name(target)
		
		if targeted_node == null:
			var matched = Utils.get_node_by_name(get_tree().root, target)
			
			if matched != null:
				targeted_node = matched
		
		if targeted_node == null and instance_from_id(int(target)):
			targeted_node = instance_from_id(int(target))
				
		if targeted_node == null:
			self.log("No target found by '%s'." % [target])
			return 1
		
		if action != null:
			if action in targeted_node:
				var typeof = typeof(targeted_node[action])
				
				# Function
				if typeof(typeof) == TYPE_STRING and typeof.ends_with("::%s" % [action]):
					self.log(targeted_node[action].call(values if values else []))
				else:
					if values.size() >= 1 and values[0] != null:
						var parsed
						
						if values[0].is_valid_int():
							parsed = int(values[0])
						elif values[0].is_valid_float():
							parsed = float(values[0])
						else:
							parsed = values[0]
						targeted_node[action] = parsed
						self.log("\"%s.%s\" = \"%s\"" % [targeted_node, action, parsed])
					else:
						self.log(targeted_node[action])
			else:
				self.log("No index '%s' on %s" % [action, targeted_node])
				return 1
			return 0
		else:
			self.log(targeted_node)
			return 0
	
	if command == "nmrecorder":
		if get_node("/root/GameUINavMeshRecorder"):
			get_node("/root/GameUINavMeshRecorder").visible = true
		else:
			Maps.load("res://ui/gameui_nav_mesh_recorder.tscn")
		
	if command == "host_timescale":
		if args.size() < 1:
			self.log("Usage:\n    host_timescale <timescale>")
			return
		
		var ts = args[0]
		
		Engine.time_scale = float(ts)
		
	if command in Globals and Globals[command] != null:
		if args.size() == 0:
			self.log("\"%s\" = \"%s\"" % [command, Globals[command]])
			self.log("No value provided to convar!")
		elif args.size() == 1:
			if args[0].is_valid_int():
				Globals[command] = int(args[0])
			elif args[0].is_valid_float():
				Globals[command] = float(args[0])
			else:
				Globals[command] = str(args[0])
		else:
			Globals[command] = args

func on_text_submitted(cmd):
	execute_command(cmd)
	history.append(cmd)
	history_index = len(history)
	input.text = ""

func on_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_UP and history_index > 0: # If up arrow is pressed
				history_index = (history_index - 1) % len(history) # Cycle through commands
				input.text = history[history_index]
			elif event.keycode == KEY_DOWN: # If down arrow is pressed
				history_index = (history_index + 1) % len(history) # Cycle through commands
				input.text = history[history_index]
			elif event.keycode == KEY_ENTER:
				history_index = len(history)

			if event.keycode == KEY_UP or event.keycode == KEY_DOWN:
				await get_tree().process_frame
				input.set_caret_column(input.text.length())
