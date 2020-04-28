# tool not working
extends Node2D

# Hard dependency on being a child of a node that has a tilemap child that generates a container for collision areas
onready var tile_map = get_parent().get_node('TileMap')

var tile_color = Color(1, 1, 0, 0.25)

onready var atlas_tile_collisions = get_atlas_tile_collisions()

func get_atlas_tile_collisions():
	var ret = []
	var tiles = tile_map.tile_set.get_tiles_ids()
	for tile in tiles:
		var tile_shapes = tile_map.tile_set.tile_get_shapes(tile)
		for shape in tile_shapes:
			var atlas_tile = shape.autotile_coord
			ret.push_back(atlas_tile)
		return ret 

func _process(delta):
  if Engine.editor_hint:
    print('running')
    generate_collision_areas()
  update()

func _draw():
  if 'show_collision_areas' in tile_map and tile_map.show_collision_areas:
    draw_rect(Rect2(Vector2(-32, -32), Vector2(64, 64)), tile_color, true)

var collision_area_container
func generate_collision_areas():
  print('HI')
  
  collision_area_container = Node2D.new()
  
  var used_cells = tile_map.get_used_cells()
  for i in range(0, used_cells.size()):
    var cell = used_cells[i]
    if valid_collision_area_location(cell):
      var area2d = preload('res://maps/TilemapCollisionArea.tscn').instance()
      area2d.position = (cell * tile_map.cell_size) + tile_map.cell_size / 2
      area2d.tile_map = tile_map
      collision_area_container.add_child(area2d)
  
  add_child(collision_area_container)

func valid_collision_area_location(cell):
	var atlas_tile = tile_map.get_cell_autotile_coord(cell.x, cell.y)
	if atlas_tile_collisions.has(atlas_tile):
		return true
	return false