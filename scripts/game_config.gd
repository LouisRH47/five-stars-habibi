class_name GameConfig
## All the tuning numbers live here, so they're easy to change later.
## Speeds are in km/h or metres per second (m/s). 1 Godot unit = 1 metre.

# --- Bicycle ---
const BIKE_MAX_SPEED_KMH := 28.0      # top speed when pedalling
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
const BIKE_SPRINT_MAX_SPEED_KMH := 36.0
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
const SPEED_BUMP_HEIGHT := 0.12      # metres; the wheels roll up this high (same as SPEED_BUMP_SIZE.y in data/wahat_al_shams.gd)
const SPEED_BUMP_HOP_MAX := 0.25      # metres the bike hops at full speed (crawling: just rolls over)
const SPEED_BUMP_HOP_TIME := 0.45     # seconds the extra springy bounce lasts (a big hop, then a small one)
const SPEED_BUMP_TILT_DEG := 7.0      # how far the nose tips up (then down) at full speed
const SPEED_BUMP_SHAKE_MIN := 0.1     # camera shake when crawling over (0 to 1)
const SPEED_BUMP_SHAKE_MAX := 0.7     # camera shake at full speed (0 to 1)

# --- Camera ---
const CAMERA_DISTANCE := 4.5          # metres behind the bike
const CAMERA_HEIGHT := 2.2            # metres above the bike
const CAMERA_LOOK_HEIGHT := 1.2       # the camera aims at this height on the rider
const CAMERA_COLLISION_RADIUS := 0.28
const CAMERA_COLLISION_MARGIN := 0.06
const HOUSING_DETAIL_DISTANCE := 135.0
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
const ORDER_NEARBY_HOME_CHANCE := 0.7  # share of orders that go to the nearer half of homes (Session 34: more, shorter trips)
const INTERACT_RADIUS := 3.5          # metres from a door where E picks up or drops off
# Session 18: picking up and dropping off need E held at the door while going slowly.
const PICKUP_HOLD_TIME := 1.5         # seconds to hold E at the restaurant
const DROPOFF_HOLD_TIME := 1.5        # seconds to hold E at the villa
const INTERACT_MAX_SPEED_KMH := 5.0   # faster than this at the door: "Slow down, then hold E"

# --- On foot (Session 19) ---
const GET_OFF_MAX_KMH := 5.0          # F only works when the bike is slower than this
const WALK_SPEED_KMH := 5.0           # W on foot
const JOG_SPEED_KMH := 9.0            # Shift + W on foot
const WALK_ACCELERATION := 8.0        # m/s gained per second on foot
const WALK_TURN_DEG_PER_SEC := 150.0  # A / D on foot
const GET_ON_DISTANCE := 2.0          # metres from the bike where F gets you back on
const BIKE_FAR_DISTANCE := 40.0       # further than this: "Your bike is over there"
const PARKED_LEAN_DEG := 8.0          # the parked bike leans on its stand
const DOOR_DISTANCE := 2.5            # the door spot is this many metres in front of a building
const MARKER_RADIUS := 1.2            # the glowing beam over the next stop
const MARKER_HEIGHT := 4.0            # lower than every roof (5 m and up), so the beam never covers a sign
const MARKER_COLOUR := Color(0.9490196, 0.54901963, 0.15686275, 0.4)  # see-through orange

# --- Order notes (Session 7) ---
const ORDER_NOTE_CHANCE := 0.25       # share of orders that come with one of the notes below
const ORDER_LEAVE_AT_DOOR_CHANCE := 0.15  # share of orders where nobody comes out (Session 11)
const ORDER_LEAVE_AT_DOOR_NOTE := "Leave it at the door, please"
const ORDER_NOTES := [                # picked at random; shown on the phone
	"Please don't ring the bell, the baby is asleep",
	"Extra napkins, please!",
	"Call me when you're outside",
	"Watch out for the cat by the gate",
	"Knock twice, the bell is broken",
]

# --- Mini-map (Session 7) ---
const MINIMAP_SIZE := 280.0           # pixels, the square in the bottom-left corner
const MINIMAP_METRES_ACROSS := 170.0  # how many metres of the map fit across it (bigger = zoomed out)
const MINIMAP_EDGE_INSET := 16.0      # pixels: a stop that's off the map gets pinned this far inside the edge

# --- Meters (Session 8) ---
# Every meter goes from 100 (green) down to 0 (red). Above 60 is green, 30 to 60 orange,
# under 30 red (PRD "How the meters go from green to red"). A red meter never cancels the order.
const METER_GREEN_ABOVE := 60.0
const METER_RED_BELOW := 30.0
# Time: target = straight-line distance at 20 km/h, times 1.5 for corners, plus 20 seconds.
const TIME_TARGET_SPEED_KMH := 20.0
const TIME_TARGET_CORNERS := 1.5
const TIME_TARGET_EXTRA := 20.0       # seconds
# How the time bar drains (Session 17 tuning): it's at TIME_METER_AT_TARGET % when you reach
# the target time (60 = the edge of green, so on time = green), and empty at
# TIME_EMPTY_AT x the target. The PRD's first idea was 0 and 1.0 (empty at the target),
# but then even on-time rides ended red.
const TIME_METER_AT_TARGET := 60.0
const TIME_EMPTY_AT := 2.0
# Freshness lost per second, per food (pizza slow, bubble tea medium, ice cream fast).
# Session 27 foods: shawarma goes cold (medium), cake keeps but breaks on bumps, groceries are
# slow to spoil and a bit heavy, farm juice and salad spoil in the sun.
const FRESHNESS_DRAIN := {"pizza": 0.25, "bubble tea": 0.4, "ice cream": 0.55,  # Session 17: was 0.35/0.6/1.0
		"shawarma": 0.35, "cake": 0.2, "groceries": 0.1, "farm juice": 0.5, "salad box": 0.45, "pad thai": 0.35, "sushi": 0.5, "tacos": 0.3, "burgers": 0.3, "coffee": 0.4, "manakish": 0.25}  # Session 27
# Damage lost per knock, per food. Bubble tea hates speed bumps.
const DAMAGE_SPEED_BUMP := {"pizza": 3.0, "bubble tea": 14.0, "ice cream": 5.0,  # at full speed
		"shawarma": 4.0, "cake": 16.0, "groceries": 6.0, "farm juice": 10.0, "salad box": 6.0, "pad thai": 7, "sushi": 9, "tacos": 14, "burgers": 5, "coffee": 14, "manakish": 4}  # cake breaks on bumps
const DAMAGE_SPEED_BUMP_SLOW_SHARE := 0.25  # at or under SPEED_BUMP_SAFE_KMH a bump costs a quarter of that
const DAMAGE_HARD_BRAKE := {"pizza": 3.0, "bubble tea": 8.0, "ice cream": 4.0,
		"shawarma": 3.0, "cake": 9.0, "groceries": 5.0, "farm juice": 7.0, "salad box": 4.0, "pad thai": 5, "sushi": 5, "tacos": 8, "burgers": 3, "coffee": 8, "manakish": 3}
const DAMAGE_COLLISION := {"pizza": 15.0, "bubble tea": 25.0, "ice cream": 18.0,  # a full-speed head-on hit
		"shawarma": 15.0, "cake": 30.0, "groceries": 20.0, "farm juice": 25.0, "salad box": 18.0, "pad thai": 18, "sushi": 22, "tacos": 25, "burgers": 15, "coffee": 25, "manakish": 15}
# Hard braking: braking (S or Space) while going faster than this counts once per press.
const HARD_BRAKE_MIN_KMH := 22.0       # Session 17: was 18, then normal braking counted too

# --- Moving obstacles (Session 9) ---
const CAT_WALK_SPEED := 0.8           # m/s, a slow stroll
const CAT_RUN_SPEED := 4.0            # m/s, running off after you bump it
const CAT_PAUSE_MIN := 1.5            # seconds a cat sits still between strolls
const CAT_PAUSE_MAX := 4.0
const SCOOTER_SPEED := 2.5            # m/s, about 9 km/h
const SCOOTER_TURN_PAUSE := 1.5       # seconds a kid waits at each end before turning round
const SCOOTER_GIVE_WAY_TIME := 2.0    # seconds a kid waits for you before turning back
const CRITTER_SCARED_TIME := 1.5      # seconds a bumped cat runs / a bumped kid stops
# Extra food damage when you bump a cat or a kid (on top of the crash itself).
const DAMAGE_CRITTER := {"pizza": 10.0, "bubble tea": 15.0, "ice cream": 12.0,
		"shawarma": 10.0, "cake": 16.0, "groceries": 12.0, "farm juice": 15.0, "salad box": 12.0, "pad thai": 12, "sushi": 14, "tacos": 15, "burgers": 10, "coffee": 15, "manakish": 10}

# --- Stars, tips, XP and rating (Session 10) ---
# Stars: start at 5, each orange meter takes off 0.5, each red one 1.5. Never below 1 (PRD).
const STARS_ORANGE_COST := 0.5
const STARS_RED_COST := 1.5
const STARS_MIN := 1.0
const RATING_WINDOW := 50             # your rating averages your last 50 deliveries
const TIP_CHANCE := 0.4               # only on 5-star deliveries (and never on boring orders)
const TIP_MIN := 2                    # Dh
const TIP_MAX := 15                   # Dh
const XP_PER_DELIVERY := 10           # every delivery gives this much XP...
const XP_PER_STAR := 2                # ...plus this much per star (5 stars = 20 XP in all)
const LEVEL_XP_FIRST := 50            # XP from Rider Level 1 to 2
const LEVEL_XP_STEP := 25             # each next level needs this much more than the last
const RESULT_MESSAGE_TIME := 4.0      # seconds the phone shows your stars after a delivery

# --- Customers at the door (Session 11) ---
const CUSTOMER_STEP_OUT := 1.2        # metres the customer walks out of the door
const CUSTOMER_WALK_TIME := 0.6       # seconds to walk out (and back in)
const CUSTOMER_TALK_TIME := 3.5       # seconds the speech bubble shows
const PARCEL_STAYS_TIME := 8.0        # seconds a left-at-the-door bag stays on the doorstep
const DEFAULT_RIDER_NAME := "habibi"  # what customers call you before you've filled in the application

# --- Crashes, bills and insurance (Session 12) ---
# A crash is hitting something fairly straight on (HEAD_ON or more, 1 = dead straight).
const CRASH_HEAD_ON := 0.6
const CRASH_SMALL_KMH := 10.0         # hitting anything at this speed or more: you fall off
const CRASH_BIG_KMH := 20.0           # hitting a car, wall or pole faster than this: clinic (PRD)
const CRASH_FALLEN_TIME := 2.0        # seconds on the ground after a small crash
const CRASH_SMALL_DAMAGE := 40.0      # % off the damage meter for a small crash (was 30, Session 52)
const CRASH_GRACE_TIME := 2.0         # seconds after getting back up when you can't fall off again
const CRASH_PUSH_BACK := 0.8          # metres the bike is moved away from what you hit, after a small fall
const HOSPITAL_BILL := 150            # Dh, big crash on the bicycle (PRD)
const REPAIR_BILL := 80               # Dh
const INSURED_CRASH_COST := 20        # Dh, all you pay for a big crash with insurance
const INSURANCE_PER_DELIVERY := 2     # Dh, taken from every delivery while insurance is on
const CRASH_FADE_TIME := 0.6          # seconds the screen takes to fade out (and back in)
const CRASH_WEEK_SHIFTS := 7          # "this week" on the clinic screen = the last 7 shifts
const CRASH_WEEK_WARNING := 3         # the clinic's crash bar is full at this many big crashes
const CRASH_GLANCING_MIN := 0.2
const CRASH_MAJOR_SCORE := 18.0
const CRASH_SEVERE_SCORE := 25.0
const CRASH_CRITICAL_SCORE := 35.0
const CRASH_GLANCE_WEIGHT := 0.2
const CRASH_TIP_SCORE := 12.0
const CRASH_TUMBLE_HEAD_ON := 0.65
const CRASH_MATERIAL_HARDNESS := {"soft": 0.35, "wood": 0.8, "vehicle": 1.15, "rigid": 1.0}
const CRASH_FALL_DURATIONS := {"tip": 1.4, "skid": 1.8, "tumble": 2.2}
# Session 54: rag-doll falls (the rider goes floppy instead of stiff)
const RAGDOLL_ON := true                 # false = the old stiff falls
const RAGDOLL_STEPS_PER_SECOND := 120.0  # small fixed steps, so it stays steady
const RAGDOLL_MAX_STEPS := 400           # most steps in one go (a long pause can't freeze the game)
const RAGDOLL_ITERATIONS := 8            # how hard the sticks hold their length each step
const RAGDOLL_GRAVITY := 9.8
const RAGDOLL_AIR_DAMPING := 0.998       # a tiny bit of air drag
const RAGDOLL_GROUND_FRICTION := 0.95    # sliding on the ground (lower = stops sooner)
const RAGDOLL_BOUNCE := 0.25             # how much a body bounces off the ground
const RAGDOLL_BRACE_STIFFNESS := 0.35    # the chest and pelvis bend a little, not a lot
const RAGDOLL_STILL_SPEED := 0.15        # m/s: slower than this counts as lying still
const RAGDOLL_SETTLE_TIME := 0.3         # seconds still before "settled"
const RAGDOLL_KEEP_SPEED := 0.6          # share of the bike's speed the rider keeps (along the wall)
const RAGDOLL_BOUNCE_BACK := 1.2         # m/s pushed back off the thing you hit
const RAGDOLL_UP_KICK := {"tip": 0.6, "skid": 1.2, "tumble": 2.6}    # m/s thrown upwards
const RAGDOLL_SPIN := {"tip": 2.5, "skid": 6.0, "tumble": 6.0}       # how fast the body turns over
const CRASH_BILL_BANDS := {
	"minor": {"hospital": 0, "repair": 0, "insured": 0},
	"moderate": {"hospital": 60, "repair": 35, "insured": 8},
	"severe": {"hospital": 150, "repair": 80, "insured": 20},
	"critical": {"hospital": 220, "repair": 140, "insured": 35},
}

# --- Shifts (Session 13) ---
const SHIFT_START_HOUR := 8.0         # the clock shows 08:00 when the shift starts...
const SHIFT_END_HOUR := 18.0          # ...and 18:00 when it's over (day shift only in Tier 1)
const GAME_MINUTES_PER_REAL_SECOND := 1.0  # fixed clock rate while gameplay is running
const SHIFT_LENGTH := (SHIFT_END_HOUR - SHIFT_START_HOUR) * 60.0 / GAME_MINUTES_PER_REAL_SECOND  # 600 active seconds
const CLOCK_STEP_MINUTES := 1         # display every game minute (once per active second)
const SHIFT_WARNING_TIME := 30.0      # the clock turns orange this many active seconds before the end

# --- Application and tutorial (Session 14) ---
const APPLICATION_REVIEW_TIME := 2.0  # seconds of "Reviewing..." before you're hired
const RIDER_NAME_MAX := 16            # letters allowed in your name
const TUTORIAL_LAST_TIPS_TIME := 7.0  # seconds each of the last two tips stays up

# --- The Schedule I look and real grass (Session 55) ---
# Bright, clean and cartoony: warm light, shadows that aren't black, a little more colour,
# matte (not shiny) surfaces and simple painted ground textures. scripts/sun_cycle.gd uses these.
const STYLIZED_TEXTURES := true     # false = the old photo textures
const LOOK_EXPOSURE := 1.3          # overall brightness
const LOOK_SATURATION := 1.3        # 1 = normal colour, more = more colourful
const LOOK_CONTRAST := 1.05
const LOOK_WHITE := 6.0             # how bright something must be to show as pure white (higher = fewer burnt-out whites)
const LOOK_AMBIENT_SCALE := 1.0     # times the "ambient" numbers in LIGHT_KEYS (the light in the shadows)
const LOOK_SHADOW_OPACITY := 0.78   # 1 = shadows as dark as possible, lower = softer, never black
const LOOK_FOG_BEGIN := 130.0       # metres: the soft haze starts here...
const LOOK_FOG_END := 900.0         # ...and is full here
const LOOK_FOG_AMOUNT := 0.55       # how thick the haze is at its fullest (0 to 1)
const MATTE_SPECULAR := 0.25        # how much surfaces shine (0.5 is Godot's normal)
const MATTE_MIN_ROUGHNESS := 0.8    # surfaces are at least this rough (matte) unless meant to shine (glass, water)
# Grass blades (scripts/grass_field.gd): tufts of 6 blades that sway in the wind and bend
# away from the bike. Only built close to the camera, in squares of GRASS_CHUNK metres.
const GRASS_BLADES_ON := true
const GRASS_TUFTS_PER_M2 := [3.0, 7.0, 12.0]   # Low, Medium, High (6 blades each)
const GRASS_RADIUS := [26.0, 38.0, 45.0]        # metres from the camera with grass (Low, Medium, High)
const GRASS_FADE := 10.0                        # the last 10 m the blades shrink away
const GRASS_CHUNK := 16.0
const GRASS_BUILD_MS := 2.0                     # milliseconds per frame spent filling in new grass
const GRASS_HEIGHT := Vector2(0.22, 0.42)       # shortest and tallest blade (metres)
const GRASS_WIND_STRENGTH := 0.08               # how far the tips sway (metres)
const GRASS_WIND_SPEED := 1.4
const GRASS_PUSH_RADIUS := 1.3                  # blades this close to the bike bend away
const GRASS_ROOT := Color(0.2, 0.42, 0.14)      # colour at the bottom of a blade...
const GRASS_TIP := Color(0.62, 0.8, 0.32)       # ...and at the tip

# --- Light and sky (Session 28) ---
# The sun follows the shift clock (scripts/sun_cycle.gd). Each line is one moment of the
# day; in between, everything blends smoothly. hour = clock time, height = how high the
# sun is (degrees above the ground), sun = sun colour, energy = how bright the sun is,
# top / horizon = sky colours, ambient = how bright the shadows are.
const LIGHT_KEYS := [
	{"hour": 8.0, "height": 16.0, "sun": Color(1.0, 0.8, 0.6), "energy": 0.95,
			"top": Color(0.36, 0.6, 0.82), "horizon": Color(0.98, 0.86, 0.72), "ambient": 0.75},
	{"hour": 10.0, "height": 45.0, "sun": Color(1.0, 0.94, 0.85), "energy": 1.0,
			"top": Color(0.3, 0.63, 0.85), "horizon": Color(0.84, 0.92, 0.95), "ambient": 0.85},
	{"hour": 12.5, "height": 72.0, "sun": Color(1.0, 0.99, 0.96), "energy": 0.9,
			"top": Color(0.27, 0.6, 0.86), "horizon": Color(0.86, 0.93, 0.96), "ambient": 0.75},
	{"hour": 15.0, "height": 45.0, "sun": Color(1.0, 0.95, 0.86), "energy": 1.0,
			"top": Color(0.3, 0.62, 0.85), "horizon": Color(0.86, 0.91, 0.92), "ambient": 0.85},
	{"hour": 16.5, "height": 26.0, "sun": Color(1.0, 0.86, 0.66), "energy": 1.1,
			"top": Color(0.33, 0.56, 0.8), "horizon": Color(0.98, 0.84, 0.66), "ambient": 0.85},
	{"hour": 17.25, "height": 14.0, "sun": Color(1.0, 0.72, 0.42), "energy": 1.05,
			"top": Color(0.34, 0.48, 0.74), "horizon": Color(1.0, 0.72, 0.46), "ambient": 0.8},
	{"hour": 18.0, "height": 5.0, "sun": Color(1.0, 0.58, 0.3), "energy": 0.85,
			"top": Color(0.3, 0.38, 0.64), "horizon": Color(0.98, 0.58, 0.36), "ambient": 0.6},
]
const SUN_TURN_MORNING := 95.0     # degrees: the sun starts in the east...
const SUN_TURN_EVENING := -95.0    # ...and ends in the west
const SUN_TURN_TILT := 20.0        # turns the whole path a little, so shadows don't run along the roads
const SKY_UPDATE_HOURS := 0.05     # sky colours update every 0.05 in-game hours (1.5 s), cheaper than every frame
# Haze (fog), glow, soft corner shadows (SSAO) and heat shimmer.
const HAZE_DENSITY := 0.0025       # thicker = the far end of the map fades into the sky sooner
const HAZE_SKY_MIX := 0.4          # how much the haze takes the sky's colour (0 to 1)
const GLOW_STRENGTH := 0.35        # the gentle glow on bright things
const GLOW_THRESHOLD := 1.0        # only things brighter than this glow
const SSAO_RADIUS := 1.2           # metres: how far the soft corner shadows reach
const SSAO_INTENSITY := 1.6        # how dark the corner shadows are
const SHIMMER_START_HOUR := 10.5   # heat shimmer fades in from here...
const SHIMMER_PEAK_HOURS := Vector2(12.0, 14.0)  # ...is strongest between these hours...
const SHIMMER_END_HOUR := 15.5     # ...and is gone again by here
const SHIMMER_NEAR := 18.0         # metres: no shimmer closer than this
const SHIMMER_FULL := 55.0         # metres: full shimmer from here on
const SHIMMER_AMOUNT := 0.0018     # how far the picture wobbles (part of the screen width)
# The Graphics setting (0 Low, 1 Medium, 2 High): how far away shadows are still drawn (metres).
const SHADOW_DISTANCE := [60.0, 150.0, 260.0]
# Session 52: the sun turns in steps this long (in game hours), so shadows don't shimmer.
const SUN_STEP_HOURS := 2.0 / 60.0
const SHADOW_MAP_SIZE := [2048, 4096, 8192]  # sun shadow map size on Low, Medium, High (Session 52)
const CAMERA_NEAR := 0.1              # metres: a little further than Godot's 0.05 stops far-off flicker
const CAMERA_FAR := 1500.0            # metres: the whole map fits, nothing past it is drawn
# --- Houses (Session 26) ---
const HOUSE_STOREY := 2.6             # metres per floor (homes have 2 floors)
const HOUSE_PARAPET := 0.5            # the low wall round the roof terrace
const HOUSE_ANNEX_HEIGHT := 3.0       # the one-floor side part with the wind tower
const HOUSE_COURTYARD_WALL := 1.3     # how high the low courtyard wall is
const HOUSE_SIDE_YARD := 2.5          # metres beside a home where buggies, bikes and lawns may go
const HOUSE_FRONT_STRIP := 0.8        # pot plants may stand this far in front of the front wall
const SIGNATURE_EXTRA_DEPTH := 3.0    # signature villas are this much deeper (at the back)...
const SIGNATURE_EXTRA_WIDTH := 2.0    # ...and this much wider on the courtyard side
const HOUSE_NUMBER_FONT := 130        # size of the house number by the door
const CLUSTER_SIGN_INSET := 3.0       # cluster signs start this far from the cluster edge (then step clear of roads)...
const CLUSTER_SIGN_SIDE := 4.6        # ...and this far to the house side of the middle lane (posts stay off the lane)
# How likely each extra is (0 = never, 1 = always). Picked from the home's number, so the
# same home always looks the same.
const HOUSE_BUGGY_CHANCE := 0.45      # a golf buggy beside the house
const HOUSE_BIKES_CHANCE := 0.5       # bikes beside the house (when there's no buggy)
const HOUSE_DISH_CHANCE := 0.4        # a satellite dish
const HOUSE_TOYS_CHANCE := 0.45       # kids' toys
const HOUSE_FLIP_CHANCE := 0.5        # the house is built mirror-image (courtyard on the other side)
const HOUSE_POOL_CHANCE := 0.5        # garden and signature villas: a pool, otherwise a trampoline
# --- People and bike (Session 29) ---
const PERSON_HEIGHT := 1.75           # metres, a grown-up (kids are made smaller)
const KID_HEIGHT := 1.3               # metres, a school kid
const PERSON_WALK_ANIM_MPS := 1.4     # the walk animation looks right at this speed (m/s)
const PERSON_JOG_ANIM_MPS := 3.0      # the jog animation looks right at this speed (m/s)
const PERSON_BLEND_TIME := 0.2        # seconds to blend from one animation to the next
const WAVE_TIME := 1.7                # seconds a person waves for
const PEDAL_GEAR := 2.2               # wheel turns per pedal turn (bigger = slower pedals)
const RIDER_LEAN_DEG := 18.0          # how far the rider leans forward over the handlebars
const HANDLEBAR_MAX_DEG := 25.0       # how far the handlebars turn when you steer
const HANDLEBAR_SMOOTHING := 10.0     # how quickly the handlebars follow the keys
const KICKSTAND_SPEED := 6.0          # how quickly the kickstand swings down or up
const BELL_HEAR_RANGE := 15.0         # metres: people and cats this close hear the bell
const BELL_SCARE_TIME := 1.2          # seconds a cat runs off (or a kid stops) after the bell


# --- Juice (Session 31) ---
# Dust puffs from the back tyre (scripts/tyre_dust.gd).
const DUST_AMOUNT := [10, 22, 36]     # puffs alive at once for Graphics Low, Medium, High
const DUST_LIFETIME := 0.7            # seconds one puff lasts
const DUST_MIN_KMH := 6.0             # slower than this on sand: no dust
const DUST_BRAKE_TIME := 0.45         # seconds of extra dust after you brake hard
const DUST_PUFF_SIZE := 0.22          # metres across a puff when it starts (it grows)
# Sprinting: a slightly wider camera and speed lines at the screen edges.
const SPRINT_FOV_EXTRA := 12.0         # degrees wider while sprinting
const SPRINT_FOV_SPEED := 4.0         # how quickly the camera widens and comes back
const SPEED_LINES_COUNT := 22         # streaks at the edges of the screen
const SPEED_LINES_ALPHA := 0.65       # how see-through they are at full strength (0 to 1)
# Delivered card pops (scripts/delivered_card.gd and scripts/pop_icon.gd).
const POP_FIRST_DELAY := 0.25         # seconds after the card shows before the first star pops
const POP_STAR_GAP := 0.13            # seconds between one star pop and the next
const POP_COINS := 7                  # coins that fly out of the "You earned" total
const POP_ICON_TIME := 0.8            # seconds one little icon lives
# The phone buzz when a new order comes in (scripts/phone.gd).
const PHONE_BUZZ_PIXELS := 6.0        # how far the phone shakes sideways
const PHONE_BUZZ_TIME := 0.35         # seconds the shake lasts

# --- Life on the map (Session 30) ---
const BUGGY_SPEED := 3.0              # m/s, about 11 km/h: golf buggies drive slowly
const HORSE_WALK_SPEED := 1.6         # m/s, a horse walking
const HORSE_TROT_SPEED := 3.4         # m/s, a horse trotting
const HORSE_GAIT_TIME := Vector2(8.0, 16.0)  # seconds before a horse switches between walk and trot
const WALKER_SPEED := 1.3             # m/s, people out for a walk
const JOGGER_SPEED := 2.8             # m/s, joggers on the bike track
const PLAY_KID_SPEED := 2.0           # m/s, kids running round the playgrounds
const DUCK_SPEED := 0.45              # m/s, ducks paddling along the stream
const DONKEY_SPEED := 0.5             # m/s, donkeys strolling in their pen
const LIFE_END_PAUSE := 2.0           # seconds a buggy, horse or walker waits at the end of its route
const LIFE_GIVE_UP_TIME := 5.0        # seconds one waits for you to move before turning round
const LIFE_TURN_SPEED := 4.0          # how quickly they turn to face where they're going
## Low / Medium / High: further away than this, people stop animating and are hidden (faster).
const LIFE_VIEW_DISTANCE := [70.0, 100.0, 140.0]
const BIRD_SPEED := 8.0               # m/s, birds circling over the community
const PALM_SWAY_DEG := 2.5            # how far the palm tops sway in the breeze
const PALM_SWAY_SPEED := 0.9          # how fast they sway
const WATER_FLOW_SPEED := 0.6         # how fast the ripples on the stream and fountain move


# --- Random events (Session 33) ---
const EVENTS_PER_SHIFT_MIN := 1         # each shift has 1 or 2 random events...
const EVENTS_PER_SHIFT_MAX := 2         # ...never more than this (one at a time)
const EVENT_EARLIEST_HOUR := 9.0        # events start somewhere between these in-game hours
const EVENT_LATEST_HOUR := 16.0
const EVENT_GAP_HOURS := 1.0            # at least this long between the start of one event and the next
const EVENT_WARNING_TIME := 6.0         # real seconds the phone warns you before the event starts
const EVENT_CLEAR_DISTANCE := 15.0      # metres: road works never pop up this close to you or your bike
const ROAD_WORKS_HOURS := Vector2(1.0, 2.0)  # road works last between 1 and 2 in-game hours
const CROSSING_WALK_SPEED := 2.2         # m/s, the groom leading the horses (a brisk walk)
const HORSE_GAP := 2.5                  # metres between the groom and each horse in the line
const HORSE_COUNT := Vector2i(2, 3)     # the groom leads 2 or 3 horses
const HORSE_GIVE_UP_TIME := 8.0         # seconds the horses wait if you block them, then they go back in
const HORSE_CLEAR_DISTANCE := 4.0       # metres: horses never start crossing this close to you or your bike
# --- Special orders, goals and regulars (Session 32) ---
# Special orders (PRD "Special orders, goals and events"). An order has at most one.
const SPECIAL_ORDER_CHANCE := 1.0 / 6.0   # about 1 in 6 orders is special
const SPECIAL_KINDS := ["rush", "fragile", "neighbour", "family"]
const SPECIAL_NAMES := {"rush": "Rush", "fragile": "Fragile cake", "neighbour": "Neighbour", "family": "Big family"}
const SPECIAL_COLOURS := {            # the chip colour on the phone
	"rush": Color(0.85, 0.22, 0.2, 1),       # red
	"fragile": Color(0.88, 0.4, 0.62, 1),    # pink
	"neighbour": Color(0.45, 0.33, 0.7, 1),  # purple
	"family": Color(0.2, 0.45, 0.8, 1),      # blue
}
const RUSH_TIME_SHARE := 0.7          # rush: the target time is 70% of normal...
const RUSH_PAY_SHARE := 1.5           # ...and it pays 50% more
const FRAGILE_SHOP := "bakery"        # fragile cakes always come from Sunrise Bakery
const FRAGILE_FOOD := "cake"
const FRAGILE_DAMAGE_TIMES := 2.0     # every knock does double damage to a fragile cake
const FRAGILE_TIP_CHANCE := 0.6       # tip chance on a 5-star fragile cake (normal: TIP_CHANCE)
const NEIGHBOUR_BONUS := 5            # Dh extra for taking it to the neighbour
const NEIGHBOUR_NOTE := "Not home! Leave it with the neighbour at %s"
const NEIGHBOUR_CHOICES := 3          # maps without clusters: one of the 3 nearest homes
const FAMILY_PAY_TIMES := 2           # big family order: double pay...
const FAMILY_SPEED_SHARE := 0.85      # ...but two bags: top speed 15% lower...
const FAMILY_WOBBLE_DEG := 7.0        # ...and the steering wobbles up to this many degrees a second...
const FAMILY_WOBBLE_SPEED := 2.2      # ...this many times a second

# School, stables and farm orders. The drop-off spots are VILLAS entries with "kind": "spot".
const SCHOOL_SPOT := 901              # the security booth at the school gate
const STABLES_SPOT := 902             # the stable office
const SCHOOL_OPEN_HOUR := 8.0         # school orders only between 08:00...
const SCHOOL_CLOSE_HOUR := 15.0       # ...and 15:00 on the shift clock
const SCHOOL_ORDER_CHANCE := 0.08     # share of orders that go to the school (outside lunch)
const LUNCH_START_HOUR := 11.5        # lunch rush from 11:30...
const LUNCH_END_HOUR := 12.5          # ...to 12:30...
const LUNCH_SCHOOL_CHANCE := 1.0 / 3.0  # ...when about 1 in 3 orders is for the school
const STABLES_ORDER_CHANCE := 0.06    # share of orders for the stable office (riders and grooms)
const FARM_SHOP := "farm"             # the Wahat Farm Stall...
const FARM_PICKUP_CHANCE := 1.0 / 8.0 # ...is the pickup for about 1 in 8 orders

# Regular customers (who they are and where they live: REGULARS in data/wahat_al_shams.gd,
# what they say: data/customer_lines.gd).
const REGULAR_ORDER_CHANCE := 0.15    # share of orders from one of the regulars (more than anyone else)
const REGULAR_TIP_CHANCE := 0.6       # regulars tip more often on 5-star jobs
const REGULAR_COLOUR := Color(0.86, 0.25, 0.42, 1)  # the heart chip on the phone

# Shift goals: 2 picked at the start of each shift, 15 Dh each when done (paid at the end).
const GOALS_PER_SHIFT := 2
const GOAL_BONUS := 15                # Dh per goal done
const GOAL_DELIVERIES := 6            # "Make 6 deliveries" (PRD said 8: too many for a 5-minute shift)
const GOAL_FIVE_STAR_STREAK := 3      # "3 five-star deliveries in a row"
const GOAL_LUNCH_ORDERS := 1          # "A school lunch order" (11:30–12:30 is 60 active seconds)
const GOAL_CLUSTERS := 3              # "Deliver to 3 different clusters" (PRD said all 5: too many for 5 minutes)
const GOAL_NO_CRASH_MIN_DELIVERIES := 1  # "No crashes" also needs at least this many deliveries

# --- Replay progression (Sessions 47–50) ---
const STREAK_TIP_STEP := 0.05
const STREAK_TIP_MAX := 0.30
const ORDER_CHOICE_RATING := 4.5
const ORDER_CHOICE_CHANCE := 0.5
const HOT_NOON_FRESHNESS_MULTIPLIER := 1.25
const RUSH_HOUR_ORDER_DELAY_SHARE := 0.5
const RUSH_HOUR_PAY_MULTIPLIER := 1.1
const SHOP_SPECIAL_TIP_MULTIPLIER := 2.0
const FRIENDLY_VISITS := 3
const BEST_FRIEND_VISITS := 8
const BEST_FRIEND_TIP_CHANCE := 0.7
const COLLECTION_STAMP_INTERVAL := 25
const COLLECTION_STAMP_BONUS := 20
const COLLECTION_HOMES_PER_CLUSTER := 100
const ANIMAL_MEET_DISTANCE := 4.0

# --- Equipment effects (Session 45) ---
const INSULATED_BAG_FRESHNESS_SHARE := 0.75
const ANTI_SPILL_DAMAGE_SHARE := 0.7
const COMFY_TYRES_DAMAGE_SHARE := 0.7
const BETTER_BRAKES_DAMAGE_SHARE := 0.7
const BOOST_FOOD_DAMAGE_TIMES := 3.0
const BOOST_SPEED_KMH := 80.0
const BOOST_DURATION := 4.0
const BOOST_COOLDOWN := 30.0

const RECEPTION_ORDER_CHANCE := 0.08

# --- District traffic and horse rails ---
const TRAFFIC_CAR_SPEED := 5.0
const TRAFFIC_BUS_SPEED := 11.5
const TRAFFIC_STOP_DISTANCE := 5.5
const TRAFFIC_PARK_WAIT := 8.0
const BUS_INTERVAL_GAME_MINUTES := 60.0
const BUS_DWELL_TIME := 8.0
const HORSE_RAIL_HEIGHT := 1.35
const HORSE_RAIL_SPACING := 4.0
const ARENA_JUMP_HEIGHT := 1.2
const ARENA_JUMP_REACH := 3.5
# --- Shops ---
const GEAR_PRICES := {"gps":50,"bell":25,"insulated_bag":70,"anti_spill":70,"stamina":40,"brakes":90,"tyres":90,"aluminium":90,"carbon":200,"rocket":10000}
const STAMINA_PRICE_STEP := 20
const COSMETIC_PRICES := {"paint":25,"box":20,"caps":20,"glasses":25,"helmets":35,"tops":40,"shoes":30,"bags":35}
const SHOP_HOLD_TIME := 0.7
const SHOP_INTERACT_DISTANCE := 2.2
const SHOP_PREVIEW_TURN_SPEED := 0.25

# --- Optional GPS route ---
const GPS_REPLAN_SECONDS := 0.5
const GPS_REPLAN_METRES := 3.0
const GPS_LINE_WIDTH := 0.45
const GPS_LINE_HEIGHT := 0.08
const GPS_WALL_COST := 2.0

const GPS_SCAN_CELLS_PER_FRAME := 4000
const CRASH_FORCE_SCALE := Vector2(0.6, 1.4)

# --- Riding wind ---
const WIND_START_KMH := 8.0
const WIND_VOLUME_DB := Vector2(-38, -10)
const WIND_SPRINT_GAIN_DB := 3.0
const WIND_PITCH := Vector2(0.8, 1.15)
const WIND_SMOOTHING := 6.0
const GPS_GROUND_SAMPLE_METRES := 2.0
const COMFY_TYRES_CAMERA_VERTICAL_SHARE := 0.5
const COMFY_TYRES_SHAKE_SHARE := 0.65

# --- Session 53: loading screen and small fixes ---
const BLACK_ROADS := ["Ring Road", "Gate Road", "Highway", "Bus Access"]  # car roads: other paths stop at their kerb
const HILL_MAX_HEIGHT := 0.5          # spine hills are gentle: never higher than this (Louis, 4 Nov)
const HILL_RADIUS := 10.0             # every hill is 20 m across (district_detail.gd)
const HILL_CLEARANCE := 4.0           # hills keep this far from pools, beds, the gym and the stall
const BRIDGE_EXTRA_LENGTH := 4.0      # stream bridges are this much longer than the stream is wide
const LOADING_MIN_SHOW_MS := 800      # the loading screen stays at least this long, so it never flashes
const LOADING_FADE_TIME := 0.4        # seconds to fade the loading screen out
const LOADING_TIP_TIME := 3.0         # a new tip every 3 seconds
const LOADING_TIPS := [
	"Ring the bell with B.",
	"Brake before lane corners: the lanes are narrow.",
	"Ice cream melts fast, so go straight there.",
	"Insurance is cheap. Hospitals aren't.",
	"Regulars tip more often.",
	"Hold E at the counter to pick up the order.",
	"The red track is for walkers: mind them.",
	"Sprinting uses stamina. Coast to get it back.",
]

# --- Session 56: the free asset packs ---
const KIT_COUNTER_HEIGHT := 1.05      # KitProps "counter" snap: props sit on a counter top this high

# --- Session 57: The Plaza outside ---
const PLAZA_LOOKS_PASS := true        # false: the old tall shops, upper blocks and round paving come back
const PLAZA_GROUND_FLOOR := 4.5       # metres: the shop floor (was 8)
const PLAZA_FLAT_FLOORS := 3          # floors of flats on top, like the real Plaza
const PLAZA_FLOOR_HEIGHT := 3.2       # metres per floor of flats
const PLAZA_PARAPET := 0.6            # the low wall round the roof
const PLAZA_WINDOW := Vector2(1.4, 1.6)   # flats windows, width x height
const PLAZA_WINDOW_SPACING := 3.4     # a window every 3.4 m along the front
const PLAZA_SIGN_BAND := 1.1          # height of the lit sign band over each shop
const PLAZA_GLASS_TOP := 3.2          # the shop glass goes from the ground to here
const PLAZA_AWNING_DEPTH := 1.4       # how far the striped awning sticks out
const PLAZA_DOOR_WIDTH := 2.4         # the sliding glass door (two 1.2 m panels)
const PLAZA_DOOR_OPEN_DISTANCE := 3.2 # the door slides open when you (or your bike) are this close
const PLAZA_DOOR_SPEED := 3.0         # how fast it slides (share of fully open per second)
const PLAZA_SIGN_GLOW_HOURS := Vector2(16.6, 17.4)  # signs start glowing, then are fully lit (sunset)
const PLAZA_SIGN_GLOW_ENERGY := 0.8   # how bright the lit sign bands are at night
const PLAZA_TROLLEYS := 8             # trolleys lined up outside Grand Groceries
