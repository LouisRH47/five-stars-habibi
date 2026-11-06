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
		"shawarma": 0.35, "cake": 0.2, "groceries": 0.1, "farm juice": 0.5, "salad box": 0.45, "pad thai": 0.35, "sushi": 0.5, "tacos": 0.3, "burgers": 0.3, "coffee": 0.4, "manakish": 0.25,
		"honey jars": 0.08, "wax candles": 0.3}  # Session 27
# Session 69: honey jars keep (glass, a bit breakable), wax candles go soft in the sun.
# Damage lost per knock, per food. Bubble tea hates speed bumps.
const DAMAGE_SPEED_BUMP := {"pizza": 3.0, "bubble tea": 14.0, "ice cream": 5.0,  # at full speed
		"shawarma": 4.0, "cake": 16.0, "groceries": 6.0, "farm juice": 10.0, "salad box": 6.0, "pad thai": 7, "sushi": 9, "tacos": 14, "burgers": 5, "coffee": 14, "manakish": 4,
		"honey jars": 9, "wax candles": 4}  # cake breaks on bumps
const DAMAGE_SPEED_BUMP_SLOW_SHARE := 0.25  # at or under SPEED_BUMP_SAFE_KMH a bump costs a quarter of that
const DAMAGE_HARD_BRAKE := {"pizza": 3.0, "bubble tea": 8.0, "ice cream": 4.0,
		"shawarma": 3.0, "cake": 9.0, "groceries": 5.0, "farm juice": 7.0, "salad box": 4.0, "pad thai": 5, "sushi": 5, "tacos": 8, "burgers": 3, "coffee": 8, "manakish": 3,
		"honey jars": 6, "wax candles": 3}
const DAMAGE_COLLISION := {"pizza": 15.0, "bubble tea": 25.0, "ice cream": 18.0,  # a full-speed head-on hit
		"shawarma": 15.0, "cake": 30.0, "groceries": 20.0, "farm juice": 25.0, "salad box": 18.0, "pad thai": 18, "sushi": 22, "tacos": 25, "burgers": 15, "coffee": 25, "manakish": 15,
		"honey jars": 24, "wax candles": 12}
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
		"shawarma": 10.0, "cake": 16.0, "groceries": 12.0, "farm juice": 15.0, "salad box": 12.0, "pad thai": 12, "sushi": 14, "tacos": 15, "burgers": 10, "coffee": 15, "manakish": 10,
		"honey jars": 13, "wax candles": 8}

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
const CRASH_TIP_SCORE := 15.0  # Session 87: falls from 12 to 15 are a gentle tip-over
const CRASH_TUMBLE_HEAD_ON := 0.65
const CRASH_MATERIAL_HARDNESS := {"soft": 0.35, "wood": 0.8, "vehicle": 1.15, "rigid": 1.0}
const CRASH_FALL_DURATIONS := {"tip": 1.4, "skid": 1.8, "tumble": 2.2}
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

# Session 61: skid marks after a hard brake (scripts/skid_marks.gd).
const SKID_MARK_TIME := 0.45          # seconds of braking that leave a mark (so they stay short)
const SKID_MARK_HOLD := 5.0           # seconds a mark stays before it starts to fade
const SKID_MARK_FADE := 5.0           # seconds it takes to fade away
const SKID_MARK_ALPHA := 0.32         # how dark a fresh mark is (0 to 1): faint
const SKID_MARK_WIDTH := 0.06         # metres
const SKID_MARK_MAX := 6              # older marks go first
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
# --- Session 68: people who live here ---
const PEOPLE_ANIMATE_DISTANCE := 45.0  # m: closer people are fully animated, further hold their pose
const HOME_WALKER_EVERY := 9.0         # s between people leaving a restaurant to walk home
const HOME_WALKER_MAX := 4             # at most this many walking home at once
const HOME_WALKER_NEAR := 160.0        # m: only restaurants this close to you send people home
const HOME_WALKER_DOOR_FADE := 0.8     # m they walk in through the door before they're gone
const HOME_WALKER_HOME_CHOICES := 12   # they walk to one of this many homes nearest the restaurant (short routes: no stutter)
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

# --- Looks pass interiors (Sessions 54 and 55) ---
const QUEUE_NONE_CHANCE := 0.5        # half the time nobody is in front of you
const QUEUE_TWO_CHANCE := 0.15        # sometimes two people (otherwise one)
const QUEUE_WAIT_MIN := 2.0           # seconds you wait for them to be served
const QUEUE_WAIT_MAX := 4.0           # never longer than this
const CAMERA_INDOOR_DISTANCE := 2.9   # metres behind you inside a walk-in place (outside: CAMERA_DISTANCE)
const CAMERA_INDOOR_HEIGHT := 2.7     # metres up inside (a little higher, under the 4.5 m ceiling)
const CAMERA_INDOOR_BLEND := 3.0      # how fast the camera moves in and out (higher = faster)
const ROOM_SOUND_DB := -8.0           # each place's background sound
const ROOM_SOUND_UNIT_SIZE := 4.0     # metres at full volume
const ROOM_SOUND_MAX_DISTANCE := 13.0 # silent further away than this
const SUSHI_BELT_SPEED := 0.35        # metres per second the sushi plates travel
const ROOM_PEOPLE_DRAW_DISTANCE := 80.0  # people inside the shops are hidden further away (metres)
# --- Session 72: the school football pitch (scripts/school_pitch.gd) ---
const FLOODLIGHT_ON_HOUR := 17.25      # the floodlights come on at 17:15, as the light goes
const FLOODLIGHT_ENERGY := 6.0
const FLOODLIGHT_RANGE := 48.0         # metres: each beam only reaches its quarter of the pitch
const FLOODLIGHT_ANGLE := 32.0         # degrees: half the width of each beam
const PITCH_PLAY_END_HOUR := 16.5      # pupils play football until 16:30
const PITCH_PUPILS := 8
const PITCH_BALL_SPEED := 5.0          # m/s
const PITCH_PUPIL_SPEED := 3.0         # m/s

# --- Session 73: more life at the stables (scripts/stable_life.gd) ---
const ARENA_RIDERS_OUT := 2            # riders on the jumping course at once (the rest wait their turn)
const GROOM_WALK_SPEED := 1.1          # m/s, a groom leading a horse round the yard

# --- World polish pass Sessions 64 to 66 (bus stop, signs, Majlis Gardens) ---
const BUS_STOP_START_PEOPLE := 4      # people waiting at the bus station when the game starts
const BUS_STOP_MAX_PEOPLE := 5        # never more than this many waiting
const BUS_STOP_SPAWN_EVERY := 10.0    # seconds between new people arriving at the stop
const BUS_STOP_WALK_SPEED := 1.4      # m/s walking to their spot and to the bus door
const BUS_STOP_BOARD_GAP := 0.8       # seconds between one person and the next getting on

# --- Looks pass Session 56: the gym and the C Institute ---
const GYM_PEDAL_TURNS := 1.2          # exercise bike pedal turns per second
const GYM_ROW_STROKES := 0.45         # rowing strokes per second
const GYM_ROW_SLIDE := 0.45           # metres the rower slides back on each stroke
const GYM_SQUATS := 0.3               # squats per second
const GYM_SQUAT_DEPTH := 0.32         # metres the lifter goes down
const TALK_SCREEN_TIMES := [12.0, 16.0]  # the talk screen: "Welcome" until 12:00, "Talk today" until 16:00, then the talk

# --- Looks pass Session 58: Plaza, streets and spine ---
const LIGHTS_ON_HOUR := 17.25         # street lamps and string lights are half on at this time (sunset)...
const LIGHTS_FADE_HOURS := 0.5        # ...fading in over this long
const LIGHTS_BULB_ENERGY := 4.0       # how bright the string light bulbs glow
const LIGHTS_LAMP_ENERGY := 3.0       # how bright the street lamp heads glow
const STREET_LAMP_HEIGHT := 5.0       # metres
const STRING_LIGHT_SAG := 0.45        # metres the string lights hang down between poles
const PLAZA_STROLLERS := 6            # extra people strolling round the Plaza
const SPINE_FLOWER_PATCHES := 140
const SPINE_ROCKS := 160
const SPINE_TREES := 45

# --- Fixes after the careless play-test (5 Nov) ---
const KERB_IMPACT_HARDNESS := 0.35     # the spine kerbs count as a soft bump (rigid walls are 1.0)

# --- Fix pass Session 75: ride freely, jump on foot, buggies on roads ---
const KERB_SPEED_KEEP := 0.9          # share of speed kept riding over a kerb (a little lost)
const KERB_SHAKE := 0.2               # camera shake riding over a kerb at full speed (0 to 1)
const KERB_BUMP_COOLDOWN := 0.25      # seconds before the next kerb counts (two kerbs close together)
const BUGGY_JUNCTION_SPEED_SHARE := 0.45  # buggies slow to this share of their speed at junctions
const BUGGY_SLOW_RAMP := 5.0          # metres over which a buggy slows down before a junction


# --- Fix pass Session 76: kerbs that join up and curved corners ---
const KERB_HEIGHT := 0.12             # metres a kerb stands above the road
const KERB_WIDTH := 0.25              # metres across the top of a kerb


# --- Fix pass Session 77: square Plaza floor and the Dune Drip buggy park ---
const PLAZA_PAVER_TILE := 6.0             # metres of floor one square_concrete_pavers photo covers (squares about 1 m)
const PLAZA_PAVER_TINT := Color(1.3, 1.36, 1.38)  # lightens the brown photo to a warm sandy stone
const PARKED_BUGGY_COLOUR := Color(0.92, 0.91, 0.84)  # the buggies parked behind Dune Drip


# --- Fix pass Session 78: bike shop and Dune Drip buildings ---
# The outside of the two shops (scripts/shop_exterior.gd) and the dressed walls round the
# Plaza (scripts/plaza_walls.gd). All in metres.
const SHOP_ARCADE_DEPTH := 3.0      # how far the shaded arcade sticks out in front of a shop
const SHOP_ARCADE_TOP := 4.0        # top of the arcade roof (it stays under the shop sign)
const SHOP_ARCH_SPRING := 2.6       # where the arches start to curve, on top of the columns
const SHOP_ARCH_TOP := 3.3          # the top of each arch (under the arcade beam)
const SHOP_COLUMN_XS := [2.9, 6.4, 9.85]  # columns each side of the door, from the middle
const SHOP_PARAPET := 1.0           # the low wall round the edge of the roof
const SHOP_CROWN_STEPS := [0.8, 1.6]  # how much higher each step over the sign goes
const SHOP_UPPER_HEIGHT := 3.2      # the raised back part of the roof (the step up)
const SHOP_TOWER_HEIGHT := 3.6      # the wind tower on top of that


# --- Fix pass Session 79: car parks and the mosque car park ---
# (Bay sizes and where each car park goes are map data: tools/build_wahat_data.py.)
const CAR_PARK_ROOF_HEIGHT := 3.1         # metres from the ground to the solar panels
const CAR_PARK_ROOF_TILT := 0.07          # how much the panels lean (radians, about 4 degrees)
const CAR_PARK_POST_EVERY := 3            # one roof post every 3 bays
const CAR_PARK_LINE_WIDTH := 0.12         # the painted bay lines (metres)
const PARKED_CARS_BATCHED := true         # draw parked cars with ParkedCarBatch (much faster)
const PARKED_CAR_BATCH_CELL := 96.0       # metres: cars in one square of this size share a draw
const PARKED_CAR_DRAW_DISTANCE := 280.0   # metres: parked cars further away aren't drawn


# --- Fix pass Session 80: C Institute front, seats and the basketball court ---
# (Session 80 numbers go here)
# The 5-a-side pitch in front of the C Institute (scripts/institute_pitch.gd)
const INSTITUTE_PITCH_PLAYERS := 10       # 5 a side, the two goalkeepers included
const INSTITUTE_PITCH_PLAY_END_HOUR := 17.0  # people play football until 17:00
const INSTITUTE_PITCH_BALL_SPEED := 4.5   # m/s
const INSTITUTE_PITCH_RUN_SPEED := 2.8    # m/s
# The basketball court in the spine (scripts/basketball_court.gd)
const COURT_PLAYERS := 3                  # two play one-on-one, one practises shots
const COURT_PLAY_END_HOUR := 17.5         # players go home at 17:30
const COURT_RUN_SPEED := 2.2              # m/s
const COURT_SHOT_EVERY := 4.0             # seconds of dribbling before a shot
const COURT_SHOT_TIME := 1.1              # seconds the ball flies to the hoop
const COURT_FENCE_HEIGHT := 3.0           # metres


# --- Fix pass Session 81: gym, stream and pools ---
# (Session 81 numbers go here)
# Pools (scripts/pool_deck.gd): heights in metres above the ground.
const POOL_WATER_Y := 0.08                # the water's surface (swimmers float here)
const POOL_DECK_Y := 0.16                 # the tiled deck round the pool
const POOL_COPING_Y := 0.2                # the stone edge (coping) round the water
const POOL_TILE_SIZE := 0.6               # metres, one deck tile
const POOL_FLOOR_DEPTH := 1.2             # how deep the pool floor looks through the water
# Water colours and ripples (scripts/water_look.gd, assets/shaders/water.gdshader)
const POOL_WATER_COLOUR := Color(0.24, 0.7, 0.86)
const STREAM_WATER_COLOUR := Color(0.3, 0.6, 0.85)
const POND_WATER_COLOUR := Color(0.22, 0.52, 0.62)
const WATER_WAVE_TILT := 0.5              # how much the ripples catch the sun (0 = none)
# Ponds at the stream's ends (scripts/stream_pond.gd)
const POND_STONE_GAP := 0.55              # metres between the stones round the edge


# --- Fix pass Session 82: textures ---
# (The ground pictures' sizes and tints are in one table: SURFACES in scripts/surface_textures.gd.)
const BIN_GREY := Color(0.5, 0.52, 0.53)          # street, bus stop and cluster bins (were green)


# --- Fix pass Session 83: people who look alive ---
# (Session 80 seats) the sitting pose keeps feet on top of the floor or step below them
const SIT_FEET_CLEARANCE := 0.03      # m the soles stay above the floor (paving is a little raised)
const SIT_ANKLE_HEIGHT := 0.08        # m from the sole up to the ankle
# Faces: simple eyes and a smile (scripts/face.gd), measured on a grown-up's head
const FACE_SHOW_DISTANCE := 25.0      # m, faces are only drawn this close
const FACE_FRONT := 0.135             # m from the middle of the head to the face
const FACE_EYE_HEIGHT := 0.014        # m above the middle of the head
const FACE_EYE_GAP := 0.1             # m between the two eyes
const FACE_MOUTH_HEIGHT := -0.075     # m, the smile below the middle of the head
# Looking alive (scripts/alive_pose.gd), only for people near the rider
const ALIVE_DISTANCE := 30.0          # m, people closer than this breathe, look round and talk
const ALIVE_BREATH_SECONDS := 4.0     # s for one breath in and out
const ALIVE_BREATH_DEG := 2.0         # degrees the chest lifts
const ALIVE_LOOK_EVERY := Vector2(2.0, 6.0)  # s between looking somewhere new
const ALIVE_LOOK_DEG := 50.0          # degrees the head turns at most
const ALIVE_LOOK_SPEED := 60.0        # degrees per second the head turns
const ALIVE_SWAY_SECONDS := 7.0       # s to shift the weight over and back
const ALIVE_SWAY := 0.035             # m the hips move to the side
const ALIVE_TALK_TURN_SECONDS := 4.0  # s one person in a pair talks before the other does


# --- Fix pass Session 75 (people): jumping on foot ---
const JUMP_HEIGHT := 0.6              # m, how high Space lifts the rider on foot
const JUMP_COOLDOWN := 0.6            # s before you can jump again (counted from take-off)
const JUMP_LAND_TIME := 0.3           # s the knees bend when you land
const JUMP_LAND_SQUAT := 0.16         # m the hips drop in that landing bend
const JUMP_TUCK := 0.22               # m the feet lift towards the body in the air

# --- Fix pass Session 81 (people): swimmers and the lifeguard ---
const SWIM_WATER_Y := 0.12            # m, the pools' water surface if a pool doesn't say (meta "water_y")
const SWIM_EDGE_ABOVE_WATER := 0.08   # m, the pool edge above the water, where resting swimmers fold their arms
const SWIM_SPEED := 0.8               # m/s, a lap swimmer (each one a little faster or slower)
const SWIM_STROKE_RATE := 0.6         # whole arm strokes per second
const SWIM_BODY_TILT_DEG := 16.0      # degrees the swimmer's head end is higher than the feet
const SWIM_NECK_ABOVE_WATER := 0.07   # m, the neck sits just above the water (head well above)
const SWIM_CHIN_UP_DEG := 80.0        # degrees the head lifts to look ahead out of the water
const SWIM_TURN_TIME := 1.8           # s to turn round at the end of the pool
const SWIM_TURN_GAP := 1.6            # m before the wall where they start turning
const SWIM_REST_GAP := 0.35           # m from the edge for people resting at the side
const SWIM_SHOULDERS_ABOVE_WATER := 0.12  # m, people resting at the side
const SWIM_COMMUNITY_LAPS := 4        # lap swimmers in the community pool
const SWIM_COMMUNITY_RESTING := 2     # people resting at its edge
const SWIM_KIDS_AREA := 8.0           # m at the community pool's east end kept for the kids' splash area
const SWIM_LAP_POOL_LAPS := 3         # lap swimmers in the gym's lap pool (one per lane)
const SWIM_SCHOOL_LAPS := 2           # lap swimmers in each school pool
const SWIM_SCHOOL_RESTING := 1        # resting at the edge of each school pool
const LIFEGUARD_SEAT_HEIGHT := 1.6    # m, the seat of the tall lifeguard chair
const LIFEGUARD_FOOTREST_HEIGHT := 1.12  # m, where his feet rest (and where he stands up)
const LIFEGUARD_LOOK_DEG := 55.0      # degrees he looks left and right
const LIFEGUARD_STAND_EVERY := Vector2(12.0, 22.0)  # s between standing up to whistle
const LIFEGUARD_STAND_TIME := 3.0     # s standing with the whistle
const LIFEGUARD_WHISTLE_HEARD := 45.0 # m, how far away you hear the whistle

# --- Steam pass (Session 85): desktop builds and the Steam Deck ---
const SMALL_SCREEN_WIDTH := 1600       # px: windows narrower than this (Steam Deck 1280x800) get bigger menus and HUD
const SMALL_SCREEN_UI_SCALE := 1.15    # how much bigger (13 px text becomes 10 px on the Deck, not 9; more makes the phone cover the speed panel)

# --- Life pass Session 86: the loading screen ---
const LOADING_MIN_SECONDS := 1.0       # s the loading screen stays up at least (even if the world builds faster)
const LOADING_SHIFT_SECONDS := 1.2     # s the short loading screen shows at the start of each new shift
const LOADING_TIP_SECONDS := 3.0       # s each tip shows before the next one
const LOADING_FADE_SECONDS := 0.4      # s the screen takes to fade out at the end
const LOADING_FRAME_BUDGET_MS := 25    # ms of building per frame before the screen gets to draw again
const LOADING_WARM_FRAMES := 3         # frames the finished world draws behind the screen (warms the shaders)

# --- Life pass Session 87: three crash levels ---
# The impact "score" is the speed into the thing in km/h (a scrape counts a fifth of its speed),
# times how hard the thing is (CRASH_MATERIAL_HARDNESS: a car 1.15, a wall 1, a palm 0.8).
const CRASH_BUMP_MIN_KMH := 6.0        # an impact score under this: just a nudge or a scrape (no bill, no message)
const CRASH_BUMP_KMH := 12.0           # under this (or anything soft, at any speed): a bump, you stay on
const CRASH_FALL_KMH := 22.0           # 12 to 22: you fall off; over 22 into something hard: big crash
const CRASH_BUMP_BILL := 10            # Dh, a bump (small repair)
const CRASH_FALL_BILL := 30            # Dh, a fall (bike repair)
const CRASH_BUMP_DAMAGE := 8.0         # % off the food's damage meter for a bump (a small rating hit)
const CRASH_BUMP_COOLDOWN := 3.0       # s before another bump can count (pushing against a wall; was 1.5)
const CRASH_WOBBLE_TIME := 0.7         # s the bike wobbles after a bump
const CRASH_WOBBLE_DEG := 14.0         # degrees the bike leans side to side in the wobble
const CRASH_TOAST_SECONDS := 2.2       # s the "Bump! 9 km/h" message stays up

# --- Life pass Session 88: three delivery companies (data/companies.gd) ---
const COMPANY_SNACKAROO_TIP_BONUS := 0.10    # Snackaroo: tips 10% bigger (rounded up)
const COMPANY_ZOOMAROO_WAIT_BONUS := 0.20    # Zoomaroo: customers wait 20% longer (the time target)
const COMPANY_DELIVEROOZ_DAMAGE_CUT := 0.25  # Deliverooz: the bigger box, 25% less food damage
const COMPANY_SWITCH_PRICE := 50             # Dh to switch company in the phone (keeps stars and level)
const CRASH_FALL_MAX_TIME := 4.0       # s: a fall always ends by now, even if something still wobbles
const CRASH_THROW_SHARE := 0.85        # share of the impact speed the rider is thrown with
const CRASH_THROW_LIFT := 1.2          # m/s upwards when thrown (x1.5 going over the handlebars)
const CRASH_THROW_SPIN := 4.0          # rad/s forward roll going over the handlebars
const CRASH_BIKE_SLIDE_SHARE := 0.6    # share of the impact speed the bike slides on with
const CRASH_GET_UP_TIME := 0.5         # s to blend from lying on the ground back onto the bike
const CRASH_FALL_HOSPITAL := 20        # Dh of the fall bill that's the clinic (the rest, 10 Dh, is the bike repair)

# --- Life pass Session 89 (jobs and messages): the phone's Jobs and Messages apps ---
const ORDER_FAR_METRES := 360.0        # m, shop door to drop-off door: more than this is a "far" order (about 1 in 3)
const ORDER_FILTER_TRIES := 5          # times a new order is made again when its kind is switched off in Jobs
const CHAT_MAX_LINES := 30             # each chat keeps only its last 30 lines
const CHAT_BOSS_ID := "boss"           # the chat with your company's boss
const CHAT_NEWS_ID := "plaza_news"     # the Plaza news chat (Session 94 posts the flea market there)

# --- Life pass Session 89: the big phone on P (scripts/phone_app.gd) ---
const PHONE_APP_SIZE := Vector2(420, 860)  # px, the big phone at 1920x1080 (it shrinks on short screens)
const PHONE_APP_MARGIN := 70.0             # px kept free above and below the phone (the keys hint sits there)
const PHONE_APP_SHADE := 0.55              # how dark the see-through shade behind the phone is (0 to 1)
const CAREER_TIER2_STARS := 4.0            # Profile app: stars Tier 2 (Dune Express) needs (PRD career ladder)
const CAREER_TIER2_DELIVERIES := 20        # Profile app: deliveries Tier 2 needs
const MOTORBIKE_TEST_PRICE := 200          # Dh, the motorbike test's first try (PRD; the test isn't built yet)

# --- Session 90 (restaurants): the homes above the Plaza restaurants, and the waiters ---
const PLAZA_HOME_BAY := 6.2             # m, how wide one flat is along the row
const PLAZA_HOME_STOREY := 3.0          # m per floor of the homes (two floors, 8 m to 14 m up)
const PLAZA_HOME_BASE_TOP := 8.42       # m, top of the thick band that sits on the shop fronts
const PLAZA_HOME_BASE_STICK := 0.36     # m the bottom band stands out from the wall (covers the join)
const PLAZA_HOME_CORNICE := 13.72       # m, bottom of the cornice under the roof edge
const PLAZA_HOME_BALCONY_DEPTH := 1.2   # m a balcony sticks out
const PLAZA_HOME_BALCONY_WIDTH := 2.8   # m, how wide a balcony is
const WAITER_WALK_SPEED := 1.2          # m/s, a waiter walking between the tables and the door
const WAITER_WIPE_SECONDS := 4.5        # s spent wiping a table
const WAITER_CHAT_SECONDS := 5.0        # s chatting to a diner at a table
const WAITER_INSIDE_SECONDS := 2.5      # s inside the restaurant (fetching plates)
const WAITER_SERVE_SECONDS := 2.0       # s putting plates down at a table
const WAITER_PAUSE_SECONDS := 1.0       # s a waiter stops at the door before going on (never longer)
const WAITER_TRAY_HEIGHT := 1.05        # m, how high a waiter holds the tray

# --- Session 90 (layout): Plaza paving, buggy park, gym, Majlis crossing ---
const ZEBRA_STRIPE := 0.5              # m, how wide one white bar of a zebra crossing is (gaps are the same)
const GYM_DOOR_PLANTER := 2.1          # m from a gym door's middle to the planter on each side of it
const GYM_SIDE_DOOR_Z := 3.3           # m, where the gym's second door (on the lap pool side) is, front to back

# --- Session 92 (people): strollers, chatting pairs, sunbeds, site workers, the player's kit ---
const STROLLER_HANDLE_REACH := 0.36    # m in front of the parent's feet that the handle is
const STROLLER_HAND_GAP := 0.36        # m between the two hands on the handle
const STROLLER_LEAN_DEG := 6.0         # degrees a parent leans forward to push

# --- Session 91: the C Institute's second floor, lift, new outside, and the big pond ---
const LIFT_RIDE_SECONDS := 3.5         # s the lift car takes between the two floors
const LIFT_DOOR_SECONDS := 0.7         # s the lift doors take to open or close
const LIFT_CALL_DISTANCE := 1.4        # m from the call spot in front of a lift door where E works
const LIFT_STEP_OUT := 0.9             # m in front of the lift door where you stand (and come out)
const TYPING_AWAKE_DISTANCE := 45.0    # m, further away the office people don't move their hands
const TYPING_TAPS_PER_SECOND := 5.0    # how fast the fingers tap on the laptop
const TYPING_TAP_HEIGHT := 0.03        # m the hands lift when typing
const TYPING_BURST_SECONDS := 4.0      # s per burst of typing (the last quarter is a pause to read)
const INSTITUTE_SHADE_DEPTH := 3.0     # m the flat roof and its sun shade reach out over the glass front
const INSTITUTE_FIN_DEPTH := 0.9       # m the sun fins stand out from the south end wall
const INSTITUTE_FIN_GAP := 1.6         # m between the sun fins
const INSTITUTE_SIGN_GLOW := 1.6       # how bright the lit signs' light boxes glow
const POND_DECK_TOP := 0.22            # m, the height of the pond deck's planks
const POND_DECK_STEPPING_STONES := 3   # flat stones from the deck back towards the spine road
const POND_DUCK_SPEED := 0.3           # m/s, ducks paddling round the pond
const POND_DUCKS_AWAKE_DISTANCE := 70.0  # m, further away the pond ducks stay still
const TALK_GAP := 1.1                  # m between two people chatting (face to face)
const TALK_FEET_APART := 0.2           # m between the feet of someone standing at ease
const TALK_NOD_DEG := 7.0              # degrees a listener nods
const SHOE_WIDTH := 0.135              # m, how wide a shoe is (a grown-up's)
const SHOE_HEIGHT := 0.125             # m, how tall the back of a shoe is
const LOUNGE_HIP_DEG := 40.0           # degrees the hips bend lying on a sun lounger (its back is 40 up)
const LOUNGE_BOOK_UP := 0.1            # m above the chest that a sunbather holds a book
const LOUNGE_BOOK_OUT := 0.34          # m in front of the chest that a sunbather holds a book
const SUNBATHERS := 4                  # people lying on loungers at the community pool
const SUNBATHER_HIPS := Vector3(0.3, 0.47, 0.0)  # m from a lounger's middle to a sunbather's hips (at the bend)
const SITE_WORKERS := 3                # workers at each building site (and a foreman by the crane)
const WORKER_JOB_SECONDS := 14.0       # s before the site workers swap jobs
const WORKER_WALK_SPEED := 1.1         # m/s, a worker walking to a job (or carrying a block)
const WORKER_PICK_SECONDS := 1.6       # s to bend down and pick a block up (or put it down)
const WORKER_BLOCK_HEIGHT := 0.92      # m, how high a worker carries a block
const WORKER_HAMMER_RATE := 1.6        # hammer blows a second
const WORKER_SHOVEL_SECONDS := 2.6     # s for one shovelful into the mixer
const COURT_PLAYER_GAP := 0.8          # m, the closest two players on a court or pitch ever get
const PITCH_SECOND_CHASER_GAP := 1.6   # m from the ball the second-nearest football player waits
const RIDER_CHEST_LOGO := Vector3(-0.08, -0.03, -0.14)  # m from the chest bone to the logo on the shirt (left chest)
const RIDER_BACK_LOGO := Vector3(0.0, -0.05, 0.13)      # m from the chest bone to the name across the back
const PERSON_DRAW_BOX := AABB(Vector3(-1.2, -0.6, -1.2), Vector3(2.4, 2.9, 2.4))  # m round a person (any pose) that's on screen if they are
