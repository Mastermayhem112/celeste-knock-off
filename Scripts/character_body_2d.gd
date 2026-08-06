extends CharacterBody2D
# ============================================================================
# CONSTANTS
# ============================================================================
const playerSpeed = 200
const jumpPower = -180
const clingTimeMax : int = 300  # ticks (5 seconds)
const coyoteTimeMax : int = 6  # ticks (0.1 seconds)
const jumpTimerMax : int = 10  # ticks (0.166 seconds)
const qSize : int = 300  # ticks (5 seconds)
const dashTimer : int = 12  # ticks (0.2 seconds)	

# ============================================================================
# VARIABLES - Cling, Climb, and Jump
# ============================================================================
var gravity : float = 0
var clingTime : int = 0
var isCling : bool = false
var canCling : bool = true
var coyoteTime : int = 0
var jumpTimer : int = 0
var canJump : bool = true

# ============================================================================
# VARIABLES - Dash
# ============================================================================
var canDash : bool = false
var isDashing : bool = false
var qVert : Array[float]
var qHori : Array[float]
var currentIndex : int = 0
var hasQueued : bool = false
var qAdd : float = 0
var qIndexCount : int = 0
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
		if !Input.is_action_pressed("playerJump") or jumpTimer > jumpTimerMax:
		# added (!isCling and !Input.is_action_pressed("playerUp")): stops gravity during climb, but also removes variable jump height
			gravity = get_gravity().y
			if velocity.y < 0:
				gravity *= 0.7
			velocity.y += gravity * delta
			if velocity.y > 400:
				velocity.y == 400
		
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
	if (direction and !isCling):
	#or isCling and Input.is_action_pressed("playerJump") and jumpTimer < jumpTimerMax:	
		velocity.x = direction * playerSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, 20)

	# --- WALL INTERACTION --- (Cling, Climb, Jump)
	if tryMoveHori() != 0:
		canJump = true
		
		# Wall Cling
		if Input.is_action_pressed("playerCling") and canCling == true:
			clingTime += 1
			if velocity.y > 0:
				isCling = true
				velocity.y = 0
				jumpTimer = 0     # Reset for variable jump height
		else:
			isCling = false
		
		# Wall Climb
		if isCling:
			var directionVert := Input.get_axis("playerUp", "playerDown")
			if directionVert:
				velocity.y = directionVert * playerSpeed * 2 / 3
			elif !directionVert and !Input.is_action_pressed("playerJump") and jumpTimer < jumpTimerMax:
				velocity.y = 0
	
		# Wall Jump
		if Input.is_action_just_pressed("playerJump") and !is_on_floor() and canJump:
			canJump = false
			jumpTimer = 0
			velocity.y = jumpPower
			if (!isCling and direction != tryMoveHori()) or (isCling and (direction == (tryMoveHori() * -1))):
				velocity.x = playerSpeed * -tryMoveHori()
				isCling = false
			if direction:
				velocity.x = velocity.x * 1.5
	else:
		isCling = false

	
	move_and_slide()
	
	# --- RESET TIMERS ---
	if clingTime > clingTimeMax:
		canCling = false
		
	if !canCling and is_on_floor():
		canCling = true
	
	if is_on_floor():
		coyoteTime = 0
		canJump = true
	
	print(isCling)
