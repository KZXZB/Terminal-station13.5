/obj/item/choice_beacon
	name = "choice beacon"
	desc = "Hey, why are you viewing this?!! Please let CentCom know about this odd occurrence."
	icon = 'icons/obj/devices/remote.dmi'
	icon_state = "gangtool-blue"
	inhand_icon_state = "radio"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	/// How many uses this item has before being deleted
	var/uses = 1
	/// Used in the deployment message - What company is sending the equipment, flavor
	var/company_source = "Central Command"
	/// Used inthe deployment message - What is the company saying with their message, flavor
	var/company_message = span_bold("Item request received. Your package is inbound, please stand back from the landing site.")

/obj/item/choice_beacon/interact(mob/user)
	. = ..()
	if(!can_use_beacon(user))
		return

	open_options_menu(user)

/// Return the list that will be used in the choice selection.
/// Entries should be in (type.name = type) fashion.
/obj/item/choice_beacon/proc/generate_display_names()
	return list()

/// Checks if this mob can use the beacon, returns TRUE if so or FALSE otherwise.
/obj/item/choice_beacon/proc/can_use_beacon(mob/living/user)
	if(user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return TRUE

	playsound(src, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	return FALSE

/// Opens a menu and allows the mob to pick an option from the list
/obj/item/choice_beacon/proc/open_options_menu(mob/living/user)
	var/list/display_names = generate_display_names()
	if(!length(display_names))
		return
	var/choice = tgui_input_list(user, "想下达何种订单?", "选择物品", display_names)
	if(isnull(choice) || isnull(display_names[choice]))
		return
	if(!can_use_beacon(user))
		return

	consume_use(display_names[choice], user)

/// Consumes a use of the beacon, sending the user a message and creating their item in the process
/obj/item/choice_beacon/proc/consume_use(obj/choice_path, mob/living/user)
	to_chat(user, span_hear("你听到信标里什么东西噼啪作响，然后传出语音. \
		\"请等待 [company_source] 的信息. 信息如下: [company_message] 通讯结束.\""))

	spawn_option(choice_path, user)
	uses--
	if(uses <= 0)
		do_sparks(3, source = src)
		qdel(src)
		return

	to_chat(user, span_notice("[uses] use[uses > 1 ? "s" : ""] remain[uses > 1 ? "" : "s"] on [src]."))

/// Actually spawns the item selected by the user
/obj/item/choice_beacon/proc/spawn_option(obj/choice_path, mob/living/user)
	podspawn(list(
		"target" = get_turf(src),
		"style" = STYLE_BLUESPACE,
		"spawn" = choice_path,
	))

/obj/item/choice_beacon/music
	name = "乐器投送信标"
	desc = "开启你的音乐人生."
	w_class = WEIGHT_CLASS_TINY

/obj/item/choice_beacon/music/generate_display_names()
	var/static/list/instruments
	if(!instruments)
		instruments = list()
		var/list/possible_instruments = list(
			/obj/item/instrument/violin,
			/obj/item/instrument/piano_synth,
			/obj/item/instrument/banjo,
			/obj/item/instrument/guitar,
			/obj/item/instrument/eguitar,
			/obj/item/instrument/glockenspiel,
			/obj/item/instrument/accordion,
			/obj/item/instrument/trumpet,
			/obj/item/instrument/saxophone,
			/obj/item/instrument/trombone,
			/obj/item/instrument/recorder,
			/obj/item/instrument/harmonica,
			/obj/item/instrument/piano_synth/headphones,
		)
		for(var/obj/item/instrument/instrument as anything in possible_instruments)
			instruments[initial(instrument.name)] = instrument
	return instruments

/obj/item/choice_beacon/ingredient
	name = "原料投送信标"
	desc = "生成一盒食材来帮助你开始烹饪."
	icon_state = "sb_delivery"
	inhand_icon_state = "sb_delivery"
	company_source = "Sophronia Broadcasting"
	company_message = span_bold("享受Sophronia Broadcasting的'Plasteel Chef'食材盒，和料理节目上的一样!")

/obj/item/choice_beacon/ingredient/generate_display_names()
	var/static/list/ingredient_options
	if(!ingredient_options)
		ingredient_options = list()
		for(var/obj/item/storage/box/ingredients/box as anything in subtypesof(/obj/item/storage/box/ingredients))
			ingredient_options[initial(box.theme_name)] = box
	return ingredient_options

/obj/item/choice_beacon/hero
	name = "英灵投送信标"
	desc = "召唤过去的英雄来保护未来."
	icon_state = "sb_delivery"
	inhand_icon_state = "sb_delivery"
	company_source = "Sophronia Broadcasting"
	company_message = span_bold("享受Sophronia Broadcasting的'History Comes Alive branded'服饰包,和电视剧里的一样!")

/obj/item/choice_beacon/hero/generate_display_names()
	var/static/list/hero_item_list
	if(!hero_item_list)
		hero_item_list = list()
		for(var/obj/item/storage/box/hero/box as anything in typesof(/obj/item/storage/box/hero))
			hero_item_list[initial(box.name)] = box
	return hero_item_list

/obj/item/choice_beacon/augments
	name = "义体投送信标"
	desc = "投送一些义体，可以使用3次!"
	uses = 3
	company_source = "S.E.L.F."
	company_message = span_bold("订单状态: 已收到. 包裹状态: 已发货. Notes: 为最佳体验, 使用 supplied Interdyne-brand autosurgeons-补给的Interdyne-brand自动手术器来改变植入物状态.")

/obj/item/choice_beacon/augments/generate_display_names()
	var/static/list/augment_list
	if(!augment_list)
		augment_list = list()
		// cyberimplants range from a nice bonus to fucking broken bullshit so no subtypesof
		var/list/selectable_types = list(
			/obj/item/organ/internal/cyberimp/brain/anti_drop,
			/obj/item/organ/internal/cyberimp/arm/toolset,
			/obj/item/organ/internal/cyberimp/arm/surgery,
			/obj/item/organ/internal/cyberimp/chest/thrusters,
			/obj/item/organ/internal/lungs/cybernetic/tier3,
			/obj/item/organ/internal/liver/cybernetic/tier3,
		)
		for(var/obj/item/organ/organ as anything in selectable_types)
			augment_list[initial(organ.name)] = organ

	return augment_list

// just drops the box at their feet, "quiet" and "sneaky"
/obj/item/choice_beacon/augments/spawn_option(obj/choice_path, mob/living/user)
	new choice_path(get_turf(user))
	playsound(src, 'sound/weapons/emitter2.ogg', 50, extrarange = SILENCED_SOUND_EXTRARANGE)

/obj/item/choice_beacon/holy
	name = "圣武投送信标"
	desc = "投送牧师们的神圣武器."
	icon_state = "icra_delivery"
	inhand_icon_state = "icra_delivery"
	company_source = "星际宗教联合会"
	company_message = span_bold("一个选择已被做下.")

/obj/item/choice_beacon/holy/can_use_beacon(mob/living/user)
	if(user.mind?.holy_role)
		return ..()

	playsound(src, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	return FALSE

// Overrides generate options so that we can show a neat radial instead
/obj/item/choice_beacon/holy/open_options_menu(mob/living/user)
	if(GLOB.holy_armor_type)
		consume_use(GLOB.holy_armor_type, user)
		return

	// Not bothering to cache this stuff because it'll only even be used once
	var/list/armament_names_to_images = list()
	var/list/armament_names_to_typepaths = list()
	for(var/obj/item/storage/box/holy/holy_box as anything in typesof(/obj/item/storage/box/holy))
		var/box_name = initial(holy_box.name)
		var/obj/item/preview_item = initial(holy_box.typepath_for_preview)
		armament_names_to_typepaths[box_name] = holy_box
		armament_names_to_images[box_name] = image(icon = initial(preview_item.icon), icon_state = initial(preview_item.icon_state))

	var/chosen_name = show_radial_menu(
		user = user,
		anchor = src,
		choices = armament_names_to_images,
		custom_check = CALLBACK(src, PROC_REF(can_use_beacon), user),
		require_near = TRUE,
	)
	if(!can_use_beacon(user))
		return
	var/chosen_type = armament_names_to_typepaths[chosen_name]
	if(!ispath(chosen_type, /obj/item/storage/box/holy))
		return

	consume_use(chosen_type, user)

/obj/item/choice_beacon/holy/spawn_option(obj/choice_path, mob/living/user)
	playsound(src, 'sound/effects/pray_chaplain.ogg', 40, TRUE)
	SSblackbox.record_feedback("tally", "chaplain_armor", 1, "[choice_path]")
	GLOB.holy_armor_type = choice_path
	return ..()
