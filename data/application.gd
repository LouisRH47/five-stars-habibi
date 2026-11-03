class_name ApplicationData
## Data only: the choices on the Snackaroo rider application (Session 14).
## scripts/application.gd shows them. Change the lists here.

## "Where are you from?" It only shows on your rider profile (the phone).
const COUNTRIES := [
	"United Arab Emirates", "Saudi Arabia", "Oman", "Qatar", "Bahrain", "Kuwait",
	"Egypt", "Jordan", "Lebanon", "Morocco", "Tunisia", "Sudan",
	"India", "Pakistan", "Bangladesh", "Sri Lanka", "Nepal", "Philippines", "Indonesia",
	"Kenya", "Nigeria", "Ethiopia", "Uganda",
	"United Kingdom", "Ireland", "France", "Germany", "Denmark", "Italy", "Spain",
	"Russia", "Ukraine", "Turkey", "Iran",
	"United States", "Canada", "Brazil", "Mexico",
	"China", "Japan", "South Korea", "Australia",
	"Somewhere else",
]

## The 3 looks (PRD "3 character presets"). All three ride the same; only the look changes.
## scripts/rider_look.gd builds them on the bike's rider.
const LOOKS := [
	{"name": "Classic", "about": "Cap, hoodie and a backpack"},
	{"name": "Sporty", "about": "Helmet with stickers, sports top"},
	{"name": "Chill", "about": "Bucket hat, sunglasses, shorts"},
]
