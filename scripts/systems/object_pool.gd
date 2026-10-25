extends Node
## ObjectPool — generic pooled-spawner for reusable instances.
##
## Purpose: avoid per-shot instantiation overhead and keep the scene
## stable across long runs. Currently used by Bullet spawning (required).
##
## Usage:
##     var pool = ObjectPool.new(ResourcePool, template_node)  # or by scene path
##     var instance = pool.spawn()
##     instance.free()  # returns to pool

enum PoolType { RESOURCE, SCENE }

class Instance:
	var node: Node
	var _template: Node
	var _resource: Resource

	func _ready() -> void:
		if _template != null:
			node = _template.duplicate()
			node.visible = true
			node.set_name(_template.get_name())

	func activate() -> void:
		node.get_parent().call_deferred("add_child(node)")
		node.visible = true

	func deactivate() -> void:
		node.visible = false
		node.get_parent().call_deferred("remove_child(node)")

	func free() -> void:
		node.queue_free()

var _type: PoolType
var _templates: Array[Node]
var _resources: Array[Resource]
var _available: Array[Instance]
var _active: Array[Instance]
var _scene_path: String

signal spawned(instance: Node)
signal returned(instance: Node)

func _init(p_type: PoolType, template: Variant = null, resources: Array[Resource] = []) -> void:
	_type = p_type
	if template is Node:
		_templates.append(template.duplicate())
	elif template is PackedScene:
		_scene_path = template.resource_path
	elif template is String:
		_scene_path = template
	for r in resources:
		_resources.append(r)
		_templates.append(_make_from_resource(r))

func _make_from_resource(r: Resource) -> Node:
	# Default: create an empty Node if the resource provides nothing.
	return Node.new()

func spawn(args: Variant = null) -> Node:
	var instance: Instance
	if _available.size() > 0:
		instance = _available.pop_back()
		instance.activate()
	else:
		var node: Node
		if _templates.size() > 0:
			node = _templates[0].duplicate()
			node.visible = true
			node.set_name(_templates[0].get_name())
		elif _scene_path != "":
			var sc: PackedScene = load(_scene_path)
			node = sc.instantiate()
		else:
			node = Node.new()
		instance = Instance.new()
		instance.node = node
		instance._template = node
		_active.append(instance)
	spawned.emit(node)
	return node

func _return_to_pool(instance: Instance) -> void:
	instance.deactivate()
	_active.erase(instance)
	_available.append(instance)
	returned.emit(instance.node)

func return_to_pool(node: Node) -> void:
	for i in _active.size() - 1:
		if _active[i].node == node:
			_return_to_pool(_active[i])
			return

func return_all() -> void:
	for i in _active.size() - 1:
		_active[i].deactivate()
	_available.append_array(_active)
	_active.clear()

func get_active_count() -> int:
	return _active.size()

func get_available_count() -> int:
	return _available.size()

# --- Bullet convenience API (required by Phase 0) ---
func setup_bullets(scene: PackedScene) -> void:
	var template = scene.instantiate()
	_templates.append(template)

func spawn_bullet(position: Vector2, direction: Vector2) -> Node:
	var b = spawn() as Area2D
	b.position = position
	b.velocity = direction
	b.set_meta("is_bullet", true)
	return b
