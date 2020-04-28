extends HBoxContainer

var pickup_amount = 0
var pickup_total = 0

func _ready():
  GlobalSignal.listen("pickup_collected", self, "_on_Pickup_collected")
  GlobalSignal.listen("pickup_created", self, "_on_Pickup_created")
  $Amount.text = String(pickup_amount)
  GlobalData.set("tomes", pickup_amount)

func _on_Pickup_collected(data):
  if data.type == "tome":
    pickup_amount += 1
    $Amount.text = String(pickup_amount)
    GlobalData.set("tomes", pickup_amount)

func _on_Pickup_created():
  pickup_total += 1
  $Total.text = String(pickup_total)
