extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var surface = []
	surface.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_TEX_UV] = uvs
	surface[Mesh.ARRAY_NORMAL] = normals
	surface[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
