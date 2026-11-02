# Five Stars Habibi: PRD (Game Design)

*Working name. Subtitle: Rider to Driver.*

This is the product requirements document: **what** the game is and how it works. It's the one true copy of the design. If something changes, update this file first (and add a line to the Decisions log at the bottom), then build it. The older copy on claude.ai is out of date.

**Mockup:** [Five Stars Habibi Mockup](https://claude.ai/artifact/8vzJizBsB69zJsuSEuWmS4) shows the gameplay HUD, the rider application, a finished delivery and the big crash screen. Use it as the look to aim for: sunny desert colours (sand, teal, orange), rounded fonts, low-poly 3D.

## Overview

Five Stars Habibi is a job-sim driving game set in Al Sarab, a made-up desert city with Dubai vibes. You start delivering food on a bicycle in one small community and climb a career ladder all the way to a luxury chauffeur service.

- **Built with:** Claude Code, in Godot 4 (GDScript). 3D, with the camera behind the rider. A Roblox port might come later.
- **First playable version:** Tier 1 only (bicycle deliveries around one villa community).
- **Big rule:** plan the whole ladder, but build one tier at a time. Don't start Tier 2 until Tier 1 is fun.

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

## The career ladder

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

- **Bad ratings:** if your average over your last 30 deliveries drops below your tier's minimum, you get a warning. Still below after 10 more deliveries means you go down a tier.
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
2. Accept it (or skip it, but skipping too many hurts your acceptance rate).
3. Ride to the restaurant and pick up the food.
4. Ride to the customer's villa. The meters start ticking.
5. Drop it off at the door, then you get stars, pay and maybe a tip.

**The three meters**

| Meter | What drains it | Food that cares most |
| --- | --- | --- |
| Time | Every second after pickup | Everything |
| Heat | Time in the sun (faster on the day shift) | Ice cream, cold drinks, hot coffee |
| Damage | Bumps, crashes, kerbs, hard braking | Cake, drinks, soup |

**Stars (1 to 5)**

- All three meters green = 5 stars. Each meter in the red takes off stars.
- Your rating is the average of your last 50 deliveries, so one bad run doesn't ruin you.
- Higher rating = better orders show up more often.

**Money**

- Base pay per delivery, plus a little extra for distance.
- **Tips:** only possible on 5-star deliveries, and not every time. Starting idea: a 40% chance of a tip between 2 and 15 Dh (scales up with tier).
- Money buys tests, vehicles and gear.

**XP**

- Every delivery gives XP. Higher-tier jobs give more.
- Doing jobs from a lower tier gives less money and less XP (starting idea: 50% of normal).

**Tier 1 food types (first version)**

- Pizza: easy, good for the tutorial
- Ice cream: melts fast
- Bubble tea: spills on bumps

**Shifts**

- One shift is about 10 real minutes (one in-game day). Tier 1 is day shift only. Night shifts unlock at Tier 2.
- At the end you get a summary screen: deliveries, stars, money earned, XP.

**Bicycle stamina:** sprinting drains a stamina bar and coasting refills it, so you can't hold sprint forever. The motorbike doesn't have this.

**Running costs:** none in Tier 1. Fuel and repairs start with the motorbike. The only Tier 1 costs are crash bills and the optional insurance (see the next section).

**Finding the address**

- Every villa has a readable house number.
- A mini-map in the bottom left shows the exact drop-off spot and the villa number.
- Some orders come with notes, like "leave it at the door" or, in Downtown, "leave it in the lobby".
- A GPS line on the road is a cheap upgrade you buy, not there from the start.

**Customers at the door:** the customer comes out with a short animation and one line of speech. Some ask you to leave it at the door. More customer types get added later.

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

One uninsured big crash on the bicycle costs about 20 deliveries of pay.

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

## The motorbike test (Tier 1 to Tier 2)

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

## Taxi tiers (4 to 6)

Taxis swap food for passengers but keep the same three-meter idea, so players already know how it works. Passengers ask for things mid-ride and you respond with keys while you keep driving.

**Passenger meters**

| Meter | Food version | What drains it |
| --- | --- | --- |
| Time | Time | Slow routes, getting lost |
| Comfort | Damage | Hard braking, sharp turns, bumps, crashes |
| Mood | Heat | Ignoring requests, wrong AC, bad music, a hot car |

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
| Palm Grove (home community) | Tier 1 | Quiet villas, palm trees, speed bumps | Gate codes, dogs, kids playing in the street |
| Other villa communities | Tier 2 | Bigger, longer roads | Security gate checks |
| Old Town | Tier 2 | Narrow alleys, markets | Shortcuts, potholes, tight turns |
| Marina | Tier 3 | Towers by the water, windy | Wind pushes you, nice tips |
| Downtown | Tier 3 | Skyscrapers, traffic jams | Lifts to high floors eat your time, and notes like "leave it in the lobby" |
| Highway and airport | Tier 4 | Fast roads, terminals | Fast travel, airport pickups |

**Palm Grove, the Tier 1 map**

- Around 25 to 40 villas with house numbers you can read.
- A small strip of 3 restaurants at the community entrance (pizza, ice cream, bubble tea).
- A park, a mosque, a small supermarket and a roundabout or two to make it feel real.
- Speed bumps, a few loose cats and kids on scooters as obstacles.
- Small enough to learn in 10 minutes, big enough that some deliveries take 2 to 3 minutes.

**Language and signs:** the game itself (menus, phone, customers) is in English only. Signs on buildings, shops, restaurants and roads show both Arabic and English, like real signs in Dubai.

**Music:** chill Arabic-style background music, the kind you'd hear in a cafe or a taxi here. Only music that's free to use (CC0 or properly credited).

## Milestones

Build it in milestones and play-test at the end of each one. Only move on when the current milestone feels good. The exact sessions are in BUILD_PLAN.md.

1. **Bike feel:** a bicycle you can ride around a flat test area.
2. **Palm Grove map:** villas with house numbers, roads, the restaurant strip, a few obstacles.
3. **One full delivery:** phone order, pickup, drop-off, pay. No meters yet.
4. **Meters and stars:** time, heat and damage, plus the star score at the end.
5. **Money, tips and XP:** wallet, random tips on 5-star jobs, XP bar.
6. **Start screen:** application form and the 3 presets.
7. **Polish Tier 1:** sounds, music, a day shift, a basic menu and saving your progress.
8. **Motorbike test:** yard course, instructor, theory quiz, fail and retake rules.
9. **Tier 2 and beyond:** motorbike, Old Town, then the next tiers one by one.

## Still open

- Final name (Five Stars Habibi for now, might change later)
- Tuning all pay, bills and insurance numbers once Tier 1 is playable
- Whether the motorbike can carry several orders at once, later on
- Exact keys for the taxi requests

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

## Sources

- [How to get a motorcycle licence in Dubai, Property Finder](https://www.propertyfinder.ae/blog/dubai-motorcycle-licence)
- [How to prepare for the UAE motorcycle test, theorytest.ae](https://www.theorytest.ae/?p=15359)
- [Dubai motorcycle rider's licence explained, Khaleej Times](https://www.khaleejtimes.com/life-and-living/dubai-how-to-get-a-motorcycle-riders-licence-requirements-eligibility-explained)
- [How many questions are in the RTA theory test, ezhire](https://www.ezhire.ae/blog/how-many-questions-in-rta-theory-test-in-dubai)
