extends CharacterBody2D

@onready var game:Node2D = $"/root/Game";
@onready var game_audio:Node2D = game.get_node("Audio");
@export var power:int = 0;

var focus:int = 0;
var slide_dir:Vector2 = Vector2.ZERO;


func _ready():
	if GV.player_snap:
		change_state("snap_idle");
	else:
		change_state("slide");

func _physics_process(delta):
	#releasing direction key loses focus
	if	focus and (\
		Input.is_action_just_released("ui_left") or\
		Input.is_action_just_released("ui_right") or\
		Input.is_action_just_released("ui_up") or\
		Input.is_action_just_released("ui_down")):
			focus = 0;
	
	#pressing direction key sets focus
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		focus = -1;
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		focus = 1;

func get_state() -> String:
	return $FSM.curState.name;

func change_state(s:String):
	$FSM.setState($FSM.states[s]);


func _on_physics_enabler_body_entered(body):
	if body is ScoreTile:
		body.set_process(true);
		body.set_physics_process(true);
		for i in range(1, 5):
			body.get_node("Ray"+str(i)).enabled = true;

func _on_physics_enabler_body_exited(body):
	if body is ScoreTile:
		body.set_process(false);
		body.set_physics_process(false);
		for i in range(1, 5):
			body.get_node("Ray"+str(i)).enabled = false;
