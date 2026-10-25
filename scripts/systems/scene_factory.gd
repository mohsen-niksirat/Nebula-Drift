extends RefCounted
## SceneFactory — builds all game scenes programmatically in code.
## Bypasses Godot 4.4 savepack crashes on .tscn files with SubResources.
## All collision shapes and sprites are created via code — no PackedScene files.

class Player:
	static func create() -> CharacterBody2D:
		var player := CharacterBody2D.new()
		player.name = "Player"
		player.collision_layer = 2
		player.collision_mask = 5
		player.set_script(preload("res://scripts/entities/player.gd"))

		var sprite := ColorRect.new()
		sprite.name = "Sprite"
		sprite.color = Color(0.408, 0.804, 1.0)
		sprite.offset_left = -14.0
		sprite.offset_top = -14.0
		sprite.offset_right = 14.0
		sprite.offset_bottom = 14.0
		player.add_child(sprite)

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		player.add_child(shape)

		return player

class Enemy:
	static func create() -> CharacterBody2D:
		var enemy := CharacterBody2D.new()
		enemy.name = "Enemy"
		enemy.collision_layer = 4
		enemy.collision_mask = 3
		enemy.motion_mode = 1
		enemy.set_script(preload("res://scripts/entities/enemy_base.gd"))

		var sprite := ColorRect.new()
		sprite.name = "Sprite"
		sprite.color = Color(1.0, 0.478, 0.478)
		sprite.offset_left = -12.0
		sprite.offset_top = -12.0
		sprite.offset_right = 12.0
		sprite.offset_bottom = 12.0
		enemy.add_child(sprite)

		var body_shape := CollisionShape2D.new()
		var body_circle := CircleShape2D.new()
		body_circle.radius = 20.0
		body_shape.shape = body_circle
		enemy.add_child(body_shape)

		var hitbox := Area2D.new()
		hitbox.name = "Hitbox"
		hitbox.collision_layer = 4
		hitbox.collision_mask = 2
		enemy.add_child(hitbox)

		var hitbox_shape := CollisionShape2D.new()
		var hitbox_circle := CircleShape2D.new()
		hitbox_circle.radius = 26.0
		hitbox_shape.shape = hitbox_circle
		hitbox.add_child(hitbox_shape)

		return enemy

class Hud:
	static func create() -> CanvasLayer:
		var hud := CanvasLayer.new()
		hud.name = "HUD"
		hud.layer = 5
		hud.set_script(preload("res://scripts/ui/hud.gd"))

		var root := Control.new()
		root.name = "Root"
		root.layout_mode = 3
		root.anchors_preset = 15
		root.anchor_right = 1.0
		root.anchor_bottom = 1.0
		hud.add_child(root)

		var info := HBoxContainer.new()
		info.name = "Info"
		info.layout_mode = 0
		info.offset_left = 16.0
		info.offset_top = 12.0
		info.offset_right = 400.0
		info.offset_bottom = 40.0
		root.add_child(info)

		var hp_label := Label.new()
		hp_label.name = "HPLabel"
		hp_label.layout_mode = 2
		hp_label.text = "HULL: 100/100"
		info.add_child(hp_label)

		var score_label := Label.new()
		score_label.name = "ScoreLabel"
		score_label.layout_mode = 2
		score_label.text = "SCORE: 0"
		info.add_child(score_label)

		# M1: XP / level display
		var xp_label := Label.new()
		xp_label.name = "XPLabel"
		xp_label.layout_mode = 2
		xp_label.text = "LV 1 | XP 0/100"
		info.add_child(xp_label)

		var game_over := CenterContainer.new()
		game_over.name = "GameOver"
		game_over.layout_mode = 1
		game_over.anchors_preset = 15
		game_over.anchor_right = 1.0
		game_over.anchor_bottom = 1.0
		game_over.visible = false
		root.add_child(game_over)

		var panel := PanelContainer.new()
		panel.name = "Panel"
		panel.layout_mode = 2
		game_over.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.name = "VBox2"
		vbox.layout_mode = 2
		vbox.alignment = 1
		panel.add_child(vbox)

		var title := Label.new()
		title.name = "Title"
		title.layout_mode = 2
		title.text = "DRIFTED TOO FAR INTO THE NEBULA..."
		title.horizontal_alignment = 1
		vbox.add_child(title)

		var final_score := Label.new()
		final_score.name = "FinalScore"
		final_score.layout_mode = 2
		final_score.text = "SCORE: 0"
		final_score.horizontal_alignment = 1
		vbox.add_child(final_score)

		var restart_btn := Button.new()
		restart_btn.name = "RestartButton"
		restart_btn.layout_mode = 2
		restart_btn.text = "RESTART RUN"
		vbox.add_child(restart_btn)

		return hud

class UpgradePicker:
	static func create() -> CanvasLayer:
		var picker := CanvasLayer.new()
		picker.name = "UpgradePicker"
		picker.layer = 10
		picker.process_mode = Node.PROCESS_MODE_ALWAYS
		picker.set_script(preload("res://scripts/ui/upgrade_picker.gd"))

		var panel := PanelContainer.new()
		panel.name = "Panel"
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.size = Vector2(700, 240)
		# Center the panel relative to the viewport. A positive position here
		# would move it toward the bottom-right after center anchors are set.
		panel.position = Vector2(-350, -120)
		picker.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.name = "VBox"
		vbox.add_theme_constant_override("separation", 12)
		panel.add_child(vbox)

		var title := Label.new()
		title.name = "Title"
		title.text = "CHOOSE AN UPGRADE"
		title.horizontal_alignment = 1
		title.add_theme_font_size_override("font_size", 24)
		vbox.add_child(title)

		var level_label := Label.new()
		level_label.name = "Level"
		level_label.text = "LEVEL 1"
		level_label.horizontal_alignment = 1
		vbox.add_child(level_label)

		var cards := HBoxContainer.new()
		cards.name = "Cards"
		cards.alignment = BoxContainer.ALIGNMENT_CENTER
		cards.add_theme_constant_override("separation", 16)
		vbox.add_child(cards)

		return picker
