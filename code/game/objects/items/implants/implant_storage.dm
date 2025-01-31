/obj/item/implant/storage
	name = "储存植入物"
	desc = "使用者将在体内获得一个由蓝空技术制成的储藏空间，可以储存两件大型物品."
	icon_state = "storage"
	implant_color = "r"
	var/max_slot_stacking = 4

/obj/item/implant/storage/activate()
	. = ..()
	atom_storage?.open_storage(imp_in)

/obj/item/implant/storage/removed(source, silent = FALSE, special = FALSE)
	if(special)
		return ..()

	var/mob/living/implantee = source
	for (var/obj/item/stored in contents)
		stored.add_mob_blood(implantee)
	atom_storage.remove_all()
	implantee.visible_message(span_warning("A bluespace pocket opens around [src] as it exits [implantee], spewing out its contents and rupturing the surrounding tissue!"))
	implantee.apply_damage(20, BRUTE, BODY_ZONE_CHEST)
	qdel(atom_storage)
	return ..()

/obj/item/implant/storage/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	for(var/X in target.implants)
		if(istype(X, type))
			var/obj/item/implant/storage/imp_e = X
			if(!imp_e.atom_storage)
				imp_e.create_storage(storage_type = /datum/storage/implant)
				qdel(src)
				return TRUE
			else if(imp_e.atom_storage.max_slots < max_slot_stacking)
				imp_e.atom_storage.max_slots += initial(imp_e.atom_storage.max_slots)
				imp_e.atom_storage.max_total_storage += initial(imp_e.atom_storage.max_total_storage)
				return TRUE
			return FALSE
	create_storage(storage_type = /datum/storage/implant)

	return ..()

/obj/item/implanter/storage
	name = "implanter" // Skyrat edit , original was implanter (storage)
	imp_type = /obj/item/implant/storage
	special_desc_requirement = EXAMINE_CHECK_SYNDICATE // Skyrat edit
	special_desc = "A Syndicate implanter used for a storage implant" // Skyrat edit
