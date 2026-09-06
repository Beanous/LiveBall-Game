extends Node

var teams = {}        # FIXED

var away_team_name : String = ""
var home_team_name : String = ""

var away_team = []
var home_team = []

var current_batter = null
var current_pitcher = null

var away_pitcher = null
var home_pitcher = null
var away_dh = null
var home_dh = null

var away_lineup = []
var home_lineup = []

var away_bullpen = []
var home_bullpen = []

var stadiums : Dictionary = {}
var stadium_name : String = ""
var stadium_quirk : String = ""

var current_stadium_weather_variation: int = 0
var current_weather_name: String = ""
var current_weather_icon: String = ""
var current_weather_ht_modifier: int = 0
var current_weather_sb_modifier: int = 0
var current_weather_idef_modifer: int = 0
var wind_flip: bool = false

var current_runners : Dictionary = {}
var outs: int = 0
var inning : int = 1
var half_inning : String = "top"
var away_batter_index : int = 0
var home_batter_index : int = 0
var current_batter_trait : String = ""

var pitcher_die_ladder := [20, 12, 8, 4, -4, -8, -12, -20, -25]

#Fatigue State
var current_pitcher_role: String = ""
var current_pitcher_die: int = 0
var current_pitcher_hand: String = ""
var current_batter_hand: String = ""
var pitcher_fatigue_index: int = 0
var last_out_was_strikeout: bool = false
var top_fatigue_7_triggered = false
var top_fatigue_8_triggered = false
var top_fatigue_9_triggered = false
var bottom_fatigue_7_triggered = false
var bottom_fatigue_8_triggered = false
var bottom_fatigue_9_triggered = false
var away_skip_inning_fatigue = false
var home_skip_inning_fatigue = false

#Tracking for Home Fatigue
var home_pitcher_runs_by_inning: Array[int] = []
var home_pitcher_total_runs_allowed: int = 0
var home_pitcher_scoreless_inning_streak: int = 0
var home_pitcher_consecutive_strikeouts: int = 0
var home_fatigue_drops_this_inning: int = 0
var home_fatigue_recovers_this_inning: int = 0

#Tracking for Away Fatigue
var away_pitcher_runs_by_inning: Array[int] = []
var away_pitcher_total_runs_allowed: int = 0
var away_pitcher_scoreless_inning_streak: int = 0
var away_pitcher_consecutive_strikeouts: int = 0
var away_fatigue_drops_this_inning: int = 0
var away_fatigue_recovers_this_inning: int = 0

var last_pitch_die_used: int = 0

var pitcher_inning_log := {}
var pitcher_last_inning_runs := {}

var away_score: int = 0
var home_score: int = 0

var runner_on_first = null
var runner_on_second = null
var runner_on_third = null

var bases :={
	1: null, 
	2: null, 
	3: null
}

var base_empty_texture = preload("res://Actual White Dot.png")
var base_occupied_texture = preload("res://Actual Gold Dot.png")

var pending_steal_runner: Variant = null
var pending_steal_target_base: int = 0

var play_by_play : Array = []
var batter_stats = {}
var pitcher_stats = {}

var home_pitchers_used: Array[String] = []
var away_pitchers_used: Array[String] = []

var game_over: bool = false
var winner_team: String = ""
var logo_path: String = ""

var pitcher_when_away_team_took_lead = null
var pitcher_when_home_team_took_lead = null
var pitcher_who_allowed_go_ahead_run = null
var home_pitcher_when_took_lead = null
var away_pitcher_when_took_lead = null

var last_snapshot : Array = []

signal play_by_play_updated
signal runners_changed

func _ready():
	load_csv("res://DBL Roster.csv")
	load_stadium_csv()
	build_bullpens()
	home_pitcher_runs_by_inning = [0]
	away_pitcher_runs_by_inning = [0]
	
func load_csv(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Could not open CSV:", path)
		return

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		if line == "" or line.begins_with("Name"):
			continue

		# Try comma first
		var parts = line.split(",")

		if parts.size() < 10:
			print("Line did not split correctly:", parts)
			continue

		var player_name = parts[0]
		var position = parts[2]
		var hand = parts[3]
		var team_name = parts[9]

		if not teams.has(team_name):
			teams[team_name] = []

		teams[team_name].append({
			"name": player_name,
			"position": position,
			"hand": hand,
			"BatTarget": int(parts[4]),
			"OnBaseTarget": int(parts[5]),
			"PitchDie": int(parts[7]),
			"trait": parts[8]
		})
		
func load_stadium_csv():
	var file = FileAccess.open("res://Stadiums.csv", FileAccess.READ)
	if file == null:
		print("Could not load Stadiums.csv")
		return
	file.get_line()
	
	while file.get_position() < file.get_length():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
			
		var columns = line.split(",")
		
		var team = columns[0]
		var ballpark = columns[1]
		var quirk = columns[2]
		var variation = int(columns[3])
		
		stadiums[team] = {
			"ballpark": ballpark,
			"quirk": quirk,
			"variation": variation
			}
			
func build_bullpens():
	home_bullpen.clear()
	away_bullpen.clear()
	
	for player in teams.get(home_team_name, []):
		if player.get("position", "") == "RP":
			home_bullpen.append(player)
			
	for player in teams.get(away_team_name, []):
		if player.get("position", "") == "RP":
			away_bullpen.append(player)
		
var current_pitcher_stats

func get_current_pitch_die() -> int: 
	return current_pitcher_die
	
func apply_fatigue_change(amount: int):
	var name = GameManager.current_pitcher["name"]
	var role = pitcher_stats[name]["role"]
	
	var old_index = pitcher_stats[name]["fatigue_index"]
	var new_index = old_index - amount
	
	if role == "SP":
		new_index = max(new_index, 1)
		
	new_index = clamp(new_index, 0, pitcher_die_ladder.size() - 1)
	
	pitcher_stats[name]["fatigue_index"] = new_index
	pitcher_stats[name]["current_die"] = pitcher_die_ladder[new_index]
	
	pitcher_fatigue_index = new_index
	current_pitcher_die = pitcher_stats[name]["current_die"]
	
	print("Fatigue chanage:", amount,
	" Pitcher:", name,
	" New Die:", current_pitcher_die,
	" Old Index:", old_index,
	" New Index:", new_index)
	
func initialize_pitcher_fatigue(pitcher):
	var name = pitcher["name"]
	current_pitcher_stats = pitcher_stats[name]
	
	if current_pitcher_stats["fatigue_index"] == null:
		var base_die = pitcher_stats[name]["base_die"]
		var idx = pitcher_die_ladder.find(base_die)
		if idx == -1:
			idx = 2
		
		current_pitcher_stats["fatigue_index"] = idx
		current_pitcher_stats["current_die"] = base_die
		
	if pitcher == GameManager.away_pitcher:
		var road_trait = pitcher.get("trait", "")
		var idx = current_pitcher_stats["fatigue_index"]
		
		if road_trait == "R+":
			if idx > 0:
				idx -= 1
				print("Debug: R+ Applied")
		elif road_trait == "R-":
			if idx < pitcher_die_ladder.size() - 1:
				idx += 1
				print("Debug R- Applied")
	
		current_pitcher_stats["fatigue_index"] = idx
		current_pitcher_stats["current_die"] = pitcher_die_ladder[idx]
		
	pitcher_fatigue_index = current_pitcher_stats["fatigue_index"]
	current_pitcher_die = current_pitcher_stats["current_die"]
	
	current_pitcher_role = current_pitcher_stats["role"]
	current_pitcher_hand = pitcher.get("hand", "R")
	
func evaluate_fatigue_triggers():
	var pitcher = GameManager.current_pitcher
	if pitcher == null: 
		return
		
	var pitcher_name = pitcher["name"]
	var pstats = pitcher_stats.get(pitcher_name, {})
	var role = pitcher.get("position", "SP")
	
	var inning_now = inning
	var half_now = GameManager.half_inning
	
	var is_home = (pitcher == home_pitcher)
	var is_away = (pitcher == away_pitcher)
	
	var runs_by_inning
	var total_runs_allowed
	var scoreless_streak
	var strikeout_streak
	
	if is_home:
		runs_by_inning = home_pitcher_runs_by_inning
		total_runs_allowed = home_pitcher_total_runs_allowed
		scoreless_streak = home_pitcher_scoreless_inning_streak
		strikeout_streak = home_pitcher_consecutive_strikeouts
	else: 
		runs_by_inning = away_pitcher_runs_by_inning
		total_runs_allowed = away_pitcher_total_runs_allowed
		scoreless_streak = away_pitcher_scoreless_inning_streak
		strikeout_streak = away_pitcher_consecutive_strikeouts
	
	print("Debug Trigger Check -", inning_now, 
	" Half:", half_now,
	" RunsThisInning:", runs_by_inning[-1],
	" TotalER:", total_runs_allowed,
	" ScorelessStreak:", scoreless_streak,
	" StrikeoutStreal", strikeout_streak,
	" FatigueIndex:", pitcher_fatigue_index,
	" CurrentDie:", current_pitcher_die)
	
	#Relievers
	if role == "RP":
		if runs_by_inning[-1]  > 0:
			print("RP fatigue drop: run allowed")
			apply_fatigue_change(-1)
			
		var outs_pitched = pstats.get("outs", 0)
	
		if outs_pitched > 0: 
			var pitcher_trait = pitcher.get("trait", "")
		
			if pitcher_trait == "ST+": 
				if outs_pitched % 6 == 0:
					print("PR fatigue drop: ST+ 6 outs")
					apply_fatigue_change(-1)
			else: 
				if outs_pitched % 3 == 0:
					print("RP fatigue drop: 3 outs")
					apply_fatigue_change(-1)
		return
	
	#Starters
	if total_runs_allowed == 5:
		print("Fatigue drop due to runs")
		apply_fatigue_change(-1)
		
	if total_runs_allowed > 5: 
		print("Fatigue drop due to runs")
		apply_fatigue_change(-1)
		
	if inning_now >= 7 and runs_by_inning[-1] >0:
		print("Fatigue drop due to late game run")
		apply_fatigue_change(-1)
		
	if half_now == "top":
		var pitcher_trait = pitcher.get("trait", "")
		var home_skip_inning_fatigue = false
		
		if pitcher_trait == "ST+":
			if inning_now >= 7 and (inning_now % 2) == 1:
				home_skip_inning_fatigue = true 
				print("Debug: ST+ active")
				
		if inning_now == 7 and not top_fatigue_7_triggered:
			if not home_skip_inning_fatigue:
				print("Fatigue drop due to inning 7")
				apply_fatigue_change(-1)
				top_fatigue_7_triggered = true
			else: 
				print("ST+")
				top_fatigue_7_triggered = true
		
		if inning_now == 8 and not top_fatigue_8_triggered:
			print("Fatigue drop due to inning 8")
			apply_fatigue_change(-1)
			top_fatigue_8_triggered = true
		
		if inning_now == 9 and not top_fatigue_9_triggered:
			if not home_skip_inning_fatigue:
				print("Fatigue drop due to inning 9")
				apply_fatigue_change(-1)
				top_fatigue_9_triggered = true
			else: 
				print("ST+")
				top_fatigue_9_triggered = true
		
	if half_now == "bottom":
		var pitcher_trait = pitcher.get("trait", "")
		var away_skip_inning_fatigue = false
		
		if pitcher_trait == "ST+":
			if inning_now >= 7 and (inning_now % 2) == 1:
				away_skip_inning_fatigue = true 
				print("Debug: ST+ active")
		
		if inning_now == 7 and not bottom_fatigue_7_triggered:
			if not away_skip_inning_fatigue:
				print("Fatigue drop due to inning 7")
				apply_fatigue_change(-1)
				bottom_fatigue_7_triggered = true
			else: 
				print("ST+")
				bottom_fatigue_7_triggered = true
		
		if inning_now == 8 and not bottom_fatigue_8_triggered:
			print("Fatigue drop due to inning 8")
			apply_fatigue_change(-1)
			bottom_fatigue_8_triggered = true
		
		if inning_now == 9 and not bottom_fatigue_9_triggered:
			if not away_skip_inning_fatigue:
				print("Fatigue drop due to inning 9")
				apply_fatigue_change(-1)
				bottom_fatigue_9_triggered = true
			else: 
				print("ST+")
				bottom_fatigue_9_triggered = true
		
	if strikeout_streak >= 3:
		apply_fatigue_change(+1)
		if is_home:
				home_pitcher_consecutive_strikeouts = 0
		else: 
				away_pitcher_consecutive_strikeouts = 0
	
	if inning_now >= 7 and scoreless_streak >= 3:
		print("Starter fatigue recovery: Late-Game Scoreless")
		apply_fatigue_change(+1)
		
		if is_home:
			home_pitcher_scoreless_inning_streak = 0
		else: 
			away_pitcher_scoreless_inning_streak = 0
			
func _test():
	print ("GameManager READY")
	load_csv("res://dbl2.0/DBL Roster.csv")
	print("Loaded Teams", teams.key())
	
func log_event(text: String):
	play_by_play.append(text)
	emit_signal("play_by_play_updated")
	
func get_speed_trait(player: Dictionary) -> String:
	var t = player["trait"]
	
	if t == "S+":
		return "S+"
	if t == "S-":
		return "S-"
		
	return "S"
	
func _on_button_pressed():
	get_tree().change_scene_to_file("res://TeamSelection.tscn"
)

func get_current_batter():
	var batter
	if half_inning == "top":
		batter = away_lineup[away_batter_index]
	else:
		batter = home_lineup[home_batter_index]
		
	current_batter_hand = batter.get("hand", "R")
	return batter

func get_fielder_stats(fielder_num: int) -> Dictionary:
	var lineup = home_lineup if half_inning == "top" else away_lineup
	
	var pos_name = ""
	match fielder_num:
		1: pos_name = "P"
		2: pos_name = "C"
		3: pos_name = "1B"
		4: pos_name = "2B"
		5: pos_name = "3B"
		6: pos_name = "SS"
		7: pos_name = "LF"
		8: pos_name = "CF"
		9: pos_name = "RF"
		
	for player in lineup:
		if player.get("position", "") == pos_name:
			return player
			
	return {}

func advance_runners_only(bases_to_advance):
	if runner_on_third != null:
		score_run()
		runner_on_third = null
	
	if runner_on_second != null: 
		runner_on_third = runner_on_second
		runner_on_second = null
		
	if runner_on_first != null: 
		runner_on_second = runner_on_first
		runner_on_first = null
		
	emit_signal("runners_changed")

func ai_choose_action() -> String:
	var batter = get_current_batter()
	var bt = batter["BatTarget"]
	var has_c_plus = batter["trait"] == "C+"
	
	var r1 = GameManager.runner_on_first
	var r2 = GameManager.runner_on_second
	@warning_ignore("unused_variable")
	var r3 = GameManager.runner_on_third
	
	#Bunt Decision
	var should_bunt := false
	
	if outs <= 1:
		if r1 != null or r2 != null:
			if bt < 25:
				should_bunt = true
			elif has_c_plus:
				should_bunt = true
				
	if should_bunt:
		return "bunt"
	
	#Steal Decision
	var steal_runner: Variant = null
	var steal_target_base: int = 0
	var should_steal := false
	
	#Runner on First
	if r1 != null:
		var s_trait = get_speed_trait(r1)
		
		if GameManager.runner_on_second == null:
			if s_trait != "S-":
				if outs == 0:
					should_steal = true
					steal_runner = r1
					steal_target_base = 2
				elif s_trait == "S+" and outs <= 1: 
					should_steal = true
					steal_runner = r1
					steal_target_base = 2
			
	#Steal 3rd
	if not should_steal and r2 != null:
		var s_trait2 = get_speed_trait(r2)
		
		if GameManager.runner_on_third == null:
			if s_trait2 == "S+" and outs <= 1:
				should_steal = true
				steal_runner = r2
				steal_target_base = 3
			
	if should_steal:
		pending_steal_runner = steal_runner
		pending_steal_target_base = steal_target_base
		return "steal"
		
	return "pitch"
		
func less_than_two_outs() -> bool:
	return outs < 2
	
func runner_on_first_is_fast() -> bool:
	return current_runners.has("1B") and current_runners["1B"]["speed"] == "S+"
	
func batter_is_c_plus() -> bool:
	return current_batter_trait == "C+"
	
func score_run():
	var pitcher_name = current_pitcher["name"]
	pitcher_stats[pitcher_name]["ER"] += 1
	print("Score Run Fired Half:", half_inning)
	
	var was_tied = (home_score == away_score)
	var home_was_leading = (home_score > away_score)
	var away_was_leading = (away_score > home_score)
	
	if half_inning == "top":
		away_score += 1
	else:
		home_score += 1
	
	if (was_tied or home_was_leading != (home_score > away_score)):
		update_lead_change_pitcher()
	
	if was_tied:
		if half_inning == "top" and away_score > home_score:
				pitcher_who_allowed_go_ahead_run = pitcher_name
		elif half_inning == "bottom" and home_score > away_score: 
				pitcher_who_allowed_go_ahead_run = pitcher_name
	
	elif home_was_leading and away_score > home_score:
			pitcher_who_allowed_go_ahead_run = pitcher_name
			
	elif away_was_leading and home_score > away_score:
			pitcher_who_allowed_go_ahead_run = pitcher_name
		
	check_game_over()
	
func roll_weather():
	print("Roll Weather: variation =", current_stadium_weather_variation)
	var variation = current_stadium_weather_variation
	var roll = randi_range(1, 100)
	
	var mud_min = 1
	var dry_min = 1
	var wind_out_min = 1
	var wind_in_min = 1
	
	var sun_base = 96
	
	var weather_total = 4 + variation
	if weather_total > 95: 
		weather_total = 95
		
	var each_weather = int(weather_total / 4)
	
	var sun_cutoff = 100 - weather_total
	var wind_out_cutoff = sun_cutoff + each_weather
	var wind_in_cutoff = wind_out_cutoff + each_weather
	var dry_cutoff = wind_in_cutoff + each_weather
	var mud_cutoff = 100
	
	if roll <= sun_cutoff:
		set_weather_sun()
	elif roll <= wind_out_cutoff:
		set_weather_wind_out()
	elif roll <= wind_in_cutoff:
		set_weather_wind_in()
	elif roll <= dry_cutoff:
		set_weather_dry()
	else: 
		set_weather_mud()
	
func set_weather_sun():
	current_weather_name = "Sun"
	current_weather_icon = "sun"
	current_weather_ht_modifier = 0
	current_weather_sb_modifier = 0
	current_weather_idef_modifer = 0
	
func set_weather_wind_out():
	current_weather_name = "Wind Out"
	current_weather_icon = "wind"
	current_weather_ht_modifier = 1
	current_weather_sb_modifier = 0
	current_weather_idef_modifer = 0
	wind_flip = false
	
func set_weather_wind_in():
	current_weather_name = "Wind In"
	current_weather_icon = "wind"
	current_weather_ht_modifier = -1
	current_weather_sb_modifier = 0
	current_weather_idef_modifer = 0
	wind_flip = true
	
func set_weather_dry():
	current_weather_name = "Dry"
	current_weather_icon = "dry"
	current_weather_ht_modifier = 0
	current_weather_sb_modifier = 1
	current_weather_idef_modifer = 1
	
func set_weather_mud():
	current_weather_name = "Mud"
	current_weather_icon = "mud"
	current_weather_ht_modifier = 0
	current_weather_sb_modifier = -1
	current_weather_idef_modifer = -1

func check_game_over() -> bool:
	var away = away_score
	var home = home_score
	var inning_now = inning
	var half_now = half_inning

	if half_now == "bottom" and inning >= 9:
		if home > away: 
			end_game("Home Team Wins!")
			return true
			
	if inning_now == 9 and half_now == "bottom":
		if home > away:
			end_game("Home Team Wins!")
			return true
	
	if inning_now == 10 and half_now == "top":
		if away > home:
			end_game("Away Team Wins!")
			return true
			
	if inning_now > 9:
		if half_now == "bottom" and home > away:
			end_game("Home Team Wins!")
			return true
			
		if half_now == "top" and away > home: 
			end_game("Away Team Wins")
			return true
			
	return false
	
func determine_winning_pitcher():
	var winning_team = GameManager.winner_team
	var lead_pitcher = null
	
	if winning_team == home_team_name:
		lead_pitcher = pitcher_when_home_team_took_lead
	else: 
		lead_pitcher = pitcher_when_away_team_took_lead
		
	if lead_pitcher == null:
		lead_pitcher = home_pitcher["name"] if winning_team == home_team_name else away_pitcher["name"]
		
	return lead_pitcher
	
func determine_losing_pitcher():
	if GameManager.pitcher_who_allowed_go_ahead_run != null:
		return GameManager.pitcher_who_allowed_go_ahead_run
	
	var winning_team = GameManager.winner_team
	var losing_pitcher = null
	
	if winning_team == home_team_name:
		losing_pitcher = pitcher_when_away_team_took_lead
		if losing_pitcher == null: 
			losing_pitcher = away_pitcher["name"]
	else: 
		losing_pitcher = pitcher_when_home_team_took_lead
		if losing_pitcher == null: 
			losing_pitcher = home_pitcher["name"]
			
	return losing_pitcher
	
func get_saving_pitcher(winning_pitcher_name):
	var lead = abs(home_score - away_score)
	
	if lead > 3:
		return null
		
	var final_pitcher_name: String = ""
	
	if GameManager.winner_team == home_team_name:
		if home_pitchers_used.size() <= 1:
			return null
		final_pitcher_name = home_pitchers_used[-1]
	else: 
		if away_pitchers_used.size() <= 1:
			return null
		final_pitcher_name = away_pitchers_used[-1]

	if final_pitcher_name == winning_pitcher_name:
		return null
		
	return final_pitcher_name
	
func end_game(message: String):

	print("END_GAME FIRED — scene changing")
	game_over = true

	if message.contains("Home"):
		GameManager.winner_team = home_team_name
		GameManager.logo_path = get_logo_path(home_team_name)
	else: 
		GameManager.winner_team = away_team_name
		GameManager.logo_path = get_logo_path(away_team_name)
		
	winner_team = GameManager.winner_team
	
	var wp = determine_winning_pitcher()
	var lp = determine_losing_pitcher()
	var sp = get_saving_pitcher(wp)
	
	GameManager.log_win_loss(wp, lp, sp)
		
	save_game_snapshot()
	export_boxscore_to_csv(GameManager.last_snapshot)
		
	get_tree().change_scene_to_file("res://GameOverPopup.tscn")
	
func get_logo_path(team_name: String) -> String:
	var base = "res://logos/%s" % team_name
	var exts = [".png", ".jpg", ".jpeg"]
	
	for ext in exts:
		var path = base + ext
		if FileAccess.file_exists(path):
			return path
			
	return ""
	
func reset_game():
	away_team_name = ""
	home_team_name = ""
	away_team.clear()
	home_team.clear()
	away_lineup.clear()
	home_lineup.clear()
	away_bullpen.clear()
	home_bullpen.clear()
	stadium_name = ""
	stadium_quirk = ""
	current_stadium_weather_variation = 0
	current_weather_name = ""
	current_weather_icon = ""
	current_weather_ht_modifier = 0
	current_weather_sb_modifier = 0
	current_weather_idef_modifer = 0
	wind_flip = false
	current_runners.clear()
	outs = 0
	inning = 1
	half_inning = "top"
	away_batter_index = 0
	home_batter_index = 0
	current_batter_trait = ""
	current_pitcher_role = ""
	current_pitcher_die = 0
	current_pitcher_hand = ""
	current_batter_hand = ""
	pitcher_fatigue_index = 0
	top_fatigue_7_triggered = false
	top_fatigue_8_triggered = false
	top_fatigue_9_triggered = false
	bottom_fatigue_7_triggered = false
	bottom_fatigue_8_triggered = false
	bottom_fatigue_9_triggered = false
	home_pitcher_runs_by_inning.clear()
	home_pitcher_total_runs_allowed = 0
	home_pitcher_scoreless_inning_streak = 0
	home_pitcher_consecutive_strikeouts = 0
	home_fatigue_drops_this_inning = 0
	home_fatigue_recovers_this_inning = 0
	away_pitcher_runs_by_inning.clear()
	away_pitcher_total_runs_allowed = 0
	away_pitcher_scoreless_inning_streak = 0
	away_pitcher_consecutive_strikeouts = 0
	away_fatigue_drops_this_inning = 0
	away_fatigue_recovers_this_inning = 0
	last_pitch_die_used = 0
	away_score = 0
	home_score = 0
	runner_on_first = null
	runner_on_second = null
	runner_on_third = null
	bases[1] = null
	bases[2] = null
	bases[3] = null
	pending_steal_runner = null
	pending_steal_target_base = 0
	play_by_play.clear()
	game_over = false
	winner_team = ""
	logo_path = ""

func init_batter_stats(team_roster):
	for player in team_roster:
		var name = player["name"]
		batter_stats[name] = {
			"PA": 0, 
			"AB": 0,
			"H": 0,
			"BB": 0,
			"1B": 0, 
			"2B": 0,
			"3B": 0,
			"HR": 0,
			"TB": 0,
			"SB": 0
		}
		
func init_pitcher_stats(team_roster):
	for player in team_roster:
		var name = player["name"]
		
		if player["position"] == "SP" or player["position"] == "RP":
			pitcher_stats[name] = {
				"name": name,
				"outs": 0,
				"BF": 0,
				"ER": 0,
				"H": 0,
				"BB": 0,
				"K": 0, 
				
				"fatigue_index": null,
				"current_die": null,
				"base_die": player["PitchDie"],
				"role": player["position"]
			}
		
func convert_outs_to_ip(outs):
	var full_innings = outs /3
	var remainder = outs % 3
	return float(full_innings) + float(remainder) * 0.1
	
func record_bfhit():
	var pitcher_name = GameManager.current_pitcher["name"]
	GameManager.pitcher_stats[pitcher_name]["BF"] += 1
	GameManager.pitcher_stats[pitcher_name]["H"] += 1
	
func record_bf():
	var pitcher_name = GameManager.current_pitcher["name"]
	GameManager.pitcher_stats[pitcher_name]["BF"] += 1
		
func record_single(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["AB"] += 1
	s["H"] += 1
	s["1B"] += 1
	s["TB"] += 1
	
func record_double(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["AB"] += 1
	s["H"] += 1
	s["2B"] += 1
	s["TB"] += 2
	
func record_triple(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["AB"] += 1
	s["H"] += 1
	s["3B"] += 1
	s["TB"] += 3
	
func record_home_run(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["AB"] += 1
	s["H"] += 1
	s["HR"] += 1
	s["TB"] += 4
	
func record_walk(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["BB"] += 1
	
func record_ab(name):
	var s = batter_stats[name]
	s["PA"] += 1
	s["AB"] += 1
	
func record_pa(name):
	var s = batter_stats[name]
	s["PA"] += 1
	
func record_stolen_base(name):
	batter_stats[name]["SB"] += 1
	
func record_strikeout():
	var pitcher_name = GameManager.current_pitcher["name"]
	GameManager.pitcher_stats[pitcher_name]["K"] += 1
	
func record_pitcher_walk():
	var pitcher_name = GameManager.current_pitcher["name"]
	GameManager.pitcher_stats[pitcher_name]["BB"] += 1
	
func update_lead_change_pitcher():
	var away = away_score
	var home = home_score
	
	if away > home and pitcher_when_away_team_took_lead == null:
		pitcher_when_away_team_took_lead = away_pitcher["name"]
		
	elif home > away and pitcher_when_home_team_took_lead == null:
		pitcher_when_home_team_took_lead = home_pitcher["name"]
	
func log_win_loss(wp, lp, sp):
	GameManager.log_event("Winning Pitcher: %s" % wp)
	GameManager.log_event("Losing Pitcher: %s" % lp)
	if sp != null:
			GameManager.log_event("Save: %s" % sp)
	
func save_game_snapshot():
	var game_state = {
			"away_team": away_team_name,
			"home_team": home_team_name,
			"away_score": away_score,
			"home_score": home_score,
			"weather": {
				"name": current_weather_name,
				"ht_mod": current_weather_ht_modifier,
				"sb_mod": current_weather_sb_modifier,
				"idef_modifier": current_weather_idef_modifer
			}
		}
	
	var away_totals = {
		"PA": 0, "AB": 0, "H": 0, "1B": 0, "2B": 0, "3B": 0, "HR": 0, "SB": 0
	}
		
	var home_totals = {
		"PA": 0, "AB": 0, "H": 0, "1B": 0, "2B": 0, "3B": 0, "HR": 0, "SB": 0
	}
	
	var away_batting_array = []
	var home_batting_array = []
	
	for entry in away_lineup:
		var name = entry["name"]
		if batter_stats.has(name):
			var stats = batter_stats[name]
			if stats.get("PA", 0) > 0:
				away_batting_array.append({
					"name": name,
					"stats": stats
				})
				for key in away_totals.keys():
					away_totals[key] += stats.get(key, 0)

	for entry in home_lineup:
		var name = entry["name"]
		if batter_stats.has(name):
			var stats = batter_stats[name]
			if stats.get("PA", 0) > 0:
				home_batting_array.append({
					"name": name,
					"stats": stats
				})
				for key in home_totals.keys():
					home_totals[key] += stats.get(key, 0)
	
	var away_pitching_array = []
	
	for name in GameManager.away_pitchers_used:
		var pstats = GameManager.pitcher_stats.get(name, null)
		if pstats != null: 
				var outs = pstats.get("outs", 0)
				var ip = int(outs / 3) + float(outs % 3) * .1
				
				away_pitching_array.append({
					"name": name,
					"stats": {
						"IP": ip,
						"BF": pstats.get("BF", 0),
						"ER": pstats.get("ER", 0),
						"H": pstats.get("H", 0),
						"BB": pstats.get("BB", 0),
						"K": pstats.get("K", 0)
					}
				})
				
	var home_pitching_array = []
	
	for name in GameManager.home_pitchers_used:
		var pstats = GameManager.pitcher_stats.get(name, null)
		if pstats != null: 
				var outs = pstats.get("outs", 0)
				var ip = int(outs / 3) + float(outs % 3) * .01
				
				home_pitching_array.append({
					"name": name,
					"stats": {
						"IP": ip,
						"BF": pstats.get("BF", 0),
						"ER": pstats.get("ER", 0),
						"H": pstats.get("H", 0),
						"BB": pstats.get("BB", 0),
						"K": pstats.get("K", 0)
					}
				})
	
	var snapshot = [
		{ "game_state:": game_state },
		{
			"decisions": {
				"winning_pitcher": determine_winning_pitcher(),
				"losing_pitcher": determine_losing_pitcher(),
				"save_pitcher": get_saving_pitcher(determine_winning_pitcher())
			}
		},
		{ "away_batting": away_batting_array },
		{ "away_batting_totals": away_totals },
		{ "away_pitching": away_pitching_array },
		{ "home_batting": home_batting_array },
		{ "home_pitching": home_pitching_array },
		{ "play_by_play": play_by_play}
	]
	
	GameManager.last_snapshot = snapshot
	
	var file = FileAccess.open("user://snapshot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()

func export_boxscore_to_csv(snapshot):
	var away_team = snapshot[0]["game_state:"]["away_team"]
	var home_team = snapshot[0]["game_state:"]["home_team"]
	var away_score = snapshot[0]["game_state:"]["away_score"]
	var home_score = snapshot[0]["game_state:"]["home_score"]
	var weather = snapshot[0]["game_state:"]["weather"]["name"]
	
	var winning_pitcher = snapshot[1]["decisions"]["winning_pitcher"]
	var losing_pitcher = snapshot[1]["decisions"]["losing_pitcher"]
	
	var away_batting = snapshot[2]["away_batting"]
	var away_pitching = snapshot[4]["away_pitching"]
	var home_batting = snapshot[5]["home_batting"]
	var home_pitching = snapshot[6]["home_pitching"]
	
	var filename = "user://boxscore.csv"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	file.store_line("%s at %s" % [away_team, home_team])
	file.store_line("")
	file.store_line("Away Score, %d" % away_score)
	file.store_line("Home Score, %d" % home_score)
	file.store_line("Weather, %s" % weather)
	file.store_line("Winning Pitcher, %s" % winning_pitcher)
	file.store_line("Losing Pitcher, %s" % losing_pitcher)
	file.store_line("")
	file.store_line("--------------------------------------------------")
	file.store_line("")
	
	file.store_line("%s Batting" % away_team)
	file.store_line("Name,PA,AB,Hits,BB,1B,2B,3B,HR,TB,SB")
	
	for batter in away_batting:
		var s = batter["stats"]
		file.store_line("%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
			batter["name"], 
			s["PA"], s["AB"], s["H"], s["BB"],
			s["1B"], s["2B"], s["3B"], s["HR"],
			s["TB"], s["SB"]
		])
		
	file.store_line("")
	file.store_line("--------------------------------------------------")
	file.store_line("")
	
	file.store_line("%s Pitching" % away_team)
	file.store_line("Name,IP,BF,ER,Hits,Ks,BBs")
	
	for p in away_pitching:
		var s = p["stats"]
		file.store_line("%s,%s,%d,%d,%d,%d,%d" % [ 
			p["name"],
			str(s["IP"]),
			s["BF"], s["ER"], s["H"],
			s["K"], s["BB"]
		])
		
	file.store_line("")
	file.store_line("--------------------------------------------------")
	file.store_line("")
		
	for batter in home_batting:
		var s = batter["stats"]
		file.store_line("%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
			batter["name"], 
			s["PA"], s["AB"], s["H"], s["BB"],
			s["1B"], s["2B"], s["3B"], s["HR"],
			s["TB"], s["SB"]
		])
		
	file.store_line("")
	file.store_line("--------------------------------------------------")
	file.store_line("")
	
	file.store_line("%s Pitching" % away_team)
	file.store_line("Name,IP,BF,ER,Hits,Ks,BBs")
	
	for p in home_pitching:
		var s = p["stats"]
		file.store_line("%s,%s,%d,%d,%d,%d,%d" % [ 
			p["name"],
			str(s["IP"]),
			s["BF"], s["ER"], s["H"],
			s["K"], s["BB"]
		])
		
	file.close()
	print("Box score exported to:", filename)
