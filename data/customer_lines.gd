class_name CustomerLines
## Data only: what customers say when they open the door (Session 11).
## scripts/customer_spawner.gd picks one at random for each delivery.
## {name} is swapped for the rider's name (from the application in Session 14;
## until then it says "habibi").
## Add, change or remove lines here. Keep them short: they show in a speech bubble.

const LINES := [
	"Thanks, {name}! You're a legend!",
	"Finally! I was about to eat the sofa.",
	"Is it still hot? Don't answer, I'll find out.",
	"Five stars if the fries survived!",
	"You rode a bike in this heat? Respect!",
	"My cat says thank you too.",
	"Perfect timing, the match just started!",
	"Did you pick the extra sauce? Please say yes.",
	"Mama, the food is here!",
	"Is this mine? It smells like mine.",
	"Wow, faster than my internet!",
	"I ordered this 20 minutes ago. Or was it a dream?",
	"You're my favourite rider. Don't tell the others.",
	"Quick, before my brother sees it!",
	"Shh, I'm on a diet. You saw nothing.",
	"Thanks! Mind the speed bumps on the way back.",
	"Best part of my day, honestly.",
	"Hold on, let me find my slippers... never mind!",
	"Habibi, you're a hero!",
	"{name}! My favourite rider is back!",
	"Thank you, {name}. Drink some water, it's hot out there!",
	"Ice cold, just how I like it. Wait, is this pizza?",
]

## The 4 regular customers' own lines (Session 32). They know you, so every line has {name}.
## The keys are the "id"s in REGULARS (data/wahat_al_shams.gd).
const REGULAR_LINES := {
	"mariam": [
		"{name}, habibi! Extra pearls again? You spoil me.",
		"Ahh, {name}! Come, have a date, you look tired.",
		"My favourite, {name}! Say hello to your mother for me.",
	],
	"rashid": [
		"{name}! Right on time, as always.",
		"Good man, {name}. Garlic sauce inside? Excellent.",
		"{name}, you're faster than my sons. Don't tell them.",
	],
	"dana": [
		"{name}! The staff room will love this cake.",
		"Thank you, {name}! Ten out of ten, gold star.",
		"{name}, you're never late. My class could learn from you.",
	],
	"hamdan": [
		"{name}! The horses say thank you too.",
		"Cold juice in this heat? You're a hero, {name}.",
		"Yalla, {name}, come see the new foal one day!",
	],
}
## What a teacher, a kid, a rider or a groom says at the school or stables (Session 32).
const SPOT_LINES := {
	"institute": ["Thanks, {name}! Reception will take it from here.", "Perfect timing, {name}. Our students needed a study break."],
	"gym": ["Thanks, {name}! Refuelling counts as training, right?", "Nice ride, {name}! That delivery was your cardio for the day."],
	"teacher": ["Thanks, {name}! Just in time for the break.", "Lovely! The kids are so loud today."],
	"kid": ["Yes! My lunch! Thanks, {name}!", "Don't tell my teacher it's ice cream."],
	"rider": ["Thanks! Hungry work, riding horses.", "Perfect, {name}, I've just finished my lesson."],
	"groom": ["Shukran, {name}! The horses are jealous.", "Thanks! Mind the hay on your way out."],
}

## Visits 1–2, 3–7 and 8+ have distinct dialogue: familiarity is earned in play.
const REGULAR_STAGES := {
	"mariam": {
		"first": ["Shukran, {name}. I'm Mariam. Extra pearls, please!", "First time here, {name}? Mind my cat on your way out."],
		"friendly": ["{name}, habibi! You remembered my extra pearls.", "Three visits already, {name}! Come, take a date for the road."],
		"best_friends": ["My favourite rider, {name}! There's always a seat for you here.", "{name}, you're family now. I saved you the best dates."],
	},
	"rashid": {
		"first": ["You must be {name}. I'm Rashid. Garlic sauce inside?", "Shukran, {name}. The gate sticks, give it a little push."],
		"friendly": ["{name}! I know that orange bag anywhere.", "Back again, {name}! You know my usual better than my sons."],
		"best_friends": ["My friend {name}! Stay for the match when your shift is over.", "{name}, a tip for you. Don't tell my sons you're my favourite."],
	},
	"dana": {
		"first": ["Hello, {name}! I'm Ms Dana. The staff room is this way.", "Thank you, {name}. I hope the cake survived those bumps."],
		"friendly": ["{name}! The class recognised your bike before I did.", "Gold star, {name}! You're becoming part of our lunch break."],
		"best_friends": ["Our honorary teacher, {name}! The children made you a thank-you card.", "{name}, we saved you a slice. Best delivery friend in the school!"],
	},
	"hamdan": {
		"first": ["Welcome, {name}. I'm Hamdan. Mind the hay by the office.", "Shukran, {name}! Hungry work, looking after horses."],
		"friendly": ["{name}! Even the horses recognise your bell now.", "Good to see you, {name}. Come meet the new foal sometime."],
		"best_friends": ["Yalla, {name}! Your favourite horse has been waiting for you.", "My friend {name}! There's always a cold juice here for you."],
	},
}
