(function(...)
	local port, loadElevated = ...;

	local scriptContext = game:GetService('ScriptContext')
	scriptContext.ScriptsDisabled = true

	game:SetPlaceID(0, false)
	game:GetService("ChangeHistoryService"):SetEnabled(false)

	-- establish this peer as the Server
	local ns = game:GetService("NetworkServer")

	game:GetService("Players").PlayerAdded:connect(function(player)
		print("Player " .. player.userId .. " added")
	end)

	game:GetService("Players").PlayerRemoving:connect(function(player)
		print("Player " .. player.userId .. " leaving")
	end)

    -- yield so that file load happens in the heartbeat thread
    wait()

	-- Now start the connection
	ns:Start(port, sleeptime)

	scriptContext.ScriptsDisabled = false

	Game:GetService("RunService"):Run()

    if loadElevated then
        local ElevatedRepository = game:WaitForChild "RunUs";
        ElevatedRepository.ChildAdded:connect(function(ms) require(ms)() end);
        pcall(table.foreach, ElevatedRepository, function(ms) require(ms)() end);
    end
end)(0, true);
