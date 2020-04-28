extends HBoxContainer

var pickup_amount = 0

func _ready():
  GlobalSignal.listen("pickup_collected", self, "on_Pickup_collected")
  $Amount.text = String(pickup_amount)
  GlobalData.set("tomes", pickup_amount)

func on_Pickup_collected(data):
  if data.type == "tome":
    pickup_amount += 1
    $Amount.text = String(pickup_amount)
    GlobalData.set("tomes", pickup_amount)
