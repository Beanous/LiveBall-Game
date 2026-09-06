extends Node

var sfx = {
	"strikeout": [
		"res://audio/Gotem.mp3",
		"res://audio/Swingandmiss.mp3",
		"res://audio/Struckoutswinging.mp3",
		"res://audio/StrikeThree.wav",
		"res://audio/Wentfishing.mp3",
		"res://audio/Whiff.wav"
	],
	"walk": [
		"res://audio/Baseonballs.mp3",
		"res://audio/Ball4.wav",
		"res://audio/Goodeye.mp3",
		"res://audio/Walk.wav"
	],
	"home_run": [
		"res://audio/Homerun.wav"
	],
	"fireworks": [
		"res://audio/HRFireworks.wav"
	],
	"reaction_cheer": [
		"res://audio/HRCheer.wav"
	],
	"reaction_boo": [
		"res://audio/HRBoo.wav"
	],
	"ambience": [
		"res://audio/CAOpen.wav",
		"res://audio/CA2.wav",
		"res://audio/CA3.wav",
		"res://audio/CA4.wav",
		"res://audio/CA5.wav",
		"res://audio/CA6.wav"
	],
	"cheer": [
		"res://audio/Cheer1.wav",
		"res://audio/Cheer3.wav",
		"res://audio/Cheer4.wav",
		"res://audio/Cheer5.wav",
		"res://audio/Cheer6.wav"
	],
	"boo": [
		"res://audio/Boo1.wav",
		"res://audio/Boo2.wav",
		"res://audio/Boo3.wav",
		"res://audio/Boo4.wav"
	],
	"1out": [
		"res://audio/Onedown.wav",
		"res://audio/Twotogo.mp3"
	],
	"2outs": [
		"res://audio/Onetogo.wav",
		"res://audio/Twodown.mp3"
	],
	"Defcheckyes": [
		"res://audio/Easyout.mp3",
		"res://audio/Nicecatch.wav"
	]
}

func get_random_sfx(key: String) -> String:
	if not sfx.has(key):
		return ""
	var list = sfx[key]
	return list[randi() % list.size()]
