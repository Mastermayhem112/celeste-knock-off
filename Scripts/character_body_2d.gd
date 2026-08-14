extends CharacterBody2D

# ============================================================================
# CONSTANTS
# ============================================================================

const playerSpeed = 100
const jumpPower = -180
const clingTimeMax : int = 300  # ticks (5 seconds)
const coyoteTimeMax : int = 6  # ticks (0.1 seconds)
const jumpTimerMax : int = 10  # ticks (0.166 seconds)
const qSize : int = 300  # ticks (5 seconds)
const pausePlayerInputTimerMax : int = 0  # ticks (0.1 seconds)

# ============================================================================
# VARIABLES - Cling, Climb, and Jump
# ============================================================================
var pausePlayerInput : bool = false
var pausePlayerInputTimer : int = 0
var gravity : float = 0
var clingTime : int = 0
var isCling : bool = false
var canCling : bool = true
var coyoteTime : int = 0
var jumpTimer : int = 0
var canJump : bool = true
var wallJumpDirection : int = 0

# ============================================================================
# VARIABLES - Dash
# ============================================================================
var lastVelocityX : float = 0
var canDash : bool = false
var isDashing : bool = false
var qVert : Array[float]
var qHori : Array[float]
var currentIndex : int = 0
var hasQueued : bool = false
var qVelX : float = 0
var qVelY : float = 0
var qIndex : int = 0
var wasOnFloor : bool = false
var wasOnWall : bool = false
var boostX : int = 0
var boostY : int = 0
var dashDirection : Vector2 = Vector2.ZERO	

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

func _ready() -> void:
	#dynamically fill the queues with useless information once at initialization
	qHori.resize(qSize)
	qHori.fill(0.0)
	qVert.resize(qSize)
	qVert.fill(0.0)
	
func _physics_process(delta: float) -> void:
	# --- GRAVITY --- (variable jump height)
	if !is_on_floor():
		coyoteTime += 1
		jumpTimer += 1
		wasOnFloor = false
		
		# vertical dash queueing
		if !isCling:
			if velocity.y < 0:
				qVert[currentIndex] = 1
			else:
				qVert[currentIndex] = -1
			qHori[currentIndex] = 0
			hasQueued = true
		
		if !Input.is_action_pressed("playerJump") or jumpTimer > jumpTimerMax:
		# added (!isCling and !Input.is_action_pressed("playerUp")): stops gravity during climb, but also removes variable jump height
			gravity = get_gravity().y
			if velocity.y < 0:
				gravity *= 0.7
			velocity.y += gravity * delta
			if velocity.y > 400:
				velocity.y = 400
	elif wasOnFloor == false:
		wasOnFloor = true	
	
	# --- GROUND JUMP ---
	if is_on_floor() or coyoteTime < coyoteTimeMax:
		canJump = true
		if wasOnFloor == false:
			wasOnFloor = true
			clingTime = 0
			if velocity.y > 500:
				boostY = 1
		if Input.is_action_just_pressed("playerJump") and canJump:
			canJump = false
			jumpTimer = 0	
			velocity.y = jumpPower
	
	# --- HORIZONTAL MOVEMENT ---
	var direction := Input.get_axis("playerLeft", "playerRight")
	if (direction and !isCling and !pausePlayerInput):
	#or isCling and Input.is_action_pressed("playerJump") and jumpTimer < jumpTimerMax:
		velocity.x = move_toward(velocity.x, direction * playerSpeed, playerSpeed/4)
		if direction == -1 and velocity.x >= direction * playerSpeed:
			velocity.x = move_toward(velocity.x, direction * playerSpeed, playerSpeed/4)
		elif direction == 1 and velocity.x <= direction * playerSpeed:
			velocity.x = move_toward(velocity.x, direction * playerSpeed, playerSpeed/4)
		qHori[currentIndex] = direction
		if hasQueued == false:
			qVert[currentIndex] = 0
			hasQueued = true
	else:
		velocity.x = move_toward(velocity.x, 0, 100)
		if abs(velocity.x) <= 20:
			pausePlayerInput = false

	# --- WALL INTERACTION --- (Cling, Climb, Jump)
	if tryMoveHori() != 0:
		canJump == true

		if wasOnWall == false:
			wasOnWall = true
			if lastVelocityX >= 1000:
				boostX = 1
			if lastVelocityX <= -1000:
				boostX = -1

		# Wall Cling
		if Input.is_action_pressed("playerCling") and canCling == true and velocity.y >= 0:
			velocity.y = 0
			jumpTimer = 0    # Reset for variable jump height 
			isCling = true
			clingTime += 1
		else:
			isCling = false
		
		# Wall Climb
		if isCling:
			if clingTime < clingTimeMax:
				var directionVert := Input.get_axis("playerUp", "playerDown")
				if directionVert:
					velocity.y = directionVert * playerSpeed * 2 / 3
				elif !directionVert and !Input.is_action_pressed("playerJump"):
					velocity.y = 0
	
		# Wall Jump
		if Input.is_action_just_pressed("playerJump") and !is_on_floor() and canJump:
			canJump = false
			jumpTimer = 0
			velocity.y = jumpPower
			wallJumpDirection = -tryMoveHori()
			if !isCling:
				velocity.x = playerSpeed * wallJumpDirection
				isCling = false
				pausePlayerInput = true
				pausePlayerInputTimer = 6
			if isCling and direction == wallJumpDirection:
				velocity.x = playerSpeed * wallJumpDirection
				isCling = false
			if direction:
				velocity.x = velocity.x * 3.1
			else:
				velocity.x = velocity.x * 2
	else:
		isCling = false
	
	# --- DASH ---
	if Input.is_action_just_pressed("playerDash") and canDash:
		pausePlayerInput = true
		pausePlayerInputTimer = 12
		canDash = false
		isDashing = true
		qVelX = 0
		qVelY = 0
		for qIndex in qSize:
			if boostX != 0:
				qVelX += boostX * abs(qHori[qIndex])
			else:
				qVelX += qHori[qIndex]
			if boostY != 0:
				qVelY += boostY * abs(qVert[qIndex])
			else:
				qVelY += qVert[qIndex]
			
		dashDirection = Vector2(qVelX, qVelY)
		if dashDirection == Vector2.ZERO:
			dashDirection = Vector2(0, 0)
		velocity = dashDirection * playerSpeed * 3
		boostX = 0
		boostY = 0

	move_and_slide()
	
	# --- RESET TIMERS ---
	if pausePlayerInputTimer > pausePlayerInputTimerMax:
		pausePlayerInputTimer -= 1
		if direction == wallJumpDirection:
			pausePlayerInput = false
			pausePlayerInputTimer = -1
	else:
		pausePlayerInput = false
		wallJumpDirection = 0
		isDashing = false


	if clingTime > clingTimeMax:
		canCling = false
		
	if !canCling and is_on_floor():
		canCling = true
	
	if is_on_floor():
		coyoteTime = 0
		canJump = true
	
	if hasQueued and currentIndex < qSize - 1:
		currentIndex += 1
	else:
		currentIndex = 0
	hasQueued = false

	if !isDashing and is_on_floor():
		canDash = true
