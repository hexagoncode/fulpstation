##Fulpstation

###  ***Transition from old Yogstation README still in progress.***


##DOWNLOADING

There are a number of ways to download the source code. Some are described here, an alternative all-inclusive guide is also located at http://www.tgstation13.org/wiki/Downloading_the_source_code

Option 1:
Follow this: http://www.tgstation13.org/wiki/Setting_up_git

Option 2:
Install GitHub::windows from http://windows.github.com/
It handles most of the setup and configuraton of Git for you.
Then you simply search for the yogstation repository and click the big clone
button.

Option 3: Download the source code as a zip by clicking the ZIP button in the
code tab of https://github.com/yogstation13/yogstation
(note: this will use a lot of bandwidth if you wish to update and is a lot of
hassle if you want to make any changes at all, so it's not recommended.)

##INSTALLATION

First-time installation should be fairly straightforward.  First, you'll need
BYOND installed.  You can get it from http://www.byond.com/.  Once you've done
that, extract the game files to wherever you want to keep them.  This is a
sourcecode-only release, so the next step is to compile the server files.
Open yogstation.dme by double-clicking it, open the Build menu, and click
compile.  This'll take a little while, and if everything's done right you'll get
a message like this:

```
saving yogstation.dmb (DEBUG mode)
yogstation.dmb - 0 errors, 0 warnings
```

If you see any errors or warnings, something has gone wrong - possibly a corrupt
download or the files extracted wrong. If problems persist, ask for assistance
in irc://irc.rizon.net/coderbus

Once that's done, open up the config folder.  You'll want to edit config.txt to
set the probabilities for different gamemodes in Secret and to set your server
location so that all your players don't get disconnected at the end of each
round.  It's recommended you don't turn on the gamemodes with probability 0,
except Extended, as they have various issues and aren't currently being tested,
so they may have unknown and bizarre bugs.  Extended is essentially no mode, and
isn't in the Secret rotation by default as it's just not very fun.

You'll also want to edit config/admins.txt to remove the default admins and add
your own.  "Council Member" is the highest level of access, and probably the one
you'll want to use for now.  You can set up your own ranks and find out more in
config/admin_ranks.txt

The format is

```
byondkey = Rank
```

where the admin rank must be properly capitalised.

Finally, to start the server, run Dream Daemon and enter the path to your
compiled yogstation.dmb file.  Make sure to set the port to the one you
specified in the config.txt, and set the Security box to 'Safe'.  Then press GO
and the server should start up and be ready to join. It is also recommended that
you set up the SQL backend (see below).

###HOSTING ON LINUX
If you're not using BYOND version 510, BYGEX will be used for some text replacement related code. Unfortunately, we only have a windows dll included right now. You can find a version known to compile on linux, along with some basic install instructions here:
https://github.com/optimumtact/byond-regex

##UPDATING

To update an existing installation, first back up your /config and /data folders
as these store your server configuration, player preferences and banlist.

Then, extract the new files (preferably into a clean directory, but updating in
place should work fine), copy your /config and /data folders back into the new
install, overwriting when prompted except if we've specified otherwise, and
recompile the game.  Once you start the server up again, you should be running
the new version.

##MAPS

/tg/station currently comes equipped with seven maps.

* [tgstation2 (default)](http://tgstation13.org/wiki/Boxstation)
* [MetaStation](https://tgstation13.org/wiki/MetaStation)
* [MiniStation](http://tgstation13.org/wiki/MiniStation)
* [AsteroidStation](https://tgstation13.org/wiki/AsteroidStation)
* [BirdStation](https://tgstation13.org/wiki/BirdStation)
* [DreamStation](https://tgstation13.org/wiki/Dreamstation)
* [EfficiencyStation](https://tgstation13.org/wiki/Efficiency_Station)

All maps have their own code file that is in the base of the _maps directory. Instead of loading the map directly we instead use a code file to include the map and then include any other code changes that are needed for it; for example MiniStation changes the uplink items for the map. Follow this guideline when adding your own map, to your fork, for easy compatibility.

If you want to load a different map, just open the corresponding map's code file in Dream Maker, make sure all of the other map code files are unticked in the file tree, in the left side of the screen, and then make sure the map code file you want is ticked.

If you are hosting a server, and want randomly picked maps to be played each round, you can enable map rotation in [config.txt](config/config.txt) and then set the maps to be picked in the [maps.txt](config/maps.txt) file.

Anytime you want to make changes to a map it's imperative you use the [Map Merging tools](http://tgstation13.org/wiki/Map_Merger)

##AWAY MISSIONS

/tg/station supports loading away missions however they are disabled by default.

Map files for away missions are located in the _maps/RandomZLevels directory. Each away mission includes it's own code definitions located in /code/modules/awaymissions/mission_code. These files must be included and compiled with the server beforehand otherwise the server will crash upon trying to load away missions that lack their code.

To enable an away mission open fileList.txt in the _maps/RandomZLevels directory and uncomment one of the .dmm lines by removing the #. If more than one away mission is uncommented then the away mission loader will randomly select one the enabled ones to load.

##SQL SETUP

The SQL backend requires a MySQL server. SQL is required for the library, stats tracking, admin notes, and job-only bans, among other features, mostly related to server administration. Your server details go in /config/dbconfig.txt (please rename or copy dbconfig.txt.example to dbconfig.txt if none is present), and the SQL schema is in /SQL/tgstation_schema.sql and /SQL/tgstation_schema_prefix.sql depending on if you want table prefixes.


##IRC BOT SETUP

Included in the repository is a python3 compatible IRC bot capable of relaying adminhelps to a specified
IRC channel/server, see the /bot folder for more

##CONTRIBUTING

Please see [CONTRIBUTING.md](CONTRIBUTING.md)

##LICENSE

All code after commit 333c566b88108de218d882840e61928a9b759d8f on 2014/31/12 at 4:38 PM PST (https://github.com/tgstation/tgstation/commit/333c566b88108de218d882840e61928a9b759d8f) is licensed under GNU AGPL v3 (http://www.gnu.org/licenses/agpl-3.0.html).

All code before commit 333c566b88108de218d882840e61928a9b759d8f on 2014/31/12 at 4:38 PM PST (https://github.com/tgstation/tgstation/commit/333c566b88108de218d882840e61928a9b759d8f) is licensed under GNU GPL v3 (https://www.gnu.org/licenses/gpl-3.0.html).
(Including tools unless their readme specifies otherwise.)

See LICENSE-AGPLv3.txt and LICENSE-GPLv3.txt for more details.

tgui clientside is licensed as a subproject under the MIT license.
tgui assets are licensed under a Creative Commons Attribution-ShareAlike 4.0 International License
(http://creativecommons.org/licenses/by-sa/4.0/).

See tgui/LICENSE.md for more details.

All assets including icons and sound are under a Creative Commons 3.0 BY-SA
license (http://creativecommons.org/licenses/by-sa/3.0/) unless otherwise indicated.
