--[[
堕神养成
--]]
local SimpleCommand = mvc.SimpleCommand
local PetDevelopCommand = class('BattleCommand', SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
--[[
constructor
--]]
function PetDevelopCommand:ctor()
	SimpleCommand.ctor(self)
	self.executed = false
end
--[[
@override
--]]
function PetDevelopCommand:Execute(signal)
	self.executed = true

	local name = signal:GetName()
	local data = signal:GetBody()

	if COMMANDS.COMMANDS_Pet_Develop_Pet_Home == name then

		-- 堕神净化 home
		httpManager:Post('pet/home', SIGNALNAMES.Pet_Develop_Pet_Home_Callback)

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_Pond_Unlock == name then

		-- 解锁净化池
		if data then
			httpManager:Post('pet/petPondUnlock', SIGNALNAMES.Pet_Develop_Pet_Pond_Unlock_Callback, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken == name then

		if data then
			httpManager:Post('pet/petAwaken', SIGNALNAMES.Pet_Develop_Pet_Pet_Awaken, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond == name then

		if data then
			httpManager:Post('pet/petEggIntoPond', SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Into_Pond, data)
		end	

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean == name then

		if data then
			httpManager:Post('pet/petClean', SIGNALNAMES.Pet_Develop_Pet_Pet_Clean, data)
		end
	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean_All == name then

		if data then
			httpManager:Post('pet/petAllClean', SIGNALNAMES.Pet_Develop_Pet_Pet_Clean_All, data)
		end
	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetEggWatering == name then

		if data then
			httpManager:Post('pet/petEggWatering', SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Watering, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_AddMagicFoodPond == name then

		if data then
			httpManager:Post('pet/addMagicFoodPond', SIGNALNAMES.Pet_Develop_Pet_AddMagicFoodPond, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_AcceleratePetClean == name then

		if data then
			httpManager:Post('pet/acceleratePetClean', SIGNALNAMES.Pet_Develop_Pet_Accelerate_Pet_Clean, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetLock == name then

		if data then
			httpManager:Post('pet/petLock', SIGNALNAMES.Pet_Develop_Pet_PetLock, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetUnlock == name then

		if data then
			httpManager:Post('pet/petUnlock', SIGNALNAMES.Pet_Develop_Pet_PetUnlock, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetRelease == name then

		if data then
			httpManager:Post('pet/petRelease', SIGNALNAMES.Pet_Develop_Pet_PetRelease, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetLevelUp == name then

		if data then
			httpManager:Post('pet/petLevelUp', SIGNALNAMES.Pet_Develop_Pet_PetLevelUp, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetBreakUp == name then

		if data then
			httpManager:Post('pet/petBreakUp', SIGNALNAMES.Pet_Develop_Pet_PetBreakUp, data)
		end

	elseif COMMANDS.COMMANDS_Pet_Develop_Pet_PetAttributeReset == name then

		if data then
			httpManager:Post('pet/petAttributeReset', SIGNALNAMES.Pet_Develop_Pet_PetAttributeReset, data)
		end

	end
end




return PetDevelopCommand
