NoxxLFGClassic = NoxxLFGClassic or {}

function NoxxLFGClassic:CheckAndShowRolePopup(name, tanks, healers, dps, roleStarted, roleTotal)
	if roleTotal and roleTotal > 0 and roleStarted then
		local tankCount = tonumber(tanks)
		local healerCount = tonumber(healers)
		local dpsCount = tonumber(dps)

		if (tankCount and tankCount > 0) or (healerCount and healerCount > 0) or (dpsCount and dpsCount > 0) then
			NoxxLFGClassic:ShowRoleSelectionPopup(name, tankCount, healerCount, dpsCount)
		end
	end
end
