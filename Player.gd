extends KinematicBody2D

const PLAYER_HURT_SOUND = preload("res://Action RPG Resources/Player/PlayerHurtSound.tscn")

export var MAX_SPEED = 100
export var ACELL = 750
export var FRICTION = 750
export var ROLL_SPEED = 120
export var ROLL_COOLDOWN = 0.5
export var ATACK_COOLDOWN = 0.1
export var EARLY_INPUT_TOLERANCE = 0.25
export var LATE_INPUT_TOLERANCE = 0.25
export var BUFFER_TIME = 0.25
export var PERFECT_EARLY_INPUT_TOLERANCE = 0.15
export var PERFECT_LATE_INPUT_TOLERANCE = 0.15
export var DASH_LIMIT = 3

enum {
	MOVE,
	ROLL,
	ATACK,
	DASH_ATACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats
var last_input
var last_input_time
var last_beat_time
var dash_counter = 0
var attack_counter = 0
var action_taken = false
var attack_vector = Vector2.ZERO
var activate_roll_timer = false
var activate_attack_timer = false

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var SwordHitbox = $HitboxPivot/Sword_Hitbox
onready var hurtbox = $Hurtbox
onready var animationState = animationTree.get("parameters/playback")
onready var blinckAnimationPlayer = $BlinkAnimationPlayer
onready var rollTimer = $RollTimer
onready var atackTimer = $AtackTimer
onready var metronomePlayer = $MetronomeSound
onready var rollIndicator = $Sprite/RollIndicator



func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	SwordHitbox.Knockback_vector = roll_vector
	last_beat_time = OS.get_ticks_msec() / 1000.0
	print(Conductor)
	if Conductor:
		Conductor.connect("quarter_passed", self, "_on_Conductor_quarter_passed")
		Conductor.connect("quarter_will_pass", self, "_on_Conductor_quarter_will_pass")

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta) 
		
		ROLL:
			roll_state(delta)
		
		ATACK:
			atack_state(delta)
		
		DASH_ATACK:
			dash_attack_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	input_vector = input_vector.normalized()
	
	# Calculate vector from player to mouse
	var mouse_position = get_global_mouse_position()
	var player_position = global_position
	attack_vector = (mouse_position - player_position).normalized()
	$HitboxPivot.rotation = attack_vector.angle()
	
	animationTree.set("parameters/Atack/blend_position", attack_vector)
	animationTree.set("parameters/DashAttack/blend_position", attack_vector)
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		SwordHitbox.Knockback_vector = attack_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACELL * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	velocity = move_and_slide(velocity)
	
	var current_time = OS.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("dash_attack") and atackTimer.is_stopped() and rollTimer.is_stopped() and attack_counter < DASH_LIMIT and dash_counter < DASH_LIMIT:
		if current_time - last_beat_time <= LATE_INPUT_TOLERANCE and not action_taken:
			if current_time - last_beat_time <= PERFECT_LATE_INPUT_TOLERANCE:
				metronomePlayer.play()
			state = DASH_ATACK
			action_taken = true
			attack_counter += 1
			dash_counter += 1
			if attack_counter >= DASH_LIMIT:
				rollIndicator.visible = true
				atackTimer.start(ATACK_COOLDOWN)
			if dash_counter >= DASH_LIMIT:
				activate_roll_timer = true
		else:
			last_input = "Dash Attack"
			last_input_time = current_time
	if Input.is_action_just_pressed("Atack") and atackTimer.is_stopped() and attack_counter < DASH_LIMIT:
		if current_time - last_beat_time <= LATE_INPUT_TOLERANCE and not action_taken:
			if current_time - last_beat_time <= PERFECT_LATE_INPUT_TOLERANCE:
				metronomePlayer.play()
			state = ATACK
			action_taken = true
			attack_counter += 1
			if attack_counter >= DASH_LIMIT:
				atackTimer.start(ATACK_COOLDOWN)
		else:
			last_input = "Atack"
			last_input_time = current_time
	if Input.is_action_just_pressed("Roll") and rollTimer.is_stopped() and dash_counter < DASH_LIMIT:
		if current_time - last_beat_time <= LATE_INPUT_TOLERANCE and not action_taken:
			if current_time - last_beat_time <= PERFECT_LATE_INPUT_TOLERANCE:
				metronomePlayer.play()
			state = ROLL
			action_taken = true
			dash_counter += 1
			if dash_counter >= DASH_LIMIT:
				activate_roll_timer = false
		else:
			last_input = "Roll"
			last_input_time = current_time

func roll_state(_delta):
	animationState.travel("Roll")
	velocity = roll_vector * ROLL_SPEED
	velocity = move_and_slide(velocity)

func atack_state(_delta):
	animationState.travel("Atack")
	
	velocity = attack_vector * 75
	move_and_slide(velocity)

func dash_attack_state(_delta):
	animationState.travel("DashAttack")
	
	velocity = attack_vector * 250
	move_and_slide(velocity)

func roll_animation_finished():
	state = MOVE
	velocity = MAX_SPEED * velocity.normalized()

func atack_animation_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	if !hurtbox.invincible:
		stats.health -= area.damage
		hurtbox.start_invincibility(0.75)
		hurtbox.create_hit_effect()
		var player_hurt_sound = PLAYER_HURT_SOUND.instance()
		get_tree().current_scene.add_child(player_hurt_sound)

func start_roll_invincibility():
	hurtbox.start_invincibility(0.3)

func _on_Hurtbox_invincibility_started():
	blinckAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinckAnimationPlayer.play("Stop")

func _on_Conductor_quarter_passed(beat):
	last_beat_time = OS.get_ticks_msec() / 1000.0
	if last_input_time:
		if last_beat_time - last_input_time <= PERFECT_EARLY_INPUT_TOLERANCE:
			metronomePlayer.play()
	last_input_time = null
	#metronomePlayer.play()
	var action_taken_previous_beat = action_taken
	action_taken = false
	if activate_roll_timer:
		atackTimer.start(ATACK_COOLDOWN)
		rool_cooldown_indicator()
	if last_input == "Dash Attack" and atackTimer.is_stopped() and rollTimer.is_stopped():
		state = DASH_ATACK
		action_taken = true
		attack_counter += 1
		dash_counter += 1
		if attack_counter >= DASH_LIMIT and atackTimer.is_stopped():
			atackTimer.start(ATACK_COOLDOWN)
			activate_roll_timer = true
	if last_input == "Atack" and atackTimer.is_stopped():
		state = ATACK
		action_taken = true
		attack_counter += 1
		if attack_counter >= DASH_LIMIT and atackTimer.is_stopped():
			atackTimer.start(ATACK_COOLDOWN)
	else:
		if not action_taken_previous_beat and attack_counter and atackTimer.is_stopped():
			atackTimer.start(ATACK_COOLDOWN)
	if last_input == "Roll" and rollTimer.is_stopped():
		state = ROLL
		action_taken = true
		dash_counter += 1
		if dash_counter >= DASH_LIMIT and rollTimer.is_stopped():
			activate_roll_timer = true
	else:
		if not action_taken_previous_beat and dash_counter and rollTimer.is_stopped():
			activate_roll_timer = true
	
	last_input = null


func _on_Conductor_quarter_will_pass(beat):
	#metronomePlayer.play()
	pass


func _on_RollTimer_timeout():
	dash_counter = 0


func _on_AtackTimer_timeout():
	attack_counter = 0
	
func rool_cooldown_indicator():
	rollIndicator.visible = true
	activate_roll_timer = false
	rollTimer.start(ROLL_COOLDOWN)
	var tween = Tween.new()
	add_child(tween)
	print(rollIndicator)
	tween.interpolate_property(rollIndicator, "scale", Vector2(0.04, 0.025), Vector2(0.06, 0.035), 0.5)
	tween.start()
	
	yield(get_tree().create_timer(ROLL_COOLDOWN), "timeout")
	
	rollIndicator.visible = false
