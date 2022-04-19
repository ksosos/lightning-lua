-- PM SYSTEM SERVER --
game.Players.PlayerAdded:Connect(function(plr) -- get the player object from playeradded since we are using a serverscript. we can't access plr.Chatted on localscripts
	plr.Chatted:Connect(function(msg) -- connect the chatted function and get the raw message
		local split = msg:split(" "); -- split the raw message by space
		if split[1]:lower() == "/pm" then -- check if the first index of the split table is equal to /pm, if not then that is not the correct format for sending a pm
			local user = split[2] -- the username is the first argument of this command, and the third is the message
			local player -- create a player variable which we can set later
			local bool = false
			for i,v in pairs(game.Players:GetPlayers()) do -- loop through all players to see if the player in the ocmmand is a valid player
				if v.Name:lower() == user:lower() then
          bool = true -- make a found variable since it would error if we kept going and the player doesn't exist
					player = v
					break
				end
			end
      if not bool then print("invalid player") return end; -- return / exit out the script if there is no player in the second arg
			local message = "" -- final message in a variable since i split it earlier. if i had done split[3] then it would only send one word as a message
			for i = 3, #split, 1 do
				message = message..split[i].." " -- concatenate the message with everything after the third index
			end -- since we know the third index is where the message starts, i set the counting variable as 3 to start there and work my way until the end of the split table, aka #split
      
			game.ReplicatedStorage:WaitForChild("Remotes").SendChat:FireClient(player,plr,message) -- fireclient to the player which was found. this sends the player who sent the message and the message itself
      
		end
	end)
end)
-- PM SYSTEM CLIENT --
game.ReplicatedStorage:WaitForChild("Remotes").SendChat.OnClientEvent:Connect(function(plr,msg) -- connect function once a fireclient is detected with the player who sent it and the mssage as the parameters / args
	game.StarterGui:SetCore("SendNotification", { -- send a notification through the startergui
		Title = "Message from "..plr.Name; -- title = message from Hanad (example)
		Text = msg; --then it shows the text
		Duration = 5; -- it exists for 5 seconds
	})
end)

-- STATS PLAYER SERVER -- 
local DataStoreService = game:GetService("DataStoreService") -- Get services we need.
local playerData = DataStoreService:GetDataStore("StatsTime") -- get our datastore
local Players = game:GetService("Players")

local function Format(Int)
	return string.format("%02i", Int) 
end
local function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end -- two functions to convert seconds into hours minutes and seconds, (not mine, found it on devforum)

local function savePlayerData(playerUserId, plr) -- function to save player data when the player leaves the game
	local success, err = pcall(function() -- we use a protected call or a pcall to catch the error. much like a try catch statement in C#
		playerData:SetAsync(playerUserId, plr.leaderstats.Time.Value) -- we try to execute this piece of code. where we store the userid and the timeplayed value. which is how long you've played for
		print("Saved!")
	end)
	if success then
		print("No errors") -- if it succeeded then we print no errors
	else
		print(err) -- if it didnt succeed then we print the error which is preventing this user from saving their data
	end

end


local function saveOnExit(player) -- second function to make it a bit smaller which has the arg player

	savePlayerData(player.UserId, player) -- we use the function from before to save this users data.

end

local function onPlayerAdded(plr) -- this function is to create the time value.
	local playerUserId = plr.UserId
	local leaderstats = Instance.new("Folder") -- leaderstats folder
	leaderstats.Parent = plr
	leaderstats.Name = 'leaderstats'
	local timee = Instance.new("IntValue") -- number value to store our timevalue
	timee.Parent = leaderstats
	timee.Name = 'Time'
	local data = playerData:GetAsync(playerUserId) -- we fetch our time played data from our data store
	timee.Value = data -- and set the time.value to that data

	repeat -- this increments the time value by one each second, until the player leaves.

		task.wait(1)
		timee.Value += 1
		print(timee.Value)

	until not plr

end
Players.PlayerRemoving:Connect(saveOnExit) -- here we connect the exiting save function
Players.PlayerAdded:Connect(onPlayerAdded) -- here we connect the joining save function

game.Players.PlayerAdded:Connect(function(a)
	a.CharacterAdded:Connect(function()
		a.Chatted:Connect(function(msg)
			if msg:lower() == "/timeplayed" then -- time played command which checks if you've typed the command /timeplayed
				local text = a.PlayerGui:WaitForChild("Timeplayed") -- if you have, then it enables a gui that has the text set to whatever amount of time you played
				text.Enabled = true
				text.Frame.TextLabel.Text = "You have played for "..convertToHMS(a.leaderstats.Time.Value)
				task.wait(2) -- active for two seconds
				text.Enabled = false
			end
		end)
	end)
end)


-- HORSE SPAWNER SERVER -- 
local remote = game.ReplicatedStorage.HorseSpawner -- we get the remote 
local cooldown = 150 -- cooldown which determines when you can spawn the horse
local debounce = false -- db
remote.OnServerEvent:Connect(function(player) -- when the remoteevent is fired
	if not debounce then-- it checks if there is a cooldown
		debounce = true -- if not then the cooldown is started
		local character = player.Character-- we get the player character
		local horse = game.ReplicatedStorage:WaitForChild("Horse")-- we clone the horse object from replicated storage
		local clone = horse:Clone() -- clone the horse and set its CFrame to forward of the humanoid root part CFrame
		clone.Parent = workspace
		clone:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame * CFrame.new(0,0,4))
		wait(cooldown) -- wait the cooldown so you can spawn it again
		debounce = false
	end
	
end)
-- HORSE SPAWNER CLIENT -- 
local tool = script.Parent
local remoteevent = game.ReplicatedStorage:WaitForChild("HorseSpawner")
local player = game.Players.LocalPlayer


tool.Activated:Connect(function(player) -- check if the tool is clicked, if so, fired remotevent
	remoteevent:FireServer()
end)
-- INVISIBILITY POTION CLIENT -- 
local player = game.Players.LocalPlayer -- get the localplayer 
local Remote = script:WaitForChild("Invisibility") -- wait for the remote which is located under the tool
local Tool = script.Parent -- get the tool aswell.
Tool.Activated:Connect(function() -- here we check if the tool is activated / clicked
	Remote:FireServer() -- if so, then we fire the remoteevent
end)
-- INVISIBILITY POTION SERVER -- 

local Invisibility = script.Parent -- get all our essential variables since we also want to play an animation when you drink this potion
local tool = script.Parent.Parent.Parent
local player = tool.Parent.Parent
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator") -- animator object which is whats used to load animations
local Animation = Instance.new("Animation")
Animation.AnimationId = "rbxassetid://6821696911"
Animation.Parent = workspace
local function ghost()
	for _, inst in ipairs(char:GetDescendants()) do -- loop through the characters descendants until we find a basepart / decal. if this is a decal or a basepart aka face, hands etc, then the transparency turns to 0
		if inst.Name ~= "HumanoidRootPart" and (inst:IsA("BasePart") or inst:IsA("Decal")) then
			inst.Transparency = 1
		end
	end
  wait(10) -- wait 10 seconds
  for _, inst in ipairs(char:GetDescendants()) do
		if inst.Name ~= "HumanoidRootPart" and (inst:IsA("BasePart") or inst:IsA("Decal")) then
			inst.Transparency = 0 -- reverse the other part of the script.
		end
	end
end



Invisibility.OnServerEvent:Connect(function(player) -- connect function when the potion was activated
	local anim = animator:LoadAnimation(Animation) -- load the animation of drinking the animation onto the animator
	anim:Play() -- play the animatio n
	wait(1.6)	 -- wait until the animation is completed
	tool:Destroy()-- destroy the potion , as we don't want people to spam it
	ghost() -- use the ghost function.
end)



