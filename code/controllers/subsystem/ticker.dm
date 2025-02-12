var/round_start_time = 0

var/datum/subsystem/ticker/ticker

/datum/subsystem/ticker
	name = "Ticker"
	init_order = 0

	priority = 200
	flags = SS_FIRE_IN_LOBBY|SS_KEEP_TIMING

	var/restart_timeout = 250	//delay when restarting server
	var/current_state = GAME_STATE_STARTUP	//state of current round (used by process()) Use the defines GAME_STATE_* !
	var/force_ending = 0					//Round was ended by admin intervention
	var/server_reboot_in_progress = 0

	var/hide_mode = 0
	var/datum/game_mode/mode = null
	var/event_time = null
	var/event = 0

	var/login_music							//music played in pregame lobby
	var/round_end_sound						//music/jingle played when the world reboots

	var/list/datum/mind/minds = list()		//The characters in the game. Used for objective tracking.

	//These bible variables should be a preference
	var/Bible_icon_state					//icon_state the chaplain has chosen for his bible
	var/Bible_item_state					//item_state the chaplain has chosen for his bible
	var/Bible_name							//name of the bible
	var/Bible_deity_name					//name of chaplin's deity

	var/list/syndicate_coalition = list()	//list of traitor-compatible factions
	var/list/factions = list()				//list of all factions
	var/list/availablefactions = list()		//list of factions with openings
	var/list/scripture_states = list(SCRIPTURE_DRIVER = TRUE, \
	SCRIPTURE_SCRIPT = FALSE, \
	SCRIPTURE_APPLICATION = FALSE, \
	SCRIPTURE_REVENANT = FALSE, \
	SCRIPTURE_JUDGEMENT = FALSE) //list of clockcult scripture states for announcements

	var/delay_end = 0						//if set true, the round will not restart on it's own

	var/triai = 0							//Global holder for Triumvirate
	var/tipped = 0							//Did we broadcast the tip of the day yet?

	var/timeLeft = 1200						//pregame timer

	var/totalPlayers = 0					//used for pregame stats on statpanel
	var/totalPlayersReady = 0				//used for pregame stats on statpanel

	var/queue_delay = 0
	var/list/queued_players = list()		//used for join queues when the server exceeds the hard population cap

	var/obj/screen/cinematic = null			//used for station explosion cinematic
	var/next_alert_time = 0
	var/next_check_admin = 1

	var/total_deaths = 0
	var/maprotatechecked = 0


/datum/subsystem/ticker/New()
	NEW_SS_GLOBAL(ticker)

	login_music = pickweight(list('sound/ambience/title1.ogg' = 33, 'sound/ambience/title2.ogg' = 33, 'sound/ambience/title3.ogg' = 34))//, 'sound/ambience/title3.ogg' =33, 'sound/ambience/clown.ogg' = 1)) // choose title music!
	//if(SSevent.holidays && SSevent.holidays[APRIL_FOOLS])
	//	login_music = 'sound/ambience/clown.ogg'

/datum/subsystem/ticker/Initialize(timeofday)
	if(!syndicate_code_phrase)
		syndicate_code_phrase	= generate_code_phrase()
	if(!syndicate_code_response)
		syndicate_code_response	= generate_code_phrase()
	setupFactions()
	..()

/datum/subsystem/ticker/fire()
	switch(current_state)
		if(GAME_STATE_STARTUP)
			timeLeft = config.lobby_countdown * 10
			world << "<b><font color='blue'>Welcome to the pre-game lobby!</font></b>"
			world << "Please, setup your character and select ready. Game will start in [config.lobby_countdown] seconds"
			current_state = GAME_STATE_PREGAME

		if(GAME_STATE_PREGAME)
				//lobby stats for statpanels
			totalPlayers = 0
			totalPlayersReady = 0
			for(var/mob/new_player/player in player_list)
				++totalPlayers
				if(player.ready)
					++totalPlayersReady

			//countdown
			if(timeLeft < 0)
				return
			timeLeft -= wait

			if(timeLeft <= 300 && !tipped)
				send_random_tip()
				tipped = 1

			if(timeLeft <= 0)
				current_state = GAME_STATE_SETTING_UP

		if(GAME_STATE_SETTING_UP)
			if(!setup())
				//setup failed
				current_state = GAME_STATE_STARTUP

		if(GAME_STATE_PLAYING)
			mode.process(wait * 0.1)
			check_queue()
			check_maprotate()
			scripture_states = scripture_unlock_alert(scripture_states)

			if(world.time > next_alert_time && next_check_admin)
				next_alert_time = world.time+1800 /* 6000 */

				var/admins_online = total_admins_active()

				if(!admins_online)
					next_check_admin = 0

			if(!mode.explosion_in_progress && mode.check_finished() || force_ending)
				current_state = GAME_STATE_FINISHED
				ticket_counter_visible_to_everyone = 1
				toggle_ooc(1) // Turn it on
				declare_completion(force_ending)
				spawn(50)
					var/admins_online = total_admins_active()
					var/unresolved_tickets = total_unresolved_tickets()

					if(unresolved_tickets && admins_online)
						delay_end = 1
						message_admins("Not all tickets have been resolved. Server restart delayed.")
					else if(unresolved_tickets && !admins_online)
						world.Reboot("Round ended, but there were still active tickets. Please submit a player complaint if you did not receive a response.", "end_proper", "ended with open tickets")
					else
						if(mode.station_was_nuked)
							world.Reboot("Station destroyed by Nuclear Device.", "end_proper", "nuke")
						else
							world.Reboot("Round ended.", "end_proper", "proper completion")

		if(GAME_STATE_FINISHED)
			if(!server_reboot_in_progress && !delay_end)
				var/unresolved_tickets = total_unresolved_tickets()
				if(!unresolved_tickets)
					world.Reboot("No unresolved tickets, restarting round.", "end_proper", "proper completion")


/datum/subsystem/ticker/proc/setup()
		//Create and announce mode
	var/list/datum/game_mode/runnable_modes
	if(master_mode == "random" || master_mode == "secret")
		runnable_modes = config.get_runnable_modes()

		if(master_mode == "secret")
			hide_mode = 1
			if(secret_force_mode != "secret")
				var/datum/game_mode/smode = config.pick_mode(secret_force_mode)
				if(!smode.can_start())
					message_admins("\blue Unable to force secret [secret_force_mode]. [smode.required_players] players and [smode.required_enemies] eligible antagonists needed.")
				else
					mode = smode

		if(!mode)
			if(!runnable_modes.len)
				world << "<B>Unable to choose playable game mode.</B> Reverting to pre-game lobby."
				return 0
			mode = pickweight(runnable_modes)

	else
		mode = config.pick_mode(master_mode)
		if(!mode.can_start())
			world << "<B>Unable to start [mode.name].</B> Not enough players, [mode.required_players] players and [mode.required_enemies] eligible antagonists needed. Reverting to pre-game lobby."
			qdel(mode)
			mode = null
			SSjob.ResetOccupations()
			return 0

	//Configure mode and assign player to special mode stuff
	var/can_continue = 0
	can_continue = src.mode.pre_setup()		//Choose antagonists
	SSjob.DivideOccupations() 				//Distribute jobs

	if(!Debug2)
		if(!can_continue)
			if(mode)
				message_admins("<B>Error setting up [master_mode]([mode.name], [mode.type]).</B> Reverting to pre-game lobby.")
			else
				message_admins("<B>Error setting up [master_mode](mode is null).</B> Reverting to pre-game lobby.")
			qdel(mode)
			mode = null
			world << "<B>Error setting up [master_mode].</B> Reverting to pre-game lobby."
			SSjob.ResetOccupations()
			return 0
	else
		world << "<span class='notice'>DEBUG: Bypassing prestart checks..."

	if(hide_mode)
		var/list/modes = new
		for (var/datum/game_mode/M in runnable_modes)
			modes += M.name
		modes = sortList(modes)
		world << "<B>The current game mode is - Secret!</B>"
		world << "<B>Possibilities:</B> [english_list(modes)]"
	else
		mode.announce()

	current_state = GAME_STATE_PLAYING
	if(!config.ooc_during_round)
		toggle_ooc(0) // Turn it off
	round_start_time = world.time

	start_landmarks_list = shuffle(start_landmarks_list) //Shuffle the order of spawn points so they dont always predictably spawn bottom-up and right-to-left
	create_characters() //Create player characters and transfer them
	collect_minds()
	equip_characters()
	data_core.manifest()

	Master.RoundStart()

	world << "<FONT color='blue'><B>Welcome to [station_name()], enjoy your stay!</B></FONT>"
	world << sound('sound/AI/welcome.ogg')

	if(SSevent.holidays)
		world << "<font color='blue'>and...</font>"
		for(var/holidayname in SSevent.holidays)
			var/datum/holiday/holiday = SSevent.holidays[holidayname]
			world << "<h4>[holiday.greet()]</h4>"


	spawn(0)//Forking here so we dont have to wait for this to finish
		mode.post_setup()
		//Cleanup some stuff
		for(var/obj/effect/landmark/start/S in landmarks_list)
			//Deleting Startpoints but we need the ai point to AI-ize people later
			if(S.name != "AI")
				qdel(S)

		var/list/adm = get_admin_counts()
		if(!adm["present"])
			send2irc("Server", "Round just started with no active admins online!")

	return 1

//Plus it provides an easy way to make cinematics for other events. Just use this as a template
/datum/subsystem/ticker/proc/station_explosion_cinematic(station_missed=0, override = null)
	if( cinematic )
		return	//already a cinematic in progress!

	for (var/datum/html_interface/hi in html_interfaces)
		hi.closeAll()
	//initialise our cinematic screen object
	cinematic = new /obj/screen{icon='icons/effects/station_explosion.dmi';icon_state="station_intact";layer=21;mouse_opacity=0;screen_loc="1,0";}(src)

	var/obj/structure/bed/temp_buckle = new(src)
	if(station_missed)
		for(var/mob/M in mob_list)
			M.buckled = temp_buckle				//buckles the mob so it can't do anything
			if(M.client)
				M.client.screen += cinematic	//show every client the cinematic
	else	//nuke kills everyone on z-level 1 to prevent "hurr-durr I survived"
		for(var/mob/M in mob_list)
			M.buckled = temp_buckle
			if(M.client)
				M.client.screen += cinematic
			if(M.stat != DEAD)
				var/turf/T = get_turf(M)
				if(T && T.z==1)
					// The chef's meat locker is lead-lined to improve the taste of the meat
					if (!istype(M.loc, /obj/structure/closet/secure_closet/freezer/meat))
						M.death(0) //no mercy
					else
						M << "The freezer wobbles a bit, then stops. You let out a sigh of relief.";

	//Now animate the cinematic
	switch(station_missed)
		if(1)	//nuke was nearby but (mostly) missed
			if( mode && !override )
				override = mode.name
			switch( override )
				if("nuclear emergency") //Nuke wasn't on station when it blew up
					flick("intro_nuke",cinematic)
					sleep(35)
					world << sound('sound/effects/explosionfar.ogg')
					flick("station_intact_fade_red",cinematic)
					cinematic.icon_state = "summary_nukefail"
				if("gang war") //Gang Domination (just show the override screen)
					cinematic.icon_state = "intro_malf_still"
					flick("intro_malf",cinematic)
					sleep(70)
				if("fake") //The round isn't over, we're just freaking people out for fun
					flick("intro_nuke",cinematic)
					sleep(35)
					world << sound('sound/items/bikehorn.ogg')
					flick("summary_selfdes",cinematic)
				if("HONK")
					flick("intro_nuke",cinematic)
					sleep(35)
					world << sound('sound/items/AirHorn.ogg')
					flick("summary_selfdes",cinematic)
				else
					flick("intro_nuke",cinematic)
					sleep(35)
					world << sound('sound/effects/explosionfar.ogg')
					//flick("end",cinematic)


		if(2)	//nuke was nowhere nearby	//TODO: a really distant explosion animation
			sleep(50)
			world << sound('sound/effects/explosionfar.ogg')
		else	//station was destroyed
			if( mode && !override )
				override = mode.name
			switch( override )
				if("nuclear emergency") //Nuke Ops successfully bombed the station
					flick("intro_nuke",cinematic)
					sleep(35)
					flick("station_explode_fade_red",cinematic)
					world << sound('sound/effects/explosionfar.ogg')
					cinematic.icon_state = "summary_nukewin"
				if("AI malfunction") //Malf (screen,explosion,summary)
					flick("intro_malf",cinematic)
					sleep(76)
					flick("station_explode_fade_red",cinematic)
					world << sound('sound/effects/explosionfar.ogg')
					cinematic.icon_state = "summary_malf"
				if("blob") //Station nuked (nuke,explosion,summary)
					flick("intro_nuke",cinematic)
					sleep(35)
					flick("station_explode_fade_red",cinematic)
					world << sound('sound/effects/explosionfar.ogg')
					cinematic.icon_state = "summary_selfdes"
				if("no_core") //Nuke failed to detonate as it had no core
					flick("intro_nuke",cinematic)
					sleep(35)
					flick("station_intact",cinematic)
					world << sound('sound/ambience/signal.ogg')
					sleep(100)
					if(cinematic)
						qdel(cinematic)
						cinematic = null
					if(temp_buckle)
						qdel(temp_buckle)
					return	//Faster exit, since nothing happened
				else //Station nuked (nuke,explosion,summary)
					flick("intro_nuke",cinematic)
					sleep(35)
					flick("station_explode_fade_red", cinematic)
					world << sound('sound/effects/explosionfar.ogg')
					cinematic.icon_state = "summary_selfdes"
	//If its actually the end of the round, wait for it to end.
	//Otherwise if its a verb it will continue on afterwards.
	spawn(300)
		if(cinematic)
			qdel(cinematic)		//end the cinematic
		if(temp_buckle)
			qdel(temp_buckle)	//release everybody
	return



/datum/subsystem/ticker/proc/create_characters()
	for(var/mob/new_player/player in player_list)
		if(player.ready && player.mind)
			joined_player_list += player.ckey
			if(player.mind.assigned_role=="AI")
				player.close_spawn_windows()
				player.AIize()
			else
				player.create_character()
				qdel(player)
		else
			if(player.client)
				if(player.client.prefs.agree < MAXAGREE)
					player.disclaimer()
				else
					player.new_player_panel()


/datum/subsystem/ticker/proc/collect_minds()
	for(var/mob/living/player in player_list)
		if(player.mind)
			ticker.minds += player.mind


/datum/subsystem/ticker/proc/equip_characters()
	var/captainless=1
	for(var/mob/living/carbon/human/player in player_list)
		if(player && player.mind && player.mind.assigned_role)
			if(player.mind.assigned_role == "Captain")
				captainless=0
			if(player.mind.assigned_role != player.mind.special_role)
				SSjob.EquipRank(player, player.mind.assigned_role, 0)
	if(captainless)
		for(var/mob/M in player_list)
			if(!istype(M,/mob/new_player))
				M << "Captainship not forced on anyone."



/datum/subsystem/ticker/proc/declare_completion()
	var/station_evacuated = EMERGENCY_ESCAPED_OR_ENDGAMED
	var/num_survivors = 0
	var/num_escapees = 0

	world << "<BR><BR><BR><FONT size=3><B>The round has ended.</B></FONT>"

	//Player status report
	for(var/mob/Player in mob_list)
		if(Player.mind && !isnewplayer(Player))
			if(Player.stat != DEAD && !isbrain(Player))
				num_survivors++
				if(station_evacuated) //If the shuttle has already left the station
					if(!Player.onCentcom() && !Player.onSyndieBase())
						Player << "<font color='blue'><b>You managed to survive, but were marooned on [station_name()]...</b></FONT>"
					else
						num_escapees++
						Player << "<font color='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></FONT>"
				else
					Player << "<font color='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></FONT>"
			else
				Player << "<font color='red'><b>You did not survive the events on [station_name()]...</b></FONT>"

	//Round statistics report
	var/datum/station_state/end_state = new /datum/station_state()
	end_state.count()
	var/station_integrity = min(round( 100 * start_state.score(end_state), 0.1), 100)

	world << "<BR>[TAB]Shift Duration: <B>[round(world.time / 36000)]:[add_zero("[world.time / 600 % 60]", 2)]:[world.time / 100 % 6][world.time / 100 % 10]</B>"
	world << "<BR>[TAB]Station Integrity: <B>[mode.station_was_nuked ? "<font color='red'>Destroyed</font>" : "[station_integrity]%"]</B>"
	if(joined_player_list.len)
		world << "<BR>[TAB]Total Population: <B>[joined_player_list.len]</B>"
		if(station_evacuated)
			world << "<BR>[TAB]Evacuation Rate: <B>[num_escapees] ([round((num_escapees/joined_player_list.len)*100, 0.1)]%)</B>"
		world << "<BR>[TAB]Survival Rate: <B>[num_survivors] ([round((num_survivors/joined_player_list.len)*100, 0.1)]%)</B>"
	world << "<BR>"

	//Silicon laws report
	for (var/mob/living/silicon/ai/aiPlayer in mob_list)
		if (aiPlayer.stat != 2 && aiPlayer.mind)
			world << "<b>[aiPlayer.name] (Played by: [aiPlayer.mind.key])'s laws at the end of the round were:</b>"
			aiPlayer.show_laws(1)
		else if (aiPlayer.mind) //if the dead ai has a mind, use its key instead
			world << "<b>[aiPlayer.name] (Played by: [aiPlayer.mind.key])'s laws when it was deactivated were:</b>"
			aiPlayer.show_laws(1)

		world << "<b>Total law changes: [aiPlayer.law_change_counter]</b>"

		if (aiPlayer.connected_robots.len)
			var/robolist = "<b>[aiPlayer.real_name]'s minions were:</b> "
			for(var/mob/living/silicon/robot/robo in aiPlayer.connected_robots)
				if(robo.mind)
					robolist += "[robo.name][robo.stat?" (Deactivated) (Played by: [robo.mind.key]), ":" (Played by: [robo.mind.key]), "]"
			world << "[robolist]"
	for (var/mob/living/silicon/robot/robo in mob_list)
		if (!robo.connected_ai && robo.mind)
			if (robo.stat != 2)
				world << "<b>[robo.name] (Played by: [robo.mind.key]) survived as an AI-less borg! Its laws were:</b>"
			else
				world << "<b>[robo.name] (Played by: [robo.mind.key]) was unable to survive the rigors of being a cyborg without an AI. Its laws were:</b>"

			if(robo) //How the hell do we lose robo between here and the world messages directly above this?
				robo.laws.show_laws(world)

	mode.declare_completion()//To declare normal completion.

	//calls auto_declare_completion_* for all modes
	for(var/handler in typesof(/datum/game_mode/proc))
		if (findtext("[handler]","auto_declare_completion_"))
			call(mode, handler)(force_ending)

	//Print a list of antagonists to the server log
	var/list/total_antagonists = list()
	//Look into all mobs in world, dead or alive
	for(var/datum/mind/Mind in minds)
		var/temprole = Mind.special_role
		if(temprole)							//if they are an antagonist of some sort.
			if(temprole in total_antagonists)	//If the role exists already, add the name to it
				total_antagonists[temprole] += ", [Mind.name]([Mind.key])"
			else
				total_antagonists.Add(temprole) //If the role doesnt exist in the list, create it and add the mob
				total_antagonists[temprole] += ": [Mind.name]([Mind.key])"

	//Now print them all into the log!
	log_game("Antagonists at round end were...")
	for(var/i in total_antagonists)
		log_game("[i]s[total_antagonists[i]].")

	//Adds the del() log to world.log in a format condensable by the runtime condenser found in tools
	if(SSgarbage.didntgc.len)
		var/dellog = ""
		for(var/path in SSgarbage.didntgc)
			dellog += "Path : [path] \n"
			dellog += "Failures : [SSgarbage.didntgc[path]] \n"
		world.log << dellog

	return 1

/datum/subsystem/ticker/proc/send_random_tip()
	var/list/randomtips = file2list("config/tips.txt")
	var/list/memetips = file2list("config/sillytips.txt")
	if(randomtips.len && prob(95))
		world << "<font color='purple'><b>Tip of the round: </b>[html_encode(pick(randomtips))]</font>"
	else if(memetips.len)
		world << "<font color='purple'><b>Tip of the round: </b>[html_encode(pick(memetips))]</font>"

/datum/subsystem/ticker/proc/check_queue()
	if(!queued_players.len || !config.hard_popcap)
		return

	queue_delay++
	var/mob/new_player/next_in_line = queued_players[1]

	switch(queue_delay)
		if(5) //every 5 ticks check if there is a slot available
			if(living_player_count() < config.hard_popcap)
				if(next_in_line && next_in_line.client)
					next_in_line << "<span class='userdanger'>A slot has opened! You have approximately 20 seconds to join. <a href='?src=\ref[next_in_line];late_join=override'>\>\>Join Game\<\<</a></span>"
					next_in_line << sound('sound/misc/notice1.ogg')
					next_in_line.LateChoices()
					return
				queued_players -= next_in_line //Client disconnected, remove he
			queue_delay = 0 //No vacancy: restart timer
		if(25 to INFINITY)  //No response from the next in line when a vacancy exists, remove he
			next_in_line << "<span class='danger'>No response recieved. You have been removed from the line.</span>"
			queued_players -= next_in_line
			queue_delay = 0

/datum/subsystem/ticker/proc/check_maprotate()
	if (!config.maprotation || !SERVERTOOLS)
		return
	if (SSshuttle.emergency.mode != SHUTTLE_ESCAPE || SSshuttle.canRecall())
		return
	if (maprotatechecked)
		return

	maprotatechecked = 1

	//map rotate chance defaults to 75% of the length of the round (in minutes)
	if (!prob((world.time/600)*config.maprotatechancedelta))
		return
	spawn(0) //compiling a map can lock up the mc for 30 to 60 seconds if we don't spawn
		maprotate()


/world/proc/has_round_started()
	if (ticker && ticker.current_state >= GAME_STATE_PLAYING)
		return TRUE
	return FALSE

/datum/subsystem/ticker/Recover()
	current_state = ticker.current_state
	force_ending = ticker.force_ending
	hide_mode = ticker.hide_mode
	mode = ticker.mode
	event_time = ticker.event_time
	event = ticker.event

	login_music = ticker.login_music
	round_end_sound = ticker.round_end_sound

	minds = ticker.minds

	Bible_icon_state = ticker.Bible_icon_state
	Bible_item_state = ticker.Bible_item_state
	Bible_name = ticker.Bible_name
	Bible_deity_name = ticker.Bible_deity_name

	syndicate_coalition = ticker.syndicate_coalition
	factions = ticker.factions
	availablefactions = ticker.availablefactions

	delay_end = ticker.delay_end

	triai = ticker.triai
	tipped = ticker.tipped

	timeLeft = ticker.timeLeft

	totalPlayers = ticker.totalPlayers
	totalPlayersReady = ticker.totalPlayersReady

	queue_delay = ticker.queue_delay
	queued_players = ticker.queued_players
	cinematic = ticker.cinematic
	maprotatechecked = ticker.maprotatechecked
