extends KinematicBody2D

const EnemyDeathEffect = preload("res://Action RPG Resources/Effects/EnemyDeathEffect.tscn")
const HEART_SCENE = preload("res://Action RPG Resources/UI/Heart.tscn")

enum {
	IDLE,
	WANDER,
	CHASE,
	ATTACK,
	ANTICIPATION
}

export var ACELLERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var SLOWING_RADIUS = 10
export var STAR_ATTACK_CHANCE = 0.5
export var ATTACK_CHANCE_INCREASE = 0.25
export(String, "MELEE", "RANGED") var TYPE = "MELEE"
export var MELEE_ATTACK_COOLDOWN = 2.0
export var MELEE_ATTACK_DURATION = 1.0
export var RANGED_ATTACK_COOLDOWN = 2.0
export var RANGED_ATTACK_DURATION = 1.0
export var MELEE_SPEED_BOOST = 0.5


onready var Stats = $Stats
onready var PlayerDetection = $PlayerDetection
onready var PlayerFollowRange = $PlayerFollowRange
onready var sprite = $Body
onready var hurtbox = $Hurtbox
onready var meleeHitbox = $Hitbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer
onready var healthBar = $TextureProgress
onready var navigationAgent = $NavigationAgent2D
onready var attackAnticipationTimer = $AttackAnticipationTimer
onready var attackCooldownTimer = $AttackCooldownTimer
onready var attackDurationTimer = $AttackDurationTimer
onready var rangedHitboxPivot = $RangedHitboxPivot
onready var rangedHitbox = $RangedHitboxPivot/RangedHitbox
onready var tween = $Tween

var state = IDLE
var velocity = Vector2.ZERO
var attack_chance = STAR_ATTACK_CHANCE
var hitbox = null
var attack_direction = Vector2.ZERO

func update_type(type: String = 'MELEE'):
	TYPE = type

func _ready():
	if Conductor:
		Conductor.connect("quarter_passed", self, "_on_Conductor_quarter_passed")
		Conductor.connect("quarter_will_pass", self, "_on_Conductor_quarter_will_pass")
		Conductor.connect("sixteenth_passed", self, "_on_Conductor_eight_passed")
	if TYPE == 'MELEE':
		hitbox = meleeHitbox
		MAX_SPEED += MELEE_SPEED_BOOST * MAX_SPEED
	else:
		hitbox = rangedHitbox
		PlayerDetection.set_attack_radius(200)
		PlayerDetection.set_target_radius(70)
		STAR_ATTACK_CHANCE = 0.25

func _physics_process(delta):
	match state:
		IDLE:
			rangedHitbox.visible = false
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			if wanderController.get_time_left() == 0:
				update_wander()
				
			seek_player()
		
		WANDER:
			rangedHitbox.visible = false
			arrival_to(wanderController.target_position, delta)
			if wanderController.get_time_left() == 0:
				update_wander()
			
			if global_position.distance_to(wanderController.target_position) <= MAX_SPEED * delta:
				update_wander()
			
			seek_player()
		
		CHASE:
			rangedHitbox.visible = false
			var player = PlayerFollowRange.player
			if player != null:
				navigationAgent.set_target_location(PlayerDetection.get_target_position())
				# print(navigationAgent.get_final_location())
				if navigationAgent.get_final_location() == navigationAgent.get_next_location():
					arrival_to(navigationAgent.get_next_location(), delta, 3)
				else:
					acellerate_towards_point(navigationAgent.get_next_location(), delta)
			else:
				wanderController.start_wander_timer(rand_range(1, 3))
				state = IDLE
		
		ATTACK:
			pass
	
		ANTICIPATION:
			if TYPE == "RANGED":
				var player = PlayerFollowRange.player
				if player == null:
					state = IDLE
				else:
					var ranged_vector = (player.global_position - rangedHitboxPivot.global_position).normalized()
					rangedHitboxPivot.rotation = ranged_vector.angle()
			else:
				var player = PlayerFollowRange.player
				if player != null:
					navigationAgent.set_target_location(PlayerDetection.get_target_position())
					if navigationAgent.get_final_location() == navigationAgent.get_next_location():
						arrival_to(navigationAgent.get_next_location(), delta, 3)
					else:
						acellerate_towards_point(navigationAgent.get_next_location(), delta)
				else:
					wanderController.start_wander_timer(rand_range(1, 3))
					state = IDLE

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * 400 * delta 
	move_and_slide(velocity)

func arrival_to(point, delta, slowing_radius=null):
	if slowing_radius == null:
		slowing_radius = SLOWING_RADIUS
	var direction = point - global_position
	sprite.flip_h = direction.x < 0
	
	var distance = direction.length()
	var desired_velocity = MAX_SPEED * direction.normalized()
	
	if distance < slowing_radius:
		desired_velocity = MAX_SPEED * direction.normalized() * (distance / SLOWING_RADIUS)
	
	velocity = velocity.move_toward(desired_velocity, ACELLERATION * delta)

func acellerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	sprite.flip_h = direction.x < 0
	velocity = velocity.move_toward(direction * MAX_SPEED, ACELLERATION * delta)

func seek_player():
	if PlayerDetection.can_see_player():
		state = CHASE

func spawn_heart():
	var heart = HEART_SCENE.instance()
	heart.global_position = global_position
	var player = PlayerFollowRange.player
	if player == null:
		return
	var direction = (global_position - player.position).normalized()
	
	var final_position = global_position + (direction * 50)

	get_parent().add_child(heart)
	
	var tween = Tween.new()
	heart.add_child(tween)
	tween.interpolate_property(heart, "global_position", heart.global_position, final_position, 1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	attackCooldownTimer.start()
	hitbox.disable()
	if PlayerFollowRange.player:
		state = CHASE
	else:
		state = IDLE
	hurtbox.create_hit_effect()
	velocity = area.Knockback_vector * 100
	Stats.health -= area.damage
	healthBar.change_progress((Stats.health/Stats.max_health)*100)
	hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
	if randf() > 0.8:
		spawn_heart()
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")

func _on_Conductor_quarter_passed(beat):
	if not attackCooldownTimer.is_stopped():
		return
	if state != ANTICIPATION:
		if randf() <= attack_chance:
			var player = PlayerFollowRange.player
			if player != null:
				if TYPE == 'MELEE' and PlayerDetection.is_within_attack_range(global_position):
					state = ANTICIPATION
				elif TYPE == 'RANGED' and PlayerDetection.is_within_attack_range(global_position):
					velocity = Vector2.ZERO
					state = ANTICIPATION
					var attack_direction = (player.global_position - global_position).normalized()
					rangedHitbox.visible = true
				attack_chance = STAR_ATTACK_CHANCE
		else:
			attack_chance += ATTACK_CHANCE_INCREASE
	else:
		attackAnticipationTimer.start()


func _on_Conductor_eight_passed(beat, fract):
	if fract == 3 and state == ANTICIPATION and TYPE == "MELEE":
		var player = PlayerFollowRange.player
		if player != null:
			var attack_direction = (player.global_position - global_position).normalized()
			tween.interpolate_property(self, "position", position, position - attack_direction * 10, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.start()

func _on_Conductor_quarter_will_pass(beat):
	pass

func _on_AttackDurationTimer_timeout():
	attackCooldownTimer.start()
	hitbox.disable()
	rangedHitbox.disable()
	var player = PlayerFollowRange.player
	if player == null:
		state = IDLE
		return
	if TYPE == 'RANGED':
		PlayerDetection.recalculate_vector()
		state = CHASE
		rangedHitbox.visible = false
	else:
		PlayerDetection.recalculate_vector()
		state = CHASE


func _on_AttackAnticipationTimer_timeout():
	state = ATTACK
	if TYPE == "MELEE":
		var player = PlayerFollowRange.player
		var attack_direction = (player.global_position - global_position).normalized()
		velocity = attack_direction * 200
		hitbox.enable()
	else:
		rangedHitbox.enable()
	attackDurationTimer.start()
