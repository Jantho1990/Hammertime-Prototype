extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var EnergyBar
var ReductionBar

# Called when the node enters the scene tree for the first time.
func _ready():
  EnergyBar = $EnergyBar
  ReductionBar = $ReductionBar
  GlobalSignal.listen('energy_change', self, '_on_Energy_change')


func _on_Energy_change(data):
  var energy = data.energy
  EnergyBar.value = energy
