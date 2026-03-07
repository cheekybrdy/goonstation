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
	name = "floor"
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"

	irradiated
		radgas = 100
		nitrogen = 0
		oxygen = 0

		New()
			..()
			var/image/fallout_overlay = image('icons/effects/tile_effects.dmi', "rad_particles")
			AddOverlays(fallout_overlay, "fallout")

		plating
			name = "plating"
			icon_state = "plating"
			intact = 0
			layer = PLATING_LAYER

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

	New()
		..()
		src.add_simple_light("rad", list(0, 0.8 * 255, 0.3 * 255, 0.8 * 255))

	Crossed(atom/movable/O, atom/old_loc, var/mult = 1)
		..()
		if(!(isnull(old_loc) || O.anchored == ANCHORED_ALWAYS))
			return_if_overlay_or_effect(O)

			if (istype(O, /obj/projectile) || istype(O, /obj/arrival_missile))
				message_admins("goop tried but gun or somthin!")
				return

			if (isintangible(O))
				message_admins("goop tried but intango man!")
				return

			if (istype(O, /obj/critter))
				message_admins("goop tried but critter!")
				var/obj/critter/C = O
				if (C.flying)
					return

			if (istype(O, /obj/machinery/vehicle))
				message_admins("goop tried but car!")
				var/obj/machinery/vehicle/V = O
				if(istype(V.movement_controller, /datum/movement_controller/pod) && V.get_part(POD_PART_ENGINE)?.active)
					return

			if (check_target_immunity(O, TRUE))
				message_admins("goop tried but immunity!")
				return
			if (isliving(O) && !ON_COOLDOWN(src, "goop_hurty", 0.5 SECONDS))
				message_admins("goop tried and worked!")
				var/mob/living/M = O
				M.take_radiation_dose(mult * (neutron ? 1 SIEVERTS: 0.6 SIEVERTS) * (radStrength/100))
				M.changeStatus("slowed", 3 SECONDS)
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
			message_admins("goop tried and met no criteria")
			return



/area/toxmoon
	name = "Facility Sigma Disposal Site"
	icon_state = "green"

/area/toxmoon/depot
	name = "Facility Sigma Waste Depot"

/area/toxmoon/plant
	irradiated = 0.2
	permarads = 1
	rad_overlay = 0

/area/toxmoon/plant/exterior
	name = "Facility Sigma Waste Site"
	ambient_light = rgb(180, 150, 150)
	sound_group = "swamp_heights"

/area/toxmoon/plant/entrance
	name = "Geisel Radiofabrik Decommisioned Power Plant - Entrance"
	ambient_light = rgb(180, 150, 150)
	sound_group = "swamp_heights"

/area/toxmoon/plant/upper
	name = "Geisel Radiofabrik Decommisioned Power Plant - Upper Level"


/area/toxmoon/plant/lower
	name = "Geisel Radiofabrik Decommisioned Power Plant - Lower Level"
