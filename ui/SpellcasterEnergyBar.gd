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
  GlobalSignal.listen('set_energy', self, '_on_Set_energy')
  GlobalSignal.listen('energy_change', self, '_on_Energy_change')
  GlobalSignal.listen('reduce_energy', self, '_on_Reduce_energy')
  GlobalSignal.listen('increase_energy', self, '_on_Increase_energy')

func _physics_process(_delta):
  GlobalSignal.dispatch('debug_label', { 'text': EnergyBar.value })
  GlobalSignal.dispatch('debug_label2', { 'text': EnergyBar.value > (EnergyBar.max_value - ReductionBar.value) })
  if EnergyBar.value > (EnergyBar.max_value - ReductionBar.value):
    EnergyBar.value = ReductionBar.value

func _on_Set_energy(data):
  if data.has('energy'):
    var energy = data.energy
    EnergyBar.value = energy
  
  if data.has('max_energy'):
    var max_energy = data.max_energy
    EnergyBar.max_value = max_energy
  
  if data.has('min_energy'):
    var min_energy = data.min_energy
    EnergyBar.min_value = min_energy

  if data.has('reduction'):
    var reduction = data.reduction
    ReductionBar.value = reduction
  
  if data.has('max_reduction'):
    var max_reduction = data.reduction
    ReductionBar.max_value = max_reduction
  
  if data.has('min_reduction'):
    var min_reduction = data.min_reduction
    ReductionBar.min_value = min_reduction

func _on_Energy_change(data):
  var energy = data.energy
  EnergyBar.value = energy

func _on_Reduce_energy(data):
  var reduction = data.amount
  ReductionBar.value += reduction
  # EnergyBar.max_value = ReductionBar.value

func _on_Increase_energy(data):
  var increase = data.amount
  ReductionBar.value -= increase
  # EnergyBar.max_value = ReductionBar.value
