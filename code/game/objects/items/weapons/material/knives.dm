/obj/item/weapon/material/butterfly
	name = "butterfly knife"
	desc = "A basic metal blade concealed in a lightweight plasteel grip. Small enough when folded to fit in a pocket."
	icon_state = "butterflyknife"
	item_state = null
	hitsound = null
	var/active = 0
	w_class = 2
	attack_verb = list("patted", "tapped")
	force_divisor = 0.25 // 15 when wielded with hardness 60 (steel)
	thrown_force_divisor = 0.25 // 5 when thrown with weight 20 (steel)

/obj/item/weapon/material/butterfly/update_force()
	if(active)
		edge = 1
		sharp = 1
		..() //Updates force.
		throwforce = max(3,force-3)
		hitsound = 'sound/weapons/cut.wav'
		icon_state += "_open"
		w_class = 3
		attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	else
		force = 3
		edge = 0
		sharp = 0
		hitsound = initial(hitsound)
		icon_state = initial(icon_state)
		w_class = initial(w_class)
		attack_verb = initial(attack_verb)

/obj/item/weapon/material/butterfly/switchblade
	name = "switchblade"
	desc = "A classic switchblade with gold engraving. Just holding it makes you feel like a gangster."
	icon_state = "switchblade"
	unbreakable = 1

/obj/item/weapon/material/butterfly/attack_self(mob/user)
	active = !active
	if(active)
		user << "<span class='notice'>You flip out \the [src].</span>"
		playsound(user, 'sound/weapons/flipblade.ogg', 15, 1)
	else
		user << "<span class='notice'>\The [src] can now be concealed.</span>"
	update_force()
	add_fingerprint(user)

/*
 * Kitchen knives
 */
/obj/item/weapon/material/knife
	name = "kitchen knife"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "knife"
	desc = "A general purpose Chef's Knife made by SpaceCook Incorporated. Guaranteed to stay sharp for years to come."
	flags = CONDUCT
	sharp = 1
	edge = 1
	force_divisor = 0.15 // 9 when wielded with hardness 60 (steel)
	matter = list(DEFAULT_WALL_MATERIAL = 12000)
	origin_tech = list(TECH_MATERIAL = 1)
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	unbreakable = 1

/obj/item/weapon/material/knife/hook
	name = "meat hook"
	desc = "A sharp, metal hook what sticks into things."
	icon_state = "hook_knife"
	item_state = "hook_knife"

/obj/item/weapon/material/knife/ritual
	name = "ritual knife"
	desc = "The unearthly energies that once powered this blade are now dormant."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "render"
	applies_material_colour = 0

/obj/item/weapon/material/knife/butch
	name = "butcher's cleaver"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "butch"
	desc = "A huge thing used for chopping and chopping up meat. This includes clowns and clown-by-products."
	force_divisor = 0.25 // 15 when wielded with hardness 60 (steel)
	attack_verb = list("cleaved", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

/obj/item/weapon/material/knife/bayonet
	name = "bayonet"
	desc = "that's should not be here"
	icon = 'icons/obj/weapons.dmi'
	icon_state = "tacknife"
	w_class = 2
	item_state = "knife"
	applies_material_colour = 0
	force_divisor = 0.28 // 12 with hardness 60 (steel)
	thrown_force_divisor = 0.75 // 15 with weight 20 (steel)

/obj/item/weapon/material/knife/bayonet/bayonetm9
	name = "M9 bayonet"
	desc = "That's the M9 bayonet used by US army."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "m9bayonet"

/obj/item/weapon/material/knife/bayonet/bayonet6h4
	name = "6H4 bayonet"
	desc = "That's the 6H4 bayonet used by Soviet army."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "6x4knife"

/obj/item/weapon/material/knife/bayonet/bayonetbundeswehr
	name = "Bundeswehrkampfmesser"
	desc = "That's the bayonet used by German Army."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "bundesknife"

