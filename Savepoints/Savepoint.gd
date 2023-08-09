class_name SavePoint
extends Area2D

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var spawned:bool = false;
var saved:bool = false;

@export var id:int = 0; #unique id for each savepoint, except connected goals' ids must match
@export var spawn_point:Vector2;
@onready var game:Node2D = $"/root/Game";


func _ready():
	init_spawn_point();
	connect("body_entered", _on_body_entered);
	connect("body_exited", _on_body_exited);
	
	if id == GV.savepoint_id:
		spawn_player();
	elif GV.savepoint_id == -1 and id == GV.level_last_savepoint_ids[GV.current_level_index]:
		spawn_player();

func init_spawn_point():
	spawn_point = position;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level and not saved and not spawned: #save level
		save_id_and_player_value(body);
		
		game.save_level(id);
		saved = true;

func _on_body_exited(body):
	#check position to ensure body wasn't freed in add_level
	if body.is_in_group("player") and body.position != position and not GV.changing_level and not saved and spawned: #save level
		save_id_and_player_value(body);
		
		game.save_level(id);
		saved = true;

func spawn_player(): #spawns player at spawn_point
	print(id, " SPAWN PLAYER");
	spawned = true;
	var player = score_tile.instantiate();
	player.is_player = true;
	player.power = GV.player_power;
	player.ssign = GV.player_ssign;
	player.position = spawn_point;
	#player.debug = true;
	game.current_level.get_node("ScoreTiles").add_child(player); #lv not ready yet, scoretiles not init

func save_id_and_player_value(player):
	GV.savepoint_id = id;
	GV.level_last_savepoint_ids[GV.current_level_index] = id;
	game.current_level.player_saved = player;
	GV.player_power = player.power;
	GV.player_ssign = player.ssign;
