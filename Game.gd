extends Node2D

@onready var GV:Node = $"/root/GV";

@onready var fader:AnimationPlayer = $"Overlay/AnimationPlayer";
@onready var right_sidebar:VBoxContainer = $"GUI/HBoxContainer/RightSideBar";
@onready var mode_label:Label = right_sidebar.get_node("MoveMode");

@onready var combine_sound = $"Audio/Combine";
@onready var slide_sound = $"Audio/Slide";
@onready var split_sound = $"Audio/Split";
@onready var shift_sound = $"Audio/Shift";

var current_level:Node2D;
var current_level_name:Label;
var levels = [];
var level_saves = [];
var current_savepoint_ids = []; #in the order visited
var current_savepoint_saves = []; #in the order visited
var next_level_index:int;


func _ready():
	#load levels
	level_saves.resize(GV.LEVEL_COUNT);
	
	for i in range(GV.LEVEL_COUNT):
		levels.append(load("res://Levels/Level "+str(i)+".tscn"));
	add_level(GV.current_level_index);
	
	#init mode label
	change_move_mode(GV.player_snap);
	
	#testing


func _input(event):
	if event.is_action_pressed("change_move_mode") and GV.abilities["move_mode"]:
		change_move_mode(not GV.player_snap);
		
		#update player(s) state
		for player in current_level.players:
			var state = player.get_state();
			if state not in ["merging1", "merging2", "combining", "splitting"]:
				var next_state = "snap" if GV.player_snap else "slide";
				player.change_state(next_state);


#defer this until previous level has been freed
func add_level(n):
	var level:Node2D;
	print("current_savepoint_saves.size: ", current_savepoint_saves.size());
	if GV.reverting and current_savepoint_ids:
		print("LOAD FROM SAVEPOINT");
		GV.savepoint_id = current_savepoint_ids.pop_back();
		var packed_level = current_savepoint_saves.pop_back();
		level_saves[n] = packed_level; #rollback level save to savepoint
		level = packed_level.instantiate();
		GV.current_level_from_save = true;
	elif GV.reverting: #and current_savepoint_ids empty
		print("LOAD FROM INITIAL");
		level_saves[n] = null;
		#clear last savepoint id
		GV.level_last_savepoint_ids[n] = -1;
		
		GV.savepoint_id = GV.level_initial_savepoint_ids[n];
		GV.player_power = GV.level_initial_player_powers[n];
		GV.player_ssign = GV.level_initial_player_ssigns[n];
		level = levels[n].instantiate();
		GV.current_level_from_save = false;
	elif level_saves[n]:
		print("LOAD FROM SAVE");
		level = level_saves[n].instantiate();
		GV.current_level_from_save = true;
	else:
		print("NO SAVE FOUND");
		level = levels[n].instantiate();
		GV.current_level_from_save = false;
	
	current_level = level;
	
	#remove and free saved player
	var player_saved = current_level.player_saved;
	if is_instance_valid(player_saved):
		current_level.get_node("ScoreTiles").remove_child(current_level.player_saved);
		player_saved.free();
	
	add_child(level);
	GV.changing_level = false;
	
	#update right sidebar visibility
	#right_sidebar.visible = true if n else false;

#update current level and current level index
func change_level(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	
	current_level.queue_free();
	call_deferred("add_level", n);
	GV.current_level_index = n;
	
	#clear saves for old level
	if not GV.reverting:
		current_savepoint_ids.clear();
		current_savepoint_saves.clear();

func change_level_faded(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	next_level_index = n;
	
	#set speed scale and fade
	if GV.reverting:
		fader.speed_scale = GV.FADER_SPEED_SCALE_MINOR;
	else:
		fader.speed_scale = GV.FADER_SPEED_SCALE_MAJOR;
	fader.play("fade_in_black");

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_in_black": #fade out black
		change_level(next_level_index);
		fader.play("fade_out_black");
	elif anim_name == "fade_out_black":
		if current_level_name != null and not GV.reverting: #fade in level name
			var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
			tween.finished.connect(_on_level_name_faded_in);
			tween.tween_property(current_level_name, "modulate:a", 1, GV.LEVEL_NAME_FADE_IN_TIME);
			

func change_move_mode(snap):
	GV.player_snap = snap;
	
	#update label
	var s:String = "Mode: ";
	s += "snap" if snap else "slide";
	mode_label.text = s;

func _on_level_name_faded_in(): #display level name
	var timer = get_tree().create_timer(GV.LEVEL_NAME_DISPLAY_TIME);
	timer.timeout.connect(_on_level_name_displayed);

func _on_level_name_displayed(): #fade out level name
	if current_level_name != null:
		var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
		tween.tween_property(current_level_name, "modulate:a", 0, GV.LEVEL_NAME_FADE_OUT_TIME);

func save_level(savepoint_id):
	print("SAVE LEVEL");
	#pack
	var packed_level = PackedScene.new();
	packed_level.pack(current_level);
	
	#find save path
	var save_path:String;
	if savepoint_id == -1:
		save_path = "res://Saves/Level%d.tscn" % GV.current_level_index;
	else:
		save_path = "res://Saves/Level%d_%d.tscn" % [GV.current_level_index, current_savepoint_ids.size()];
	
	#save and store in array(s)
	ResourceSaver.save(packed_level, save_path);
	level_saves[GV.current_level_index] = packed_level;
	if savepoint_id != -1:
		current_savepoint_ids.push_back(savepoint_id);
		current_savepoint_saves.push_back(packed_level);
