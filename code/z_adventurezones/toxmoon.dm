///////////////////////////////////////////////////////////////////////////////////////////////////////////
/////// contents:
/////// --------
/////// terrain
/////// areas
///////
///////
///////

////////////////////////////////
///////////////////////////////////////

///////////////////

/turf/unsimulated/floor/setpieces/toxmoon
	name = "wilted silt"
	desc = "Someone should fire the gardener here."
	icon = 'icons/turf/forest.dmi'
	icon_state = "grass1"

	grass

		New()
			. = ..()
			var/grass_type = rand(1,9)
			src.icon_state = "grass[grass_type]"

	irradiated
		radgas = 100
		nitrogen = 0
		oxygen = 0

		New()
			..()
			var/image/fallout_overlay = image('icons/effects/tile_effects.dmi', "rad_particles")
			AddOverlays(fallout_overlay, "fallout")

/turf/unsimulated/floor/setpieces/toxmoon/radpool
	name = "radioactive goop"
	desc = "The water test says this needs more chlorine."
	icon = 'icons/turf/floors.dmi'
	icon_state = "wastewaterfloor"

	can_replace_with_stuff = TRUE
	can_burn = FALSE
	can_break = FALSE

	var/radStrength = 75
	var/neutron = FALSE // no neutron shit, unless you want to make a especially vile subtype

	Entered(atom/movable/O, atom/old_loc, var/mult = 1)
		..()
		if(!(isnull(old_loc) || O.anchored == ANCHORED_ALWAYS))
			return_if_overlay_or_effect(O)

			if (istype(O, /obj/projectile) || istype(O, /obj/arrival_missile))
				return

			if (isintangible(O))
				return

			if (istype(O, /obj/critter))
				var/obj/critter/C = O
				if (C.flying)
					return

			if (istype(O, /obj/machinery/vehicle))
				var/obj/machinery/vehicle/V = O
				if(istype(V.movement_controller, /datum/movement_controller/pod) && V.get_part(POD_PART_ENGINE)?.active)
					return

			if (isliving(O))
				var/mob/living/M = O
				if(HAS_ATOM_PROPERTY(M, PROP_ATOM_FLOATING))
					return

			if (check_target_immunity(O, TRUE))
				return

			if (HAS_ATOM_PROPERTY(O, PROP_ATOM_FLOATING))
				if (isliving(O) && !ON_COOLDOWN(src, "goop_hurty", 0.5 SECONDS))
					var/mob/living/M = O
					M.take_radiation_dose(mult * (neutron ? 1 SIEVERTS: 0.6 SIEVERTS) * (radStrength/100))
					var/other_damage = rand(1,3)
					if (other_damage == 1)
						boutput(M, "You feel a piece of debris in the pool cut against you!")
						take_bleeding_damage(M, null, rand(10,20) * mult, DAMAGE_STAB)
					if (other_damage == 2)
						boutput(M, "You feel the corrosive goop singe you!")
						random_burn_damage(M, rand(10,20) * mult)
					if (other_damage == 3)
						boutput(M, "You feel bile seep across your skin.")
						if(M == /mob/living/carbon/human)
							M.take_toxin_damage(rand(10,20))
			return



/area/toxmoon
	name = "Outpost Gamma Disposal Site"
	icon_state = "green"

/area/toxmoon/depot
	name = "Outpost Gamma Waste Depot"

/area/toxmoon/exterior
	name = "Outpost Gamma Waste Site"
	ambient_light = rgb(180, 150, 150)
	sound_group = "swamp_heights"

/area/toxmoon/entrance
	name = "Geisel Radiofabrik Decommisioned Power Plant - Entrance"
	ambient_light = rgb(180, 150, 150)
	sound_group = "swamp_heights"

/area/toxmoon/upper_plant
	name = "Geisel Radiofabrik Decommisioned Power Plant - Upper Level"

/area/toxmoon/lower_plant
	name = "Geisel Radiofabrik Decommisioned Power Plant - Lower Level"
