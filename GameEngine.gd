extends Node2D

@onready var inning_label = $Scoreboard/InningLabel
@onready var outs_label = $Scoreboard/OutsLabel
@onready var away_team_label = $Scoreboard/AwayTeamLabel
@onready var home_team_label = $Scoreboard/HomeTeamLabel
@onready var away_score_label = $Scoreboard/AwayScoreLabel
@onready var home_score_label = $Scoreboard/HomeScoreLabel
@onready var pitcher_label = $Scoreboard/PitcherLabel
@onready var batter_label = $Scoreboard/BatterLabel
@onready var stadium_label = $Scoreboard/StadiumLabel
@onready var first_base_icon = $BaseDiamond/FirstBase
@onready var second_base_icon = $BaseDiamond/SecondBase
@onready var third_base_icon = $BaseDiamond/ThirdBase
@onready var first_base_runner_sprite = $first_base_runner_sprite
@onready var second_base_runner_sprite = $second_base_runner_sprite
@onready var third_base_runner_sprite = $third_base_runner_sprite
@onready var first_base_runner_label = $first_base_runner_label
@onready var second_base_runner_label = $second_base_runner_label
@onready var third_base_runner_label = $third_base_runner_label
@onready var pitch_die_label = $Scoreboard/PitchDieLabel
@onready var bullpen_button = $BullpenButton
@onready var bullpen_menu = $BullpenMenu
@onready var weather_icon = $WeatherIcon
@onready var sfx_player = $SFXPlayer
@onready var reaction_player = $ReactionPlayer
@onready var ambience_player = $AmbiencePlayer
@onready var audio_dict = preload("res://Audio_Dictionary.gd").new()

var base_empty_texture = preload("res://Actual White Dot.png")
var base_occupied_texture = preload("res://Actual Gold Dot.png")

var fatigue_warning_shown = false
	
func play_sfx(path: String):
	sfx_player.stream = load(path)
	sfx_player.play()
	print("SFXPlayer exists")
	
func play_reaction(path: String):
	reaction_player.stream = load(path)
	reaction_player.play()
	print("Reaction exists")
	
func play_random_reaction(path: String, duration := 2.0):
	reaction_player.stream = load(path)
	reaction_player.play()
	await get_tree().create_timer(duration).timeout
	reaction_player.stop()
	
func play_random_ambience():
	var path = audio_dict.get_random_sfx("ambience")
	var stream = load(path)
		
	ambience_player.stream = stream
	ambience_player.play()
		
	print("Ambience playing", path)
	
func play_home_run_audio(is_home_team: bool):
	play_sfx("res://audio/Homerun.wav")
	
	if is_home_team:
		play_sfx("res://audio/HRFireworks.wav")
		play_reaction("res://audio/HRCheer.wav")
	else: 
		play_reaction("res://audio/HRBoo.wav")

func play_catcher_interference():
	play_sfx("res://audio/catcher.mp3")
	await get_tree().create_timer(0.15).timeout
	
	play_sfx("res://audio/interference.mp3")
	
	if GameManager.half_inning == "top":
		play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
	else: 
		play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
		
func bcaf_out():
	play_sfx("res://audio/Umpout.wav")
	
	if GameManager.half_inning == "top":
		play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
	else: 
		play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
		
func bcaf_safe():
	play_sfx("res://audio/Umpsafe.wav")
	
	if GameManager.half_inning == "top":
		play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
	else:
		play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0 )
		
func play_out_call():
	var outs_after = GameManager.outs
	
	if outs_after == 1:
		play_sfx(audio_dict.get_random_sfx("1out"))
	elif outs_after == 2:
		play_sfx(audio_dict.get_random_sfx("2outs"))
		
func _ready():
	print("GameEngine ready")
	update_base_icons()
	update_weather_icon()
	print("Weather:", GameManager.current_weather_name, GameManager.current_weather_icon)
	_initialize_scoreboard()

	GameManager.connect("play_by_play_updated", Callable(self,"_update_play_log"))
	GameManager.connect("runners_changed", self._on_runners_changed)
	play_sfx("res://audio/PlayBall.wav")
	play_random_ambience()

func update_pitcher_display():
	var pitcher = GameManager.home_pitcher if GameManager.half_inning == "top" else GameManager.away_pitcher
	var name = pitcher["name"]
	var hand = pitcher.get("hand", "R")
	
	var stats = GameManager.pitcher_stats[name]
	
	var outs = stats.get("outs", 0)
	var ip = int(outs / 3) + float(outs % 3) * 0.1
	
	var h = stats.get("H", 0)
	var r = stats.get("ER", 0)
	var bb = stats.get("BB", 0)
	var k = stats.get("K", 0)
	var bf = stats.get("BF", 0)
	
	pitcher_label.text = "Pitcher: %s (%s)\nIP: %.1f   BF: %d   K: %d   BB: %d\nH: %d   R: %d" % [
		name, hand, ip, bf, k, bb, h, r
	]
	
func _update_batter_label():
	var batter = get_current_batter()
	var name = batter["name"]
	var hand = batter.get("hand", "R")
	
	var stats = GameManager.batter_stats[name]
	
	var hits = stats.get("H", 0)
	var abs = stats.get("AB", 0)
	
	var line = "%d for %d" % [hits, abs]
	
	batter_label.text = "Batter: %s (%s) - %s" % [name, hand, line]
	
func update_base_icons():
	first_base_icon.texture = base_occupied_texture if GameManager.runner_on_first != null else base_empty_texture
	first_base_runner_sprite.visible = GameManager.runner_on_first != null
	first_base_runner_label.visible = GameManager.runner_on_first != null
	if GameManager.runner_on_first != null:
		first_base_runner_label.text = GameManager.runner_on_first.name
	second_base_icon.texture = base_occupied_texture if GameManager.runner_on_second != null else base_empty_texture
	second_base_runner_sprite.visible = GameManager.runner_on_second != null
	second_base_runner_label.visible = GameManager.runner_on_second != null
	if GameManager.runner_on_second != null:
		second_base_runner_label.text = GameManager.runner_on_second.name
	third_base_icon.texture = base_occupied_texture if GameManager.runner_on_third != null else base_empty_texture
	third_base_runner_sprite.visible = GameManager.runner_on_third != null
	third_base_runner_label.visible = GameManager.runner_on_third != null
	if GameManager.runner_on_third != null:
		third_base_runner_label.text = GameManager.runner_on_third.name
	
func _initialize_scoreboard():
	away_team_label.text = GameManager.away_team_name
	home_team_label.text = GameManager.home_team_name
	
	var p_hand = GameManager.home_pitcher.get("hand", "R")
	pitcher_label.text = "Pitcher: %s (%s)" % [GameManager.home_pitcher.get("name", "Unknown"), p_hand]
	pitch_die_label.text = "Die: %s" % str(GameManager.current_pitcher_die)
	
	GameManager.home_pitchers_used = [GameManager.home_pitcher["name"]]
	GameManager.away_pitchers_used = [GameManager.away_pitcher["name"]]
	
	for batter in GameManager.away_lineup:
		if not GameManager.batter_stats.has(batter["name"]):
			GameManager.batter_stats[batter["name"]] = {"H": 0, "AB": 0}
	for batter in GameManager.home_lineup:
		if not GameManager.batter_stats.has(batter["name"]):
			GameManager.batter_stats[batter["name"]] = {"H": 0, "AB": 0}
			
	var batter = get_current_batter()
	var name = batter.get("name", "unknown")
	var b_hand = batter.get("hand", "R")
	var stats = GameManager.batter_stats[name]
	var hits = stats.get("H", 0)
	var abs = stats.get("AB", 0)
	var line = "%d for %d" % [hits, abs]
	
	batter_label.text = "Batter: %s (%s) - %s" % [name, b_hand, line]
	
	inning_label.text = "%s %d" % [GameManager.half_inning.capitalize(), GameManager.inning]
	outs_label.text = "Outs: %d" % GameManager.outs
	away_score_label.text = "0"
	home_score_label.text = "0"
	stadium_label.text = GameManager.stadium_name

func get_position_name(fielder_num):
	match fielder_num:
		1: return "P"
		2: return "C"
		3: return "1B"
		4: return "2B"
		5: return "3B"
		6: return "SS"
		7: return "LF"
		8: return "CF"
		9: return "RF"
	return "Unknown"

func get_current_batter():
	var batter
	
	if GameManager.half_inning == "top":
		batter = GameManager.away_lineup[GameManager.away_batter_index]
	else: 
		batter = GameManager.home_lineup[GameManager.home_batter_index]
		
	GameManager.current_batter_hand = batter.get("hand", "R")
	
	return batter

func advance_batter():
	print("ADVANCING BATTER: ", GameManager.away_batter_index, GameManager.home_batter_index)
	var batter 
	
	if GameManager.half_inning == "top":
		GameManager.away_batter_index += 1
		if GameManager.away_batter_index >= GameManager.away_lineup.size():
			GameManager.away_batter_index = 0
		
		batter = GameManager.away_lineup[GameManager.away_batter_index]
	else:
		GameManager.home_batter_index += 1
		if GameManager.home_batter_index >= GameManager.home_lineup.size():
			GameManager.home_batter_index = 0
		
		batter = GameManager.home_lineup[GameManager.home_batter_index]
	
	GameManager.current_batter_hand = batter.get("hand", "R")
	
	update_pitcher_display()
	_update_batter_label()
	
func _update_play_log():
	if GameManager.game_over:
		return
		
	var log_container = $ScrollContainer/play_log
	
	for child in log_container.get_children():
		child.queue_free()
	
	for entry in GameManager.play_by_play:
		var label = Label.new()
		label.text = entry
		log_container.add_child(label)
		
	await get_tree().process_frame
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value
	
func clear_bases():
	GameManager.runner_on_first = null
	GameManager.runner_on_second = null
	GameManager.runner_on_third = null
	
func update_scoreboard():
	away_score_label.text = str(GameManager.away_score)
	home_score_label.text = str(GameManager.home_score)

func advance_walk(batter):
	play_sfx(audio_dict.get_random_sfx("walk"))
	GameManager.record_walk(batter["name"])
	GameManager.record_pitcher_walk()
	GameManager.record_bf()
	
	var is_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var is_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	#BasesLoaded
	if GameManager.runner_on_first != null and GameManager.runner_on_second != null and GameManager.runner_on_third != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
		
		GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
		
	#Force Runners
	if GameManager.runner_on_second != null and GameManager.runner_on_first != null:
		GameManager.runner_on_third = GameManager.runner_on_second
		GameManager.runner_on_second = GameManager.runner_on_first
		GameManager.runner_on_first = batter
	elif GameManager.runner_on_first != null: 
		GameManager.runner_on_second = GameManager.runner_on_first 
		GameManager.runner_on_first = null
		GameManager.runner_on_first = batter
	else:
		GameManager.runner_on_first = batter
	
	update_base_icons()
	
	var outs_before = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
			plural_before = ""
			
	GameManager.log_event("%s %d - %d out%s: %s walked" % [
		GameManager.half_inning.to_upper(),
		GameManager.inning,
		GameManager.outs,
		plural_before,
		GameManager.get_current_batter()["name"]
	])
		
	advance_batter()
	
func advance_single(batter, runners_advance):
	play_sfx("res://audio/Single.mp3")
	GameManager.record_single(batter["name"])
	GameManager.record_bfhit()
	
	var is_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var is_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	if runners_advance == 2:
		if GameManager.runner_on_third != null: 
			GameManager.score_run()
			GameManager.runner_on_third = null

			if is_home: 
				GameManager.home_pitcher_total_runs_allowed += 1
				GameManager.home_pitcher_runs_by_inning[-1] += 1
			else: 
				GameManager.away_pitcher_total_runs_allowed += 1
				GameManager.away_pitcher_runs_by_inning[-1] += 1
			
				var pname = GameManager.current_pitcher["name"]
				GameManager.pitcher_last_inning_runs[pname] = GameManager.pitcher_last_inning_runs.get(pname, 0) + 1

		
		if GameManager.runner_on_second != null:
			GameManager.score_run()
			GameManager.runner_on_second = null
		
			if is_home:
				GameManager.home_pitcher_total_runs_allowed += 1
				GameManager.home_pitcher_runs_by_inning[-1] += 1
			else: 
				GameManager.away_pitcher_total_runs_allowed += 1
				GameManager.away_pitcher_runs_by_inning[-1] += 1
				
			var pname = GameManager.current_pitcher["name"]
			GameManager.pitcher_last_inning_runs[pname] = GameManager.pitcher_last_inning_runs.get(pname, 0) + 1
		
		if GameManager.runner_on_first != null:
			GameManager.runner_on_third = GameManager.runner_on_first
			GameManager.runner_on_first = null
			
		GameManager.runner_on_first = batter
		
		update_scoreboard()
		GameManager.evaluate_fatigue_triggers()
		update_base_icons()
		
		var outs_before = GameManager.outs
		var plural_before = "s"
		if outs_before == 1:
			plural_before = ""
			
		GameManager.log_event("%s %d - %d out%s: %s singles" % [
			GameManager.half_inning.to_upper(),
			GameManager.inning,
			GameManager.outs,
			plural_before,
			GameManager.get_current_batter()["name"]
		])
		
		advance_batter()
		return
		
	
	if GameManager.runner_on_third != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1

			var pname = GameManager.current_pitcher["name"]
			GameManager.pitcher_last_inning_runs[pname] = GameManager.pitcher_last_inning_runs.get(pname, 0) + 1
		
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
		
		GameManager.runner_on_third = null
			
	if GameManager.runner_on_second != null:
		GameManager.runner_on_third = GameManager.runner_on_second
		GameManager.runner_on_second = null
			
	if GameManager.runner_on_first:
		GameManager.runner_on_second = GameManager.runner_on_first
		GameManager.runner_on_first = null
			
	GameManager.runner_on_first = batter
		
	update_base_icons()
	
	var outs_before = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
			plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: %s singles" % [
		GameManager.half_inning.to_upper(),
		GameManager.inning,
		GameManager.outs,
		plural_before,
		GameManager.get_current_batter()["name"]
	])
	
	advance_batter()
		
func advance_double(batter):
	play_sfx("res://audio/Double.mp3")
	GameManager.record_double(batter["name"])
	GameManager.record_bfhit()
	
	var is_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var is_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	if GameManager.runner_on_third != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			
		var pname = GameManager.current_pitcher["name"]
		GameManager.pitcher_last_inning_runs[pname] = GameManager.pitcher_last_inning_runs.get(pname, 0) + 1
		
		GameManager.runner_on_third = null
		
	if GameManager.runner_on_second != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			
		var pname = GameManager.current_pitcher["name"]
		GameManager.pitcher_last_inning_runs[pname] = GameManager.pitcher_last_inning_runs.get(pname, 0) + 1
		
		GameManager.runner_on_second = null
		
	if GameManager.runner_on_first != null:
		GameManager.runner_on_third = GameManager.runner_on_first
		GameManager.runner_on_first = null
		
	GameManager.runner_on_second = batter
	
	update_scoreboard()
	GameManager.evaluate_fatigue_triggers()
	update_base_icons()
	
	var outs_before = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
			plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: %s doubles" % [
	GameManager.half_inning.to_upper(),
	GameManager.inning,
	GameManager.outs,
	plural_before,
	GameManager.get_current_batter()["name"]
		])
		
	advance_batter()
	
func advance_triple(batter):
	play_sfx("res://audio/Triple.mp3")
	GameManager.record_triple(batter["name"])
	GameManager.record_bfhit()
	
	var is_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var is_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	if GameManager.runner_on_third != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
		
	if GameManager.runner_on_second != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
		
	if GameManager.runner_on_first != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
	
	clear_bases()
	
	GameManager.runner_on_third = batter
	
	update_base_icons()
	
	var outs_before = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
			plural_before = ""
			
	GameManager.log_event("%s %d - %d out%s: %s triples" % [
	GameManager.half_inning.to_upper(),
	GameManager.inning,
	GameManager.outs,
	plural_before,
	GameManager.get_current_batter()["name"]
		])
		
	advance_batter()
	
func advance_home_run(batter):
	GameManager.record_home_run(batter["name"])
	GameManager.record_bfhit()
	
	var is_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var is_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	GameManager.score_run()

	if is_home: 
		GameManager.home_pitcher_total_runs_allowed += 1
		GameManager.home_pitcher_runs_by_inning[-1] += 1
		GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
	else: 
		GameManager.away_pitcher_total_runs_allowed += 1
		GameManager.away_pitcher_runs_by_inning[-1] += 1
		GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
	GameManager.evaluate_fatigue_triggers()
			
	if GameManager.runner_on_third != null:
		GameManager.score_run()
		
		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
			
	if GameManager.runner_on_second != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
		
	if GameManager.runner_on_first != null:
		GameManager.score_run()

		if is_home: 
			GameManager.home_pitcher_total_runs_allowed += 1
			GameManager.home_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
		else: 
			GameManager.away_pitcher_total_runs_allowed += 1
			GameManager.away_pitcher_runs_by_inning[-1] += 1
			GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
			
		GameManager.evaluate_fatigue_triggers()
	
	play_home_run_audio(is_away)
	
	update_scoreboard()

	clear_bases()

	update_base_icons()
	
	var outs_before = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
			plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: %s hits a HOME RUN!" % [
	GameManager.half_inning.to_upper(),
	GameManager.inning,
	GameManager.outs,
	plural_before,
	GameManager.get_current_batter()["name"]
		])
		
	advance_batter()

func _on_pitch_button_pressed():
	var action = GameManager.ai_choose_action()
	match action:
		"bunt":
			resolve_bunt()
		"steal":
			resolve_steal()
		"pitch":
			resolve_pitch()
			
func resolve_bunt():
	var occupied_bases = 0
	if GameManager.runner_on_first != null:
		occupied_bases += 1
	if GameManager.runner_on_second != null:
		occupied_bases += 1
	if GameManager.runner_on_third != null: 
		occupied_bases += 1
		
	if occupied_bases >= 2:
		resolve_pitch()
		return
		
	var batter = get_current_batter()
	var batter_name = batter["name"]

	var r1 = GameManager.runner_on_first
	var r2 = GameManager.runner_on_second
	var r3 = GameManager.runner_on_third
	
	var roll = randi_range(1, 6)
	var batter_trait = batter.get("trait", "")
	
	match batter_trait: 
		"C+": 
			roll += 1
			print("Debug: C+")
		"C-": 
			roll -= 1
			print("Debug C-")
		
		
	roll = clamp(roll, 1, 6)
	
#1/2 Batter Safe, Runner OUt
	if roll <= 2:
		var lead_base := 0
		if r3 != null:
			lead_base = 3
		elif r2 != null:
			lead_base = 2
		elif r1 != null:
			lead_base = 1
		
		if lead_base == 1:
				GameManager.runner_on_first = null
		elif lead_base == 2:
				GameManager.runner_on_second = null
		elif lead_base == 3:
				GameManager.runner_on_third = null
		
		GameManager.record_pa(batter["name"])
		
		GameManager.record_bf()
		
		advance_batter()
		
		var half_before = GameManager.half_inning
		var inning_before = GameManager.inning
		var outs_before = GameManager.outs
		
		handle_out()
		
		var new_batter = get_current_batter()
		GameManager.runner_on_first = batter
		
		update_base_icons()
		

		var outs_after = GameManager.outs
		
		var plural_before = "s"
		if outs_before == 1:
			plural_before = ""
			
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""
		
		GameManager.log_event("%s %d - %d out%s: %s bunts. Lead runner out - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter["name"],
			outs_after,
			plural_after
		])
		_update_batter_label()
		return
			
#Special Logic
	if roll == 3:
		
		if r3 != null:
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			var outs_before = GameManager.outs
			
			GameManager.record_pa(batter["name"])
			
			GameManager.record_bf()
			
			advance_batter()
			
			GameManager.runner_on_third = null
			handle_out()
			
			GameManager.runner_on_first = batter
			update_base_icons()
			
			var outs_after = GameManager.outs
			var plural_before = "s"
			if outs_before == 1:
				plural_before = ""
			
			var plural_after = "s"
			if outs_after == 1:
				plural_after = ""
	
			GameManager.log_event("%s %d - %d out%s: %s bunts. Lead runner out. - %d out%s" % [
				half_before.to_upper(),
				inning_before,
				outs_before,
				plural_before,
				batter_name,
				outs_after,
				plural_after
			])
			_update_batter_label()
			return
			
		if r2 != null: 
			play_sfx("res://audio/Bunt.wav")
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			var outs_before = GameManager.outs
			
			GameManager.runner_on_third = r2
			
			GameManager.record_pa(batter["name"])
			
			GameManager.record_bf()
			
			advance_batter()
			
			GameManager.runner_on_second = null
			handle_out()
			
			update_base_icons()
			
			var outs_after = GameManager.outs
			var plural_before = "s"
			if outs_before == 1:
				plural_before = ""
			
			var plural_after = "s"
			if outs_after == 1:
				plural_after = ""
	
			GameManager.log_event("%s %d - %d out%s: %s executes a perfect sac bunt. - %d out%s" % [
				half_before.to_upper(),
				inning_before,
				outs_before,
				plural_before,
				batter_name,
				outs_after,
				plural_after
			])
			_update_batter_label()
			return
			
		if r1 != null: 
			play_sfx("res://audio/Bunt.wav")
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			var outs_before = GameManager.outs
			
			GameManager.record_pa(batter["name"])
			
			GameManager.record_bf()
			
			GameManager.runner_on_second = r1
			
			advance_batter()
			
			GameManager.runner_on_first = null
			handle_out()
			
			update_base_icons()
			
			var outs_after = GameManager.outs
			var plural_before = "s"
			if outs_before == 1:
				plural_before = ""
			
			var plural_after = "s"
			if outs_after == 1:
				plural_after = ""
			
			GameManager.log_event("%s %d - %d out%s: %s executes a perfect sac bunt. - %d out%s." % [
				half_before.to_upper(),
				inning_before,
				outs_before,
				plural_before,
				batter_name,
				outs_after,
				plural_after
			])
			_update_batter_label()
			return
	
	#Sac Bunt
	play_sfx("res://audio/Bunt.wav")
	var lead_base := 0 
	if r3 != null:
		lead_base = 3
	elif r2 != null:
		lead_base = 2
	elif r1 != null:
		lead_base = 1
		
	if lead_base == 1:
		GameManager.runner_on_second = r1
		GameManager.runner_on_first = null
	elif lead_base == 2:
		GameManager.runner_on_third = r2
		GameManager.runner_on_second = null
	elif lead_base == 3:
		GameManager.score_run()
		GameManager.pitcher_total_runs_allowed += 1
		GameManager.pitcher_runs_by_inning[-1] += 1
		GameManager.evaluate_fatigue_triggers()
		update_scoreboard()
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	GameManager.record_pa(batter["name"])
	
	GameManager.record_bf()
	
	advance_batter()
	
	handle_out()	
	
	update_base_icons()
	
	var outs_after = GameManager.outs
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
			
	var plural_after = "s"
	if outs_after == 1:
		plural_after = ""
	
	GameManager.log_event("%s %d - %d out%s: %s executes a perfect sac bunt. Lead runner advances. - %d out%s" % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before,
		batter_name,
		outs_after,
		plural_after
	])
	_update_batter_label()
	return
	
func resolve_steal():
	var runner = GameManager.pending_steal_runner
	var target_base = GameManager.pending_steal_target_base
	
	if runner == null or target_base == 0:
		resolve_pitch()
		return
		
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	var runner_name = runner["name"]
	
	var roll = randi_range(1, 8)
	
	print("Debug: BSteal:", roll)
	
	roll += GameManager.current_weather_sb_modifier
	
	print("Debug: WSteal:", roll)
	
	if target_base == 3:
		roll -= 1
		
	print("Debug: S3rd:", roll)
		
	var pitcher_trait = GameManager.current_pitcher.get("trait", "")
	if pitcher_trait == "Q+":
		roll -= 1
		print("Debug: Q+")
	elif pitcher_trait == "Q-":
		roll += 1
		print("Debug: Q-")
	
	var s_trait = GameManager.get_speed_trait(runner)
	if s_trait == "S+":
		roll += 1
	if s_trait == "S-":
		roll -= 1
	
	if GameManager.stadium_quirk == "SB-1IDEF+1":
		roll -= 1
		print("SB-1IDEF+1")
	elif GameManager.stadium_quirk == "SB+1IDEF-1":
		roll += 1
		print("SB+1IDEF-1")
	
	if roll <= 3: 
		play_sfx("res://audio/Umpout.wav")
		if GameManager.runner_on_first == runner: 
			GameManager.runner_on_first = null
		elif GameManager.runner_on_second == runner:
			GameManager.runner_on_second = null
		elif GameManager.runner_on_third == runner: 
			GameManager.runner_on_third = null
			
		handle_out()
		update_base_icons()
		
		var outs_after =GameManager.outs
		
		var plural_before = "s"
		if outs_before == 1:
			plural_before = ""
			
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""
		
		GameManager.log_event("%s %d - %d out%s: %s caught stealing - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			runner_name,
			outs_after,
			plural_after
		])
	
		GameManager.pending_steal_runner = null
		GameManager.pending_steal_target_base = 0
		return
	
	if GameManager.runner_on_first == runner:
		GameManager.runner_on_first = null
	elif GameManager.runner_on_second == runner: 
		GameManager.runner_on_second = null
	elif GameManager.runner_on_third == runner: 
		GameManager.runner_on_third = null
			
	GameManager.record_stolen_base(runner["name"])
	
	if target_base == 2:
		GameManager.runner_on_second = runner
	elif target_base == 3:
		GameManager.runner_on_third = runner
		
	play_sfx("res://audio/Umpsafe.wav")
	update_base_icons()
		
		
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
		
	update_base_icons()
		
	GameManager.log_event("%s %d - %d out%s: %s stole %s" % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before,
		runner_name,
		str(target_base),
		])
		
	GameManager.pending_steal_runner = null
	GameManager.pending_steal_target_base = 0

			
func resolve_pitch():
	print("\n== Resolve Pitch Start")
	print("Debug: Entering Resolve_Pitch. Half:", GameManager.half_inning, "Inning:", GameManager.inning)
	
	var before_half = GameManager.half_inning
	var batter = get_current_batter()
	var pitch_die = GameManager.get_current_pitch_die()
	
	var pitcher = GameManager.current_pitcher
	var is_home = (pitcher == GameManager.home_pitcher)
	var is_away = (pitcher == GameManager.away_pitcher)
	
	var scoreless_streak = 0
	
	var pitched_home = (GameManager.current_pitcher == GameManager.home_pitcher)
	var pitched_away = (GameManager.current_pitcher == GameManager.away_pitcher)
	
	if is_home:
		scoreless_streak = GameManager.home_pitcher_scoreless_inning_streak
	else: 
		scoreless_streak = GameManager.away_pitcher_scoreless_inning_streak
		
	print("Debug: Streak entering Resolve Pitch", scoreless_streak)
	
	print("Base Die:", pitch_die)
	
	var pitcher_hand = pitcher.get("hand", "R")
	var batter_hand = batter.get("hand", "R")

	print("Debug: Pitcher's Hand:", pitcher_hand, "Batter's hand:", batter_hand)
		
	var ladder = [20, 12, 8, 4, -4, -8, -12, -20]
	var idx = ladder.find(pitch_die)
	
	print("Debug: Ladder idx for base die:", idx)
	
	var temp_die = pitch_die
	var pitcher_trait = pitcher.get("trait", 0)
	
	if pitcher_trait != "SC+":
		if idx != -1 and pitcher_hand == batter_hand:
			if idx >  0: 
				temp_die = ladder[idx - 1]
				print("Debug: Handness bump applied. Temp Die:", temp_die)
			else: 
				print("Debug: Handness match, but already at top.")
				
	if pitcher_trait == "SC+":
		if batter_hand != pitcher_hand  or batter_hand == "S":
			var sc_idx = ladder.find(temp_die)
			if sc_idx > 0:
				temp_die = ladder[sc_idx - 1]
				print("Debug SC+ Bump", temp_die)
			else: 
				print("Debug SC+, but alread at top.")
			
	print("HB Die:", temp_die)
	
	var roll = roll_d100()
	print("Debug: Raw Roll:", roll)
	
	var modified_roll = apply_mss_modifiers(roll, temp_die)
	print("Debug: Mod Roll:", modified_roll)
	
	var mss_result = resolve_mss(modified_roll, batter, pitcher)
	
	print("MSS category:", mss_result.category)
	print("Details:", mss_result.details)
	
	process_mss_outcome(mss_result)
	
	var after_half = GameManager.half_inning
	var after_inning = GameManager.inning
	
	print("Debug: After resolve pitch | Half:", after_half, "Inning", after_inning)
	print("== Resolve Pitch End ===\n")
	
	update_base_icons()
	GameManager.check_game_over()
	
	var next_batter = get_current_batter()
	var hand = next_batter.get("hand", "R")
	_update_batter_label()
	check_pitcher_fatigue_popup()
	
func lookup_mss_result(roll: int) -> String:
	if roll >100:
		return "triple_play"
	if roll <= 5:
		return "strikeout"
	elif roll <= 15:
		return "groundout"
	elif roll <=25:
		return "flyout"
	elif roll <= 35:
		return "walk"
	elif roll <= 60:
		return "single"
	elif roll <= 80:
		return "double"
	elif roll <= 90:
		return "triple"
	elif roll <= 100:
		return "home_run"
	
	return "single"
	
func resolve_hit_table(d20_roll: int) -> Dictionary:
	var result := {
		"type": "",
		"fielder": null,
		"runners_advance": 1,
		"defensive_check": false
	}

# --- Singles ---
	if d20_roll in [1, 2, 7, 8, 9]:
		result.type = "single"
		result.ht_value = d20_roll
		return result

# --- Singles w/ Defensive Check (3–6) ---
	if d20_roll >= 3 and d20_roll <= 6:
		result.type = "single"
		result.defensive_check = true

		match d20_roll:
			3: result.fielder = 3
			4: result.fielder = 4
			5: result.fielder = 5
			6: result.fielder = 6
		
		result.ht_value = d20_roll
		return result

# --- Singles w/ Extra Advancement (10–14) ---
	if d20_roll >= 10 and d20_roll <= 14:
		result.type = "single"
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

# --- Doubles ---
	if d20_roll == 15:
		result.type = "double"
		result.fielder = 7
		result.defensive_check = true
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

	if d20_roll == 16:
		result.type = "double"
		result.fielder = 8
		result.defensive_check = true
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

	if d20_roll == 17:
		result.type = "double"
		result.fielder = 9
		result.defensive_check = true
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

	#HT1820HR
	if GameManager.stadium_quirk == "HT1820HR" and d20_roll in [18, 19, 20]:
		print("SQ: HT1820HR")
		result.type = "home_run"
		result.runners_advance = 4
		result.ht_value = d20_roll
		return result

	#HT18 Stadium Quirk
	if GameManager.stadium_quirk == "HT18T" and d20_roll == 18:
		print("SQ: HT18T")
		result.type = "triple"
		result.runners_advance = 3
		result.ht_value = d20_roll
		return result
		
	if d20_roll == 18:
		result.type = "double"
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

	if GameManager.stadium_quirk == "HT20HR" and d20_roll == 19:
		print("SQ: H20HR")
		result.type = "double"
		result.runners_advance = 2
		result.ht_value = d20_roll
		return result

# --- Home Runs ---
	if d20_roll == 19 or d20_roll == 20:
		result.type = "home_run"
		result.runners_advance = 4
		result.ht_value = d20_roll
		return result

# Fallback (should never happen)
	result.type = "single"
	result.ht_value = d20_roll
	return result
		
func apply_cn_modifiers(batter_stats: Dictionary, pitcher_stats: Dictionary) -> int:
	var bat_target = batter_stats.get("BatTarget", 0)
	var onbase_target = batter_stats.get("OnBaseTarget", 0)
	
	var pitcher_trait = pitcher_stats.get("trait", "")
	var batter_trait = batter_stats.get("trait", "")
	
	if pitcher_trait == "CN+":
		onbase_target -= 2
		if onbase_target <= bat_target:
			onbase_target = bat_target +1
	
	if pitcher_trait == "CN-":
		onbase_target += 3
		if onbase_target >= 98:
			onbase_target = 98

	return onbase_target

func resolve_mss(mss_value: int, batter_stats: Dictionary, pitcher_stats: Dictionary) -> Dictionary:
	var result := {
	"category": "",
	"details": {}
}

	result.mss_value = mss_value
	
	if GameManager.stadium_quirk == "MSS+":
		print("SQ: MSS+")
		mss_value += 1
	
	if GameManager.stadium_quirk == "MSS-":
		print("SQ: MSS-")
		mss_value -= 1 
		
	var bat_target = batter_stats.get("BatTarget", 0)
	var on_base_target = apply_cn_modifiers(batter_stats, pitcher_stats)
	var pitcher_trait = pitcher_stats.get("trait", "")
	
	var road_trait = batter_stats.get("trait", "")
	
	var batter_is_away = GameManager.half_inning == "top"
	
	if batter_is_away: 
		match road_trait:
			"R+":
				bat_target += 5
				on_base_target += 5
			"R-":
				bat_target -= 5
				on_base_target -= 5
		
	if GameManager.stadium_quirk == "BTOBT+":
		print("SQ: BTOBT+")
		bat_target += 5
		on_base_target += 5
		
	if GameManager.stadium_quirk == "BTOBT-":
		print("SQ: BTOBT-")
		bat_target -= 5
		on_base_target -= 5
		
	bat_target = clamp(bat_target, 1, 98)
	on_base_target = clamp(on_base_target, bat_target +1, 98)
	
	
	
	var last_digit = mss_value % 10
	
	if GameManager.stadium_quirk == "4757HR" and mss_value in [47, 57]:
		print("SQ: 4757HR triggered for", mss_value)
		result.category = "hit"
		result.details = {
			"type": "home_run",
			"runners_advance": 4
		}
		return result
	
	if GameManager.stadium_quirk == "4959HR" and mss_value in [49, 59]:
		print("SQ: 4959HR triggered for", mss_value)
		result.category = "hit"
		result.details = {
			"type": "home_run",
			"runners_advance": 4
		}
		return result
	
# Oddity
	if mss_value <= 1 or mss_value == 99:
		handle_oddity()
		return result
		

# Critical Hit
	if mss_value >= 2 and mss_value <= 5:
		var d20 = randi_range(1, 20)
		d20 += GameManager.current_weather_ht_modifier
		var original_d20 = d20 #DEBUG LINE
		
		#Stadium Quirk: HT+1
		if GameManager.stadium_quirk == "Hit Table +1":
			d20 +=1
			if d20 > 20:
				d20 = 20
				
		#Stadium Quirk: HT-1
		if GameManager.stadium_quirk == "Hit Table -1":
			d20 -= 1
			if d20 < 1:
				d20 = 1
		
		#P Trait
		var batter_trait = batter_stats.get("trait","")
		match batter_trait:
			"P+": d20 += 1
			"P++": d20 += 2
			"P-": d20 -= 1
			"P--": d20 -= 2
		
		if d20 < 1:
			d20 = 1
		if d20 > 20:
			d20 = 20
			
		print("DEBUG: P Trait:", original_d20, "trait:", batter_trait)
			
		print("Hit Table roll:", d20)
				
		var hit_info = resolve_hit_table(d20)

		match hit_info.type:
			"single": hit_info.type = "double"
			"double": hit_info.type = "triple"
			"triple": hit_info.type = "home_run"
			"home_run": pass
			
		result.category = "hit"
		result.details = hit_info
		return result

# Normal Hit
	if mss_value >= 6 and mss_value <= bat_target:
		var d20 = randi_range(1, 20)
		d20 += GameManager.current_weather_ht_modifier

		var original_d20 = d20 #DEBUG Line
		
		#Stadium Quirk: HT+1
		if GameManager.stadium_quirk == "Hit Table +1":
			d20 +=1
			if d20 > 20:
				d20 = 20
				
		#Stadium Quirk: HT-1
		if GameManager.stadium_quirk == "Hit Table -1":
			d20 -= 1
			if d20 < 1:
				d20 = 1
				
		print("Stadium DEBUG:", d20, "OG:", original_d20)
				
		#P Trait
		var batter_trait = batter_stats.get("trait","")
		match batter_trait:
			"P+": d20 += 1
			"P++": d20 += 2
			"P-": d20 -= 1
			"P--": d20 -= 2
		
		if d20 < 1:
			d20 = 1
		if d20 > 20:
			d20 = 20
		
		print("DEBUG: P Trait:", original_d20, "trait:", batter_trait)
		
		print("Hit Table roll:", d20)
		
		var hit_info = resolve_hit_table(d20)

		result.category = "hit"
		result.details = hit_info
		return result

# Walk (BaseTarget < MSS ≤ OnBaseTarget)
	if mss_value > bat_target and mss_value <= on_base_target:
		result.category = "walk"
		return result

# Error Check (OnBaseTarget + 1 → OnBaseTarget + 5)
	if mss_value > on_base_target and mss_value <= on_base_target + 5:
		result.category = "error_check"
		return result

# Out Logic (MSS > OnBaseTarget + 5)
	if mss_value > on_base_target + 5:
		
	# Double Play (70–98 and ends in 3–6)
		if mss_value >= 70 and mss_value <= 98:
			if last_digit in [3, 4, 5, 6]:
				result.category = "double_play"
				return result
				
	#GB+
		if last_digit == 2 and pitcher_trait == "GB+":
			result.category = "out"
			result.details = {"type": "groundout"}
			return result
	
	# Strikeout w/ K+
		if last_digit in [0, 1] or (last_digit == 3 and pitcher_trait == "K+"):
			result.category = "out"
			result.details = {"type": "strikeout"}
			return result

	#Strikeout 2
		if last_digit == 2:
			result.category = "out"
			result.details = {"type": "strikeout"}
			return result
			
	# Groundout
		if last_digit in [4, 5, 6]:
			result.category = "out"
			result.details = {"type": "groundout"}
			return result

	# Flyout
		if last_digit in [7, 8, 9]:
			result.category = "out"
			result.details = {"type": "flyout"}
			return result

	# Triple Play (>100)
		if mss_value > 100:
			result.category = "triple_play"
			return result

	# Fallback
		result.category = "out"
		return result 
		
	# Final fallback (should never hit)
	return result
	
func roll_d100() -> int:
	return randi_range(1,100)
	
func roll_pitcher_die() -> int:
	
	var die = GameManager.get_current_pitch_die()
	GameManager.last_pitch_die_used = die
	
	if die == 0:
		return 0
		
	var abs_die = abs(die)
	var roll = randi_range(1, abs_die)
	
	if die < 0:
		return -roll
	else:
		return roll 
	
func apply_mss_modifiers(roll: int, pitch_die: int) -> int:
	var result = roll
	
#Pitcher die mod
	var pitcher_mod = roll_pitcher_die()
	result += pitcher_mod
		
#Batter Trait
	if GameManager.current_batter_trait == "C+":
		result += 1

	return result
	
func get_fielder_from_last_digit(last_digit: int) -> int:
	match last_digit:
		0,1: return 1 
		2: return 2
		3: return 3
		4: return 4
		5: return 5
		6: return 6
		7: return 7
		8: return 8
		9: return 9
	return 1
	
func handle_out():
	GameManager.outs += 1
	
	if not GameManager.last_out_was_strikeout: 
		if GameManager.current_pitcher == GameManager.home_pitcher:
			GameManager.home_pitcher_consecutive_strikeouts = 0
		else: 
			GameManager.away_pitcher_consecutive_strikeouts = 0
			
	GameManager.last_out_was_strikeout = false
	
	print("Bebug :current_pitcher:", GameManager.current_pitcher)
	
	var pitcher_name = GameManager.current_pitcher["name"]
	GameManager.pitcher_stats[pitcher_name]["outs"] += 1
	outs_label.text = "Outs: %d" % GameManager.outs
	
	update_pitcher_display()
	
	if GameManager.outs >= 3:
	
		var pitched_home = (GameManager.current_pitcher == GameManager.home_pitcher)
		var pitched_away = (GameManager.current_pitcher == GameManager.away_pitcher)
		
		var runs_this_inning = 0
		if pitched_home: 
			runs_this_inning = GameManager.home_pitcher_runs_by_inning[-1]
		else: 
			runs_this_inning = GameManager.away_pitcher_runs_by_inning[-1]
			
		var name = GameManager.current_pitcher["name"]
		var rti = GameManager.pitcher_last_inning_runs.get(name, 0)
		
		if not GameManager.pitcher_inning_log.has(name):
			GameManager.pitcher_inning_log[name] = []
			
		var scoreless = 0
		if rti == 0:
			scoreless = 1
		
		GameManager.pitcher_inning_log[name].append(scoreless)
		GameManager.pitcher_last_inning_runs[name] = 0
		
		var log = GameManager.pitcher_inning_log[name]
		if log.size() >= 3:
			var last_three = log.slice(log.size() - 3, log.size())
			if last_three[0] == 1 and last_three[1] == 1 and last_three[2] == 1: 
				print("Fatigue bump due to scoreless innings")
				GameManager.apply_fatigue_change(+1)
				
				GameManager.pitcher_inning_log[name].clear()
			
		GameManager.save_game_snapshot()
		
		if GameManager.half_inning == "top":
			GameManager.half_inning = "bottom"
		else:
			GameManager.half_inning = "top"
			GameManager.inning += 1
			GameManager.check_game_over()
			
			play_random_ambience()
			
		GameManager.outs = 0
		
		GameManager.runner_on_first = null
		GameManager.runner_on_second = null
		GameManager.runner_on_third = null
		
		clear_bases()
		update_base_icons()
		
		var new_pitcher = GameManager.home_pitcher if GameManager.half_inning == "top" else GameManager.away_pitcher
		GameManager.current_pitcher = new_pitcher
		GameManager.initialize_pitcher_fatigue(new_pitcher)
				
		if pitched_home:
			if runs_this_inning == 0:
				GameManager.home_pitcher_scoreless_inning_streak += 1
			else: 
				GameManager.home_pitcher_scoreless_inning_streak = 0
				
		if pitched_away:
			if runs_this_inning == 0:
				GameManager.away_pitcher_scoreless_inning_streak += 1
			else: 
				GameManager.away_pitcher_scoreless_inning_streak = 0
			
		if pitched_home:
			if GameManager.home_pitcher_consecutive_strikeouts >= 3:
				print("Fatigue bump due to striking out the side")
				GameManager.apply_fatigue_change(+1)
			GameManager.home_pitcher_consecutive_strikeouts = 0
			
		if pitched_away:
			if GameManager.away_pitcher_consecutive_strikeouts >= 3:
				print("Fatigue bump due to striking out the side")
				GameManager.apply_fatigue_change(+1)
			GameManager.away_pitcher_consecutive_strikeouts = 0
			
		if pitched_home:
			GameManager.home_pitcher_runs_by_inning.append(0)
			GameManager.home_pitcher_consecutive_strikeouts = 0
		else: 
			GameManager.away_pitcher_runs_by_inning.append(0)
			GameManager.away_pitcher_consecutive_strikeouts = 0
		
		GameManager.evaluate_fatigue_triggers()
		
		update_pitcher_display()
		_update_batter_label()
		outs_label.text = "Outs: 0"
		inning_label.text = "%s %d" % [
			GameManager.half_inning.capitalize(),
			GameManager.inning
		]
		
func process_mss_outcome(result):
	print(result)
	var outcome = result.category
	var details = result.details
	var mss_value = result.mss_value
	
	var pitcher = GameManager.current_pitcher
	var is_home = (pitcher == GameManager.home_pitcher)
	var is_away = (pitcher == GameManager.away_pitcher)
	
	match outcome:
		
		"triple_play":
			if GameManager.outs >= 2:
				var batter = GameManager.get_current_batter()
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				advance_batter()
				handle_out()
				play_out_call()
				clear_bases()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s grounded out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				return
				
			var batter = get_current_batter()
			var last_digit = mss_value % 10
			var fielder = get_fielder_from_last_digit(last_digit)
			
			var runner_on_first = GameManager.runner_on_first
			var runner_on_second = GameManager.runner_on_second
			var runner_on_third = GameManager.runner_on_third
			
			if runner_on_first == null:
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				advance_batter()
				
				handle_out()
				play_out_call()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s grounded out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				return
			
			var outs_before = GameManager.outs
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			
			GameManager.record_ab(batter["name"])
			
			if GameManager.runner_on_first!= null:
				GameManager.runner_on_first = null 
				
				handle_out()
				handle_out()
				update_base_icons()
				play_sfx(audio_dict.get_random_sfx("res://audio/Doubleplay.wav"))
				play_out_call()
			
				if GameManager.half_inning == "top":
					play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
				else: 
					play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
				
				GameManager.runner_on_first = null
			
				if runner_on_second != null:
					GameManager.runner_on_third = GameManager.runner_on_second
					GameManager.runner_on_second = null
			
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s grounded into double play - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				return
			
			if GameManager.outs == 0 and GameManager.runner_on_first != null and GameManager.runner_on_second != null:
				GameManager.record_ab(batter["name"])
				GameManager.record_bf()
				
				advance_batter()
				
				handle_out()
				handle_out()
				handle_out()
				
				GameManager.runner_on_first = null
				GameManager.runner_on_second = null
				GameManager.runner_on_third = null
				
				clear_bases()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				GameManager.log_event("%s %d - %d outs: %s hits into a Triple Play - %d outs" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					batter["name"],
					outs_after
				])
				return
			
		"out":
			var out_type = details.get("type", "")
			if out_type == "":
				out_type = "groundout"
			
			if out_type == "strikeout":
				var batter = GameManager.get_current_batter()
				play_sfx(audio_dict.get_random_sfx("strikeout"))
				GameManager.record_strikeout()
			
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				advance_batter()
				
				if is_home:
					GameManager.home_pitcher_consecutive_strikeouts += 1
				else:
					GameManager.away_pitcher_consecutive_strikeouts += 1
					
				GameManager.last_out_was_strikeout = true

				handle_out()

				var outs_after = GameManager.outs

				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s struck out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				
				return
				
			elif out_type == "groundout":
				var batter = GameManager.get_current_batter()
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				advance_batter()
				
				var last_digit: int = mss_value % 10
				var is_outfield: bool = last_digit in [7, 8, 9]
				var is_right_infield: bool = last_digit in [3, 4]
				var is_infield: bool = last_digit in [3, 4, 5, 6]
				
				var fc_happened := false
				var fc_runner_name := ""
				
				if mss_value <= 49:
					if is_outfield or is_right_infield:
						if GameManager.runner_on_third != null and GameManager.outs < 2:
							GameManager.score_run()
							if is_home:
								GameManager.home_pitcher_total_runs_allowed += 1
								GameManager.home_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
							else: 
								GameManager.away_pitcher_total_runs_allowed += 1
								GameManager.away_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
								
							GameManager.evaluate_fatigue_triggers()
							GameManager.runner_on_third = null
							update_scoreboard()
						
						if GameManager.runner_on_second != null:
							GameManager.runner_on_third = GameManager.runner_on_second
							GameManager.runner_on_second = null
						
					if is_infield:
						if GameManager.runner_on_first != null:
							GameManager.runner_on_second = GameManager.runner_on_first
							GameManager.runner_on_first = null
						
				elif mss_value >= 50 and mss_value <= 69:
					if is_outfield or is_right_infield:
						if GameManager.runner_on_third != null and GameManager.outs < 2:
							GameManager.score_run()
							if is_home:
								GameManager.home_pitcher_total_runs_allowed += 1
								GameManager.home_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
							else: 
								GameManager.away_pitcher_total_runs_allowed += 1
								GameManager.away_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
								
							GameManager.evaluate_fatigue_triggers()
							GameManager.runner_on_third = null
							update_scoreboard()
						
						if GameManager.runner_on_second != null:
							GameManager.runner_on_third = GameManager.runner_on_second
							GameManager.runner_on_second = null
						
						if GameManager.runner_on_first != null: 
							fc_runner_name = GameManager.runner_on_first["name"]
							GameManager.runner_on_first = batter
							fc_happened = true
						else: 
							pass
							
				handle_out()
				play_out_call()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
				
				if fc_happened:
					GameManager.log_event("%s %d - %d out%s: %s out on fielder's choice - %d out%s" % [
							half_before.to_upper(),
							inning_before,
							outs_before,
							plural_before,
							fc_runner_name,
							outs_after,
							plural_after
					])
				else:
					GameManager.log_event("%s %d - %d out%s: %s grounded out - %d out%s" % [
						half_before.to_upper(),
						inning_before,
						outs_before,
						plural_before,
						batter["name"],
						outs_after,
						plural_after
					])
				return
			
			elif out_type == "flyout":
				var batter = GameManager.get_current_batter()
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				advance_batter()
				
				var last_digit: int = mss_value % 10
				var is_outfield: bool = last_digit in [7, 8, 9]
				var is_right_infield: bool = last_digit in [3, 4]
				var is_infield: bool = last_digit in [3, 4, 5, 6]
				
				if mss_value <= 49:
					if is_outfield or is_right_infield:
						if GameManager.runner_on_third != null and GameManager.outs < 2:
							GameManager.score_run()
							if is_home:
								GameManager.home_pitcher_total_runs_allowed += 1
								GameManager.home_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
							else: 
								GameManager.away_pitcher_total_runs_allowed += 1
								GameManager.away_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
								
							GameManager.evaluate_fatigue_triggers()
							GameManager.runner_on_third = null
							update_scoreboard()
						
						if GameManager.runner_on_second != null:
							GameManager.runner_on_third = GameManager.runner_on_second
							GameManager.runner_on_second = null
						
					if is_infield:
						if GameManager.runner_on_first != null:
							GameManager.runner_on_second = GameManager.runner_on_first
							GameManager.runner_on_first = null
						
				elif mss_value >= 50 and mss_value <= 69:
					if is_outfield or is_right_infield:
						if GameManager.runner_on_third != null and GameManager.outs < 2:
							GameManager.score_run()
							if is_home:
								GameManager.home_pitcher_total_runs_allowed += 1
								GameManager.home_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
							else: 
								GameManager.away_pitcher_total_runs_allowed += 1
								GameManager.away_pitcher_runs_by_inning[-1] += 1
								GameManager.pitcher_last_inning_runs[GameManager.current_pitcher["name"]] = 1
								
							GameManager.evaluate_fatigue_triggers()
							GameManager.runner_on_third = null
							update_scoreboard()
							
						if GameManager.runner_on_second != null:
							GameManager.runner_on_third = GameManager.runner_on_second
							GameManager.runner_on_second = null
				
				handle_out()
				play_out_call()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
				
				GameManager.log_event("%s %d - %d out%s: %s flied out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
			])
			return
			
		"double_play":
			if GameManager.outs >= 2:
				var batter = GameManager.get_current_batter()
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				advance_batter()
				handle_out()
				play_out_call()
				clear_bases()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s grounded out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				return
				
			var batter = get_current_batter()
			var last_digit = mss_value % 10
			var fielder = get_fielder_from_last_digit(last_digit)
			
			var runner_on_first = GameManager.runner_on_first
			var runner_on_second = GameManager.runner_on_second
			var runner_on_third = GameManager.runner_on_third
			
			if runner_on_first == null:
				var half_before = GameManager.half_inning
				var inning_before = GameManager.inning
				var outs_before = GameManager.outs
				
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				advance_batter()
				
				handle_out()
				play_out_call()
				update_base_icons()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s grounded out - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				return
			
			var outs_before = GameManager.outs
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			
			GameManager.record_ab(batter["name"])
			
			if GameManager.runner_on_first!= null:
				GameManager.runner_on_first = null 
				
			handle_out()
			handle_out()
			update_base_icons()
			play_sfx(audio_dict.get_random_sfx("res://audio/Doubleplay.wav"))
			play_out_call()
			
			if GameManager.half_inning == "top":
				play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
			else: 
				play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
				
			GameManager.runner_on_first = null
			
			if runner_on_second != null:
				GameManager.runner_on_third = GameManager.runner_on_second
				GameManager.runner_on_second = null
			
			var outs_after = GameManager.outs
				
			var plural_before = "s"
			if outs_before == 1:
				plural_before = ""
					
			var plural_after = "s"
			if outs_after == 1:
				plural_after = ""
					
			GameManager.log_event("%s %d - %d out%s: %s grounded into double play - %d out%s" % [
				half_before.to_upper(),
				inning_before,
				outs_before,
				plural_before,
				batter["name"],
				outs_after,
				plural_after
			])
			return
		
		"walk":
			var batter = get_current_batter()
			advance_walk(batter)
			
		"hit":
			var hit_type = details.get("type","")
			var batter = get_current_batter()
			if details.has("defensive_check") and details.defensive_check == true: 
				
				var fielder = details.fielder
				var fielder_stats = GameManager.get_fielder_stats(fielder)
				print("Debug Fielder Stats", fielder_stats)
				var fielder_trait = fielder_stats.get("trait", "")
				print("Debug Fielder Trait:", fielder_trait)
				
				var original_def_roll = randi_range(1, 12)
				var def_roll = original_def_roll
				print("Debug: bdef:", original_def_roll)
				match fielder_trait:
					"D+": 
						def_roll += 1
						print("D+", def_roll)
					"D-": 
						def_roll -= 1
						print("D-", def_roll)
					
				def_roll += GameManager.current_weather_idef_modifer
				
				print("Debug: WDEF:", def_roll)
				
				if fielder in [3, 4, 5, 6]:
					if GameManager.stadium_quirk == "SB-1IDEF+1":
						def_roll += 1
						print("IDEF+1")
					elif GameManager.stadium_quirk == "SB+1IDEF-1":
						def_roll -= 1
						print("IDEF-1")
				
				if GameManager.stadium_quirk == "LFDEF-1" and fielder == 7:
					print("SQ: LFDEF-1")
					def_roll -= 1
					
				if GameManager.stadium_quirk == "CFDEF-1" and fielder == 8:
					print("SQ: CFDEF-1")
					def_roll -= 1
					
				if GameManager.stadium_quirk == "RFDEF-1" and fielder == 9:
					print("SQ: RFDEF-1")
					def_roll -= 1
					
				if GameManager.stadium_quirk == "OFDEF+1" and fielder in [7, 8, 9]:
					print("SQ: OFDEF+1")
					def_roll += 1
					
				if GameManager.stadium_quirk == "OFDEF-1" and fielder in [7, 8, 9]:
					print("SQ: OFDEF-1")
					def_roll -= 1
				
				def_roll = clamp(def_roll, 1, 12)
				
				if def_roll <= 2:
					print("Error")
					
					match hit_type:
						"single": hit_type = "double"
						"double": hit_type = "triple"
						"triple": hit_type = "home_run"
						"home_run": pass
						
					details.type = hit_type
				elif def_roll >= 11:
					print("DEF Check Result: Out - Highlight play")
					
					var half_before = GameManager.half_inning
					var inning_before = GameManager.inning
					var outs_before = GameManager.outs
					
					GameManager.record_ab(batter["name"])
					GameManager.record_bf()
					
					advance_batter()
					handle_out()
					update_base_icons()
					update_scoreboard()
					
					play_sfx(audio_dict.get_random_sfx("Defcheckyes"))
					
					if GameManager.half_inning == "top":
						play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
					
					var outs_after = GameManager.outs
				
					var plural_before = "s"
					if outs_before == 1:
						plural_before = ""
					
					var plural_after = "s"
					if outs_after == 1:
						plural_after = ""
					
					GameManager.log_event("%s %d - %d out%s: %s robbed on a highlight defensive play! - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter["name"],
					outs_after,
					plural_after
				])
				
					result.category = "out"
					result.details = {"type": "Groundout"}
					return result
					
				else: 
					print("Hit")
					
			hit_type = details.type 
			
			match hit_type:
				"single":
					advance_single(batter, result.details.runners_advance)
		
				"double":
					advance_double(batter)
		
				"triple":
					advance_triple(batter)
		
				"home_run":
					advance_home_run(batter)
		
				_:
					print ("Unknown hit type:", hit_type)
					
		"error_check":
			var batter = get_current_batter()
			var batter_name = batter["name"]
			
			var last_digit = mss_value % 10
			var fielder = get_fielder_from_last_digit(last_digit)
			var pos_name = get_position_name(fielder)
			
			var half_before = GameManager.half_inning
			var inning_before = GameManager.inning
			var outs_before = GameManager.outs
			var defense_roll = randi_range(1,12)
			
			if defense_roll <=2:
				play_sfx("res://audio/Error.wav")
				
				if GameManager.half_inning == "top":
					play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
				else: 
					play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
				advance_error(batter)
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				GameManager.log_event("%s %d - %d out%s: %s reaches on error by the %s - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter_name,
					pos_name,
					outs_after,
					plural_after
				])
				
				return
				
			else:
				GameManager.record_ab(batter["name"])
				
				GameManager.record_bf()
				
				advance_batter()
				
				handle_out()
				
				var outs_after = GameManager.outs
				
				var plural_before = "s"
				if outs_before == 1:
					plural_before = ""
					
				var plural_after = "s"
				if outs_after == 1:
					plural_after = ""
					
				update_base_icons()
				update_scoreboard()
					
				GameManager.log_event("%s %d - %d out%s: %s out on the %s - %d out%s" % [
					half_before.to_upper(),
					inning_before,
					outs_before,
					plural_before,
					batter_name,
					pos_name,
					outs_after,
					plural_after
				])
				
				return

func check_pitcher_fatigue_popup():
	if  fatigue_warning_shown:
		return
		
	var fatigue = GameManager.current_pitcher_die
	if fatigue <= -12:
		fatigue_warning_shown = true
		show_bullpen_prompt()

func show_bullpen_prompt():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Current Pitch Die at -12. Do you want to swap pitchers?"
	dialog.get_ok_button().text = "Yes"
	dialog.get_cancel_button().text = "No"
	
	dialog.connect("confirmed", Callable(self, "_on_bullpen_confirmed"))
	
	add_child(dialog)
	dialog.popup_centered()
	
func _on_bullpen_confirmed():
	open_bullpen_menu()
	
func _on_bullpen_button_pressed():
	play_sfx("res://audio/Inthebullpen.wav")
	open_bullpen_menu()

func open_bullpen_menu():
	bullpen_menu.clear()
	
	var bullpen = GameManager.home_bullpen if GameManager.half_inning == "top" else GameManager.away_bullpen

	for i in range(bullpen.size()):
		var p = bullpen[i]
		
		if p.get("position", "") == "RP":
			var name = p.get("name", "unknown")
			var die = p.get("PitchDie", 0)

			bullpen_menu.add_item("%s (Die: %s)" % [name, str(die)], i)
			
	bullpen_menu.popup()
	
func _on_bullpen_menu_id_pressed(id):
	var bullpen = GameManager.home_bullpen if GameManager.half_inning == "top" else GameManager.away_bullpen
	var new_pitcher = bullpen[id]
	
	if GameManager.half_inning == "top":
		GameManager.home_pitcher = new_pitcher
	else:
		GameManager.away_pitcher = new_pitcher
	
	GameManager.current_pitcher = new_pitcher
	
	var name = new_pitcher["name"]
	
	if GameManager.half_inning == "top":
		if not GameManager.home_pitchers_used.has(name):
			GameManager.home_pitchers_used.append(name)
	else: 
		if not GameManager.away_pitchers_used.has(name):
			GameManager.away_pitchers_used.append(name)
	
	GameManager.initialize_pitcher_fatigue(new_pitcher)
		
	var half_now = GameManager.half_inning
	var inning_now = GameManager.inning
	var outs_now = GameManager.outs
	
	var plural = "s"
	if outs_now ==1: 
		plural = ""
		
	GameManager.log_event("%s %d - %d out%s: %s enters the game as the new pitcher" % [
		half_now.to_upper(),
		inning_now,
		outs_now,
		plural,
		new_pitcher["name"]
	])
		
	update_pitcher_display()
	
func handle_oddity():
	var oddity_roll = randi_range(1, 10)
	
	match oddity_roll:
		1: fan_interference()
		2: pickoff()
		3: bad_call_first()
		4: bad_call_home()
		5: hbp()
		6: wild_pitch()
		7: dropped_third_strike()
		8: balk()
		9: pitcher_error()
		10: catcher_interference()
	
func fan_interference():
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var pd_roll = roll_pitcher_die()
	var pd_even = (pd_roll % 2 == 0)

	if pd_even:
		GameManager.record_ab(batter["name"])
		GameManager.record_bf()
		advance_batter()
		handle_out()
		
		play_sfx("res://audio/Umpout")
		
		if GameManager.half_inning == "bottom":
			play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
		
		var outs_after = GameManager.outs
				
		var plural_before = "s"
		if outs_before == 1:
			plural_before = ""
					
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""

		GameManager.log_event("%s %d - %d out%s: %s out on Fan Interference call. - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
			outs_after,
			plural_after
		])
		return
	else:
		var plural_before = "s"
		if outs_before == 1:
			plural_before = ""
		
		GameManager.log_event("%s %d - %d outs: %s homers just out of the fielder's reach" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before
		])
		advance_home_run(batter)
		return
		
		
func pickoff():
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs

	if GameManager.runner_on_first != null:
		play_sfx("res://audio/Pickoff.mp3")
		handle_out()
		var outs_after = GameManager.outs
				
		var plural_before = "s"
		if outs_before == 1:
				plural_before = ""
					
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""

		GameManager.log_event("%s %d - %d out%s: Pick-off! Runner caught leaning. - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			outs_after,
			plural_after
		])
	else: 
		GameManager.log_event("Pick-off attempt, but no runner on first. Play continues.")
	return
	
func bad_call_first():
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var pd_roll = roll_pitcher_die()
	var pd_even = (pd_roll % 2 == 0)
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
					
	if pd_even: 
		bcaf_out()
		GameManager.record_ab(batter["name"])
		GameManager.record_bf()
		advance_batter()
		handle_out()
		
		var outs_after = GameManager.outs
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""
		
		GameManager.log_event("%s %d - %d out%s: Close call - Umpire rules %s out at first. - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
			outs_after,
			plural_after
		])
		return
	else: 
		bcaf_safe()
		GameManager.log_event("%s %d - %d out%s: Close call - Umpire rules %s safe at first." % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
		])
		
		advance_to_first_silent(batter)
		return
		
func bad_call_home():
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
	
	var pd_roll = roll_pitcher_die()
	var pd_even = (pd_roll % 2 == 0)
	
	if pd_even:
		GameManager.record_strikeout()
		GameManager.record_ab(batter["name"])
		GameManager.record_bf()
		advance_batter()
		handle_out()
		
		play_sfx(audio_dict.get_random_sfx("strikeout"))
		
		if GameManager.half_inning == "top":
			play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
		else: 
			play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
		
		var outs_after = GameManager.outs
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""
		
		GameManager.log_event("%s %d - %d out%s: Ump calls Strike 3.  %s out. - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
			outs_after,
			plural_after
		])
		return
	else:
		GameManager.log_event("%s %d - %d out%s: Ump calls Ball 4. %s takes their base." % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
		])
		
		play_sfx(audio_dict.get_random_sfx("walk"))
		
		if GameManager.half_inning == "top":
			play_random_reaction(audio_dict.get_random_sfx("boo"), 2.0)
		else: 
			play_random_reaction(audio_dict.get_random_sfx("cheer"), 2.0)
		
		advance_to_first_walk_silent(batter)
		return

func hbp():
	play_sfx("res://audio/Beaned.mp3")
	var batter = GameManager.get_current_batter()
	var batter_name = GameManager.get_current_batter().get("name", "Unknown")
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: %s is beaned by that pitch." % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before,
		batter_name,
		])
	advance_to_first_walk_silent(batter)
	return
	
func dropped_third_strike():
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
	
	var roll = randi_range(1,8)
		
	if roll <= 3:
		play_sfx(audio_dict.get_random_sfx("strikeout"))
		GameManager.record_strikeout()
		GameManager.record_ab(batter["name"])
		GameManager.record_bf()
		advance_batter()
		handle_out()
		
		var outs_after = GameManager.outs
		var plural_after = "s"
		if outs_after == 1:
			plural_after = ""
		
		GameManager.log_event("%s %d - %d out%s: %s out on strikes. - %d out%s" % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name,
			outs_after,
			plural_after
		])
		return
	else: 
		play_sfx("res://audio/Umpsafe.wav")
		
		await get_tree().create_timer(0.35).timeout
		
		play_sfx("res://audio/single.mp3")
		
		GameManager.log_event("%s %d - %d out%s: %s makes it to first on a dropped third strike." % [
			half_before.to_upper(),
			inning_before,
			outs_before,
			plural_before,
			batter_name
		])
		advance_to_first_silent(batter)
		return
	
func balk():
	play_sfx("res://audio/Balk.wav")
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: Pitcher commits a Balk - all runners advance." % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before
	])
	GameManager.advance_runners_only(1)
	return
	
func wild_pitch():
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
	
	GameManager.log_event("%s %d - %d out%s: Woah, the pitch goes wild." % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before
	])
	GameManager.advance_runners_only(1)
	return
	
func catcher_interference():
	play_catcher_interference()
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
		
	GameManager.log_event("%s %d - %d out%s: Catcher Interference - %s takes first." % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before,
		batter_name,
		])
	advance_to_first_walk_silent(batter)
	return
	
func pitcher_error():
	var batter = GameManager.get_current_batter()
	var batter_name = batter["name"]
	
	var half_before = GameManager.half_inning
	var inning_before = GameManager.inning
	var outs_before = GameManager.outs
	
	var plural_before = "s"
	if outs_before == 1:
		plural_before = ""
		
	GameManager.log_event("%s %d - %d out%s: An egregious error by the Pitcher - %s takes first." % [
		half_before.to_upper(),
		inning_before,
		outs_before,
		plural_before,
		batter_name,
		])
	advance_to_first_silent(batter)
	return
		
func update_weather_icon():
	if GameManager.current_weather_icon != "": 
		$WeatherIcon.texture = load("res://icon/%s.png" % GameManager.current_weather_icon)
		$WeatherIcon.flip_h = GameManager.wind_flip
		
func _on_runners_changed():
	update_base_icons()

func advance_to_first_silent(batter):
	GameManager.record_bfhit()
	GameManager.record_single(batter["name"])
	GameManager.advance_runners_only(1)
	GameManager.runner_on_first = batter
	update_base_icons()
	advance_batter()
	
func advance_to_first_walk_silent(batter):
	GameManager.record_bf()
	GameManager.record_walk(batter["name"])
	GameManager.record_pitcher_walk()
	
	if GameManager.runner_on_first != null:
		GameManager.advance_runners_only(1)
		
	GameManager.runner_on_first = batter
	update_base_icons()
	advance_batter()
	
func advance_error(batter):
	GameManager.record_pa(batter["name"])
	GameManager.record_bf()
	GameManager.advance_runners_only(1)
	GameManager.runner_on_first = batter
	update_base_icons()
	advance_batter()
