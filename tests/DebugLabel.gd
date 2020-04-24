extends Label

export(String) var listen_name = 'debug_label'

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalSignal.listen(listen_name, self, "_on_Debug_label")

func _on_Debug_label(data):
	text = String(data.text)