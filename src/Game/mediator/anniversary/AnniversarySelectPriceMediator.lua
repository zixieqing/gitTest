--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversarySelectPriceMediator :Mediator
local AnniversarySelectPriceMediator = class("AnniversarySelectPriceMediator", Mediator)
local NAME = "AnniversarySelectPriceMediator"
local anniversaryManager = app.anniversaryMgr
local BUTTON_TAG = {
    ADD_PRICE    = 10011, -- 加钱
    REDUCE_PRICE = 10012, -- 减钱
    CHOOSE_PRICE = 10013, -- 输入钱数
    PUT_AWAY     = 10014, --上菜
    CLOSE_TAG    = 10015, -- 关闭界面
    TIP_BUTTON   = 10016   -- tip 的提示按钮
}
local MAX_SALE_PRICE = 999 -- 最大的售卖价格
--==============================--
---@Description: 
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--
--[[param {
    priceValue =  1 , 售卖价格
    chooseCardId =  11 ， --选择的卡牌id
    recipeId = 1111     -- 选择的菜品id
}
--]]
function AnniversarySelectPriceMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.priceValue = param.priceValue or 0   -- 当前的价格
    self.chooseCardId = param.chooseCardId or 0   -- 选择的卡牌chooseCardId
    self.preIndex = nil
    self.selectIndex = checkint(param.recipeId)  > 0 and  checkint(param.recipeId)  or 1  --选择的序列
    self.startIndex =checkint(param.recipeId)  > 0 and  checkint(param.recipeId)  or 1
    self.startPrice = self.priceValue
    self.recipes =self:GetRecipeData()

end

function AnniversarySelectPriceMediator:InterestSignals()
    local signals = {
    }
    return signals
end

function AnniversarySelectPriceMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
end


function AnniversarySelectPriceMediator:Initial( key )
    self.super.Initial(self, key)
    ---@type AnniversalSelectPrceView
    local viewComponent  = require('Game.views.anniversary.AnniversarySelectPriceView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    local reduceBtn = viewData.reduceBtn
    local addBtn = viewData.addBtn
    local closeView = viewData.closeView
    local putAwayBtn = viewData.putAwayBtn
    local goodInfo = viewData.goodInfo
    local grideVIew = viewData.grideVIew
    local tipButton = viewData.tipButton
    reduceBtn:setTag(BUTTON_TAG.REDUCE_PRICE)
    addBtn:setTag(BUTTON_TAG.ADD_PRICE)
    putAwayBtn:setTag(BUTTON_TAG.PUT_AWAY)
    closeView:setTag(BUTTON_TAG.CLOSE_TAG)
    goodInfo:setTag(BUTTON_TAG.CHOOSE_PRICE)
    tipButton:setTag(BUTTON_TAG.TIP_BUTTON)
    grideVIew:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
    grideVIew:setCountOfCell(table.nums(self.recipes))
    grideVIew:reloadData()
    display.commonUIParams(reduceBtn , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(addBtn , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(closeView , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(putAwayBtn , {cb = handler(self, self.ButtonAction)})
    display.commonUIParams(goodInfo, {cb = handler(self, self.ButtonAction)})
    self:UpdateSelectIndex(self.selectIndex)
    display.commonUIParams(tipButton, {cb = handler(self, self.ButtonAction)})
end
function AnniversarySelectPriceMediator:GetRecipeData()
    local parseConfig = anniversaryManager:GetConfigParse()
    local foodAtrrConfig =  anniversaryManager:GetConfigDataByName(parseConfig.TYPE.FOOD_ATTR)
    local recipes = anniversaryManager.homeData.recipes or {}
    for recipeId  , recipeData in pairs(foodAtrrConfig) do
        if not  recipes[tostring(recipeId)] then
            anniversaryManager:SetRecipeIdAndExp( recipeId , 0 )
        end
    end
    return  anniversaryManager.homeData.recipes
end
--==============================--
---@Description: 获取当前价格的成功率
---@author : xingweihao
---@date : 2018/10/15 9:43 AM
--==============================--
function AnniversarySelectPriceMediator:GetPriceSuccessRate()
    return  anniversaryManager:GetPriceSuccessRate(self.selectIndex , self.priceValue , self.chooseCardId)
end
function AnniversarySelectPriceMediator:OnDataSource(cell, idx )
    local index = idx + 1
    if  not  cell  then
        ---@type AnniversalSelectPrceView
        local viewComponent = self:GetViewComponent()
        cell = viewComponent:CreateGridViewCell()
        display.commonUIParams(cell.viewData.cellLayout , { cb = handler(self, self.CellClick)} )
    end
    local viewData  = cell.viewData
    xTry(function ( )
        if self.selectIndex == index  then
            viewData.lightImage:setVisible(true)
         else
            viewData.lightImage:setVisible(false)
        end
        viewData.cellLayout:setTag(index)
        local level =   anniversaryManager:GetRecipeLevelByExp(checkint(self.recipes[tostring(index)]))
        local gradePath =  app.anniversaryMgr:GetResPath( string.format('ui/home/kitchen/cooking_grade_ico_%d.png' , level))
        viewData.gradeImage:setTexture(gradePath)
        viewData.recipeImage:setTexture(anniversaryManager:GetAnniversaryRecipePathByRecipId(index))
    end, __G__TRACKBACK__)
    return cell
end
function AnniversarySelectPriceMediator:CellClick(sender)
    local tag = sender:getTag()
    self:UpdateSelectIndex(tag)
end
--==============================--
---@Description: 更新选中菜品的界面
---@param index number @菜品的下标元素
---@author : xingweihao
---@date : 2018/10/15 10:00 AM
--==============================--
function AnniversarySelectPriceMediator:UpdateSelectIndex(index)
    index = index or 1
    ---@type AnniversalSelectPrceView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    self.preIndex = self.selectIndex
    self.selectIndex = index
    local preCell = viewData.grideVIew:cellAtIndex(self.preIndex - 1)
    if preCell  then
        preCell.viewData.lightImage:setVisible(false)
    end
    local cell = viewData.grideVIew:cellAtIndex(self.selectIndex - 1)
    if cell  then
        cell.viewData.lightImage:setVisible(true )
    end
    -- 进度条
    local prograss = viewData.prograss
    local recipeName = viewData.recipeName
    local recipeImage = viewData.recipeImage
    local prograssValue = viewData.prograssValue
    local gradeImage = viewData.gradeImage
    local parseConfig =   anniversaryManager:GetConfigParse()
    local foodAttrConfig = anniversaryManager:GetConfigDataByName(parseConfig.TYPE.FOOD_ATTR)
    local foodAttrOneConfig = foodAttrConfig[tostring(index)] or {}
    local name = foodAttrOneConfig.name or ""
    recipeImage:setTexture(anniversaryManager:GetAnniversaryRecipePathByRecipId(index))
    display.commonLabelParams(recipeName , {text = name})
    local expValue = checkint(self.recipes[tostring(index)])
    local level = anniversaryManager:GetRecipeLevelByExp(expValue)
    local limitExp =  anniversaryManager:GetRecipeLevelLimitExp(level)
    gradeImage:setTexture(string.format(app.anniversaryMgr:GetResPath('ui/home/kitchen/cooking_grade_ico_%s.png') ,level ) )
    prograss:setMaxValue(limitExp)
    prograss:setValue( expValue >limitExp and limitExp or expValue  )
    display.commonLabelParams(prograssValue , {text =  expValue  .. "/" .. limitExp})
    self:UpdatePriceLabel()
    if self.startIndex  == index and  checkint(self.startPrice) > 0  then
        self.priceValue = self.startPrice
    else
        self.priceValue = self:GetRecipeRecommendPrice()
    end
    self:UpdateSuccessByPrice(self.priceValue)
end
--==============================--
---@Description: 获取菜谱的推荐价格
---@author : xingweihao
---@date : 2018/10/20 2:17 PM
--==============================--

function AnniversarySelectPriceMediator:GetRecipeRecommendPrice()
    local parserConfig = anniversaryManager:GetConfigParse()
    local recipePriceConfig =anniversaryManager:GetConfigDataByName(parserConfig.TYPE.RECIPE_PRICE)
    local recipeExp = checkint(self.recipes[tostring(self.selectIndex)])
    local keys =  table.keys(recipePriceConfig)
    for i = 1, #keys do
        keys[i] = checkint(keys[i])
    end
    table.sort(keys , function(a, b )
        if a >=  b  then
            return false
        end
        return true
    end)
    if recipeExp < keys[1]  then
        return  57
    end
    for i = 1 , #keys - 1  do
        if recipeExp >= keys[i] and recipeExp < keys[i+1] then
            -- 返回推荐的价格
            return checkint(recipePriceConfig[tostring( keys[i])].price)
        end
    end
    return checkint(recipePriceConfig[tostring( keys[#keys])].price)
end
function AnniversarySelectPriceMediator:ButtonAction(sender)
    local tag = sender:getTag()
    ---@type AnniversalSelectPrceView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    if tag == BUTTON_TAG.CLOSE_TAG  then

        app:UnRegsitMediator(NAME)
    elseif tag ==BUTTON_TAG.REDUCE_PRICE  then
        self.priceValue = self.priceValue - 1
        self:UpdateSuccessByPrice(self.priceValue)
    elseif tag ==BUTTON_TAG.ADD_PRICE  then
        self.priceValue = self.priceValue +1
        self:UpdateSuccessByPrice(self.priceValue)
    elseif tag ==BUTTON_TAG.CHOOSE_PRICE  then -- 输入价格
        app.uiMgr:ShowNumberKeyBoard({
                                         nums 			=  3, 				-- 最大输入位数
                                         model 			= 2, 				-- 输入模式 1为n位密码模式 2为自由模式
                                         callback 		= handler(self, self.NumberKeyBoardCallBack), 						-- 回调函数 确定之后接收输入字符的处理回调
                                         titleText 		=  app.anniversaryMgr:GetPoText(__('请输入价格:')), 					-- 标题
                                         defaultContent =  app.anniversaryMgr:GetPoText(__('输入数字1 - 999')) 				-- 输入框中默认显示的文字
                                     })
    elseif tag ==BUTTON_TAG.PUT_AWAY  then -- 上架
        app:DispatchObservers(ANNIVERSARY_CHOOSE_RECIPE_EVENT ,{ priceValue = self.priceValue , recipeId = self.selectIndex })
        app:UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.TIP_BUTTON  then -- tip 提示
        --app.uiMgr:ShowIntroPopup({moduleId =  -10})
        local parseConfig =   anniversaryManager:GetConfigParse()
        local foodAttrConfig = anniversaryManager:GetConfigDataByName(parseConfig.TYPE.FOOD_ATTR)
        local foodAttrOneConfig = foodAttrConfig[tostring(self.selectIndex)] or {}
        local  str = foodAttrOneConfig.descr
        local day = checkint(foodAttrOneConfig.day)
        if anniversaryManager.homeData.day > day  then
            str = foodAttrOneConfig.unlockDescr or ""
        else
            str = foodAttrOneConfig.lockDescr or ""
        end
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = str, type = 5})
    end
end
--==============================--
---@Description: 键盘输入价格的返回事件
---@author : xingweihao
---@date : 2018/10/15 9:57 AM
--==============================--
function AnniversarySelectPriceMediator:NumberKeyBoardCallBack(data)
    self:UpdateSuccessByPrice(data)
end

function AnniversarySelectPriceMediator:UpdateSuccessByPrice(price)
    local price = checkint(price)
    local  viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    self.priceValue = price
    if self.priceValue > MAX_SALE_PRICE  then
        self.priceValue = MAX_SALE_PRICE
        app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('已超过售价上限')))
        return
    elseif self.priceValue < 1  then
        self.priceValue = 1
        app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('售卖价格不能为0')))
        return
    end
    self:UpdatePriceLabel()
    local successRate = self:GetPriceSuccessRate()
    display.commonLabelParams(viewData.successRateNumLabel ,{text = successRate .. "%" })
end
function AnniversarySelectPriceMediator:UpdatePriceLabel()
    ---@type AnniversalSelectPrceView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    display.reloadRichLabel(viewData.richLabel , {c= {
        fontWithColor(14,{ text =  self.priceValue , color =  '#d23d3d'}) ,
        {img = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetIncomeCurrencyID()) , scale = 0.2  }
    }})
end
function AnniversarySelectPriceMediator:OnRegist()
end
function AnniversarySelectPriceMediator:OnUnRegist()
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AnniversarySelectPriceMediator
