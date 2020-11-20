--[[
	Author: guidable
	License: https://github.com/ohjelma-org/RagdollClass/blob/main/LICENSE.md
	Source: https://github.com/ohjelma-org/RagdollClass/blob/main/src/RagdollClass/init.lua
--]]

local RagdollClass = {}
RagdollClass.__index = RagdollClass

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Ragdoll = require(script.Ragdoll)
local Replication = require(script.Replication)
local Maid = require(script.Maid)

-- @@ Class Constructors
function RagdollClass.new(character: Model, randomness: number)
	assert(RunService:IsServer(), "RagdollClass can only be used from the server")
	local self = setmetatable({
		-- @@ Public Members
		Enabled = false, -- read only
		Character = character, -- read only

		-- @@ Private Members
		humanoidRootPart = nil,
		humanoid = nil,

		randomness = randomness or 0.5,
		maid = Maid.new(),
	}, RagdollClass)
	self:setup()
	return self
end

-- @@ Private Methods
function RagdollClass:setup()
	local humanoidRootPart = self.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = self.Character:FindFirstChildWhichIsA("Humanoid")

	assert(humanoidRootPart, "character does not have a HumanoidRootPart")
	assert(humanoid, "character does not have a Humanoid")

	self.player = Players:GetPlayerFromCharacter(self.Character)
	self.humanoidRootPart = humanoidRootPart
	self.humanoid = humanoid
end

-- @@ Public Methods
function RagdollClass:Enable(pointOfContact: CFrame)
	assert(not self.Enabled, "ragdoll is already enabled")
	self.Enabled = true

	local player = self.player
	local character = self.Character
	local humanoidRootPart = self.humanoidRootPart
	local humanoid = self.humanoid
	local randomness = self.randomness

	assert(humanoidRootPart:CanSetNetworkOwnership(), "must be able to set HumanoidRootPart network ownership auto")
	local requiresNeck = humanoid.RequiresNeck
	humanoid.RequiresNeck = false

	local ragdollConstraints = Ragdoll.CreateRagdollConstraints(character, humanoid)
	local motors

	local networkOwner = humanoidRootPart:GetNetworkOwner()
	local networkOwnershipAuto = humanoidRootPart:GetNetworkOwnershipAuto()
	if player then
		humanoidRootPart:SetNetworkOwner(player)
		motors = Replication.Fire(player, true, character, nil, pointOfContact, randomness)
	else
		humanoidRootPart:SetNetworkOwner(nil)
		motors = Ragdoll.SetupCharacter(character, pointOfContact, randomness)
	end

	self.maid:GiveTask(function()
		Ragdoll.RemoveRagdollConstraints(ragdollConstraints)
		Ragdoll.EnableMotors(motors)
		if player then
			Replication.Fire(player, false, character, motors)
		else
			Ragdoll.ResetCharacter(character, motors)
		end

		if humanoidRootPart:CanSetNetworkOwnership() then
			humanoidRootPart:SetNetworkOwner(networkOwner)
			if networkOwnershipAuto then
				humanoidRootPart:SetNetworkOwnershipAuto()
			end
		end
		humanoid.RequiresNeck = requiresNeck
	end)
end

function RagdollClass:Disable()
	assert(self.Enabled, "ragdoll is not enabled")
	self.Enabled = false
	self.maid:Destroy()
end

-- @@ Class Destructors
function RagdollClass:Destroy()
	self.maid:Destroy()

	self.player = nil
	self.Character = nil
	self.humanoidRootPart = nil
	self.humanoid = nil
end

return RagdollClass