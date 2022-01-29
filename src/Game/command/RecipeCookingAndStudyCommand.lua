local SimpleCommand = mvc.SimpleCommand

local RecipeCookingAndStudyCommand = class("RecipeCookingAndStudyCommand", SimpleCommand)
function RecipeCookingAndStudyCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function RecipeCookingAndStudyCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local data  = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMANDS_RecipeCooking_Study_Callback then
		httpManager:Post("Cooking/recipeStudy", SIGNALNAMES.RecipeCooking_Study_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Study_Cancel_Callback then
		httpManager:Post("Cooking/cancelRecipeStudy", SIGNALNAMES.RecipeCooking_Study_Cancel_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Study_Accelertate_Callback then
		httpManager:Post("Cooking/accelerateRecipeStudy", SIGNALNAMES.RecipeCooking_Study_Accelertate_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Study_Draw_Callback then
		httpManager:Post("Cooking/drawRecipeStudy", SIGNALNAMES.RecipeCooking_Study_Draw_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Cooking_Style_Callback then
		httpManager:Post("Cooking/cookingStyleUnlock", SIGNALNAMES.RecipeCooking_Cooking_Style_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Making_Callback then
		httpManager:Post("Cooking/recipeMaking", SIGNALNAMES.RecipeCooking_Making_Callback,data)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_GradeLevelUp_Callback then
		httpManager:Post("Cooking/recipeGradeLevelUp", SIGNALNAMES.RecipeCooking_GradeLevelUp_Callback,data)	
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Home_Callback then
		httpManager:Post("Cooking/home", SIGNALNAMES.RecipeCooking_Home_Callback)
	elseif name == COMMANDS.COMMANDS_RecipeCooking_Magic_Make_Callback then
		httpManager:Post("Cooking/magicRecipeMaking", SIGNALNAMES.RecipeCooking_Magic_Make_Callback ,data)
	end
end

return RecipeCookingAndStudyCommand