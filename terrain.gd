@tool
extends MeshInstance3D

#const size := 256.0
@export var height := 10.0
@export var width := 256
@export var depth := 1536

var minX
var maxX
var minZ
var maxZ

@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		updateMesh()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateMesh()

@export var noise: FastNoiseLite:
	set(new_noise):
		noise = new_noise
		updateMesh()
		if noise:
			noise.changed.connect(updateMesh)

func getHeight(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y) * height + log(abs(x / 2)) * 20 - 50

func getNormal(x: float, y: float) -> Vector3:
	var epsilon := width / resolution
	var normal := Vector3(
		(getHeight(x + epsilon, y) - getHeight(x - epsilon, y)) / (2.0 * epsilon),
		1.0,
		(getHeight(x, y + epsilon) - getHeight(x, y - epsilon)) / (2.0 * epsilon),
	)
	return normal.normalized()

func shift() -> void:
	position.z += 128
	updateMesh()

func updateMesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution 
	plane.subdivide_width = resolution * (depth / width)
	plane.size = Vector2(width, depth)
	
	var planeArrays := plane.get_mesh_arrays()
	var vertexArray : PackedVector3Array = planeArrays[ArrayMesh.ARRAY_VERTEX]
	var normalArray : PackedVector3Array = planeArrays[ArrayMesh.ARRAY_NORMAL]
	var tangentArray : PackedFloat32Array = planeArrays[ArrayMesh.ARRAY_TANGENT]
	
	for i:int in vertexArray.size():
		var vertex := vertexArray[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = getHeight(vertex.x, vertex.z + position.z)
			normal = getNormal(vertex.x, vertex.z + position.z)
			tangent = normal.cross(Vector3.UP)
		vertexArray[i] = vertex
		normalArray[i] = normal
		tangentArray[4 * i] = tangent.x
		tangentArray[4 * i + 1] = tangent.y
		tangentArray[4 * i + 2] = tangent.z + position.z
		
	var arrayMesh := ArrayMesh.new()
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, planeArrays)
	mesh = arrayMesh
