/mob/living/carbon/New()
	//setup reagent holders
	bloodstr = new/datum/reagents/metabolism(1000, src, CHEM_BLOOD)
	ingested = new/datum/reagents/metabolism(1000, src, CHEM_INGEST)
	touching = new/datum/reagents/metabolism(1000, src, CHEM_TOUCH)
	reagents = bloodstr
	..()

/mob/living/carbon/Life()
	..()

	handle_viruses()

	// Increase germ_level regularly
	if(germ_level < GERM_LEVEL_AMBIENT && prob(30))	//if you're just standing there, you shouldn't get more germs beyond an ambient level
		germ_level++

/mob/living/carbon/Destroy()
	qdel(ingested)
	qdel(touching)
	// We don't qdel(bloodstr) because it's the same as qdel(reagents)
	for(var/guts in internal_organs)
		qdel(guts)
	for(var/food in stomach_contents)
		qdel(food)
	return ..()

/mob/living/carbon/rejuvenate()
	bloodstr.clear_reagents()
	ingested.clear_reagents()
	touching.clear_reagents()
	nutrition = 400
	..()

/mob/living/carbon/Move(NewLoc, direct)
	. = ..()
	if(.)
		if(src.nutrition && src.stat != 2)
			src.nutrition -= DEFAULT_HUNGER_FACTOR/10
			if(src.m_intent == "run")
				src.nutrition -= DEFAULT_HUNGER_FACTOR/10
		if((FAT in src.mutations) && src.m_intent == "run" && src.bodytemperature <= 360)
			src.bodytemperature += 2

		// Moving around increases germ_level faster
		if(germ_level < GERM_LEVEL_MOVE_CAP && prob(8))
			germ_level++


		if(!lying)
			var/turf/T = src.loc
			if(istype(T) && T.stepsound)
				if(istype(src, /mob/living/carbon/human))
					var/mob/living/carbon/human/H = src
					if(H.shoes)
						playsound(src, T.stepsound, 30, 0, 3, 1)

		if(using_object)
			use_object(null)

/mob/living/carbon/relaymove(var/mob/living/user, direction)
	if((user in src.stomach_contents) && istype(user))
		if(user.last_special <= world.time)
			user.last_special = world.time + 50
			src.visible_message("<span class='danger'>You hear something rumbling inside [src]'s stomach...</span>")
			var/obj/item/I = user.get_active_hand()
			if(I && I.force)
				var/d = rand(round(I.force / 4), I.force)
				if(istype(src, /mob/living/carbon/human))
					var/mob/living/carbon/human/H = src
					var/obj/item/organ/external/organ = H.get_organ(BP_CHEST)
					if (istype(organ))
						if(organ.take_damage(d, 0))
							H.UpdateDamageIcon()
					H.updatehealth()
				else
					src.take_organ_damage(d)
				user.visible_message("<span class='danger'>[user] attacks [src]'s stomach wall with the [I.name]!</span>")
				playsound(user.loc, 'sound/effects/attackblob.ogg', 50, 1)

				if(prob(src.getBruteLoss() - 50))
					for(var/atom/movable/A in stomach_contents)
						A.loc = loc
						stomach_contents.Remove(A)
					src.gib()

/mob/living/carbon/gib()
	for(var/mob/M in src)
		if(M in src.stomach_contents)
			src.stomach_contents.Remove(M)
		M.loc = src.loc
		for(var/mob/N in viewers(src, null))
			if(N.client)
				N.show_message(text("\red <B>[M] bursts out of [src]!</B>"), 2)
	..()

/mob/living/carbon/attack_hand(mob/M as mob)
	if(!istype(M, /mob/living/carbon)) return
	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/external/temp = H.organs_by_name[BP_R_HAND]
		if (H.hand)
			temp = H.organs_by_name[BP_L_HAND]
		if(temp && !temp.is_usable())
			H << "\red You can't use your [temp.name]"
			return

	return

/mob/living/carbon/electrocute_act(var/shock_damage, var/obj/source, var/siemens_coeff = 1.0, var/def_zone = null)
	if(status_flags & GODMODE)	return 0	//godmode
	shock_damage *= siemens_coeff
	if (shock_damage<1)
		return 0

	src.apply_damage(shock_damage, BURN, def_zone, used_weapon="Electrocution")
	playsound(loc, "sparks", 50, 1, -1)
	if (shock_damage > 15)
		src.visible_message(
			"\red [src] was shocked by the [source]!", \
			"\red <B>You feel a powerful shock course through your body!</B>", \
			"\red You hear a heavy electrical crack." \
		)
		Stun(10)//This should work for now, more is really silly and makes you lay there forever
		Weaken(10)
	else
		src.visible_message(
			"\red [src] was mildly shocked by the [source].", \
			"\red You feel a mild shock course through your body.", \
			"\red You hear a light zapping." \
		)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(5, 1, loc)
	s.start()

	return shock_damage

/mob/proc/swap_hand()
	return

/mob/living/carbon/swap_hand()
	src.hand = !( src.hand )
	if(hud_used.l_hand_hud_object && hud_used.r_hand_hud_object)
		if(hand)	//This being 1 means the left hand is in use
			hud_used.l_hand_hud_object.icon_state = "l_hand_active"
			hud_used.r_hand_hud_object.icon_state = "r_hand_inactive"
		else
			hud_used.l_hand_hud_object.icon_state = "l_hand_inactive"
			hud_used.r_hand_hud_object.icon_state = "r_hand_active"
	return

/mob/living/carbon/proc/activate_hand(var/selhand) //0 or "r" or "right" for right hand; 1 or "l" or "left" for left hand.

	if(istext(selhand))
		selhand = lowertext(selhand)

		if(selhand == "right" || selhand == "r")
			selhand = 0
		if(selhand == "left" || selhand == "l")
			selhand = 1

	if(selhand != src.hand)
		swap_hand()

/mob/living/carbon/proc/help_shake_act(mob/living/carbon/M)
	if (src.health >= config.health_threshold_crit)
		if(src == M && istype(src, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = src
			src.visible_message( \
				text("\blue [src] examines [].",src.gender==MALE?"himself":"herself"), \
				"\blue You check yourself for injuries." \
				)

			for(var/obj/item/organ/external/org in H.organs)
				var/list/status = list()
				var/brutedamage = org.brute_dam
				var/burndamage = org.burn_dam
				if(halloss > 0)
					if(prob(30))
						brutedamage += halloss
					if(prob(30))
						burndamage += halloss
				switch(brutedamage)
					if(1 to 20)
						status += "bruised"
					if(20 to 40)
						status += "wounded"
					if(40 to INFINITY)
						status += "mangled"

				switch(burndamage)
					if(1 to 10)
						status += "numb"
					if(10 to 40)
						status += "blistered"
					if(40 to INFINITY)
						status += "peeling away"

				if(org.is_stump())
					status += "MISSING"
				if(org.status & ORGAN_MUTATED)
					status += "weirdly shapen"
				if(org.dislocated == 2)
					status += "dislocated"
				if(org.status & ORGAN_BROKEN)
					status += "hurts when touched"
				if(org.status & ORGAN_DEAD)
					status += "is bruised and necrotic"
				if(!org.is_usable() || org.is_dislocated())
					status += "dangling uselessly"
				if(status.len)
					src.show_message("My [org.name] is <span class='warning'> [english_list(status)].</span>",1)
				else
					src.show_message("My [org.name] is <span class='notice'> OK.</span>",1)

			if((SKELETON in H.mutations) && (!H.w_uniform) && (!H.wear_suit))
				H.play_xylophone()
		else if (on_fire)
			playsound(src.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
			if (M.on_fire)
				M.visible_message("<span class='warning'>[M] tries to pat out [src]'s flames, but to no avail!</span>",
				"<span class='warning'>You try to pat out [src]'s flames, but to no avail! Put yourself out first!</span>")
			else
				M.visible_message("<span class='warning'>[M] tries to pat out [src]'s flames!</span>",
				"<span class='warning'>You try to pat out [src]'s flames! Hot!</span>")
				if(do_mob(M, src, 15))
					src.fire_stacks -= 0.5
					if (prob(10) && (M.fire_stacks <= 0))
						M.fire_stacks += 1
					M.IgniteMob()
					if (M.on_fire)
						M.visible_message("<span class='danger'>The fire spreads from [src] to [M]!</span>",
						"<span class='danger'>The fire spreads to you as well!</span>")
					else
						src.fire_stacks -= 0.5 //Less effective than stop, drop, and roll - also accounting for the fact that it takes half as long.
						if (src.fire_stacks <= 0)
							M.visible_message("<span class='warning'>[M] successfully pats out [src]'s flames.</span>",
							"<span class='warning'>You successfully pat out [src]'s flames.</span>")
							src.ExtinguishMob()
							src.fire_stacks = 0
		else
			var/t_him = "it"
			if (src.gender == MALE)
				t_him = "him"
			else if (src.gender == FEMALE)
				t_him = "her"
			if (istype(src,/mob/living/carbon/human) && src:w_uniform)
				var/mob/living/carbon/human/H = src
				H.w_uniform.add_fingerprint(M)

			var/show_ssd
			var/mob/living/carbon/human/H = src
			if(istype(H)) show_ssd = H.species.show_ssd
			if(show_ssd && !client && !teleop)
				M.visible_message("<span class='notice'>[M] shakes [src] trying to wake [t_him] up!</span>", \
				"<span class='notice'>You shake [src], but they do not respond... Maybe they have S.S.D?</span>")
			else if(lying || src.sleeping)
				src.sleeping = max(0,src.sleeping-5)
				if(src.sleeping == 0)
					src.resting = 0
				M.visible_message("<span class='notice'>[M] shakes [src] trying to wake [t_him] up!</span>", \
									"<span class='notice'>You shake [src] trying to wake [t_him] up!</span>")
			else
				var/mob/living/carbon/human/hugger = M
				if(istype(hugger))
					hugger.species.hug(hugger,src)
				else
					M.visible_message("<span class='notice'>[M] hugs [src] to make [t_him] feel better!</span>", \
								"<span class='notice'>You hug [src] to make [t_him] feel better!</span>")
				if(M.fire_stacks >= (src.fire_stacks + 3))
					src.fire_stacks += 1
					M.fire_stacks -= 1
				if(M.on_fire)
					src.IgniteMob()
			AdjustParalysis(-3)
			AdjustStunned(-3)
			AdjustWeakened(-3)

			playsound(src.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

/mob/living/carbon/proc/eyecheck()
	return 0

/mob/living/carbon/flash_eyes(intensity = FLASH_PROTECTION_MODERATE, override_blindness_check = FALSE, affect_silicon = FALSE, visual = FALSE, type = /obj/screen/fullscreen/flash)
	if(eyecheck() < intensity || override_blindness_check)
		return ..()

// ++++ROCKDTBEN++++ MOB PROCS -- Ask me before touching.
// Stop! ... Hammertime! ~Carn

/mob/living/carbon/proc/getDNA()
	return dna

/mob/living/carbon/proc/setDNA(var/datum/dna/newDNA)
	dna = newDNA

// ++++ROCKDTBEN++++ MOB PROCS //END

/mob/living/carbon/clean_blood()
	. = ..()
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.gloves)
			if(H.gloves.clean_blood())
				H.update_inv_gloves(0)
			H.gloves.germ_level = 0
		else
			if(H.bloody_hands)
				H.bloody_hands = 0
				H.update_inv_gloves(0)
			H.germ_level = 0
	update_icons()	//apply the now updated overlays to the mob

//Throwing stuff
/mob/proc/throw_item(atom/target)
	return

/mob/living/carbon/throw_item(atom/target)
	src.throw_mode_off()
	if(usr.stat || !target)
		return
	if(target.type == /obj/screen) return

	var/atom/movable/item = src.get_active_hand()

	if(!item) return

	var/throw_range = item.throw_range
	if (istype(item, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = item
		item = G.throw_held() //throw the person instead of the grab
		if(ismob(item))
			var/mob/M = item

			//limit throw range by relative mob size
			throw_range = round(M.throw_range * min(src.mob_size/M.mob_size, 1))

			var/turf/start_T = get_turf(loc) //Get the start and target tile for the descriptors
			var/turf/end_T = get_turf(target)
			if(start_T && end_T)
				var/start_T_descriptor = "<font color='#6b5d00'>tile at [start_T.x], [start_T.y], [start_T.z] in area [get_area(start_T)]</font>"
				var/end_T_descriptor = "<font color='#6b4400'>tile at [end_T.x], [end_T.y], [end_T.z] in area [get_area(end_T)]</font>"

				M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been thrown by [usr.name] ([usr.ckey]) from [start_T_descriptor] with the target [end_T_descriptor]</font>")
				usr.attack_log += text("\[[time_stamp()]\] <font color='red'>Has thrown [M.name] ([M.ckey]) from [start_T_descriptor] with the target [end_T_descriptor]</font>")
				msg_admin_attack("[usr.name] ([usr.ckey]) has thrown [M.name] ([M.ckey]) from [start_T_descriptor] with the target [end_T_descriptor] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[usr.x];Y=[usr.y];Z=[usr.z]'>JMP</a>)")

	src.drop_from_inventory(item)
	if(!item || !isturf(item.loc))
		return

	//actually throw it!
	src.visible_message("<span class='warning'>[src] has thrown [item].</span>")
	playsound(loc, "sound/effects/throw.wav", 50, 1)

	if(!src.lastarea)
		src.lastarea = get_area(src.loc)
	if((istype(src.loc, /turf/space)) || (src.lastarea.has_gravity == 0))
		src.inertia_dir = get_dir(target, src)
		step(src, inertia_dir)


/*
	if(istype(src.loc, /turf/space) || (src.flags & NOGRAV)) //they're in space, move em one space in the opposite direction
		src.inertia_dir = get_dir(target, src)
		step(src, inertia_dir)
*/


	item.throw_at(target, throw_range, item.throw_speed, src)

/mob/living/carbon/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	..()
	var/temp_inc = max(min(BODYTEMP_HEATING_MAX*(1-get_heat_protection()), exposed_temperature - bodytemperature), 0)
	bodytemperature += temp_inc

/mob/living/carbon/can_use_hands()
	if(handcuffed)
		return 0
	if(buckled && ! istype(buckled, /obj/structure/bed/chair)) // buckling does not restrict hands
		return 0
	return 1

/mob/living/carbon/restrained()
	if (handcuffed)
		return 1
	return

/mob/living/carbon/u_equip(obj/item/W as obj)
	if(!W)	return 0

	else if (W == handcuffed)
		handcuffed = null
		update_inv_handcuffed()
		if(buckled && buckled.buckle_require_restraints)
			buckled.unbuckle_mob()

	else if (W == legcuffed)
		legcuffed = null
		update_inv_legcuffed()
	else
	 ..()

	return

/mob/living/carbon/verb/mob_sleep()
	set name = "Sleep"
	set category = "IC"

	if(usr.sleeping)
		usr << "\red You are already sleeping"
		return
	if(alert(src,"You sure you want to sleep for a while?","Sleep","Yes","No") == "Yes")
		usr.sleeping = 20 //Short nap

/mob/living/carbon/Bump(var/atom/movable/AM, yes)
	if(now_pushing || !yes)
		return
	..()
	if(istype(AM, /mob/living/carbon) && prob(10))
		src.spread_disease_to(AM, "Contact")

/mob/living/carbon/slip(var/slipped_on,stun_duration=8)
	if(buckled)
		return 0
	stop_pulling()
	src << "<span class='warning'>You slipped on [slipped_on]!</span>"
	playsound(src.loc, 'sound/misc/slip.ogg', 50, 1, -3)
	Stun(stun_duration)
	Weaken(Floor(stun_duration/2))
	return 1

/mob/living/carbon/proc/add_chemical_effect(var/effect, var/magnitude = 1)
	if(effect in chem_effects)
		chem_effects[effect] += magnitude
	else
		chem_effects[effect] = magnitude

/mob/living/carbon/get_default_language()
	if(default_language)
		return default_language

	if(!species)
		return null
	return species.default_language ? all_languages[species.default_language] : null

/mob/living/carbon/show_inv(mob/user as mob)
	user.set_machine(src)
	var/dat = {"
	<B><HR><FONT size=3>[name]</FONT></B>
	<BR><HR>
	<BR><B>Head(Mask):</B> <A href='?src=\ref[src];item=mask'>[(wear_mask ? wear_mask : "Nothing")]</A>
	<BR><B>Left Hand:</B> <A href='?src=\ref[src];item=l_hand'>[(l_hand ? l_hand  : "Nothing")]</A>
	<BR><B>Right Hand:</B> <A href='?src=\ref[src];item=r_hand'>[(r_hand ? r_hand : "Nothing")]</A>
	<BR><B>Back:</B> <A href='?src=\ref[src];item=back'>[(back ? back : "Nothing")]</A> [((istype(wear_mask, /obj/item/clothing/mask) && istype(back, /obj/item/weapon/tank) && !( internal )) ? text(" <A href='?src=\ref[];item=internal'>Set Internal</A>", src) : "")]
	<BR>[(internal ? text("<A href='?src=\ref[src];item=internal'>Remove Internal</A>") : "")]
	<BR><A href='?src=\ref[src];item=pockets'>Empty Pockets</A>
	<BR><A href='?src=\ref[user];refresh=1'>Refresh</A>
	<BR><A href='?src=\ref[user];mach_close=mob[name]'>Close</A>
	<BR>"}
	user << browse(dat, text("window=mob[];size=325x500", name))
	onclose(user, "mob[name]")
	return

/**
 *  Return FALSE if victim can't be devoured, DEVOUR_FAST if they can be devoured quickly, DEVOUR_SLOW for slow devour
 */
/mob/living/carbon/proc/can_devour(atom/movable/victim)
	if((FAT in mutations) && issmall(victim))
		return DEVOUR_FAST

	return FALSE

/mob/living/carbon/onDropInto(var/atom/movable/AM)
	for(var/e in stomach_contents)
		var/atom/movable/stomach_content = e
		if(stomach_content.contains(AM))
			if(can_devour(AM))
				stomach_contents += AM
				return null
			src.visible_message("<span class='warning'>\The [src] regurgitates \the [AM]!</span>")
			return loc
	return ..()
/mob/living/carbon/proc/should_have_organ(var/organ_check)
	return 0

/mob/living/carbon/proc/can_feel_pain(var/check_organ)
	if(isSynthetic())
		return 0
	return !(species.flags & NO_PAIN)

/mob/living/carbon/proc/get_adjusted_metabolism(metabolism)
	return metabolism