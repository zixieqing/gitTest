--[[
组队副本入口主界面UI
--]]
local Mediator = mvc.Mediator
---@class RecipeResearchAndMakingMediator
local RecipeResearchAndMakingMediator = class("RecipeResearchAndMakingMediator", Mediator)
---@type TimerManager
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
---@type BackpackCell
local BackpackCell = require('home.BackpackCell')
local EXTERNAL_REFRESH = 1
local NAME = "RecipeResearchAndMakingMediator"
local BtnCollect = {
    ImprovedRecipe = 1001, --改进按钮
    Research = 1002, --研究按钮
    Specialization = 1003, --专精按钮
    MagicStyle = 4, --魔法菜系
    closeBtn = 1004, --关闭按钮
    STYLE_BTN = 1005, --风格按钮
    SEARCH_BTN = 1006, --搜寻按钮
    SHOW_RECIPE_DETAIL = 1007, --显示菜谱详情界面的信息
    RESEARCH_RSEARCH = 1201, -- 菜谱开发中的开发
    RESEARCH_QUCIK = 1202, -- 开发中的快速完成
    RESEARCH_CANCEL = 1203, -- 菜谱开发取消
    RESEARCH_REWARD = 1204, -- 菜谱开发奖励领取
    STYLE_BTN_TWO  = 1311 , -- 第二个风格按钮
    CURRENT_RESEARCH_STYLE = 1205 , -- 当前研究的菜系
    FOOD_METARIAL = 1206 , ---- 食材的提示

}
local MAGIC_FOOD_STYLE = 2
local RED_TAG = 1115
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function RecipeResearchAndMakingMediator:ctor(params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    params = params or {}
    self.preClickTag = nil    -- 记录上一次点击的功能模块的按钮tag
    self.presStyleTag = params.presStyleTag or BtnCollect.ImprovedRecipe   --上一次选择风格按钮的tag   --上一次选择风格按钮的tag
    self.preStyleCell = nil    -- 记录上一次的cell
    self.currentRecipeData = nil -- 当前菜谱的数据
    self.preRecipeClickTag = nil
    self.preRcipeCell = nil
    self.newStyleCell = nil    --记录当前最新的就所得风格cell
    self.showStyleDetail = false  -- 记录cell详情的状态
    self.showLayerDataTable = {}     -- 主要用于三个界面模块的数据
    self.presStyleDetailTag = nil  --显示菜品详情的任务显示
    self.recipeResearchAndMakingView = nil  -- 烹饪界面
    self.foodMaterialData = {}  -- 食材表的数据
    self.remaindSortFoodIndex = {} -- 记录点机顺序
    self.consumeFoodMeterialData = {}   -- 记录当前需要的食材的数据
    self.researchFoodCellPreIndex = nil -- 记录满栈后的第一个弹出的第一个数据  --栈的大小为三
    self.RecipeDetailMediator = nil  --记录菜谱详情mediator
    self.leftReseachTimes = -1  --开发的剩余时间
    self.cookingStyleId = nil
    self.recipeStyle = params.recipeStyle
    self.preNowTag = nil
    self.isStyleAction = false
    -- self.researchStatus = 0   -- 0 为正常状态处于未开发 1、是在开发中
    self.redDotTable = {}  --获取到红点的table界面
    self.recipeStudyFormulaData = CommonUtils.GetConfigAllMess('recipeStudyFormula', 'cooking') -- 菜谱匹配表
    self.upgradeRecipeLevelData = CommonUtils.GetConfigAllMess('grade', 'cooking')
end

function RecipeResearchAndMakingMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.RecipeCooking_Cooking_Style_Callback,
        SIGNALNAMES.RecipeCooking_Study_Cancel_Callback,
        SIGNALNAMES.RecipeCooking_Study_Accelertate_Callback,
        SIGNALNAMES.RecipeCooking_Study_Draw_Callback,
        SIGNALNAMES.RecipeCooking_Study_Callback,
        SIGNALNAMES.RecipeCooking_Home_Callback,
        SIGNALNAMES.RecipeCooking_Magic_Make_Callback,
        "REFRESH_NOT_CLOSE_GOODS_EVENT",

        LOBBY_FESTIVAL_ACTIVITY_END,
        POST.Activity_Draw_restaurant.sglName,
    }
    return signals
end

function RecipeResearchAndMakingMediator:ProcessSignal(signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == "SELECT_STYLE_RECIPE" then
        self.selectCookingStyleId = data.cookingStyleId
        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Cooking_Style_Callback, data)
    elseif name == SIGNALNAMES.RecipeCooking_Cooking_Style_Callback then
        --解锁
        local cookingStyle = tostring(self.selectCookingStyleId)
        if not gameMgr:GetUserInfo().cookingStyles[cookingStyle] then
            --gameMgr:GetUserInfo().cookingStyles[cookingStyle] = {}
            if data.recipes then
                for i = 1, #data.recipes do
                    app.cookingMgr:UpdateCookingStyleDataById(data.recipes[i].recipeId)
                end
            end
            local countStyleNum = 0
            local cookingStyleData = self:GetStyleTable()
            for k, v in pairs(gameMgr:GetUserInfo().cookingStyles) do
                local styleData = cookingStyleData[k] or {}
                if checkint(styleData.initial) == 1 then
                    countStyleNum = countStyleNum + 1
                end
            end
            if countStyleNum == 1 then
                -- 如果是1 证明是刚开始研发选择 如果不是则是解锁另一个菜谱
                self:closeCurrentLayer(self:GetViewComponent(), true, true)
            elseif countStyleNum > 1 then
                local cellTable = self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:getNodes()
                for k, v in pairs(cellTable) do
                    --遍历所有的选项
                    if checkint(self.selectCookingStyleId) == checkint(v.id) then
                        --找到当前菜谱的类型
                        v.bgImage:clearFilter() -- 解锁新菜谱 清除以前的白色
                        v.titleImage:setTexture(_res('ui/home/kitchen/cooking_mastery_title.png'))
                    end
                end
                self:GetFacade():DispatchObservers("REFRESH_RECIPE_DETAIL", { recipeType = self.selectCookingStyleId, recipeLevelIsAdd = true,recipeNewStyle = true ,recipeNew = true, recipeId = data.recipes[1].recipeId })
            end
        end
        GuideUtils.DispatchStepEvent()
    elseif name == SIGNALNAMES.RecipeCooking_Study_Cancel_Callback then
        app.cookingMgr:SetRecipeLeftSecodTime(-1)
        timerMgr:StopTimer("RecipeReach")
        self:setcountDownLabelStatus()
        self:updateCancelOrRewardResearchView()
        self.showLayerDataTable[tostring(BtnCollect.Research)].view:stopAllActions()
        self.cookingStyleId = nil  --取消制空
    elseif name == SIGNALNAMES.RecipeCooking_Study_Accelertate_Callback then
        --self.leftReseachTimes = -1
        app.cookingMgr:SetRecipeLeftSecodTime(-1)
        timerMgr:StopTimer("RecipeReach")
        self:setcountDownLabelStatus()
        self.showLayerDataTable[tostring(BtnCollect.Research)].view:stopAllActions()
        CommonUtils.DrawRewards({ { goodsId = tostring(DIAMOND_ID), num = data.diamond - gameMgr:GetUserInfo().diamond } })
        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Draw_Callback, { cookingStyleId = self.cookingStyleId })
        GuideUtils.DispatchStepEvent()
    elseif name == SIGNALNAMES.RecipeCooking_Study_Draw_Callback then
        self.cookingStyleId = nil  --领取奖励后研究的类型制空
        --self.leftReseachTimes = -1
        app.cookingMgr:SetRecipeLeftSecodTime(-1)
        app.badgeMgr:CheckClearResearchRecipeRed()
        self:setcountDownLabelStatus()
        local isHave = false
        if data.recipeId then
            local recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')[tostring(data.recipeId)]
            local cookingStyle = tostring(recipeData.cookingStyleId)
            if not gameMgr:GetUserInfo().cookingStyles[cookingStyle] then
                gameMgr:GetUserInfo().cookingStyles[cookingStyle] = {}
            end
            local recipeOneData = {}
            if gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyle)] then
                for i = 1, #gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyle)] do
                    local v = gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyle)][i]
                    if checkint( v.recipeId) == checkint(data.recipeId) then
                        isHave = true
                        local addPropertyTable = { 'taste', 'museFeel', 'fragrance', 'exterior' }
                        v.growthTotal = 0
                        for i = 1, #addPropertyTable do
                            v[addPropertyTable[i]] = checkint( v[addPropertyTable[i]]) + checkint(data[addPropertyTable[i]].base) + checkint(data[addPropertyTable[i]].assistant) + checkint(data[addPropertyTable[i]].seasoning)
                            v.growthTotal = v.growthTotal + v[addPropertyTable[i]]
                        end
                        recipeOneData = clone(v)
                        -- 此处也应该调用展示界面
                    end
                end
            end
            if not isHave then
                --这个里面弹出获得奖励款
                app.cookingMgr:UpdateCookingStyleDataById(data.recipeId)
                -- 调用GameManager 统一修改
                CommonUtils.DrawRewards(data.rewards)
                self:GetFacade():DispatchObservers("REFRESH_RECIPE_DETAIL", { recipeType = cookingStyle, recipeLevelIsAdd = false, recipeNew = true, recipeId = data.recipeId })
                local t = {}
                t.recipeId      = tostring(data.recipeId)
                t.taste         = 0
                t.museFeel      = 0
                t.fragrance     = 0
                t.exterior      = 0
                t.growthTotal   = 0
                t.gradeId       = 1
                t.seasoning     = ''
                local recipedata = t
                recipedata.type = MAGIC_FOOD_STYLE
                local RewardResearchAndMakeView = require('Game.views.RewardResearchAndMakeView')
                local layer = RewardResearchAndMakeView.new(recipedata)
                layer:setName('RewardResearchAndMakeView')
                layer:setPosition(display.center)
                uiMgr:GetCurrentScene():AddDialog(layer)

                -- 解锁新菜谱 广播一次消息
                AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.RecipeUnlock_Callback)
            end
        end
        self:updateCancelOrRewardResearchView()
        if (isHave and data.recipeId) or ((not isHave) and (not data.recipeId) ) then
            uiMgr:AddDialog('common.RewardPopup', { rewards = checktable(data.rewards), type = 2 } )
        end
    elseif name == SIGNALNAMES.RecipeCooking_Study_Callback then
        -- 菜谱制作
        local leftReseachTimes = checkint(data.leftSeconds)
        if leftReseachTimes < 300 then
            leftReseachTimes = math.ceil( leftReseachTimes / 60) + leftReseachTimes
        end
        app.cookingMgr:SetRecipeLeftSecodTime(leftReseachTimes)
        app.badgeMgr:AddRecipeTimeInfoRed()
        self:setcountDownLabelStatus()
        local datas = {}
        local sortData = {}
        for k , v in pairs(self.consumeFoodMeterialData) do
            sortData[#sortData+1] = v.index
        end
        table.sort(sortData, function( a, b)
            if checkint(a) > checkint(b) then
                return true
            else
                return false
            end
        end)
        for  i =1, #sortData do
            local   k = sortData[i]
            local data = {}
            if self.foodMaterialData[checkint(k)]  and self.foodMaterialData[checkint(k)].goodsId then
                data.goodsId = tostring(self.foodMaterialData[checkint(k)].goodsId)
                data.num = -1
                datas[#datas + 1] = data
                if checkint(self.foodMaterialData[checkint(k)].amount) == 1 then
                    table.remove(self.foodMaterialData, checkint(k) )
                end
            end
        end

        CommonUtils.DrawRewards(datas)
        local isHave = false
        if isHave then
            self:swithRecipeStyleGridView()
        end
        self.consumeFoodMeterialData = {}
        self.showLayerDataTable[ tostring(BtnCollect.Research)].foodGridView:setCountOfCell(table.nums(self.foodMaterialData))
        self.showLayerDataTable[ tostring(BtnCollect.Research)].foodGridView:reloadData()
        self:recipeResearchAction()
        GuideUtils.DispatchStepEvent()

    elseif name == SIGNALNAMES.RecipeCooking_Home_Callback then
        local isHave = false
        for k, v in pairs(data.cookingStyles) do
            if v.leftSeconds ~= -1 then
                app.cookingMgr:SetRecipeLeftSecodTime(v.leftSeconds)
                self.cookingStyleId = v.cookingStyleId
                isHave = true
                self:setcountDownLabelStatus()
            end
        end
        if not  isHave  then
            app.cookingMgr:SetRecipeLeftSecodTime(-1)
        end
        if self.presStyleTag == BtnCollect.Research then
            self:research_Special_make(self.recipeResearchAndMakingView.collectBtn[tostring(self.presStyleTag)])
        end

        if self:GetViewComponent():getName() == 'Game.views.ArrangeSpecialStartView' and not GuideUtils.IsGuiding() then
            GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_LOBBY, 4)
        else
            GuideUtils.DispatchStepEvent()
        end
    elseif name == "REFRESH_RECIPE_DETAIL" then
        local recipeNew = data.recipeNew  --是否研究出来了新的菜品
        local recipeType = data.recipeType   -- 研究出新的菜品的type
        local recipeFull = data.recipeFull
        local recipeLevelIsAdd = data.recipeLevelIsAdd -- 菜品等级是否增加
        local recipeNewStyle = data.recipeNewStyle
        local isHave = false
        -- 产生新菜谱的时候 刷新界面需要
        if recipeNew and self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)] then
            -- 确定是否有新的菜谱产生
            local unLockStyleData = app.cookingMgr:getResearchStyleTable()
            for k, v in pairs(gameMgr:GetUserInfo().cookingStyles) do
                -- 判断该类型的菜品是否存在
                if checkint(k ) ~= BtnCollect.MagicStyle and  not self.recipeResearchAndMakingView.styleBtns[tostring(k)]  and  unLockStyleData[k] then
                    self.currentRecipeData = app.cookingMgr:SortRecipeKindsOfStyleByGradeThenOrder(k)
                    local styleLayout = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].styleLayout
                    local styleLayoutParent =  styleLayout:getParent()
                    local pos = cc.p(styleLayout:getPosition())
                    local scaleY = styleLayout:getScaleY()
                    local isVisible = styleLayout:isVisible()
                    -- 重新删除菜谱的系列 重新排列 注册事件
                    styleLayout:removeFromParent()
                    styleLayout = nil
                    local styleLayoutData = self.recipeResearchAndMakingView:createStyleButtonsLayout()
                    styleLayout = styleLayoutData.view
                    styleLayoutParent:addChild(styleLayout)
                    styleLayout:setPosition(pos)
                    styleLayout:setAnchorPoint(display.CENTER_TOP)
                    styleLayout:setScaleY(scaleY)
                    styleLayout:setVisible(isVisible)
                    self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].styleLayout = styleLayout
                    for  k ,v in pairs( self.recipeResearchAndMakingView.styleBtns) do
                        v:setTag(checkint(k))
                        v:setOnClickScriptHandler(handler(self, self.switchRecipeStyle))
                    end
                    isHave = true
                    break
                end
            end
        end
        if ( recipeNew or recipeFull ) then -- 产生新菜和满足升级添加红点
            self:addRedDotNofication(data)
            self:addRedDotToBtn()
            if self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)]   then
                -- 检测该改进页面数据数据是否存在
                self.preRecipeClickTag = nil
                self.preRcipeCell = nil
                -- 如果菜谱是最新菜谱 节更新进度
                if not isHave then
                    if recipeNew and checkint(self.presStyleTag ) == checkint(recipeType)
                            or self.presStyleTag == checkint(ALL_RECIPE_STYLE)  then
                        self.currentRecipeData = app.cookingMgr:SortRecipeKindsOfStyleByGradeThenOrder(recipeType)
                    end
                end
                isHave = true
            end
        end
        if recipeLevelIsAdd then -- 菜谱可升级的时候 需要清除红点
            self:clearRedDotBtn()
        end
        local nowPressStyle = self.presStyleTag
        if recipeNewStyle then
            nowPressStyle = recipeType
        end
        self.presStyleTag = nil
        if   self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)] then
            for k , v in pairs(self.recipeResearchAndMakingView.styleBtns) do
                if checkint(k) == nowPressStyle  then
                    self:switchRecipeStyle(v)
                    break
                end
            end
        end
        if self.showLayerDataTable[tostring(BtnCollect.Specialization)] and recipeNew then
            --专精页面数据是否存在
            self:setVisibleOrFalseUnLockBtn()
        end
    elseif "REFRESH_NOT_CLOSE_GOODS_EVENT" == name  then
        if self.showLayerDataTable[tostring(BtnCollect.Research)] then
            local viewData =  self.showLayerDataTable[tostring(BtnCollect.Research)]
            self.foodMaterialData = self:getFoodMaterialData()
            self:CheckMakeFoodMaterialIndex()  -- 修改消耗材料的顺序
            viewData.foodGridView:setCountOfCell(table.nums(self.foodMaterialData ))
            viewData.foodGridView:setDataSourceAdapterScriptHandler(handler(self, self.onFoodsDataSourceAction))
            viewData.foodGridView:reloadData()
        end

    elseif name == POST.Activity_Draw_restaurant.sglName then
        self:updateStyleButtonsLayout()
    elseif name == LOBBY_FESTIVAL_ACTIVITY_END then
        self:updateStyleButtonsLayout()
        -- 当前选中的是 节日菜谱分类的话 则刷新
        if self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)] and tostring(self.preNowTag) == FESTIVAL_RECIPE_STYLE then
            local recipeStyle = ALL_RECIPE_STYLE
            local btn = self.recipeResearchAndMakingView.styleBtns[tostring(recipeStyle)]
            self:switchRecipeStyle(btn)

        end
    end
end
--- 收集刷新研究label的进度
function RecipeResearchAndMakingMediator:RefreshResearhViewCollectLabel ()
    if   self.showLayerDataTable[tostring(BtnCollect.Research)] then
        local styleType = self:makeSureReserchStyle()
        local cookingStylesTable = self:GetStyleTable()[tostring(styleType)]
        local Num = table.nums(gameMgr:GetUserInfo().cookingStyles[tostring(styleType)] or {})
        local accountNum = checkint(cookingStylesTable.studyRecipe) + checkint(cookingStylesTable.rewardsRecipe)
        local progressLabel = self.showLayerDataTable[tostring(BtnCollect.Research)].progressLabel
        progressLabel:setVisible(true)
        progressLabel:setString(string.format( __('收集进度%d/%d'), Num, accountNum) )
    end
end
-- 设置解锁按钮是否可见
function RecipeResearchAndMakingMediator:setVisibleOrFalseUnLockBtn()
    local cellTable = self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:getNodes()
    local isCollectComplete = true   -- 用于检测是否符合动画检测条件
    local cookingStylesTable = self:GetStyleTable()
    local unLockStyleData = app.cookingMgr:getResearchStyleTable()
    for k, v in pairs(cellTable) do
        -- 遍历所有的选项
        local value_Common = 0
        local value_Special = 0
        for recipeType, vv in pairs(gameMgr:GetUserInfo().cookingStyles ) do
            if checkint(recipeType) == checkint(v.id) then
                --找到当前菜谱的类型
                for kk, vv in pairs( gameMgr:GetUserInfo().cookingStyles[tostring(recipeType)]) do
                    if  unLockStyleData[recipeType] then
                        local recipeData = self.recipeResearchAndMakingView.recipeData[tostring(vv.recipeId)]
                        if checkint(recipeData.canStudyUnlock) == 1 then
                            value_Common = value_Common + 1
                        elseif checkint(recipeData.canStudyUnlock) == 0 then
                            value_Special = value_Special + 1
                        end
                    end
                end
                if v:getChildByTag(111) then
                    -- 判断菜谱详细显示信息是否存在
                    if  v.expBarCommon and not  tolua.isnull(v.expBarCommon) then
                        v.expBarCommon:setValue(value_Common)
                    end
                    if  v.expBarSpecial and not  tolua.isnull(v.expBarSpecial)  then
                        v.expBarSpecial:setValue(value_Special)
                    end
                end
                -- 如果有一个不符合 就显示加锁
                if value_Common ~= checkint(cookingStylesTable[tostring(recipeType)].studyRecipe) then
                    isCollectComplete = false
                    break
                end
            end
        end
    end
    for k, v in pairs(cellTable) do
        if  unLockStyleData[tostring(v.id)]  then -- 根据id 显示 而不是根据顺序
            if (  v.unLuckBtn and (not  tolua.isnull( v.unLuckBtn))  ) then -- 菜系解锁
                v.unLuckBtn:setVisible(false)
            end
            if (  v.lockIcon and (not tolua.isnull(v.lockIcon)  ) ) then
                v.lockIcon:setVisible(false)
            end
        else
            if v.unLuckBtn then
                v.unLuckBtn:setVisible(isCollectComplete)
            end
            if v.lockIcon then
                if isCollectComplete  then
                    v.lockIcon:setVisible(false)
                else
                    v.lockIcon:setVisible(true)
                end
            end

        end
    end
end
-- 添加对应的小红点
function RecipeResearchAndMakingMediator:addRedDotToBtn()
    for k, v in pairs(self.redDotTable) do
        if table.nums(v) > 0 then
            local btnTable = {
                self.recipeResearchAndMakingView.styleBtns[k],
                self.recipeResearchAndMakingView.othersButtns[tostring(BtnCollect.STYLE_BTN) ],
                self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.ImprovedRecipe) ]
            }
            for i = 1, #btnTable do
                local node = btnTable[i]:getChildByTag(RED_TAG)
                if not node then
                    local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
                    image:setTag(RED_TAG)
                    local size = btnTable[i]:getContentSize()
                    image:setPosition(cc.p(size.width - 20, size.height - 20))
                    btnTable[i]:addChild(image, 10)
                end
            end
        end
    end
end
--- 添加研究的红点 如果已经有了就不进行任何操作
function RecipeResearchAndMakingMediator:AddResearchRedDotBtn()
    local lefetime = app.cookingMgr:GetRecipeLeftSecodTime()
    if lefetime == 0 then
        local node = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research) ]
        local image = node:getChildByTag(RED_TAG)
        if not  image and tolua.isnull(image) then
            local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
            image:setTag(RED_TAG)
            local size = node:getContentSize()
            image:setPosition(cc.p(size.width - 20, size.height - 20))
            node:addChild(image, 10)
        end
    end
end
--- 清除研究红点
function RecipeResearchAndMakingMediator:ClearResearchRedDotBtn ()
    local lefetime = app.cookingMgr:GetRecipeLeftSecodTime()
    if lefetime ~= 0 then
        local node = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research) ]
        local image = node:getChildByTag(RED_TAG)
        if image  and (not tolua.isnull(image)) then
            node:removeChildByTag(RED_TAG)
        end
    end
end
-- 清除btn 红点的逻辑
function RecipeResearchAndMakingMediator:clearRedDotBtn()
    local isNewRecipe = false
    for k, v in pairs(self.redDotTable) do
        if table.nums(v) == 0 then
            if self.recipeResearchAndMakingView.styleBtns[k] then
                local node = self.recipeResearchAndMakingView.styleBtns[k]:getChildByTag(RED_TAG)
                if node then
                    self.recipeResearchAndMakingView.styleBtns[k]:removeChildByTag(RED_TAG)
                end
            end

        else
            isNewRecipe = true
        end
    end
    if not isNewRecipe then
        local node = self.recipeResearchAndMakingView.othersButtns[tostring( BtnCollect.STYLE_BTN)]:getChildByTag(RED_TAG)
        if node then
            self.recipeResearchAndMakingView.othersButtns[tostring( BtnCollect.STYLE_BTN)]:removeChildByTag(RED_TAG)
        end
        local node = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.ImprovedRecipe)]:getChildByTag(RED_TAG)
        if node then
            self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.ImprovedRecipe)]:removeChildByTag(RED_TAG)
        end
    end
end


-- 添加新菜谱
function RecipeResearchAndMakingMediator:addRedDotNofication(data)
    local recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local cookingStyleId = tostring(recipeData[tostring(data.recipeId)].cookingStyleId)
    if not self.redDotTable[cookingStyleId] then
        return
    end
    app.badgeMgr:AddUpgradeRecipeLevelAndNewRed(tostring(data.recipeId), cookingStyleId)
end
-- 判断当前的cell 是否显示new 新获得这张照片
function RecipeResearchAndMakingMediator:judgeIsAddRed( pcell, index)
    local data = self.currentRecipeData[index]
    local recipeId = tostring(data.recipeId)
    if self.redDotTable[tostring(self.presStyleTag)] then
        if self.redDotTable[tostring(self.presStyleTag)][recipeId] and checkint(data.growthTotal) == 0 then
            pcell.newImage:setVisible(true)
        end
    end
end
--- 判断是否可以满足升级的条件
function RecipeResearchAndMakingMediator:JudgeIsAddNewLevel(pcell, index)
    local data = self.currentRecipeData[index]
    local recipeId = tostring(data.recipeId)
    local growthTotal = checkint(data.growthTotal)
    if not  data.gradeId then
        return
    end
    local upgradeData =  self.upgradeRecipeLevelData[tostring(data.gradeId+1)]
    if self.redDotTable[tostring(self.presStyleTag)] then
        if self.redDotTable[tostring(self.presStyleTag)][recipeId] and growthTotal > 0 and upgradeData  and growthTotal >= checkint(upgradeData.sum)  then -- 检测数据
            pcell.levelupImage:setVisible(true)
        end
    end
end

--获取到具有新菜谱的数据
function RecipeResearchAndMakingMediator:getRedDotNofication()
    return gameMgr:GetUserInfo().recipeStylesRed or {}
end

function RecipeResearchAndMakingMediator:clearRedDotStatus(data)
    -- 设置红点的状态
    if not self.redDotTable[tostring(self.presStyleTag)] then
        return
    end
    app.badgeMgr:ClearUpgradeRecipeLevelAndNewRed(data.recipeId, self.presStyleTag)
end
-- 检查当前开发的菜谱是否圆满
function RecipeResearchAndMakingMediator:checkReseachStyleComplete()
    local styleData = self:GetStyleTable()
    local isComplete = true
    local isAllComplete = true
    for k, v in pairs(styleData) do
        if checkint( v.initial) ~= MAGIC_FOOD_STYLE then
            if gameMgr:GetUserInfo().cookingStyles[k] then
                if checkint(v.rewardsRecipe) + checkint(v.studyRecipe) > table.nums( gameMgr:GetUserInfo().cookingStyles[k]) then
                    isComplete = false
                end
            else
                isAllComplete = false
            end
        end
    end
    if isComplete and not isAllComplete then
        uiMgr:ShowInformationTips(__('当前菜系已开发完，请去专精解锁新的菜系'))
        return false
    end
    if isComplete and isAllComplete then
        uiMgr:ShowInformationTips(__('所有菜系已经开发完成'))
        return false
    end
    return true
end
-- 菜谱开发中
function RecipeResearchAndMakingMediator:updateResearchDevelopment()
    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
    viewData.cancelBtn:setVisible(true)
    viewData.quickBtn:setVisible(true)
    viewData.makingBtn:setVisible(false)
    viewData.rewardBtn:setVisible(false)
    local node = viewData.foodsBtns[2]:getChildByTag(111)
    if node then
        node:setVisible(true)
    end
    for i = 1, #viewData.foodsBtns do
        viewData.foodsBtns[i]:runAction(
        cc.Sequence:create(cc.MoveTo:create(0.1, cc.p(viewData.foodsBtnsPos[2])),
        cc.CallFunc:create(function()
            local node = viewData.foodsBtns[i]:getChildByTag(115)
            if node then
                viewData.foodsBtns[i]:removeChildByTag(115)
            end
            if i == 2 then
                local foodsSize = viewData.foodsBtns[2]:getContentSize()
                local image = display.newImageView(_res('ui/home/kitchen/cooking_study_ico_secret.png'), foodsSize.width / 2, foodsSize.height / 2)
                viewData.foodsBtns[2]:addChild(image)
                image:setTag(115)
            else
                viewData.foodsBtns[i]:setVisible(false)
            end
        end))
        )
    end
    self:ClearResearchRedDotBtn()
    viewData.foodsBtns[2]:runAction(cc.Repeat:create(
    cc.Sequence:create(
    cc.MoveBy:create(1, cc.p(0, -10) ), cc.MoveBy:create(1, cc.p(0, 10))
    ), math.ceil(app.cookingMgr:GetRecipeLeftSecodTime() / 2 ) ) )
    local fisrt = 0
    local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
    local node = btn:getChildByTag(112)
    node:setVisible(true)
    local countDowanLabel = node.countDownLabel
    local btnNameLabel = btn:getChildByTag(111)
    btnNameLabel:setVisible(false)
    local callback = function()
        fisrt = fisrt + 1
        local leftReseachTimes = app.cookingMgr:GetRecipeLeftSecodTime()
        local num = leftReseachTimes % 60
        leftReseachTimes = leftReseachTimes > 0 and leftReseachTimes or 0
        local numBei = math.ceil(  leftReseachTimes / 60 ) > 10 and 10 or math.ceil(  leftReseachTimes / 60 )
        if num == 0 or fisrt == 1 then
            display.reloadRichLabel(self.showLayerDataTable[tostring(BtnCollect.Research)].richLabel,
            { c = {
                fontWithColor('14', { text = tostring(numBei) }),
                { img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.15 }
            }
            }
            )
            local richLabel =  self.showLayerDataTable[tostring(BtnCollect.Research)].richLabel --  描边
            local nodeTable = richLabel:getChildren()
            if tolua.type(nodeTable[1]) == "ccw.CLabel" then
                local label = nodeTable[1]
                local params = nil
                if not  params then
                    params = {}
                    params.outline = "734441"
                    params.outlineSize = 1
                end
                local outlineSize = math.max(1, checkint(params.outlineSize))
                label:enableOutline(ccc4FromInt(params.outline), outlineSize)
            end
        end
        local timesTable = string.formattedTime(leftReseachTimes )
        local node = viewData.foodsBtns[2]:getChildByTag(111)
        if node then
            display.commonLabelParams(node, fontWithColor('10', { text = string.format( "%02d:%02d", timesTable.m, timesTable.s) }))
            display.commonLabelParams(countDowanLabel, fontWithColor('10', { text = string.format( "%02d:%02d", timesTable.m, timesTable.s) }))
        end
        if leftReseachTimes >= 0 then
            if numBei == 0 then
                --这个表是开发时间已经完成
                self:updateResearchViewDone()
            end
        end

    end
    callback()
    viewData.studyWordsLabel:setString( __("开发中..."))
    self.showLayerDataTable[tostring(BtnCollect.Research)].view:runAction(
    cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(callback)), app.cookingMgr:GetRecipeLeftSecodTime()) )
end
-- 菜谱开发完成
function RecipeResearchAndMakingMediator:updateResearchViewDone()
    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
    -- self.researchStatus = 1
    self.showLayerDataTable[tostring(BtnCollect.Research)].view:stopAllActions()
    if not viewData.foodsBtns[2]:getChildByTag(115) then
        local foodsSize = viewData.foodsBtns[2]:getContentSize()
        local image = display.newImageView(_res('ui/home/kitchen/cooking_study_ico_secret.png'), foodsSize.width / 2, foodsSize.height / 2)
        viewData.foodsBtns[2]:addChild(image)
        image:setTag(115)
    end
    for i = 1, #viewData.foodsBtns do
        if i == 2 then
            local node = viewData.foodsBtns[i]:getChildByTag(111)
            if node then
                node:getLabel():setString("00:00")
            end
        else
            viewData.foodsBtns[i]:setVisible(false)
        end
    end
    self:AddResearchRedDotBtn()
    local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
    local node = btn:getChildByTag(112)
    --local countDowanLabel = node.countDownLabel
    local researchLabel = node:getChildByTag(113)
    researchLabel:setString(__('开发完成'))
    local btnNameLabel = btn:getChildByTag(111)
    btnNameLabel:setVisible(false)
    --node:setVisible(false)
    viewData.studyWordsLabel:setString( __("开发完成..."))
    viewData.cancelBtn:setVisible(false)
    viewData.quickBtn:setVisible(false)
    viewData.makingBtn:setVisible(false)
    viewData.rewardBtn:setVisible(true)
end
-- 领取按钮和取消的时候应该做的时间
function RecipeResearchAndMakingMediator:updateCancelOrRewardResearchView()
    -- self.researchStatus = 0

    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
    viewData.foodsBtns[2]:stopAllActions()
    for i = 1, 3 do
        viewData.foodsBtns[i]:setScale(1)
        local node = viewData.foodsBtns[i]:getChildByTag(111)
        if node then
            node:setVisible(true)
        end
    end
    self:setRecipeMeterialLight()
    self:ClearResearchRedDotBtn()
    viewData.foodsBtns[2]:setPosition(cc.p(viewData.foodsBtnsPos[2]))
    display.commonLabelParams(viewData.foodsBtns[2]:getChildByTag(111), fontWithColor('16'))
    local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
    local node = btn:getChildByTag(112)
    node:setVisible(false)
    for i = 1, #viewData.foodsBtns do
        viewData.foodsBtns[i]:runAction(
        cc.Sequence:create(
        cc.CallFunc:create(function()
            viewData.foodsBtns[i]:setVisible(true)
            if viewData.foodsBtns[2]:getChildByTag(115) then
                viewData.foodsBtns[2]:removeChildByTag(115)
            end
            viewData.foodsBtns[i]:getChildByTag(111):getLabel():setString("")
        end ),
        cc.MoveTo:create(0.1, cc.p(viewData.foodsBtnsPos[i]))
        ))
    end
    local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
    local node = btn:getChildByTag(112)
    --local countDowanLabel = node.countDownLabel
    local researchLabel = node:getChildByTag(113)
    researchLabel:setString(__('开发中'))
    viewData.cancelBtn:setVisible(false)
    viewData.quickBtn:setVisible(false)
    viewData.makingBtn:setVisible(true)
    viewData.makingBtn:setOpacity(255)
    viewData.rewardBtn:setVisible(false)
    viewData.studyWordsLabel:setString( __('放入1~3种材料可以开发新美食'))
end

function RecipeResearchAndMakingMediator:updateStyleButtonsLayout()
    local viewData = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)]
    if viewData and self.recipeResearchAndMakingView then
        local styleLayout = viewData.styleLayout
        self.recipeResearchAndMakingView.styleTable = self:GetStyleTable()
        self.recipeResearchAndMakingView.styleBtns = {}
        self.recipeResearchAndMakingView:renderStyleButtonsLayout(styleLayout)
        for  k ,v in pairs( self.recipeResearchAndMakingView.styleBtns) do
            v:setTag(checkint(k))
            v:setOnClickScriptHandler(handler(self, self.switchRecipeStyle))
        end
    end
end

-- 开发动画
function RecipeResearchAndMakingMediator:recipeResearchAction()
    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
    --local btn = viewData.foodsBtns[1]
    local seqAction = cc.Sequence:create(
    cc.Spawn:create(
    cc.MoveBy:create(5 / 30, cc.p(-16, 0)),
    cc.ScaleTo:create(5 / 30, 1.07)
    ),
    cc.MoveBy:create(2 / 30, cc.p(3.1, 1.85)),
    cc.MoveBy:create(2 / 30, cc.p(-5.6, 1.49)),
    cc.MoveBy:create(2 / 30, cc.p(3.1, -3.09)),
    cc.MoveBy:create(2 / 30, cc.p(-0.6, 2.38)),
    cc.MoveBy:create(2 / 30, cc.p(3.1, 1.85)),
    cc.MoveBy:create(2 / 30, cc.p(-5.6, 1.24)),
    cc.MoveBy:create(2 / 30, cc.p(-3.1, -3.09)),
    cc.MoveBy:create(2 / 30, cc.p(-0.6, 2.48)),
    cc.Spawn:create(cc.ScaleTo:create(4 / 30, 0.4),
    cc.Sequence:create(
    cc.MoveBy:create(2 / 30, cc.p(82.5, 47.4)),
    cc.MoveBy:create(1 / 30, cc.p(41.25, -2.52)),
    cc.MoveTo:create(1 / 30, cc.p(viewData.foodsBtnsPos[2]))
    )
    )
    )
    local seqActionTwo = cc.Sequence:create(
    cc.ScaleTo:create(5 / 30, 1.2),
    cc.ScaleTo:create(2 / 30, 1.1),
    cc.ScaleTo:create(2 / 30, 1.2),
    cc.ScaleTo:create(2 / 30, 1.1),
    cc.ScaleTo:create(2 / 30, 1.2),
    cc.ScaleTo:create(2 / 30, 1.1),
    cc.ScaleTo:create(2 / 30, 1.2),
    cc.ScaleTo:create(2 / 30, 1.1),
    cc.ScaleTo:create(2 / 30, 1.2),
    cc.ScaleTo:create(4 / 30, 0.4)
    )
    local seqActionThree = cc.Sequence:create(
    cc.Spawn:create(
    cc.MoveBy:create(5 / 30, cc.p(12, 0)),
    cc.ScaleTo:create(5 / 30, 1.07)
    ),
    cc.MoveBy:create(2 / 30, cc.p(-2.5, 1.23)),
    cc.MoveBy:create(2 / 30, cc.p(3.7, -2.57)),
    cc.MoveBy:create(2 / 30, cc.p(-5.24, -3.71)),
    cc.MoveBy:create(2 / 30, cc.p(3.1, 4.95)),
    cc.MoveBy:create(2 / 30, cc.p(-2.5, 1.23)),
    cc.MoveBy:create(2 / 30, cc.p(3.7, -2.57)),
    cc.MoveBy:create(2 / 30, cc.p(-5.24, -3.71)),
    cc.MoveBy:create(2 / 30, cc.p(3.1, 4.95)),
    cc.Spawn:create(cc.ScaleTo:create(4 / 30, 0.4),
    cc.Sequence:create(
    cc.MoveBy:create(2 / 30, cc.p(-82.5, -40.4)),
    cc.MoveBy:create(1 / 30, cc.p(-41.25, -47.9)),
    cc.MoveTo:create(1 / 30, cc.p(viewData.foodsBtnsPos[2]))
    )
    )
    )
    local nextAction = cc.Sequence:create(
    cc.CallFunc:create(function()
        local node = viewData.foodsBtns[2]:getChildByTag(115)
        if node then
            viewData.foodsBtns[2]:removeChildByTag(115)
        end
        local foodsSize = viewData.foodsBtns[2]:getContentSize()
        local image = display.newImageView(_res('ui/home/kitchen/cooking_study_ico_secret.png'), foodsSize.width / 2, foodsSize.height / 2)
        viewData.foodsBtns[2]:addChild(image)
        image:setTag(115)
        viewData.foodsBtns[2]:getChildByTag(113):setVisible(true)
        viewData.foodsBtns[2]:setOpacity(100)
        viewData.foodsBtns[2]:runAction(cc.FadeTo:create(5 / 30, 255))
    end
    ),
    cc.ScaleTo:create(5 / 30, 1.5),
    cc.ScaleTo:create(5 / 30, 0.7),
    cc.ScaleTo:create(5 / 30, 1)
    )
    local allSeqAction = cc.Sequence:create(
    cc.CallFunc:create(function()
        for i = 1, 3 do
            local node = viewData.foodsBtns[i]:getChildByTag(111)
            local nodeTwo = viewData.foodsBtns[i]:getChildByTag(113)
            if node and nodeTwo then
                node:setVisible(false)
                nodeTwo:setVisible(false)
            end
        end
    end),
    cc.Spawn:create(
    cc.TargetedAction:create(viewData.foodsBtns[1], seqAction),
    seqActionTwo,
    cc.TargetedAction:create(viewData.foodsBtns[3], seqActionThree)
    ),
    nextAction,
    cc.CallFunc:create(function()
        self:updateResearchDevelopment()
    end)
    )
    viewData.foodsBtns[2]:runAction(allSeqAction)
    viewData.makingBtn:runAction(cc.FadeOut:create(2 / 30))
end
function RecipeResearchAndMakingMediator:Initial( key )
    self.super.Initial(self, key)
    if app.cookingMgr:isUninitCookingStyle() then
        local tag = 888
        local ArrangeSpecialStartView = require('Game.views.ArrangeSpecialStartView')
        local layer = ArrangeSpecialStartView.new()
        layer:setTag(tag)
        layer:setName('Game.views.ArrangeSpecialStartView')
        layer:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(layer)
        local delayTime = 1
        local isCloseAction = false
        layer:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), cc.CallFunc:create(function()
            isCloseAction = true
        end) ))
        layer.closeView:setOnClickScriptHandler(function()
            if isCloseAction then
                PlayAudioByClickClose()
                self:closeCurrentLayer(layer, false, true)
                GuideUtils.DispatchStepEvent()
            end
        end)
        self:SetViewComponent(layer)
    else
        self:addRecipeResearchAndMakingView()
    end
end
-- 关闭当前的界面 如果isMoveMediator 那么删除当前的mediator
-- isAdd 是否添加烹饪界面
-- isMoveMediator 是否移除当前的mediator
function RecipeResearchAndMakingMediator:closeCurrentLayer(layer, isAdd, isMoveMediator)
    -- body
    if layer.bgLayout then
        layer.bgLayout:runAction(
        cc.TargetedAction:create(layer,
        cc.Sequence:create(
        cc.CallFunc:create(
        function()
            if isMoveMediator then
                AppFacade.GetInstance():UnRegsitMediator(NAME)
            else
                if isAdd then
                    self:addRecipeResearchAndMakingView()
                end
            end

        end

        ),
        cc.RemoveSelf:create()
        ))
        )
    end
end
--添加菜谱研究和专精界面
function RecipeResearchAndMakingMediator:addRecipeResearchAndMakingView()
    local tag = 888
    local RecipeResearchAndMakingView = require('Game.views.RecipeResearchAndMakingView')
    local layer = RecipeResearchAndMakingView.new()
    layer:setTag(tag)
    layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)
    self.recipeResearchAndMakingView = layer
    self.recipeResearchAndMakingView.closeBtn:setOnClickScriptHandler(
    function()
        PlayAudioByClickClose()
        self:closeCurrentLayer(layer, false, true)
        GuideUtils.DispatchStepEvent()
    end
    )
    self.recipeResearchAndMakingView.closeView:setOnClickScriptHandler(
    function()
        PlayAudioByClickClose()
        self:closeCurrentLayer(layer, false, true)
        GuideUtils.DispatchStepEvent()
    end
    )
    for k, v in pairs(layer.collectBtn) do
        v:setOnClickScriptHandler(handler(self, self.research_Special_make))
    end
    self:SetViewComponent(self.recipeResearchAndMakingView)
    if self.presStyleTag ~= BtnCollect.Research then
        self:research_Special_make(self.recipeResearchAndMakingView.collectBtn[tostring(self.presStyleTag)])
    end

end
-- 用于检测是否 RecipeDeatailView 的位置以及所要做的运动
function RecipeResearchAndMakingMediator:recoverRecipeDeatailViewPos(isTrue)
    local isImproveRecipe = true
    if self.preClickTag  ~= BtnCollect.ImprovedRecipe and  self.preClickTag ~= BtnCollect.MagicStyle then
        isImproveRecipe = false
        if self.preRcipeCell then
            self.preRcipeCell.selectImage:setVisible(false)
            self.preRcipeCell = nil
            self.preRecipeClickTag = nil
        end
    end
    local recipeDetailMediator = app:RetrieveMediator("RecipeDetailMediator")
    local recipeReminderMediator = app:RetrieveMediator("RecipeReminderMediator")
    local recipeReminderView = nil
    local recipeDetailView = nil
    if recipeReminderMediator then
        recipeReminderView = recipeReminderMediator:GetViewComponent()
    end
    if recipeDetailMediator then
        recipeDetailView = recipeDetailMediator:GetViewComponent()
    end
    local spawnTable = {}
    if self.preClickTag  == BtnCollect.ImprovedRecipe  or  self.preClickTag == BtnCollect.MagicStyle  then
        if recipeReminderView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeReminderView , cc.Sequence:create(cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.2, display.center)), cc.Hide:create()) )
        end
        if recipeDetailView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeDetailView , cc.Sequence:create(cc.Show:create(), cc.Spawn:create(cc.FadeIn:create(0.2), cc.MoveTo:create(0.2, cc.p(display.cx - 90, display.cy))) ) )
            spawnTable[#spawnTable+1] = cc.MoveTo:create(0.2, cc.p(display.cx + 285, display.cy))
        else
            spawnTable[#spawnTable+1] = cc.MoveTo:create(0.2,display.center)
        end
    elseif self.preClickTag  == BtnCollect.Research then
        if not  recipeReminderView then
            local data = {}
            local styleType = self:makeSureReserchStyle()
            data.layer =  self.recipeResearchAndMakingView
            data.styleType =  styleType
            recipeReminderMediator = require("Game.mediator.RecipeReminderMediator").new(data)
            app:RegistMediator(recipeReminderMediator)
            recipeReminderView = recipeReminderMediator:GetViewComponent()
        end 
        if recipeReminderView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeReminderView , cc.Sequence:create(cc.Show:create(), cc.Spawn:create(cc.FadeIn:create(0.2), cc.MoveTo:create(0.2, cc.p(display.cx - 65, display.cy))) ) )
        end
        if recipeDetailView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeDetailView , cc.Sequence:create(cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.2, display.center)), cc.Hide:create()) )
        end
        spawnTable[#spawnTable+1] = cc.MoveTo:create(0.2, cc.p(display.cx + 285, display.cy))
    else
        if recipeReminderView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeReminderView , cc.Sequence:create(cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.2, display.center)), cc.Hide:create()) )
        end
        if recipeDetailView  then
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(recipeDetailView , cc.Sequence:create(cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.2, display.center)), cc.Hide:create()) )
        end
        spawnTable[#spawnTable+1] = cc.MoveTo:create(0.2,display.center)
    end
    self.recipeResearchAndMakingView.bgLayout:runAction(cc.Spawn:create(spawnTable))
end
-- 烹饪界面三大模块的切换
function RecipeResearchAndMakingMediator:research_Special_make(sender)
    -- body
    local tag = sender:getTag()
    if self.preClickTag then
        PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
    end

    if tag == BtnCollect.Research and (not CommonUtils.UnLockModule(RemindTag.RESEARCH, true) ) then
        sender:setChecked(false)
        return
    end
    if self.preClickTag then
        if tag == self.preClickTag then
            return
        else
            local checkBox = self.recipeResearchAndMakingView.collectBtn[tostring(self.preClickTag)]
            checkBox:setEnabled(true)
            checkBox:setChecked(false)
            local tag  = self.preClickTag
            if tag == BtnCollect.MagicStyle then
                tag = BtnCollect.ImprovedRecipe
            end
            if self.showLayerDataTable[tostring(tag)] then
                self.showLayerDataTable[tostring(tag)].view:setVisible(false)
            end
            local label = checkBox:getChildByTag(111)
            if tag == BtnCollect.Research then
                --开发因为有倒计时 这里面要添加一下判断的
                local isChange = true
                if isChange then

                    label:setColor(ccc3FromInt("#2b2017"))
                end
            else
                label:setColor(ccc3FromInt("#2b2017"))
            end
        end
    end
    self.preClickTag = tag
    sender:setEnabled(false)
    sender:setChecked(true)
    local label = sender:getChildByTag(111)
    self:recoverRecipeDeatailViewPos()
    label:setColor(ccc3FromInt("#e0491a"))
    --local showTag =  tag
    if self.showLayerDataTable[tostring(tag)] then

        self.showLayerDataTable[tostring(tag)].view:setVisible(true)
        GuideUtils.DispatchStepEvent()
        if tag == BtnCollect.ImprovedRecipe then
            local btn =  self.recipeResearchAndMakingView.styleBtns[tostring(self.preNowTag)]
            if( not btn) or  tolua.isnull(btn) then
                local recipeStyle = ALL_RECIPE_STYLE
                --self:makeSureReserchStyle()
                btn = self.recipeResearchAndMakingView.styleBtns[tostring(recipeStyle)]
            end
            self:switchRecipeStyle(btn)
        elseif tag == BtnCollect.Research then -- 切换之后 做菜 还是获取数据 都要刷新的 没有刷新

            self.foodMaterialData = {}
            self.foodMaterialData = self:getFoodMaterialData()
            local viewData =  self.showLayerDataTable[tostring(BtnCollect.Research)]
            viewData.foodGridView:setCountOfCell(table.nums(self.foodMaterialData ))
            viewData.foodGridView:reloadData()
        end
    else
        local viewData = nil
        if tag == BtnCollect.ImprovedRecipe then
            local styleData = app.cookingMgr:getResearchStyleTable()
            viewData = self.recipeResearchAndMakingView:createMakeLayout(self.recipeResearchAndMakingView.leftLayoutSize ,styleData )
            self.showLayerDataTable[tostring(tag)] = viewData
            self.recipeResearchAndMakingView:addShowLayer(viewData.view, 4)
            self:buildingMakeLayoutStylesAndOthesButton()
            viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
            
            -- 餐厅活动开启 并且 拥有餐厅活动所需的菜谱 并且 不是引导状态
            local recipeStyle =nil
            if  not self.recipeStyle then
                recipeStyle = app.activityMgr:isDefaultSelectFestivalMenu() and FESTIVAL_RECIPE_STYLE or ALL_RECIPE_STYLE
            else
                recipeStyle = self.recipeStyle
            end


            local btn = self.recipeResearchAndMakingView.styleBtns[tostring(recipeStyle)]
            self.showLayerDataTable[tostring(tag)].styleSwallowLayer:setOnClickScriptHandler(handler(self ,self.SetStyleLayoutStatus))
            self.redDotTable = self:getRedDotNofication()
            self:addRedDotToBtn()
            self:switchRecipeStyle(btn)
            self:setcountDownLabelStatus()
        elseif tag == BtnCollect.Research then
            -- 不满足开发直接返回

            viewData = self.recipeResearchAndMakingView:researchLayout(self.recipeResearchAndMakingView.leftLayoutSize)
            self.recipeResearchAndMakingView:addShowLayer(viewData.view)
            self.foodMaterialData = self:getFoodMaterialData()
            viewData.foodGridView:setCountOfCell(table.nums(self.foodMaterialData ))
            viewData.foodGridView:setDataSourceAdapterScriptHandler(handler(self, self.onFoodsDataSourceAction))
            viewData.foodGridView:reloadData()
            for i = 1, #viewData.foodsBtns do
                viewData.foodsBtns[i]:setTag(20000 + i)  -- 这里面的减少按钮害怕重复 所以加上了个 20000
                viewData.foodsBtns[i]:setOnClickScriptHandler(handler(self, self.reduceFoodMaterial))
            end
            -- 注册事件
            viewData.searchBtn:setOnClickScriptHandler(function (sender)
                local styleType = self:makeSureReserchStyle()
                local view = require("Game.views.RecipeStyleKindsDetailView").new({ styleType = styleType })
                local isTrue = true
                view:setPosition(display.center)
                view.viewData.eaterLayer:setOnClickScriptHandler(
                function()
                    if isTrue then
                        self:closeCurrentLayer(view, false, false)
                        isTrue = false
                    end
                end
                )
                uiMgr:GetCurrentScene():AddDialog(view)

            end)
            viewData.handbookBtn:setOnClickScriptHandler(function (sender)
                PlayAudioByClickNormal()
                local FoodMaterialHandbookMediator = require("Game.mediator.FoodMaterialHandbookMediator")
                local mediator = FoodMaterialHandbookMediator.new()
                self:GetFacade():RegistMediator(mediator)
            end)

            viewData.makingBtn:setOnClickScriptHandler(handler(self, self.sendResearchSingalClick))
            viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.sendResearchSingalClick))
            viewData.quickBtn:setOnClickScriptHandler(handler(self, self.sendResearchSingalClick))
            viewData.cancelBtn:setOnClickScriptHandler(handler(self, self.sendResearchSingalClick))
            self.showLayerDataTable[tostring(tag)] = viewData
            self:RefreshResearhViewCollectLabel()

            local leftReseachTimes = app.cookingMgr:GetRecipeLeftSecodTime()
            if leftReseachTimes and leftReseachTimes ~= -1 then
                if leftReseachTimes > 0 then
                    self:updateResearchDevelopment()
                elseif leftReseachTimes == 0 then
                    self:updateResearchViewDone()
                end
            end
            GuideUtils.DispatchStepEvent()
        elseif tag == BtnCollect.Specialization then
            viewData = self.recipeResearchAndMakingView:createSpecialLayout(self.recipeResearchAndMakingView.leftLayoutSize)
            self.recipeResearchAndMakingView:addShowLayer(viewData.view)
            self.showLayerDataTable[tostring(tag)] = viewData
            local isSpread = false
            local styleData = app.cookingMgr:getResearchStyleTable()
            local sortStyleData = {}
            local style  =  self:makeSureReserchStyle()
            for k  , v in pairs(styleData) do
                if checkint(k) == checkint(style) then
                    table.insert(sortStyleData,1 ,k)
                else
                    table.insert(sortStyleData,#sortStyleData+1,k)
                end
            end
            for k, v in pairs(self.recipeResearchAndMakingView.styleTable) do
                if checkint( self.recipeResearchAndMakingView.styleTable[k].initial) ~= MAGIC_FOOD_STYLE   and  checkint(k) ~= checkint(ALL_RECIPE_STYLE)   then
                    if not  gameMgr:GetUserInfo().cookingStyles[tostring(v.id)]  then
                        table.insert(sortStyleData,#sortStyleData+1 ,k)

                    end
                end
            end
            for i =1 ,#sortStyleData do
                local k = tostring(sortStyleData[i])
                if   checkint(k) ~= checkint(ALL_RECIPE_STYLE) and checkint(k) ~=  checkint(FESTIVAL_RECIPE_STYLE) then
                    local v = self.recipeResearchAndMakingView.styleTable[k]
                    local cell = self.recipeResearchAndMakingView:createSpecialCell(v)
                    cell.contentLayer:setOnClickScriptHandler(handler(self, self.specialDetailCheck))
                    if not isSpread then
                        if gameMgr:GetUserInfo().cookingStyles[tostring(cell.id)] and styleData[k] then
                            if not isSpread then
                                isSpread = true
                                self:specialDetailCheck(cell.contentLayer)
                            end
                        end
                    end
                    self.showLayerDataTable[tostring(tag)].listView:insertNodeAtLast(cell)

                end
            end
            self:setVisibleOrFalseUnLockBtn()
            self.showLayerDataTable[tostring(tag)].listView:reloadData()

        elseif tag == BtnCollect.MagicStyle  then
            if not  self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)] then
                local styleData = app.cookingMgr:getResearchStyleTable()
                viewData = self.recipeResearchAndMakingView:createMakeLayout(self.recipeResearchAndMakingView.leftLayoutSize , styleData)
                self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)] = viewData
                self.recipeResearchAndMakingView:addShowLayer(viewData.view, 4)
                self:buildingMakeLayoutStylesAndOthesButton()
                viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
                self.redDotTable = self:getRedDotNofication()
                self:addRedDotToBtn()
                self:setcountDownLabelStatus()
            end
            self:switchRecipeStyle(sender)
            self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].view:setVisible(true)
        end
    end
end

-- 返回食材表
function RecipeResearchAndMakingMediator:getFoodMaterialData( )
    local temp_data = {}
    for k, item in pairs(gameMgr:GetUserInfo().backpack) do
        local data = CommonUtils.GetConfig('goods', 'goods', item.goodsId)
        if data then
            if checkint(data.type) == checkint(GoodsType.TYPE_FOOD_MATERIAL ) then
                if checkint(item.goodsId ) >= 169001 and checkint(item.goodsId ) <= 169999 then
                    --排除掉魔法的食物
                else
                    table.insert(temp_data, (#temp_data + 1), item)
                end
            end
        end
    end
    local foodMaterialData = CommonUtils.GetConfigAllMess('foodMaterial', 'goods')
    -- 给菜谱排序
    table.sort(temp_data, function( a, b)
        local aData = foodMaterialData[tostring(a.goodsId)]
        local bData = foodMaterialData[tostring(b.goodsId)]
        if checkint(aData.order) < checkint(bData.order) then
            return true
        else
            return false
        end
    end)

    return temp_data
end
--获取材料的Index
--[[
    consumeFoodMeterialData = {
        {
            index =  -- 所在的顺序
            goodsId = -- 对应的goodsId
        }



    }
--]]
function RecipeResearchAndMakingMediator:GetMakeFoodMaterialIndex(tag)
    local index = 0
    local count  = table.nums(self.consumeFoodMeterialData)
    local data = nil
    for i =1 , count do
        data = self.consumeFoodMeterialData[i]
        if tag == data.index then
            index = i
        end
    end
    return index
end
-- 根据Id 获取材料的位置
function RecipeResearchAndMakingMediator:GetFoodMaterialIndexById(goodsId)
    local count = table.nums(self.foodMaterialData)
    local data  = nil
    local index = 0
    goodsId = checkint(goodsId)
    for i = 1, count do
        data = self.foodMaterialData[i]
        if checkint(data.goodsId) == goodsId then
            index = i
            break
        end
    end
    return index
end
-- 扫荡材料的时候 矫正显示
function RecipeResearchAndMakingMediator:CheckMakeFoodMaterialIndex()
    local count = table.nums(self.consumeFoodMeterialData)
    local index = nil
    local data = nil
    local isChange = false
    for i =1 , count do
        data = self.consumeFoodMeterialData[i]
        index  =  data.index
        -- 防止数据超出
        if self.foodMaterialData[index] then
            if checkint(self.foodMaterialData[index].goodsId) == checkint(data.goodsId) then
            else
                isChange = true
                index =   self:GetFoodMaterialIndexById(data.goodsId)
                data.index = index
            end
        end
    end
    if isChange then --发生了改变 直接刷新 界面
        self:DisPlayFoodsBtnStatus()
    end
end
-- 添加食材
function RecipeResearchAndMakingMediator:addOrReduceFoodMaterial(sender)
    PlayAudioByClickNormal()
    local leftReseachTimes = app.cookingMgr:GetRecipeLeftSecodTime()
    if leftReseachTimes > 0 or self.cookingStyleId then
        uiMgr:ShowInformationTips(__('菜品正在开发中'))
        return
    end
    local tag = sender:getTag()
    local index =  self:GetMakeFoodMaterialIndex(tag)
    if index > 0  then
        self:reduceFoodBtns(index)
    else
        self:addFoodBtns(tag)
    end
    self:DisPlayFoodsBtnStatus()
    self:checkAdaptiveRecipe()
    self:setRecipeMeterialLight()
    GuideUtils.DispatchStepEvent()
end
--减少button里面的资源
function RecipeResearchAndMakingMediator:reduceFoodBtns(index)
    local data =  self.consumeFoodMeterialData[index]
    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research) ]
    local gridView = viewData.foodGridView
    local cell = gridView:cellAtIndex(data.index -1)
    if cell and  cell.selectImg and ( not  tolua.isnull( cell.selectImg)) then
        cell.selectImg:setVisible(false)
    end
    table.remove(self.consumeFoodMeterialData , index)

end
-- 根据数据显示 UI
function RecipeResearchAndMakingMediator:DisPlayFoodsBtnStatus()
    local maxCount = 3
    local foodBtns = self.showLayerDataTable[tostring(BtnCollect.Research)].foodsBtns
    local foodBtnSize = foodBtns[1]:getContentSize()
    local isVisible = false
    local index = nil
    for i =1 , maxCount do
        local data = self.consumeFoodMeterialData[i]
        isVisible = data and true or false
        if isVisible then
            index = data.index
            if self.foodMaterialData[index] then
                local goodsId =  self.foodMaterialData[index].goodsId
                local image = foodBtns[i]:getChildByTag(115)
                local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
                if image and not tolua.isnull(image) then
                    image:setVisible(isVisible)
                    image:setTexture(iconPath)
                else
                    image = display.newImageView(iconPath, foodBtnSize.width / 2, foodBtnSize.height / 2)
                    image:setTag(115)
                    foodBtns[i]:addChild(image)
                end
                image:setScale(0.5)
                local data = CommonUtils.GetConfig('goods', 'goods', self.foodMaterialData[index].goodsId)
                if foodBtns[i].foodsBtn then
                    local startPos, endPos = string.find( data.name, "（.*）" )
                    if startPos then
                        local name = string.sub(data.name, 1, startPos - 1 )
                        foodBtns[i].foodsBtn:getLabel():setString(name )

                    else
                        foodBtns[i].foodsBtn:getLabel():setString(data.name )
                    end
                    if  display.getLabelContentSize(foodBtns[i].foodsBtn:getLabel()).height > 45  then
                        display.commonLabelParams(foodBtns[i].foodsBtn, {reqH = 45 , fontSize = 15})
                    else
                        display.commonLabelParams(foodBtns[i].foodsBtn, {reqH = 45 , fontSize = 20})
                    end

                end


            end
        else
            local image = foodBtns[i]:getChildByTag(115)
            if image and not  tolua.isnull(image) then
                image:setVisible(isVisible)
            end
            if foodBtns[i].foodsBtn then
                foodBtns[i].foodsBtn:getLabel():setString("")
            end
        end

    end

end

--添加图片的资源
function RecipeResearchAndMakingMediator:addFoodBtns(index)
    local count = table.nums(self.consumeFoodMeterialData)
    -- 满足三个删除第一个位置
    if count == 3 then
        self:reduceFoodBtns(1)
    end
    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research) ]
    local gridView = viewData.foodGridView
    local cell =  gridView:cellAtIndex(index-1)
    local data = {}
    if cell and not  tolua.isnull(cell) then
        data.index = index
        data.goodsId = self.foodMaterialData[index].goodsId
        cell.selectImg:setVisible(true)
    end
    table.insert(self.consumeFoodMeterialData  ,#self.consumeFoodMeterialData+1 ,data)

end
-- 该方法用于食材光圈的外发光设置
function RecipeResearchAndMakingMediator:setRecipeMeterialLight()
    local foodBtns = self.showLayerDataTable[tostring(BtnCollect.Research)].foodsBtns
    local count = table.nums(self.consumeFoodMeterialData)
    for i = 1, #foodBtns do
        if count >= i  then
            foodBtns[i]:getChildByTag(113):setVisible(true)
        else
            foodBtns[i]:getChildByTag(113):setVisible(false)
        end
    end
 --DSSF
end
--==============================--
--desc:该方法适用于检测是否已经匹配了已经存现在的菜谱
--time:2017-06-20 11:15:15
-- 该表的匹配规则是 goodsId_Num_  按照顺序排列
--@return
--==============================--
function RecipeResearchAndMakingMediator:checkAdaptiveRecipe()
    local data = {}
    for kk, v in pairs(self.consumeFoodMeterialData) do
        local k = v.index
        if self.foodMaterialData[checkint(k)]  then -- 检测该数据是否存在
            data[#data + 1] = checkint(self.foodMaterialData[checkint(k)].goodsId)
        end
    end
    table.sort( data, function(a, b)
        if a < b then
            return true
        else
            return false
        end
    end )
    local str = ""
    for i = 1, #data do
        str = str .. data[i] .. "_" .. "1" .. "_"
    end

    local recipeStyle = self:makeSureReserchStyle()
    local adapterData = self.recipeStudyFormulaData[tostring(recipeStyle)]
    if adapterData then
        local recipeId = checkint(adapterData[str])
        if recipeId then
            local recipeKindsOfData = gameMgr:GetUserInfo().cookingStyles[tostring(recipeStyle)] or { }
            for i = 1, #recipeKindsOfData do
                if recipeId == checkint(recipeKindsOfData[i].recipeId) then
                    local studyBgBtnTips = self.showLayerDataTable[tostring(BtnCollect.Research)].studyBgBtnTips
                    studyBgBtnTips:stopAllActions()
                    studyBgBtnTips:setVisible(false)
                    studyBgBtnTips:setScale(0.2)
                    studyBgBtnTips:setVisible(true)
                    studyBgBtnTips:getLabel():setString(__('注意本次开发不会出现新的食物!!!'))
                    studyBgBtnTips:runAction(
                    cc.Sequence:create( cc.ScaleTo:create(0.1, 1.2),
                    cc.ScaleTo:create(0.05, 1.1), cc.DelayTime:create(2),
                    cc.CallFunc:create(
                    function( )
                        studyBgBtnTips:setVisible(false)
                    end
                    )
                    )
                    )
                    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
                    viewData.makingBtn:setEnabled(false)
                    break
                else
                    local viewData = self.showLayerDataTable[tostring(BtnCollect.Research)]
                    viewData.makingBtn:setEnabled(true)
                end
            end
        end
    end
end
-- 减少食材
function RecipeResearchAndMakingMediator:reduceFoodMaterial(sender)
    --local image = sender:getChildByTag(115)
    local tag = sender:getTag()
    local index  =  tag - 20000
    local count = table.nums(self.consumeFoodMeterialData)
    if count >=index then
        self:reduceFoodBtns(index)
    else
        uiMgr:ShowInformationTips(__("请添加食材~"))
    end
    self:DisPlayFoodsBtnStatus()
    self:checkAdaptiveRecipe()
    self:setRecipeMeterialLight()
end
--==============================--
--desc:用于收集稀有菜谱的
--time:2017-06-28 01:49:15
--@recipeType: 菜谱的风格
--@canStudyUnlock: 菜谱是否可以研发解锁 0 为可以研发 1为不可以开发
--@return
--==============================--
function RecipeResearchAndMakingMediator:getRecipeTypeByData(recipeType, canStudyUnlock)
    local data = {}
    local recipeAllData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    for k, v in pairs( gameMgr:GetUserInfo().cookingStyles[tostring(canStudyUnlock)]) do
        local recipeData = recipeAllData[tostring(v.recipeId)]
        if checkint(recipeData.canStudyUnlock) == checkint(recipeType) then
            data[#data + 1] = clone(recipeData)
        end
    end
    return data
end
-- 返回能制作菜谱的总数量
function RecipeResearchAndMakingMediator:GetMakeRcipeStyles()
    local styleData = self:GetStyleTable()
    local countNum = 0
    for k , v in pairs(styleData) do
        if checkint(v.studyRecipe) > 0  then
            countNum = countNum +1
        end
    end
    return countNum
end
--- 确定当前可以制作的菜谱系列
function RecipeResearchAndMakingMediator:getResearchStyleTable()
    local styleData = self:GetStyleTable()
    --local recipeAllData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local recipeStyleTable  = {}
    for k , v in pairs( gameMgr:GetUserInfo().cookingStyles) do
        if checkint(styleData[k].initial) ~=  MAGIC_FOOD_STYLE then
            -- 排除掉魔法菜谱 求他的是可以制作的菜谱系列
            for kk , vv in pairs(v) do
                recipeStyleTable[tostring(k)] = true
                break

            end
        end
    end
    return recipeStyleTable
end

function RecipeResearchAndMakingMediator:GetStyleTable()
    return app.cookingMgr:GetStyleTable()
end
-- 确定开发的类型
function RecipeResearchAndMakingMediator:makeSureReserchStyle()

    local recipeStyle = 1
    local isLock = true
    local styleData = self:GetStyleTable()
    local countNum = 0
    if gameMgr:GetUserInfo().cookingStyles then
        -- 检测是否符合下次开锁条件
        local recipeStyleTable = app.cookingMgr:getResearchStyleTable()
        for k, v in pairs(gameMgr:GetUserInfo().cookingStyles) do
            if  recipeStyleTable[tostring(k)] and checkint(styleData[tostring(k)].studyRecipe) > 0   then
                countNum = countNum + 1
                local recipeKindsData = self:getRecipeTypeByData(1, k) -- 选取该系列已经的研发菜谱
                local allRecipeNum = checkint(styleData[k].studyRecipe)
                if allRecipeNum > table.nums(recipeKindsData) then
                    isLock = false
                    recipeStyle = checkint(k)
                    break
                end
            end
        end
    end
    if isLock then
        -- 菜谱研究判断是
        local selectNum = 0
        if countNum == 1 then
            selectNum = 1
        else
            --local allCountNum = self:GetMakeRcipeStyles()
            if  countNum  > 1 then
                selectNum = math.random(countNum ) --当你的菜谱选择满的时候，研究的时候随机给一个菜系
            end

        end
        local Num = 0
        for k, v in pairs( gameMgr:GetUserInfo().cookingStyles) do
            if (checkint(styleData[k].studyRecipe ) >  0) then -- 修改判断条件 只要是研究解锁 就说明是可以研究的菜系
                Num = Num + 1
                if Num == selectNum then
                    recipeStyle = checkint(k)
                end
            end
        end
    end
    return recipeStyle
end
-- 发送开发的命令时间
function RecipeResearchAndMakingMediator:sendResearchSingalClick(sender)
    local tag = sender:getTag()
    PlayAudioByClickNormal()

    if tag == BtnCollect.RESEARCH_RSEARCH then
        if not self:checkReseachStyleComplete() then
            return
        end
        if app.cookingMgr:GetRecipeLeftSecodTime() > 0  then  -- 正在开发中直接返回
            return
        end
        if table.nums(self.consumeFoodMeterialData) == 0 then
            uiMgr:ShowInformationTips(__('请添加食材~'))
        else
            local data = {}
            if self.cookingStyleId then
                data.cookingStyleId = self.cookingStyleId
            else
                self.cookingStyleId = self:makeSureReserchStyle()  --记录当前研究的菜系品质
                data.cookingStyleId = self.cookingStyleId
            end
            self.nowRecipeResearchCookingStyle = data.cookingStyleId
            data.material = {}
            for kk, v in pairs(self.consumeFoodMeterialData) do
                local k = v.index
                if self.foodMaterialData[checkint(k)] and  self.foodMaterialData[checkint(k)].goodsId then
                    data.material[ tostring(self.foodMaterialData[checkint(k)].goodsId)] = 1
                end
            end
            data.material = json.encode(data.material)
            self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Callback, data)
        end
    elseif tag == BtnCollect.RESEARCH_QUCIK then
        local needConusumDiamond = math.ceil(  app.cookingMgr:GetRecipeLeftSecodTime() / 60 )
        needConusumDiamond = needConusumDiamond > 10 and 10 or needConusumDiamond
        local diamondNum = gameMgr:GetUserInfo().diamond

        if checkint(diamondNum) >= checkint(needConusumDiamond) then
            --  判断幻晶石是否足够
            local CommonTip = require( 'common.CommonTip' ).new(
                {
                    text = __('是否要加快进度?'), descr = string.format(__('此项操作将会扣除您%d幻晶石!'), needConusumDiamond),
                    callback = function()
                        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Accelertate_Callback, { cookingStyleId = self.cookingStyleId })
                    end
                }
            )
            CommonTip:setPosition(display.center)
            local scene = uiMgr:GetCurrentScene()
            scene:AddDialog(CommonTip, 10)
        else
            if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showDiamonTips()
            else
                uiMgr:ShowInformationTips(__('幻晶石数量不足！！！'))
            end
        end
        GuideUtils.DispatchStepEvent()
    elseif tag == BtnCollect.RESEARCH_CANCEL then
        local CommonTip = require( 'common.CommonTip' ).new(
        { text = __('确定取消吗?'), descr = string.format(__('取消开发将不退还食材，是否确定取消?'), needConusumDiamond),
            callback = function()
                self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Cancel_Callback, { cookingStyleId = self.cookingStyleId })
            end
        })
        CommonTip:setPosition(display.center)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(CommonTip, 10)
    elseif tag == BtnCollect.RESEARCH_REWARD then
        self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Draw_Callback, { cookingStyleId = self.cookingStyleId })
    end
end
-- 研发所处的gradview
function RecipeResearchAndMakingMediator:onFoodsDataSourceAction(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(108, 115)
    if self.foodMaterialData and index <= table.nums(self.foodMaterialData) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.foodMaterialData[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self, self.addOrReduceFoodMaterial))
            if index <= 15 then
                pCell.eventnode:setPositionY(sizee.height - 800)
                pCell.eventnode:runAction(
                cc.Sequence:create(cc.DelayTime:create(index * 0.01),
                cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width * 0.5, sizee.height * 0.5)), 0.2))
                )
            else
                pCell.eventnode:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
            end
        else

            pCell.selectImg:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
        end
        xTry(function()
            local quality = 1
            if data then
                if data.quality then
                    quality = data.quality
                end
            end
            local drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(quality) .. '.png')
            local fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
            if not utils.isExistent(drawBgPath) then
                drawBgPath = _res('ui/common/common_frame_goods_' .. tostring(1) .. '.png')
                fragmentPath = _res('ui/common/common_ico_fragment_' .. tostring(quality) .. '.png')
            end
            pCell:setName("1")
            pCell.fragmentImg:setTexture(fragmentPath)
            pCell.toggleView:setNormalImage(drawBgPath)
            pCell.toggleView:setSelectedImage(drawBgPath)
            pCell.toggleView:setTag(index)
            pCell.toggleView:setScale(0.92)
            pCell:setTag(index)

            if data then
                pCell.fragmentImg:setVisible(false)
            else
                pCell.fragmentImg:setVisible(false)
            end
            pCell.numLabel:setString(tostring(self.foodMaterialData[index].amount))
            local node = pCell.toggleView:getChildByTag(111)
            if node then
                node:removeFromParent()
            end
            local goodsId = self.foodMaterialData[index].goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
            local sprite = display.newImageView(_res(iconPath), 0, 0, { as = false })
            sprite:setScale(0.55)
            local index = self:GetMakeFoodMaterialIndex(index)
            if index > 0  then
                pCell.selectImg:setVisible(true)
            else
                pCell.selectImg:setVisible(false)
            end
            local lsize = pCell.toggleView:getContentSize()
            sprite:setPosition(cc.p(lsize.width * 0.5, lsize.height * 0.5))
            sprite:setTag(111)
            pCell.toggleView:addChild(sprite)

        end, __G__TRACKBACK__)
        return pCell
    end
end
--专精详情查看
function RecipeResearchAndMakingMediator:specialDetailCheck(sender)
    PlayAudioByClickNormal()
    local cell = sender:getParent()
    local tag = checkint(cell.id)
    local bgSize = sender:getContentSize()
    if gameMgr:GetUserInfo().cookingStyles[tostring(cell.id)] then
        if self.preStyleCell then
            if tag == self.presStyleDetailTag then
                local detailLayout = self.preStyleCell:getChildByTag(111)
                if detailLayout then
                    cell:runAction(cc.Sequence:create(
                    cc.TargetedAction:create(detailLayout, cc.RemoveSelf:create()),
                    cc.CallFunc:create(function()
                        cell:setContentSize(bgSize)
                        cell.selectImage:setVisible(true)
                        cell.contentLayer:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
                        self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:reloadData()
                    end)
                    ))
                else
                    self.recipeResearchAndMakingView:createSpecialSelect(cell)
                    cell.selectImage:setVisible(true)
                    cell.spearSearchBtn:setOnClickScriptHandler(handler(self, self.switchRecipeFunction))
                    self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:reloadData()
                end
                return
            else
                local cell = self.preStyleCell
                local detailLayout = self.preStyleCell:getChildByTag(111)
                if detailLayout then
                    cell:setContentSize(bgSize)
                    cell.contentLayer:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
                    self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:reloadData()
                    self.recipeResearchAndMakingView:runAction(cc.Sequence:create(
                    cc.TargetedAction:create(detailLayout, cc.RemoveSelf:create()),
                    cc.CallFunc:create(function()
                        cell.selectImage:setVisible(true)
                        cell:setContentSize(bgSize)
                        cell.contentLayer:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
                        self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:reloadData()
                    end)
                    ))
                end
            end
        end
        self.presStyleDetailTag = tag
        self.preStyleCell = cell
        self.preStyleCell.selectImage:setVisible(true)
        self.recipeResearchAndMakingView:createSpecialSelect(cell)
        cell.spearSearchBtn:setOnClickScriptHandler(handler(self, self.switchRecipeFunction))
        self.showLayerDataTable[tostring(BtnCollect.Specialization)].listView:reloadData()
    else
        if gameMgr:GetUserInfo().cookingStyles then
            local isLock = true  -- 检测是否符合下次开锁条件
            for k, v in pairs(gameMgr:GetUserInfo().cookingStyles) do
                local data = self:GetStyleTable()
                local isJump = (checkint(data[k].initial ) ~= MAGIC_FOOD_STYLE and true) or false  -- 判断当前菜谱是否是魔法菜谱
                if isJump then
                    local allRecipeNum = checkint(data[k].studyRecipe)
                    local recipeHaveKindsData = self:getRecipeTypeByData(1, k)  -- 判断研究菜谱是否足够
                    if checkint(k) ~= checkint(DISABLE_EDITBOX_MEDIATOR) then
                        if allRecipeNum > table.nums(recipeHaveKindsData) then
                            isLock = false
                            break
                        end
                    end
                end
            end
            if isLock then
                local CommonTip = require( 'common.CommonTip' ).new({ text = __('确定解锁新菜谱?'), descr = string.format(__('解锁后将一直开发新菜谱 !'), needConusumDiamond), callback = function()
                    self:GetFacade():DispatchObservers('SELECT_STYLE_RECIPE', { cookingStyleId = checkint(cell.id) })
                end })
                CommonTip:setPosition(display.center)
                local scene = uiMgr:GetCurrentScene()
                scene:AddDialog(CommonTip, 10)

            else
                uiMgr:ShowInformationTips(__('请将当前专精菜品研究完全~'))
            end
        end
    end

end

-- 用于绑定改良的菜品体系的绑定buttons
function RecipeResearchAndMakingMediator:buildingMakeLayoutStylesAndOthesButton()
    local styleData = self:GetStyleTable()
    for k, v in pairs(self.recipeResearchAndMakingView.styleBtns) do
        local isLock = false
        local data = styleData[tostring(k)]
        if checkint( data.initial ) == MAGIC_FOOD_STYLE then
            isLock = true
        else
            for kk, vv in pairs(gameMgr:GetUserInfo().cookingStyles) do
                if checkint(kk) == checkint(k) then
                    isLock = true
                    break
                end
            end
        end
        v:setEnabled(isLock)
        v:getChildByTag(111):setVisible(not isLock)
        v:setOnClickScriptHandler(handler(self, self.switchRecipeStyle))
    end

    for k, v in pairs(self.recipeResearchAndMakingView.othersButtns) do
        display.commonUIParams(v, { cb = handler(self, self.switchRecipeFunction)} )
        --v:setOnClickScriptHandler(handler(self, self.switchRecipeFunction))
    end
    local styleLayout =  self.showLayerDataTable[tostring( BtnCollect.ImprovedRecipe)].styleLayout
    if styleLayout and ( not tolua.isnull(self )) then
        self.showLayerDataTable[tostring( BtnCollect.ImprovedRecipe)].styleLayout:setScaleY(0)
    end

end
function RecipeResearchAndMakingMediator:SetStyleLayoutStatus(status)
    if not  self.isStyleAction then
        local layer = self.showLayerDataTable[tostring( BtnCollect.ImprovedRecipe)].styleLayout
        layer:stopAllActions()
        if status == false then
            layer:setScaleY(1)
        end
        layer:runAction(
        cc.Sequence:create(
            cc.CallFunc:create(function ()
                self.isStyleAction = true
            end),
            cc.EaseBackIn:create(cc.ScaleTo:create(0.2, 1, math.abs(layer:getScaleY() - 1))),
            cc.CallFunc:create(function()
                if status ~= false then
                    local isShow = (not layer:isVisible())
                    layer:setVisible(isShow)
                    self.showLayerDataTable[tostring( BtnCollect.ImprovedRecipe)].styleSwallowLayer:setVisible(isShow )
                else
                    layer:setVisible(status)
                    self.showLayerDataTable[tostring( BtnCollect.ImprovedRecipe)].styleSwallowLayer:setVisible(status)
                end


            end),
            cc.CallFunc:create(function ()
                self.isStyleAction = false
            end)
            )
        )
    end
end
-- 这个里面存放的是风格按钮和查看菜谱的种类的按钮
function RecipeResearchAndMakingMediator:switchRecipeFunction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BtnCollect.STYLE_BTN then
        self:SetStyleLayoutStatus()
    elseif tag == BtnCollect.SEARCH_BTN then
        local styleType = (self.preClickTag == BtnCollect.ImprovedRecipe and self.presStyleTag ) or self.presStyleDetailTag
        local view = require("Game.views.RecipeStyleKindsDetailView").new({ styleType = styleType })
        local isTrue = true
        view:setPosition(display.center)
        view.viewData.eaterLayer:setOnClickScriptHandler(
        function()
            if isTrue then
                self:closeCurrentLayer(view, false, false)
                isTrue = false
            end
        end
        )
        uiMgr:GetCurrentScene():AddDialog(view)
    end
end

-- 用于切换菜品的风格
function RecipeResearchAndMakingMediator:switchRecipeStyle(sender)
    local tag = sender:getTag()
    self:SetStyleLayoutStatus(false)
    if self.presStyleTag then
        if tag == self.presStyleTag then
            return
        end
    end
    self.presStyleTag = tag
    self.preRecipeClickTag = nil
    self.preRcipeCell = nil
    self.currentRecipeData = app.cookingMgr:SortRecipeKindsOfStyleByGradeThenOrder(self.presStyleTag)
    if self.preNowTag then
        PlayAudioByClickNormal()

    end
    local btn = self.recipeResearchAndMakingView.othersButtns[tostring(BtnCollect.STYLE_BTN)]

    if self.presStyleTag == BtnCollect.MagicStyle then
        local richLabel = btn:getChildByTag(115)
        richLabel:setVisible(false)
        local label = btn:getChildByTag(116)
        label:setVisible(true)
        local node = btn:getChildByTag(RED_TAG)
        if node then
            node:setVisible(false)
        end
        btn:setEnabled(false)
        local styleData =self:GetStyleTable()
        self.recipeResearchAndMakingView.othersButtns[ tostring(BtnCollect.SEARCH_BTN)]:setVisible(false)
        local progressLabel = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].progressLabel
        progressLabel:setVisible(false)
        label:setString(styleData[tostring(BtnCollect.MagicStyle)].name)
        self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].view:setVisible(true)
        self:swithRecipeStyleGridView()

    else
        self.preNowTag = tag
        btn:setEnabled(true)
        if tag == checkint(ALL_RECIPE_STYLE ) or  tag == checkint(FESTIVAL_RECIPE_STYLE)  then
            self.recipeResearchAndMakingView.othersButtns[tostring(BtnCollect.SEARCH_BTN)]:setVisible(false)
        else
            self.recipeResearchAndMakingView.othersButtns[tostring(BtnCollect.SEARCH_BTN)]:setVisible(true)
        end
        local styleBtn = self.recipeResearchAndMakingView.styleBtns[tostring(tag)]
        local richLabel = btn:getChildByTag(115)
        local node = btn:getChildByTag(RED_TAG)
        if node  then
            node:setVisible(true)
        end
        if richLabel then
            local text = styleBtn:getLabel():getString()
            display.reloadRichLabel(richLabel, { ap = display.CENTER, c = {
                fontWithColor('14', { text = text , color = "fffae9", fontSize = 22 }),
                { img = _res('ui/home/task/main/rank_ico_arrow.png'), ap = cc.p(-1, -0.5) }
            } })
            richLabel:setVisible(true)
            CommonUtils.AddRichLabelTraceEffect(richLabel , "#4a2000" ,1)
            CommonUtils.SetNodeScale(richLabel , {width = 210})
        end
        local label = btn:getChildByTag(116)
        label:setVisible(false)
        self:swithRecipeStyleGridView()
        local cookingStylesTable = self:GetStyleTable()[tostring(tag)]
        local Num = table.nums(gameMgr:GetUserInfo().cookingStyles[tostring(tag)] or {})
        local accountNum = checkint(cookingStylesTable.studyRecipe) + checkint(cookingStylesTable.rewardsRecipe)
        local progressLabel = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].progressLabel
        progressLabel:setVisible(true)
        progressLabel:setString(string.format( __('收集进度%d/%d'), Num, accountNum) )

    end

end


-- 不同菜系种类的显示
function RecipeResearchAndMakingMediator:swithRecipeStyleGridView()
    local data = self.currentRecipeData or {}
    local gridView = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].gridView
    gridView:setCountOfCell(table.nums(data))
    gridView:reloadData()
    local noRecipeView = self.showLayerDataTable[tostring(BtnCollect.ImprovedRecipe)].noRecipeView
    noRecipeView:setVisible(table.nums(data) == 0 )
end
function RecipeResearchAndMakingMediator:onShowRecipDetail(sender)
    local cell = sender:getParent():getParent()
    local tag = sender:getTag()
    if self.preRecipeClickTag then
        if self.preRecipeClickTag == tag then
            return
        else
            if self.preRcipeCell then
                -- 判断上次点击的cell是否存在
                if self.preRecipeClickTag ~= tag then
                    -- 判断是否翻页更新
                    self.preRcipeCell.selectImage:setVisible(false)
                end
            end
        end
    end
    for k, v in pairs(self.redDotTable) do
        if checkint(k) == self.presStyleTag then
            for kk, vv in pairs(v) do
                if checkint(kk) == checkint(self.currentRecipeData[tag].recipeId) then
                    cell.newImage:setVisible(false)
                    if checkint(self.currentRecipeData[tag].growthTotal) == 0 then
                        self:clearRedDotStatus(clone(self.currentRecipeData[tag]))
                        self:clearRedDotBtn()
                    end
                end
            end
        end
    end
    self.preRecipeClickTag = tag
    self.preRcipeCell = cell
    self.preRcipeCell.selectImage:setVisible(true)
    PlayAudioByClickNormal()
    if self.showLayerDataTable[tostring(BtnCollect.SHOW_RECIPE_DETAIL)] then
        -- 如果有直接走刷新事件
        self.RecipeDetailMediator:updateRecipeDetailView(self.currentRecipeData[tag], EXTERNAL_REFRESH )
        self:recoverRecipeDeatailViewPos(true)
        --GuideUtils.DispatchStepEvent()
    else -- 如果没有 走出创建
        
        local data = self.currentRecipeData[tag]
        data.layer = self.recipeResearchAndMakingView
        data.type = 2
        local RecipeDetailMediator = require("Game.mediator.RecipeDetailMediator")
        local mediator = RecipeDetailMediator.new(data)
        self:GetFacade():RegistMediator(mediator)
        self.RecipeDetailMediator = mediator
        self.showLayerDataTable[tostring(BtnCollect.SHOW_RECIPE_DETAIL)] = mediator:GetViewComponent().viewData
        self:recoverRecipeDeatailViewPos(true)
        local recipeOneConfig = CommonUtils.GetConfigAllMess('recipe', 'cooking')[tostring(data.recipeId)]
        if recipeOneConfig then
            data.cookingStyleId = recipeOneConfig.cookingStyleId
        end
        if checkint(data.cookingStyleId) ~= RECIPE_STYLE.MO_LIAO_LI  and checkint(data.cookingStyleId) ~= 0  then
            local  gradeConf = CommonUtils.GetConfigAllMess('grade' , 'cooking' )
            if checkint(data.gradeId)  > 1  then
                if GuideUtils.IsGuiding() and GuideUtils.GetGuidingId() ==  GUIDE_MODULES.MODULE_ACCEPT_STORY  then
                    GuideUtils.DispatchStepEvent()
                    GuideUtils.ForceShowSkip()
                end
            else
                if GuideUtils.IsGuiding() and GuideUtils.GetGuidingId() ==  GUIDE_MODULES.MODULE_ACCEPT_STORY  then
                    if checkint(data.growthTotal) <  checkint(gradeConf['1'].limit) then
                        GuideUtils.DispatchStepEvent()
                        GuideUtils.ForceShowSkip()
                    else
                        GuideUtils.DispatchStepEvent()
                    end
                else
                    GuideUtils.DispatchStepEvent()
                end
            end
        else
            GuideUtils.DispatchStepEvent()
        end
    end

end
function RecipeResearchAndMakingMediator:setcountDownLabelStatus()
    --设置countLabel 的状态

    if not self.showLayerDataTable[tostring(BtnCollect.Research)] then
        local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
        local node = btn:getChildByTag(112)
        local countDowanLabel = node.countDownLabel
        local btnNameLabel = btn:getChildByTag(111)
        local researchDoing = node:getChildByTag(113)
        if app.cookingMgr:GetRecipeLeftSecodTime() >= 0 then
            if app.cookingMgr:GetRecipeLeftSecodTime() == 0 then
                countDowanLabel:setString("00:00")
                researchDoing:setString(__('开发完成'))
                countDowanLabel:stopAllActions()
                node:setVisible(true)
                btnNameLabel:setVisible(false)
                self:AddResearchRedDotBtn()
            else
                node:setVisible(true)
                btnNameLabel:setVisible(false)
                countDowanLabel:setString("")
                researchDoing:setString(__('开发中'))
                self:ClearResearchRedDotBtn()
                local repeatAction = cc.Repeat:create(
                cc.Sequence:create(
                cc.DelayTime:create(1),

                cc.CallFunc:create(function()
                    if not self.showLayerDataTable[tostring(BtnCollect.Research)] then
                        --self.leftReseachTimes =  self.leftReseachTimes -1
                        local time = checkint(app.cookingMgr:GetRecipeLeftSecodTime() )
                        if time == 0 then
                            researchDoing:setString(__('开发完成'))
                            self:AddResearchRedDotBtn()
                            countDowanLabel:stopAllActions()
                            return
                        end
                        local timesTable = string.formattedTime(time)

                        countDowanLabel:setString(string.format("%02d:%02d", timesTable.m, timesTable.s))
                    else
                        countDowanLabel:stopAllActions()
                    end
                end)
                )
                , app.cookingMgr:GetRecipeLeftSecodTime() )
                countDowanLabel:stopAllActions()
                countDowanLabel:runAction(repeatAction)
            end
            display.commonLabelParams(researchDoing , {reqH  = 55 ,  w = 140 ,reqW =120, hAlign = display.TAC})
        else
            node:setVisible(false)
            btnNameLabel:setVisible(true)
        end
    else
        local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
        local node = btn:getChildByTag(112)
        local countDowanLabel = node.countDownLabel
        countDowanLabel:stopAllActions()
    end
    if app.cookingMgr:GetRecipeLeftSecodTime() < 0 then
        local btn = self.recipeResearchAndMakingView.collectBtn[tostring(BtnCollect.Research)]
        local node = btn:getChildByTag(112)
        --local countDowanLabel = node.countDownLabel
        local btnNameLabel = btn:getChildByTag(111)
        node:setVisible(false)
        btnNameLabel:setVisible(true)
    end

end
-- 制作的菜品刷新
function RecipeResearchAndMakingMediator:onMakeDataSourceAction(p_convertview, idx)
    local pCell = p_convertview
    --local pButton = nil
    local index = idx + 1
    local sizee = cc.size(185, 218)
    if self.currentRecipeData and index <= table.nums(self.currentRecipeData) then
        if pCell == nil then
            pCell = self.recipeResearchAndMakingView:creatGridCell()
            pCell.bgImage:setOnClickScriptHandler(handler(self, self.onShowRecipDetail))
            if index <= 9 then
                pCell.bgLayout:setPositionY(sizee.height - 800)
                pCell.bgLayout:runAction(
                cc.Sequence:create(cc.DelayTime:create(index * 0.01),
                cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width * 0.5, sizee.height * 0.5)), 0.2))
                )
            else
                pCell.bgLayout:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
            end
        else
            pCell:setName(tostring(index))
            pCell.selectImage:setVisible(false)
            pCell.bgLayout:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
        end
        xTry(function()
            local isShow = false
            pCell.bgImage:setTag(index)
            if self.preRecipeClickTag then
                if checkint(index) == self.preRecipeClickTag then
                    isShow = true
                end
            end
            pCell.newImage:setVisible(false)
            pCell.levelupImage:setVisible(false)
            self:judgeIsAddRed(pCell, index)
            self:JudgeIsAddNewLevel(pCell, index)

            self.recipeResearchAndMakingView:updateGradeCell(pCell, self.currentRecipeData[index], isShow)
        end, __G__TRACKBACK__)
        return pCell
    end
end
function RecipeResearchAndMakingMediator:EnterLayer()
    --就如界面
    self:SendSignal(COMMANDS.COMMANDS_RecipeCooking_Home_Callback)
end
function RecipeResearchAndMakingMediator:OnRegist(  )

    local RecipeCookingAndStudyCommand = require('Game.command.RecipeCookingAndStudyCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Cooking_Style_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Accelertate_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Cancel_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Draw_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_RecipeCooking_Home_Callback, RecipeCookingAndStudyCommand)
    self:GetFacade():RegistObserver("REFRESH_RECIPE_DETAIL", mvc.Observer.new(self.ProcessSignal, self))
    self:GetFacade():RegistObserver("SELECT_STYLE_RECIPE", mvc.Observer.new(self.ProcessSignal, self))
    self:EnterLayer()
end

function RecipeResearchAndMakingMediator:OnUnRegist(  )
    --称出命令
    if not tolua.isnull(self.recipeResearchAndMakingView) then
        self.recipeResearchAndMakingView:runAction(cc.RemoveSelf:create())
    end

    if self.RecipeDetailMediator then
        self:GetFacade():UnRegsitMediator('RecipeDetailMediator')
    end
    local recipeReminderMediator = app:RetrieveMediator("RecipeReminderMediator")
    if recipeReminderMediator then
        self:GetFacade():UnRegsitMediator('RecipeReminderMediator')
    end
    app.badgeMgr:CheckClearResearchRecipeRed()
    self:GetFacade():UnRegistObserver("SELECT_STYLE_RECIPE", self)
    self:GetFacade():UnRegistObserver("REFRESH_RECIPE_DETAIL", self)

    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Cooking_Style_Callback)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Callback)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Accelertate_Callback)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Cancel_Callback)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Study_Draw_Callback)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_RecipeCooking_Home_Callback)

    AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return RecipeResearchAndMakingMediator
