# Review: the walk-in insides (overnight check of Sessions 58 to 61)

Done by Claude on the night of 4 to 5 November 2026, on the `looks-review-interiors` branch
(from `looks-build` with Sessions 52 to 59 merged, then `looks-build` 1aa5e5b merged again at
the end: the outdoor review and Session 66).

What I looked at: the 10 Plaza restaurants and Grand Groceries, Pedal Point Bikes, Dune Drip,
the gym, the C Institute lobby and the stable office. The clinic room didn't change in the
Looks pass, so I left it.

How I checked:
- **Renders** with the real renderer, every room from the door, from a front corner and from
  behind the counter looking out, at 10 AM and at 5 PM (84 pictures), then again after the
  fixes. Pictures are in `/home/claude/out/review_interiors_*.png`.
- **What the player sees**: the real follow camera with the rider on foot, 2 m inside the door
  and at the pickup spot, in 8 rooms.
- **Walking it**: a small script walks the on-foot rider from outside into every restaurant to
  the pickup spot (going round chairs and people, not through them), holds E and picks up; and
  into both shops, holds E and the shop screen opens. All 12 pass. It also watches the camera on
  the way: it never left the room or sat inside a chair or a person.
- **The play-test bot's own walking**: the bot's map grid and steering, into all 10 restaurants
  from 3 parking spots, with and without the queue (54 walks), and 16 walks out of Burgerology
  from the spot where it got stuck. All fine (see "The Burgerology freeze" below).

## What was wrong, and what I did

Every fix can be switched off in `scripts/game_config.gd`, section "Review: interiors":
`INTERIOR_REVIEW_FIXES`, `MENU_TEXT_FIT` and `INDOOR_CAMERA_ON` (false = exactly as before).

| # | Problem (picture) | Fixed? |
| --- | --- | --- |
| 1 | **Menu boards too small to read from the door.** Every board used text size 19 (letters about 6 cm high on a 4 m board, 9 m away). (`review_interiors_menu_before.png`) | Yes. Each board now picks the biggest text that fits (up to 34), in 1 or 2 columns. The shawarma picture menu went from 30/34 to 38/42. (`review_interiors_menu_after.png`) |
| 2 | **Names ran into their prices** on four boards: "Zaatar manakish8 Dh" (Bread & Zaatar), "Mango sticky rice" (Thai), "California roll" (Sushi), "Smash double" (Burgerology). | Yes, same fix (the bakery board now uses one column). |
| 3 | **Brain Freeze: you couldn't read the back row's flavour tags**, they were hidden behind the front row's gelato. (`review_interiors_gelato_before.png`) | Yes. The back row's tags stand on little picks in their tubs, above the front row and under the glass top. (`review_interiors_gelato_after.png`) |
| 4 | **Brain Freeze: the plant by the window stood inside the last window stool and its diner.** | Yes, moved 0.6 m. |
| 5 | **Flickering stripes on the side walls.** Shops come in pairs 12 m apart, and each room built a 25 cm side wall centred on its edge, so the two rooms' walls filled exactly the same space and fought (pale stripes on Mario Bonito's and Burgerology's shared wall, and the same between Thai/Sushi, Pizza/Gelato, Spill the Brew/Shawarma, Bread & Zaatar/Pedal Point). (`review_interiors_wall_stripes_before.png`) | Yes. A wall shared with the shop next door is now only the inner half, up to the edge (the side facing a passage is unchanged). (`review_interiors_wall_stripes_after.png`) |
| 6 | **Grand Groceries: the "Fruit and veg" sign floated in the air** (no cords). (`review_interiors_market_before.png`) | Yes, it hangs on two cords. (`review_interiors_market_after.png`) |
| 7 | **Grand Groceries: the shelf stacker stood in the middle of aisle 1**, where a shopper pushes her trolley right through him. | Yes, he stands at the shelf he's filling. |
| 8 | **Hanging sign cords stopped 5 to 6 cm above the signs** (every "Pick up" sign and the aisle signs). | Yes, they reach the sign's top now. |
| 9 | **Bread & Zaatar: the peel was the wrong way round.** Its handle went through the baker into the oven, the bread end hung in the air behind him. | Yes. Bread end in the oven's mouth, a shorter handle back past his side, clear of the counter. |
| 10 | **Tok Tok Thai: the "Photo spot!" sign hovered over the tuk-tuk roof.** (`review_interiors_thai_before.png`) | Yes, it stands on the roof. (`review_interiors_thai_after.png`) |
| 11 | **Tok Tok Thai: a lamp shade hung inside a red lantern** (0.45 m apart). | Yes, the lamp moved over its table. |
| 12 | **Sushi You: the belt ran over the chefs' gap with nothing under it.** | Yes, a lift-up flap carries the top over the gap (open underneath), like real conveyor bars. |
| 13 | **Stable office: sky showed through between the side walls and the roof** (the gable was two stepped boards). (`review_interiors_stable_before.png`) | Yes, real triangle gables with the roof's slope. (`review_interiors_stable_after.png`) |
| 14 | **C Institute: the name under the big C was hidden behind the desk** (you saw only the top of the Arabic from the door). (`review_interiors_institute_before.png`) | Yes, the C is a little smaller and higher and the name sits above the desk. (`review_interiors_institute_after.png`) |
| 15 | **Gym: "Smoothies · عصائر" floated in the air** over the cooler. | Yes, it's on a teal board standing on the cooler. |
| 16 | **The camera indoors.** The PRD (Interiors) and the Session 58 plan want the camera "closer and a little higher indoors"; it wasn't built. At the pizza pickup spot the diners hid most of the rider. (`review_interiors_camera_before.png`) | Yes. Inside a restaurant or shop the follow camera eases to 3.0 m behind and 2.7 m up (outside: 4.5 and 2.2), and back when you leave. (`review_interiors_camera_after.png`) |

Things I checked that were fine: nothing poking through walls, ceilings or glass; machines on
the floor or a counter (the espresso machine sits on the counter); people sit on their chairs
and stools, chairs face their tables, the window stools face the glass; the doors are clear and
the pickup spots can be reached with a 1.2 m way; the till screens face the staff; Arabic is
joined up and right to left on every sign I looked at; the 5 PM light comes through the glass
warm without washing the room out. Each room looks like its kind of real place (the pizza dome
oven, the gelato case by the door, the coffee bar, the spits in the shawarma window, the bakery
oven and bread rack, the supermarket aisles and checkouts, the woks and tuk-tuk, the sushi belt,
the taco counter, the burger grill and neon, the bike workshop, the streetwear shop).

## The Burgerology freeze (from the outdoor review)

In two careless bot runs the rider stood still at (-177.95, -101.02), 2 m in from Burgerology's
glass and right beside a 4-seat table, "going to the bike", for the rest of the shift.

- That spot is free: the walker can move from it every way.
- I ran the bot's own walking (its grid and steering) 54 times into the restaurants and 16 times
  out of Burgerology starting exactly there, facing 8 ways, with and without the doorway step.
  It always walked out and got back on the bike in 5 to 8 seconds.
- Nothing in the room moves into that spot: chairs and diners have no collision, the queue
  people stand at the till, nobody walks there.
- The logs show the shift clock kept going (events kept starting), so the game wasn't paused,
  and there was still an order (the shift waits for it).

So I couldn't find a cause in the room. What I added to `tests/playtest_bot.gd`: if the walker
hasn't moved 5 cm in 8 seconds it prints one "WALK FROZEN" line with everything (height, on the
floor, velocity, paused, walker active and processing, stage, which way it's walking, the route,
which of the 4 ways a 30 cm move is blocked, which keys are held, the queue). After 30 seconds it
presses R like a player (back on the bike at the start), so the shift carries on, and the
summary says how many times that happened. The next run that hits it will say why.

## New checks

`tests/interior_test.gd`:
- every menu board's text is big enough (26 or more) and no name runs into its price; the
  picture menu's names are 32 or more
- no plant, bin or cactus pot stands in a seat
- staff don't stand inside each other or in a seat, and the shoppers' trolley routes keep 0.6 m
  from every staff member
- Brain Freeze: every back-row flavour tag can be read from the door (over the front row)
- no two shops side by side build their walls in the same space
- Bread & Zaatar: the peel goes bread-first into the oven and the handle stays behind the counter
- the follow camera comes closer indoors (3.0 m) and goes back outside (4.5 m)

I checked the first four catch the old problems: with the fixes switched off they fail (gelato
plant, Thai/Sushi/Burgerology/bakery boards, the stacker).

`tests/venues_test.gd`: the institute's name shows over the desk from the door and under the C;
the stable office's gables are full triangles.

## Not fixed, and why

- **The rooms' ceiling is really the flats' cornice band.** In `scripts/plaza_rows.gd` the
  cornice band over the shops covers the whole row (not just a ledge round the edge), so inside
  every shop the ceiling you see is its underside at 4.37 m (tan), 13 cm below the room's own
  white ceiling at 4.5 m. It looks fine and doesn't flicker, so I left the outdoor code alone.
  If you want white ceilings, make the band a ring round the edge.
- "Hold E to shop" still floats over the shop counters (a game hint, kept on purpose in S59).
- The pizza peel rests in the air in front of the pizza maker (there's no holding pose); from
  the dining room it looks like he holds it. The oven is in a corner right behind the counter, so
  a straight peel can't go in and out without crossing the counter.
- Diners sit still and the mannequins are frozen people (known since S58/S59).
- Chairs, stools and diners have no collision, so you can walk through them if you steer into
  them. Making them solid would block the aisles in these small rooms.
- Very faint shadow lines on the institute's stair wall at 5 PM (the steps' shadows); fine.

## For Louis to decide

1. **Camera indoors**: is 3 m behind and 2.7 m up nice, or would you like it even closer?
   (`INDOOR_CAMERA_DISTANCE` / `INDOOR_CAMERA_HEIGHT` in game_config.gd.)
2. **White ceilings** in the shops instead of the tan band (see above)?
3. **Bread & Zaatar's oven** looks small and pale from the door. Make it bigger and darker
   stone, or is it fine?
4. **C Institute floor**: very bright white in the sun. Keep, or a warmer, darker stone?
5. **Solid chairs?** Right now you can walk through chairs and seated people.

## Louis's check

1. Open the project in Godot and press **F5**. Start a shift.
2. Take a **Bread & Zaatar** or **Tok Tok Thai** order, ride to the Plaza, get off (**F**) and
   walk in. Read the menu board from the door: the prices should be easy to read. Watch the
   camera come in closer as you walk through the door, and go back out when you leave.
3. In **Brain Freeze**, stand at the door: you can read all 12 flavour tags, both rows.
4. In **Mario Bonito** or **Burgerology**, look at the side walls: no pale flickering stripes.
5. In **Grand Groceries**, the "Fruit and veg" sign hangs on two cords.
6. Ride to the **stables** and look into the office: no sky between the walls and the roof.
7. In the **C Institute**, from the door you can read "C Institute" under the big C.
