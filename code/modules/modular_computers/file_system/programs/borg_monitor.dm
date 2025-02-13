/datum/computer_file/program/borg_monitor
	filename = "siliconnect"
	filedesc = "SiliConnect-硅基链"
	downloader_category = PROGRAM_CATEGORY_SCIENCE
	ui_header = "borg_mon.gif"
	program_open_overlay = "generic"
	extended_desc = "该程序允许用户远程监控站点Cyborg."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_ROBOTICS)
	size = 5
	tgui_id = "NtosCyborgRemoteMonitor"
	program_icon = "project-diagram"
	var/list/loglist = list() ///A list to copy a borg's IC log list into
	var/mob/living/silicon/robot/DL_source ///reference of a borg if we're downloading a log, or null if not.
	var/DL_progress = -1 ///Progress of current download, 0 to 100, -1 for no current download

/datum/computer_file/program/borg_monitor/Destroy()
	loglist = null
	DL_source = null
	return ..()

/datum/computer_file/program/borg_monitor/kill_program(mob/user)
	loglist = null //Not everything is saved if you close an app
	DL_source = null
	DL_progress = 0
	return ..()

/datum/computer_file/program/borg_monitor/tap(atom/A, mob/living/user, params)
	var/mob/living/silicon/robot/borgo = A
	if(!istype(borgo) || !borgo.modularInterface)
		return FALSE
	DL_source = borgo
	DL_progress = 0

	var/username = "unknown user"
	var/obj/item/card/id/stored_card = computer.GetID()
	if(istype(stored_card) && stored_card.registered_name)
		username = "user [stored_card.registered_name]"
	to_chat(borgo, span_userdanger("从[username]收到系统日志文件的请求，正在上传."))//Damning evidence may be contained, so warn the borg
	borgo.logevent("[username]请求文件: /var/logs/syslog")
	return TRUE

/datum/computer_file/program/borg_monitor/process_tick(seconds_per_tick)
	if(!DL_source)
		DL_progress = -1
		return

	var/turf/here = get_turf(computer)
	var/turf/there = get_turf(DL_source)
	if(!here.Adjacent(there))//If someone walked away, cancel the download
		to_chat(DL_source, span_danger("日志上传失败：一般连接错误"))//Let the borg know the upload stopped
		DL_source = null
		DL_progress = -1
		return

	if(DL_progress == 100)
		if(!DL_source || !DL_source.modularInterface) //sanity check, in case the borg or their modular tablet poofs somehow
			loglist = list("[DL_source.name]单元的系统日志")
			loglist += "Error -- 下载内容损坏."
		else
			loglist = DL_source.modularInterface.borglog.Copy()
			loglist.Insert(1,"[DL_source.name]单元的系统日志")
		DL_progress = -1
		DL_source = null
		return

	DL_progress += 25

/datum/computer_file/program/borg_monitor/ui_data(mob/user)
	var/list/data = list()

	data["card"] = FALSE
	if(checkID())
		data["card"] = TRUE

	data["cyborgs"] = list()
	for(var/mob/living/silicon/robot/R in GLOB.silicon_mobs)
		if(!evaluate_borg(R))
			continue

		var/list/upgrade
		for(var/obj/item/borg/upgrade/I in R.upgrades)
			upgrade += "\[[I.name]\] "

		var/shell = FALSE
		if(R.shell && !R.ckey)
			shell = TRUE

		var/list/cyborg_data = list(
			name = R.name,
			integ = round((R.health + 100) / 2), //mob heath is -100 to 100, we want to scale that to 0 - 100
			locked_down = R.lockcharge,
			status = R.stat,
			shell_discon = shell,
			charge = R.cell ? round(R.cell.percent()) : null,
			module = R.model ? "[R.model.name] Model" : "No Model Detected",
			upgrades = upgrade,
			ref = REF(R)
		)
		data["cyborgs"] += list(cyborg_data)
		data["DL_progress"] = DL_progress

	data["borglog"] = loglist

	return data

/datum/computer_file/program/borg_monitor/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	switch(action)
		if("messagebot")
			var/mob/living/silicon/robot/R = locate(params["ref"]) in GLOB.silicon_mobs
			if(!istype(R))
				return TRUE
			var/ID = checkID()
			if(!ID)
				return TRUE
			if(R.stat == DEAD) //Dead borgs will listen to you no longer
				to_chat(usr, span_warning("Error -- 无法打开单元:[R]的链接"))
			var/message = tgui_input_text(usr, "给cyborg发送消息", "发送消息")
			if(!message)
				return TRUE
			to_chat(R, "<br><br>[span_notice("消息来自[ID] -- \"[message]\"")]<br>")
			to_chat(usr, "消息送至[R]: [message]")
			R.logevent("消息来自[ID] -- \"[message]\"")
			SEND_SOUND(R, 'sound/machines/twobeep_high.ogg')
			if(R.connected_ai)
				to_chat(R.connected_ai, "<br><br>[span_notice("消息从[ID]至[R] -- \"[message]\"")]<br>")
				SEND_SOUND(R.connected_ai, 'sound/machines/twobeep_high.ogg')
			usr.log_talk(message, LOG_PDA, tag="Cyborg监控程序: ID name \"[ID]\" to [R]")
			return TRUE

///This proc is used to determin if a borg should be shown in the list (based on the borg's scrambledcodes var). Syndicate version overrides this to show only syndicate borgs.
/datum/computer_file/program/borg_monitor/proc/evaluate_borg(mob/living/silicon/robot/R)
	if(!is_valid_z_level(get_turf(computer), get_turf(R)))
		return FALSE
	if(R.scrambledcodes)
		return FALSE
	return TRUE

///Gets the ID's name, if one is inserted into the device. This is a separate proc solely to be overridden by the syndicate version of the app.
/datum/computer_file/program/borg_monitor/proc/checkID()
	var/obj/item/card/id/ID = computer.GetID()
	if(!ID)
		if(computer.obj_flags & EMAGGED)
			return "STDERR:UNDF"
		return FALSE
	return ID.registered_name

/datum/computer_file/program/borg_monitor/syndicate
	filename = "roboverlord"
	filedesc = "Roboverlord-硅基链"
	downloader_category = PROGRAM_CATEGORY_SCIENCE
	ui_header = "borg_mon.gif"
	program_open_overlay = "generic"
	extended_desc = "该程序允许用户远程监控任务中的Cyborg."
	program_flags = PROGRAM_ON_SYNDINET_STORE
	download_access = list()

/datum/computer_file/program/borg_monitor/syndicate/evaluate_borg(mob/living/silicon/robot/R)
	if(!is_valid_z_level(get_turf(computer), get_turf(R)))
		return FALSE
	if(!R.scrambledcodes)
		return FALSE
	return TRUE

/datum/computer_file/program/borg_monitor/syndicate/checkID()
	return "\[CLASSIFIED\]" //no ID is needed for the syndicate version's message function, and the borg will see "[CLASSIFIED]" as the message sender.
