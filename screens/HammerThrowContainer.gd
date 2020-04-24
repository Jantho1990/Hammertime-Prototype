extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  GlobalSignal.listen('hammer_thrown', self, '_on_hammer_thrown')
  GlobalSignal.listen('hammer_returned', self, '_on_hammer_returned')

func _on_hammer_thrown(data):
  var hammer = data.hammer
  hammer.position = hammer.global_position
  hammer.parent.remove_child(hammer)
  add_child(hammer)

func _on_hammer_returned(data):
  var hammer = data.hammer
  remove_child(hammer)
  hammer.parent.add_child(hammer)
  hammer.position = Vector2(0, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
