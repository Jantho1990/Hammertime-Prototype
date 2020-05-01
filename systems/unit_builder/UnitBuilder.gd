extends Node

#export(Array, Array, String, FILE, "*.tscn") var buildable_units = []

# Path to directory containing buildable units.
export(String) var buildable_units_path = ''

# List of names of buildable units.
export(Array, String) var buildable_unit_names = []

var buildable_units = {}

# Called when the node enters the scene tree for the first time.
func _ready():
  GlobalSignal.listen('build_unit', self, '_on_Build_unit')
  
  if buildable_units_path.substr(buildable_units_path.length() - 1, 1) != '/':
    buildable_units_path = buildable_units_path + '/'
  
  # Preload all entites.
  for unit_name in buildable_unit_names:
    var path = buildable_units_path + unit_name + '/' + unit_name + '.tscn'
    var buildable_unit = load(path)
    buildable_units[unit_name] = buildable_unit
    GlobalSignal.dispatch('unit_loaded', { 'unit': buildable_unit })

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Build_unit(data):
  var unit_name = data.unit_name
  var unit_position = data.pos
  var unit_cost = data.cost
  
  if buildable_units.has(unit_name):
    var buildable_unit = buildable_units[unit_name]
    var unit = buildable_unit.instance()
    unit.energy_cost = unit_cost
    # if not Budget.can_afford(unit.budget_cost):
    #   print('cannot afford to build ', unit.name)
    #   GlobalSignal.dispatch('unit_cannot_afford', { 'unit': unit })
    #   return false
    Selection.select_entity(unit)
    GlobalSignal.dispatch("add_" + unit_name, {
      'entity': unit,
      'instance': false,
      'container_id': unit_name,
      'position': unit_position,
      'cost': unit_cost
    })
