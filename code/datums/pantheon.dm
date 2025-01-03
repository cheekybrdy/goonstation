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
