@tool
extends EditorPlugin

func _ready():
	pass
	
func generate():
	var highlighted_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	if len(highlighted_nodes) <= 0:
		print("rigid-collision-generator: no nodes selected!")
		return
	
	var meshes: Array = []
	
	for node in highlighted_nodes:
		if node is MeshInstance3D:
			meshes.append(node)
		else:
			continue
	
	for mesh in meshes:
		var node: MeshInstance3D = mesh
		
		var shape: ConvexPolygonShape3D = node.mesh.create_convex_shape(true, true)
		
		var rigid3d = RigidBody3D.new()
		
		var collision3d = CollisionShape3D.new()
		collision3d.shape = shape
		collision3d.transform = node.transform

		var scene = node.get_parent()

		# Create RigidBody3D
		rigid3d.name = "RigidBody3D__" + node.name
		
		node.get_parent().add_child(rigid3d, true);
		node.get_parent().move_child(rigid3d, node.get_index() + 1);
		rigid3d.set_owner(scene)

		rigid3d.add_child(collision3d, true)
		collision3d.set_owner(scene)

		scene.remove_child(node)
		rigid3d.add_child(node, true)
		node.set_owner(scene)
	pass

func _input(event):
	if Input.is_key_pressed(KEY_F10):
		generate()
