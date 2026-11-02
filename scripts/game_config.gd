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

# --- Speed bumps (Session 6) ---
# A bump isn't solid. Riding over one makes the bike hop, shakes the camera and slows you
# down, but only if you're going fast: slow down for bumps and you keep your speed.
const SPEED_BUMP_SAFE_KMH := 10.0     # at or under this speed a bump doesn't slow you at all
const SPEED_BUMP_SPEED_KEEP := 0.55   # share of speed kept when you hit a bump at 25 km/h or more
const SPEED_BUMP_HOP_MIN := 0.04      # metres the bike hops when crawling over
const SPEED_BUMP_HOP_MAX := 0.25      # metres the bike hops at full speed
const SPEED_BUMP_HOP_TIME := 0.45     # seconds the bounce lasts (a big hop, then a small one)
const SPEED_BUMP_TILT_DEG := 7.0      # how far the nose tips up (then down) at full speed
const SPEED_BUMP_SHAKE_MIN := 0.1     # camera shake when crawling over (0 to 1)
const SPEED_BUMP_SHAKE_MAX := 0.7     # camera shake at full speed (0 to 1)

# --- Camera ---
const CAMERA_DISTANCE := 4.5          # metres behind the bike
const CAMERA_HEIGHT := 2.2            # metres above the bike
const CAMERA_LOOK_HEIGHT := 1.2       # the camera aims at this height on the rider
const CAMERA_FOLLOW_SMOOTHING := 6.0  # higher = camera catches up faster

# --- World ---
const GRAVITY := 9.8
const WORLD_FALL_RESET_Y := -20.0      # if the bike drops below this height it goes back to the start
const WHEEL_RADIUS := 0.34            # metres, matches the wheel mesh (used to spin the wheels)

# --- Orders (Session 3) ---
const ORDER_NEXT_DELAY := 3.0         # seconds with no order before the next one pops up
const ORDER_OFFER_TIMEOUT := 30.0     # an order you ignore this long counts as skipped (PRD)
const ORDER_PAY_MIN := 8              # Dh, lowest Tier 1 pay (PRD: 8 to 15 Dh)
const ORDER_PAY_MAX := 15             # Dh, highest Tier 1 pay
const ORDER_PAY_BASE := 7.0           # Dh every order pays before the distance extra
const ORDER_PAY_PER_METRE := 0.03     # Dh extra per metre, straight line restaurant to villa (30 m = 8 Dh, 270 m = 15 Dh)
const ORDER_ACCEPT_HISTORY := 20      # acceptance rate looks at your last 20 accept/skip choices
const ORDER_LOW_ACCEPTANCE := 0.7     # below 70% you get boring orders: short ride, lowest pay
const ORDER_BORING_CHOICES := 2       # a boring order goes to one of the 2 villas closest to the restaurant
const INTERACT_RADIUS := 3.5          # metres from a door where E picks up or drops off
const DOOR_DISTANCE := 2.5            # the door spot is this many metres in front of a building
const DELIVERED_MESSAGE_TIME := 2.5   # seconds the phone shows "+12 Dh  Delivered!"
const MARKER_RADIUS := 1.2            # the glowing beam over the next stop
const MARKER_HEIGHT := 4.0            # lower than every roof (5 m and up), so the beam never covers a sign
const MARKER_COLOUR := Color(0.9490196, 0.54901963, 0.15686275, 0.4)  # see-through orange
