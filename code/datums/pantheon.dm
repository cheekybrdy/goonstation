/datum/pantheon
	/// The chosen name of this pantheon.
	var/pantheon_type = null
	/// The mind of this pantheon's leader.
	var/datum/mind/leader = null
	/// The minds of pantheon members associated with this pantheon. Does not include the pantheon leader.
	var/list/datum/mind/members = list()
	/// The pantheon brazier of this pantheon.
	var/obj/brazier/brazier = null
	/// The location of this pantheon's brazier's founding, used for proximity benefits.
	var/area/holy_site = null

/datum/brazier_item // totally not stolen from the gang locker code.
	var/name = "commodity"	// Name of the item
	var/desc = "item"		//Description for item
	var/pantheon = ""			//This should be general category: weapon, clothing/armor, misc
	var/item_path = null 		// Type Path of the item
	var/price = 100 			// Gee I wonder

//Standard Item Datum Defines

/datum/brazier_item/rit_core
	name = "Ritual Core"
	desc = "A centrepiece to enacct one of the pantheon's rituals."
	var/obj/ritual_item =
