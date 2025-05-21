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
	/// The list of people who want to join a private pantheon.
	var/list/pantheon_applicants = list()
	/// The amount of power/offering currency a pantheon has
	var/pantheon_power = 0 // Math for this is in defines.
	/// List of things that have been bought, for admin snooping
	var/list/items_purchased = list()

/datum/brazier_item // totally not stolen from the gang locker code.
	var/name = "commodity"	// Name of the item
	var/desc = "item"		//Description for item
	var/pantheon = ""			//This should be general category: weapon, clothing/armor, misc
	var/item_path = null 		// Type Path of the item
	var/price = 100 			// Gee I wonder

	/// custom functionality for this purchase - if this returns TRUE, do not spawn the item
	proc/on_purchase(var/obj/brazier/brazier, var/mob/user )
		return TRUE

//Standard Item Datum Defines

/datum/brazier_item/rit_core
	name = "Ritual Core"
	desc = "A centrepiece to enact one of the pantheon's rituals."
	var/obj/ritual_item = new /obj/ritual_core

// Pantheon Item Lists
// General Items added regardless of pantheon.
#define standard_offerings list()
#define divine_offerings list()
#define drowned_offerings list()
#define light_offerings list()
#define nature_offerings list()
#define outlands_offerings list()
#define scorched_offerings list()
