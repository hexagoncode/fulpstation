/*
Contains:
Borg Hypospray
Borg Shaker
Nothing to do with hydroponics in here. Sorry to dissapoint you.
*/

/*
Borg Hypospray
*/
/obj/item/weapon/reagent_containers/borghypo
	name = "cyborg hypospray"
	desc = "An advanced chemical synthesizer and injection system, designed for heavy-duty medical equipment."
	icon = 'icons/obj/syringe.dmi'
	item_state = "hypo"
	icon_state = "borghypo"
	amount_per_transfer_from_this = 5
	volume = 30
	possible_transfer_amounts = list()
	var/mode = 1
	var/charge_cost = 50
	var/charge_tick = 0
	var/recharge_time = 5 //Time it takes for shots to recharge (in seconds)
	var/bypass_protection = 1 //If the hypospray can go through armor or thick material

	var/list/datum/reagents/reagent_list = list()
	var/list/reagent_ids = list("dexalin", "kelotane", "bicaridine", "antitoxin", "epinephrine", "spaceacillin", "mannitol")
	//var/list/reagent_ids = list("salbutamol", "salglu_solution", "salglu_solution", "charcoal", "ephedrine", "spaceacillin")
	var/list/modes = list() //Basically the inverse of reagent_ids. Instead of having numbers as "keys" and strings as values it has strings as keys and numbers as values.
								//Used as list for input() in shakers.


/obj/item/weapon/reagent_containers/borghypo/New()
	..()

	var/iteration = 1
	for(var/R in reagent_ids)
		add_reagent(R)
		modes[R] = iteration
		iteration++

	START_PROCESSING(SSobj, src)


/obj/item/weapon/reagent_containers/borghypo/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()


/obj/item/weapon/reagent_containers/borghypo/process() //Every [recharge_time] seconds, recharge some reagents for the cyborg
	charge_tick++
	if(charge_tick >= recharge_time)
		regenerate_reagents()
		charge_tick = 0

	//update_icon()
	return 1

// Purely for testing purposes I swear~ //don't lie to me
/*
/obj/item/weapon/reagent_containers/borghypo/verb/add_cyanide()
	set src in world
	add_reagent("cyanide")
*/


// Use this to add more chemicals for the borghypo to produce.
/obj/item/weapon/reagent_containers/borghypo/proc/add_reagent(reagent)
	reagent_ids |= reagent
	var/datum/reagents/RG = new(30)
	RG.my_atom = src
	reagent_list += RG

	var/datum/reagents/R = reagent_list[reagent_list.len]
	R.add_reagent(reagent, 30)

/obj/item/weapon/reagent_containers/borghypo/proc/regenerate_reagents()
	if(isrobot(src.loc))
		var/mob/living/silicon/robot/R = src.loc
		if(R && R.cell)
			for(var/i in 1 to reagent_ids.len)
				var/datum/reagents/RG = reagent_list[i]
				if(RG.total_volume < RG.maximum_volume) 	//Don't recharge reagents and drain power if the storage is full.
					R.cell.use(charge_cost) 					//Take power from borg...
					RG.add_reagent(reagent_ids[i], 5)		//And fill hypo with reagent.

/obj/item/weapon/reagent_containers/borghypo/attack(mob/living/carbon/M, mob/user)
	var/datum/reagents/R = reagent_list[mode]
	if(!R.total_volume)
		user << "<span class='notice'>The injector is empty.</span>"
		return
	if(!istype(M))
		return
	if(R.total_volume && (bypass_protection || M.can_inject(user, 1)))
		M << "<span class='warning'>You feel a tiny prick!</span>"
		user << "<span class='notice'>You inject [M] with the injector.</span>"
		var/fraction = min(amount_per_transfer_from_this/R.total_volume, 1)
		R.reaction(M, INJECT, fraction)
		if(M.reagents)
			var/trans = R.trans_to(M, amount_per_transfer_from_this)
			user << "<span class='notice'>[trans] unit\s injected.  [R.total_volume] unit\s remaining.</span>"
			var/datum/reagent/injected = chemical_reagents_list[reagent_ids[mode]]
			add_logs(user, M, "injected", src, "(CHEMICALS: [injected.name])")

/obj/item/weapon/reagent_containers/borghypo/attack_self(mob/user)
	var/chosen_reagent = modes[input(user, "What reagent do you want to dispense?") as null|anything in reagent_ids]
	if(!chosen_reagent)
		return
	mode = chosen_reagent
	playsound(loc, 'sound/effects/pop.ogg', 50, 0)
	var/datum/reagent/R = chemical_reagents_list[reagent_ids[mode]]
	user << "<span class='notice'>[src] is now dispensing '[R.name]'.</span>"
	return

/obj/item/weapon/reagent_containers/borghypo/examine(mob/user)
	usr = user
	..()
	DescribeContents()	//Because using the standardized reagents datum was just too cool for whatever fuckwit wrote this

/obj/item/weapon/reagent_containers/borghypo/proc/DescribeContents()
	var/empty = 1

	for(var/datum/reagents/RS in reagent_list)
		var/datum/reagent/R = locate() in RS.reagent_list
		if(R)
			usr << "<span class='notice'>It currently has [R.volume] unit\s of [R.name] stored.</span>"
			empty = 0

	if(empty)
		usr << "<span class='warning'>It is currently empty! Allow some time for the internal syntheszier to produce more.</span>"

/obj/item/weapon/reagent_containers/borghypo/hacked
	icon_state = "borghypo_s"
	reagent_ids = list ("facid", "mutetoxin", "cyanide", "sodium_thiopental", "heparin", "lexorin")

/obj/item/weapon/reagent_containers/borghypo/syndicate
	name = "syndicate cyborg hypospray"
	desc = "An experimental piece of Syndicate technology used to produce powerful restorative nanites used to very quickly restore injuries of all types. Also metabolizes potassium iodide, for radiation poisoning, and morphine, for offense."
	icon_state = "borghypo_s"
	charge_cost = 20
	recharge_time = 2
	reagent_ids = list("syndicate_nanites", "potass_iodide", "morphine")
	bypass_protection = 1

/*
Borg Shaker
*/
/obj/item/weapon/reagent_containers/borghypo/borgshaker
	name = "cyborg shaker"
	desc = "An advanced drink synthesizer and mixer."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "shaker"
	possible_transfer_amounts = list(5,10,20)
	charge_cost = 20 //Lots of reagents all regenerating at once, so the charge cost is lower. They also regenerate faster.
	recharge_time = 3

	reagent_ids = list("beer", "orangejuice", "limejuice", "tomatojuice", "cola", "tonic", "sodawater", "ice", "cream", "whiskey", "vodka", "rum", "gin", "tequila", "vermouth", "wine", "kahlua", "cognac", "ale")

/obj/item/weapon/reagent_containers/borghypo/borgshaker/attack(mob/M, mob/user)
	return //Can't inject stuff with a shaker, can we? //not with that attitude

/obj/item/weapon/reagent_containers/borghypo/borgshaker/regenerate_reagents()
	if(isrobot(src.loc))
		var/mob/living/silicon/robot/R = src.loc
		if(R && R.cell)
			for(var/i in modes) //Lots of reagents in this one, so it's best to regenrate them all at once to keep it from being tedious.
				var/valueofi = modes[i]
				var/datum/reagents/RG = reagent_list[valueofi]
				if(RG.total_volume < RG.maximum_volume)
					R.cell.use(charge_cost)
					RG.add_reagent(reagent_ids[valueofi], 5)

/obj/item/weapon/reagent_containers/borghypo/borgshaker/afterattack(obj/target, mob/user, proximity)
	if(!proximity) return

	else if(target.is_open_container() && target.reagents)
		var/datum/reagents/R = reagent_list[mode]
		if(!R.total_volume)
			user << "<span class='warning'>[src] is currently out of this ingredient! Please allow some time for the synthesizer to produce more.</span>"
			return

		if(target.reagents.total_volume >= target.reagents.maximum_volume)
			user << "<span class='notice'>[target] is full.</span>"
			return

		var/trans = R.trans_to(target, amount_per_transfer_from_this)
		user << "<span class='notice'>You transfer [trans] unit\s of the solution to [target].</span>"

/obj/item/weapon/reagent_containers/borghypo/borgshaker/DescribeContents()
	var/empty = 1

	var/datum/reagents/RS = reagent_list[mode]
	var/datum/reagent/R = locate() in RS.reagent_list
	if(R)
		usr << "<span class='notice'>It currently has [R.volume] unit\s of [R.name] stored.</span>"
		empty = 0

	if(empty)
		usr << "<span class='warning'>It is currently empty! Please allow some time for the synthesizer to produce more.</span>"

/obj/item/weapon/reagent_containers/borghypo/borgshaker/hacked
	..()
	name = "cyborg shaker"
	desc = "Will mix drinks that knock them dead."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "threemileislandglass"
	possible_transfer_amounts = list(5,10,20)
	charge_cost = 20 //Lots of reagents all regenerating at once, so the charge cost is lower. They also regenerate faster.
	recharge_time = 3

	reagent_ids = list("beer2")

/obj/item/weapon/reagent_containers/borghypo/peace
	name = "Peace Hypospray"

	reagent_ids = list("dizzysolution","tiresolution")

/obj/item/weapon/reagent_containers/borghypo/peace/hacked
	desc = "Everything's peaceful in death!"
	icon_state = "borghypo_s"
	reagent_ids = list("dizzysolution","tiresolution","tirizene","sulfonal","sodium_thiopental","cyanide","neurotoxin2")
