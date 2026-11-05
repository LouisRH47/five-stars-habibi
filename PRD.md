# Five Stars Habibi: PRD (Game Design)

*Working name. Subtitle: Rider to Driver.*

This is the product requirements document: **what** the game is and how it works. It's the one true copy of the design. If something changes, update this file first (and add a line to the Decisions log at the bottom), then build it. The older copy on claude.ai is out of date.

**Mockup:** [Five Stars Habibi Mockup](https://claude.ai/artifact/8vzJizBsB69zJsuSEuWmS4) shows the gameplay HUD, the rider application, a finished delivery and the big crash screen. Use it as the look to aim for: sunny desert colours (sand, teal, orange), rounded fonts, low-poly 3D.

## Overview

Five Stars Habibi is a job-sim driving game set in Al Sarab, a made-up desert city with Dubai vibes. You start delivering food on a bicycle in one small community and climb a career ladder all the way to a luxury chauffeur service.

- **Built with:** Claude Code, in Godot 4 (GDScript). 3D, with the camera behind the rider. A Roblox port might come later.
- **First playable version:** Tier 1 only (bicycle deliveries around one villa community).
- **Big rule:** plan the whole ladder, but build one tier at a time. Don't start Tier 2 until Tier 1 is fun.
- **Reading this file:** the sections "The career ladder", "The motorbike test" and "Taxi tiers" are the long-term vision. They are marked **NOT NOW**. Session prompts only build what's in the Tier 1 sections.

**Decided so far**

- One city that opens up district by district. Old areas stay playable forever.
- Auto-approved job application at the start, plus 3 preset characters.
- A paid licence test (cone course + 10-question theory, pass with 8/10) to go from bicycle to motorbike. A car test works the same way for taxis.
- Money from every delivery, stars decide what you can unlock, and random tips on 5-star jobs.
- Bicycle carries one small order. Motorbike carries bigger orders that pay more.
- Crashes cost you: small ones hurt your rating, big ones mean hospital and repair bills. Optional insurance per delivery.
- Too many bad ratings sends you down a tier. Crashing a lot sends you down and you retake the test.
- Lower jobs always stay open but pay less and give less XP.
- Taxis use passenger requests (AC up/down, AUX, music) that you handle with keys.
- All brands are made up (no real company names).
- Game text is English only. Signs in the world are Arabic + English, like Dubai.
- Chill Arabic-style background music (free-to-use tracks only).
- Tier 1 happens in Wahat Al Shams, a made-up car-free eco community at real size (about 940 by 500 m): a Plaza with 10 restaurants, a bike shop and a clothes shop, a green park through the middle, 5 clusters of 100 joined homes, a school, an institute and stables. Shifts are 8 minutes.

## The career ladder (NOT NOW, vision only)

Six tiers, each one with a new vehicle, new areas and better pay. Pay numbers are starting guesses in game Dirhams (Dh) and will need tuning once it's playable.

| Tier | Job | Vehicle | Where you can go | Pay per job | To unlock |
| --- | --- | --- | --- | --- | --- |
| 1 | Food rider (Snackaroo) | Bicycle | Your home villa community | 8 to 15 Dh | Application form at the start |
| 2 | Box delivery rider (Dune Express) | Small motorbike | Villas, Old Town, other communities | 20 to 40 Dh | 4.0+ stars, 20 deliveries, pay and pass the motorbike test |
| 3 | Pro rider (Snackaroo Pro) | Bigger motorbike with a cooler box | Adds Marina and Downtown | 40 to 80 Dh | 4.3+ stars, buy the bigger bike |
| 4 | Taxi driver (Yalla Cabs) | Taxi saloon | Whole city | 60 to 120 Dh | 4.5+ stars, pay and pass the car test |
| 5 | Premium taxi (Falcon Ride) | Premium SUV | Whole city, airport and hotel pickups | 120 to 250 Dh | 4.7+ stars, buy the SUV |
| 6 | Luxury chauffeur (Mirage Black) | Luxury car | VIP pickups anywhere | 250 to 600 Dh | 4.8+ stars, prestige rank, buy the car |

**How climbing works**

1. Stars show you're good enough. Each tier needs a minimum star average.
2. Money pays for the next test or vehicle.
3. Tests (Tier 2 and Tier 4) make the big jumps feel like a moment.

**Going back down:** you can take any job from a tier you've already unlocked, using any vehicle you own. It pays less and gives less XP, but it's good for daily challenges or just chilling. A Tier 4 taxi driver doing an ice cream run on a bicycle is allowed.

**Order size by vehicle:** the bicycle only fits one small order for one person. The motorbike carries bigger orders (family meals, big drink runs), and bigger orders pay more. Carrying several orders at once might come later.

**Getting sent down**

- **Bad ratings:** if your rating (the average of your last 50 deliveries, same number everywhere) drops below your tier's minimum, you get a warning. Still below after 10 more deliveries means you go down a tier.
- **Crashing a lot:** 3 big crashes within 7 shifts (a "week") sends you down a tier, and you have to retake that tier's test (100 Dh retake).
- **Climbing back:** meet the requirements again and you go straight back up. No new test unless crashes were the reason you went down.

## Start of the game

The game opens with a quick job application on a phone screen. It always gets accepted, so it's about setting the mood, not a challenge.

**Application form (Snackaroo Rider Application)**

1. What's your name? (text box, this is what customers call you)
2. Where are you from? (pick from a list of countries, it just shows on your rider profile)
3. Pick your look (3 presets, see below)
4. Tap Submit, then a short "Reviewing..." spinner, then "Congrats, you're hired!"

**3 character presets**

| Preset | Look | Notes |
| --- | --- | --- |
| A | Cap, hoodie, backpack | Classic rider |
| B | Helmet with stickers, sports top | Sporty |
| C | Bucket hat, sunglasses, shorts | Chill |

All three play the same. Only the look changes.

Right after you're hired, the boss sends a message with your first order. It's an easy pizza two streets away, and it works as the tutorial.

## Delivery loop, stars and money

Every delivery is a race against three meters: time, heat and damage. How well you manage them sets your star rating, and stars plus money are what move you up the ladder.

**One delivery, step by step**

1. An order pops up on your phone: restaurant, customer address, food type, pay.
2. Accept it (or skip it). An order you ignore for 30 seconds counts as skipped.
   - **Acceptance rate** is the share of your last 20 orders you accepted. Below 70% the next few orders are the boring short ones (low pay, no tip chance) until it's back above 70%. No other punishment.
3. Ride to the restaurant and pick up the food: stop near the door, press **F** to get off the bike, walk to the door and **hold E for 1.5 seconds** (an orange bar fills on the phone). Walk back and press **F** to get on.
4. Ride to the customer's villa. The meters start ticking.
5. Park near the villa, press **F** to get off, walk to the door and **hold E for 1.5 seconds** to hand the food over. The meters keep ticking while you walk, so parking close to the door matters. Then the **Delivered!** card shows your stars, pay and maybe a tip (see "Screens").

**The three meters**

| Meter | What drains it | Food that cares most |
| --- | --- | --- |
| Time | Every second after pickup | Everything |
| Freshness | Time in the sun (faster on the day shift). Cold food melts, hot food goes cold | Ice cream, cold drinks, hot coffee |
| Damage | Bumps, crashes, kerbs, hard braking | Cake, drinks, soup |

**How the meters go from green to red**

- Each meter is a bar from 100% (green) down to 0% (red). Above 60% is green, 30% to 60% is orange, below 30% is red.
- **Time:** the target time is the straight-line distance from restaurant to villa at a normal riding pace (20 km/h), times 1.5 for corners, plus 20 seconds. The bar is full at pickup, at 60% (the edge of green) when you reach the target time, and empty at twice the target time. So on time = green, a bit late = orange, very late = red. Once empty it stays empty, the order isn't cancelled.
- **Freshness:** drains at a fixed rate per food type (pizza slow, bubble tea medium, ice cream fast). Numbers live in game_config.gd.
- **Damage:** starts full. Every bump, speed bump, kerb, hard brake or crash takes off a chunk. Bubble tea loses the most per bump.
- A meter at 0% never cancels the order. You can always deliver, you just get fewer stars.

**Stars (1 to 5)**

- Start at 5 stars. Each meter in the orange takes off half a star, each meter in the red takes off one and a half stars. Round to the nearest half star, never below 1 star.
- Examples: all green = 5. One orange = 4.5. One red = 3.5. All three red = 1.
- Your rating is the average of your last 50 deliveries, so one bad run doesn't ruin you.
- Higher rating = better orders show up more often. A "better order" is one with higher pay, a shorter ride, or a tip-friendly customer (a higher tip chance). Starting idea: at 4.5+ stars, half the orders are better orders; below 4.0, one in five.

**Money**

- Base pay per delivery, plus a little extra for distance.
- **Tips:** only possible on 5-star deliveries, and not every time. Starting idea: a 40% chance of a tip between 2 and 15 Dh (scales up with tier).
- Money buys tests, vehicles and gear.

**XP**

- Every delivery gives XP. Higher-tier jobs give more.
- XP builds your **Rider Level** (shown on your profile). Each level needs more XP than the last.
- Rider Level is what gear needs. Gear costs money **and** a level: a louder bell at level 2, the GPS line at level 3, a bigger stamina bar at level 5. Levels don't change the career ladder, stars and money do.
- Doing jobs from a lower tier gives less money and less XP (starting idea: 50% of normal).

**Tier 1 food types (first version)**

- Pizza: easy, good for the tutorial
- Ice cream: melts fast
- Bubble tea: spills on bumps
- From the graphics pass: shawarma, cake, groceries and farm juice/salad
- From the detail pass: coffee, manakish, pad thai, sushi, tacos and burgers (see the restaurant table in "Wahat Al Shams")

**Shifts**

- The clock rate is fixed: **one real gameplay second = one in-game minute**. The shift runs from 8:00 AM to 6:00 PM, so it lasts **10 active real minutes (600 seconds)**. One in-game hour takes 60 real seconds. The AM/PM clock advances one displayed minute each second, with a small sun icon, and the shift ends with a golden sunset. Pause menus, delivery-result screens and the tutorial freeze gameplay time. Tier 1 is day shift only. Night shifts unlock at Tier 2.
- If the clock runs out while you're carrying an order, you still finish that delivery. The shift ends right after you drop it off. No new orders pop up once the clock is out.
- At the end you get a summary screen: deliveries, stars, money earned, XP.

**Bicycle stamina:** sprinting drains a stamina bar and coasting refills it, so you can't hold sprint forever. The motorbike doesn't have this.

**Running costs:** none in Tier 1. Fuel and repairs start with the motorbike. The only Tier 1 costs are crash bills and the optional insurance (see the next section).

**Finding the address**

- Every villa has a readable house number.
- A mini-map in the bottom left shows the exact drop-off spot and the villa number.
- Some orders come with notes, like "leave it at the door" or, in Downtown, "leave it in the lobby".
- A GPS route (a line on the road and the mini-map) is an upgrade you buy at Pedal Point Bikes, not there from the start.

**Customers at the door:** the customer comes out with a short animation and one line of speech. Some ask you to leave it at the door. More customer types get added later.

## Special orders, goals and events (graphics pass)

These stop deliveries from feeling the same after a few. All numbers are starting ideas and live in game_config.gd.

**Special orders** (about 1 in 6 orders, never two at once, shown with a coloured chip on the phone)

| Order | What's different | Reward |
| --- | --- | --- |
| Rush | Target time is 70% of normal | +50% pay |
| Fragile cake | From Bread & Zaatar. Bumps do double damage | Tip chance 60% instead of 40% on 5 stars |
| Neighbour | When you get to the door: "Not home! Leave it with the neighbour at Villa X" (a home in the same cluster). The clock keeps running | Normal pay, +5 Dh |
| Big family order | Two bags on the bike: top speed 15% lower and steering a bit wobblier | Double pay |

**School orders:** teachers and kids order to Fair Grade International School, always to the security booth at the school gate. They only come in between 08:00 and 15:00 on the shift clock. Lunch rush from 11:30 to 12:30: about 1 in 3 orders is for the school.

**Stables orders:** riders and grooms order to the stable office. Horses in the paddock are just for looking at.

**Farm orders:** about 1 in 8 orders is picked up at the Wahat Farm Stall in the green spine instead of the Plaza.

**Regular customers:** 4 regulars who order more often than anyone else, have a heart on the phone and say your name. Their tip chance is 60%. Starting list:

| Regular | Where | Usually orders |
| --- | --- | --- |
| Auntie Mariam | Villa 7, Cluster 2 | Bubble tea |
| Mr Rashid | Villa 3, Cluster 5 | Shawarma |
| Ms Dana (teacher) | Fair Grade school gate | Cake from Bread & Zaatar |
| Hamdan (groom) | Stable office | Farm juice |

**Shift goals:** at the start of each shift the phone shows 2 goals picked from a list. Each done goal pays a 15 Dh bonus, shown on the shift summary. List: make 6 deliveries; 3 five-star deliveries in a row; no crashes; a school lunch order; a fragile cake with 5 stars; deliver to 3 different clusters.

**Random events** (at most 2 per shift, one at a time, the phone warns you):
- **Road works:** cones, a barrier and a small digger close one cluster lane or one part of the ring road for 1 to 2 in-game hours. The mini-map shows a cone icon. You find another way.
- **Horses crossing:** a groom leads 2 or 3 horses across a path for about 5 seconds. You wait or go round. Riding into them is a small crash.

## Controls (Tier 1, keyboard)

Keys are placeholders until the controls are tested. Controller support comes later.

| Key | What it does |
| --- | --- |
| W or Up arrow | Pedal |
| S or Down arrow | Brake, then roll slowly backwards |
| A / D or Left / Right | Steer (only while moving) |
| Shift | Sprint (uses stamina) |
| Space | Handbrake |
| B | Bike bell (people and kids look up and wave, cats move aside) |
| E | Tap: accept order, Next order on the Delivered card. Hold 1.5 s at the door (on foot): pick up, drop off |
| F | Get off the bike / get back on (only when nearly stopped) |
| W A S D (on foot) | Walk. Shift to jog |
| Q | Skip order |
| I | Switch crash insurance on or off (shown on the phone) |
| X | Rocket booster (once you own it, see "Shops and upgrades") |
| In a shop | ‹ › or W/S: type, A/D or click: try on, E: add to cart, C: checkout, drag: turn, Esc: leave |
| Esc | Pause (and resume) |
| R | Put the bike back on the road if you get stuck |

## Screens (look and feel)

The mockup (link at the top) is the look to copy. The game world stays 3D; the cards and panels on top copy the mockup's clean style.

**Fonts and colours (every screen):** Baloo 2 for big titles and numbers, Nunito for everything else, Noto Sans Arabic for Arabic. All three are free under the SIL Open Font License. Colours: deep teal #0F4C5C, orange #F28C28, sun yellow #F2B230, sand #F3E3C3, ink #1B1D22, white cards with rounded corners (about 28 px), dark see-through HUD panels (#0F2026 at 86%).

**Start screen (main menu + rider application):** one layout, like the mockup's "Start: rider application". Left: "AL SARAB · السراب" label, big "Five Stars Habibi" title, orange "Rider to Driver" subtitle and one line about the game, in front of a low-poly 3D desert (sand dunes, a big pale sun, one palm). Right: a phone. On the main menu the phone shows Play (or Continue if you have a save), New game, Settings and Quit. The first time you play, the phone turns into the Snackaroo rider application: name, where you're from, "Pick your look" with 3 cards (Classic, Sporty, Chill), each with its own little 3D rider, and a Submit application button. Then "Reviewing..." and "Congrats, you're hired!" on the same phone.

**Delivered card (after every delivery):** the game pauses (the shift clock too). The camera cuts to a 3D shot of your rider and the customer at the villa door (or the bag on the doorstep for leave-at-the-door orders), with the customer's line in a white speech bubble. On the right, a white card like the mockup: "Delivered!", 1 to 5 stars, the food, villa and ride time, three tiles (Time, Freshness, Damage) each with a word and a colour, then Delivery pay, 5-star tip, Insurance, a bold "You earned" total and XP. A dark teal "Next order · E" button closes it.

**Clinic screen (after a big crash):** like the mockup's "Big crash: clinic bills". A simple 3D clinic room (pale teal walls, a bed with your rider lying in it, a drip stand) behind it. Left: a small red "BIG CRASH" label, the big title "You woke up at Wahat Al Shams Clinic", one sentence saying what you hit and how fast, and a teal Arabic sign "عيادة واحة الشمس". Right: a white "Your bills" card with an "ORDER CANCELLED · 0 STARS" tag, Clinic bill, Bike repair (Snackaroo), Insurance, a bold red "You pay" total, a yellow tip box when insurance was off, a "Big crashes this week" bar (1 of 3), and two buttons: "Turn on insurance" (only when it's off) and "Shift summary". When the boss covers your first big crash, the card says so and You pay is 0 Dh.

## Graphics and feel (graphics pass)

Polished low-poly: still simple shapes, but with nicer light, moving people and lots of little details.

- **Art:** the houses, Plaza, school, mosque, stables and domes are built in code from our own kit of parts. People, cars, plants and small props come from free CC0 packs (Kenney, Quaternius), credited in CREDITS.md. Never paid or copyrighted assets.
- **People move:** customers, walkers, gardeners, kids, teachers and grooms have idle, walk and wave animations. Your rider too, on the bike (pedalling) and on foot.
- **The bike:** a proper low-poly bicycle. The pedals turn with speed, the handlebars turn when you steer, the kickstand drops when you get off, and B rings the bell.
- **Light:** the sun moves with the shift clock: low and warm in the morning, high and white at noon, a golden sunset from 17:00. Soft shadows in corners (SSAO), a light haze towards the desert, and a gentle glow on bright things. (The heat shimmer was removed in the detail pass: it looked like a warpy smear in front of you.)
- **Juice:** dust puffs from the tyres on sand and when braking hard, speed lines and a wider camera when sprinting, coin and star pops when you deliver, and the phone buzzes (shakes with a sound) when a new order comes in.
- **Life on the map:** golf buggies driving slowly on fixed routes (they stop and wait if you're in the way), horses with riders on the edge track, joggers and walkers, gardeners watering, kids at the cluster playgrounds, birds flying over, palms swaying, the stream and fountain moving, ducks on the stream and donkeys in the spine. No real traffic AI until Tier 2.
- **Graphics setting:** Low, Medium (default) or High in Settings. Low turns off SSAO and haze and shows fewer people; High shows everything.
- **Camera:** it moves in closer when a wall comes between it and your rider, so it never ends up inside a house.
- **Speed (detail pass):** top speed 28 km/h, sprint 36 km/h. Sprinting shows strong speed lines, a bigger camera stretch and a wind sound, so it feels fast.

## Reasons to come back (Sessions 47 to 51)

Research on games like Crazy Taxi, PowerWash Simulator, Stardew Valley, Euro Truck Simulator 2 and Death Stranding (Nov 2026) says players return when they always have a clear next goal, every action feels satisfying, their skill pays off, and there are characters they care about. Right now money and XP don't buy anything, so these come before the itch.io release. Rule for all of them: the reasons to come back must be fun, never fear of missing out. No daily login rewards, no streaks you lose by not playing, no countdowns that nag you to come back.

**A perfect delivery feels special.** The Delivered card already pops the stars and coins (Session 31). On top of that: all three meters green shows a big "PERFECT!" with a happy jingle, and a tip gets its own little jingle.

**Gear shop and the next goal:** moved to "Shops and upgrades" (the Pedal Point bike shop, detail pass).

**5-star streak and personal bests.** Each 5-star delivery in a row adds +5% to your tip chance, up to +30%. A crash or a delivery under 5 stars resets it (stopping playing never does). The phone shows "4 in a row". Personal bests, shown on the shift summary when you beat them: best shift earnings, longest streak, most deliveries in a shift, fastest ride to each home.

**Regulars get to know you.** The 4 regulars (Auntie Mariam, Mr Rashid, Ms Dana, Hamdan) get lines for a first visit, getting friendly (3 visits) and best friends (8 visits). Best friends tip a bit more often (70%).

**Choosing orders.** At a rating of 4.5 or more, half the time the phone shows two orders side by side: 1 or 2 picks one, Q skips both (counts as one skip). This is how "higher rating = better orders" works: one of the two is a better order (higher pay, a shorter ride or a tip-friendly customer).

**Tomorrow's special.** Each shift is a kind of day: a normal day, Hot Noon (food spoils faster in the sun), Rush Hour (orders come quicker, 10% more pay) or a shop special ("2-for-1 at Brain Freeze": double tip chance on that shop's food). The clock shows today's, and the shift summary says what tomorrow will be.

**Collections.** A Wahat Al Shams stamp card: a stamp for every home you've delivered to (500 homes in 5 clusters, plus the school gate, the stable office, the C Institute and the gym). Every 25 homes in a cluster pays a small 20 Dh bonus; a full cluster unlocks a gold delivery box colour. Also the cats and horses you've met (each gets a name) and the customer lines you've heard. All on a Profile page on the phone.

## Looks pass (Sessions 52 to 59)

Louis played the detail pass on 4 November. The map and gameplay are good. What's wrong: full screen looks low-res and jaggy, roads and overlapping surfaces flicker, interiors are too big and too plain, the gym is just a restaurant room, the C Institute's glass faces the wrong way, and the Plaza, streets and spine need more detail. The designs below were drawn in chat with Louis and approved one by one.

**Sharper graphics**
- Anti-aliasing (smooths jagged edges) on every level: Low uses FXAA, Medium uses MSAA 4x, High uses MSAA 4x plus TAA. The game draws at full screen resolution on desktop (the browser keeps its 0.75 scale).
- Sharper shadows near the rider: 4 shadow cascades and a bigger shadow map on Medium and High.
- Crisp signs and 3D text (bigger font size or MSDF fonts) so they don't blur in full screen.
- The first time the game starts it tests the computer and picks Low, Medium or High (a Mac like Louis's should get High, an iPad Low). Settings can still change it.

**No more flicker:** roads, lanes, paths, lawns, paving, courts and plazas are laid only 1 to 4 cm apart today, so from a distance they fight (z-fighting) and flicker. Merge the ground into one mesh with painted areas, or give each layer a real height step and a render priority, and check the camera's near and far planes. Fix the dome doors the same way. Louis saw flicker on roads and ground, and where surfaces overlap.

**Interiors (all walk-in places)**
- Smaller inside: about 12 × 10 m with a 4.5 m ceiling (they were 18 × 16 × 8 m). The outside of the Plaza stays the same; the leftover space is a storeroom you can't enter.
- Built from free CC0 kits found online, not our own boxes: KayKit Restaurant Bits (220+ restaurant and kitchen models), KayKit Furniture Bits, Kenney Furniture Kit, Kenney Food Kit (200 food models), a CC0 supermarket pack, and CC0 gym models from Poly Pizza (check each model's licence says CC0). All credited in CREDITS.md.
- Same layout everywhere: a menu board and the kitchen with a cook at the back, the counter with staff in the middle, tables with people eating at the front, plus a drinks fridge, a bin, plants, hanging lamps and a tiled floor in the shop's own colours.
- People move: diners eat, cooks cook, chefs slice, gym people run, row and lift, institute people type on laptops.
- A short queue: sometimes 1 or 2 people are in front of you at the counter and you wait 2 to 4 seconds. Never more.
- Big glass fronts so you can see inside from the Plaza, sliding glass doors that open as you walk up (the stable office has a wooden door), warm light from the lamps with soft shadows.
- The camera moves closer and a little higher indoors, so walls don't block the view, and moves back out when you leave.
- Each place has its own background sound (made by tools/make_sounds.py): oven crackle, grill sizzle, the sushi belt, gym music, quiet chatter, the till beep.

| Place | What's inside (from the approved designs) |
| --- | --- |
| 1000 Pizza | Brick dome oven with flames, pizza on a peel, stacked pizza boxes, black-and-white checker floor, red accents |
| Brain Freeze Gelato | Glass freezer of 8 colourful tubs, cone jar, pink-and-white stripes, pastel floor |
| Spill the Tea | 4 tea taps, cup sealing machine, cups with pearls, plant wall |
| Shawarma Supreme | Two spinning shawarma grills, stack of bread, Arabic patterned tiles |
| Bread & Zaatar | Bread oven, glass cake display (the fragile cake orders), bread baskets |
| Grand Groceries | A real supermarket: wall of drinks fridges at the back, 3 shelf units with hanging bilingual aisle signs (1 Snacks, 2 Rice and pasta, 3 Home) and yellow price strips, a fruit and veg stand, a bread shelf, a sweets rack, 2 checkouts with belts, a cashier, baskets and shoppers with trolleys. Pick up at checkout 1 |
| Tok Tok Thai | Woks over flames, red lanterns, dark wood floor |
| Sushi You | Sushi bar with a conveyor belt of coloured plates and diners on stools, glass fish case, two chefs, paper lanterns, navy curtain over the kitchen, a booth table, bamboo, a pick-up counter |
| Mario Bonito | Colourful tile band, paper bunting, cactus pots, taco counter |
| Burgerology | Flat grill with patties, fryer, pink neon "Burgerology" sign, white metro tiles |
| Wahat Gym | A real gym: glass wall onto the spine with the lap pool outside, 4 treadmills facing the glass, exercise bikes, a squat rack with a loaded barbell on a wooden platform, a dumbbell rack, 2 rowing machines, yoga mats and kettlebells, a mirror wall with "Train hard · تمرّن بقوة", rubber floor tiles, a water fountain and towel stand, reception with a smoothie cooler (drop-off) |
| C Institute | Two storeys tall: glass on both long sides (one faces the spine, so you see the domes and palms; the other faces the opposite way), a balcony walkway with a glass railing, a staircase, wide wooden stepped seats with cushions and people on laptops facing a talk screen (it changes during the shift: "Talk today · 4 PM", "Solar cities of tomorrow", "Welcome · أهلاً"), hanging plants, a wood-slat ceiling, a curved white reception desk with a big "C" logo wall (drop-off) |
| Pedal Point Bikes | Bikes hanging on the wall, tool pegboard, tyre rack, a repair stand with a bike, the mechanic at the workbench |
| Dune Drip | Caps and sunglasses wall, clothes rails, folded hoodies on a table, a rug and a big mirror, the cashier |
| Stable office | Wood walls, saddles on stands, rosettes and horse photos, riding helmets on hooks, a hay bale, a window onto the paddock with a horse, the groom at the desk |
| Wahat Farm Stall | Open stall by the domes with a striped awning, fruit and veg crates, a juice press and cooler, chalkboard menu, the farmer |
| Fair Grade school gate | Glass security booth with the guard, barrier, the school wall and sign behind, a teacher waiting |

**C Institute fix:** turn the building so one long glass side faces the spine (east) with the stepped seats in front of it, and add the same big windows on the opposite side, so you can see right through the lobby.

**More detail outside**
- Plaza: café tables outside the restaurants, a juice kiosk, string lights that come on at sunset, more people walking.
- Streets and lanes: street lamps that light up at sunset, white road markings and kerbs, bins, bilingual street signs, bike racks.
- Spine: real grass blades instead of the little green cubes on Medium and High; Low keeps a lighter, sparser version. Plus flowers, rocks and more trees.

**Bugs found in testing**
- Crash loop: a gardener standing still near the Cluster 4 playground (data/wahat_al_shams.gd GARDENERS, x 125, z 53) got hit, and the rider crashed into him again and again (162 times) after each fall; with an order still on, the shift never ended. Fix: after a small crash the bike is pushed back and gets a short grace period, and standing people step aside when you ring or come close.
- Crashing costs too little: a careless bot earned 89 Dh against 95 Dh for a careful one. Small crashes should cost more (rating, food damage or a small fee) so a careful shift clearly pays better.

## Shops and upgrades (detail pass)

Money and Rider Level finally buy things. Two shops in the Plaza, both walk-in like the restaurants.

**Shop screens (the same style for every walk-in place):** you stay in the 3D shop and see yourself, like in GTA's clothes shops. The camera turns to face your rider, and the menu sits on the left as a dark see-through panel with an orange header (the game's own fonts and colours), so you can still see the shop, the racks and the cashier or mechanic. Mockups: docs/shop_screens.svg.
- Arrows ‹ › (or W/S) switch the type, A/D or a click tries the next item on straight away, and you can drag to turn your rider or bike round.
- **Cart and checkout:** E adds the item to your cart. The cart shows what's in it and the total. "Checkout" (C) buys everything in the cart at once if you have the money and the level. Esc leaves the shop; anything not bought goes back on the shelf and you keep your old look.
- Owned items say "Owned", locked ones show the level they need, new ones have a "NEW" tag.
- Restaurant counters, the C Institute reception and the gym reception use the same side panel, smaller: it shows the order while the person hands you the bag or takes it.

**Pedal Point Bikes (بيدال بوينت)**, the bike shop and mechanic. Bikes hang on the wall, tools on a pegboard, and a mechanic stands at the workbench. Your bike turns slowly on a stand while you shop. Prices are starting ideas; tune them in the ten-minute-shift play-test.

| Upgrade | Level | Price | What it does |
| --- | --- | --- | --- |
| GPS route | 2 | 50 Dh | A glowing line on the road and the mini-map showing the way to the next stop |
| Louder bell | 2 | 25 Dh | B reaches twice as far: cats, kids and buggies move out of the way sooner |
| Insulated bag | 3 | 70 Dh | Food loses freshness 25% slower |
| Anti-spill box | 3 | 70 Dh | Bumps damage the food 30% less |
| Stamina +10% | 3 | 40 Dh, then 20 Dh more each time | Sprint lasts 10% longer. Buy it again and again, up to 10 times (+100%) |
| Better brakes | 4 | 90 Dh | You stop faster, and hard braking hurts the food less |
| Comfy tyres | 4 | 90 Dh | Speed bumps hurt less, and the spine's hills are smoother |
| Aluminium frame | 4 | 90 Dh | +1 km/h top speed |
| Carbon frame | 7 | 200 Dh | +2 km/h more (needs the aluminium frame) |
| **Rocket booster** | 10 | **10,000 Dh** | Press X: 4 seconds at 80 km/h with flames out the back, then 30 seconds to recharge. While it fires, bumps hurt the food 3 times as much, and any crash is a big crash. Late-game fun |

Also bike paint and delivery box colours (no level needed, 15 to 40 Dh, looks only).

**Dune Drip (ديون دريب)**, the clothes shop. Racks of clothes, a shelf of caps and glasses, a rug in front of a big mirror, and a cashier behind the counter. Caps, sunglasses, helmets, hoodies and tops, cycling jerseys, trainers and backpacks, 15 to 60 Dh, looks only, no level needed. What you wear shows on your rider everywhere (on the bike, on foot, on the Delivered card).

**The next goal:** the phone and the shift summary always show what you're saving up for with a progress bar, like "Carbon frame: Level 7 and 60 Dh to go".

## Crashes, bills and insurance

Crashing costs you, and insurance is an optional bet. Prices are scaled down from real Dubai costs so they fit game pay.

**Small crash vs big crash**

- **Small crash:** a low-speed hit or wipeout. You fall off, the damage meter takes a big hit (bad for your rating), and you get back on after about 2 seconds.
- **Big crash:** hitting a car, wall or pole above about 20 km/h on the bicycle (higher limits for faster vehicles). The screen fades out and you wake up at the clinic. The order is cancelled (0 stars, no pay), the bills pop up, and your shift ends.

**Crash reactions and severity billing (Sessions 44A–44B)**

- **Show the fall before the hospital.** A crash plays a short, stylised rider-and-bike sequence before recovery or the clinic fade. Use distinct reactions: a wobble or gentle tip for a soft/slow hit, a sideways skid for a glancing collision, and a forward tumble or over-the-handlebars fall for a hard frontal impact. Faster, harder impacts give a stronger tumble/slide and camera/sound feedback. The rider separates from the bike where appropriate; the camera keeps the fall visible.
- **Use the actual impact.** Capture the impact before the bike is stopped: relative speed into the obstacle, collision direction/angle, and obstacle category/hardness. A scrape along a wall should be milder than hitting it straight on at the same riding speed. A soft obstacle and a rigid wall/car should produce different reactions. Preserve the existing forgiving policy for people and animals.
- **Make bills depend on severity.** Replace the prototype's flat major-crash prices with tunable severity bands for treatment and bike repair. Higher-impact-speed and harder-object collisions cost more; low-severity falls recover with little or no cash cost. Insured contributions also vary by severity within a clearly shown cap, so insurance reduces the cost without making every crash cost the same. Show what was hit, impact speed, severity, treatment, repair, insurance and the final amount due.
- **One accident, one consequence.** The captured impact drives both the fall and its bill. Bounces during the fall must not add extra charges, crash counts or order cancellations. Disable normal riding during the sequence; always finish in a safe recovery or clinic transition, with a timeout if a physics fall does not settle.
- **Keep the existing protections.** The boss still covers the first major crash, and insurance starts on. Minor falls return control to the rider; major falls finish the animation before the hospital and shift-ending flow. The later rocket's “any crash is major” rule still applies, using the same impact record.
- Start with a few reliable authored/physics-assisted fall reactions; full ragdoll physics is optional. Exact thresholds, durations, material weights, bill bands and insured caps are playtest values in game_config.gd. Tune them against delivery earnings so a cool fall does not create an excessive repeat-work penalty.

**Bicycle bill bands (detail pass, playtest values)**

The captured relative impact speed, angle and material hardness choose the band.
Recoverable minor falls have no cash bill. The first major crash is still boss-covered.

| Severity | Treatment | Repair | Insured contribution cap |
| --- | --- | --- | --- |
| Minor | 0 Dh | 0 Dh | 0 Dh |
| Moderate | 60 Dh | 35 Dh | 8 Dh |
| Severe | 150 Dh | 80 Dh | 20 Dh |
| Critical | 220 Dh | 140 Dh | 35 Dh |

**Previous flat prototype bills (higher tiers remain future design)**

| Tier | Hospital bill | Repair bill (from the delivery company) | With insurance you only pay |
| --- | --- | --- | --- |
| Bicycle | 150 Dh | 80 Dh | 20 Dh |
| Motorbike | 400 Dh | 300 Dh | 50 Dh |
| Taxi tiers | 800 Dh | 1,500 Dh+ | 150 Dh |

A severe uninsured bicycle crash costs about 20 deliveries of pay. New riders have these protections:

- **The boss covers your first big crash.** The first big crash of the game shows the bills, then a message from the boss saying Snackaroo pays this one. You still lose the order and the shift.
- **Insurance starts switched on.** You can turn it off from the phone whenever you like. The tutorial points it out.

**Insurance (optional, paid per delivery)**

| Tier | Cost per delivery |
| --- | --- |
| Bicycle | 2 Dh |
| Motorbike | 5 Dh |
| Pro bike | 8 Dh |
| Yalla Cabs | 10 Dh |
| Falcon Ride | 15 Dh |
| Mirage Black | 25 Dh |

**Real prices this is based on:** a UAE ER visit costs about 500 to 1,500 AED before tests ([Zavis](https://www.zavis.ai/directory/pricing/guide/for-tourists)). A bike service in Dubai runs from about 50 to 300 AED ([UAEcycle](https://www.uaecycle.com/pages/bike-service-charging-list), [Adventure HQ](https://adventurehq.ae/pages/bike-service)). Real riders can earn 4 to 13 AED per delivery in incentives ([job ad](https://app.qureos.com/jobs/bike-rider-1773450516512)), which is why insurance had to be scaled down.

## The motorbike test (Tier 1 to Tier 2) (NOT NOW, vision only)

To leave the bicycle behind you book and pay for a test at the Al Sarab Riding School. It has two parts, a practical yard test and a theory quiz, and you need to pass both.

**What the real Dubai test looks like (what we're copying)**

- Getting a real licence involves a theory test, yard training, a yard test, road training and a final road test ([Property Finder](https://www.propertyfinder.ae/blog/dubai-motorcycle-licence)).
- The yard test has five moves: riding a straight line without putting your feet down, riding through the yard without hitting cones, leaning into turns, changing direction without hitting cones, and an emergency brake without crossing a marked line ([theorytest.ae](https://www.theorytest.ae/?p=15359)).
- It also checks slow riding and how fast you take turns ([Khaleej Times](https://www.khaleejtimes.com/life-and-living/dubai-how-to-get-a-motorcycle-riders-licence-requirements-eligibility-explained)).
- The real car theory test is 35 multiple-choice questions, and you need 23 right to pass ([ezhire](https://www.ezhire.ae/blog/how-many-questions-in-rta-theory-test-in-dubai)). Our game version is shorter and needs a higher score.

**Booking**

- Unlocks at 4.0+ stars and 20 deliveries.
- First attempt costs 200 Dh (around 15 to 20 Tier 1 deliveries, so it feels like a goal).

**Part 1: Practical yard test (with an instructor)**

An instructor NPC stands in the yard with a clipboard and talks you through each section.

1. **Straight line:** ride slowly along a narrow lane without wobbling out of it.
2. **Cone slalom:** weave through a line of cones without touching any.
3. **Figure of eight:** a tight loop around two cones at low speed.
4. **Speed limit section:** stay under the posted limit (for example 25 km/h) the whole way.
5. **Emergency stop:** the instructor shouts "Stop!" at a random moment and you have to stop before the line.

Mistakes give penalty points. Starting idea: a touched cone is 1 point, going over the speed limit is 2 points, missing the stop line is 3 points, and falling off is an instant fail. 4 or more points is a fail.

**Part 2: Theory quiz**

- 10 multiple-choice questions picked at random from a bank of around 30. A perfect 10/10 gets you half your test fee back (100 Dh on the first test, 50 Dh on a retake).
- You need **8 or 9 out of 10** to pass.
- Topics: speed limits, road signs, giving way, helmets, riding in sandstorms, what to do after a crash.

**If you fail**

- You have to do 5 more deliveries before you can retake it.
- The retake costs 100 Dh, half the price of the first try.
- You only retake the part you failed.

**If you pass:** a licence card animation, then your first motorbike unlocks and Old Town opens on the map.

The car test for Tier 4 reuses the same system: a yard course (parking, hill start, emergency stop) plus a theory quiz.

## Taxi tiers (4 to 6) (NOT NOW, vision only)

Taxis swap food for passengers but keep the same three-meter idea (time, comfort instead of damage, mood instead of freshness), so players already know how it works. Passengers ask for things mid-ride and you respond with keys while you keep driving.

**Passenger meters**

| Meter | Food version | What drains it |
| --- | --- | --- |
| Time | Time | Slow routes, getting lost |
| Comfort | Damage | Hard braking, sharp turns, bumps, crashes |
| Mood | Freshness | Ignoring requests, wrong AC, bad music, a hot car |

**Passenger requests**

A speech bubble pops up and you have a few seconds to react.

| Request | What you do | Starting key |
| --- | --- | --- |
| "Can you turn the AC up?" | Colder | Up arrow on the AC panel, or ] |
| "It's freezing, AC down please" | Warmer | [ |
| "Can I connect to the AUX?" | Hand over the music | M, then pick their phone |
| "Can you change the song?" | Next radio station | N |
| "Can you turn it down?" | Lower volume | - |
| "Can we take the fast road?" | Take the toll road (costs you a little) | Choose on the route screen |

Key choices are placeholders until the controls are tested.

**What changes per taxi tier**

- **Yalla Cabs (Tier 4):** normal passengers and simple requests. Someone always wants the AC colder.
- **Falcon Ride (Premium, Tier 5):** airport and hotel pickups, luggage to load, pickier passengers, bigger tips.
- **Mirage Black (Luxury, Tier 6):** VIP passengers, strict comfort rules (one hard brake ruins it), dress-code jobs, and a prestige rank you build over time.

**Later idea: big event orders.** Once you have a taxi car, a big catering order for an event can randomly pop up instead of a passenger. You load up a car full of food and get a big bonus.

## Fictional brands

Every brand is made up so the game never uses a real company's name or logo. Each one is a light nod to the kind of company it stands in for.

| In-game name | What it is | Stands in for |
| --- | --- | --- |
| Snackaroo | Food delivery app (Tiers 1 and 3) | Food delivery apps |
| Dune Express | Box and parcel delivery (Tier 2) | Parcel couriers |
| Yalla Cabs | Normal taxis (Tier 4) | City taxis and ride-hail apps |
| Falcon Ride | Premium taxis (Tier 5) | Premium ride services |
| Mirage Black | Luxury chauffeur (Tier 6) | Limo and luxury car services |
| Al Sarab Riding School | Where you take your tests | Driving schools |
| Al Sarab | The city ("sarab" means mirage in Arabic) | Dubai |

Restaurants get funny made-up names too, like Shawarma Supreme and Brain Freeze Gelato. In Wahat Al Shams most are spoofs of the real eco community's restaurants: 1000 Pizza, Tok Tok Thai, Sushi You, Mario Bonito, Burgerology, Bread & Zaatar, Spill the Tea and Grand Groceries. Places get spoof names too: Fair Grade International School, the C Institute, Pedal Point Bikes and Dune Drip.

## City map and districts

Al Sarab is one map. Districts sit behind barriers or a "not in your zone yet" message until your tier unlocks them, and once they're open they stay open.

| District | Opens at | Feel | Gameplay twist |
| --- | --- | --- | --- |
| Wahat Al Shams (home community) | Tier 1 | Car-free eco community: shady lanes, solar panels, a green park through the middle, horses | One drop-off spot at the school and the stables, regular customers, horses crossing |
| Other villa communities | Tier 2 | Bigger, longer roads | Security gate checks |
| Old Town | Tier 2 | Narrow alleys, markets | Shortcuts, potholes, tight turns |
| Marina | Tier 3 | Towers by the water, windy | Wind pushes you, nice tips |
| Downtown | Tier 3 | Skyscrapers, traffic jams | Lifts to high floors eat your time, and notes like "leave it in the lobby" |
| Highway and airport | Tier 4 | Fast roads, terminals | Fast travel, airport pickups |

**Wahat Al Shams, the Tier 1 community (real size since the detail pass)**

Wahat Al Shams (واحة الشمس, "Sun Oasis") is a made-up eco community. Its layout copies a real car-free eco community in Dubai (see Sources) as closely as we can, at **real size**, with every name made up. Built from a data list (data/wahat_al_shams.gd) plus builder scripts. Map sketch: docs/wahat_al_shams_map.svg. House sketch: docs/villa_types.svg.

*Size:* about **940 m west to east and 500 m north to south** (the real one is about 469,000 m² with a 2.9 km edge, measured by Louis on Google Earth). The long side runs west to east. The highway runs along the west end.

*Layout (west to east, see the sketch):*

| Part | Where | What's there |
| --- | --- | --- |
| Highway and 2 checkpoints | Along the west end | The highway outside the wall. Two entrances off it, one at the north-west and one at the south-west. Each has a security booth, a red-and-white barrier and **one guard** who waves. The barrier lifts for cars; your bike rides through a gap at the side. Real ID checks come later with motorbikes and cars (Tier 2) |
| Tree belt | All the way round the edge | Thick belt of tall trees and date palms |
| Horse track | Just inside the tree belt, all the way round | Dirt and sand, white horse rails on both sides. **Horses only**: nobody else goes on it. Gaps in the rails where the gate roads cross it |
| Run and cycle track | Right beside the horse track, all the way round | A **blue** rubber track for runners, cyclists and you. No buggies, no cars |
| Ring road | Inside the tracks, all the way round | The only road for cars. Cars drive slowly round it on set routes and pull in and out of the car parks. **No buggies on the ring road** |
| Mosque | North-west, just inside the north checkpoint, in front of the Plaza | A mosque with a minaret. Scenery only: no orders ever go there |
| Bus station | North-west, between the mosque and the Plaza | A bus bay with a shelter and a parked bus, joined to the ring road by its own short road so it looks real. A bus drives round the ring road and into the bay every in-game hour. A sign says "Coming soon: travel to other districts". **Each shift starts in front of the bus station.** Later (Tier 2) it becomes the way to travel to Downtown and other districts |
| The Plaza | North-west, from the bus station to Cluster 1 (a bigger area than before) | The hub: five low-rise blocks (flats and offices above, shops below) round a sunken square with a fountain, date palms, shade sails and benches. 10 restaurants, the bike shop and the clothes shop (see "Shops and upgrades"). A solar car park in the gap between the Plaza and Cluster 1 |
| Fair Grade International School | South-west | Copies the real school next door (photos Louis sent, described below). Orders only go to the security booth at the school gate |
| Horse jumping arena | Next to the school, south-west | A sand arena with white horse rails and jumps. Horses with riders jump now and then. Scenery |
| C Institute | Beside the school, between the school and the spine | A modern institute building (see below). Its big glass front and stepped seats face the spine. A small car park behind it. Drop-off: the receptionist inside |
| Stables | South-west, by the jumping arena | Stable block, a paddock with horses you can watch, and the stable office (drop-off spot) |
| Green spine | Through the middle, west to east | The long park (see below) with the domes, the farm, the gym, the lap pool and the community pool. Its paths are the main bike shortcut |
| 5 clusters | 3 north of the spine (C1, C2, C3), 2 south (C4, C5) | **100 homes each, 500 in total**, in joined rows (see below). No cars inside |
| Solar car parks | **In the gaps between clusters** (Plaza and C1, C1 and C2, C2 and C3, C4 and C5) | A short road off the ring road with car bays, every bay under a **solar panel roof**. Parked cars. Not behind the houses: homes go there instead |
| Building sites | Where there's nothing yet: south of the spine's west end (where the horse ring was), the south-east block where a sixth cluster could go, and any other empty patch | Fence with a bilingual "Coming soon" banner, a crane, sand piles, a site cabin and a couple of workers. Later we can swap them for real buildings |

*Who drives where:* cars only on the ring road and in the car parks, never in the lanes. Golf buggies only on the lanes inside the clusters and the spine paths, never on the ring road. People walk, and kids ride bikes and scooters, on the lanes and paths. Your bike can go everywhere except the horse track.

*The homes (joined rows, like the real ones):* homes are joined side by side in long rows with no gaps. Two rows sit back to back with just a wall between them, so each double row has a lane on both sides and every front door faces a lane. Now and then a small alley cuts through a row. Each cluster has 4 of these double rows of about 12 to 13 homes a side. Same 3 types as the real place: **90 courtyard villas, 8 garden villas and 2 signature villas per cluster** (the house kit from Session 26 stays: Louis likes the houses). Each double row is built as one merged mesh, and far-away rows use a simpler version, so 500 homes stay fast. The cluster mini-plazas (cooling tower, playground, benches) stay.

*Addresses:* homes are numbered 1 to 100 inside each cluster, like the real ones, so an address reads "Villa 45, Cluster 1" (phone and mini-map: "C1 · Villa 45").

*Fair Grade International School (from Louis's photos of the real school):* a 3-storey sand-coloured building whose wings curve in and out, with white rounded balcony bands on every floor, flat white roofs with AC boxes and white railings, and a rooftop garden. A big boxy sports hall at one end, sand-coloured with a dark strip of windows and the bilingual sign "FAIR GRADE INTERNATIONAL SCHOOL · مدرسة فير جريد الدولية" along the top, with tall flags at the entrance. Long solar panel roofs over the school car park. A fenced football pitch with green turf, two shaded pools, basketball and tennis courts, two shaded playgrounds. A low white wall round it all and a security booth at the gate. Big enough that you see it from far away.

*C Institute:* a modern low building with a huge glass front and wide stepped seats in front of it, like big stairs you can sit on, with a few people sitting there. Inside: one tall open lobby up to the roof, very modern (light wood, plants, glass), with a reception desk and a receptionist. You walk in and hold E at reception to hand over the food. A small car park behind it.

*The green spine:* grass with a real grass texture, tufts and flowers, gentle hills between 0.5 and 1.5 m high that you roll over, more trees, the stream, the farm beds, beehives, donkeys, the basketball court and the playground. One path links all the domes, evenly spaced along the spine, with no big gaps. In the middle: the **gym**, a small box that's rounded at the back with a glass front (treadmills you can see inside), with a **lap pool** along its side; a little way off, the **community pool**, a chill place with sunbeds, umbrellas, a kids' area and people swimming. The gym reception is a drop-off spot.

*Pickup spots:* the 10 restaurants in the Plaza (inside, at the counter) and the Wahat Farm Stall in the spine.

| Restaurant | Arabic sign | Food | What the food cares about |
| --- | --- | --- | --- |
| 1000 Pizza | ١٠٠٠ بيتزا | Pizza | Easy |
| Brain Freeze Gelato | برين فريز جيلاتو | Ice cream | Melts fast |
| Spill the Tea | سبيل ذا تي | Bubble tea and coffee | Spills on bumps |
| Shawarma Supreme | شاورما سوبريم | Shawarma | Goes cold, medium |
| Bread & Zaatar | خبز وزعتر | Manakish and cakes | Cakes break on bumps (the fragile cake orders) |
| Grand Groceries | جراند جروسريز | Groceries bag | Slow to spoil, a bit heavy |
| Tok Tok Thai | توك توك تاي | Pad thai | Goes cold, spills a little |
| Sushi You | سوشي يو | Sushi | Must stay cool, a bit fragile |
| Mario Bonito | ماريو بونيتو | Tacos | Fall apart on bumps |
| Burgerology | برجرولوجي | Burgers | Goes cold |
| Wahat Farm Stall | كشك مزرعة الواحة | Fresh juice and salad box | Spoils in the sun |

The names are made-up spoofs of the real Plaza's restaurants (Louis's picks), so no real brand name is used.

*Restaurant fronts and interiors:* every restaurant looks different outside (awning colour, sign shape, outside seats) and inside. You get off the bike, walk in, and hold E at the counter; a staff member hands you the bag. Each has 2 to 4 tables with a few customers and a menu board. Insides: 1000 Pizza a brick oven, Brain Freeze a glass freezer with colourful tubs, Spill the Tea tea taps and cups, Shawarma Supreme a spinning grill, Bread & Zaatar a cake display and a bread oven, Grand Groceries shelves and fridges, Tok Tok Thai woks and lanterns, Sushi You a sushi bar with a conveyor, Mario Bonito colourful tiles and a taco counter, Burgerology a grill and neon menu. No two insides are the same.

*Drop-off spots:* the 500 home doors, the school gate booth, the stable office, the C Institute reception and the gym reception. Never the mosque, the bus station or the shops.

*Who orders:* residents (the 5 outfits), teachers and school kids at the school, riders and grooms at the stables, staff and visitors at the C Institute, and gym-goers at the gym.

*Obstacles:* speed bumps on the ring road, cats, kids on scooters and bikes, golf buggies, and horses when they cross a path.

*Details everywhere:* real-looking textures (grass, sand, paving patterns, asphalt with road lines, kerbs) and small props so nothing looks plain: lamp posts, bins, recycling points, bike racks, electric car chargers, planters, benches and signs.

**Language and signs:** the game itself (menus, phone, customers) is in English only. Signs on buildings, shops, restaurants and roads show both Arabic and English, like real signs in Dubai.

**Music:** chill Arabic-style background music, the kind you'd hear in a cafe or a taxi here. Only music that's free to use (CC0 or properly credited).

## Milestones

Build it in milestones and play-test at the end of each one. Only move on when the current milestone feels good. The exact sessions are in BUILD_PLAN.md.

1. **Bike feel:** a bicycle you can ride around a flat test area.
2. **One full delivery on the test area:** phone order, pickup, drop-off, pay. No meters yet. If this isn't fun, the map won't fix it.
3. **Palm Grove map:** roads, villas with house numbers (placed from a data list, not by hand), the restaurant strip with Arabic + English signs, decoration, mini-map.
4. **Meters, obstacles and stars:** time, freshness and damage, the things that hurt them, plus the star score at the end.
5. **Money, tips, XP and customers:** wallet, random tips on 5-star jobs, Rider Level, customers at the door.
6. **Crashes and shifts:** small and big crashes, insurance, the shift and the summary screen.
7. **Start screen and polish:** application form and the 3 presets, menu, saving, sounds and music, then the polish pass (hold E, get off the bike, screens like the mockup).
8. **Graphics pass:** the Wahat Al Shams community, the house kit, light and weather, animated people, the real bike, juice, life on the map, special orders, goals and events.
9. **Detail pass:** real-size Wahat Al Shams with joined rows of homes, walk-in restaurants, Fair Grade School, the C Institute, gym and pools, horse tracks, textures, the bike shop and the clothes shop.
10. **Reasons to come back:** streaks, choosing orders, tomorrow's special, collections, then release on itch.io and the browser site.
11. **Motorbike test:** yard course, instructor, theory quiz, fail and retake rules.
12. **Tier 2 and beyond:** motorbike, Old Town, then the next tiers one by one.

## Still open

- Final name (Five Stars Habibi for now, might change later)
- Tuning all pay, bills and insurance numbers once Tier 1 is playable
- Whether the motorbike can carry several orders at once, later on
- Exact keys for the taxi requests
- Pay for the new foods, special orders and goal bonuses: starting ideas are in the PRD, tune them after the graphics pass play-test
- Upgrade prices and how much a shift pays at real size and 8 minutes: tune in the detail pass play-test
- What goes on the building sites later (a sixth cluster, a hotel, something else)

### Road network (World polish pass, from 5 Nov 2026)

The approved top-down plan is docs/road_plan_2026-11-05.svg. The ring road is the only main
road and connects to just four things: the two gate roads, the bus station loop and the
stables car park. The car parks between the clusters keep their entrances from the ring road.
Everything inside is one connected network with rounded corners and no dead ends: the spine
road (the only road that gets red walking tracks, both sides), the loop round the spine (the
cluster front road, the south road and the school road), the road behind the C Institute, and
a roundabout east of the C Institute whose north exit curves into the Plaza. Each cluster has
a front and a back cross road joining its five lanes; only the front one links out, and no
cluster road touches the ring road. Buses only use the ring road and the bus loop. Each shift
starts beside the bus station, facing the Plaza.

## Decisions log

One line per decision, newest at the bottom. Add a line whenever the design changes.

| Date | Decision |
| --- | --- |
| 2 Nov 2026 | Food delivery career game with a 6-tier ladder: bicycle, motorbike, pro rider, taxi, premium taxi, luxury chauffeur |
| 2 Nov 2026 | Build in Godot 4 with GDScript, 3D, camera behind the rider. Roblox port maybe later |
| 2 Nov 2026 | First version is Tier 1 only (bicycle in Palm Grove) |
| 2 Nov 2026 | All brands are made up (Snackaroo, Dune Express, Yalla Cabs, Falcon Ride, Mirage Black). City is Al Sarab |
| 2 Nov 2026 | Motorbike test: cone course + 10-question theory, pass with 8/10, 10/10 gets half the fee back |
| 2 Nov 2026 | Test costs 200 Dh, retake 100 Dh after 5 more deliveries. Taxi tier uses a car test built the same way |
| 2 Nov 2026 | Bicycle carries one small order; motorbike carries bigger orders that pay more |
| 2 Nov 2026 | Crashes: small ones hurt your rating, big ones mean clinic + repair bills. Optional insurance per delivery |
| 2 Nov 2026 | Bad ratings send you down a tier; crashing a lot sends you down and you retake the test |
| 2 Nov 2026 | Game text English only; signs in the world are Arabic + English. Chill Arabic-style music, free tracks only |
| 2 Nov 2026 | Low-poly graphics with free CC0 assets; keyboard controls first |
| 2 Nov 2026 | Working name Five Stars Habibi (may change later). Release Tier 1 free on itch.io |
| 2 Nov 2026 | Mockup made; gameplay and customer screens should feel 3D with real depth |
| 2 Nov 2026 | This file is the PRD and the one true copy of the design |
| 2 Nov 2026 | Review fixes: rating always averages the last 50 deliveries (was 30 in one place) |
| 2 Nov 2026 | Heat meter renamed Freshness. Meters have green/orange/red bands and a written time target. A red meter never cancels an order |
| 2 Nov 2026 | Star formula: start at 5, orange meter takes half a star, red takes one and a half, never below 1 |
| 2 Nov 2026 | XP builds a Rider Level that gates gear (bell, GPS line, stamina). Ladder still uses stars and money only |
| 2 Nov 2026 | Ignored orders count as skipped after 30 s. Acceptance rate under 70% gives boring orders, nothing worse |
| 2 Nov 2026 | Boss covers the first big crash. Insurance starts switched on |
| 2 Nov 2026 | Shift clock running out mid-delivery lets you finish that delivery first |
| 2 Nov 2026 | Controls table added to the PRD (Esc pause, R reset). Vision-only sections marked NOT NOW |
| 2 Nov 2026 | Build order changed: delivery loop on the test area before the Palm Grove map. Villas placed from a data list |
| 2 Nov 2026 | Signs use Noto Sans Arabic (SIL Open Font License, credited in CREDITS.md) for both lines. Brand names are written out in Arabic letters (برين فريز جيلاتو), plain words are translated (واحة البوبا, شارع الواحة) |
| 2 Nov 2026 | Palm Grove gets a mosque and a park north of Ghaf Street, the Al Sarab Mini Market by the gate, palm trees, parked cars and 10 speed bumps. Speed bumps are a trigger, not a solid block: the bike hops, slows if fast, and counts each bump for the Session 8 damage meter |
| 2 Nov 2026 | Mini-map turns with the rider (heading up), shows villa numbers, an orange pin with the next stop's number and distance, pinned to the edge when off the map. About 1 in 3 orders has a customer note |
| 2 Nov 2026 | Meters: freshness drains 0.35 (pizza), 0.6 (bubble tea), 1.0 (ice cream) % per second. Damage per knock depends on the food; bubble tea loses 14% on a fast speed bump. Hard braking = braking above 18 km/h |
| 2 Nov 2026 | 5 cats wander slowly in gaps between villas, 3 kids on scooters ride up and down street edges. Both are solid; bumping one costs 10 to 15% food damage and they get scared for 1.5 s. Kids wait if the bike blocks them |
| 2 Nov 2026 | XP per delivery = 10 + 2 per star (5 stars = 20 XP). Rider Level 1 to 2 needs 50 XP, each next level needs 25 more. Boring orders never tip. Better orders for high ratings not built yet |
| 2 Nov 2026 | Customers: 5 outfits (incl. kandura and abaya), 20 lines in data/customer_lines.gd with {name} for the rider's name. 15% of orders are 'leave it at the door': nobody comes out, a bag is left on the doorstep. Other notes on 25% of orders |
| 2 Nov 2026 | Crashes: a fairly head-on hit at 10 km/h or more is a small crash (fall off 2 s, -30% damage); above 20 km/h into a car, wall or pole is a big crash. Cats and kids only cause small crashes. A cancelled order counts as 0 stars in the rating. Wallet can go below 0. I toggles insurance |
| 2 Nov 2026 | Shifts: 10 real minutes, clock 08:00 to 18:00, orange in the last minute. An order on the phone when the clock runs out disappears without counting as a skip. A big crash ends the shift after the clinic |
| 2 Nov 2026 | Application: 43 countries + 'Somewhere else'; a 3D preview shows the picked look. Tutorial order: Pizza to villa 4. During the tutorial no other orders come and the shift clock waits |
| 2 Nov 2026 | Saving: one JSON save (user://save.json) that saves itself after every change and when you close the game. New game wipes it. Settings (fullscreen, later volume) live in their own file so New game keeps them |
| 2 Nov 2026 | All music and sounds are made by our own script (tools/make_sounds.py), so they're CC0 and need no downloads. Music: a 53 s loop in maqam Hijaz (oud-like pluck, darbuka maqsum, drone). Volume sliders: Volume, Music, Effects, Ambience |
| 2 Nov 2026 | Session 17 tuning from a play-test bot that rides whole shifts: the time bar now reaches 60% at the target time and 0% at twice the target (it used to be empty at the target, so even on-time rides were red). Freshness drain lowered to 0.25 / 0.4 / 0.55 % a second (pizza / bubble tea / ice cream). Speed bumps only hurt the food much above 10 km/h. Hard braking starts at 22 km/h. A careful shift now gets about 12 deliveries, 5 stars and 120 Dh; a careless one crashes and earns about half |
| 2 Nov 2026 | Palm Grove layout: 300 m square with a wall and a closed gate in the south, Palm Grove Avenue from the gate to a central roundabout, three cross streets, 36 villas, restaurant strip just inside the gate |
| 3 Nov 2026 | Polish pass planned (Sessions 18 to 24): hold E for 1.5 s to pick up and drop off, nearly stopped |
| 3 Nov 2026 | You get off the bike to pick up and deliver: F gets off and on (only when nearly stopped), you walk to the door yourself, meters keep ticking while you walk |
| 3 Nov 2026 | Screens copy the mockup: Baloo 2 + Nunito fonts on every screen, start screen with the title left and the phone right, a Delivered card after every delivery (game paused), and the clinic screen as in the mockup with a 3D clinic room |
| 3 Nov 2026 | Graphics pass planned (Sessions 25 to 34) after the polish pass. Biggest problems to fix: the map feels empty, and deliveries get the same after a few |
| 3 Nov 2026 | Shift is 5 minutes: 30 seconds per in-game hour, 08:00 to 18:00, ending with a golden sunset (was 10 minutes) |
| 3 Nov 2026 | New Tier 1 community Wahat Al Shams replaces Palm Grove. Layout copies the idea of a real car-free eco community in Dubai: tree belt and horse track round the edge, ring road, gate on the west, a Plaza, a green spine through the middle, 5 car-free clusters of 12 homes with shady lanes and mini-plazas, solar car parks, a school, a mosque, stables and a building site. About 400 by 300 m |
| 3 Nov 2026 | Houses: one style (cream L-shaped two-storey villa, roof terrace under solar panels, wind tower, courtyard wall) in 3 types: 10 courtyard, 1 garden and 1 signature villa per cluster. Built in code from our own kit of parts. Addresses read "Villa 7, Cluster 3" |
| 3 Nov 2026 | The Plaza has a sunken round square and 6 shops around it: Pizza, Brain Freeze Gelato, Boba Oasis, Shawarma Supreme, Sunrise Bakery, Al Sarab Mini Market. Plus the Wahat Farm Stall in the spine. New foods: shawarma, cake, groceries, farm juice/salad |
| 3 Nov 2026 | School orders (teachers and kids) only to the gate security booth, 08:00 to 15:00, lunch rush 11:30 to 12:30. Stables: look at the horses, orders only to the stable office. The mosque is scenery only, never an order |
| 3 Nov 2026 | Special orders (rush, fragile cake, neighbour, big family order), 4 regular customers, 2 shift goals worth 15 Dh each, and 2 random events (road works, horses crossing). The dust gust event was dropped |
| 3 Nov 2026 | Graphics: polished low-poly with CC0 packs (Kenney, Quaternius) for people, cars and props; animated people; a real bike model with turning pedals, steering, kickstand and a bell on B; sun moving with the shift clock, SSAO, haze, glow, heat shimmer; juice (dust, speed lines and FOV, coin and star pops, phone buzz); life on the map (buggies on fixed routes, horses, joggers, gardeners, kids, birds, palms, ducks, donkeys); Low/Medium/High graphics setting |
| 3 Nov 2026 | Session 34 play-test tuning (for Louis to confirm): a careful bot gets 5 to 6 deliveries a 5-minute shift (without sprinting), so the goals are now make 6 deliveries (was 8), a school lunch order (was 2: the lunch rush is only 30 real seconds) and deliver to 3 different clusters (was all 5). 7 in 10 orders now go to the nearer half of homes from the shop, so trips are shorter and a shift is busier; pay per shift stays about the same |
| 3 Nov 2026 | Reasons to come back planned as Sessions 35 to 40, after the graphics pass so Louis's Sessions 18 to 34 keep their numbers (replaces PR #7): gear shop with prices for 5-minute shifts, 5-star streak and personal bests, regulars' lines growing friendlier, choosing between two orders at 4.5+ stars, tomorrow's special, the 60-home stamp card and a final play-test before itch.io. No fear-of-missing-out mechanics. For Louis to confirm or cross out |
| 3 Nov 2026 | Detail pass planned (Sessions 35 to 46) after Louis's play-test of the graphics pass. Reasons to come back move to Sessions 47 to 51; their gear shop session is folded into the new bike shop |
| 3 Nov 2026 | Wahat Al Shams goes real size, about 940 by 500 m, copied from Louis's Google Earth view of the real community, and shifts become 8 minutes (48 s per in-game hour). The clock shows AM/PM in 10-minute steps |
| 3 Nov 2026 | Layout: highway on the west with 2 checkpoints (booth, barrier, one guard; bike rides through), mosque then bus station then a bigger Plaza in the north-west, Fair Grade School, the C Institute, the jumping arena and the stables in the south-west, the green spine through the middle, 3 clusters north and 2 south, solar car parks between clusters (not behind homes), building sites on the empty patches. The horse ring was dropped. Each shift starts in front of the bus station |
| 3 Nov 2026 | Homes are joined rows like the real ones: double rows back to back with a wall between, a lane on each side, the odd alley. 100 homes per cluster (90 courtyard, 8 garden, 2 signature), 500 in total, addresses "Villa 45, Cluster 1" |
| 3 Nov 2026 | Cars only on the ring road and car parks, buggies only on the lanes and spine paths. Horse track round the edge is dirt with white rails, horses only; a blue run and cycle track beside it |
| 3 Nov 2026 | 10 walk-in restaurants with their own fronts and insides: 1000 Pizza, Brain Freeze Gelato, Spill the Tea, Shawarma Supreme, Bread & Zaatar, Grand Groceries, Tok Tok Thai, Sushi You, Mario Bonito, Burgerology. Pick up by holding E at the counter |
| 3 Nov 2026 | Fair Grade International School copies the real school from Louis's photos. The C Institute (glass front and stepped seats facing the spine, walk-in lobby with a receptionist) is a drop-off. Gym (rounded at the back, lap pool beside it) and a separate community pool in the spine; gym reception is a drop-off |
| 3 Nov 2026 | Spine gets grass texture, flowers and gentle hills (0.5 to 1.5 m), and one path linking all the domes. Textures and props everywhere. Camera never goes inside houses. Heat shimmer removed. Top speed 28, sprint 36 km/h with stronger speed lines and wind sound. Fix people with no head and the glitchy dome doors |
| 3 Nov 2026 | Shops: Pedal Point Bikes (upgrades, stamina +10% buyable up to 10 times, aluminium then carbon frame, a 10,000 Dh rocket booster on X at Level 10, paint and box colours) and Dune Drip (clothes, try on in front of a mirror like GTA). Menu on the left while you stay in the 3D shop, with a cart and checkout. Same side-panel style at every walk-in place |
| 3 Nov 2026 | Clock correction requested by Michael: one real gameplay second equals one game minute, displayed minute by minute. Keep 8:00 AM–6:00 PM, deriving a 600-second (ten-minute) shift from the fixed rate. This supersedes the eight-minute / ten-minute-display-step choice. Pause, tutorial and delivery-result screens still freeze gameplay time; action timers retain their real-second units |
| 3 Nov 2026 | Michael requested distinct rider/bike fall animations before the hospital, based on the object, impact direction and force, plus treatment/repair and insured payments that vary with relative impact speed and obstacle hardness. Planned as 44A–44B; preserve first-crash cover and charge once per accident. Exact severity bands and prices need playtesting |
| 3 Nov 2026 | Browser distribution requested by Michael: publish the current game at fivestarshabibi.middleleap.com for Louis to test on MacBook and potentially iPad, with GitHub deployment and releases. Keep desktop Forward+; use Compatibility/Low for web and add landscape touch controls. Browser saves stay on each device. |
| 4 Nov 2026 | The old Palm Grove map is removed (scene, data, and the road, street-sign and park builders only it used). Wahat Al Shams is the only map; the flat test area stays for tests |
| 4 Nov 2026 | The game is released both on itch.io (Mac and Windows downloads) and in the browser at fivestarshabibi.middleleap.com. A crash "week" is 7 shifts, as the clinic screen already counts (CRASH_WEEK_SHIFTS) |
| 4 Nov 2026 | Opening the game no longer counts as a new shift: a shift you quit halfway through is played again (same number, same kind of day); only a finished shift counts. Your last accept / skip choices are saved, so the acceptance rate survives a restart |
| 4 Nov 2026 | Looks pass planned (Sessions 52 to 59) after Louis's play-test of the detail pass: anti-aliasing on every level, sharper shadows, auto-picked graphics level, no ground flicker, smaller and fuller interiors from free CC0 kits (KayKit, Kenney, Poly Pizza), a short queue of 1 or 2 people, glass shop fronts, sliding doors, indoor camera, sounds per place, a real gym, the C Institute turned to face the spine with glass on both sides and a changing talk screen, every walk-in place rebuilt from the approved designs, more detail in the Plaza, streets and spine (grass blades, sparser on Low), and fixes for the crash loop and crashes costing too little |
| 5 Nov 2026 | Road plan approved (docs/road_plan_2026-11-05.svg): the ring road is the only main road and connects only to the two gates, the bus station loop and the stables car park (plus the car park entrances); the inside roads form one connected, rounded network with a roundabout east of the C Institute and no dead ends |
| 5 Nov 2026 | Red walking tracks only along the spine road, both sides behind a planter; buggies can't use them |
| 5 Nov 2026 | Cluster lanes are asphalt with a front and back cross road; only the front links out; Cluster 3 moves 10 m west and Clusters 4 and 5 move 6 m north to keep a margin from the ring road |
| 5 Nov 2026 | All roads get a yellow dashed centre line and direction arrows (drive on the right); tyre marks removed |
| 5 Nov 2026 | New: stables car park, school car park, Majlis Gardens, football pitch with floodlights replacing the tennis and basketball courts |
| 5 Nov 2026 | Cluster signs copy the real green SIKKA signs ("Cluster N"); a made-up "5-Star Habibi Police" sign; people dressed for each place; customers walk home instead of vanishing |
| 5 Nov 2026 | Beekeeper becomes a pickup (honey jars, candles); new horses and donkeys and rounded playgrounds made with Blender scripts; full map on M; resolution setting |
| 5 Nov 2026 | World polish pass numbered Sessions 60 to 74; Session 60 (roads) built before looks Sessions 53 to 59 |
| 5 Nov 2026 | Parked for later: a delivery robot upgrade, and whether the desktop download becomes the main version |
| 5 Nov 2026 | Session 61: the ring road's corners are rounded (12 m) and traffic follows them; the roundabout is one-way anticlockwise; kerbs are low and only for looks (except the spine's red-track kerb); a hard brake leaves a short faint skid mark that fades after about 10 s |
| 5 Nov 2026 | Session 62: the spine road has a planter and a red walking track on both sides with crossing gaps; the Domes Path is removed (the north red track passes the domes); the C Institute's stepped seats face outwards |
| 5 Nov 2026 | Session 63: the ground is grass and the clusters are paved; sand only at the stables, jumping arena and horse track. The blue and horse tracks have rounded corners matching the ring road; greenery between the ring road and the blue track; dunes and far-off towers past the fence |
| 5 Nov 2026 | Session 64: the bus station platform is a raised island inside the bus loop with two glass shelters facing the bay; 3 to 5 people wait and get on when a bus stops (the bus waits for them) |
| 5 Nov 2026 | Session 65: one cluster sign per cluster at its entrance (green board, pale blue frame, ranges "Villa 1–50" / "Villa 51–100" with arrows, EXIT), a made-up "5-Star Habibi Police" sign there and along the red tracks, small STOP (قف) signs; bins at the back of each cluster; the community pool is fenced with its gate on the red-track side and the pool sign beside the gate; big end houses where rows stop 10 m short of a road are scenery, not addresses |
| 5 Nov 2026 | Session 66: Majlis Gardens fills the strip between the C1-west car park and Cluster 1 (fountain plaza, palms, a shaded majlis with low sofas, benches, a community garden bed, paver paths to the lanes, car park and spine loop road, people using it); the phase 3 site south of the mosque has the same fence, crane, containers, workers and a "Phase 3 coming soon" sign as phase 2 |

## Sources

Wahat Al Shams layout and houses (the idea only, every name in the game is made up):

- [Sustainable City masterplan, Urbanitarian](https://urbanitarian.com/masterplans_post?id=378)
- [Project profile: The Sustainable City, Middle East Construction News](https://meconstructionnews.com/?p=21952)
- [Beyond oil: Inside Dubai's Sustainable City, New Atlas](https://newatlas.com/beyond-oil-dubai-sustainable-city/57441)
- [Green and gated, Gulf Construction](https://gulfconstructiononline.com/Article/378864/Green_and_gated)
- [Sustainable Plaza streetscape, Urbanitarian](https://urbanitarian.com/streetscapes_post?id=18)

Detail pass (the real community, the school and the restaurants; every name in the game is made up):

- [Sustainable City restaurants guide, The Dubai Fork](https://wheretoeatdubai.pages.dev/blog/sustainable-city-restaurants-dubai-2026)
- [Fairgreen International School campus and facilities, edcare](https://edcare.ae/schools/fairgreen-international-school/campus)
- [Sanad Village, Gulf News](https://gulfnews.com/uae/sanad-village-in-dubai-sets-new-global-standard-for-people-of-determination-1.78778336)
- [Inside Dubai's Sustainable City: facilities list, Gulf News](https://gulfnews.com/uae/inside-dubais-sustainable-city-community-what-makes-it-different-1.91842975)
- Louis's own Google Earth measurements and photos of the community, the school and the gym (not stored in the repo)

Looks pass (free CC0 kits and interior ideas):

- [KayKit Restaurant Bits (CC0)](https://kaylousberg.itch.io/restaurant-bits)
- [KayKit Furniture Bits (CC0)](https://kaylousberg.itch.io/furniture-bits)
- [Kenney Furniture Kit (CC0)](https://kenney.nl/assets/furniture-kit)
- [Kenney Food Kit (CC0)](https://kenney.nl/assets/food-kit)
- [Low poly Supermarket pack (CC0)](https://pensamientoazul.itch.io/supermarket-3d-assets)
- [Small café layout ideas, Bellwether Coffee](https://bellwethercoffee.com/blog/small-cafe-layout-design-guide)

Licence tests:

- [How to get a motorcycle licence in Dubai, Property Finder](https://www.propertyfinder.ae/blog/dubai-motorcycle-licence)
- [How to prepare for the UAE motorcycle test, theorytest.ae](https://www.theorytest.ae/?p=15359)
- [Dubai motorcycle rider's licence explained, Khaleej Times](https://www.khaleejtimes.com/life-and-living/dubai-how-to-get-a-motorcycle-riders-licence-requirements-eligibility-explained)
- [How many questions are in the RTA theory test, ezhire](https://www.ezhire.ae/blog/how-many-questions-in-rta-theory-test-in-dubai)
