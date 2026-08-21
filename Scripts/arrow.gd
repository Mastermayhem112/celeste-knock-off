extends Sprite2D	

func _process(delta: float) -> void:
	var player = get_parent()

	var arrowDirection = player.dashDirection
	var arrowStrength = arrowDirection.length()
	
	# if there is no dash information, hide the arrow
	if (arrowStrength == 0 and player.is_on_floor()) or !player.canDash:
		visible = false
		return
	visible = true
	
	rotation = arrowDirection.angle()
	
	var arrowColor : Color
	
	if arrowStrength < 50 * player.velXmult:
		arrowColor = Color.GREEN
	elif arrowStrength < 100 * player.velXmult:
		arrowColor = Color.YELLOW
	elif arrowStrength < 125 * player.velXmult:
		arrowColor = Color.ORANGE
	else:
		arrowColor = Color.RED
		
	modulate = modulate.lerp(arrowColor, 5 * delta)
