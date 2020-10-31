--[[
	Author: guidable
	License:
	Source:
--]]

local RagdollClass = {}
RagdollClass.__index = RagdollClass

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Ragdoll = require(script.Ragdoll)
local Replication = require(script.Replication)
local Maid = require(script.Maid)

-- @@ Class Constructors
function RagdollClass.new(character: Model)
	assert(RunService:IsServer(), "RagdollClass can only be used from the server")
	local self = setmetatable({
		character = character,
		humanoidRootPart = nil,
		humanoid = nil,
		maid = Maid.new(),
	}, RagdollClass)
	self:setup()
	return self
end

-- @@ Private Methods
function RagdollClass:setup()
	local humanoidRootPart = self.character:FindFirstChild("HumanoidRootPart")
	local humanoid = self.character:FindFirstChildWhichIsA("Humanoid")

	assert(humanoidRootPart, "character does not have a HumanoidRootPart")
	assert(humanoid, "character does not have a Humanoid")

	self.humanoidRootPart = humanoidRootPart
	self.humanoid = humanoid
end

-- @@ Public Methods
function RagdollClass:Start(pointOfContact: Vector3)
	local player = Players
	self.maid.ragdollFolder = Ragdoll.createRagdollConstraints(self.character, self.humanoid.RigType)
	local motors = Ragdoll.disableMotors(self.character)

	self.maid:GiveTask(function()
		Ragdoll.enableMotors(motors)	
	end)
end

function RagdollClass:Stop()

end

-- @@ Class Destructors
function RagdollClass:Destroy()

end

return RagdollClass