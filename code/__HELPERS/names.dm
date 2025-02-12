/proc/lizard_name(gender)
	if(gender == MALE)
		return "[pick(lizard_names_male)]-[pick(lizard_names_male)]"
	else
		return "[pick(lizard_names_female)]-[pick(lizard_names_female)]"


var/church_name = null
/proc/church_name()
	if (church_name)
		return church_name

	var/name = ""

	name += pick("Holy", "United", "First", "Second", "Last", "Grand", "Final", "Original")

	if (prob(20))
		name += " Fulp"//" Space"

	name += " " + pick("Church", "Cathedral", "Body", "Worshippers", "Movement", "Witnesses")
	name += " of [religion_name()]"

	return name

var/command_name = null
/proc/command_name()
	if (command_name)
		return command_name

	var/name = "Central Command"

	command_name = name
	return name

/proc/change_command_name(name)

	command_name = name

	return name

var/religion_name = null
/proc/religion_name()
	if (religion_name)
		return religion_name

	var/name = ""

	name += pick("bee", "science", "edu", "captain", "assistant", "monkey", "alien", "space", "unit", "sprocket", "gadget", "bomb", "revolution", "beyond", "station", "goon", "robot", "ivor", "hobnob")
	name += pick("ism", "ia", "ology", "istism", "ites", "ick", "ian", "ity")

	return capitalize(name)

/proc/station_name()
	if(station_name)
		return station_name

	if(config && config.station_name)
		station_name = config.station_name
	else
		station_name = new_station_name()

	feedback_set_details("station_name","[station_name]")

	if(config && config.server_name)
		world.name = "[config.server_name][config.server_name==station_name ? "" : ": [station_name]"]"
	else
		world.name = station_name

	return station_name

/proc/new_station_name()
	var/random = rand(1,5)
	var/name = ""
	var/new_station_name = ""

	//Rare: Pre-Prefix
	//if (prob(10))
	//	name = pick("Imperium", "Heretical", "Cuban", "Psychic", "Elegant", "Common", "Uncommon", "Rare", "Unique", "Houseruled", "Religious", "Atheist", "Traditional", "Houseruled", "Mad", "Super", "Ultra", "Secret", "Top Secret", "Deep", "Death", "Zybourne", "Central", "Main", "Government", "Uoi", "Fat", "Automated", "Experimental", "Augmented")
	//	new_station_name = name + " "
	//	name = ""

	// Prefix
	for(var/holiday_name in SSevent.holidays)
		if(holiday_name == "Friday the 13th")
			random = 13
		var/datum/holiday/holiday = SSevent.holidays[holiday_name]
		name = holiday.getStationPrefix()
		//get normal name
	if(!name)
		name = pick("Kurt","Stu","Willy","Willie","Geeves","Bateman","James","Axel","Bruno","Caleb","Dale","Tucker","Felix","Fabian","Grant","Hal","Ives","Jarvis","T.J.","Nash","Gavyn","Don","Bronson","Heston","Charleton","Clint","Eastwood","Graves","Stumbles","Liam","Hangar", "Jordan","Duane","Jacob","Stamper","Fulp","Bandelin","Tanner","Brick","Scooter","Roland","Blade","Logan","Xavier","Po","Thor","Odin","Loki","Zeus","Gil","Hermes","Hercules","Mars","Ares","Hades","Apollo","Frenchie","Aurelius","Zeke","Yale","Wade", "Vincent","Vincenzo","Vance","Uistean","Urien","Chuckles","Houston","Thorpe","Shawn","Biddle","Johanson","Francis","Drake","Raleigh","Walter","Walt","Quade","Pedro","Oliver","Neal","Manuel","Landon","Keegan","Butch","Buck","Kane","Jasper","Smalls", "Ponyboy","Godzilla","Sailor","Charles","Mabutu","Chumbo","Ching","Mr.Beautiful","Johnny","Sticky","Duncan","Malcom","Malone","Professor","Coach","Ellis","Leonardo","Michelangelo","Donatello","Raphael","Oney","O�Neal","Leon","Norton","Jacob", "Archer","Fletcher","Grisham","Graham","Marcus","Watson","Holmes","Blake","Cartiff","Ulysses","Marty","Rick","Sanchez","Morty","Lloyd","Emmet","Tiernan","Tiberius","Thadeus","Max","Holden","Hayden","Hadrian","Claus","Claudius","Caesar","Fernando", "Hernando","Gooseman","Wheeler","Ma-Ti","Kwame","Captain","Lee","Lucky","King","Spades","Diamonds","Clubs","Swords","Hearts","Wildboy","Cadet","Niko","Roman","Brutus","Spartacus","Clayton","Kleeton","Cleetus","Aden","Abram","Lee","Colby","Maynard", "Jonesy","Chauncey","Jack","Harvey","Hugh","Tobias","Phoenix","Simon","Alucard","Drachen","Dragon", "Serpent", "Dracul", "Alistar", "Cromley", "Cromwell","Edgar","Edwin","Reuben","Jonas","Dylan","Kai","Nigel","Percy","Bruce","Alfie","Gordon", "Lebowski","Walter","Donnie","Frank","Leo","Deadeye","Skittles","Mr.E","Arnold","Chuck","Chucky","Sly","Statham","Jet","Dirk","Matches","Sandman","Quintus","Ryu","Moe","Curly","Shemp","Shep","Shepherd","Shepard","Larry","Ricky","Addison","Adonis","Ajay", "Ari","Cale","Carlo","Castle","Dalvin","Ethan","Eli","Elias","Ezekiel","Fox","Snake","Mordecai","Wolf","Garett","Gideon","Rocco","Judah","Judas","Mick","Sylas","Jan","Lionel","Sabin","Setzer","Spencer","Waylon","Wyatt","Victor","Malakai","Fingers", "Tiny","8-Ball","Dingus","Rocky","Slade","Wilson", "Zach","Zachariah","Grupert","Rupert","Hulius","Julius","Kaiser","Pauly","Gaylord","Crumbs","Crumbles","Sammy","Shipwreck","Duck","Ducky","Ape","Hungry","Viper","Toad","Badger","Reek","Damian","Dorito","Pops","Sam","Dean","Bobby","Crowley","Abaddon", "Stooley","Gopher","Squirrel","Stanley","Ghost","Mr.Spooks","Ghastly","Zombie","Goblin","Lothar","Spaniard","Winston","Church","Churchill","Priest","Bishop","Danks","Bilbo","Godfried","Jeffe","Biggy","Lewis","Louie","Drumpf","Booger","Trump", "Bernie","Metatron","Soupy","Pyotr","Marius","Grendel","Demarcus","Urgurth","Telwik","Hills","Percival","Drogan","Aloysius","Armstrong","Goku","Krillin","Vegeta","Picollo","Yamcha","Garlic","Onion","Taters", "Celery Man","Rudd","Tayne","Oyster", "Tate","Heat","Rabbit","Squid","Porker","Halibut","Nerves","Nelson","Rowan","Bob","Mikey","Chill","Lounge","Specs","Speedy","Rubbers","Bonkers","Party","Scurvy","Chunky","Fruity","Salty","Pepper","Puppy","Doggy","Kitty","Reginald","Reggie","Clumps", "Sparkles","Ryan","Steven","Chester","Kristof","Vlad","Godmur","Citsymon","Freekill","Bonk","Honk")
	//	SWAIN CHANGE: name = pick("", "Stanford", "Dorf", "Alium", "Prefix", "Clowning", "Aegis", "Ishimura", "Scaredy", "Death-World", "Mime", "Honk", "Rogue", "MacRagge", "Ultrameens", "Safety", "Paranoia", "Explosive", "Neckbear", "Donk", "Muppet", "North", "West", "East", "South", "Slant-ways", "Widdershins", "Rimward", "Expensive", "Procreatory", "Imperial", "Unidentified", "Immoral", "Carp", "Ork", "Pete", "Control", "Nettle", "Aspie", "Class", "Crab", "Fist","Corrogated","Skeleton","Race", "Fatguy", "Gentleman", "Capitalist", "Communist", "Bear", "Beard", "Derp", "Space", "Spess", "Star", "Moon", "System", "Mining", "Neckbeard", "Research", "Supply", "Military", "Orbital", "Battle", "Science", "Asteroid", "Home", "Production", "Transport", "Delivery", "Extraplanetary", "Orbital", "Correctional", "Robot", "Hats", "Pizza")
	if(name)
		new_station_name += name + " "

	// Suffix
	if (prob(50)) // SWAIN START CHANGES
		name = "Station"
	else
		name = pick ("Hub", "Base", "Moon", "Channel", "Lab", "Star", "Complex", "Habitat", "Facility", "Zone", "Point", "Area", "System")
	//name = pick("Station", "Fortress", "Frontier", "Suffix", "Death-trap", "Space-hulk", "Lab", "Hazard","Spess Junk", "Fishery", "No-Moon", "Tomb", "Crypt", "Hut", "Monkey", "Bomb", "Trade Post", "Fortress", "Village", "Town", "City", "Edition", "Hive", "Complex", "Base", "Facility", "Depot", "Outpost", "Installation", "Drydock", "Observatory", "Array", "Relay", "Monitor", "Platform", "Construct", "Hangar", "Prison", "Center", "Port", "Waystation", "Factory", "Waypoint", "Stopover", "Hub", "HQ", "Office", "Object", "Fortification", "Colony", "Planet-Cracker", "Roost", "Fat Camp")
	new_station_name += name + " "

	// ID Number
	switch(random)
		if(1)
			new_station_name += "[rand(1, 99)]"
		if(2)
			new_station_name += pick("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
		if(3)
			new_station_name += pick("II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX")
		if(4)
			new_station_name += pick("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu")
		if(5)
			new_station_name += pick("One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen")
		if(13)
			new_station_name += pick("13","XIII","Thirteen")
	return new_station_name

var/syndicate_name = null
/proc/syndicate_name()
	if (syndicate_name)
		return syndicate_name

	var/name = ""

	// Prefix
	name += pick("Clandestine", "Prima", "Blue", "Zero-G", "Max", "Blasto", "Waffle", "North", "Omni", "Newton", "Cyber", "Bonk", "Gene", "Gib")

	// Suffix
	if (prob(80))
		name += " "

		// Full
		if (prob(60))
			name += pick("Syndicate", "Consortium", "Collective", "Corporation", "Group", "Holdings", "Biotech", "Industries", "Systems", "Products", "Chemicals", "Enterprises", "Family", "Creations", "International", "Intergalactic", "Interplanetary", "Foundation", "Positronics", "Hive")
		// Broken
		else
			name += pick("Syndi", "Corp", "Bio", "System", "Prod", "Chem", "Inter", "Hive")
			name += pick("", "-")
			name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Code")
	// Small
	else
		name += pick("-", "*", "")
		name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Gen", "Star", "Dyne", "Code", "Hive")

	syndicate_name = name
	return name


//Traitors and traitor silicons will get these. Revs will not.
var/syndicate_code_phrase//Code phrase for traitors.
var/syndicate_code_response//Code response for traitors.

	/*
	Should be expanded.
	How this works:
	Instead of "I'm looking for James Smith," the traitor would say "James Smith" as part of a conversation.
	Another traitor may then respond with: "They enjoy running through the void-filled vacuum of the derelict."
	The phrase should then have the words: James Smith.
	The response should then have the words: run, void, and derelict.
	This way assures that the code is suited to the conversation and is unpredicatable.
	Obviously, some people will be better at this than others but in theory, everyone should be able to do it and it only enhances roleplay.
	Can probably be done through "{ }" but I don't really see the practical benefit.
	One example of an earlier system is commented below.
	/N
	*/

/proc/generate_code_phrase()//Proc is used for phrase and response in master_controller.dm

	var/code_phrase = ""//What is returned when the proc finishes.
	var/words = pick(//How many words there will be. Minimum of two. 2, 4 and 5 have a lesser chance of being selected. 3 is the most likely.
		50; 2,
		200; 3,
		50; 4,
		25; 5
	)

	var/safety[] = list(1,2,3)//Tells the proc which options to remove later on.
	var/nouns[] = list("love","hate","anger","peace","pride","sympathy","bravery","loyalty","honesty","integrity","compassion","charity","success","courage","deceit","skill","beauty","brilliance","pain","misery","beliefs","dreams","justice","truth","faith","liberty","knowledge","thought","information","culture","trust","dedication","progress","education","hospitality","leisure","trouble","friendships", "relaxation")
	var/drinks[] = list("vodka and tonic","gin fizz","bahama mama","manhattan","black Russian","whiskey soda","long island tea","margarita","Irish coffee"," manly dwarf","Irish cream","doctor's delight","Beepksy Smash","tequila sunrise","brave bull","gargle blaster","bloody mary","whiskey cola","white Russian","vodka martini","martini","Cuba libre","kahlua","vodka","wine","moonshine")
	var/locations[] = teleportlocs.len ? teleportlocs : drinks//if null, defaults to drinks instead.

	var/names[] = list()
	for(var/datum/data/record/t in data_core.general)//Picks from crew manifest.
		names += t.fields["name"]

	var/maxwords = words//Extra var to check for duplicates.

	for(words,words>0,words--)//Randomly picks from one of the choices below.

		if(words==1&&(1 in safety)&&(2 in safety))//If there is only one word remaining and choice 1 or 2 have not been selected.
			safety = list(pick(1,2))//Select choice 1 or 2.
		else if(words==1&&maxwords==2)//Else if there is only one word remaining (and there were two originally), and 1 or 2 were chosen,
			safety = list(3)//Default to list 3

		switch(pick(safety))//Chance based on the safety list.
			if(1)//1 and 2 can only be selected once each to prevent more than two specific names/places/etc.
				switch(rand(1,2))//Mainly to add more options later.
					if(1)
						if(names.len&&prob(70))
							code_phrase += pick(names)
						else
							if(prob(10))
								code_phrase += pick(lizard_name(MALE),lizard_name(FEMALE))
							else
								code_phrase += pick(pick(first_names_male,first_names_female))
								code_phrase += " "
								code_phrase += pick(last_names)
					if(2)
						code_phrase += pick(get_all_jobs())//Returns a job.
				safety -= 1
			if(2)
				switch(rand(1,2))//Places or things.
					if(1)
						code_phrase += pick(drinks)
					if(2)
						code_phrase += pick(locations)
				safety -= 2
			if(3)
				switch(rand(1,3))//Nouns, adjectives, verbs. Can be selected more than once.
					if(1)
						code_phrase += pick(nouns)
					if(2)
						code_phrase += pick(adjectives)
					if(3)
						code_phrase += pick(verbs)
		if(words==1)
			code_phrase += "."
		else
			code_phrase += ", "

	return code_phrase
