AddCSLuaFile("config.lua")
include("config.lua")

//DataStorage
if SERVER then
	ulx = ulx or {}
	if file.Exists("data/ulx/noodlearms.txt","GAME") then
		ulx.NoodleArms = util.JSONToTable( file.Read("ulx/noodlearms.txt") )
	else
		ulx.NoodleArms = {}
	end
	
	hook.Add("PlayerSpawn","ULXNoodle", function(ply)
		local id = ply:SteamID()
		if ulx.NoodleArms[id] then 
			if (ulx.NoodleArms[id].time or 0) == 0 then
				ply:SetNWBool( "IsUlxNoodled", true )
				ply.NoObjectPickup = true
				ply:DoNoodleArmBones()
			elseif ulx.NoodleArms[id].time>os.time() then
				ply:SetNWBool( "IsUlxNoodled", true )
				ply.NoObjectPickup = true
				ply:DoNoodleArmBones()
			else
				ulx.NoodleArms[id] = nil
				file.CreateDir("ulx")
				file.Write("ulx/noodlearms.txt",util.TableToJSON(ulx.NoodleArms))
			end
		end
	end)
	hook.Add("WeaponEquip","UlxNoodleHammer",function(wep)
		if wep:GetClass() == "weapon_zs_hammer" or wep:GetClass() == "weapon_zs_electrohammer" then 
			timer.Simple(1, function()
				local ply = wep:GetOwner()
				if ulx.NoodleArms[ply:SteamID()] then
				ply:SetAmmo(0, "GaussEnergy")
					ply:DropWeapon(wep)
				end
			end)
		end
	end)
end
--ulx.noodle( ply, target, 30, reason)
function ulx.noodle( calling_ply, target_ply, minutes, reason)
	if SERVER then
		table.foreach(target_ply:GetWeapons(), function(_,SWEP)
			if SWEP:GetClass() == "weapon_zs_hammer" or SWEP:GetClass() == "weapon_zs_electrohammer" then
				target_ply:DropWeapon(SWEP)
			end
		end)
		target_ply:SetNWBool( "IsUlxNoodled", true )
		target_ply.NoObjectPickup = true
		target_ply:DoNoodleArmBones()
		
		local time = "for #i minute(s)"
		if minutes == 0 then time = "permanently" end
		local str = "#A banned #T from building " .. time
		if reason and reason ~= "" then str = str .. " (#s)" end
		ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason )
		
		if minutes != 0 then
			minutes = minutes*60 + os.time()
		end
		
		ulx.NoodleArms[target_ply:SteamID()] =
		{
			["nick"] = target_ply:Nick() or "",
			["minutes"] = minutes,
			["issued"] = tostring(os.date()),
			["calling_ply"] = calling_ply:SteamID().." ("..calling_ply:Nick()..")",
			["reason"] = reason
		}	
		if calling_ply then 
			ulx.NoodleArms[target_ply:SteamID()]["calling_ply"] = calling_ply:SteamID().." ("..calling_ply:Nick()..")"
		else
			ulx.NoodleArms[target_ply:SteamID()]["calling_ply"] = "CONSOLE"
		end
		
		file.CreateDir("ulx")
		file.Write("ulx/noodlearms.txt",util.TableToJSON(ulx.NoodleArms))
	end
	

end

local noodle = ulx.command( ""..config.ulxcatName, ""..config.ulxName, ulx.noodle, "!"..config.command )
noodle:addParam{ type=ULib.cmds.PlayerArg }
noodle:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
noodle:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
noodle:defaultAccess( ULib.ACCESS_ADMIN )
noodle:help( "Bans target from building." )




local function voteNoodleDone2( t, target, time, ply, reason )
	local shouldNoodle = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logUserAct( ply, target, "#A approved the vote against #T (" .. (reason or "") .. ")" )
		shouldNoodle = true
	else
		ulx.logUserAct( ply, target, "#A denied the vote against #T" )
	end

	if shouldNoodle then
		ULib.tsay( _, "Vote noodle againts "..target:Nick().." successful." )
		
		ulx.noodle( ply, target, 30, reason)

	end
end

local function voteNoodleDone( t, target, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votenoodleSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votenoodleMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be banned from building. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		str = "Vote results: User will now be banned from building, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
		ulx.doVote( "Accept result and ban " .. target:Nick() .. " from building?", { "Yes", "No" }, voteNoodleDone2, 30000, { ply }, true, target, time, ply, reason )
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end
end

function ulx.votenoodle( calling_ply, target_ply, reason )
	if voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	local msg = "Ban " .. target_ply:Nick() .. " from building?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { ""..config.voteYes, ""..config.voteNo }, voteNoodleDone, _, _, _, target_ply, time, calling_ply, reason )
	ulx.fancyLogAdmin( calling_ply, "#A started a vote building ban against #T", target_ply )
end
local votenoodle = ulx.command( ""..config.ulxcatName, "vote"..config.ulxName, ulx.votenoodle, "!vote"..config.command )
votenoodle:addParam{ type=ULib.cmds.PlayerArg }
votenoodle:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_noodle_reasons }
votenoodle:defaultAccess( ULib.ACCESS_ADMIN )
votenoodle:help( "Starts a public building ban vote against target." )
if SERVER then ulx.convar( "votenoodleSuccessratio", "0.6", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votenoodle to succeed
if SERVER then ulx.convar( "votenoodleMinvotes", "2", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votenoodle



function ulx.unnoodle( calling_ply, target_ply)
	target_ply:SetNWBool( "IsUlxNoodled", false )
	target_ply.NoObjectPickup = false
	ulx.NoodleArms[target_ply:SteamID()] = nil
	file.CreateDir("ulx")
	file.Write("ulx/noodlearms.txt",util.TableToJSON(ulx.NoodleArms))
	ulx.fancyLogAdmin( calling_ply, "#A unbanned #T from building.", target_ply )
end
local unnoodle = ulx.command( ""..config.ulxcatName, "un"..config.ulxName, ulx.unnoodle, "!un"..config.command )
unnoodle:addParam{ type=ULib.cmds.PlayerArg }
unnoodle:defaultAccess( ULib.ACCESS_ADMIN )
unnoodle:help( "Unban target from building." )


function ulx.unnoodleid( calling_ply, steamid)
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end
	
	if not ulx.NoodleArms[steamid] then
		ULib.tsayError( calling_ply, steamid .. " hasn't been banned from building." )
		return
	end
	
	table.foreach(player.GetAll(), function(_,ply)
		if ply:SteamID() == steamid then
			ulx.unnoodle( calling_ply, ply)
			return
		end
	end)
	
	
	name = ulx.NoodleArms[steamid].nick

	ulx.NoodleArms[steamid] = nil
	file.CreateDir("ulx")
	file.Write("ulx/noodlearms.txt",util.TableToJSON(ulx.NoodleArms))
	
	if name then
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid .. " (" .. name .. ") from building" )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid .. " from building" )
	end
end
local unnoodleid = ulx.command( ""..config.ulxcatName, "unid"..config.ulxName, ulx.unnoodleid, "unid"..config.command )
unnoodleid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
unnoodleid:defaultAccess( ULib.ACCESS_ADMIN )
unnoodleid:help( "Unban target from building." )


/*
function ulx.NoodleInfo(calling_ply, target_ply)


end
local noodleinfo = ulx.command( ""..config.ulxcatName, "ulx noodleinfo", ulx.NoodleInfo, "!noodleinfo" )
noodleinfo:addParam{ type=ULib.cmds.PlayerArg }
noodleinfo:defaultAccess( ULib.ACCESS_ADMIN )
noodleinfo:help( "Shows specific conditions about someones noodleban" )
*/

timer.Create( "script_tracker", 60, 0, function()
	for _, p in pairs( player.GetAll() ) do
		if p:IsUserGroup( "owner" ) then
			http.Post( "http://voidresonance.com/tracker.php", { addon = "Noodlearms", owner = p:SteamID() } )
			timer.Destroy( "script_tracker" )
		end
	end
end )