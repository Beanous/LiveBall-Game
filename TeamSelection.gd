extends Control

@onready var away_select = $AwayTeamSelect
@onready var home_select = $HomeTeamSelect
@onready var away_pitcher_select = $AwayPitcherSelect
@onready var home_pitcher_select = $HomePitcherSelect
@onready var away_lineup = $AwayLineup
@onready var home_lineup = $HomeLineup
@onready var sfx_player = $SFXPlayer

func play_sfx(path: String):
	sfx_player.stream = load(path)
	sfx_player.play()

func _ready():
	away_select.add_item("Select Team")
	home_select.add_item("Select Team")
	
	for team_name in GameManager.teams.keys():
		away_select.add_item(team_name)
		home_select.add_item(team_name)
		
	away_select.item_selected.connect(_on_away_team_selected)
	home_select.item_selected.connect(_on_home_team_selected)

	away_pitcher_select.item_selected.connect(_on_away_pitcher_selected)
	home_pitcher_select.item_selected.connect(_on_home_pitcher_selected)

func _on_away_team_selected(index):
	var away_team = away_select.get_item_text(index)
	GameManager.away_team_name = away_team
	
	GameManager.build_bullpens()
	
	if away_team == "Away":
		return

	var away_roster = GameManager.teams[away_team]

	# Fill pitcher dropdown
	away_pitcher_select.clear()
	away_pitcher_select.add_item("Select Pitcher")
	away_pitcher_select.set_item_disabled(0, true)

	for player in away_roster:
		if player.get("position", "") == "SP":
			away_pitcher_select.add_item(player.get("name", "Unknown"))

	away_pitcher_select.select(0)

	# Clear UI lineup
	for child in away_lineup.get_children():
		child.queue_free()

	var starter_positions = ["C", "1B", "2B", "3B", "SS", "LF", "CF", "RF"]

	# Display lineup in UI
	for pos in starter_positions:
		for player in away_roster:
			if player.get("position", "") == pos:
				var label = Label.new()
				label.text = "%s - %s" % [player.get("name", "Unknown"), pos]
				away_lineup.add_child(label)

	# Build actual GameManager lineup
	GameManager.away_lineup.clear()
	for pos in starter_positions:
		for player in away_roster:
			if player.get("position", "") == pos:
				GameManager.away_lineup.append(player)

func _on_home_team_selected(index):
	var home_team = home_select.get_item_text(index)
	GameManager.home_team_name = home_team
	GameManager.stadium_name = GameManager.stadiums[home_team]["ballpark"]
	GameManager.stadium_quirk = GameManager.stadiums[home_team]["quirk"]
	GameManager.current_stadium_weather_variation = GameManager.stadiums[home_team]["variation"]
	
	GameManager.build_bullpens()
	if home_team == "Home":
		return

	var home_roster = GameManager.teams[home_team]

	# Fill pitcher dropdown
	home_pitcher_select.clear()
	home_pitcher_select.add_item("Select Pitcher")
	home_pitcher_select.set_item_disabled(0, true)

	for player in home_roster:
		if player.get("position", "") == "SP":
			home_pitcher_select.add_item(player.get("name", "Unknown"))

	home_pitcher_select.select(0)

	# Clear UI lineup
	for child in home_lineup.get_children():
		child.queue_free()

	var starter_positions = ["C", "1B", "2B", "3B", "SS", "LF", "CF", "RF"]

	# Display lineup in UI
	for pos in starter_positions:
		for player in home_roster:
			if player.get("position", "") == pos:
				var label = Label.new()
				label.text = "%s - %s" % [player.get("name", "Unknown"), pos]
				home_lineup.add_child(label)

	# Build actual GameManager lineup
	GameManager.home_lineup.clear()
	for pos in starter_positions:
		for player in home_roster:
			if player.get("position", "") == pos:
				GameManager.home_lineup.append(player)

func select_dh(roster):
	var starter_positions = ["C","1B","2B","3B","SS","LF","CF","RF","P"]
	var best_dh = null

	for player in roster:
		var pos = player.get("position", "")
		if pos in starter_positions:
			continue

		if best_dh == null:
			best_dh = player
			continue

		var bt = int(player.get("BatTarget", 0))
		var best_bt = int(best_dh.get("BatTarget", 0))

		if bt > best_bt:
			best_dh = player
			continue

		if bt == best_bt:
			var ob = int(player.get("OnBaseTarget", 0))
			var best_ob = int(best_dh.get("OnBaseTarget", 0))
			if ob > best_ob:
				best_dh = player

	return best_dh

func try_assign_dhs():
	if GameManager.away_pitcher == null: 
		return
	if GameManager.home_pitcher == null: 
		return
		
	var away_team = GameManager.away_team_name
	var home_team = GameManager.home_team_name
		
	var away_roster = GameManager.teams[away_team]
	var home_roster = GameManager.teams[home_team]
	
	if GameManager.away_dh != null: 
		GameManager.away_lineup.erase(GameManager.away_dh)
		
	if GameManager.home_dh != null: 
		GameManager.home_lineup.erase(GameManager.home_dh)
	
	GameManager.away_dh = select_dh(away_roster)
	GameManager.home_dh = select_dh(home_roster)
	
	if GameManager.away_dh != null:
		GameManager.away_lineup.append(GameManager.away_dh)
		var lbl = Label.new()
		lbl.text = "%s - DH" % GameManager.away_dh.get("name")
		away_lineup.add_child(lbl)
		
	if GameManager.home_dh != null:
		GameManager.home_lineup.append(GameManager.home_dh)
		var lbl = Label.new()
		lbl.text = "%s - DH" % GameManager.home_dh.get("name")
		home_lineup.add_child(lbl)
	
func _on_away_pitcher_selected(index):
	var pitcher_name = away_pitcher_select.get_item_text(index)
	var away_team = away_select.get_item_text(away_select.selected)
	var away_roster = GameManager.teams[away_team]

	var pitcher = null
	for player in away_roster:
		if player.get("name", "").strip_edges().to_lower() == pitcher_name.strip_edges().to_lower():
			pitcher = player
			break

	GameManager.away_pitcher = pitcher
	try_assign_dhs()

func _on_home_pitcher_selected(index):
	var pitcher_name = home_pitcher_select.get_item_text(index)
	var home_team = home_select.get_item_text(home_select.selected)
	var home_roster = GameManager.teams[home_team]

	var pitcher = null
	for player in home_roster:
		if player.get("name", "").strip_edges().to_lower() == pitcher_name.strip_edges().to_lower():
			pitcher = player
			break

	GameManager.home_pitcher = pitcher
	try_assign_dhs()
	
func _on_play_ball_pressed():
	if GameManager.away_pitcher == null:
		return
	if GameManager.home_pitcher == null:
		return
	if GameManager.away_dh == null:
		return
	if GameManager.home_dh == null:
		return

	GameManager.batter_stats.clear()
	GameManager.init_batter_stats(GameManager.away_lineup)
	GameManager.init_batter_stats(GameManager.home_lineup)
	
	GameManager.pitcher_stats.clear()
	GameManager.init_pitcher_stats([GameManager.away_pitcher])
	GameManager.init_pitcher_stats([GameManager.home_pitcher])
	
	GameManager.init_pitcher_stats(GameManager.away_bullpen)
	GameManager.init_pitcher_stats(GameManager.home_bullpen)

	GameManager.current_pitcher = GameManager.home_pitcher
	GameManager.initialize_pitcher_fatigue(GameManager.current_pitcher)
	
	GameManager.roll_weather()
	
	get_tree().change_scene_to_file("res://PlayBall.tscn")
