@tool
extends MeshInstance3D

#const size := 256.0
@export var height := 10.0
@export var width := 256
@export var depth := 2048

@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		updateMesh()

# Called when the node enters the scene tree for the first time.
func ready() -> void:
	updateMesh()

@export var noise: FastNoiseLite:
	set(new_noise):
		noise = new_noise
		updateMesh()
		if noise:
			noise.changed.connect(updateMesh)

func getHeight(x: float, y: float) -> float:
	var riverCenter = 90 * sin(y / 200)
	
	var noiseBase := noise.get_noise_2d(x, y) * height
	var ridgeFactor = log(abs((x - riverCenter) / 3)) * 20
	if (ridgeFactor < -8):
		ridgeFactor = -8
	var barrierFactor = abs((x - riverCenter) / 3.5)
	var sinkConst = -60
	
	var subtotal = noiseBase + ridgeFactor + barrierFactor + sinkConst

	if (subtotal < 0):
		return 0

	return subtotal

func getNormal(x: float, y: float) -> Vector3:
	var epsilon : float = float(width) / float(resolution)
	var normal := Vector3(
		(getHeight(x + epsilon, y) - getHeight(x - epsilon, y)) / (2.0 * epsilon),
		1.0,
		(getHeight(x, y + epsilon) - getHeight(x, y - epsilon)) / (2.0 * epsilon),
	)
	return normal.normalized()


var minZ = -128
func shift() -> void:
	minZ += 512
	updateMesh()

func updateMesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution 
	plane.subdivide_width = resolution * (depth / width)
	plane.size = Vector2(width, depth)
	plane.center_offset = Vector3(0, 0, minZ)
	
	var planeArrays := plane.get_mesh_arrays()
	var vertexArray : PackedVector3Array = planeArrays[ArrayMesh.ARRAY_VERTEX]
	var normalArray : PackedVector3Array = planeArrays[ArrayMesh.ARRAY_NORMAL]
	var tangentArray : PackedFloat32Array = planeArrays[ArrayMesh.ARRAY_TANGENT]
	
	for i:int in vertexArray.size():
		var vertex := vertexArray[i]
		vertex.z += position.z
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = getHeight(vertex.x, vertex.z)
			normal = getNormal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertexArray[i] = vertex
		normalArray[i] = normal
		tangentArray[4 * i] = tangent.x
		tangentArray[4 * i + 1] = tangent.y
		tangentArray[4 * i + 2] = tangent.z
		
	var arrayMesh := ArrayMesh.new()
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, planeArrays)
	mesh = arrayMesh
	
	create_trimesh_collision()
