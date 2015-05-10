config = {} // Dont edit this!

config.headName = "Banned from building" // Text that is shown above someone who is banned from building. Leave blank for nothing to be shown

config.ulxName = "noodle" // The name of the addon you it to be called in ULX. DONT leave blank

config.command = "noodle" // The command used to ban/unban users from building (!, un, unid is already added at the front). DONT leave blank

config.ulxcatName = "Zombie Survival" //  The category name you want the addon name to be in ULX. DONT leave blank

config.voteYes = "Yes, he is a bad builder, ban him from building" // What should the text say for voing yes?. DONT leave blank

config.voteNo = "Don't ban him from building, he's a good player" // What should the text say for voting no?. DONT leave blank

config.selfMessage = "Banned from building" // Text that is shown on the right of the clients screen who is banned from building.

config.textFont = "DermaLarge" // The font used on the overhead (DermaLarge is best)

--config.zombieEscape = true

--[[config.BannedWeapons = {}
config.BannedWeapons = {
	weapon_zs_hammer,
	weapon_zs_electrohammer,
	weapon_zs_nailgun
}]]--

		---if wep:GetClass() == "weapon_zs_hammer" or wep:GetClass() == "weapon_zs_electrohammer" then 

						
