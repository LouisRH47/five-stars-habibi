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
