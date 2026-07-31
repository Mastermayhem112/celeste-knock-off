extends CharacterBody2D
# ============================================================================
# CONSTANTS
# ============================================================================
const playerSpeed = 200
const jumpPower = -200
const clingTimeMax : int = 300  # ticks (5 seconds)
const coyoteTimeMax : int = 12  # ticks (0.2 seconds)
const jumpTimerMax : int = 12  # ticks (0.2 seconds)


# ============================================================================
# VARIABLES - Cling, Climb, and Jump
# ============================================================================
var clingTime : int = 0
var isCling : bool = false
var canCling : bool = true
var coyoteTime : int = 0
var wasOnFloor : bool = true
var jumpTimer : int = 0
var canJump : bool = true

# ============================================================================
# FUNCTIONS
# ============================================================================

func tryMoveHori() -> int:
	if test_move(global_transform, Vector2(2, 0)):
		return 1
	elif test_move(global_transform, Vector2(-2, 0)):
		return -1
	else:
		return 0

	
func _physics_process(delta: float) -> void:
	# --- GRAVITY --- (variable jump height)
	if !is_on_floor():
		coyoteTime += 1
		jumpTimer += 1
		wasOnFloor = false
		if !Input.is_action_pressed("playerJump") or jumpTimer > jumpTimerMax:
			velocity += get_gravity() * delta
	
	# --- GROUND JUMP ---
	if (is_on_floor() or coyoteTime < coyoteTimeMax) and !isCling:
		canJump = true
		if wasOnFloor == false:
			wasOnFloor = true
			clingTime = 0
		if Input.is_action_just_pressed("playerJump") and canJump:
			canJump = false
			jumpTimer = 0
			velocity.y = jumpPower
	
	# --- HORIZONTAL MOVEMENT ---
	var direction := Input.get_axis("playerLeft", "playerRight")
	if direction and !isCling:
		velocity.x = direction * playerSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, 20)

	# --- WALL INTERACTION --- (Cling, Climb, Jump)
	if tryMoveHori() != 0:
		canJump == true

		# Wall Cling
		if Input.is_action_pressed("playerCling") and canCling == true:
			isCling = true
			clingTime += 1
			if velocity.y >= 0:
				velocity.y = 0
				jumpTimer = 0                 # Reset for variable jump height

		else:
			isCling = false
		
		# Wall Climb
		if isCling:
			if clingTime < clingTimeMax:
				var directionVert := Input.get_axis("playerUp", "playerDown")
				if directionVert:
					velocity.y = directionVert * playerSpeed * 2 / 3
	
		# Wall Jump
		if Input.is_action_just_pressed("playerJump") and !is_on_floor():
			velocity.y = jumpPower
			jumpTimer = 0
			if (!isCling and direction != tryMoveHori()) or (isCling and direction == (tryMoveHori() * -1)):
				velocity.x = playerSpeed * -tryMoveHori()
				isCling = false
			if direction != 0:
				velocity.x = velocity.x * 1.5

			
#dsa
	
	move_and_slide()
	
	# --- RESET TIMERS ---
	if clingTime > clingTimeMax:
		canCling = false
		
	if !canCling and is_on_floor():
		canCling = true
	
	if is_on_floor():
		coyoteTime = 0
	
	print(coyoteTime)
