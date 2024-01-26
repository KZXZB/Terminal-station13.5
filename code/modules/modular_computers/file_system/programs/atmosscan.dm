/// Scan the turf where the computer is on.
#define ATMOZPHERE_SCAN_ENV "env"
/// Scan the objects that the tablet clicks.
#define ATMOZPHERE_SCAN_CLICK "click"

/datum/computer_file/program/atmosscan
	filename = "atmosscan"
	filedesc = "AtmoZphere-气探"
	downloader_category = PROGRAM_CATEGORY_ENGINEERING
	program_open_overlay = "air"
	extended_desc = "内置的微型传感器可以读出设备周围的大气状况."
	size = 4
	tgui_id = "NtosGasAnalyzer"
	program_icon = "thermometer-half"

	/// Whether we scan the current turf automatically (env) or scan tapped objects manually (click).
	var/atmozphere_mode = ATMOZPHERE_SCAN_ENV
	/// Saved [GasmixParser][/proc/gas_mixture_parser] data of the last thing we scanned.
	var/list/last_gasmix_data

/// Secondary attack self.
/datum/computer_file/program/atmosscan/proc/turf_analyze(datum/source, mob/user)
	SIGNAL_HANDLER
	if(atmozphere_mode != ATMOZPHERE_SCAN_CLICK)
		return
	atmos_scan(user=user, target=get_turf(computer), silent=FALSE)
	on_analyze(source=source, target=get_turf(computer))
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// Keep this in sync with it's tool based counterpart [/obj/proc/analyzer_act] and [/atom/proc/tool_act]
/datum/computer_file/program/atmosscan/tap(atom/A, mob/living/user, params)
	if(atmozphere_mode != ATMOZPHERE_SCAN_CLICK)
		return FALSE
	if(!atmos_scan(user=user, target=A, silent=FALSE))
		return FALSE
	on_analyze(source=computer, target=A)
	return TRUE

/// Updates our gasmix data if on click mode.
/datum/computer_file/program/atmosscan/proc/on_analyze(datum/source, atom/target)
	var/mixture = target.return_analyzable_air()
	if(!mixture)
		return FALSE
	var/list/airs = islist(mixture) ? mixture : list(mixture)
	var/list/new_gasmix_data = list()
	for(var/datum/gas_mixture/air as anything in airs)
		var/mix_name = capitalize(lowertext(target.name))
		if(airs.len != 1) //not a unary gas mixture
			mix_name += " - Node [airs.Find(air)]"
		new_gasmix_data += list(gas_mixture_parser(air, mix_name))
	last_gasmix_data = new_gasmix_data

/datum/computer_file/program/atmosscan/ui_static_data(mob/user)
	return return_atmos_handbooks()

/datum/computer_file/program/atmosscan/ui_data(mob/user)
	var/list/data = list()
	var/turf/turf = get_turf(computer)
	data["atmozphereMode"] = atmozphere_mode
	data["clickAtmozphereCompatible"] = (computer.hardware_flag & PROGRAM_PDA)
	switch (atmozphere_mode) //Null air wont cause errors, don't worry.
		if(ATMOZPHERE_SCAN_ENV)
			var/datum/gas_mixture/air = turf?.return_air()
			data["gasmixes"] = list(gas_mixture_parser(air, "Location Reading"))
		if(ATMOZPHERE_SCAN_CLICK)
			LAZYINITLIST(last_gasmix_data)
			data["gasmixes"] = last_gasmix_data
	return data

/datum/computer_file/program/atmosscan/ui_act(action, list/params)
	switch(action)
		if("scantoggle")
			if(atmozphere_mode == ATMOZPHERE_SCAN_CLICK)
				atmozphere_mode = ATMOZPHERE_SCAN_ENV
				UnregisterSignal(computer, COMSIG_ITEM_ATTACK_SELF_SECONDARY)
				return TRUE
			if(!(computer.hardware_flag & PROGRAM_PDA))
				computer.say("不兼容的扫描对象!")
				return FALSE
			atmozphere_mode = ATMOZPHERE_SCAN_CLICK
			RegisterSignal(computer, COMSIG_ITEM_ATTACK_SELF_SECONDARY, PROC_REF(turf_analyze))
			var/turf/turf = get_turf(computer)
			last_gasmix_data = list(gas_mixture_parser(turf?.return_air(), "Location Reading"))
			return TRUE

#undef ATMOZPHERE_SCAN_ENV
#undef ATMOZPHERE_SCAN_CLICK
