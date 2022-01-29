---@type Mediator
local Mediator = mvc.Mediator
---@class RecipeDetailMediator : Mediator
local RecipeDetailMediator = class("RecipeDetailMediator", Mediator)
local NAME = "RecipeDetailMediator"
local BTNCOLLECT_TAG = {
    ADDTIP_TEST = 1  ,
    ADDTIP_MUSEFEEL = 2 ,
    ADDTIP_FRAGRABCE = 3,
    ADDTIP_EXTERIOR = 4 , 
    ADDTIP_TOTAL   =  5 ,
    MAKE_BTN = 1001 ,
    ADDSEASONING_BTN = 1002,
    READY_LEVEL_UP = 1003 ,
    MAKE_BTN_TIMES = 1004 , -- 多次制作按钮
    CUSTOM_BTN        = 1007,
    UPGRADE_CANACEL = 1101,
    UPGRADE_LEVEL = 1102 ,
    USER_SEASONING = 1103 ,
    UNCOMMON_SEASONING = 1104 ,
    COMMON_SEASONING = 1105,

    LOBBY_FESTIVAL_TIP = 2000,
}
local MAGIC_FOOD_STYLE = 2
local UNMAGIC_FOOD_STYLE = 1
local RECIPE_UPGRADE_COMPLETE  = 3 -- 升级动画展示
local EXTERNAL_REFRESH = 1
local CONTENT_REFRESH = 2

local nodeExist = function (node)
    return node and not tolua.isnull(node)
end

---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local BackpackCell = require('home.BackpackCell')
function RecipeDetailMediator:ctor( param ,viewComponent )
	self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.type = param.type or 1   -- type 的类型 主要是界面的显示是单页面调出 还是混合调出
    self.seasoningType = 1 -- 1、为普通 2、为精致
    self.datas = param
    self.seasoning  = {}
    self.RecipeBackPackView =  nil -- 菜谱背包界面
    self.UpGradeRecipeLevelView =  nil  -- 菜谱升级界面
    self.makeSureSeasoningId = nil 
    self.currentSeasoningId  = nil  
    self.preSeasoningCell = nil  
    self.commonSeasoning =  {} -- 普通调料
    self.unCommonSeasoning = {} -- 精致调料
    self.currentSeasoningData = {} -- 当前的类别是精致调料还是普通调料
    self.preRecipeBackPackIndex = nil  -- 记录当前点击的index 
    self.preSelectBtn = nil
    self.makeCountNum = 0  -- 制作菜系的数量
    self.RewardResearchAndMakeView = nil 
    self.recipeCookingEffect = CommonUtils.GetConfigAllMess('recipeSeasoningEffect','cooking') 
    self.growthTable = CommonUtils.GetConfigAllMess('growth','cooking') 
    self.seasoningTable = CommonUtils.GetConfigAllMess('seasoning','goods') 
end

function RecipeDetailMediator:InterestSignals()
	local signals = { 
		SIGNALNAMES.RecipeCooking_Making_Callback,
        SIGNALNAMES.RecipeCooking_GradeLevelUp_Callback,
        SIGNALNAMES.RecipeCooking_Magic_Make_Callback,

        -- 餐厅活动相关
        LOBBY_FESTIVAL_ACTIVITY_END,
        POST.Activity_Draw_restaurant.sglName,
	}
	return signals
end
function RecipeDetailMediator:ProcessSignal( signal )
	local name = signal:GetName()
    
    if name == SIGNALNAMES.RecipeCooking_Making_Callback then
        local bodyData =  checktable(signal:GetBody())
        local rewards  =  bodyData.rewards or {}
        local addExp =  checkint(bodyData.mainExp)  - gameMgr:GetUserInfo().mainExp
        table.insert(rewards, #rewards+1 ,{goodsId = EXP_ID, num = addExp } )
        local delayFuncList_ =  CommonUtils.DrawRewards( rewards , true ) --增加经验和物品
        local addPropertyTable = { 'taste' , 'museFeel' , 'fragrance','exterior'}
        local count  = 0
        local lastGrowthTotal =  self.datas.growthTotal
        for k , v in pairs(addPropertyTable) do
            self.datas[v] = checkint( bodyData.attrFinal[v])
            count = self.datas[v] + count
        end
        self.datas.growthTotal = count
        local gradeData = CommonUtils.GetConfigAllMess('grade', 'cooking')
        local cookingStyle  = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(self.datas.recipeId)].cookingStyleId

        local count = table.nums(gradeData)
        if count > checkint(self.datas.gradeId)  then   -- 判断是否满级
            local sum = gradeData[tostring(self.datas.gradeId+1)].sum
            if  checkint(sum )<= checkint(self.datas.growthTotal) then
                -- 添加升级红点坐标
                app.badgeMgr:AddUpgradeRecipeLevelAndNewRed(self.datas.recipeId,cookingStyle )
                self:GetFacade():DispatchObservers("REFRESH_RECIPE_DETAIL", { recipeType  = checkint(cookingStyle) , recipeFull = true , recipeLevelIsAdd = false ,  recipeNew = false  , recipeId =  self.datas.recipeId})
            else
                -- 当不满足升级的时候清除红点 这个地方调用是防止其他地方单独调起做菜界面没有刷新红点
                app.badgeMgr:ClearUpgradeRecipeLevelAndNewRed(self.datas.recipeId,cookingStyle )
            end
        end
        local datasClones = clone(self.datas)
        datasClones.makeSureSeasoningId = self.makeSureSeasoningId
        local consumeData = clone(self:GetViewComponent().recipeData[tostring(self.datas.recipeId)].make) 
        if self.makeSureSeasoningId then
            self.datas.seasoning = (self.datas.seasoning or "") .. "," .. (self.makeSureSeasoningId - 230000)
        end
        local countNum =  #bodyData.attrAddition
        local needData = {}
        for k , v in pairs(consumeData) do 
            needData[#needData+1] = {}
            needData[#needData].num  = - (checkint(v) *countNum)
            needData[#needData].goodsId  =  k
        end
        
        if  self.makeSureSeasoningId then
            local seasoning = {}
            seasoning.num = 0 - countNum
            seasoning.goodsId = self.makeSureSeasoningId
            needData[#needData+1] = seasoning
           if self.preRecipeBackPackIndex then 
                local data = self.currentSeasoningData[self.preRecipeBackPackIndex] 
                if data.amount <= countNum  then --如果等于制作的份数 删除id 和图
                    self.preRecipeBackPackIndex = nil  
                    self.makeSureSeasoningId = nil 
                end 
           end
        end
        CommonUtils.DrawRewards(needData)
        datasClones.type = UNMAGIC_FOOD_STYLE
        datasClones.lastGrowthTotal = lastGrowthTotal
        datasClones.Exp = addExp
        datasClones.rewards = bodyData.rewards
        local collect ={
            taste = {
                base =  0 ,
                assistant =  0,
                seasoning =  0
            } ,
            museFeel = {
                base =  0 ,
                assistant =  0,
                seasoning =  0
            } ,
            fragrance = {
                base =  0 ,
                assistant =  0,
                seasoning =  0
            } ,
            exterior = {
                base =  0 ,
                assistant =  0,
                seasoning =  0
            }
        }
        --- 构造已经有的数组

        for j =1 , #bodyData.attrAddition do  --  遍历数组
            for k , v in pairs(bodyData.attrAddition[j]) do
                for kk , vv in pairs(v) do
                    -- 每个数组中的相同属性相加
                    collect[k][kk] = collect[k][kk] + checkint(vv)
                end
            end
        end
        for i =1 , #addPropertyTable do
            datasClones[addPropertyTable[i].."Map"] = collect[addPropertyTable[i]]
        end
        local initial = CommonUtils.GetConfigAllMess('style','cooking')[tostring(self:GetViewComponent().recipeData[tostring(self.datas.recipeId)].cookingStyleId)].initial
        if checkint(initial) ~= MAGIC_FOOD_STYLE then
            self.RewardResearchAndMakeView:setVisible(true)
            self.RewardResearchAndMakeView:updateData(datasClones, delayFuncList_)
        end
        self.viewData.seasoningIcon:setVisible(true)
        
        if self.lobbyFestivalTipView ~= nil then
            local lobbyFestivalMenuData = app.activityMgr:getLobbyFestivalMenuData(self.datas.recipeId)
            local lobbyFestivalTipVisible = app.activityMgr:isOpenLobbyFestivalActivity() and lobbyFestivalMenuData ~= nil
            if lobbyFestivalTipVisible then
                self:UpdateLobbyFestivalTipUi(lobbyFestivalMenuData, self.datas)
            end
        end

        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.RecipeCookingMaking_Callback)
        GuideUtils.DispatchStepEvent()
    elseif  name == SIGNALNAMES.RecipeCooking_Magic_Make_Callback then
        local needData = {}
        local consumeData = clone(self:GetViewComponent().recipeData[tostring(self.datas.recipeId)].make)
        for k , v in pairs(consumeData) do  -- 整合数据 魔法菜谱是不可以用调料的 所以不消耗调料
            needData[#needData+1] = {}
            needData[#needData].num  = - (v  * checkint(self.makeCountNum))
            needData[#needData].goodsId  =  k
        end
        CommonUtils.DrawRewards(needData)
        self.makeSureSeasoningId = nil
        uiMgr:AddDialog('common.RewardPopup',{rewards = checktable(checktable(signal:GetBody()).rewards),mainExp = signal:GetBody().mainExp})
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.RecipeCookingMaking_Callback)
    elseif  name == SIGNALNAMES.RecipeCooking_GradeLevelUp_Callback then
        self.datas.gradeId  =   self.datas.gradeId +1
        local data = clone(self.datas.gradeId)
       
        local consumeData = clone( self:GetViewComponent().recipeData[tostring(self.datas.recipeId)].grade[tostring(self.datas.gradeId)].consume)
        for k , v in pairs(consumeData) do 
            v.num = 0 - v.num 
        end
        CommonUtils.DrawRewards(consumeData)
        local cookingStyle  = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(self.datas.recipeId)].cookingStyleId
        app.badgeMgr:ClearUpgradeRecipeLevelAndNewRed(tostring(self.datas.recipeId), tostring(cookingStyle))
        self:GetFacade():DispatchObservers("REFRESH_RECIPE_DETAIL", { recipeType  = checkint(cookingStyle) , recipeLevelIsAdd = true ,  recipeNew = false  , recipeId =  self.datas.recipeId})
        local cloneData = clone( self.datas)
        cloneData.type = RECIPE_UPGRADE_COMPLETE
        self.RewardResearchAndMakeView:setVisible(true)
        self.RewardResearchAndMakeView:updateData(cloneData)

        --此处调用升级的动画
    elseif  "REFRESH_NOT_CLOSE_GOODS_EVENT" == name  then
        self:UpdateMakeBtnTimes()
        if not tolua.isnull(self.UpGradeRecipeLevelView) then -- 判断升级菜谱页面是否存在
            self.UpGradeRecipeLevelView:updateView(self.datas)
        end

    elseif LOBBY_FESTIVAL_ACTIVITY_END == name then
        
        local lobbyFestivalTipLayer = self.viewData.lobbyFestivalTipLayer
        if nodeExist(lobbyFestivalTipLayer) then
            lobbyFestivalTipLayer:setVisible(false)
        end
        
        if nodeExist(self.lobbyFestivalTipView) then
            self.lobbyFestivalTipView:setVisible(false)
        end
    elseif name == POST.Activity_Draw_restaurant.sglName then
        -- 餐厅活动开始时
        -- self:showLobbyFestivalTip()
    end
    self:updateRecipeDetailView(self.datas,CONTENT_REFRESH)
end
function RecipeDetailMediator:Initial( key )
	self.super.Initial(self,key)
	local RecipeDetailView = require("Game.views.RecipeDetailView")
    local layer = RecipeDetailView.new({type = self.type})
    local tag = 999
    layer:setTag(tag)
    layer:setPosition(display.center)
    if self.type == 1 then
        layer:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(layer)
    elseif self.type == 2 then
        local parentLayer = self.datas.layer 
        parentLayer:addChild(layer)
        self.datas.layer = nil
        if gameMgr:GetUserInfo().chef["2"] then
            local layerSize  = layer:getContentSize()
            local assisantLayout = self:createAssistantHeader()

            local cookHead =  display.newImageView(_res("ui/home/kitchen/cooking_cook_ico_head.png") ,layerSize.width-45 , layerSize.height -20 , { ap = display.LEFT_BOTTOM})
            layer:addChild(cookHead)
            assisantLayout:setPosition(cc.p(layerSize.width + 5,layerSize.height+10))
            layer:addChild(assisantLayout)

        end 
    end
    self.viewData = layer.viewData
    self.viewData.seasoningImage:setOnClickScriptHandler(handler(self,self.ButtonActions))
    self:SetViewComponent(layer)
    layer.viewData.levelBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
    self.viewData.makeBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
    self.viewData.makeBtnTimes:setOnClickScriptHandler(handler(self,self.ButtonActions))
    for i = 1 , #self.viewData.expBarBtns do
        self.viewData.expBarBtns[i]:getParent():setOnClickScriptHandler(handler(self,self.ButtonActions))
    end
    self.viewData.expBar:getParent():setOnClickScriptHandler(handler(self,self.ButtonActions))
    
    self:updateRecipeDetailView(self.datas)

end
-- 创建助手头像
function RecipeDetailMediator:createAssistantHeader()
    local headerImageBtn = display.newImageView("ui/home/kitchen/cooking_cook_bg_head_2.png")
    local headSize = headerImageBtn:getContentSize()
    local cardUid  = gameMgr:GetUserInfo().chef["2"]
    local cardData = gameMgr:GetCardDataById(cardUid)
    local cardId = nil 
    if  cardData and cardData.cardId then
        cardId  = cardData.cardId 
    else 
        return CLayout:create(cc.size(80,80))
    end 
    headerImageBtn:setTag(checkint(cardUid))
    headerImageBtn:setTouchEnabled(true)

    headerImageBtn:setOnClickScriptHandler(function (sender)
        local tag = sender:getTag()
       	local CardKitchenNode = require('common.CardKitchenNode')
		local layer = CardKitchenNode.new({id = tostring(tag)})
		layer:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(layer)
    end)
    headerImageBtn:setPosition(cc.p(headSize.width/2 , headSize.height/2))
    local headerLayout = display.newLayer(0,0,{ap = display.RIGHT_TOP , size = headSize })
    headerLayout:addChild(headerImageBtn,2)
    local headBg = display.newImageView(_res('ui/home/kitchen/cooking_cook_bg_head.png'))
    headBg:setPosition(cc.p(headSize.width/2 , headSize.height/2))
    headerLayout:addChild(headBg)
    local skinId      = cardMgr.GetCardSkinIdByCardId(cardId)
    local effectImage = CardUtils.GetCardHeadPathBySkinId(skinId)
    local clippingNode = cc.ClippingNode:create()
    local noticeImage = display.newImageView(effectImage)
    local stencilNode = display.newImageView(_res('ui/home/kitchen/cooking_cook_bg_head.png'))
    local stencilNodeSzie = stencilNode:getContentSize()
    local scale = stencilNodeSzie.width/ noticeImage:getContentSize().width
    noticeImage:setScale(scale)
    clippingNode:setAnchorPoint(display.CENTER)
    clippingNode:setContentSize( cc.size(stencilNodeSzie.width,stencilNodeSzie.height))
    clippingNode:addChild(noticeImage)
    clippingNode:setPosition(cc.p(headSize.width-3, headSize.height-3))
    clippingNode:setStencil(stencilNode)
    clippingNode:setAlphaThreshold(0.05)
    clippingNode:setInverted(false)
    -- clippingNode:setScale(10)
    headerLayout:addChild(clippingNode)
    return headerLayout 
end
--- 获取菜谱制作的最大的分数 设置制作最大的份数是十
function RecipeDetailMediator:GetMaxMakePartMargicRecipeStyle()
    local consumeData = CommonUtils.GetConfigAllMess("recipe","cooking")[tostring(self.datas.recipeId)].make
    local enoughMaterial = true
    for k,v in pairs (consumeData ) do
        -- 检测调料是否充足
        local num = gameMgr:GetAmountByGoodId(k)
        if checkint(num) < checkint(v) then
            enoughMaterial = false
            return 0
        end
    end
    local countPart = 10
    local makeCount =  0  -- 可以制作菜的分数
    for k,v in pairs (consumeData ) do
        -- 检测调料是否充足
        local num = gameMgr:GetAmountByGoodId(k)
        makeCount =  math.floor(num / checkint(v))
        countPart = math.min(makeCount , countPart)  -- 比较取最小的值
    end
    if self.makeSureSeasoningId then
        local makeSeasoningPart = gameMgr:GetAmountByGoodId(self.makeSureSeasoningId)  -- 菜谱制作每次消耗一个调料
        if makeSeasoningPart == 0 then
            self.makeSureSeasoningId = nil
        else
            countPart = math.min(makeSeasoningPart, countPart )
        end
    end
    return countPart
end
function RecipeDetailMediator:SenderMakeRecipeBtn(countNum)
    if self.RewardResearchAndMakeView then
        if not  tolua.isnull( self.RewardResearchAndMakeView ) then
            return
        end
    end
    local cookingStyleId = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(self.datas.recipeId)].cookingStyleId
    local initial = CommonUtils.GetConfigAllMess('style','cooking')[tostring(cookingStyleId)].initial

    if countNum == 0 then
        if GuideUtils.IsGuiding() then
            GuideUtils.ForceShowSkip()
            local mediator = self:GetFacade():RetrieveMediator("HomeMediator")
            if mediator and  mediator:GetViewComponent() then
                mediator:GetViewComponent():onClickFoldButtonHandler_()
                ---@type RecipeResearchAndMakingMediator
                local RecipeResearchAndMakingMediator =   self:GetFacade():RetrieveMediator("RecipeResearchAndMakingMediator")
                if RecipeResearchAndMakingMediator  then
                   self:GetFacade():UnRegsitMediator("RecipeResearchAndMakingMediator")
                else
                    self:GetFacade():UnRegsitMediator(NAME)
                end
            end
        end
        uiMgr:ShowInformationTips(__('制作菜品材料不足！！'))
        return
    end
    if checkint(initial) ~= MAGIC_FOOD_STYLE then  -- 菜谱制作分为魔法菜谱 和非魔法菜谱
        local data = {}
        data.recipeId = checkint( self.datas.recipeId)
        data.seasoning = {}
        if self.makeSureSeasoningId then
            data.seasoning[tostring( self.makeSureSeasoningId)] = 1
            data.seasoning = json.encode(data.seasoning)
        else
            data.seasoning = json.encode({})
        end
        data.num = countNum
        self.makeCountNum = countNum
        local RewardResearchAndMakeView = require('Game.views.RewardResearchAndMakeView')
        local layer = RewardResearchAndMakeView.new({type = UNMAGIC_FOOD_STYLE})
        layer:setPosition(display.center)
        layer:setName("RewardResearchAndMakeView")
        uiMgr:GetCurrentScene():AddDialog(layer)
        self.RewardResearchAndMakeView = layer
        self.RewardResearchAndMakeView:setVisible(false)
        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Making_Callback , data)
    else
        local  data = {}
        data.recipeId = checkint( self.datas.recipeId)
        data.num = countNum
        self.makeCountNum = countNum
        data.seasoning = nil
        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Magic_Make_Callback , data)

    end
end
--- 更新多次制作按钮
function RecipeDetailMediator:UpdateMakeBtnTimes()
    local countNum = self:GetMaxMakePartMargicRecipeStyle()
    countNum  =countNum > 1  and countNum  or 10
    local label =  self.viewData.makeBtnTimes:getLabel()
    label:setString(string.format(__('做%d份' ) ,countNum ))
end
--[[
推荐。申请切换
@param sender button对象
--]]
function RecipeDetailMediator:ButtonActions( sender )
    local tag= sender:getTag()
	PlayAudioByClickNormal()
    if   tag == BTNCOLLECT_TAG.ADDTIP_TEST then
        uiMgr:ShowInformationTips(__('影响菜品在餐厅内出售获得的知名度'))
    elseif tag ==  BTNCOLLECT_TAG.ADDTIP_MUSEFEEL  then
        uiMgr:ShowInformationTips(__('提高菜品在餐厅出售额外获得的金币数量.'))
    elseif  tag == BTNCOLLECT_TAG.ADDTIP_FRAGRABCE then
        uiMgr:ShowInformationTips(__('提高餐厅内的客流量.'))
    elseif  tag ==  BTNCOLLECT_TAG.ADDTIP_EXTERIOR then
        uiMgr:ShowInformationTips(__('影响菜品在餐厅内的售卖价格'))
    elseif  tag ==  BTNCOLLECT_TAG.MAKE_BTN_TIMES then -- 多次制作的按钮
        local countNum = self:GetMaxMakePartMargicRecipeStyle()
        countNum = countNum > 0 and  countNum   or  0  -- 多次制作  要么是0 要么是 1
        if countNum == 0 then
            uiMgr:ShowInformationTips(__('制作菜品材料不足！！'))
            return
        elseif  countNum == 1 then
            local cookingStyleId = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(self.datas.recipeId)].cookingStyleId
            local initial = CommonUtils.GetConfigAllMess('style','cooking')[tostring(cookingStyleId)].initial
            if checkint(initial) ~=  MAGIC_FOOD_STYLE then
                if self.makeSureSeasoningId then
                    local seasoningNum =  CommonUtils.GetCacheProductNum(self.makeSureSeasoningId)
                    if seasoningNum > countNum then
                        uiMgr:ShowInformationTips(__('制作菜品材料不足！！'))
                    else
                        uiMgr:ShowInformationTips(__('调料不足！！'))
                    end

                else
                    uiMgr:ShowInformationTips(__('制作菜品材料不足！！'))
                end
                return
            end

        end
        self:SenderMakeRecipeBtn(countNum)
    elseif  tag ==  BTNCOLLECT_TAG.ADDTIP_TOTAL then
        local gradeTable  = self:GetViewComponent().recipeData[tostring(self.datas.recipeId)].grade or {}
        local cookingPoint = checkint(checktable(gradeTable[tostring(self.datas.gradeId)]).cookingPoint)
        local makingMax = checkint(checktable(gradeTable[tostring(self.datas.gradeId)]).makingMax)
        uiMgr:ShowInformationTips( string.format( __('当前菜谱制作出的菜品,在外卖中可获得的厨力点为%s.餐厅内可批量生产的份数为%s.') , cookingPoint ,makingMax))
    elseif  tag ==  BTNCOLLECT_TAG.MAKE_BTN then
        local countNum = self:GetMaxMakePartMargicRecipeStyle()
        countNum = countNum > 0 and  1 or  0  -- 单次制作  要么是0 要么是 1
        self:SenderMakeRecipeBtn(countNum)
    elseif  tag ==  BTNCOLLECT_TAG.ADDSEASONING_BTN then
        -- 此处添加背包列表
        self:obtainCommonOrUnCommonSeasoning() -- 筛选出来精致的和普通的调料
        local RecipeBackPackView = require("Game.views.RecipeBackPackView")
        local layer = RecipeBackPackView.new()
        layer:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(layer)
        ---@type RecipeBackPackView
        self.RecipeBackPackView  = layer
        local viewData_ = self.RecipeBackPackView.viewData_
        viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self,self.onDataSourceAction))
        viewData_.closeView:setOnClickScriptHandler(function ()
            self.currentSeasoningId = nil
            self.preRecipeBackPackIndex = nil
            self.preSeasoningCell = nil
            self.preSelectBtn = nil
            self:closeLayerView(viewData_.bgLayout,self.RecipeBackPackView)
        end)
        self.RecipeBackPackView:setName("RecipeBackPackView")
        viewData_.obtainWayBtn:setOnClickScriptHandler(function ()
            uiMgr:AddDialog("common.GainPopup", {goodId = self.currentSeasoningId  })
        end)
        self.seasoningType = self:getGoodsIdBySeasoningType()
        for k ,v in pairs (viewData_.buttons) do
            v:setOnClickScriptHandler(handler(self,self.ButtonActions))
            if  self.seasoningType == 1 and v:getTag() == BTNCOLLECT_TAG.COMMON_SEASONING then --显示第一次应该训中的类型
                v:setChecked(true)
                v:setEnabled(false)
                self.preSelectBtn = v
                if self.makeSureSeasoningId then
                    for i =1 ,  #self.commonSeasoning do
                        if checkint(self.commonSeasoning[i].goodsId) == checkint(self.makeSureSeasoningId)  then
                            self.preRecipeBackPackIndex = i
                        end
                    end
                else
                    self.preRecipeBackPackIndex = 1
                end
                self.currentSeasoningData = self.commonSeasoning
            elseif  self.seasoningType == 2 and v:getTag() == BTNCOLLECT_TAG.UNCOMMON_SEASONING then
                v:setChecked(true)
                v:setEnabled(false)
                self.preSelectBtn = v
                if self.makeSureSeasoningId then
                    for i =1 ,  #self.unCommonSeasoning do
                        if checkint(self.unCommonSeasoning[i].goodsId) == checkint(self.makeSureSeasoningId)  then
                            self.preRecipeBackPackIndex = i
                        end
                    end
                else
                    self.preRecipeBackPackIndex = 1
                end
                self.currentSeasoningData = self.unCommonSeasoning
            end
        end
        viewData_.getBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
        self:switchCommonOrUncommon()
    elseif  tag ==  BTNCOLLECT_TAG.READY_LEVEL_UP then
        local UpGradeRecipeLevelView = require("Game.views.UpGradeRecipeLevelView").new()
        UpGradeRecipeLevelView:setPosition(display.center)
        UpGradeRecipeLevelView:setName("UpGradeRecipeLevelView")

        local tag = 11111
        UpGradeRecipeLevelView:setTag(tag)
        uiMgr:GetCurrentScene():AddDialog(UpGradeRecipeLevelView)

        self.UpGradeRecipeLevelView = UpGradeRecipeLevelView
        self.UpGradeRecipeLevelView.viewData.upGradeBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
        self.UpGradeRecipeLevelView.viewData.btnCanacel:setEnabled(true)
        local isClose = false
        self.UpGradeRecipeLevelView.viewData.btnCanacel:setOnClickScriptHandler(function(sender)
            if not  isClose  and self.UpGradeRecipeLevelView then
                isClose = true

                self:closeLayerView(self.UpGradeRecipeLevelView.viewData.bgLayout , self.UpGradeRecipeLevelView)
                self.UpGradeRecipeLevelView = nil
                GuideUtils.DispatchStepEvent()
            end
        end)
        self.UpGradeRecipeLevelView:updateView(self.datas)
        self.UpGradeRecipeLevelView.viewData.closeView:setOnClickScriptHandler(function()
            if not  isClose  and self.UpGradeRecipeLevelView  then
                isClose = true
                self:closeLayerView(self.UpGradeRecipeLevelView.viewData.bgLayout , self.UpGradeRecipeLevelView)
                self.UpGradeRecipeLevelView = nil
            end
        end)
        GuideUtils.DispatchStepEvent()
    elseif  tag ==  BTNCOLLECT_TAG.USER_SEASONING then
        self.preSelectBtn = nil
        self.preSeasoningCell = nil

        if self.currentSeasoningId and  self.currentSeasoningId == self.makeSureSeasoningId then
            self.currentSeasoningId = nil
            self.makeSureSeasoningId = nil  --首先重置数据
            local node  = self.viewData.seasoningImage:getChildByTag(115)
            if node then
                self.viewData.seasoningImage:removeChildByTag(115)
            end
            self.viewData.seasoningIcon:setVisible(true)
            self:GetViewComponent():reloadIconShow()
        else  -- 这个是更换的方法

            local str = self:GetViewComponent().addSeasoningUpdateView and self:GetViewComponent():addSeasoningUpdateView(self.datas, self.currentSeasoningId) or ''
            if str and  str ~= "" then
                local CommonTip  = require( 'common.CommonTip' ).new({text = string.format( __(' 该食谱的%s属性已满' ),str)  ,descr = __('添加食谱已经无法再为该食谱添加额外的属性了哦？确定还要继续吗？'),
                    callback = function ()
                        --self:ButtonActions(self:GetViewComponent().viewData.makeBtn)
                        local node  = self.viewData.seasoningImage:getChildByTag(115)
                        if node then
                            self.viewData.seasoningImage:removeChildByTag(115)
                        end
                        self.viewData.seasoningIcon:setVisible(false)
                        self.makeSureSeasoningId = self.currentSeasoningId
                        self.currentSeasoningId = nil
                        local iconPath = CommonUtils.GetGoodsIconPathById( self.makeSureSeasoningId )
                        local seasoningImageSize =  self.viewData.seasoningImage:getContentSize()
                        local sprite = display.newImageView(iconPath,seasoningImageSize.width/2 ,seasoningImageSize.height/2)
                        sprite:setScale(0.5)
                        sprite:setTag(115)
                        self.viewData.seasoningImage:addChild(sprite)
                        local seasoningData = CommonUtils.GetConfig('goods','goods',self.makeSureSeasoningId)
                        self.viewData.tipLabel:setString(seasoningData.name)
                    end,
                    cancelBack = function ()
                    end})
                CommonTip:setPosition(display.center)
                local scene = uiMgr:GetCurrentScene()
                scene:AddDialog(CommonTip,10)
            else
                local node  = self.viewData.seasoningImage:getChildByTag(115)
                if node then
                    self.viewData.seasoningImage:removeChildByTag(115)
                end
                self.viewData.seasoningIcon:setVisible(false)
                self.makeSureSeasoningId = self.currentSeasoningId
                self.currentSeasoningId = nil
                local iconPath = CommonUtils.GetGoodsIconPathById( self.makeSureSeasoningId )
                local seasoningImageSize =  self.viewData.seasoningImage:getContentSize()
                local seasoningData = CommonUtils.GetConfig('goods','goods',self.makeSureSeasoningId) or {}
                self.viewData.tipLabel:setString(tostring(seasoningData.name))
                local sprite = display.newImageView(iconPath,seasoningImageSize.width/2 ,seasoningImageSize.height/2)
                sprite:setScale(0.5)
                sprite:setTag(115)
                self.viewData.seasoningImage:addChild(sprite)
            end
        end
        self:UpdateMakeBtnTimes()
        if self.RecipeBackPackView then
            self:closeLayerView(self.RecipeBackPackView.viewData_.bgLayout ,self.RecipeBackPackView)
        end
    elseif  tag ==  BTNCOLLECT_TAG.UPGRADE_LEVEL then
        if self.UpGradeRecipeLevelView then
            if self.UpGradeRecipeLevelView.foodMaterial then
                local data = {}
                data.recipeId = self.datas.recipeId
                local cookingStyleId = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(self.datas.recipeId)].cookingStyleId
                local initial = CommonUtils.GetConfigAllMess('style','cooking')[tostring(cookingStyleId)].initial
                if checkint(initial) ~= MAGIC_FOOD_STYLE then
                    local RewardResearchAndMakeView = require('Game.views.RewardResearchAndMakeView')
                    local layer = RewardResearchAndMakeView.new({ type = RECIPE_UPGRADE_COMPLETE})
                    layer:setPosition(display.center)
                    uiMgr:GetCurrentScene():AddDialog(layer)
                    self.RewardResearchAndMakeView = layer
                    self.RewardResearchAndMakeView:setVisible(false)
                end
                self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_GradeLevelUp_Callback, data)
                self:closeLayerView(self.UpGradeRecipeLevelView.viewData.bgLayout , self.UpGradeRecipeLevelView)
                GuideUtils.DispatchStepEvent()
            else
                if GuideUtils.IsGuiding() then
                    self:closeLayerView(self.UpGradeRecipeLevelView.viewData.bgLayout , self.UpGradeRecipeLevelView)
                    GuideUtils.ForceShowSkip() --是否显示引导的逻辑
                end
                uiMgr:ShowInformationTips(__('所需材料不足'))
            end
        end
    elseif  tag ==  BTNCOLLECT_TAG.UPGRADE_CANACEL then
        self.closeLayerView(self.UpGradeRecipeLevelView.viewData.bgLayout , self.UpGradeRecipeLevelView)
    elseif tag <=  BTNCOLLECT_TAG.COMMON_SEASONING and tag >=  BTNCOLLECT_TAG.UNCOMMON_SEASONING  then
        if self.preSelectBtn and self.preSelectBtn:getTag() == tag then -- 如果点击的是同一个没有反应
            return
        end
        if self.preSelectBtn then
            self.preSelectBtn:setChecked(false)
            self.preSelectBtn:setEnabled(true)
        end
        sender:setChecked(true)
        sender:setEnabled(false)
        self.preSelectBtn = sender
        if  tag ==  BTNCOLLECT_TAG.COMMON_SEASONING then
            self.seasoningType = 1
            self.preSeasoningCell = nil
            self.preRecipeBackPackIndex = nil
            self.currentSeasoningData = self.commonSeasoning
            self:switchCommonOrUncommon()
        elseif  tag ==  BTNCOLLECT_TAG.UNCOMMON_SEASONING then
            self.seasoningType = 2
            self.preSeasoningCell = nil
            self.preRecipeBackPackIndex = nil
            self.currentSeasoningData = self.unCommonSeasoning
            self:switchCommonOrUncommon()
        end
    elseif tag == BTNCOLLECT_TAG.LOBBY_FESTIVAL_TIP then
        if self.lobbyFestivalTipView == nil then
            local bgLayout = self.viewData.bgLayout
            local bgSize = bgLayout:getContentSize()
            self.lobbyFestivalTipView = require('Game.views.LobbyFestivalTipView').new({arrowDirection = 2})
            display.commonUIParams(self.lobbyFestivalTipView, {ap = display.CENTER_TOP, po = cc.p(140, bgSize.height - 66)})
            bgLayout:addChild(self.lobbyFestivalTipView)

            local recepeFestivalData = app.activityMgr:getLobbyFestivalMenuData(self.datas.recipeId)
            self:UpdateLobbyFestivalTipUi(recepeFestivalData, self.datas)
        else
            self.lobbyFestivalTipView:setVisible(not self.lobbyFestivalTipView:isVisible())

            if self.lobbyFestivalTipView:isVisible() then
                local recepeFestivalData = app.activityMgr:getLobbyFestivalMenuData(self.datas.recipeId)
                self:UpdateLobbyFestivalTipUi(recepeFestivalData, self.datas)
            end
        end
    end
end
-- 获取调料的type
function RecipeDetailMediator:getGoodsIdBySeasoningType()
    -- body
    local type = 1   -- 一为普通 2为特殊
    if self.makeSureSeasoningId  then
        if checkint( self.makeSureSeasoningId  ) >=231001 and checkint( self.makeSureSeasoningId  ) <=231999 then
            type = 2 
        else 
            type = 1 
        end 
    end
    return type

end
-- 关闭界面
function RecipeDetailMediator:closeLayerView(bgLayout,layer)
    if tolua.isnull(layer) then
        return 
    end
    if bgLayout then
        bgLayout:runAction(
            cc.Sequence:create(
                cc.EaseExponentialOut:create(
                    cc.ScaleTo:create(0.2, 1.1)
                ),
                cc.ScaleTo:create(0.1, 1),
                cc.TargetedAction:create(layer, cc.RemoveSelf:create())
            )
        )
    end
end
--切换普通和精致的功能
function RecipeDetailMediator:switchCommonOrUncommon()
    if self.RecipeBackPackView == nil then
        return
    end
    local gridView = self.RecipeBackPackView.viewData_.gridView
    gridView:setCountOfCell(#self.currentSeasoningData)
    gridView:reloadData()
    if self.makeSureSeasoningId and self:getGoodsIdBySeasoningType() == self.seasoningType then  --获取当前type 类型是否是选中的类型 ，是否需要进行页面翻转
        local Num = 0
        local cellSize = gridView:getSizeOfCell()
        local gridSize =  gridView:getContentSize()
        local containerSize = gridView:getContainerSize()
        for i =1 , #self.currentSeasoningData do
            if self.currentSeasoningData[i].goodsId ==  self.makeSureSeasoningId then
                Num   = i 
                local columes = gridView:getColumns()
                local line = math.ceil( i / columes )
                if containerSize.height > gridSize.height then
                    -- gridView 的偏移分为超过和未超过两种方式
                    if  containerSize.height >=  cellSize.height * (line-1) + gridView:getContentSize().height then
                        gridView:setContentOffset(cc.p(0 ,  gridSize.height + cellSize.height * (line-1) - containerSize.height ))
                    else
                        gridView:setContentOffset(cc.p(0 ,  0 ))
                    end
                end
                break
            end
        end
    end
end
function RecipeDetailMediator:obtainCommonOrUnCommonSeasoning() -- 获取
    self.unCommonSeasoning = {}
    self.commonSeasoning = {}
    local ownerSeasoningTable = {}  -- 记录已经拥有的调料

    for k ,v in pairs(gameMgr:GetUserInfo().backpack) do 
        if checkint( v.goodsId ) >=230001 and checkint(v.goodsId) <=239999  then
            if checkint( v.goodsId ) >=231001 and checkint(v.goodsId) <=231999  then
                self.unCommonSeasoning[#self.unCommonSeasoning+1] = v 
                ownerSeasoningTable[tostring(v.goodsId)] = true 
            else
                self.commonSeasoning[#self.commonSeasoning+1] = v
                ownerSeasoningTable[tostring(v.goodsId)] = true 
            end
        end
    end
    local seasoningTable = CommonUtils.GetConfigAllMess('seasoning','goods') --记录调料的表
    for k ,v in pairs(seasoningTable) do
        if checkint( v.id ) >=230001 and checkint(v.id) <=239999  then
            if not  ownerSeasoningTable[tostring(v.id)] then
                local data = {}
                data.goodsId = v.id 
                data.amount = 0 
                if checkint( v.id ) >=231001 and checkint(v.id) <=231999  then
                    self.unCommonSeasoning[#self.unCommonSeasoning+1] = data 
                else
                    self.commonSeasoning[#self.commonSeasoning+1] = data
                end
            end
        end
    end
    local callfunc = function (a ,b)
        local aData = seasoningTable[tostring(a.goodsId)]
        local bData = seasoningTable[tostring(b.goodsId)]
        if a.amount == 0     then -- 判断是否为零 为零直接放到最后边
            return false
        end
        if b.amount == 0 then
            return true
        end
        if (not aData  ) or  not  aData.order then
            return  false
        end
        if (not bData  ) or  not  bData.order then
            return  true
        end
        if checkint(aData.order) > checkint(bData.order) then  -- 比较顺序的大小
            return false
        else
            return true
        end
    end
    table.sort(self.commonSeasoning, callfunc)
    table.sort(self.unCommonSeasoning, callfunc)
end
-- cell按钮的绑定
function RecipeDetailMediator:onDataSourceAction(p_convertview ,idx )
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(108, 115)
    if self.currentSeasoningData and index <= table.nums(self.currentSeasoningData) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.currentSeasoningData[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.updateBackPackView))
            if index <= 20 then
				pCell.eventnode:setPositionY(sizee.height - 800)
			    pCell.eventnode:runAction(
			        cc.Sequence:create(cc.DelayTime:create(index * 0.01),
			        cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5)), 0.2))
			    )
			else
            	pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
			end
        else
            pCell.selectImg:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        end
		xTry(function()
			local quality = 1
			if data then
				if data.quality then
					quality = data.quality 
				end
			end

			local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
			local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			if not utils.isExistent(drawBgPath) then
				drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
				fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			end
			pCell.fragmentImg:setTexture(fragmentPath)
			pCell.toggleView:setNormalImage(drawBgPath)
			pCell.toggleView:setSelectedImage(drawBgPath)
			pCell.toggleView:setTag(index)
			pCell.toggleView:setScale(0.92)
			pCell:setTag(index)
            if index == self.preRecipeBackPackIndex and (not self.preSeasoningCell)  then
                self:updateBackPackView(pCell.toggleView)
            end
			if data then
				if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
					pCell.fragmentImg:setVisible(true)
				else
					pCell.fragmentImg:setVisible(false)
				end
			else
				pCell.fragmentImg:setVisible(false)
			end
			if index == self.preRecipeBackPackIndex then
				pCell.selectImg:setVisible(true)
			else
				pCell.selectImg:setVisible(false)
			end

			pCell.numLabel:setString(tostring(self.currentSeasoningData[index].amount))

			local node = pCell.toggleView:getChildByTag(111)
			if node then node:removeFromParent() end
			local goodsId = self.currentSeasoningData[index].goodsId
			local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
			local sprite = display.newImageView(_res(iconPath),0,0,{as = false})
			sprite:setScale(0.55)
			local lsize = pCell.toggleView:getContentSize()
			sprite:setPosition(cc.p(lsize.width * 0.5,lsize.height *0.5))
			sprite:setTag(111)
			pCell.toggleView:addChild(sprite)
            if self.currentSeasoningData[index].amount == 0  then
                sprite:setColor(cc.c3b(80,80,80)) --设置为灰色
            end 
		end,__G__TRACKBACK__)
        return pCell
    end
end
--更新调料界面的显示
function RecipeDetailMediator:updateBackPackView(sender)
    local tag = sender:getTag()
    if checkint( self.preRecipeBackPackIndex) == tag and self.preSeasoningCell then
        return 
    end
    if self.preSeasoningCell then
        self.preSeasoningCell.selectImg:setVisible(false)
    end
    self.currentSeasoningId = self.currentSeasoningData[tag].goodsId  --获取到当前点击调料的值
    self.preSeasoningCell = sender:getParent():getParent()
    self.preSeasoningCell.selectImg:setVisible(true)
    
    self.preRecipeBackPackIndex = tag -- 获取到当前点击背包的顺序
    local viewData_ = self.RecipeBackPackView.viewData_
    
    local recipeData =  CommonUtils.GetConfigAllMess('recipe','cooking')
    local recipeOneData = recipeData[tostring(self.datas.recipeId) ]
    local recipeName = CommonUtils.GetConfig('goods','goods',recipeOneData.foods[1].goodsId).name
    local haveUseSeasoningTable 
    if self.datas.seasoning then
        haveUseSeasoningTable  = table.split(self.datas.seasoning ,",")
    else 
        haveUseSeasoningTable = {}
    end
    
    local haveUse = false 
    for  i =1 ,#haveUseSeasoningTable do 
        if checkint(self.currentSeasoningData[self.preRecipeBackPackIndex].goodsId) == checkint(haveUseSeasoningTable[i]) + 230000  then
            haveUse = true
            break 
        end
    end
    for i =1 ,  #viewData_.effectUITables do  --更新背包界面 首先要的做的是重置显示的信息
        viewData_.effectUITables[i].valueLabel:setString("")
        for j =1 , #viewData_.effectUITables[i].effectUI do
            viewData_.effectUITables[i].effectUI[j]:setVisible(false) 
        end
    end
    local effectTabel = {0,0,0,0} -- 定义添加作料的作用的等级表
     
    if haveUse  then
        local data  =  self.recipeCookingEffect[tostring(self.datas.recipeId)][tostring(self.currentSeasoningId)]  
        if data then  -- 判断当前调料是否有效果
            local attrTable = table.split(tostring(data.attr) ,";")
            for i =1 ,  #attrTable do 
                effectTabel[checkint(attrTable[i]) ] =  checkint(data.effectLevel[i]) 
            end
        else 
            for i =1 , 4 do 
                 viewData_.effectUITables[i].valueLabel:setString(__('无'))
            end 
        end
        for i =1 , #effectTabel do 
            local iconPath = ""
            if checkint(effectTabel[i])  > 0 then
                iconPath = _res('ui/home/kitchen/kitchen_ico_top.png') 
            elseif  checkint(effectTabel[i])  < 0 then
                iconPath = _res('ui/home/kitchen/kitchen_ico_down.png')
            end
            for j =1 ,math.abs(checkint(effectTabel[i])  or 0 )  do
                viewData_.effectUITables[i].effectUI[j]:setVisible(true)
                viewData_.effectUITables[i].effectUI[j]:setTexture(iconPath)
            end
        end
    else 
        for i =1, #viewData_.effectUITables do 
             viewData_.effectUITables[i].valueLabel:setString("?")
        end
    end
    display.reloadRichLabel(viewData_.recipeeffectName, {c = {
					fontWithColor('11',{text = recipeName ,color = "5c5c5c" }),
                    fontWithColor('16',{text = __('中的效果' ) , color = "5c5c5c" ,fontSize =20}),
				}
            })
    local desLabel =viewData_.DesNamebtn:getLabel()
    desLabel:setString(self.seasoningTable[tostring(self.currentSeasoningId)].name)
    desLabel:setAnchorPoint(display.LEFT_CENTER)
    local desSize =  viewData_.DesNamebtn:getContentSize()
    desLabel:setPosition(cc.p(10,desSize.height/2 ))
    viewData_.DesNumLabel:setString(__('拥有：') .. gameMgr:GetAmountByGoodId(self.currentSeasoningId))
    if (self.currentSeasoningId and self.makeSureSeasoningId ) and  (checkint(self.makeSureSeasoningId)  == checkint(self.currentSeasoningId))   then
        viewData_.getBtn:getLabel():setString(__('撤销'))
    else
        if gameMgr:GetAmountByGoodId(self.currentSeasoningId) == 0  then
            viewData_.getBtn:setEnabled(false)
            viewData_.getBtn:getLabel():setString(__('使用'))
        else 
            viewData_.getBtn:setEnabled(true)
            viewData_.getBtn:setNormalImage("ui/common/common_btn_orange.png")
            viewData_.getBtn:getLabel():setString(__('使用'))
        end 
    end 
    if viewData_.reward_rank:getChildByTag(1112) then
        viewData_.reward_rank:removeChildByTag(1112)
    end



    local seasingDescrTable = self:DisposeSpecialString(recipeOneData.seasoningTips or  "")
    display.reloadRichLabel(viewData_.recipeTips,{ c = seasingDescrTable  } )
    local labelSize = display.getLabelContentSize(viewData_.recipeTips)
    viewData_.contentLayout:setContentSize(labelSize)
    viewData_.recipeTips:setPosition(cc.p(labelSize.width/2 , labelSize.height))
    viewData_.listView:reloadData()
    local  framesize = viewData_.reward_rank:getContentSize()
    local goodsPath = CommonUtils.GetGoodsIconPathById(self.currentSeasoningId) 
    local goodsImage = display.newImageView(goodsPath,framesize.width/2 , framesize.height/2)
    goodsImage:setScale(0.6)
    goodsImage:setTag(1112)
    viewData_.reward_rank:addChild(goodsImage)
    viewData_.reward_rank:setVisible(true)
end

function RecipeDetailMediator:UpdateLobbyFestivalTipUi(recepeFestivalData, recepeData)
	self.lobbyFestivalTipView:updateUi(recepeFestivalData, recepeData)
end

--[[
    字符串的分割方式 是以<b></b>
--]]
function RecipeDetailMediator:DisposeSpecialString (str )
    local count = string.len( str )
    local redTable = {}
    local i = 1
    while (i <=  count ) do
        local x, y =  string.find( str,"<b>.-</b>", i , false)
        print("x =%d , y =%d " ,x ,y )
        if x and y then
            i = y +1
        else
            break
        end
        redTable[#redTable+1] = { x, y }
    end
    local tabalestr = {}
    if redTable[1] then
        if redTable[1][1] > 1 then
            tabalestr[#tabalestr+1] = {common = true , str  = string.sub( str, 1, redTable[1][1]-1 )  }
        end
    end

    for  i = 1 , #redTable do
        local str1 = string.sub( str,redTable[i][1] ,redTable[i][2])
        local x,y  = string.find(str1,">.-<",1,false)
        if (x +1)  <= (y -1)  then
            local str2 = string.sub(str1,x+1, y-1)
            tabalestr[#tabalestr+1] = {common = false , str  = str2}
        end
        if i ==  #redTable  then
            if redTable[i][2] < count then
                tabalestr[#tabalestr+1] = {common = true , str  = string.sub( str, redTable[i][2]+1, count)  }
            end
        else
            tabalestr[#tabalestr+1] = {common = true , str  = string.sub( str, redTable[i][2]+1, redTable[i+1][1]-1 )  }
        end
    end
    local elementTable = {}
    for  i =1 ,#tabalestr do
        if tabalestr[i].common then
            elementTable[#elementTable+1] = fontWithColor(8, {text = tabalestr[i].str})
        else
            elementTable[#elementTable+1] = fontWithColor(8, {text = tabalestr[i].str ,color = "d23d3d" ,fontSize = 20 })
        end
    end
    if #elementTable == 0 then
        elementTable[#elementTable+1] = fontWithColor(8, {text = str })
    end
    return elementTable
end
-- 刷新详情的信息
--==============================--
--desc:
--time:2017-06-22 05:09:09
--@data:
--@type:1.表示外部刷新  2.表示内部刷新
--@return 
--==============================-- 
function RecipeDetailMediator:updateRecipeDetailView(data , type )
    self.datas = data  --重置数据刷新界面
    -- table.merge( self.datas ,data)
    self.seasoning = {}
    self.RecipeBackPackView =  nil -- 菜谱背包界面
    -- self.UpGradeRecipeLevelView =  nil  -- 菜谱升级界面
    if type ==EXTERNAL_REFRESH then
         self.makeSureSeasoningId = nil  
         self.preRecipeBackPackIndex = nil
         self.currentSeasoningData = {} -- 当前的类别是精致调料还是普通调料
    end 

    self.currentSeasoningId  = nil   
    self.commonSeasoning = {}  -- 普通调料
    self.unCommonSeasoning = {} -- 精致调料
    
    --   -- 记录当前点击的index
    self:UpdateMakeBtnTimes()
    self:GetViewComponent():updateDetailView(data, self.makeSureSeasoningId)

    if nodeExist(self.viewData.lobbyFestivalTipLayer) then
        self.viewData.lobbyFestivalTipLayer:setOnClickScriptHandler(handler(self,self.ButtonActions))
    end
end

function RecipeDetailMediator:OnRegist()
	local RecipeCookingAndStudyCommand = require('Game.command.RecipeCookingAndStudyCommand')
    self:GetFacade():RegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", mvc.Observer.new(self.ProcessSignal, self))
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Making_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_GradeLevelUp_Callback,RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Magic_Make_Callback,RecipeCookingAndStudyCommand)
end

function RecipeDetailMediator:OnUnRegist(  )
    self:GetFacade():UnRegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT",self)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Making_Callback)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_GradeLevelUp_Callback)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Magic_Make_Callback)
    if not  tolua.isnull(self.viewComponent) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
    if self.UpGradeRecipeLevelView and not tolua.isnull(self.UpGradeRecipeLevelView) then  --删除当前界面的时候注意删除
        self.UpGradeRecipeLevelView:runAction(cc.RemoveSelf:create())
    end
    local rewardResearchAndMakeView = uiMgr:GetCurrentScene():GetDialogByName("RewardResearchAndMakeView")
    if rewardResearchAndMakeView and ( not  tolua.isnull(rewardResearchAndMakeView) )then
        rewardResearchAndMakeView:stopAllActions()
        rewardResearchAndMakeView:runAction(cc.RemoveSelf:create())
        rewardResearchAndMakeView = nil
    end
end

return RecipeDetailMediator
