	////////////
	//SECURITY//
	////////////
#define UPLOAD_LIMIT		1048576	//Restricts client uploads to the server to 1MB //Could probably do with being lower.

	/*
	When somebody clicks a link in game, this Topic is called first.
	It does the stuff in this proc and  then is redirected to the Topic() proc for the src=[0xWhatever]
	(if specified in the link). ie locate(hsrc).Topic()

	Such links can be spoofed.

	Because of this certain things MUST be considered whenever adding a Topic() for something:
		- Can it be fed harmful values which could cause runtimes?
		- Is the Topic call an admin-only thing?
		- If so, does it have checks to see if the person who called it (usr.client) is an admin?
		- Are the processes being called by Topic() particularly laggy?
		- If so, is there any protection against somebody spam-clicking a link?
	If you have any  questions about this stuff feel free to ask. ~Carn
	*/
/client/Topic(href, href_list, hsrc)
	if(!usr || usr != mob)	//stops us calling Topic for somebody else's client. Also helps prevent usr=null
		return
	// asset_cache
	if(href_list["asset_cache_confirm_arrival"])
		//src << "ASSET JOB [href_list["asset_cache_confirm_arrival"]] ARRIVED."
		var/job = text2num(href_list["asset_cache_confirm_arrival"])
		completed_asset_jobs += job
		return

	// Admin PM
	if(href_list["priv_msg"])
		if (href_list["ticket"])
			var/datum/admin_ticket/T = locate(href_list["ticket"])

			if(holder && T.resolved)
				var/found_ticket = 0
				for(var/datum/admin_ticket/T2 in tickets_list)
					if(!T.resolved && compare_ckey(T.owner_ckey, T2.owner_ckey))
						found_ticket = 1

				if(!found_ticket)
					if(alert(usr, "No open ticket exists, would you like to make a new one?", "Tickets", "New ticket", "Cancel") == "Cancel")
						return
			else if(!holder && T.resolved)
				usr << "<span class='boldnotice'>Your ticket was closed. Only admins can add finishing comments to it.</span>"
				return

			if(get_ckey(usr) == get_ckey(T.owner))
				T.owner.cmd_admin_pm(get_ckey(T.handling_admin),null)
			else if(get_ckey(usr) == get_ckey(T.handling_admin))
				T.handling_admin.cmd_admin_pm(get_ckey(T.owner),null)
			else
				cmd_admin_pm(get_ckey(T.owner),null)
			return

		if(href_list["new"])
			var/datum/admin_ticket/T = locate(href_list["ticket"])
			if(T.handling_admin && !compare_ckey(T.handling_admin, usr))
				usr << "Using this PM-link for this ticket would usually be the first response to a ticket. However, an admin has already responded to this ticket. This link is now disabled, to ensure that no additional tickets are created for the same problem. You can create a new ticket by PMing the user any other way."
				return
			else
				T.pm_started_user = get_client(usr)
		if (href_list["ahelp_reply"])
			cmd_ahelp_reply(href_list["priv_msg"])
			return
		cmd_admin_pm(href_list["priv_msg"],null)
		return

	if(href_list["view_admin_ticket"])
		var/id = text2num(href_list["view_admin_ticket"])
		var/client/C = usr.client
		if(!C.holder)
			message_admins("EXPLOIT \[admin_ticket\]: [usr] attempted to operate ticket [id].")
			return

		for(var/datum/admin_ticket/T in tickets_list)
			if(T.ticket_id == id)
				T.view_log()
				return

		usr << "The ticket ID #[id] doesn't exist."

		return

	if(prefs.afreeze && !holder)
		src << "<span class='userdanger'>You are frozen by an administrator.</span>"
		return
	//Logs all hrefs
	if(config && config.log_hrefs && href_logfile)
		href_logfile << "<small>[time2text(world.timeofday,"hh:mm")] [src] (usr:[usr])</small> || [hsrc ? "[hsrc] " : ""][href]<br>"

	switch(href_list["_src_"])
		if("holder")
			hsrc = holder
		if("usr")
			hsrc = mob
		if("prefs")
			return prefs.process_link(usr,href_list)
		if("vars")
			return view_var_Topic(href,href_list,hsrc)

	..()	//redirect to hsrc.Topic()

/client/proc/is_content_unlocked()
	if(!prefs.unlock_content)
		src << "Become a BYOND member to access member-perks and features, as well as support the engine that makes this game possible. Only 10 bucks for 3 months! <a href='http://www.byond.com/membership'>Click Here to find out more</a>."
		return 0
	return 1

/client/proc/handle_spam_prevention(message, mute_type)
	if(config.automute_on && !holder)
		if(last_message == message && message != "" && message != " ")
			last_message_count++
			if(last_message_count >= SPAM_TRIGGER_AUTOMUTE_IDENTICAL)
				src << "<span class='danger'>You have exceeded the spam filter limit for identical messages. An auto-mute was applied.</span>"
				cmd_admin_mute(src, mute_type, 1)
				var/admins_online = total_admins_active()
				if(admins_online == 0)
					src << "<span class='notice'>Your auto mute will be lifted in 5 minutes due to no admins being online.</span>"
					spawn(3000)
						var/datum/preferences/P
						P = src.prefs
						P.muted &= ~mute_type
						src << "<span class='notice'>Your auto mute has been lifted. You may now speak.</span>"
				return 1
			if(last_message_count >= SPAM_TRIGGER_WARNING_IDENTICAL)
				src << "<span class='danger'>You are nearing the spam filter limit for identical messages.</span>"
		else
			last_message_count = 0
			last_message = message

		if((world.time - last_message_time) < SPAM_TRIGGER_AUTOMUTE_TIME && message != "" && message != " ")
			fast_message_count++
			if(fast_message_count >= SPAM_TRIGGER_AUTOMUTE)
				src << "<span class='danger'>You have exceeded the spam filter limit for messages in a short time period. An auto-mute was applied.</span>"
				cmd_admin_mute(src, mute_type, 1)
				var/admins_online = total_admins_active()
				if(admins_online == 0)
					src << "<span class='notice'>Your auto mute will be lifted in 5 minutes due to no admins being online.</span>"
					spawn(3000)
						var/datum/preferences/P
						P = src.prefs
						P.muted &= ~mute_type
						src << "<span class='notice'>Your auto mute has been lifted. You may now speak.</span>"
				return 1
			if(fast_message_count >= SPAM_TRIGGER_WARNING)
				src << "<span class='danger'>You are nearing the spam filter limit for messages in a short time period.</span>"
		else
			fast_message_count = 0
		last_message_time = world.time

	return 0

//This stops files larger than UPLOAD_LIMIT being sent from client to server via input(), client.Import() etc.
/client/AllowUpload(filename, filelength)
	if(filelength > UPLOAD_LIMIT)
		src << "<font color='red'>Error: AllowUpload(): File Upload too large. Upload Limit: [UPLOAD_LIMIT/1024]KiB.</font>"
		return 0
/*	//Don't need this at the moment. But it's here if it's needed later.
	//Helps prevent multiple files being uploaded at once. Or right after eachother.
	var/time_to_wait = fileaccess_timer - world.time
	if(time_to_wait > 0)
		src << "<font color='red'>Error: AllowUpload(): Spam prevention. Please wait [round(time_to_wait/10)] seconds.</font>"
		return 0
	fileaccess_timer = world.time + FTPDELAY	*/
	return 1


	///////////
	//CONNECT//
	///////////
#if (PRELOAD_RSC == 0)
var/list/external_rsc_urls
var/next_external_rsc = 0
#endif


/client/New(TopicData)

	TopicData = null							//Prevent calls to client.Topic from connect

	if(connection != "seeker" && connection != "web")//Invalid connection type.
		return null

	spawn(30)
		antag_token_reload_from_db(src)
		//credits_reload_from_db(src)

		for(var/datum/admin_ticket/T in tickets_list)
			if(compare_ckey(T.owner_ckey, src) && !T.resolved)
				T.owner = src
				T.add_log(new /datum/ticket_log(T, src, "¤ Connected ¤", 1), src)
				break
			if(compare_ckey(T.handling_admin, src) && !T.resolved)
				T.handling_admin = src
				T.add_log(new /datum/ticket_log(T, src, "¤ Connected ¤", 1), src)
				break

#if (PRELOAD_RSC == 0)
	if(external_rsc_urls && external_rsc_urls.len)
		next_external_rsc = Wrap(next_external_rsc+1, 1, external_rsc_urls.len+1)
		preload_rsc = external_rsc_urls[next_external_rsc]
#endif

	clients += src
	directory[ckey] = src

	//Admin Authorisation

	var/localhost_addresses = list("127.0.0.1", "::1")
	if(address && (address in localhost_addresses))
		var/datum/admin_rank/localhost_rank = new("!localhost!", R_MAXPERMISSION - 1 - R_NOJOIN)
		if(localhost_rank)
			var/datum/admins/localhost_holder = new(localhost_rank, ckey)
			localhost_holder.associate(src)

	if(protected_config.autoadmin)
		if(!admin_datums[ckey])
			var/datum/admin_rank/autorank
			for(var/datum/admin_rank/R in admin_ranks)
				if(R.name == protected_config.autoadmin_rank)
					autorank = R
					break
			if(!autorank)
				world << "Autoadmin rank not found"
			else
				var/datum/admins/D = new(autorank, ckey)
				admin_datums[ckey] = D
	holder = admin_datums[ckey]
	if(holder)
		admins |= src
		holder.owner = src

	//Need to load before we load preferences for correctly removing Ultra if user no longer whitelisted
	is_whitelisted = is_job_whitelisted(src)

	//preferences datum - also holds some persistant data for the client (because we may as well keep these datums to a minimum)
	prefs = preferences_datums[ckey]
	if(!prefs)
		prefs = new /datum/preferences(src)
		preferences_datums[ckey] = prefs
	prefs.last_ip = address				//these are gonna be used for banning
	prefs.last_id = computer_id			//these are gonna be used for banning
	if(ckey in donators)
		prefs.unlock_content |= 2
		add_donor_verbs()
	else
		prefs.unlock_content &= ~2
		if(prefs.toggles & QUIET_ROUND)
			prefs.toggles &= ~QUIET_ROUND
			prefs.save_preferences()
	sethotkeys(1) //use preferences to set hotkeys (from_pref = 1)

	. = ..()	//calls mob.Login()

	if (byond_version < config.client_error_version)		//Out of date client.
		src << "<span class='danger'><b>Your version of byond is too old:</b></span>"
		src << config.client_error_message
		src << "Your version: [byond_version]"
		src << "Required version: [config.client_error_version] or later"
		src << "Visit http://www.byond.com/download/ to get the latest version of byond."
		if (holder)
			src << "Because you are an admin, you are being allowed to walk past this limitation, But it is still STRONGLY suggested you upgrade"
		else
			del(src)
			return 0
	else if (byond_version < config.client_warn_version)	//We have words for this client.
		src << "<span class='danger'><b>Your version of byond may be getting out of date:</b></span>"
		src << config.client_warn_message
		src << "Your version: [byond_version]"
		src << "Required version to remove this message: [config.client_warn_version] or later"
		src << "Visit http://www.byond.com/download/ to get the latest version of byond."

	if (connection == "web")
		if (!config.allowwebclient)
			src << "Web client is disabled"
			del(src)
			return 0
		if (config.webclientmembersonly && !IsByondMember())
			src << "Sorry, but the web client is restricted to byond members only."
			del(src)
			return 0

	if( (world.address == address || !address) && !host )
		host = key
		world.update_status()

	if(holder)
		message_admins("Admin login: [key_name(src)]")
		if(config.allow_vote_restart && check_rights_for(src, R_ADMIN))
			log_admin("Staff joined with +ADMIN. Restart vote disallowed.")
			message_admins("Staff joined with +ADMIN. Restart vote disallowed.")
			config.allow_vote_restart = 0
		add_admin_verbs()
		add_donor_verbs()
		admin_memo_output("Show")
		if((global.comms_key == "default_pwd" || length(global.comms_key) <= 6) && global.comms_allowed) //It's the default value or less than 6 characters long, but it somehow didn't disable comms.
			src << "<span class='danger'>The server's API key is either too short or is the default value! Consider changing it immediately!</span>"
		//verbs += /client/verb/weightstats

	add_verbs_from_config()
	set_client_age_from_db()

	if (isnum(player_age) && player_age == -1) //first connection
		if (config.panic_bunker && !holder && !(ckey in deadmins))
			log_access("Failed Login: [key] - New account attempting to connect during panic bunker")
			message_admins("<span class='adminnotice'>Failed Login: [key] - New account attempting to connect during panic bunker</span>")
			src << "Sorry but the server is currently not accepting connections from never before seen players."
			del(src)
			return 0

		if (config.notify_new_player_age >= 0)
			message_admins("New user: [key_name_admin(src)] is connecting here for the first time.")
			if (config.irc_first_connection_alert)
				send2irc_adminless_only("New-user", "[key_name(src)] is connecting for the first time!")

		player_age = 0 // set it from -1 to 0 so the job selection code doesn't have a panic attack

	else if (isnum(player_age) && player_age < config.notify_new_player_age)
		message_admins("New user: [key_name_admin(src)] just connected with an age of [player_age] day[(player_age==1?"":"s")]")

	findJoinDate()

	sync_client_with_db()

	send_resources()

	if(!void)
		void = new()
		void = void.MakeGreed()

	screen += void

	if(prefs.lastchangelog != changelog_hash) //bolds the changelog button on the interface so we know there are updates.
		src << "<span class='info'>You have unread updates in the changelog.</span>"
		if(config.aggressive_changelog)
			changelog()
		else
			winset(src, "infowindow.changelog", "font-style=bold")

	if(ckey in clientmessages)
		for(var/message in clientmessages[ckey])
			src << message
		clientmessages.Remove(ckey)

	if(holder || !config.admin_who_blocked)
		verbs += /client/proc/adminwho

	if(config && config.autoconvert_notes)
		convert_notes_sql(ckey)

	if(!winexists(src, "asset_cache_browser")) // The client is using a custom skin, tell them.
		src << "<span class='warning'>Unable to access asset cache browser, if you are using a custom skin file, please allow DS to download the updated version, if you are not, then make a bug report. This is not a critical issue but can cause issues with resource downloading, as it is impossible to know when extra resources arrived to you.</span>"

	world.manage_fps()

	//This is down here because of the browse() calls in tooltip/New()
	if(!tooltips)
		tooltips = new /datum/tooltip(src)


//////////////
//DISCONNECT//
//////////////

/client/Del()
	for(var/datum/admin_ticket/T in tickets_list)
		if(compare_ckey(T.owner_ckey, usr) && !T.resolved)
			T.add_log(new /datum/ticket_log(T, src, "¤ Disconnected ¤", 1))

	if(holder)
		adminGreet(1)
		holder.owner = null
		admins -= src
		if(!total_admins_active())
			if(total_unresolved_tickets())
				send_discord_message("admin", "The last remaining active admin has logged out, There are now a total of [total_unresolved_tickets()] unresolved tickets.")
	sync_logout_with_db(connection_number)
	directory -= ckey
	clients -= src

	world.manage_fps()

	return ..()

/client/proc/sync_logout_with_db(number)
	if(!number || !isnum(number))
		return
	establish_db_connection()
	if (!dbcon.IsConnected())
		return
	var/DBQuery/query_logout = dbcon.NewQuery("UPDATE `[format_table_name("connection_log")]` SET `left`=Now() WHERE `id`=[number];")
	query_logout.Execute()

/client/proc/set_client_age_from_db()
	if (IsGuestKey(src.key))
		return

	establish_db_connection()
	if(!dbcon.IsConnected())
		return

	var/sql_ckey = sanitizeSQL(src.ckey)

	var/DBQuery/query = dbcon.NewQuery("SELECT id, datediff(Now(),firstseen) as age FROM [format_table_name("player")] WHERE ckey = '[sql_ckey]'")
	if (!query.Execute())
		return

	while (query.NextRow())
		player_age = text2num(query.item[2])
		return

	//no match mark it as a first connection for use in client/New()
	player_age = -1


/client/proc/sync_client_with_db()
	if (IsGuestKey(src.key))
		return

	establish_db_connection()
	if (!dbcon.IsConnected())
		return

	var/sql_ckey = sanitizeSQL(ckey)

	var/DBQuery/query_ip = dbcon.NewQuery("SELECT ckey FROM [format_table_name("player")] WHERE ip = '[address]' AND ckey != '[sql_ckey]'")
	query_ip.Execute()
	related_accounts_ip = ""
	while(query_ip.NextRow())
		related_accounts_ip += "[query_ip.item[1]], "

	var/DBQuery/query_cid = dbcon.NewQuery("SELECT ckey FROM [format_table_name("player")] WHERE computerid = '[computer_id]' AND ckey != '[sql_ckey]'")
	query_cid.Execute()
	related_accounts_cid = ""
	while (query_cid.NextRow())
		related_accounts_cid += "[query_cid.item[1]], "

	var/admin_rank = "Player"
	if (src.holder && src.holder.rank)
		admin_rank = src.holder.rank.name
	else
		if (check_randomizer())
			return


	var/watchreason = check_watchlist(sql_ckey)
	if(watchreason)
		message_admins("<font color='red'><B>Notice: </B></font><font color='blue'>[key_name_admin(src)] is on the watchlist and has just connected - Reason: [watchreason]</font>")
		send2irc_adminless_only("Watchlist", "[key_name(src)] is on the watchlist and has just connected - Reason: [watchreason]")


	var/sql_ip = sanitizeSQL(src.address)
	var/sql_computerid = sanitizeSQL(src.computer_id)
	var/sql_admin_rank = sanitizeSQL(admin_rank)

	var/DBQuery/query_insert = dbcon.NewQuery("INSERT INTO [format_table_name("player")] (id, ckey, firstseen, lastseen, ip, computerid, lastadminrank) VALUES (null, '[sql_ckey]', Now(), Now(), '[sql_ip]', '[sql_computerid]', '[sql_admin_rank]') ON DUPLICATE KEY UPDATE lastseen = VALUES(lastseen), ip = VALUES(ip), computerid = VALUES(computerid), lastadminrank = VALUES(lastadminrank)")
	query_insert.Execute()

	//Logging player access
	var/serverip = "[world.internet_address]:[world.port]"
	var/DBQuery/query_accesslog = dbcon.NewQuery("INSERT INTO `[format_table_name("connection_log")]` (`id`,`datetime`,`serverip`,`ckey`,`ip`,`computerid`) VALUES(null,Now(),'[serverip]','[sql_ckey]','[sql_ip]','[sql_computerid]');")
	query_accesslog.Execute()
	var/DBQuery/query_getid = dbcon.NewQuery("SELECT `id` FROM `[format_table_name("connection_log")]` WHERE `serverip`='[serverip]' AND `ckey`='[sql_ckey]' AND `ip`='[sql_ip]' AND `computerid`='[sql_computerid]' ORDER BY datetime DESC LIMIT 1;")
	query_getid.Execute()
	while (query_getid.NextRow())
		connection_number = text2num(query_getid.item[1])

/client/proc/add_verbs_from_config()
	if(config.see_own_notes)
		verbs += /client/proc/self_notes


#undef TOPIC_SPAM_DELAY
#undef UPLOAD_LIMIT
#undef MIN_CLIENT_VERSION

//checks if a client is afk
//3000 frames = 5 minutes
/client/proc/is_afk(duration=3000)
	if(inactivity > duration)
		return inactivity
	return 0

// Byond seemingly calls stat, each tick.
// Calling things each tick can get expensive real quick.
// So we slow this down a little.
// See: http://www.byond.com/docs/ref/info.html#/client/proc/Stat
/client/Stat()
	. = ..()
	if (holder)
		sleep(1)
	else
		sleep(5)
		stoplag()

//send resources to the client. It's here in its own proc so we can move it around easiliy if need be
/client/proc/send_resources()
	//get the common files
	getFiles(
		'html/search.js',
		'html/panels.css',
		'html/browser/common.css',
		'html/browser/scannernew.css',
		'html/browser/playeroptions.css',
		)
	spawn (10) //removing this spawn causes all clients to not get verbs.
		//Precache the client with all other assets slowly, so as to not block other browse() calls
		getFilesSlow(src, SSasset.cache, register_asset = FALSE)

/client/proc/check_randomizer()
	. = FALSE
	if (!config.check_randomizer)
		return
	var/static/cidcheck = list()
	var/static/cidcheck_failedckeys = list() //to avoid spamming the admins if the same guy keeps trying.

	var/oldcid = cidcheck[ckey]
	if (oldcid)
		if (oldcid != computer_id) //IT CHANGED!!!
			cidcheck -= ckey //so they can try again after removing the cid randomizer.

			src << "<span class='userdanger'>Connection Error:</span>"
			src << "<span class='danger'>Invalid ComputerID(spoofed). Please remove the ComputerID spoofer from your byond installation and try again.</span>"

			if (!cidcheck_failedckeys[ckey])
				message_admins("<span class='adminnotice'>[key_name(src)] has been detected as using a cid randomizer. Connection rejected.</span>")
				send2irc_adminless_only("CidRandomizer", "[key_name(src)] has been detected as using a cid randomizer. Connection rejected.")
				cidcheck_failedckeys[ckey] = 1
				note_randomizer_user()

			log_access("Failed Login: [key] [computer_id] [address] - CID randomizer confirmed (oldcid: [oldcid])")

			del(src)
			return TRUE
		else
			if (cidcheck_failedckeys[ckey])
				message_admins("<span class='adminnotice'>[key_name_admin(src)] has been allowed to connect after showing they removed their cid randomizer</span>")
				send2irc_adminless_only("CidRandomizer", "[key_name(src)] has been allowed to connect after showing they removed their cid randomizer.")
				cidcheck_failedckeys -= ckey
			cidcheck -= ckey
	else
		var/sql_ckey = sanitizeSQL(ckey)
		var/DBQuery/query_cidcheck = dbcon.NewQuery("SELECT computerid FROM [format_table_name("player")] WHERE ckey = '[sql_ckey]'")
		query_cidcheck.Execute()

		var/lastcid
		if (query_cidcheck.NextRow())
			lastcid = query_cidcheck.item[1]

		if (computer_id != lastcid)
			cidcheck[ckey] = computer_id
			log_access("Failed Login: [key] [computer_id] [address] - CID randomizer check")

			var/url = winget(src, null, "url")
			//special javascript to make them reconnect under a new window.
			src << browse("<a id='link' href=byond://[url]>byond://[url]</a><script type='text/javascript'>document.getElementById(\"link\").click();window.location=\"byond://winset?command=.quit\"</script>", "border=0;titlebar=0;size=1x1")
			winset(src, "reconnectbutton", "is-disable=true") //reconnect keeps the same cid in the randomizer, they could use this button to fake it.
			sleep(10) //browse is queued, we don't want them to disconnect before getting the browse() command.

			//teeheehee (in case the above method doesn't work, its not 100% reliable.)
			src << "<pre class=\"system system\">Network connection shutting down due to read error.</pre>"
			del(src)
			return TRUE

/client/proc/note_randomizer_user()
	var/const/adminckey = "CID-Error"
	var/sql_ckey = sanitizeSQL(ckey)
	//check to see if we noted them in the last day.
	var/DBQuery/query_get_notes = dbcon.NewQuery("SELECT id FROM [format_table_name("notes")] WHERE ckey = '[sql_ckey]' AND adminckey = '[adminckey]' AND timestamp + INTERVAL 1 DAY < NOW()")
	if(!query_get_notes.Execute())
		var/err = query_get_notes.ErrorMsg()
		log_game("SQL ERROR obtaining id from notes table. Error : \[[err]\]\n")
		return
	if (query_get_notes.NextRow())
		return

	//regardless of above, make sure their last note is not from us, as no point in repeating the same note over and over.
	query_get_notes = dbcon.NewQuery("SELECT adminckey FROM [format_table_name("notes")] WHERE ckey = '[sql_ckey]' ORDER BY timestamp DESC LIMIT 1")
	if(!query_get_notes.Execute())
		var/err = query_get_notes.ErrorMsg()
		log_game("SQL ERROR obtaining id from notes table. Error : \[[err]\]\n")
		return
	if (query_get_notes.NextRow())
		if (query_get_notes.item[1] == adminckey)
			return
	add_note(ckey, "Detected as using a cid randomizer.", null, adminckey, logged = 0)
