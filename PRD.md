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
- Tier 1 happens in Wahat Al Shams, a made-up car-free eco community with a Plaza, a green park through the middle, 5 clusters of homes, a school and stables. Shifts are 5 minutes.

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
- **Crashing a lot:** 3 big crashes within 5 shifts sends you down a tier, and you have to retake that tier's test (100 Dh retake).
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
- From the graphics pass: shawarma, cake, groceries and farm juice/salad too (see "Wahat Al Shams" in the city map section)

**Shifts**

- One shift is 5 real minutes (one in-game day, 08:00 to 18:00, so one in-game hour is 30 seconds). It ends with a golden sunset. Tier 1 is day shift only. Night shifts unlock at Tier 2.
- If the clock runs out while you're carrying an order, you still finish that delivery. The shift ends right after you drop it off. No new orders pop up once the clock is out.
- At the end you get a summary screen: deliveries, stars, money earned, XP.

**Bicycle stamina:** sprinting drains a stamina bar and coasting refills it, so you can't hold sprint forever. The motorbike doesn't have this.

**Running costs:** none in Tier 1. Fuel and repairs start with the motorbike. The only Tier 1 costs are crash bills and the optional insurance (see the next section).

**Finding the address**

- Every villa has a readable house number.
- A mini-map in the bottom left shows the exact drop-off spot and the villa number.
- Some orders come with notes, like "leave it at the door" or, in Downtown, "leave it in the lobby".
- A GPS line on the road is a cheap upgrade you buy, not there from the start.

**Customers at the door:** the customer comes out with a short animation and one line of speech. Some ask you to leave it at the door. More customer types get added later.

## Special orders, goals and events (graphics pass)

These stop deliveries from feeling the same after a few. All numbers are starting ideas and live in game_config.gd.

**Special orders** (about 1 in 6 orders, never two at once, shown with a coloured chip on the phone)

| Order | What's different | Reward |
| --- | --- | --- |
| Rush | Target time is 70% of normal | +50% pay |
| Fragile cake | From Sunrise Bakery. Bumps do double damage | Tip chance 60% instead of 40% on 5 stars |
| Neighbour | When you get to the door: "Not home! Leave it with the neighbour at Villa X" (a home in the same cluster). The clock keeps running | Normal pay, +5 Dh |
| Big family order | Two bags on the bike: top speed 15% lower and steering a bit wobblier | Double pay |

**School orders:** teachers and kids order to the school, always to the security booth at the main gate. They only come in between 08:00 and 15:00 on the shift clock. Lunch rush from 11:30 to 12:30: about 1 in 3 orders is for the school.

**Stables orders:** riders and grooms order to the stable office. Horses in the paddock are just for looking at.

**Farm orders:** about 1 in 8 orders is picked up at the Wahat Farm Stall in the green spine instead of the Plaza.

**Regular customers:** 4 regulars who order more often than anyone else, have a heart on the phone and say your name. Their tip chance is 60%. Starting list:

| Regular | Where | Usually orders |
| --- | --- | --- |
| Auntie Mariam | Villa 7, Cluster 2 | Bubble tea |
| Mr Rashid | Villa 3, Cluster 5 | Shawarma |
| Ms Dana (teacher) | School gate | Cake from Sunrise Bakery |
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
- **Light:** the sun moves with the shift clock: low and warm in the morning, high and white at noon, a golden sunset from 17:00. Soft shadows in corners (SSAO), a light haze towards the desert, a gentle glow on bright things, and heat shimmer above the roads at noon.
- **Juice:** dust puffs from the tyres on sand and when braking hard, speed lines and a wider camera when sprinting, coin and star pops when you deliver, and the phone buzzes (shakes with a sound) when a new order comes in.
- **Life on the map:** golf buggies driving slowly on fixed routes (they stop and wait if you're in the way), horses with riders on the edge track, joggers and walkers, gardeners watering, kids at the cluster playgrounds, birds flying over, palms swaying, the stream and fountain moving, ducks on the stream and donkeys in the spine. No real traffic AI until Tier 2.
- **Graphics setting:** Low, Medium (default) or High in Settings. Low turns off SSAO, shimmer and haze and shows fewer people; High shows everything.

## Crashes, bills and insurance

Crashing costs you, and insurance is an optional bet. Prices are scaled down from real Dubai costs so they fit game pay.

**Small crash vs big crash**

- **Small crash:** a low-speed hit or wipeout. You fall off, the damage meter takes a big hit (bad for your rating), and you get back on after about 2 seconds.
- **Big crash:** hitting a car, wall or pole above about 20 km/h on the bicycle (higher limits for faster vehicles). The screen fades out and you wake up at the clinic. The order is cancelled (0 stars, no pay), the bills pop up, and your shift ends.

**Big crash bills**

| Tier | Hospital bill | Repair bill (from the delivery company) | With insurance you only pay |
| --- | --- | --- | --- |
| Bicycle | 150 Dh | 80 Dh | 20 Dh |
| Motorbike | 400 Dh | 300 Dh | 50 Dh |
| Taxi tiers | 800 Dh | 1,500 Dh+ | 150 Dh |

One uninsured big crash on the bicycle costs about 20 deliveries of pay. That is too harsh for someone still learning the bike, so:

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

Restaurants get funny made-up names too, like Shawarma Supreme, Brain Freeze Gelato and Boba Oasis.

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

**Wahat Al Shams, the Tier 1 community (replaces Palm Grove)**

Wahat Al Shams (واحة الشمس, "Sun Oasis") is a made-up eco community. Its layout copies the idea of a real car-free eco community in Dubai (see Sources), scaled down for the game and with every name made up. The old Palm Grove map stays as a test map until Wahat Al Shams works, then it's removed. Built from a data list (data/wahat_al_shams.gd) plus builder scripts, like Palm Grove.

*Layout (about 400 m east to west, 300 m north to south). Map sketch: docs/wahat_al_shams_map.svg. House sketch: docs/villa_types.svg.*

| Part | Where | What's there |
| --- | --- | --- |
| Tree belt and horse track | All the way round the edge | A thick belt of tall trees, with a sandy horse track and a bike track inside it. Riders on horses use it. You can ride the bike track |
| Ring road | Inside the tree belt | The only road for cars. Parked cars and golf buggies only, no traffic driving around in Tier 1 |
| Main gate | Middle of the west side | Gate house with a barrier and a big bilingual "Welcome to Wahat Al Shams" sign |
| The Plaza | Just inside the gate | The hub. A sunken round square in the middle (steps down, a fountain, date palms, shade sails, benches) with 6 shops around it (see below). Every order is picked up here, except farm orders |
| Green spine | Through the middle, west to east | A long park: a winding stream, 6 white dome greenhouses, farm beds, beehives, donkeys in a pen, a basketball court and a playground. Paths through it are the main shortcut for the bike. The Farm Stall by the domes is the 7th pickup spot |
| 5 clusters | 3 north of the spine (C1, C2, C3), 2 south (C4, C5) | 12 homes each, 60 in total. No cars inside. Narrow shady lanes (about 4 m wide) for bikes, people and buggies. A mini-plaza in the middle of each cluster with a cooling tower, a small playground and benches |
| Solar car parks | On the ring road next to each cluster | Car bays under a roof of solar panels. No door is more than about 40 m from its car park. Bollards stop cars going into the clusters |
| School | South side, east of C5 | Al Shams School, a low building with a fenced yard. Orders go to one spot only: the security booth at the main gate |
| Mosque | South side, between C5 and the school | A mosque with a minaret. Scenery only: no orders ever go there |
| Stables | East end of the spine | Stable block, a paddock with horses you can stop and watch, and a small office. Orders go to one spot only: the stable office |
| Building site | South-east corner | A fenced plot with a crane and a "Phase 2 coming soon" sign. Scenery and a landmark for addresses |

*Addresses:* homes are numbered 1 to 12 inside each cluster, so an address reads "Villa 7, Cluster 3" (phone and mini-map: "C3 · Villa 7"). Each cluster has a bilingual sign at both lane entrances.

*The houses:* one style for the whole community, built in code from our own kit of parts (no free pack has houses like these). Cream or sand walls, two storeys, L-shaped, flat roof with a roof terrace shaded by tilted solar panels, a small wind tower (barjeel), small deep windows, a wooden door and a low courtyard wall. Three types, as in the real place:

| Type | Per cluster | Look |
| --- | --- | --- |
| Courtyard villa | 10 | The normal L-shaped home with a small walled courtyard |
| Garden villa | 1 | Same house with a big lawn and a tree |
| Signature villa | 1 | Bigger corner home with a wooden mashrabiya screen on the front |

To make every home easy to tell apart: door colour, plants, a golf buggy or bikes outside, toys, AC units, a satellite dish, and on garden and signature villas a small pool or a trampoline. Picked from the villa's number so it's always the same.

*The 6 Plaza shops plus the Farm Stall (pickup spots):*

| Shop | Arabic sign | Food | What the food cares about |
| --- | --- | --- | --- |
| Pizza | بيتزا | Pizza | Easy |
| Brain Freeze Gelato | برين فريز جيلاتو | Ice cream | Melts fast |
| Boba Oasis | واحة البوبا | Bubble tea | Spills on bumps |
| Shawarma Supreme | شاورما سوبريم | Shawarma | Goes cold, medium |
| Sunrise Bakery | مخبز الشروق | Cake | Breaks on bumps (fragile) |
| Al Sarab Mini Market | ميني ماركت السراب | Groceries bag | Slow to spoil, bit heavy |
| Wahat Farm Stall | كشك مزرعة الواحة | Fresh juice and salad box | Spoils in the sun |

*Drop-off spots:* the 60 home doors, the school gate booth and the stable office. Never the mosque or the shops.

*Who orders:* residents (the 5 outfits we have), teachers (lanyard, folder) and school kids (uniform) at the school, riders and grooms (riding helmet, boots) at the stables.

*Obstacles:* speed bumps on the ring road, the loose cats and the kids on scooters (now also in the cluster lanes and mini-plazas), golf buggies, and horses when they cross.

*Size:* the bike can cut through the spine, so most rides are 30 to 60 seconds and the far corners about 90 seconds.

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
9. **Motorbike test:** yard course, instructor, theory quiz, fail and retake rules.
10. **Tier 2 and beyond:** motorbike, Old Town, then the next tiers one by one.

## Still open

- Final name (Five Stars Habibi for now, might change later)
- Tuning all pay, bills and insurance numbers once Tier 1 is playable
- Whether the motorbike can carry several orders at once, later on
- Exact keys for the taxi requests
- Pay for the new foods, special orders and goal bonuses: starting ideas are in the PRD, tune them after the graphics pass play-test

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

## Sources

Wahat Al Shams layout and houses (the idea only, every name in the game is made up):

- [Sustainable City masterplan, Urbanitarian](https://urbanitarian.com/masterplans_post?id=378)
- [Project profile: The Sustainable City, Middle East Construction News](https://meconstructionnews.com/?p=21952)
- [Beyond oil: Inside Dubai's Sustainable City, New Atlas](https://newatlas.com/beyond-oil-dubai-sustainable-city/57441)
- [Green and gated, Gulf Construction](https://gulfconstructiononline.com/Article/378864/Green_and_gated)
- [Sustainable Plaza streetscape, Urbanitarian](https://urbanitarian.com/streetscapes_post?id=18)

Licence tests:

- [How to get a motorcycle licence in Dubai, Property Finder](https://www.propertyfinder.ae/blog/dubai-motorcycle-licence)
- [How to prepare for the UAE motorcycle test, theorytest.ae](https://www.theorytest.ae/?p=15359)
- [Dubai motorcycle rider's licence explained, Khaleej Times](https://www.khaleejtimes.com/life-and-living/dubai-how-to-get-a-motorcycle-riders-licence-requirements-eligibility-explained)
- [How many questions are in the RTA theory test, ezhire](https://www.ezhire.ae/blog/how-many-questions-in-rta-theory-test-in-dubai)
