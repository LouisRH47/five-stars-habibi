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
const FRESHNESS_DRAIN := {"pizza": 0.25, "bubble tea": 0.4, "ice cream": 0.55}  # Session 17: was 0.35/0.6/1.0
# Damage lost per knock, per food. Bubble tea hates speed bumps.
const DAMAGE_SPEED_BUMP := {"pizza": 3.0, "bubble tea": 14.0, "ice cream": 5.0}  # at full speed
const DAMAGE_SPEED_BUMP_SLOW_SHARE := 0.25  # at or under SPEED_BUMP_SAFE_KMH a bump costs a quarter of that
const DAMAGE_HARD_BRAKE := {"pizza": 3.0, "bubble tea": 8.0, "ice cream": 4.0}
const DAMAGE_COLLISION := {"pizza": 15.0, "bubble tea": 25.0, "ice cream": 18.0}  # a full-speed head-on hit
# Hard braking: braking (S or Space) while going faster than this counts once per press.
const HARD_BRAKE_MIN_KMH := 22.0       # Session 17: was 18, then normal braking counted too

# --- Moving obstacles (Session 9) ---
const CAT_WALK_SPEED := 0.8           # m/s, a slow stroll
const CAT_RUN_SPEED := 4.0            # m/s, running off after you bump it
const CAT_PAUSE_MIN := 1.5            # seconds a cat sits still between strolls
const CAT_PAUSE_MAX := 4.0
const SCOOTER_SPEED := 2.5            # m/s, about 9 km/h
const SCOOTER_TURN_PAUSE := 1.5       # seconds a kid waits at each end before turning round
const CRITTER_SCARED_TIME := 1.5      # seconds a bumped cat runs / a bumped kid stops
# Extra food damage when you bump a cat or a kid (on top of the crash itself).
const DAMAGE_CRITTER := {"pizza": 10.0, "bubble tea": 15.0, "ice cream": 12.0}

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

# --- Shifts (Session 13) ---
const SHIFT_LENGTH := 600.0           # seconds of real time in one shift (10 minutes, PRD)
const SHIFT_START_HOUR := 8.0         # the clock shows 08:00 when the shift starts...
const SHIFT_END_HOUR := 18.0          # ...and 18:00 when it's over (day shift only in Tier 1)
const SHIFT_WARNING_TIME := 60.0      # the clock turns orange this many seconds before the end

# --- Application and tutorial (Session 14) ---
const APPLICATION_REVIEW_TIME := 2.0  # seconds of "Reviewing..." before you're hired
const RIDER_NAME_MAX := 16            # letters allowed in your name
const TUTORIAL_LAST_TIPS_TIME := 7.0  # seconds each of the last two tips stays up
