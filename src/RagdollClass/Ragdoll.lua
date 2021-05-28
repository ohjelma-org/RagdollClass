--[[
	Author: guidable
	License: https://github.com/ohjelma-org/RagdollClass/blob/main/LICENSE.md
	Source: https://github.com/ohjelma-org/RagdollClass/blob/main/src/RagdollClass/Ragdoll.lua
--]]
local Ragdoll = {}

local RunService = game:GetService("RunService")

local RAGDOLL_SETTINGS = {
	[Enum.HumanoidRigType.R15] = {},

	[Enum.HumanoidRigType.R6] = {
		["Head"] = {
			["Attachments"] = {
				["Neck"] = {
					Position = Vector3.new(0, -0.5, 0),
					Parent = "",
					OffsetSideAttachment = false,
				},
			},

			["ConstraintSettings"] = {
				["Neck"] = {
					Attachment1 = "Torso>Neck",

					LimitsEnabled = true,
					UpperAngle = 45,

					TwistLimitsEnabled = true,
					TwistLowerAngle = -40,
					TwistUpperAngle = 70,
				},
			},
		},

		["Torso"] = {
			["Attachments"] = {
				["Shoulder"] = {
					Position = Vector3.new(1, 0.95, 0),
					Parent = "",
					OffsetSideAttachment = true,
				},

				["Hip"] = {
					Position = Vector3.new(0.5, -1, 0),
					Parent = "",
					OffsetSideAttachment = true,
				},

				["Neck"] = {
					Position = Vector3.new(0, 1, 0),
					Parent = "",
					OffsetSideAttachment = false,
				},
			},
		},

		["Arm"] = {
			["Attachments"] = {
				["Shoulder"] = {
					Position = Vector3.new(-0.5, 0.95, 0),
					-- If the parent string is empty, it'll just be the current parent in interation.
					-- This setting mainly exists for R15!
					Parent = "",
					OffsetSideAttachment = true,
				},
			},

			["ConstraintSettings"] = {
				["Shoulder"] = {
					Attachment1 = "Torso>Shoulder",

					LimitsEnabled = true,
					UpperAngle = 160,

					TwistLimitsEnabled = true,
					TwistLowerAngle = -120,
					TwistUpperAngle = 160,
				}
			},
		},

		["Leg"] = {
			["Attachments"] = {
				["Hip"] = {
					Position = Vector3.new(0, 1, 0),
					Parent = "",
					OffsetSideAttachment = true,
				},
			},

			["ConstraintSettings"] = {
				["Hip"] = {
					Attachment1 = "Torso>Hip",

					LimitsEnabled = true,
					UpperAngle = 160,

					TwistLimitsEnabled = true,
					TwistLowerAngle = -110,
					TwistUpperAngle = 90,
				}
			},
		},
	},
}

local function getLastWordFromPascalCase(text: string)
	text = text:reverse()

	local wordStart = text:find("[%u]")
	local word = text:sub(1, wordStart):reverse()

	word = word:gsub("%d+$", "")
	return word
end

local function getFirstWordFromPascalCase(text: string)
	-- this is quite scuffed, atleast I guidable, think so.
	local wordStart, wordEnd = text:find("[%u]+[%U]+")
	local word = text:sub(wordStart, wordEnd)

	word = word:gsub("[%d%s]+$", "")
	return word
end

local function getSideFromName(text: string)
	local wordRightStart, wordRightEnd = text:find("Right")
	local wordLeftStart, wordLeftEnd = text:find("Left")

	if not wordRightStart and not wordLeftStart then
		return ""
	end

	if wordRightStart and not wordLeftStart then
		return text:sub(wordRightStart, wordRightEnd)
	elseif wordLeftStart and not wordRightStart then
		return text:sub(wordLeftStart, wordLeftEnd)
	end

	if wordRightStart < wordLeftStart then
		return text:sub(wordRightStart, wordRightEnd)
	else
		return text:sub(wordLeftStart, wordLeftEnd)
	end
end

local function delay(length: number, callback: Function)
	local start = time()

	local Connection
	Connection = RunService.Heartbeat:Connect(function()
		if length <= (time() - start) then
			Connection:Disconnect()
			Connection = nil

			callback()
		end
	end)
	return Connection
end

local function getRandomVelocityNumber(random: Random, maxVelocity: number)
	return random:NextNumber(maxVelocity / 3, maxVelocity) * (random:NextInteger(0, 1) == 0 and -1 or 1)
end

function Ragdoll.SetupCharacter(character: Model, pointOfContact: CFrame | nil, randomness: number)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local motors = Ragdoll.DisableMotors(character)

	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if animator then
		animator:ApplyJointVelocities(motors)
	end

	for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
		-- I'm using a thousandth of the second instead of 0 because there's a bug where if it is 0 it freezes poses?
		-- Read the developer hub for more information: https://developer.roblox.com/en-us/api-reference/function/AnimationTrack/Stop
		animationTrack:Stop(0.001)
	end

	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("LowerTorso")
	if not humanoidRootPart then
		return
	end

	-- Reduce the friction of the limbs that are in contact with the ground, as otherwise there's a somewhat big chance the character is gonna stay standing up.
	local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightFoot")
	local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftFoot")
	if rightLeg then
		local currentPhysicalProperties = PhysicalProperties.new(rightLeg.Material)
		rightLeg.CustomPhysicalProperties = PhysicalProperties.new(
			currentPhysicalProperties.Density,
			0,
			currentPhysicalProperties.Elasticity,
			100,
			currentPhysicalProperties.ElasticityWeight
		)
	end

	if leftLeg then
		local currentPhysicalProperties = PhysicalProperties.new(leftLeg.Material)
		leftLeg.CustomPhysicalProperties = PhysicalProperties.new(
			currentPhysicalProperties.Density,
			0,
			currentPhysicalProperties.Elasticity,
			100,
			currentPhysicalProperties.ElasticityWeight
		)
	end

	if pointOfContact and torso then
		local position = pointOfContact.Position
		local closestLimb
		local closestLimbDistance

		for _, bodyPart in pairs(character:GetChildren()) do
			if humanoid:GetLimb(bodyPart) == Enum.Limb.Unknown then
				continue
			end

			local distance = (bodyPart.Position - position).Magnitude
			if closestLimb then
				if distance < closestLimbDistance then
					closestLimb = bodyPart
					closestLimbDistance = distance
				end
			else
				closestLimb = bodyPart
				closestLimbDistance = distance
			end
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "PointOfContact"
		attachment.CFrame = closestLimb.CFrame:ToObjectSpace(pointOfContact)

		local vectorForce = Instance.new("VectorForce")
		vectorForce.Name = "PointOfContactForce"

		vectorForce.ApplyAtCenterOfMass = false
		vectorForce.Force = Vector3.new(0, 0, -1) * 22
		vectorForce.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		vectorForce.Attachment0 = attachment

		vectorForce.Parent = closestLimb
		attachment.Parent = closestLimb
		delay(0.1, function()
			attachment:Destroy()
			vectorForce:Destroy()
		end)
	else
		local walkSpeed = humanoid.WalkSpeed
		local seed = os.clock() * 1000
		local random = Random.new(seed)
		for _, bodyPart in pairs(character:GetChildren()) do
			if humanoid:GetLimb(bodyPart) == Enum.Limb.Unknown then
				continue
			end

			local localRandomVelocity = Vector3.new(
				getRandomVelocityNumber(random, walkSpeed * randomness),
				getRandomVelocityNumber(random, walkSpeed * (randomness / 4)),
				getRandomVelocityNumber(random, walkSpeed * randomness)
			)
			local worldRandomVelocity = humanoidRootPart.CFrame:VectorToWorldSpace(localRandomVelocity)
			local velocity = bodyPart.Velocity

			bodyPart.Velocity = velocity + (worldRandomVelocity - velocity)
		end
	end
	return motors
end

function Ragdoll.ResetCharacter(character: Model, motors: Array)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	Ragdoll.EnableMotors(motors)

	humanoid.AutoRotate = true
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightFoot")
	local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftFoot")
	if rightLeg then
		rightLeg.CustomPhysicalProperties = PhysicalProperties.new(rightLeg.Material)
	end

	if leftLeg then
		leftLeg.CustomPhysicalProperties = PhysicalProperties.new(leftLeg.Material)
	end
end

function Ragdoll.CreateRagdollConstraints(character: Model, humanoid: Humanoid)
	local constraintsFolder = Instance.new("Folder")
	constraintsFolder.Name = "RagdollConstraints"

	local rigSettings = RAGDOLL_SETTINGS[humanoid.RigType]

	local ragdollAttachments = {}
	for _, bodyPart in pairs(character:GetChildren()) do
		if humanoid:GetLimb(bodyPart) == Enum.Limb.Unknown then
			continue
		end

		local limbType = getLastWordFromPascalCase(bodyPart.Name)
		local limbSide = getSideFromName(bodyPart.Name)
		local firstWord = getFirstWordFromPascalCase(bodyPart.Name)

		local limbSettings = rigSettings[limbType]
		local limbAttachments = limbSettings["Attachments"]
		for attachmentName, attachmentSettings in pairs(limbAttachments) do
			local position = attachmentSettings.Position
			local parentFirstWord = attachmentSettings.Parent
			local offsetSideAttachment = attachmentSettings.OffsetSideAttachment

			if firstWord ~= "" and firstWord ~= bodyPart.Name and firstWord ~= limbSide and parentFirstWord ~= firstWord then
				continue
			end

			if limbSide == "" and offsetSideAttachment then
				-- i define both positions for the sake of readability
				local rightPosition = position
				local leftPosition = position * Vector3.new(-1, 1, 1)

				local rightAttachment = Instance.new("Attachment")
				rightAttachment.Name = "Right" .. limbType .. attachmentName .. "Attachment"
				rightAttachment.Position = rightPosition
				rightAttachment.Parent = bodyPart

				local leftAttachment = Instance.new("Attachment")
				leftAttachment.Name = "Left" .. limbType .. attachmentName .. "Attachment"
				leftAttachment.Position = leftPosition
				leftAttachment.Parent = bodyPart

				ragdollAttachments["Right" .. ">" .. limbType .. ">" .. attachmentName] = rightAttachment
				ragdollAttachments["Left" .. ">" .. limbType .. ">" .. attachmentName] = leftAttachment
			elseif limbSide ~= "" and offsetSideAttachment then
				local sideOffset = Vector3.new((limbSide == "Right" and 1) or (limbSide == "Left" and -1) or 1, 1, 1)
				position = position * sideOffset

				local attachment = Instance.new("Attachment")
				attachment.Name = limbSide .. limbType .. attachmentName .. "Attachment"
				attachment.Position = position
				attachment.Parent = bodyPart

				ragdollAttachments[limbSide .. ">" .. limbType .. ">" .. attachmentName] = attachment
			elseif not offsetSideAttachment then
				local attachment = Instance.new("Attachment")
				attachment.Name = limbSide .. limbType .. attachmentName .. "Attachment"
				attachment.Position = position
				attachment.Parent = bodyPart

				ragdollAttachments[limbType .. ">" .. attachmentName] = attachment
			end
		end
	end

	for limbName, limbSettings in pairs(rigSettings) do
		local limbConstraintSettings = limbSettings["ConstraintSettings"]
		if not limbConstraintSettings then
			continue
		end

		for attachment0Name, constraintSettings in pairs(limbConstraintSettings) do
			local attachment1Name = constraintSettings.Attachment1
			attachment0Name = limbName .. ">" .. attachment0Name

			local attachment0, attachment1 = ragdollAttachments[attachment0Name], ragdollAttachments[attachment1Name]
			local rightAttachment0, rightAttachment1 = ragdollAttachments["Right>" .. attachment0Name], ragdollAttachments["Right>" .. attachment1Name]
			local leftAttachment0, leftAttachment1 = ragdollAttachments["Left>" .. attachment0Name], ragdollAttachments["Left>" .. attachment1Name]
			if rightAttachment0 and leftAttachment0 then
				local rightBallSocketConstraint = Instance.new("BallSocketConstraint")
				rightBallSocketConstraint.Attachment0 = rightAttachment0
				rightBallSocketConstraint.Attachment1 = rightAttachment1
				rightBallSocketConstraint.Enabled = true
				rightBallSocketConstraint.Parent = constraintsFolder

				local leftBallSocketConstraint = Instance.new("BallSocketConstraint")
				leftBallSocketConstraint.Attachment0 = leftAttachment0
				leftBallSocketConstraint.Attachment1 = leftAttachment1
				leftBallSocketConstraint.Enabled = true

				for property, value in pairs(constraintSettings) do
					if property == "Attachment0" or property == "Attachment1" then
						continue
					end
					rightBallSocketConstraint[property] = value
				end

				for property, value in pairs(constraintSettings) do
					if property == "Attachment0" or property == "Attachment1" then
						continue
					end
					leftBallSocketConstraint[property] = value
				end

				leftBallSocketConstraint.Parent = constraintsFolder
			else
				local ballSocketConstraint = Instance.new("BallSocketConstraint")
				ballSocketConstraint.Attachment0 = attachment0
				ballSocketConstraint.Attachment1 = attachment1
				ballSocketConstraint.Enabled = true

				for property, value in pairs(constraintSettings) do
					if property == "Attachment0" or property == "Attachment1" then
						continue
					end
					ballSocketConstraint[property] = value
				end

				ballSocketConstraint.Parent = constraintsFolder
			end
		end
	end

	constraintsFolder.Parent = character
	return constraintsFolder
end

function Ragdoll.RemoveRagdollConstraints(folder: Folder)
	for _, constraint in pairs(folder:GetChildren()) do
		local attachment0 = constraint.Attachment0
		local attachment1 = constraint.Attachment1

		if attachment0 then
			attachment0:Destroy()
		end

		if attachment1 then
			attachment1:Destroy()
		end
	end

	folder:Destroy()
end

function Ragdoll.EnableMotors(motors: array)
	for _, motor in pairs(motors) do
		motor.Enabled = true
	end
end

function Ragdoll.DisableMotors(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local motors = {}
	for _, motor in pairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part0 ~= humanoidRootPart then
			motor.Enabled = false
			table.insert(motors, motor)
		end
	end
	return motors
end

return Ragdoll
