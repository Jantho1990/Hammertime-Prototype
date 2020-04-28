extends Area2D

var width setget ,width
var height setget ,height

func _ready():
	self.connect("body_entered", self, "_on_Body_entered")

func _physics_process(delta):
	position.y += sin(global.run_time / 0.1) * 0.35

func _on_Body_entered(body):
	if body.name == "Player":
		queue_free()
		GlobalSignal.dispatch("pickup_collected", {
			"type": "tome"
		})

func spawn_acceptable(tilemap, pos):
	var cell = tilemap.world_to_map(pos)
	var above = tilemap.tile_above_pos(pos)
	var below = tilemap.tile_below_pos(pos)
	
	var map = tilemap.get_parent()
	for child in map.get_children():
		if child.get("position") != null:
			if pos == child.position:
				return false
	
	if tilemap.get_cell(above.x, above.y) == -1 \
		and tilemap.get_cell(cell.x, cell.y) == -1 \
		and tilemap.get_cell(below.x, below.y) != -1:
			return true
	return false

func height():
	return $CollisionShape2D.shape.extents.y * 2

func width():
	return $CollisionShape2D.shape.extents.x * 2