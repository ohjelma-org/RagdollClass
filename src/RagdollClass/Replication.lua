local Replication = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local client
local remoteEvent

local Ragdoll = require(script.Parent.Ragdoll)

function Replication.OnClientEvent(enabled: boolean, character: Model, motors: Array, pointOfContact: CFrame)
	local clientCharacter = client.Character
	if not clientCharacter then
		return
	end

	-- We have this check in place, in the case where someone calls :Destroy() or :Disable() when the original character no longer exists and there is a new one.
	if clientCharacter ~= character then
		return
	end

	if enabled then
		Ragdoll.SetupCharacter(character, motors, pointOfContact)
	else
		Ragdoll.ResetCharacter(character)
	end
end

function Replication.Fire(player: Player, ...)
	remoteEvent:FireClient(player, ...)
end

function Replication:init()
	if RunService:IsServer() then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = "RagdollRemoteEvent"
		remoteEvent.Parent = script
	else
		client = Players.LocalPlayer
		remoteEvent = script:WaitForChild("RagdollRemoteEvent")
		remoteEvent.OnClientEvent:Connect(self.OnClientEvent)
	end

	return Replication
end


return Replication:init()