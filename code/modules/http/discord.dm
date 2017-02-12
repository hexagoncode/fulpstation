/proc/send_discord_message(var/channel, var/message)
	if(discord_token == "nodiscord")
		return
	shell("python ByondPOST.pyc \"https://discordapp.com/api/channels/[discord_channels[channel]]/messages\" \"[message]\" \"Bot [discord_token]\" ")
