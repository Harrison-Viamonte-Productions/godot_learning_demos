extends CanvasModulate

const DARK = Color("0e0f40");
const NIGHTVISION = Color("1eb05e");

func _ready():
	add_to_group("interface");
	color = DARK;

func NightVision_mode():
	inform_NPCS("NightVision_mode");
	color = NIGHTVISION;
	$AudioStreamPlayer.stream = load(Global.nightvision_on_sfx);
	play_sfx();

func DarkVision_mode():
	inform_NPCS("DarkVision_mode");
	color = DARK;
	$AudioStreamPlayer.stream = load(Global.nightvision_off_sfx);
	play_sfx();

func play_sfx():
	$AudioStreamPlayer.play();

func inform_NPCS(vision_mode_func: String):
	get_tree().call_group("NPC", vision_mode_func);
