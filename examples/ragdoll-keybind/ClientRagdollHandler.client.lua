-- Load the ragdoll class for the client.
-- You are not able to use RagdollClass in client-side, it is server-only.
require(game:GetService("ReplicatedStorage"):WaitForChild("RagdollClass"))

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local toggleRagdoll = ReplicatedStorage:WaitForChild("ToggleRagdoll")

local KEYBIND = Enum.KeyCode.R
local function handleAction(_, userInputState)
	if userInputState == Enum.UserInputState.Begin then
		toggleRagdoll:FireServer()
	end
end

ContextActionService:BindAction("Toggle Ragdoll", handleAction, true, KEYBIND)