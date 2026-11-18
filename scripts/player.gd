class_name Player
extends CharacterBody2D

## Joust-inspired momentum player. Floaty flap with a timing skill curve,
## stamina-limited hovering, a tight decaying dash (horizontal and downward),
## dive-bounce landings, and a momentum meter built through skilled actions.
##
## Feel systems:
## - Input buffering: flap/dash presses are captured as events and consumed
##   per physics tick via countdown timers (Godot issue #73339).
## - Speed preservation: a bounce never overwrites a faster same-direction
##   speed.
## - Apex float: gravity halves near the apex, widening the timed-flap window.
## - Stamina: flaps cost stamina, regenerated on the ground and refunded by
##   bounce landings, so hovering drains a visible resource.
## - Chain: skilled actions within a window extend a chain; repeats of the
##   same action type pay diminishing returns.
## - Meter payouts: momentum tiers boost flap strength and dash readiness.
##
## Tuning: every value is an @export, so you can select the Player node in the
## editor and change values in the Inspector while the game runs.

signal flapped(flap_type: StringName)
signal dashed(dash_type: StringName)
signal landed(impact_speed: float)
signal bounced(impact_speed: float)
signal stamina_changed(value: float)
signal momentum_changed(value: float)
signal chain_changed(count: int)

## Horizontal movement
@export var ground_acceleration: float = 1200.0
@export var air_acceleration: float = 600.0
## How much air acceleration is lost at top speed (0 = no loss, 1 = none left).
@export_range(0.0, 1.0) var air_control_loss_at_speed: float = 0.6
@export var ground_friction: float = 1000.0
@export var air_friction: float = 40.0
@export var max_speed: float = 350.0
## Air acceleration multiplier while an action chain is active (chaining feel).
@export_range(1.0, 2.0) var chain_air_control_bonus: float = 1.3

## Flapping movement. Lower gravity and a lower fall clamp make the flap
## floaty; the rise curve punishes spam and rewards apex timing.
@export var flap_impulse: float = 280.0
## Flap strength multiplier when already rising at max rise speed (spamming).
@export_range(0.0, 1.0) var flap_min_factor: float = 0.12
## Vertical speed window around the apex that counts as a timed flap.
@export var flap_timing_window: float = 90.0
## Extra impulse for a perfectly timed flap.
@export var flap_timing_bonus: float = 60.0
## Rise fraction above which a flap counts as spam and drains momentum.
@export_range(0.0, 1.0) var flap_spam_rise_threshold: float = 0.5
@export var gravity: float = 620.0
## Extra gravity while falling; keeps the descent from feeling weightless.
@export var gravity_fall_multiplier: float = 1.2
## Gravity multiplier near the apex (Celeste-style half-gravity float window).
@export_range(0.0, 1.0) var apex_gravity_multiplier: float = 0.5
## Vertical speed window around the apex where gravity is reduced.
@export var apex_gravity_window: float = 90.0
@export var max_fall_speed: float = 450.0
@export var max_rise_speed: float = -400.0

## Flap steering coupling (Joust): a flap adds a fraction of the held
## horizontal direction as extra sideways momentum.
@export_range(0.0, 1.0) var flap_steer: float = 0.35

## Stamina. Flaps cost stamina; it regenerates on the ground and bounce
## landings refund some. When stamina runs out, no flap is possible.
@export var max_stamina: float = 5.0
@export var flap_stamina_cost: float = 1.0
@export var dive_flap_stamina_cost: float = 1.0
@export var stamina_ground_regen_rate: float = 3.0
@export var bounce_stamina_refund: float = 2.0

## Dive flap: hold S/Down while flapping to sink fast and gain horizontal speed.
@export var dive_flap_downward: float = 250.0
@export var dive_flap_horizontal: float = 180.0
## Cost of the dive flap: the flap action is locked out for this long.
@export var dive_flap_lockout: float = 0.35

## Dash settings. A tight punch: a strong burst that decays quickly to a
## fraction of its peak, layered on top of kept pre-dash momentum.
@export var dash_speed: float = 650.0
## Fraction of dash_speed the burst has decayed to when the dash ends.
@export_range(0.0, 1.0) var dash_end_factor: float = 0.15
## Fraction of pre-dash horizontal velocity kept on top of the dash burst.
@export_range(0.0, 1.0) var dash_momentum_retention: float = 0.35
@export var dash_duration: float = 0.12
@export var dash_cooldown: float = 1.2
## Downward dash: hold S/Down while dashing to slam down instead. This is the
## setup move for bounce landings.
@export var dash_down_speed: float = 550.0
## Fraction of dash_down_speed the slam has decayed to when the dash ends.
@export_range(0.0, 1.0) var dash_down_end_factor: float = 0.5
## Fraction of the dash cooldown removed at the top momentum tier.
@export_range(0.0, 1.0) var dash_cooldown_tier2_reduction: float = 0.5

## Dive-bounce landing. Landing hard while holding a horizontal direction
## converts fall speed into a forward burst.
@export var bounce_min_fall_speed: float = 420.0
## Fraction of fall speed converted into horizontal velocity.
@export_range(0.0, 1.0) var bounce_conversion: float = 0.7
@export var bounce_pop: float = 120.0

## Input buffering. Presses are captured as events and consumed per tick, so
## rapid taps and tick-boundary presses are never dropped. Kept short: the
## action should feel like it happened when the player pressed it.
@export_range(0.0, 0.1) var flap_buffer_window: float = 0.05
@export_range(0.0, 0.1) var dash_buffer_window: float = 0.05

## Action chaining. Skilled actions (timed flap, dive flap, bounce landing,
## dash) within the chain window extend the chain. When the window expires the
## chain decays one link at a time instead of resetting to zero. Repeating the
## same action type within the variety window pays diminishing returns.
@export var chain_window: float = 0.9
## Seconds between chain link decays after the chain window expires.
@export var chain_decay_step: float = 0.6
## Momentum gain multiplier per chain link beyond the first.
@export_range(0.0, 2.0) var chain_gain_bonus: float = 0.35
## Seconds a repeated action type stays "stale" for the variety clause.
@export var chain_variety_window: float = 2.0
## Gain multipliers for the 1st, 2nd, 3rd+ repeat of the same action type.
@export var chain_variety_factors: Array[float] = [1.0, 0.7, 0.4]

## Momentum meter. Built only by skilled actions; drains passively (faster on
## the ground) and takes a hit from spam flaps. Payouts in movement power:
## tier 1 boosts flap strength, tier 2 shortens the dash cooldown.
@export var momentum_gain_flap: float = 0.1
@export var momentum_gain_bounce: float = 0.2
@export var momentum_gain_dash: float = 0.08
@export var momentum_spam_penalty: float = 0.15
@export var momentum_air_drain_rate: float = 0.08
@export var momentum_ground_drain_rate: float = 0.4
## Tier 1: flap strength multiplier at this meter value or above.
@export var momentum_tier1: float = 0.5
@export var momentum_tier1_flap_boost: float = 1.15
## Tier 2: dash cooldown reduction at this meter value or above.
@export var momentum_tier2: float = 0.9

## Juice. Hit-stop freezes the game briefly on high-impact moments.
@export var hitstop_bounce_ref_speed: float = 500.0
@export var hitstop_bounce_max_duration: float = 0.1
@export var hitstop_dash_duration: float = 0.04
@export var hitstop_time_scale: float = 0.05

## Input actions
@export var input_left: StringName = &"move_left"
@export var input_right: StringName = &"move_right"
@export var input_down: StringName = &"move_down"
@export var input_flap: StringName = &"jump"
@export var input_dash: StringName = &"dash"

## Dash state. One mode instead of separate flags, so a dash always ends by
## restoring gravity and the fall clamp.
enum DashMode { NONE, HORIZONTAL, DOWN }
var dash_mode: DashMode = DashMode.NONE
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0
var _pre_dash_velocity_x: float = 0.0

## Action chain state
var chain_count: int = 0
var chain_timer: float = 0.0
var chain_decay_timer: float = 0.0
var _last_action_type: StringName = &""
var _last_action_time: float = 0.0
var _action_repeat_count: int = 0
var _time: float = 0.0

## Momentum meter (0..1)
var momentum: float = 0.0

## Stamina (0..max_stamina)
var stamina: float = 0.0

## Input buffers: countdown timers set by input events, consumed per tick.
var _flap_buffer_timer: float = 0.0
var _dash_buffer_timer: float = 0.0

## Flap lockout after a dive flap.
var _flap_lockout_timer: float = 0.0

## Hit-stop state (timestamp-based so overlapping hits extend, not corrupt).
var _hitstop_end_msec: int = 0


## Starts the run with a full stamina bar.
func _ready() -> void:
	stamina = max_stamina


## Captures flap and dash presses as buffered events.
func _unhandled_input(event: InputEvent) -> void:
	# Event-driven capture: every press lands here exactly once, so nothing is
	# lost between physics ticks. Consumption happens in _physics_process.
	if event.is_action_pressed(input_flap):
		_flap_buffer_timer = flap_buffer_window
	elif event.is_action_pressed(input_dash):
		_dash_buffer_timer = dash_buffer_window


## Runs the movement, dash, flap, bounce and meter systems for one tick.
func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(input_left, input_right)
	var grounded: bool = is_on_floor()
	_time += delta

	# Timers.
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	_flap_lockout_timer = maxf(_flap_lockout_timer - delta, 0.0)
	_flap_buffer_timer = maxf(_flap_buffer_timer - delta, 0.0)
	_dash_buffer_timer = maxf(_dash_buffer_timer - delta, 0.0)
	_update_chain(delta)
	_restore_time_scale()

	# Consume buffered inputs.
	var flap_pressed: bool = _flap_buffer_timer > 0.0 and _flap_lockout_timer == 0.0
	var dash_pressed: bool = _dash_buffer_timer > 0.0 and dash_cooldown_timer == 0.0 \
	and dash_mode == DashMode.NONE
	if flap_pressed:
		_flap_buffer_timer = 0.0
	if dash_pressed:
		_dash_buffer_timer = 0.0

	# Start dash
	if dash_pressed:
		dash_mode = DashMode.DOWN if Input.is_action_pressed(input_down) \
		else DashMode.HORIZONTAL
		dash_timer = dash_duration
		dash_cooldown_timer = _dash_cooldown_for_tier()

		if direction != 0.0:
			dash_direction = direction
		else:
			dash_direction = signf(velocity.x)

		if dash_direction == 0.0:
			dash_direction = 1.0

		# Keep part of the pre-dash momentum to layer the burst on.
		_pre_dash_velocity_x = velocity.x * dash_momentum_retention
		_register_skilled_action(&"dash", momentum_gain_dash)
		_start_hitstop(hitstop_dash_duration)
		dashed.emit(&"down" if dash_mode == DashMode.DOWN else &"horizontal")

	# Horizontal movement
	if dash_mode != DashMode.NONE:
		dash_timer -= delta
		var dash_frac: float = clampf(dash_timer / dash_duration, 0.0, 1.0)
		if dash_mode == DashMode.DOWN:
			# Downward dash: a clean vertical slam, gravity suppressed so the
			# speed stays sharp. Horizontal control stays available.
			velocity.y = lerpf(dash_down_speed,
					dash_down_speed * dash_down_end_factor, 1.0 - dash_frac)
		else:
			# Tight burst: peak speed decaying to dash_end_factor, layered on
			# the retained pre-dash momentum.
			var falloff: float = lerpf(1.0, dash_end_factor, 1.0 - dash_frac)
			velocity.x = dash_direction * dash_speed * falloff + _pre_dash_velocity_x
		if dash_timer <= 0.0:
			dash_mode = DashMode.NONE
	else:
		var accel: float = ground_acceleration if grounded else air_acceleration
		var fric: float = ground_friction if grounded else air_friction

		# Air control shrinks as horizontal speed grows: fast = committed.
		# An active chain partially restores it (chaining feel).
		if not grounded:
			var speed_frac: float = clampf(absf(velocity.x) / max_speed, 0.0, 1.0)
			var control: float = lerpf(1.0, 1.0 - air_control_loss_at_speed, speed_frac)
			if chain_timer > 0.0:
				control = minf(control * chain_air_control_bonus, 1.0)
			accel = accel * control

		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# Asymmetric gravity: heavier on the way down, lighter near the apex.
	# Suppressed during a downward dash so the slam stays sharp.
	var fall_gravity: float = gravity * (gravity_fall_multiplier if velocity.y > 0.0 else 1.0)
	if absf(velocity.y) <= apex_gravity_window:
		fall_gravity *= apex_gravity_multiplier
	if dash_mode != DashMode.DOWN:
		velocity.y += fall_gravity * delta

	# Flapping
	if flap_pressed:
		_do_flap(direction, grounded)

	# Clamp vertical velocity (except during a downward dash)
	if dash_mode != DashMode.DOWN:
		velocity.y = clampf(velocity.y, max_rise_speed, max_fall_speed)

	# Dive-bounce landing: convert a hard fall into a forward burst.
	var was_on_floor: bool = grounded
	var fall_speed: float = velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed >= bounce_min_fall_speed \
	and direction != 0.0:
		var burst: float = direction * fall_speed * bounce_conversion
		# Speed preservation: keep the faster of the bounce burst and current.
		velocity.x = _preserve_speed(velocity.x, burst)
		velocity.y = -bounce_pop
		_register_skilled_action(&"bounce", momentum_gain_bounce)
		stamina = minf(stamina + bounce_stamina_refund, max_stamina)
		stamina_changed.emit(stamina)
		_start_hitstop(minf(fall_speed / hitstop_bounce_ref_speed * hitstop_bounce_max_duration,
				hitstop_bounce_max_duration))
		bounced.emit(fall_speed)
	elif is_on_floor() and not was_on_floor:
		landed.emit(fall_speed)

	# Stamina regen on the ground.
	if is_on_floor() and stamina < max_stamina:
		stamina = minf(stamina + stamina_ground_regen_rate * delta, max_stamina)
		stamina_changed.emit(stamina)

	_update_momentum(delta, is_on_floor())


## Applies a flap. An airborne flap near the apex gets full impulse plus a
## bonus; flaps while rising fast are heavily reduced and drain momentum, so
## spamming costs you. Holding S/Down turns the flap into a dive flap. A flap
## also couples the held horizontal direction into extra sideways momentum
## (Joust steering). Flaps cost stamina: no stamina, no flap.
func _do_flap(direction: float, grounded: bool) -> void:
	if Input.is_action_pressed(input_down):
		# Dive flap: sink fast and gain horizontal speed, at the cost of a
		# brief flap lockout.
		if stamina < dive_flap_stamina_cost:
			return
		stamina -= dive_flap_stamina_cost
		stamina_changed.emit(stamina)
		velocity.y += dive_flap_downward
		if direction != 0.0:
			velocity.x += direction * dive_flap_horizontal
		_flap_lockout_timer = dive_flap_lockout
		_register_skilled_action(&"dive", momentum_gain_flap)
		flapped.emit(&"dive")
	else:
		# Neutral flap: strength falls off the faster you already rise.
		if stamina < flap_stamina_cost:
			return
		stamina -= flap_stamina_cost
		stamina_changed.emit(stamina)
		# Flap steering coupling: spending a flap to steer adds sideways momentum.
		if direction != 0.0:
			velocity.x += direction * flap_impulse * flap_steer

		var rise_frac: float = clampf(velocity.y / max_rise_speed, 0.0, 1.0)
		var factor: float = lerpf(1.0, flap_min_factor, rise_frac)
		var strength: float = _flap_strength_for_tier()
		# Only an airborne flap near the apex counts as timed; a ground tap
		# would otherwise always qualify at rest.
		if not grounded and absf(velocity.y) <= flap_timing_window:
			var impulse: float = (flap_impulse + flap_timing_bonus) * strength
			velocity.y = maxf(velocity.y - impulse, max_rise_speed)
			_register_skilled_action(&"timed", momentum_gain_flap)
			flapped.emit(&"timed")
		else:
			velocity.y = maxf(velocity.y - flap_impulse * factor * strength, max_rise_speed)
			if rise_frac > flap_spam_rise_threshold:
				# Spamming while rising fast: momentum takes a hit.
				momentum = maxf(momentum - momentum_spam_penalty, 0.0)
				momentum_changed.emit(momentum)
			flapped.emit(&"neutral")


## Registers a skilled action: extends the chain if it is still open, otherwise
## starts a new one, and adds momentum scaled by the chain length and the
## variety clause (repeating the same action type pays diminishing returns).
func _register_skilled_action(action_type: StringName, base_gain: float) -> void:
	if chain_timer > 0.0:
		chain_count += 1
	else:
		chain_count = 1
	chain_timer = chain_window
	chain_decay_timer = 0.0
	chain_changed.emit(chain_count)

	# Variety clause: repeats of the same action type within the window decay.
	if action_type == _last_action_type \
	and _time - _last_action_time <= chain_variety_window:
		_action_repeat_count += 1
	else:
		_action_repeat_count = 0
	_last_action_type = action_type
	_last_action_time = _time

	var variety_factor: float = 1.0
	if _action_repeat_count > 0:
		var index: int = mini(_action_repeat_count, chain_variety_factors.size() - 1)
		variety_factor = chain_variety_factors[index]

	var gain: float = base_gain * (1.0 + chain_gain_bonus * (chain_count - 1)) \
	* variety_factor
	momentum = minf(momentum + gain, 1.0)
	momentum_changed.emit(momentum)


## Lets the chain decay one link at a time after the window expires instead of
## resetting to zero (DMC-style gauge).
func _update_chain(delta: float) -> void:
	if chain_timer > 0.0:
		chain_timer = maxf(chain_timer - delta, 0.0)
		if chain_timer == 0.0:
			chain_decay_timer = chain_decay_step
	elif chain_count > 0:
		chain_decay_timer -= delta
		if chain_decay_timer <= 0.0:
			chain_count = maxi(chain_count - 1, 0)
			chain_decay_timer = chain_decay_step
			chain_changed.emit(chain_count)


## Returns the dash cooldown for the current momentum tier.
func _dash_cooldown_for_tier() -> float:
	if momentum >= momentum_tier2:
		return dash_cooldown * (1.0 - dash_cooldown_tier2_reduction)
	return dash_cooldown


## Returns the flap strength multiplier for the current momentum tier.
func _flap_strength_for_tier() -> float:
	if momentum >= momentum_tier1:
		return momentum_tier1_flap_boost
	return 1.0


## Speed preservation rule (Celeste): if the new speed is slower than the
## current speed in the same direction, keep the current speed.
func _preserve_speed(current_x: float, new_x: float) -> float:
	if signf(current_x) == signf(new_x) and absf(current_x) > absf(new_x):
		return current_x
	return new_x


## Freezes the game briefly for impact weight. Overlapping hits extend the
## freeze rather than corrupting it.
func _start_hitstop(duration: float) -> void:
	var end_msec: int = Time.get_ticks_msec() + int(duration * 1000.0)
	if end_msec > _hitstop_end_msec:
		_hitstop_end_msec = end_msec
		if Engine.time_scale != hitstop_time_scale:
			Engine.time_scale = hitstop_time_scale
			get_tree().create_timer(duration, true, false, true).timeout.connect(
					_restore_time_scale)


## Restores normal time scale when the hit-stop window has elapsed.
func _restore_time_scale() -> void:
	if Engine.time_scale != 1.0 and Time.get_ticks_msec() >= _hitstop_end_msec:
		Engine.time_scale = 1.0


## Restores the time scale if this node is freed mid-hit-stop.
func _exit_tree() -> void:
	if Engine.time_scale == hitstop_time_scale:
		Engine.time_scale = 1.0


## Drains the momentum meter passively; faster on the ground.
func _update_momentum(delta: float, grounded: bool) -> void:
	var drain: float = momentum_ground_drain_rate if grounded else momentum_air_drain_rate
	var before: float = momentum
	momentum = maxf(momentum - drain * delta, 0.0)
	if momentum != before:
		momentum_changed.emit(momentum)
