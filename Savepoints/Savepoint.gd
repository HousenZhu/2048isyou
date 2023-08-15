class_name SavePoint
extends Area2D

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var spawned:bool = false;
var player:ScoreTile = null; #will be invalid after player splits
@export var saved:bool = false;

@export var id:int = 0; #unique id for each savepoint, except connected goals' ids must match
@export var spawn_point:Vector2;
@onready var game:Node2D = $"/root/Game";


func _ready():
	init_spawn_point();
	connect("body_entered", _on_body_entered);
	
	if id == GV.savepoint_id:
		spawn_player();
	elif GV.savepoint_id == -1 and id == GV.level_last_savepoint_ids[GV.current_level_index]:
		spawn_player();

func init_spawn_point():
	spawn_point = position;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level and not saved and not spawned: #save level
		game.current_level.current_snapshot.enter_savepoint = true;
		#game.current_level.remove_last_snapshot_if_not_meaningful();
		save_id_and_player_value(body);
		
		game.save_level(id);
		saved = true;

#if player was spawned, don't save until player starts action
func _on_player_start_action():
	if not GV.changing_level and not saved and spawned: #save level
		game.current_level.remove_last_snapshot_if_not_meaningful();
		save_id_and_player_value(player);
		
		game.save_level(id);
		saved = true;

func spawn_player(): #spawns player at spawn_point
	#print("SPAWN PLAYER AT SAVEPOINT ", id);
	spawned = true;
	player = score_tile.instantiate();
	player.is_player = true;
	player.power = GV.current_savepoint_powers.pop_back();
	player.ssign = GV.current_savepoint_ssigns.pop_back();
	player.snapshot_locations = GV.temp_player_snapshot_locations;
	player.snapshot_locations_new = GV.temp_player_snapshot_locations_new;
	player.position = spawn_point;
	#player.debug = true;
	game.current_level.get_node("ScoreTiles").add_child(player); #lv not ready yet, scoretiles not init
	player.start_action.connect(_on_player_start_action);

func save_id_and_player_value(player):
	GV.savepoint_id = id;
	GV.level_last_savepoint_ids[GV.current_level_index] = id;
	game.current_level.player_saved = player;
	GV.current_savepoint_ids.push_back(id);
	#current_savepoint_saves gets save in game.save_level()
	GV.current_snapshot_sizes.push_back(game.current_level.player_snapshots.size());
	GV.current_savepoint_powers.push_back(player.power);
	GV.current_savepoint_ssigns.push_back(player.ssign);
	GV.temp_player_snapshot_locations = player.snapshot_locations;
	GV.temp_player_snapshot_locations_new = player.snapshot_locations_new;

	GV.temp_tiles_snapshot_locations.clear();
	GV.temp_tiles_snapshot_locations_new.clear();
	for tile in game.current_level.scoretiles.get_children():
		if tile != player:
			GV.temp_tiles_snapshot_locations.push_back(tile.snapshot_locations);
			GV.temp_tiles_snapshot_locations_new.push_back(tile.snapshot_locations_new);
	
	GV.temp_baddies_snapshot_locations.clear();
	for baddie in game.current_level.baddies.get_children():
		GV.temp_baddies_snapshot_locations.push_back(baddie.snapshot_locations);
