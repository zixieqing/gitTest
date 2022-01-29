local Mediator = mvc.Mediator
local NAME = "RecipeReminderMediator"
---@class RecipeReminderMediator:Mediator
local RecipeReminderMediator = class(NAME, Mediator)
local uiMagr = app.uiMgr
local gameMgr = app.gameMgr
local BTN_COLLECT = {
    IMPROVED_RECIPE = 1001, --改进按钮
    RESEARCH = 1002, --研究按钮
    SPECIALIZATION = 1003, --专精按钮
    MAGIC_STYLE = 4
}
function RecipeReminderMediator:ctor(params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    local params = params or {}
    self.datas = params
    self.styleType = params.styleType or 2 --这个表示菜系的风格
    self.selectIndex = 1
    self:SetStyleData()
    self:SetRecipeData()
end

function RecipeReminderMediator:InterestSignals()
    local signals = {
        "REFRESH_RECIPE_DETAIL",
    }

    return signals
end


function RecipeReminderMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name == "REFRESH_RECIPE_DETAIL" then
        local recipeNew = body.recipeNew
        local recipeNewStyle = body.recipeNewStyle
        local selectCookingStyleId = body.recipeType
        -- 产生新菜品的时候 重新处理数据
        if  recipeNewStyle then
            self.styleType = checkint(selectCookingStyleId)
            self:SetStyleData()
            self:SetRecipeData()
            self:UpdateUI()
        elseif recipeNew then
            self:SetStyleData()
            self:SetRecipeData()
            self:UpdateUI()
        end
    end
end

function RecipeReminderMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type RecipeReminderView
    local viewComponent = require('Game.views.RecipeReminderView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    local parentLayer = self.datas.layer
    parentLayer:addChild(viewComponent)
    self:UpdateUI()
end

function RecipeReminderMediator:SetStyleData()
    local styleData = gameMgr:GetUserInfo().cookingStyles[tostring(self.styleType)] or {} -- 该菜谱的数据
    self.styleData = {}
    for index , recipeData in pairs(styleData) do
        self.styleData[tostring(recipeData.recipeId)] = recipeData.recipeId
    end
end
function RecipeReminderMediator:GetStyleData()
    return self.styleData
end
function RecipeReminderMediator:UpdateUI()

    local recipeData = self:GetRecipeData()
    local recipeId =recipeData[self.selectIndex]
    local viewComponent = self:GetViewComponent()
    local styleData = self:GetStyleData()
    local isOwner = styleData[tostring(recipeData[self.selectIndex])] and true or false
    local viewData = viewComponent.viewData
    local count = table.nums(recipeData)
    viewData.gridView:setCountOfCell(count)
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    viewData.gridView:reloadData()
    local data = {
        preIndex = self.selectIndex  ,
        index = self.selectIndex ,
        recipeId = recipeId ,
        isOwner = isOwner
    }
    viewComponent:UpdateUI(data)
    local styleInfo = {
        styleId = self.styleType ,
        ownerNum =  table.nums(styleData)
    }
    viewComponent:UpdateStyleRecipeInfo(styleInfo)
end
--==============================--
---@Description: 获取当前菜系的所有菜谱
---@author : xingweihao
---@date : 2019/1/23 9:28 PM
--==============================--

function RecipeReminderMediator:SetRecipeData()
    self.allRecipes = {}
    local recipeStudyFormulaConfig  = CommonUtils.GetConfigAllMess('recipeStudyFormula', 'cooking')
    local recipeOneStudyConfig =recipeStudyFormulaConfig[tostring(self.styleType)]
    local count = 0
    if recipeOneStudyConfig  then
        for formula, recipeId in pairs(recipeOneStudyConfig) do
            count = count +1
            self.allRecipes[count] =  tostring(recipeId)
        end
    end

    if count > 0  then
        local styleData = self:GetStyleData()
        table.sort(self.allRecipes , function(aRecipeId , bRecipeId)
            local aIndex = 1
            local bIndex = 1
            aIndex = styleData[ aRecipeId] and 1 or 2
            bIndex = styleData[ bRecipeId] and 1 or 2
            if aIndex == bIndex then
                if aRecipeId > bRecipeId then
                    return false
                else
                    return true
                end
            elseif aIndex > bIndex then
                return false
            else
                return true
            end
        end)
    end
end
function RecipeReminderMediator:GetRecipeData()
    return self.allRecipes
end


function RecipeReminderMediator:OnDataSource(cell , idx )
    local index = idx +1
    local cellSize = cc.size(125,125)
    local recipeData = self:GetRecipeData()
    if not  cell  then
        cell = CGridViewCell:new()
        cell:setContentSize(cellSize)
        ---@type RecipeReminderView
        local viewComponent = self:GetViewComponent()
        local goodLayout =  viewComponent:CreatRecipeNode()
        goodLayout:setPosition(cellSize.width/2 , cellSize.height/2)
        cell:addChild(goodLayout)
        goodLayout:setName("goodLayout")
    end
    xTry(function ()
        ---@type RecipeReminderView
        local viewComponent = self:GetViewComponent()
        local styleData = self:GetStyleData()
        -- 判断是否拥有该菜谱
        local isOwner = styleData[tostring(recipeData[index])] and true or false
        local data = {
            cell = cell ,
            index = index ,
            recipeId = recipeData[index],
            callback = handler(self, self.CellButtonClick) ,
            isOwner = isOwner
        }
        viewComponent:UpdateRecipeNode(data)
    end,__G__TRACKBACK__)
    return cell
end
function RecipeReminderMediator:CellButtonClick(sender)
    local index = sender:getTag()
    local recipeData = self:GetRecipeData()
    local recipeId =recipeData[index]
    local viewComponent = self:GetViewComponent()
    local styleData = self:GetStyleData()
    local isOwner = styleData[tostring(recipeData[index])] and true or false
    local data = {
        preIndex = self.selectIndex ,
        index = index ,
        recipeId = recipeId ,
        isOwner = isOwner
    }
    viewComponent:UpdateUI(data)
    self.selectIndex = index

end

function RecipeReminderMediator:OnRegist()

end

function RecipeReminderMediator:OnUnRegist()
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end
-- regist/unRegist
-----------------------------------
---
return RecipeReminderMediator
