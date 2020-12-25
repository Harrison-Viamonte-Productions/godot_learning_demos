extends TextureButton

func _ready():
	self.connect("pressed", self, "_on_pressed");

func _on_pressed():
	get_tree().change_scene(Global.Level1);
