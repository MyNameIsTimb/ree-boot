reeboot = reeboot or {}

-- REE-BOOT: server dying after 12 mins 50 seconds?
--  Install this badboy, drop an alias into your network.cfg, and all will be well.
--  Works on dedicated servers only.

-- define this as an alias to "exit" in cfg/network.cfg.
-- i.e.: `alias restart_server_hackylau "exit"`
local reboot_concommand = "restart_server_hackylau"
-- the message to show players when the server restarts.
local reboot_message = "FC&N is restarting. Give us a few minutes and we'll be right back online."
-- grace period. i.e.: "server will restart in X minutes"
local reboot_warning = 30 -- minutes
local reboot_grace_period = 10 -- minutes
-- i.e. "server rebooting soon, save your stuff"
local reboot_grace_period_urgent = 5 -- minutes
-- base reboot time offsets.
local reboot_at_hours = 12
local reboot_at_minutes = 30
-- start the base reboot timer when this script is loaded?
local start_at_load = true

-- the reeboot command works like this:
--  help: gets the help page
--  schedule <X>: schedules a reboot in <X> minutes
--  cancel: cancels the reboot 
--  when: displays how much time is left until reboot 
--  announce: tells everyone how much time is left until reboot
-- all subcommands need admin or superadmin EXCEPT `when`




-- Editing below voids warranty

if CLIENT then 
	net.Receive( "reeboot_chat_message", function( len )
		local ctab = net.ReadTable()
		if ctab ~= nil then 
			chat.AddText( unpack( ctab ) )
		end
	end )
end

if SERVER then
	util.AddNetworkString( "reeboot_chat_message" )
	
	local reboot_internal = function()
		-- kick all players and show our nice message
		for k,v in next, player.GetAll(), nil do 
			if IsValid( v ) then 
				v:Kick( reboot_message )
			end 
		end
		-- issue the restart 
		timer.Simple( 0, function()
			game.ConsoleCommand( reboot_concommand .. "\n" )
		end )
	end
	
	-- Stops and removes the timers 
	local cancel_timers = function()
		timer.Stop( "reeboot_timer_farout_warn" )
		timer.Remove( "reeboot_timer_farout_warn" )
		timer.Stop( "reeboot_timer_before_warn" )
		timer.Remove( "reeboot_timer_before_warn" )
		timer.Stop( "reeboot_timer_post_warn" )
		timer.Remove( "reeboot_timer_post_warn" )
		timer.Stop( "reeboot_timer_post_warn_urgent" )
		timer.Remove( "reeboot_timer_post_warn_urgent" )
	end 
	
	-- Sends shit to players' chat 
	local send_chat = function( str )
		net.Start( "reeboot_chat_message" )
			net.WriteTable( { Color( 255, 155, 0 ), "Ree-boot // ", color_white, str } )
		net.Broadcast()
	end
	
	-- Reboots the server after X seconds of delay.
	reeboot.reboot = function( sec_delay )
		local sec_delay = sec_delay or 0
		if sec_delay == 0 then 
			reboot_internal()
		else
			cancel_timers()
			
			-- Outer timer: actually reboots the server.
			timer.Create( "reeboot_timer_before_warn", sec_delay, 1, function()
				send_chat( "The server is rebooting. See you soon!" )
				timer.Simple( 5, function()
					reboot_internal()
				end )
			end )
			
			if ( sec_delay > ( reboot_warning * 60 ) ) then	
				-- First warning: to give people a notice that the server will go down in 30 minutes. Finish up.
				timer.Create( "reeboot_timer_farout_warn", sec_delay - ( reboot_warning * 60 ), 1, function()
					send_chat( "Reminder: The server will reboot in " .. reboot_warning .. " minutes. Take time to finish what you're doing." )
				end )
			end
			
			if ( sec_delay > ( reboot_grace_period * 60 ) ) then	
				-- First grace period: to give people a grace period to save stuff.
				timer.Create( "reeboot_timer_post_warn", sec_delay - ( reboot_grace_period * 60 ), 1, function()
					send_chat( "Warning! The server will reboot in " .. reboot_grace_period .. " minutes. Save your stuff!" )
				end )
			else
				-- We don't have enough time to cover the first grace period.
				send_chat( "Warning! The server will reboot in " .. math.floor( sec_delay / 60 ) .. " minutes. Save your stuff!" )
			end
			
			if ( sec_delay > ( reboot_grace_period_urgent * 60 ) ) then	
				-- Second grace period: to give people a notice of very shortly rebooting.
				timer.Create( "reeboot_timer_post_warn_urgent", sec_delay - ( reboot_grace_period_urgent * 60 ), 1, function()
					send_chat( "Urgent warning! The server will reboot in " .. reboot_grace_period_urgent .. " minutes. Make sure all your stuff is saved." )
				end )
			end
			
		end
	end
	
	-- Do up the concommand.
	concommand.Add( "reeboot", function( ply, cmd, args, argStr )
		local operation = args[1]
		if operation == "when" then 
			local tname = "reeboot_timer_before_warn"
			local txt = "There is no reboot scheduled."
			if timer.Exists( tname ) and ( timer.TimeLeft( tname ) != nil ) then 
				local tleft = timer.TimeLeft( tname )
				local mleft = math.floor( ( tleft % 3600 ) / 60 )
				local hleft = math.floor( tleft / 3600 )
				txt = "The server is restarting in " .. hleft .. " hours and " .. mleft .. " minutes."
			end
			if IsValid( ply ) then
				ply:ChatPrint( txt )
			else
				print( txt )
			end
		else
			local player_can_do = not IsValid( ply )
			if not player_can_do then 
				player_can_do = ply:IsAdmin() or ply:IsSuperAdmin()
			end 
			local nick = ( IsValid( ply ) and ply:Nick() or "The Server" )
			if not player_can_do then 
				print( "Player " .. ply:SteamID() .. " (" .. ply:Nick() .. ") tried accessing reeboot." )
				ply:ChatPrint( "You are not allowed to use Reeboot on this server." )
			else 
				if operation == nil then 
					ply:ChatPrint( "Please pass an operation. Type `reeboot help` for help." )
				elseif operation == "schedule" then 
					local delay = args[2]
					if delay == nil then 
						ply:ChatPrint( "A delay (in minutes) is needed. 0 the an option for an immediate reboot." )
					else 
						delay = tonumber( delay )
						reeboot.reboot( delay * 60 )
						send_chat( nick .. " just scheduled a reboot for " .. delay .. " minutes from now." )
					end 
				elseif operation == "cancel" then 
					cancel_timers()
					send_chat( nick .. " just canceled the scheduled reboot." )
				elseif operation == "announce" then 
					local tname = "reeboot_timer_before_warn"
					if timer.Exists( tname ) and ( timer.TimeLeft( tname ) != nil ) then 
						local tleft = timer.TimeLeft( tname )
						local mleft = math.floor( ( tleft % 3600 ) / 60 )
						local hleft = math.floor( tleft / 3600 )
						send_chat( "The server is restarting in " .. hleft .. " hours and " .. mleft .. " minutes." )
					else 
						send_chat( "There is no reboot scheduled." )
					end 
				elseif operation == "help" then 
					ply:ChatPrint( "REEBOOT: Commands" )
					ply:ChatPrint( " `help`: displays this text." )
					ply:ChatPrint( " `schedule <minutes>`: reboots in the specified minutes." )
					ply:ChatPrint( " `when`: displays when the reboot will happen." )
					ply:ChatPrint( " `cancel`: cancels the scheduled reboot." )
					ply:ChatPrint( " `announce`: tells everyone when the reboot is happening." )
				end 
			end 
		end 
	end )
	
	-- Informational hook for the player.
	-- Just have them run the "reeboot when" command as the code already exists there.
	hook.Add( "PlayerInitialSpawn", "reeboot_PlayerInitialSpawn", function( ply )
		timer.Simple( 30, function()
			ply:ConCommand( "reeboot", "when" )
		end )
	end )
	
	-- schedule the reboot.
	if start_at_load then
		print( "Scheduling reboot for " .. reboot_at_hours .. " hours and " .. reboot_at_minutes .. " minutes from now." )
		reeboot.reboot( ( reboot_at_hours * 3600 ) + ( reboot_at_minutes * 60 ) )
	end
end
