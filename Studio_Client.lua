(function(...)
    local Server, Port, CreatorID, CreatorType, ChatType = ...;
	pcall(function() game:SetPlaceID(-1, false) end)

	-- if we are on a touch device, no blocking http calls allowed! This can cause a crash on iOS
	-- In general we need a long term strategy to remove blocking http calls from all platforms
	local isTouchDevice = Game:GetService("UserInputService").TouchEnabled

	print("Joining!")

    waitingForCharacter = true;
	game:GetService("ChangeHistoryService"):SetEnabled(false)
	game:GetService("ContentProvider"):SetThreadPool(16)
	game:GetService("InsertService"):SetBaseSetsUrl("http://www.roblox.com/Game/Tools/InsertAsset.ashx?nsets=10&type=base")
	game:GetService("InsertService"):SetUserSetsUrl("http://www.roblox.com/Game/Tools/InsertAsset.ashx?nsets=20&type=user&userid=%d")
	game:GetService("InsertService"):SetCollectionUrl("http://www.roblox.com/Game/Tools/InsertAsset.ashx?sid=%d")
	game:GetService("InsertService"):SetAssetUrl("http://www.roblox.com/Asset/?id=%d")
	game:GetService("InsertService"):SetAssetVersionUrl("http://www.roblox.com/Asset/?assetversionid=%d")

	pcall(function() game:GetService("SocialService"):SetFriendUrl("http://www.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=IsFriendsWith&playerid=%d&userid=%d") end)
	pcall(function() game:GetService("SocialService"):SetBestFriendUrl("http://www.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=IsBestFriendsWith&playerid=%d&userid=%d") end)
	pcall(function() game:GetService("SocialService"):SetGroupUrl("http://www.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=IsInGroup&playerid=%d&groupid=%d") end)
	pcall(function() game:GetService("SocialService"):SetGroupRankUrl("http://www.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=GetGroupRank&playerid=%d&groupid=%d") end)
	pcall(function() game:GetService("SocialService"):SetGroupRoleUrl("http://www.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=GetGroupRole&playerid=%d&groupid=%d") end)
	pcall(function() game:GetService("GamePassService"):SetPlayerHasPassUrl("http://www.roblox.com/Game/GamePass/GamePassHandler.ashx?Action=HasPass&UserID=%d&PassID=%d") end)
	pcall(function() game:GetService("MarketplaceService"):SetProductInfoUrl("https://api.roblox.com/marketplace/productinfo?assetId=%d") end)
	pcall(function() game:GetService("MarketplaceService"):SetPlayerOwnsAssetUrl("https://api.roblox.com/ownership/hasasset?userId=%d&assetId=%d") end)
	pcall(function() game:SetCreatorID(CreatorID or 0, CreatorType or Enum.CreatorType.User) end)

	pcall(function() game:GetService("Players"):SetChatStyle(ChatType) end)

	local client = game:GetService("NetworkClient")
	local visit = game:GetService("Visit")
    
    local function setMessage(Message)
        print("Message", Message);
		game:SetMessage(Message);
    end

	function showErrorWindow(...)
		setMessage(table.concat({...}, " "))
	end

	function reportError(err, message)
		client:Disconnect()
		wait(4)
		showErrorWindow("Error: " .. err)
	end

	-- called when the client connection closes
	function onDisconnection(peer, lostConnection)
        if lostConnection then
            showErrorWindow("Disconnected from ", Server, Port)
        else
            showErrorWindow("You were kicked from", Server, Port)
        end
	end

	function requestCharacter(replicator)

		-- prepare code for when the Character appears
		local connection
		connection = player.Changed:connect(function (property)
			if property=="Character" then
				game:ClearMessage()
				waitingForCharacter = false

				connection:disconnect()
			end
		end)

		setMessage("Requesting character")

		local success, err = pcall(function()
			replicator:RequestCharacter()
			setMessage("Waiting for character")
			waitingForCharacter = true
		end)
		if not success then
			reportError(err)
			return
		end
	end

	-- called when the client connection is established
	function onConnectionAccepted(url, replicator)
		connectResolved = true

		local waitingForMarker = true

		local success, err = pcall(function()
			replicator.Disconnection:connect(onDisconnection)

			-- Wait for a marker to return before creating the Player
			local marker = replicator:SendMarker()

			marker.Received:connect(function()
				waitingForMarker = false
				requestCharacter(replicator)
			end)
		end)

		if not success then
			return reportError(err)
		end

		while waitingForMarker do
			workspace:ZoomToExtents()
			wait(0.5)
		end
	end

	-- called when the client connection fails
	function onConnectionFailed(_, error)
		showErrorWindow("Connection failed. (Error=" .. error .. ")")
	end

	-- called when the client connection is rejected
	function onConnectionRejected()
		connectionFailed:disconnect()
		showErrorWindow("Version mismatch / connection rejected")
	end

	local success, err = pcall(function()
        print("Starting");
		game:SetRemoteBuildMode(true)

		setMessage("Connecting to Server")
		client.ConnectionAccepted:connect(onConnectionAccepted)
		client.ConnectionRejected:connect(onConnectionRejected)
		connectionFailed = client.ConnectionFailed:connect(onConnectionFailed)
		client.Ticket = ""

		playerConnectSucces, player = pcall(function() return client:PlayerConnect(0, Server, Port, 0, threadSleepTime) end)

        setMessage("Connection succeeded")
	end)

	if not success then
		reportError(err)
	end

end)("localhost", REPLACEPORT);
