class_name ChatLines
## Data only: what people write to you in the phone's Messages app (Session 89).
## scripts/chat_feed.gd picks the lines. {name} is swapped for your name, {company} for
## your company's name. Keep them short: they show in a chat bubble.

## Each regular's round picture in the chat list: a letter on a soft colour.
## The keys are the "id"s in REGULARS (data/wahat_al_shams.gd).
const REGULAR_FACES := {
	"mariam": {"face": "M", "colour": Color("#b9e4c9")},
	"rashid": {"face": "R", "colour": Color("#e7d3b0")},
	"dana": {"face": "D", "colour": Color("#f6c9d5")},
	"hamdan": {"face": "H", "colour": Color("#d9e7ee")},
}

## What a regular writes after you deliver to them. "good": 4 stars or more, "meh": less.
const REGULAR_THANKS := {
	"mariam": {
		"good": ["Thank you dear, still cold!", "The pearls were perfect, {name}. Shukran!", "You're a star, habibi. Drink water today!"],
		"meh": ["It came, {name}. A bit warm, but you tried.", "Shukran habibi. Next time maybe a little faster?"],
	},
	"rashid": {
		"good": ["Extra garlic next time, {name}!", "Hot and on time. Good man.", "My sons ate half before I sat down. Shukran!"],
		"meh": ["Got it. A bit squashed, but it tastes the same.", "Thanks, {name}. The traffic was bad today, no?"],
	},
	"dana": {
		"good": ["The class loved the cake!", "Gold star for you, {name}!", "Not one crumb out of place. Thank you!"],
		"meh": ["The cake had a little adventure, but thank you!", "Thanks, {name}. The kids didn't notice the bump."],
	},
	"hamdan": {
		"good": ["Cold juice, happy horses. Shukran!", "Come ride the horses one day, {name}.", "Perfect, my friend. The foal says hi."],
		"meh": ["Shukran, {name}. A bit warm, but the horses don't mind.", "It made it! Mind the hay next time."],
	},
}

## The reply buttons under a regular's thank-you. You tap one; you never type.
const REGULAR_REPLIES := ["Anytime, habibi!", "Thanks! See you soon.", "Glad you liked it!"]

## Your boss. {company} is the company you ride for now.
const BOSS_FACE_COLOUR := Color("#0f4c5c")
const BOSS_WELCOME := "Welcome to {company}, {name}! Ride safe, be kind at the door, and the stars will come. I'll message you after each shift."
const BOSS_SHIFT_NOTES := {
	"none": "Shift %d done. No deliveries today? Tomorrow is a new day, {name}.",
	"great": "Shift %d: %s at %.1f stars. Excellent work, keep it up!",
	"good": "Shift %d: %s at %.1f stars. Good shift, {name}.",
	"low": "Shift %d: %s at %.1f stars. Careful on the bumps tomorrow, okay?",
}

## Plaza news: the Plaza's notice board, as a chat.
const NEWS_NAME := "Plaza news"
const NEWS_FACE := "P"
const NEWS_COLOUR := Color("#f28c28")
