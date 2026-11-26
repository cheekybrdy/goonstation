/*
event switcher thing!
Relies a lot on the event_settings stuff in code/event.dm
Datum new() is called near the end of world/New()
*/

var/global/datum/eventSwitchHandler/eventSwitcher

/datum/eventSwitchHandler
	var/active = 0 //set to 1 if the datum initializes correctly
	var/current = null //the human-readable name of the current event
	var/next = null //the human-readable name of the next event, if set
	var/nextPrior = null //the human-readable name of the previous next event, if that makes any sense at all
	var/locked = 0 //set to 1 during a event-switch build

	//reboot delay handling
	var/holdingReboot = 0 //1 if a server reboot was called but we were compiling a new event
	var/rebootRetryDelay = 30 SECONDS //time to wait between attempting another reboot
	var/currentRebootAttempt = 0 //how many times have we attempted a reboot
	var/rebootLimit = 4 //how many times should we attempt a restart before just doing it anyway

	//player vote stuff
	var/votingAllowed = 1 //is event voting allowed?
	var/playersVoting = 0 //are players currently voting on the event?
	var/voteStartedAt = 0 //timestamp when the event vote was started
	var/autoVoteDelay = 30 SECONDS //how long should we wait after round start to trigger to automatic event vote?
	var/autoVoteDuration = 7 MINUTES //how long (in byond deciseconds) the automatic event vote should last (1200 = 2 mins)
	var/voteCurrentDuration = 0 //how long is the current vote set to last?
	var/queuedVoteCompile = 0 //is a player event vote scheduled for after the current compilation?
	var/voteChosenevent = "" //the event that the players voted to switch to
	var/nexteventIsVotedFor = 0 //is the next event a result of player voting?
	var/nexteventIsVotedForPrior = 0 //we save the voted event state in the event of a failed compile, so we can restore
	var/voteIndex = 0 //a count of votes
	var/list/playerPickable = list() //list of events players are allowed to pick
	var/list/passiveVotes = list() //list of passive event votes
	var/list/previousVotes = list() //a list of how people voted for every vote

	//cause of switch to this event
	var/thiseventWasVotedFor

	New()
		..()
		src.setupPickableList()
		thiseventWasVotedFor = world.load_intra_round_value("voted_event")

	proc/setupPickableList()
		//event_setting set by code/event.dm
		src.playerPickable.len = 0
		for (var/event in eventNames)
			if (eventNames[event]["id"] == event_setting)
				src.active = 1
				src.setCurrentevent(event)

			if (eventNames[event]["playerPickable"])
				if (eventNames[event]["MinPlayersAllowed"])
					if (total_clients() < eventNames[event]["MinPlayersAllowed"])
						continue
				#ifndef UPSCALED_event
				if (eventNames[event]["MaxPlayersAllowed"])
					if (total_clients() > eventNames[event]["MaxPlayersAllowed"])
						continue
				#endif

				src.playerPickable[event] += eventNames[event]

		if (!src.active)
			logTheThing(LOG_DEBUG, null, "<b>event Switcher:</b> Failed to find an entry in eventNames. event_setting: [event_setting]")
			return


	proc/lock(eventID)
		src.locked = 1


	proc/unlock(eventID)
		//we attempted to compile a custom event, but it failed for some reason
		if (eventID == "FAILED")
			src.locked = 0
			src.next = src.nextPrior ? src.nextPrior : null
			src.nextPrior = null

			//we tried to switch away from a voted event, but it failed, so restore state
			if (src.nexteventIsVotedForPrior)
				src.nexteventIsVotedFor = 1
				src.nexteventIsVotedForPrior = 0


		//the custom event actually compiled whoa
		else
			/*
			handle weird fucked up cases :v
			1. got...nothing?
			2. no next event set and the current event ISNT the eventID we were just given
			3. next event set, but it doesn't match the eventID we were just given
			*/
			/*
			if (!eventID || \
				(!src.next && eventNames[src.current]["id"] != eventID) || \
				(src.next && eventNames[src.next]["id"] != eventID))
				src.locked = 0
			else
				src.locked = 0
				src.nextPrior = null
			*/

			src.locked = 0
			src.nextPrior = null

			//we switched away from a voted event and it succeeded, forget all about that vote
			if (src.nexteventIsVotedForPrior)
				src.nexteventIsVotedForPrior = 0


		//aaaa we were holding up a reboot, go go go!
		if (src.holdingReboot)
			if (eventID == "FAILED")
				boutput(world, "<span class='bold notice'>event switch failed, continuing restart. Shed a tear for the event that was never to be.</span>")
			else
				boutput(world, "<span class='bold notice'>event switch complete, continuing restart</span>")

			Reboot_server()
		else if (src.queuedVoteCompile)
			//ok we're not holding up a reboot and there's a queued player vote event, so let's trigger it
			src.queuedVoteCompile = 0
			try
				src.setNextevent("Player Vote", eventName = src.voteChosenevent)
			catch (var/exception/e)
				logTheThing("admin", null, null, "Failed to set event <b>[src.voteChosenevent]</b> from event vote: [e]")
				logTheThing("diary", null, null, "Failed to set event <b>[src.voteChosenevent]</b> from event vote: [e]", "debug")


	proc/setCurrentevent(event)
		if (!src.active || !event)
			return

		src.current = event


	proc/setNextevent(trigger, eventName = "", eventID = "", votes = 0)
		if (!eventName && !eventID)
			throw EXCEPTION("No event identifier given")

		if (eventName && eventID)
			throw EXCEPTION("Too many event identifiers given")

		if (src.locked)
			throw EXCEPTION("event switcher is locked")

		if (!src.active)
			throw EXCEPTION("event switcher is currently inactive")

		if (eventName)
			if (!eventNames[eventName])
				throw EXCEPTION("Incorrect event name given: [eventName]")

			eventID = eventNames[eventName]["id"]
		else
			eventName = geteventNameFromID(eventID)

		try
			var/datum/apiRoute/gamebuilds/build/gameBuild = new
			gameBuild.buildBody(
				trigger == "Player Vote" ? "bot" : trigger,
				config.server_id,
				roundId,
				eventID,
				votes
			)
			apiHandler.queryAPI(gameBuild)
		catch (var/exception/e)
			var/datum/apiModel/Error/error = e.name
			throw EXCEPTION(error.message)

		//we switched away from a voted event, make a note of this
		if (src.nexteventIsVotedFor)
			src.nexteventIsVotedFor = 0
			src.nexteventIsVotedForPrior = 1

		//make a note if this is a player voted event
		src.nexteventIsVotedFor = trigger == "Player Vote" ? 1 : 0
		world.save_intra_round_value("voted_event", src.nexteventIsVotedFor)

		//set next only if we're not re-compiling the current event for whatever reason
		if (src.current != eventName)
			src.next = eventName
		else
			src.next = null

		src.lock(eventID)


	//we're stuck waiting for a event compile so we can reboot. try again
	proc/attemptReboot()
		src.currentRebootAttempt++

		//that's it! pull the damn plug!
		if (src.currentRebootAttempt >= src.rebootLimit)
			src.unlock("FAILED")
		else
			Reboot_server(1)


	//start a vote to change the event
	proc/starteventVote(duration = 0)
		if (!src.votingAllowed)
			throw EXCEPTION("event votes are currently disabled")

		if (src.playersVoting)
			throw EXCEPTION("A event vote is currently underway")

		src.setupPickableList()

		src.voteChosenevent = ""
		src.playersVoting = 1
		src.voteStartedAt = TIME
		src.voteCurrentDuration = duration
		src.voteIndex++

		for (var/client/C in clients)
			C.verbs += /client/proc/eventVote
			if(C?.preferences && length(C.preferences.preferred_event) && !istype(C.mob,/mob/new_player) && (C.preferences.preferred_event in playerPickable))
				src.passiveVotes[C.ckey] = C.preferences.preferred_event

		//announce vote
		var/msg = "<br><span class='bold notice'>"
		msg += "A vote for next round's event has started! Click here: [eventVoteLinkStat.chat_link()] or on the 'event Vote' button in your status window."

		if (duration)
			msg += " It will end in [duration / 10] seconds."
		msg += "</span><br><br>"
		boutput(world, msg)

		//if the vote was triggered with a duration, wait that long and end it
		if (duration)
			var/currentVoteIndex = src.voteIndex
			SPAWN(duration)
				//it's possible that a vote was started, cancelled, and then another started again. we don't want this spawn to prematurely end the new one
				if (currentVoteIndex != src.voteIndex)
					return

				//it's possible the vote was cancelled
				if (src.playersVoting)
					src.endeventVote()


	//voting is DONE
	proc/endeventVote()
		if (!src.playersVoting)
			throw EXCEPTION("There is no event vote underway")

		src.playersVoting = 0

		for (var/client/C in clients)
			C.verbs -= /client/proc/eventVote

		//count votes
		var/list/reportData = list()
		var/list/votes = list()

		var/list/results = event_vote_holder.count_votes()
		votes = results["tally"]
		reportData = results["report"]

		//save this vote data
		src.previousVotes["vote[src.voteIndex]"] = reportData
		src.previousVotes["vote_tally[src.voteIndex]"] = votes

		logTheThing(LOG_DEBUG, null, "<b>event Vote Debug:</b> Vote data: [json_encode(votes)]. Report data: [json_encode(reportData)]")

		//reset votes holders
		src.passiveVotes = new()
		event_vote_holder.clear_votes()
		//no one voted :(
		if (length(votes) == 0)
			return

		//determine winner
		var/highestVotes = 0
		var/list/tiedevents = list()
		for (var/event in votes)
			var/eventVotes = votes[event]
			//note the event with the highest votes
			if (eventVotes > highestVotes)
				highestVotes = eventVotes
				src.voteChosenevent = event
				// reset the tied list
				tiedevents = list()

			//a tie is detected! make a note of which events are tied
			else if (eventVotes == highestVotes)
				if (length(tiedevents) == 0)
					//retroactively note that the previously highest voted event is now tied
					tiedevents += src.voteChosenevent
				tiedevents += event

		//handle ties
		if (tiedevents.len)
			logTheThing(LOG_DEBUG, null, "event tie detected. Choices: [json_encode(tiedevents)]")
			src.voteChosenevent = pick(tiedevents)

		//trigger event switch using voteChosenevent
		if (src.voteChosenevent == src.current)
			//dont trigger a recompile of the current event for no reason
			src.nexteventIsVotedFor = 1
		else
			if (src.locked)
				//welp we're already compiling something, queue this compilation for when it finishes
				src.queuedVoteCompile = 1
			else
				try
					src.setNextevent("Player Vote", eventName = src.voteChosenevent, votes = highestVotes)
				catch (var/exception/e)
					logTheThing(LOG_ADMIN, null, "Failed to set event <b>[src.voteChosenevent]</b> from event vote: [e.name]")
					logTheThing(LOG_DIARY, null, "Failed to set event <b>[src.voteChosenevent]</b> from event vote: [e.name]", "debug")
					return

		//announce winner
		var/msg = "<br><span style='font-size: 1.25em;' class='internal'>"
		msg += "The vote for next event has ended. The winning choice is '[src.voteChosenevent]'.<a href='byond://?src=\ref[src];type=view_eventvote_report_simple;vote=[src.voteIndex]'>(View Tally)</a>"
		if (src.voteChosenevent == src.current)
			msg += " (No change)"
		msg += "</span><br><br>"
		boutput(world, msg)

		//log this
		logTheThing(LOG_ADMIN, null, "The players voted for <b>[src.voteChosenevent]</b> as the next event.")
		logTheThing(LOG_DIARY, null, "The players voted for [src.voteChosenevent] as the next event.", "admin")
		message_admins("The players voted for <b>[src.voteChosenevent]</b> as the next event. <a href='byond://?src=\ref[src];type=view_eventvote_report;vote=[src.voteIndex]'>(View Voters)</a>")

	//rudely cancel the vote without counting votes/doing anything
	proc/canceleventVote()
		src.playersVoting = 0

		for (var/client/C in clients)
			C.verbs -= /client/proc/eventVote

	// Standardized way to ask a user for a event
	proc/clientSelectevent(client/C,var/pickable)
		return tgui_input_list(C, "Select a event. Currently on: [src.current]", "Switch event", pickable ? src.playerPickable : eventNames, src.next || src.current)

	//show a html report of who voted for what in any given event vote
	proc/composeVoteReport(vote)
		if (!vote)
			return

		vote = text2num(vote)
		if (vote > src.voteIndex || !("vote[vote]" in src.previousVotes))
			throw EXCEPTION("That vote index does not exist")

		var/list/reportDataDetailed = src.previousVotes["vote[vote]"]
		var/datum/eventVoteReport/mvr = new(reportDataDetailed = reportDataDetailed)
		mvr.ui_interact(usr)

	//show a html report of the weighted votes per choice
	proc/composeVoteReportSimple(vote)
		if (!vote)
			return

		vote = text2num(vote)
		if (vote > src.voteIndex || !("vote_tally[vote]" in src.previousVotes))
			throw EXCEPTION("That vote index does not exist")

		var/list/reportDataSimple = src.previousVotes["vote_tally[vote]"]
		var/datum/eventVoteReport/mvr = new(reportDataSimple = reportDataSimple)
		mvr.ui_interact(usr)

	Topic(href, href_list)
		if (..())
			return

		if (href_list["type"])
			if (href_list["type"] == "view_eventvote_report")
				var/vote = href_list["vote"]
				src.composeVoteReport(vote)
			if (href_list["type"] == "view_eventvote_report_simple")
				var/vote = href_list["vote"]
				src.composeVoteReportSimple(vote)

	proc/get_player_pickable_event_list()
		. = new/list()
		for (var/event in src.playerPickable)
			. += list(list(
				name = event,
				thumbnail = "[config.goonhub_url]/storage/events/[lowertext(src.playerPickable[event]["id"])]/thumb.png"
			))
/proc/iseventSwitcherBusted()
	if (!eventSwitcher || !eventSwitcher.active)
		return "The event switcher is apparently broken right now. Yell at Wire I guess"

	if (!config.allow_event_switching)
		return "event switching is disabled on this server, sorry."

	return 0


/client/proc/eventVote()
	set name = "event Vote"
	set desc = "Vote on the event for next round"
	set category = "Commands"
	set popup_menu = 0

	event_vote_holder.show_window(usr.client)

/datum/event_vote_holder
	var/list/list/client/vote_event = list() // a event of ckeys to (a event of event_names to the ckey's current vote)
	var/voters = 0

	disposing()
		clear_votes()
		..()

	proc/clear_votes()
		src.vote_event.len = 0

	proc/count_votes()
		var/list/results = list()
		var/list/event_vote_count = list()
		var/list/event_vote_report = list()
		for(var/key in vote_event)
			eventSwitcher.passiveVotes.Remove(key)
			var/client_vote_event = vote_event[key]
			for(var/event_name in client_vote_event)
				if(client_vote_event[event_name])
					if(event_name in event_vote_count)
						event_vote_count[event_name] += eventVOTE_ACTIVE_WEIGHT
					else
						event_vote_count[event_name] = eventVOTE_ACTIVE_WEIGHT
					if(event_name in event_vote_report)
						event_vote_report[event_name] += key
					else
						event_vote_report[event_name] = list(key)

		var/list/passive_votes = eventSwitcher.passiveVotes
		for(var/key in passive_votes)
			var/event_name = passive_votes[key]
			if(event_name in event_vote_count)
				event_vote_count[event_name] += eventVOTE_PASSIVE_WEIGHT
			else
				event_vote_count[event_name] = eventVOTE_PASSIVE_WEIGHT
			if(event_name in event_vote_report)
				event_vote_report[event_name] += key
			else
				event_vote_report[event_name] = list(key)

		results["tally"] = event_vote_count
		results["report"] = event_vote_report
		return results

	proc/setup_client_vote_event(var/client/C)
		if(!C.ckey)
			return
		var/key = C.ckey
		if(key in vote_event)
			return
		var/list/events = list()
		for(var/event in eventSwitcher.playerPickable)
			events[event] = 0
		src.vote_event[key] = events
		voters++

	proc/get_client_votes(var/client/C)
		if(!C.ckey)
			return
		var/key = C.ckey
		if(!(key in vote_event))
			return
		var/list/events = list()
		var/list/client_vote_event = vote_event[key]
		for(var/event in client_vote_event)
			if(client_vote_event[event] > 0)
				events += event
		return events

	proc/toggle_vote(event_name, client/C)
		if(!(C.ckey in vote_event))
			setup_client_vote_event(C)
		var/list/client_vote_event = vote_event[C.ckey]
		if(event_name in client_vote_event)
			client_vote_event[event_name] = !client_vote_event[event_name]

	proc/all_yes(client/C)
		if(!(C.ckey in vote_event))
			setup_client_vote_event(C)
		var/list/client_vote_event = vote_event[C.ckey]
		for(var/event_name in client_vote_event)
			client_vote_event[event_name] = 1

	proc/all_no(client/C)
		if(!(C.ckey in vote_event))
			setup_client_vote_event(C)
		var/list/client_vote_event = vote_event[C.ckey]
		for(var/event_name in client_vote_event)
			client_vote_event[event_name] = 0

	proc/special_vote(var/client/C,var/event_name)
		if(!(C.ckey in vote_event))
			setup_client_vote_event(C)
		var/list/client_vote_event = vote_event[C.ckey]
		client_vote_event[event_name] = 1

	proc/voting_box(var/obj/voting_box/V,var/event_name)
		var/vref = "\ref[V]"
		vote_event[vref] = list(event_name)
		vote_event[vref][event_name] = 1

	ui_state(mob/user)
		return tgui_always_state.can_use_topic(src, user)

	ui_status(mob/user, datum/ui_state/state)
		return tgui_always_state.can_use_topic(src, user)

	ui_interact(mob/user, datum/tgui/ui)
		ui = tgui_process.try_update_ui(user, src, ui)
		if (!ui)
			ui = new(user, src, "eventVote", "Event Vote")
			ui.open()

	ui_static_data()
		. = list(
			"eventList" = eventSwitcher.get_player_pickable_event_list()
		)

	ui_data(mob/user)
		if(!(user.client.ckey in vote_event))
			setup_client_vote_event(user.client)

		. = list(
			"playersVoting" = eventSwitcher.playersVoting,
			"clientVoteevent" = vote_event[user.client.ckey]
		)

	proc/show_window(client/C)
		ui_interact(C.mob)

	ui_act(action, list/params)
		. = ..()
		switch (action)
			if("toggle_vote")
				toggle_vote(params["event_name"], usr)
			if("all_yes")
				all_yes(usr)
			if("all_no")
				all_no(usr)
		. = TRUE

/obj/eventVoteLink
	name = "<span style='color: green; text-decoration: underline;'>event Vote</span>"
	flags = NOSPLASH

	Click()
		var/client/C = usr.client
		if (!C) return
		var/mob/living/M = C.mob
		var/chosenevent = null
		if(istype(M))
			var/obj/item/I = M.equipped()
			if(istype(I, /obj/item/reagent_containers) && I:reagents:has_reagent("space_fungus"))
				chosenevent = "Mushroom"
			// if(istype(I, /obj/item/reagent_containers) && (I:reagents:has_reagent("reversium") || I:reagents:has_reagent("fliptonium")))
			// 	chosenevent = "1 pamgoC"
			//if(istype(I, /obj/item/reagent_containers) && I:reagents:has_reagent("ldmatter"))
				//chosenevent = "Density"
			// if(istype(I, /obj/item/reagent_containers/food/snacks/donut))
			// 	chosenevent = "Donut 2"
			//if(istype(I, /obj/item/grab))
				//chosenevent = "Wrestleevent"

		if (eventSwitcher.playersVoting)
			if(chosenevent)
				event_vote_holder.special_vote(C,chosenevent)
				boutput(C.mob, SPAN_SUCCESS("event vote successful???"))
			else
				event_vote_holder.show_window(C)


	examine()
		return list()

	proc/chat_link()
		return "<a href='byond://?src=\ref[src]'>[src]</a>"

	Topic(href, href_list)
		. = ..()
		Click()

var/global/obj/eventVoteLink/eventVoteLinkStat = new /obj/eventVoteLink
var/global/datum/event_vote_holder/event_vote_holder = new()

/datum/eventVoteReport
	var/list/eventList
	var/winner
	var/isDetailed = FALSE

	New(list/reportDataSimple, list/reportDataDetailed)
		src.eventList = eventSwitcher.get_player_pickable_event_list()

		if (reportDataSimple)
			for (var/event in src.eventList)
				event["count"] = reportDataSimple[event["name"]] || 0

		if (reportDataDetailed)
			isDetailed = TRUE
			for (var/event in src.eventList)
				event["count"] = length(reportDataDetailed[event["name"]]) || 0
				event["voters"] = reportDataDetailed[event["name"]]

		sortList(src.eventList, /proc/compare_event_vote_count)

		src.winner = eventSwitcher.voteChosenevent

		..()

	ui_state(mob/user)
		return tgui_always_state.can_use_topic(src, user)

	ui_status(mob/user, datum/ui_state/state)
		return tgui_always_state.can_use_topic(src, user)

	ui_interact(mob/user, datum/tgui/ui)
		ui = tgui_process.try_update_ui(user, src, ui)
		if (!ui)
			ui = new(user, src, "eventVoteReport", "Vote Report")
			ui.open()

	ui_static_data(mob/user)
		. = list(
			"eventList" = eventList,
			"winner" = winner,
			"isDetailed" = isDetailed)

/proc/compare_event_vote_count(list/a, list/b)
	. = b["count"] - a["count"]
