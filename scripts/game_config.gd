class_name GameConfig
## All the tuning numbers live here, so they're easy to change later.
## Speeds are in km/h or metres per second (m/s). 1 Godot unit = 1 metre.

# --- Bicycle ---
const BIKE_MAX_SPEED_KMH := 25.0      # top speed when pedalling
const BIKE_REVERSE_SPEED_KMH := 5.0   # how fast you roll backwards holding S
const BIKE_ACCELERATION := 3.0        # m/s gained per second while pedalling
const BIKE_BRAKE := 8.0               # m/s lost per second while braking (S)
const BIKE_COAST_DRAG := 1.0          # m/s lost per second when you let go
const BIKE_HANDBRAKE := 14.0          # m/s lost per second with Space
const BIKE_STEER_DEG_PER_SEC := 110.0 # how fast the bike turns
const BIKE_BUMP_SPEED_KEEP := 0.25    # speed kept after riding straight into something
const BIKE_LEAN_MAX_DEG := 14.0       # how far the rider leans into a turn at full speed
const BIKE_LEAN_SMOOTHING := 8.0      # higher = leans in and out faster

# --- Sprinting (hold Shift while pedalling) ---
const BIKE_SPRINT_MAX_SPEED_KMH := 32.0
const BIKE_SPRINT_ACCELERATION := 4.5 # m/s gained per second while sprinting
const STAMINA_MAX := 100.0
const STAMINA_DRAIN_PER_SEC := 22.0   # about 4.5 seconds of sprinting from full
const STAMINA_REFILL_PEDALLING := 6.0 # refill per second while pedalling normally
const STAMINA_REFILL_COASTING := 18.0 # refill per second when you stop pedalling
const STAMINA_TIRED_UNTIL := 25.0     # after running out, you can't sprint again until this much is back

# --- Bumps ---
const BUMP_MIN_STRENGTH := 0.15       # smaller knocks than this don't shake the camera
const BUMP_COOLDOWN := 0.4            # seconds between camera shakes
const CAMERA_SHAKE_AMOUNT := 0.25     # metres the camera jolts on a full-speed crash
const CAMERA_SHAKE_FADE := 5.0        # higher = shake dies down faster

# --- Camera ---
const CAMERA_DISTANCE := 4.5          # metres behind the bike
const CAMERA_HEIGHT := 2.2            # metres above the bike
const CAMERA_LOOK_HEIGHT := 1.2       # the camera aims at this height on the rider
const CAMERA_FOLLOW_SMOOTHING := 6.0  # higher = camera catches up faster

# --- World ---
const GRAVITY := 9.8
