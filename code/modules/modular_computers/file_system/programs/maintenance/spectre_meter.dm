
#define SPOOK_VALUE_SAME_TURF_MULT 1.5
#define SPOOK_VALUE_LIVING_MULT 6
#define SPOOK_VALUE_DEF_MOB 10
#define SPOOK_VALUE_ICON_STATE_MAX 120
#define SPOOK_VALUE_SEGMENT 15

/datum/computer_file/program/maintenance/spectre_meter
	filename = "spectre_meter"
	filedesc = "Spectre-Meter-探灵"
	power_cell_use = PROGRAM_BASIC_CELL_USE * 2
	downloader_category = PROGRAM_CATEGORY_EQUIPMENT
	extended_desc = "用来探测附近光谱存在的程序，结合相机拍摄灵异图片."
	size = 7
	can_run_on_flags = PROGRAM_LAPTOP|PROGRAM_PDA
	tgui_id = "NtosSpectreMeter"
	program_icon = "ghost"
	program_open_overlay = "spectre_meter_0"
	/// The cooldown for manual scans
	COOLDOWN_DECLARE(manual_scan_cd)
	/// Whether the automatic scan mode is active or not
	var/auto_mode = FALSE
	/// The value reported by the last scan.
	var/last_spook_value = 0
	var/datum/looping_sound/spectre_meter/soundloop

/datum/computer_file/program/maintenance/spectre_meter/on_start(mob/user)
	. = ..()
	if(.)
		soundloop = new()

/datum/computer_file/program/maintenance/spectre_meter/kill_program()
	QDEL_NULL(soundloop)
	auto_mode = FALSE
	last_spook_value = 0
	program_open_overlay = "spectre_meter_0"
	power_cell_use = PROGRAM_BASIC_CELL_USE
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/computer_file/program/maintenance/spectre_meter/ui_data(mob/user)
	var/list/data = list()
	data["spook_value"] = last_spook_value
	data["auto_mode"] = auto_mode
	data["on_cooldown"] = !COOLDOWN_FINISHED(src, manual_scan_cd)
	return data

/datum/computer_file/program/maintenance/spectre_meter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	switch(action)
		if("manual_scan")
			if(COOLDOWN_FINISHED(src, manual_scan_cd))
				INVOKE_ASYNC(src, PROC_REF(scan_surroundings))
				COOLDOWN_START(src, manual_scan_cd, 2 SECONDS)
				playsound(computer, 'sound/effects/ping_hit.ogg', vol = 40, vary = TRUE)
				return TRUE
		if("toggle_mode")
			auto_mode = !auto_mode
			if(auto_mode)
				///We want SSprocess. It fires twice as fast than the standard SSobjs used by [computer_file/program/process_tick]
				START_PROCESSING(SSprocessing, src)
				soundloop.start(computer)
			else
				STOP_PROCESSING(SSprocessing, src)
				soundloop.stop(TRUE)
			power_cell_use = auto_mode ? PROGRAM_BASIC_CELL_USE * 3 : PROGRAM_BASIC_CELL_USE
			return TRUE

/datum/computer_file/program/maintenance/spectre_meter/process(seconds_per_tick)
	if(auto_mode)
		INVOKE_ASYNC(src, PROC_REF(scan_surroundings))

///Return the "spook level" of the area the computer is in.
/datum/computer_file/program/maintenance/spectre_meter/proc/scan_surroundings()
	var/spook_value = 0
	var/turf/turf = get_turf(computer)

	for(var/atom/atom as anything in range(5, turf))
		var/spook_amount = 0
		if(ismob(atom))
			///ghastly mobs count toward spookiness more than observers.
			var/spook_value_mult = 0
			if(isliving(atom))
				var/mob/living/living = atom
				if(living.mob_biotypes & MOB_SPIRIT)
					spook_value_mult = SPOOK_VALUE_LIVING_MULT
			else if(isobserver(atom))
				spook_value_mult = 1
			spook_amount += SPOOK_VALUE_DEF_MOB * spook_value_mult
		var/list/materials = atom.has_material_type(/datum/material/hauntium)
		if(materials)
			spook_amount += materials[/datum/material/hauntium]/SHEET_MATERIAL_AMOUNT
		spook_amount += atom.reagents?.get_reagent_amount(/datum/reagent/hauntium)/20
		if(!spook_amount)
			continue
		if(atom.loc == turf)
			spook_amount *= SPOOK_VALUE_SAME_TURF_MULT
		spook_value += spook_amount/max(get_dist(turf, atom), 1)
		CHECK_TICK

	soundloop.last_spook_value = last_spook_value = round(spook_value)
	var/old_open_overlay = program_open_overlay
	program_open_overlay = "spectre_meter_[min(FLOOR(last_spook_value, SPOOK_VALUE_SEGMENT), SPOOK_VALUE_ICON_STATE_MAX)]"
	if(program_open_overlay != old_open_overlay)
		computer.update_appearance(UPDATE_OVERLAYS)

/datum/looping_sound/spectre_meter
	mid_sounds = /datum/looping_sound/geiger::mid_sounds
	mid_length = 2
	volume = 12
	var/last_spook_value = 0

/datum/looping_sound/spectre_meter/get_sound()
	var/index = 1
	switch(last_spook_value)
		if(0 to 14)
			return null
		if(14 to 40)
			index = 1
		if(40 to 65)
			index = 2
		if(65 to 90)
			index = 3
		else
			index = 4
	return ..(mid_sounds[index])

/datum/looping_sound/spectre_meter/stop(null_parent = FALSE)
	last_spook_value = 0
	return ..()

#undef SPOOK_VALUE_SAME_TURF_MULT
#undef SPOOK_VALUE_LIVING_MULT
#undef SPOOK_VALUE_DEF_MOB
#undef SPOOK_VALUE_ICON_STATE_MAX
#undef SPOOK_VALUE_SEGMENT
