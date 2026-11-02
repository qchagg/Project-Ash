class_name Events
extends RefCounted
## What can happen at a wayside stop: a short scene, two or three choices, a one-line outcome. See design/events.md.
##
## `road` is a road's key, or "any" for the shared pool. `rare` events turn up a third as often.
## A choice has `text`, and how it resolves:
##   do    an outcome, as written.
##   pay   a cost in purses (Expedition.PURSE.wayside), or `half` for half the gold in hand, paid first.
##   roll  an aptitude: the player picks a hero, who rolls for `win` or `lose`.
##   luck  true: even odds of `win` or `lose`, with no hero.
##   hero  a hero's key: only offered with them standing.
##   needs "fallen": offered once for each fallen hero, whose name fills `text`.
## An outcome has `say`, and any of:
##   gold (purses; the stop's rarity lifts what you gain), heal (the squad), hurt (the hero who rolled), hurt_all,
##   boon (a key of Expedition.BOONS, at the stop's rarity, `up` steps better), augment, rerolls, fight (a kind of
##   fight), raise (health the fallen hero gets back), loan ([purses now, purses owed when the run banks]).
## The last choice always costs nothing and risks nothing, so nothing here can trap the player.

const LIST := {
	# ---------- The Basalt Steps ----------
	"unfinished_stair": {"road": "basalt", "title": "the unfinished stair",
		"scene": "A golem sets a step, lifts it out, and sets it again. Nobody has told it the stair is finished. Nobody is left to.",
		"choices": [
			{"text": "Take the other end", "roll": "might",
				"win": {"say": "It sets the stone once.", "boon": "bulwark"},
				"lose": {"say": "The stone is heavier than it looks.", "hurt": 0.15}},
			{"text": "Tell it the work is done", "roll": "charm",
				"win": {"say": "It looks at its hands, then gives you its wages.", "gold": 2.0},
				"lose": {"say": "It disagrees.", "fight": "battle"}},
			{"text": "Basalt lifts it alone", "hero": "rock",
				"do": {"say": "Neither of them says anything.", "boon": "bulwark", "up": 1}},
			{"text": "Walk on", "do": {"say": "Behind you: set, lift, set."}}]},
	"warm_water": {"road": "basalt", "title": "the warm water",
		"scene": "A skald sits in a hot spring up to her chin. She offers praise at a fair price, and mockery for free.",
		"choices": [
			{"text": "Pay for a verse", "pay": 1.0,
				"do": {"say": "You had no idea you were this brave.", "boon": "whetstone"}},
			{"text": "Correct her metre", "roll": "wits",
				"win": {"say": "She laughs until the water moves.", "boon": "whetstone"},
				"lose": {"say": "That one will follow you home.", "hurt": 0.10}},
			{"text": "Just get in", "do": {"say": "She doesn't look up.", "heal": 0.15}}]},
	"gate_without_wall": {"road": "basalt", "title": "a gate with no wall",
		"scene": "A stone gate stands alone in the lava field. Its keeper asks for the password. There is plenty of room to walk round.",
		"choices": [
			{"text": "Give the old password", "roll": "lore",
				"win": {"say": "It steps aside. It had been hoping someone would.", "boon": "heartwood"},
				"lose": {"say": "It corrects you, firmly.", "hurt": 0.10}},
			{"text": "Knock it down", "roll": "might",
				"win": {"say": "There was a strongbox in the lintel.", "gold": 2.0},
				"lose": {"say": "The gate had been waiting for this.", "fight": "battle"}},
			{"text": "Walk round it", "do": {"say": "It watches you do it. You feel rude."}}]},

	# ---------- The Aqueduct ----------
	"lamp_upstream": {"road": "lotus", "rare": true, "title": "a lamp going upstream",
		"scene": "One lotus lamp is moving against the water. It stops in front of you, and waits to be given a name.",
		"choices": [
			{"text": "Give it the name %s", "needs": "fallen", "half": true,
				"do": {"say": "The lamp goes on without you. Someone stands up behind you.", "raise": 0.30}},
			{"text": "Light yours from it", "do": {"say": "It doesn't get any smaller.", "heal": 0.15}},
			{"text": "Let it pass", "do": {"say": "It goes on without you. It knows the way."}}]},
	"rain_on_clay": {"road": "lotus", "title": "rain on clay",
		"scene": "There's a perfumer's stall here, with no dry ground for it to stand on. She holds out a stoppered vial. \"You've already said yes. I can smell it.\"",
		"choices": [
			{"text": "Pay her", "pay": 1.0, "do": {"say": "It smells of a day you can't quite place.", "boon": "fleetfoot"}},
			{"text": "Say no, and mean it", "roll": "resolve",
				"win": {"say": "She bows, slightly annoyed, and gives you the vial.", "boon": "fleetfoot"},
				"lose": {"say": "You're holding the vial. You've paid. You feel fine about it.", "gold": -2.0}},
			{"text": "Breathe through your mouth, and leave", "do": {"say": "You think about rain for an hour."}}]},
	"two_sluices": {"road": "lotus", "title": "two sluices",
		"scene": "A chalked note hangs by two sluice wheels: open one, close the other, in the right order. Somebody keeps these gates. Nobody says who.",
		"choices": [
			{"text": "Open the low gate", "do": {"say": "The water drains and leaves a little of what it hid.", "gold": 1.0}},
			{"text": "Work out the order", "roll": "wits",
				"win": {"say": "A chamber opens that the water has been guarding.", "gold": 2.0, "augment": true},
				"lose": {"say": "The water comes back all at once.", "hurt": 0.15}},
			{"text": "Varuni asks the water", "hero": "ilse",
				"do": {"say": "She hums. The wheels turn themselves, somewhat embarrassed.", "gold": 2.0, "augment": true}},
			{"text": "Leave the gates alone", "do": {"say": "Someone, somewhere, approves."}}]},

	# ---------- The Saltglass Road ----------
	"one_turned_back": {"road": "saltglass", "title": "the one who turned back",
		"scene": "The footprints in the glass all run the same way. One set stops, turns, and walks back towards the fire.",
		"choices": [
			{"text": "Follow the many", "do": {"say": "They dropped things as they ran.", "gold": 1.0}},
			{"text": "Follow the one", "roll": "finesse",
				"win": {"say": "Whatever they went back for, they left it.", "gold": 3.0, "augment": true},
				"lose": {"say": "The glass is still hot, this far in.", "hurt": 0.20}},
			{"text": "The Seer stands in the print", "hero": "seer",
				"do": {"say": "It fits. She doesn't explain.", "gold": 3.0, "augment": true}},
			{"text": "Keep to the road", "do": {"say": "The road has seen this before."}}]},
	"small_mirrors": {"road": "saltglass", "title": "a hall of small mirrors",
		"scene": "A wall of mirror shards stands alone in the dunes. All of you are in it. One of the reflections has stopped moving.",
		"choices": [
			{"text": "Bow to it", "roll": "lore",
				"win": {"say": "It bows back, a moment late.", "boon": "kinfire"},
				"lose": {"say": "It doesn't bow back.", "hurt": 0.10}},
			{"text": "Break the glass", "do": {"say": "The foes are your reflection's idea.", "fight": "elite"}},
			{"text": "Look away", "do": {"say": "It's still looking when you leave."}}]},
	"wrong_hour": {"road": "saltglass", "title": "the wrong hour",
		"scene": "A stone sundial stands in the road, its shadow pointing at an hour that isn't now. A reckoner sits beside it with a ledger, and offers to read it for a fee.",
		"choices": [
			{"text": "Pay for a reading", "pay": 1.0, "do": {"say": "The next hour belongs to you. She writes that down.", "boon": "whetstone"}},
			{"text": "Read it yourself", "roll": "wits",
				"win": {"say": "You're a little ahead of the day now.", "boon": "fleetfoot"},
				"lose": {"say": "The answer was now. It was a small answer, and sharp.", "hurt": 0.10}},
			{"text": "Surya admires the ledger", "hero": "kaede",
				"do": {"say": "He hands it back, eventually. Your purse is heavier.", "gold": 3.0}},
			{"text": "Don't ask what time it is", "do": {"say": "Very wise, she says, and makes a note."}}]},

	# ---------- The Standing Stones ----------
	"line_the_herds_keep": {"road": "stones", "title": "the line the herds keep",
		"scene": "The herd grazes right up to the ring and stops, as if the grass ended. One foal stands a step inside, pleased with itself, then less so.",
		"choices": [
			{"text": "Lead it out", "roll": "finesse",
				"win": {"say": "The herd watches you all the way to the ridge.", "boon": "heartwood"},
				"lose": {"say": "Foals kick. Nobody warned you.", "hurt": 0.10}},
			{"text": "Sorrel whistles", "hero": "sorrel",
				"do": {"say": "One note. It trots out as if that had been the plan.", "boon": "fleetfoot", "up": 1}},
			{"text": "Leave it be", "do": {"say": "It gets out on its own. You don't stay to see how."}}]},
	"labelled_barrow": {"road": "stones", "title": "the labelled barrow",
		"scene": "An archaeologist stands waist-deep in a barrow, labelling something that appears to be labelling her back.",
		"choices": [
			{"text": "Help her lift it", "roll": "might",
				"win": {"say": "It comes up quietly. She gives you the duplicates.", "gold": 2.0, "augment": true},
				"lose": {"say": "It was not asleep.", "fight": "battle"}},
			{"text": "Buy something she's finished with", "pay": 2.0, "do": {"say": "\"Do keep the tag on.\"", "augment": true}},
			{"text": "Don't ask", "do": {"say": "She hadn't planned on telling you."}}]},
	"wind_says_a_name": {"road": "stones", "title": "the wind says a name",
		"scene": "The wind through the ring says a name. It is very nearly one of yours.",
		"choices": [
			{"text": "Answer it", "roll": "resolve",
				"win": {"say": "It has the wrong person, and it apologises.", "boon": "fleetfoot"},
				"lose": {"say": "It had the right person after all.", "hurt": 0.10}},
			{"text": "Stand and listen", "do": {"say": "You learn nothing, restfully.", "heal": 0.10}},
			{"text": "Keep moving", "do": {"say": "It tries again behind you, further off."}}]},

	# ---------- The Empty Pavilions ----------
	"table_for_twelve": {"road": "pavilions", "title": "a table for twelve",
		"scene": "In the largest tent a meal is laid for twelve, still warm. One place has a card with your name on it.",
		"choices": [
			{"text": "Sit, and be a good guest", "roll": "charm",
				"win": {"say": "Nobody comes. It's the best meal of the road.", "heal": 0.30},
				"lose": {"say": "The host arrives.", "fight": "battle"}},
			{"text": "Pocket the spoons", "roll": "finesse",
				"win": {"say": "Real silver. Slightly warm.", "gold": 3.0},
				"lose": {"say": "The tablecloth moves faster than you do.", "hurt": 0.15}},
			{"text": "Leave your card, and go", "do": {"say": "On the way out you notice there are thirteen chairs."}}]},
	"lantern_oil": {"road": "pavilions", "title": "one lantern left on",
		"scene": "One lantern still burns in the empty lane. An old woman tends it, and sells oil to nobody.",
		"choices": [
			{"text": "Buy a flask", "pay": 1.0, "do": {"say": "It burns hotter than it should.", "boon": "kinfire"}},
			{"text": "Ask where they all went", "roll": "lore",
				"win": {"say": "She draws you the road they took, and which turns to skip.", "rerolls": 2},
				"lose": {"say": "She answers. You wish she hadn't.", "hurt": 0.10}},
			{"text": "Wish her a good night", "do": {"say": "She looks surprised to be seen."}}]},
	"tent_too_big": {"road": "pavilions", "title": "the tent that goes on",
		"scene": "From outside it was a small tent. You have now been walking inside it for some time.",
		"choices": [
			{"text": "Cut through the silk", "roll": "might",
				"win": {"say": "Outside, at last, and somebody's strongbox.", "gold": 2.0},
				"lose": {"say": "The silk closes on you like a hand.", "hurt": 0.15}},
			{"text": "Follow the seams", "roll": "wits",
				"win": {"say": "The way out teaches you a shorter way everywhere.", "boon": "fleetfoot"},
				"lose": {"say": "The seam goes round. So did you.", "hurt": 0.10}},
			{"text": "Turn around", "do": {"say": "The door was right behind you the whole time."}}]},

	# ---------- The Walking Wood ----------
	"your_own_footprints": {"road": "wood", "title": "your own footprints",
		"scene": "Your own footprints cross the path ahead of you. They are fresher than they should be.",
		"choices": [
			{"text": "Follow them", "roll": "wits",
				"win": {"say": "They lead to something you must have left for yourself.", "gold": 2.0},
				"lose": {"say": "They lead to a low branch you already know about.", "hurt": 0.10}},
			{"text": "Galeblade asks the trees", "hero": "leaf",
				"do": {"say": "They point at once. He looks uneasy at how well they know him.", "boon": "fleetfoot", "up": 1}},
			{"text": "Wait for the path to settle", "do": {"say": "It takes a while. You need the sit.", "heal": 0.15}}]},
	"bark_shrine": {"road": "wood", "title": "the bark shrine",
		"scene": "A shrine of bark, with a bowl of old coins. The custom is one coin, and then you are let past.",
		"choices": [
			{"text": "Add a coin", "pay": 1.0, "do": {"say": "The path straightens for you. It didn't have to.", "boon": "heartwood"}},
			{"text": "Take what's in the bowl", "roll": "finesse",
				"win": {"say": "Nothing happens. You keep listening for it.", "gold": 3.0},
				"lose": {"say": "The trees notice.", "fight": "battle"}},
			{"text": "Bow, and go by", "do": {"say": "The custom is one coin. The wood will remember the bow."}}]},
	"old_street": {"road": "wood", "title": "the old street",
		"scene": "Under the roots runs a paved street with a bakery on it. It smells of fresh bread. Nobody has baked here in two hundred years.",
		"choices": [
			{"text": "Go in and eat", "roll": "resolve",
				"win": {"say": "It is only bread. It is very good bread.", "heal": 0.25},
				"lose": {"say": "It is not only bread.", "hurt": 0.15}},
			{"text": "Check the till", "do": {"say": "Two hundred years of small change.", "gold": 1.0}},
			{"text": "Keep to the roots", "do": {"say": "The smell follows you for a mile."}}]},

	# ---------- The Serpent Archive ----------
	"overdue": {"road": "archive", "title": "overdue",
		"scene": "A keeper slides up with a slip. One of your party borrowed a book here. It is very overdue, and the date is before they were born.",
		"choices": [
			{"text": "Pay the fine", "pay": 1.0, "do": {"say": "Your account is clear, and now earns interest.", "boon": "tithe"}},
			{"text": "Dispute it", "roll": "charm",
				"win": {"say": "The Archive regrets the error, in writing and in coin.", "gold": 2.0},
				"lose": {"say": "The Archive has a long reach. It uses it.", "hurt": 0.10}},
			{"text": "Snake corrects the date", "hero": "snake",
				"do": {"say": "He adds a footnote. The keeper bows, and pays him.", "boon": "tithe", "up": 1}},
			{"text": "Say it wasn't you", "do": {"say": "The keeper writes that down too."}}]},
	"filed_under_regret": {"road": "archive", "title": "filed under regret",
		"scene": "You put a bag down for a moment, and it is gone. The catalogue says it has been shelved three floors down, under \"regret\".",
		"choices": [
			{"text": "Go and get it", "roll": "finesse",
				"win": {"say": "It's there, and so is someone else's.", "augment": true},
				"lose": {"say": "The stacks shift while you're in them.", "hurt": 0.15}},
			{"text": "Pay the retrieval fee", "pay": 1.0, "do": {"say": "It comes back with notes in the margins.", "rerolls": 2}},
			{"text": "Let it go", "do": {"say": "You didn't need it. The card says so."}}]},
	"wet_ink": {"road": "archive", "title": "wet ink",
		"scene": "A page lies open on a lectern, ending mid-sentence. The ink is wet. The pen is being held out to you, though you can't see by what.",
		"choices": [
			{"text": "Finish the sentence", "roll": "lore",
				"win": {"say": "It reads better now. Something is grateful.", "boon": "kinfire"},
				"lose": {"say": "That was not the word.", "hurt": 0.10}},
			{"text": "Read what came before", "roll": "wits",
				"win": {"say": "It's about you, and it mentions two ways out.", "rerolls": 2},
				"lose": {"say": "You read it twice. The second time it read you.", "hurt": 0.10}},
			{"text": "Close the book", "do": {"say": "It lets you."}}]},

	# ---------- The Veiled Undercroft ----------
	"behind_the_curtain": {"road": "undercroft", "title": "behind the curtain",
		"scene": "There's an auction behind a curtain, and no faces showing. Someone bids on you before you've sat down.",
		"choices": [
			{"text": "Bid on the box", "pay": 2.0, "do": {"say": "You'll never learn what else was in the lot.", "augment": true}},
			{"text": "Bid with nothing", "roll": "charm",
				"win": {"say": "They pay you to stop.", "gold": 3.0},
				"lose": {"say": "They check.", "fight": "battle"}},
			{"text": "Smoke walks through the room", "hero": "smoke",
				"do": {"say": "Nobody stops a masked man who isn't in a hurry.", "gold": 3.0}},
			{"text": "Slip out", "do": {"say": "Someone holds the curtain for you. You never see who."}}]},
	"ember_vent": {"road": "undercroft", "title": "the vent that breathes",
		"scene": "An ember vent breathes in the wall, in and out, on a slow count. Something shines on the far side.",
		"choices": [
			{"text": "Time it, and run", "roll": "finesse",
				"win": {"say": "Your boots are smoking, and your pockets are full.", "gold": 3.0},
				"lose": {"say": "You counted to the wrong number.", "hurt": 0.20}},
			{"text": "Warm your hands", "do": {"say": "It's the first warm thing down here.", "heal": 0.15}},
			{"text": "Walk on", "do": {"say": "It breathes out behind you, almost a sigh."}}]},
	"small_favour": {"road": "undercroft", "title": "a small favour",
		"scene": "A veiled clerk offers you a favour now, to be named later. She has already started writing it down.",
		"choices": [
			{"text": "Accept", "do": {"say": "\"Nothing you'd miss,\" she says.", "boon": "whetstone", "loan": [0.0, 3.0]}},
			{"text": "Refuse, and hold her gaze", "roll": "resolve",
				"win": {"say": "She tears up the page, and leaves you the blank half.", "boon": "bulwark"},
				"lose": {"say": "You look away first. It costs you.", "hurt": 0.10}},
			{"text": "Refuse, and leave quickly", "do": {"say": "She writes that down as well."}}]},

	# ---------- The Whale Cathedral ----------
	"bell_below": {"road": "whale", "title": "the bell below",
		"scene": "A bell rings under the ice. A rope comes up through it, frozen solid at the top and still moving.",
		"choices": [
			{"text": "Pull", "roll": "might",
				"win": {"say": "It rings once, for you, and the ice holds firmer underfoot.", "boon": "bulwark"},
				"lose": {"say": "Something pulls back.", "hurt": 0.15}},
			{"text": "Cut it for the bronze fittings", "do": {"say": "The ringing stops. You wish it hadn't.", "gold": 1.0}},
			{"text": "Let it ring", "do": {"say": "It rings for a long time after you've gone."}}]},
	"choir_of_ribs": {"road": "whale", "title": "the choir of ribs",
		"scene": "The wind plays the great ribs like reeds. An old sexton says the chord is missing a voice, and points to a spot on the ice.",
		"choices": [
			{"text": "Stand there and sing", "roll": "charm",
				"win": {"say": "The whole cathedral settles, as if it had been waiting.", "boon": "heartwood"},
				"lose": {"say": "The ribs take the note, and some of your breath.", "hurt": 0.10}},
			{"text": "Tidecaller sings", "hero": "caller",
				"do": {"say": "The sexton takes off his hat.", "boon": "heartwood", "up": 1}},
			{"text": "Tell him you can't sing", "do": {"say": "\"No one can,\" he says. \"That's why it's missing.\""}}]},
	"what_the_ice_keeps": {"road": "whale", "title": "what the ice keeps",
		"scene": "There's a pack frozen into the wall, and a lamp, and a hand still holding them.",
		"choices": [
			{"text": "Cut it all free", "roll": "resolve",
				"win": {"say": "They would have wanted someone to have it.", "gold": 3.0, "augment": true},
				"lose": {"say": "The cold in that wall is older than you are.", "hurt": 0.20}},
			{"text": "Take only the lamp", "do": {"say": "It's lighter than you expected.", "gold": 1.0}},
			{"text": "Say a word, and go", "do": {"say": "It's a small thing. You feel better for it.", "heal": 0.10}}]},

	# ---------- anywhere ----------
	"knotted_cord": {"road": "any", "title": "the knotted cord",
		"scene": "A woman with a bundle of cords offers you gold, at no charge today. She ties a knot, to remember.",
		"choices": [
			{"text": "Take the loan", "do": {"say": "She counts it out, and the knot is tied.", "loan": [3.0, 5.0]}},
			{"text": "Ask what you already owe", "roll": "lore",
				"win": {"say": "One of your knots was hers. She unties it.", "rerolls": 2},
				"lose": {"say": "She says you'd rather not know."}},
			{"text": "Keep your hands in your pockets", "do": {"say": "She ties a knot anyway, a small one."}}]},
	"two_mushrooms": {"road": "any", "title": "two mushrooms",
		"scene": "A hedge healer keeps the one that mends and the one that kills in the same pocket. She says it keeps her honest.",
		"choices": [
			{"text": "Take one", "luck": true,
				"win": {"say": "It mends.", "heal": 0.30},
				"lose": {"say": "It doesn't kill. That's the best you can say.", "hurt_all": 0.10}},
			{"text": "Tell them apart", "roll": "lore",
				"win": {"say": "\"Well,\" she says. \"That's one of us who can.\"", "heal": 0.30},
				"lose": {"say": "It was the other one.", "hurt": 0.10}},
			{"text": "Say you've eaten", "do": {"say": "She shrugs, and eats one herself."}}]},
	"verse_for_sale": {"road": "any", "title": "a verse for the road",
		"scene": "A griot with a kora is singing a song of everyone who has walked this road. She asks whether you'd like to be in it.",
		"choices": [
			{"text": "Pay for a verse", "pay": 1.0, "do": {"say": "You fight better knowing it will be sung.", "boon": "heartwood"}},
			{"text": "Sing her one back", "roll": "charm",
				"win": {"say": "She laughs, and puts that in too.", "boon": "whetstone"},
				"lose": {"say": "She puts that in as well.", "hurt": 0.10}},
			{"text": "Listen, and leave", "do": {"say": "Your name isn't in it yet. There's time."}}]},
	"mule_in_the_road": {"road": "any", "title": "the mule in the road",
		"scene": "A spice merchant's mule has lain down in the road. She offers a fair cut to anyone who can get it up.",
		"choices": [
			{"text": "Lift it", "roll": "might",
				"win": {"say": "It gets up, offended. She pays in full.", "gold": 2.0},
				"lose": {"say": "It weighs what a mule weighs.", "hurt": 0.10}},
			{"text": "Reason with it", "roll": "charm",
				"win": {"say": "She offers you a share of the whole route.", "boon": "tithe"},
				"lose": {"say": "It kicks without getting up.", "hurt": 0.10}},
			{"text": "Go round", "do": {"say": "You smell of cloves for a day."}}]},
	"door_on_its_own": {"road": "any", "title": "a door on its own",
		"scene": "A carved door stands by the road with a carver still working on it. \"It's finished,\" he says, \"when someone walks through.\"",
		"choices": [
			{"text": "Walk through", "roll": "resolve",
				"win": {"say": "You come out the other side harder to move.", "boon": "bulwark", "up": 1},
				"lose": {"say": "It was not finished.", "hurt": 0.15}},
			{"text": "Buy the ward he cut", "pay": 2.0, "do": {"say": "It weighs nothing, and it holds.", "boon": "bulwark"}},
			{"text": "Admire it, and go round", "do": {"say": "He nods. He's used to that."}}]},
	"runner_with_a_message": {"road": "any", "title": "the runner's message",
		"scene": "A relay runner staggers up, presses a message on you for someone further down the road, and is gone before you can ask who.",
		"choices": [
			{"text": "Run it on", "roll": "finesse",
				"win": {"say": "Someone was very glad of it, and paid accordingly.", "gold": 2.0},
				"lose": {"say": "The road is rougher at a run.", "hurt": 0.10}},
			{"text": "Open it", "do": {"say": "It's a list of what you'll do next, with two lines crossed out.", "rerolls": 2}},
			{"text": "Leave it on a stone", "do": {"say": "The next runner will find it. That's how it works."}}]},
}

## How much likelier a normal event is than a rare one.
const COMMON_WEIGHT := 3
const RARE_WEIGHT := 1


## The keys on a road (or "any") not yet in `seen`.
static func pool(road: String, seen: Array) -> Array:
	return LIST.keys().filter(func(k): return LIST[k].road == road and not k in seen)


static func weight(key: String) -> int:
	return RARE_WEIGHT if LIST[key].get("rare", false) else COMMON_WEIGHT
