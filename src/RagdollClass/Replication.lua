local Replication = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local client
local remoteEvent
local remoteFunction

local Ragdoll = require(script.Parent.Ragdoll)

function Replication.OnFired(enabled: boolean, character: Model, motors: Array | nil, pointOfContact: CFrame | nil, randomness: number)
	local clientCharacter = client.Character
	if not clientCharacter then
		return
	end

	-- We have this check in place, in the case where someone calls :Destroy() or :Disable() when the original character no longer exists and there is a new one.
	if clientCharacter ~= character then
		return
	end

	if enabled then
		Ragdoll.SetupCharacter(character, pointOfContact, randomness)
	else
		Ragdoll.ResetCharacter(character, motors)
	end
	return
end

function Replication.Fire(player: Player, enabled: boolean, character: Model, ...)
	if enabled then
		remoteFunction:InvokeClient(player, enabled, character, ...)
		return Ragdoll.DisableMotors(character)
	else
		remoteEvent:FireClient(player, enabled, character, ...)
	end
end

function Replication:init()
	if RunService:IsServer() then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = "RagdollRemoteEvent"

		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = "RagdollRemoteFunction"

		remoteEvent.Parent = script
		remoteFunction.Parent = script
	else
		client = Players.LocalPlayer

		remoteEvent = script:WaitForChild("RagdollRemoteEvent")
		remoteFunction = script:WaitForChild("RagdollRemoteFunction")

		remoteEvent.OnClientEvent:Connect(self.OnFired)
		remoteFunction.OnClientInvoke = self.OnFired
	end

	return Replication
end


return Replication:init()