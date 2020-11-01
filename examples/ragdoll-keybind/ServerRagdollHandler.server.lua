local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollClass = require(ReplicatedStorage:WaitForChild("RagdollClass"))

local toggleRagdoll = Instance.new("RemoteEvent")
toggleRagdoll.Name = "ToggleRagdoll"
toggleRagdoll.Parent = RagdollClass

local ragdolls = {}
toggleRagdoll.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then
		return
	end
	-- See if the player has a ragdoll, which if so see if it is the same character.
	-- If it is not, they probably respawned, so we destroy the ragdoll class before proceeding to create a new one.
	-- If it is, then it means that they are in the ragdoll state and we destroy the ragdoll and stop the code from continuing.
	local ragdoll = ragdolls[player]
	if ragdoll then
		if ragdoll.Character ~= player.Character then
			ragdoll:Destroy()

			ragdolls[player] = nil
		elseif ragdoll then
			ragdoll:Disable()
			ragdoll:Destroy()

			ragdolls[player] = nil
			return
		end
	end

	-- Create a new ragdoll
	ragdoll = RagdollClass.new(player.Character)
	-- Enable it
	ragdoll:Enable()
end)