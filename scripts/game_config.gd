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
const SPEED_BUMP_HEIGHT := 0.12      # metres; the wheels roll up this high (same as SPEED_BUMP_SIZE.y in data/palm_grove.gd)
const SPEED_BUMP_HOP_MAX := 0.25      # metres the bike hops at full speed (crawling: just rolls over)
const SPEED_BUMP_HOP_TIME := 0.45     # seconds the extra springy bounce lasts (a big hop, then a small one)
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
		"shawarma": 0.35, "cake": 0.2, "groceries": 0.1, "farm juice": 0.5, "salad box": 0.45}  # Session 27
# Damage lost per knock, per food. Bubble tea hates speed bumps.
const DAMAGE_SPEED_BUMP := {"pizza": 3.0, "bubble tea": 14.0, "ice cream": 5.0,  # at full speed
		"shawarma": 4.0, "cake": 16.0, "groceries": 6.0, "farm juice": 10.0, "salad box": 6.0}  # cake breaks on bumps
const DAMAGE_SPEED_BUMP_SLOW_SHARE := 0.25  # at or under SPEED_BUMP_SAFE_KMH a bump costs a quarter of that
const DAMAGE_HARD_BRAKE := {"pizza": 3.0, "bubble tea": 8.0, "ice cream": 4.0,
		"shawarma": 3.0, "cake": 9.0, "groceries": 5.0, "farm juice": 7.0, "salad box": 4.0}
const DAMAGE_COLLISION := {"pizza": 15.0, "bubble tea": 25.0, "ice cream": 18.0,  # a full-speed head-on hit
		"shawarma": 15.0, "cake": 30.0, "groceries": 20.0, "farm juice": 25.0, "salad box": 18.0}
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
		"shawarma": 10.0, "cake": 16.0, "groceries": 12.0, "farm juice": 15.0, "salad box": 12.0}

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
const CRASH_SMALL_DAMAGE := 30.0      # % off the damage meter for a small crash
const HOSPITAL_BILL := 150            # Dh, big crash on the bicycle (PRD)
const REPAIR_BILL := 80               # Dh
const INSURED_CRASH_COST := 20        # Dh, all you pay for a big crash with insurance
const INSURANCE_PER_DELIVERY := 2     # Dh, taken from every delivery while insurance is on
const CRASH_FADE_TIME := 0.6          # seconds the screen takes to fade out (and back in)
const CRASH_WEEK_SHIFTS := 7          # "this week" on the clinic screen = the last 7 shifts
const CRASH_WEEK_WARNING := 3         # the clinic's crash bar is full at this many big crashes

# --- Shifts (Session 13) ---
const SHIFT_LENGTH := 300.0           # seconds of real time in one shift (5 minutes, 30 s per in-game hour)
const SHIFT_START_HOUR := 8.0         # the clock shows 08:00 when the shift starts...
const SHIFT_END_HOUR := 18.0          # ...and 18:00 when it's over (day shift only in Tier 1)
const SHIFT_WARNING_TIME := 30.0      # the clock turns orange this many seconds before the end (one in-game hour)

# --- Application and tutorial (Session 14) ---
const APPLICATION_REVIEW_TIME := 2.0  # seconds of "Reviewing..." before you're hired
const RIDER_NAME_MAX := 16            # letters allowed in your name
const TUTORIAL_LAST_TIPS_TIME := 7.0  # seconds each of the last two tips stays up

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
const CLUSTER_SIGN_INSET := 5.0       # cluster signs stand this far in from the lane's end...
const CLUSTER_SIGN_SIDE := 3.4        # ...and this far to the side of the lane's middle line
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
const SPRINT_FOV_EXTRA := 7.0         # degrees wider while sprinting
const SPRINT_FOV_SPEED := 4.0         # how quickly the camera widens and comes back
const SPEED_LINES_COUNT := 22         # streaks at the edges of the screen
const SPEED_LINES_ALPHA := 0.45       # how see-through they are at full strength (0 to 1)
# Delivered card pops (scripts/delivered_card.gd and scripts/pop_icon.gd).
const POP_FIRST_DELAY := 0.25         # seconds after the card shows before the first star pops
const POP_STAR_GAP := 0.13            # seconds between one star pop and the next
const POP_COINS := 7                  # coins that fly out of the "You earned" total
const POP_ICON_TIME := 0.8            # seconds one little icon lives
# The phone buzz when a new order comes in (scripts/phone.gd).
const PHONE_BUZZ_PIXELS := 6.0        # how far the phone shakes sideways
const PHONE_BUZZ_TIME := 0.35         # seconds the shake lasts
