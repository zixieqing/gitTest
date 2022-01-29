--[[
代理店长Mediator
--]]
local Mediator = mvc.Mediator
local LobbyAgentShopOwnerMediator = class("LobbyAgentShopOwnerMediator", Mediator)

local NAME = "LobbyAgentShopOwnerMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local RESTAURANT_MANAGER_CONF = CommonUtils.GetConfigAllMess('manager', 'restaurant')

local BUTTON_TAG = {
    DETERMINE = 1, -- 委托
    CANCEL    = 2, -- 取消
    JUMP      = 3, -- 跳转
}

local COMMON_TIP_TAG = 5555

function LobbyAgentShopOwnerMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)

    self.args = checktable(params)
    
    -- dump(RESTAURANT_MANAGER_CONF, 'RESTAURANT_MANAGER_CONF')

end

function LobbyAgentShopOwnerMediator:InterestSignals()
    local signals = {
        POST.RESTAURANT_AGENT_SHOPOWNER.sglName,
        POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER.sglName,
        COUNT_DOWN_ACTION,

        'REFRESH_NOT_CLOSE_GOODS_EVENT', -- 刷新拥有个数
	}

	return signals
end

function LobbyAgentShopOwnerMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = checktable(signal:GetBody())

    if name == POST.RESTAURANT_AGENT_SHOPOWNER.sglName  then
        local data = self.datas[self.curSelectIndex]
        local mangerId = checkint(body.requestData.managerId)
        local num = checkint(data.num)
        self:setIsOwnShopOwnerById(mangerId)
        local gridView = self.viewData.gridView
        gridView:reloadData()
        self:initBtnShowState()
        CommonUtils.DrawRewards({
			{goodsId = AGENT_COUPON_ID, num = -num}
		})
        self:updateCurrencyCountLabel()
        self:setCellSelectState(self.curSelectIndex, false)
    elseif name == POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER.sglName then
        self:setIsOwnShopOwnerById(0)
        local gridView = self.viewData.gridView
        gridView:reloadData()
        self:initBtnShowState()
        self:setCellSelectState(self.curSelectIndex, true)
    elseif name == COUNT_DOWN_ACTION then
        local tag = checkint(body.tag)
        if tag ~= RemindTag.LOBBY_AGENT_SHOPOWNER then return end

        local seconds  = checkint(body.countdown)
        local countDownLabel       = self.viewData.countDownLabel
        
        countDownLabel:setString(CommonUtils.getTimeFormatByType(seconds))
        if seconds <= 0 then
            self:setIsOwnShopOwnerById(0)
            local gridView = self.viewData.gridView
            gridView:reloadData()
            self:initBtnShowState()
            self:setCellSelectState(self.curSelectIndex, true)
        end
    elseif name == 'REFRESH_NOT_CLOSE_GOODS_EVENT' then
        self:updateCurrencyCountLabel()
    end
end

function LobbyAgentShopOwnerMediator:Initial( key )
    self.super.Initial(self,key)
    
    local scene = uiMgr:GetCurrentScene()
    local viewComponent = require('Game.views.LobbyAgentShopOwnerView').new({mediatorName = NAME})
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    self.viewData = viewComponent:getViewData()

    self:initData()
    self:initUi()

end

function LobbyAgentShopOwnerMediator:initData()
    self.datas = {}
    self.curSelectIndex = 1
    
    self:setIsOwnShopOwnerById(self.args.mangerId)
    for i,v in pairs(RESTAURANT_MANAGER_CONF) do
        table.insert(self.datas, v)
    end
    local sortfunction = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aId = checkint(a.id)
        local bId = checkint(b.id)
        return aId < bId
    end
    table.sort(self.datas, sortfunction)
    
    for i,v in ipairs(self.datas) do
        if self.args.mangerId == checkint(v.id) then
            self.curSelectIndex = i
        end
    end
end

function LobbyAgentShopOwnerMediator:initUi()
    self:initRule()
    self:initBtn()
    self:initRoleList()
    self:updateRole(self.curSelectIndex)
    self:updateCurrencyCountLabel()
end

function LobbyAgentShopOwnerMediator:initRule()
    local scrollView = self.viewData.scrollView
    local ruleLabel = self.viewData.ruleLabel
    local moduleId = MODULE_DATA[tostring(RemindTag.LOBBY_AGENT_SHOPOWNER)]
    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))[tostring(moduleId)] or {}
    
    local labelparser = require("Game.labelparser")
    local parsedtable = labelparser.parse(moduleExplainConf.descr)
    dump(parsedtable)
    local ruleLabelTable = {}
    local  text = ""
    for i,v in ipairs(parsedtable) do
        --if v.labelname == 'b' then
        --    table.insert( ruleLabelTable, {text = v.content, fontSize = 22, color = '#ff5151'} )
        --else
        --    table.insert( ruleLabelTable, {text = v.content, fontSize = 22, color = '#5c5c5c'} )
        --end
        text = text  ..  v.content
    end
    local oldContentSize = scrollView:getContentSize()
    print(text)
    display.commonLabelParams(ruleLabel, {fontSize = 22, color = '#5c5c5c' , text =text})
    --display.reloadRichLabel(ruleLabel, {c = ruleLabelTable})
    local scrollViewSize = display.getLabelContentSize(ruleLabel)
    scrollView:setContainerSize(scrollViewSize)
    display.commonUIParams(ruleLabel, {po = cc.p(ruleLabel:getPositionX(), 0)})
    
    local newContentSize = scrollView:getContentSize()
    scrollView:setContentOffset(cc.p(0, oldContentSize.height - scrollViewSize.height))
    
    
    -- local labelparser = require("Game.labelparser")
    -- local parsedtable = labelparser.parse(moduleExplainConf.descr)
    -- dump(parsedtable)
end

function LobbyAgentShopOwnerMediator:initBtn()
    local determineBtn         = self.viewData.determineBtn
    display.commonUIParams(determineBtn, {cb = handler(self, self.onButtonAction)})
    determineBtn:setTag(BUTTON_TAG.DETERMINE)

    local cancelBtn            = self.viewData.cancelBtn
    display.commonUIParams(cancelBtn, {cb = handler(self, self.onButtonAction)})
    cancelBtn:setTag(BUTTON_TAG.CANCEL)

    local jumpLayer = self.viewData.jumpLayer
    display.commonUIParams(jumpLayer, {cb = handler(self, self.onButtonAction)})
    jumpLayer:setTag(BUTTON_TAG.JUMP)

    self:initBtnShowState()

end

function LobbyAgentShopOwnerMediator:updateRole(index)
    if index == nil then return end

    local roleLayer = self.viewData.roleLayer
    if roleLayer:getChildrenCount() > 0 then
        roleLayer:removeAllChildren()
    end

    local data = self.datas[index]
    local photoId        = data.photoId
    local roleNode = CommonUtils.GetRoleNodeById(photoId, 1)
    roleNode:setAnchorPoint(display.CENTER_TOP)
    roleNode:setPosition(cc.p(display.cx, display.height + 20))
    roleLayer:addChild(roleNode)
    roleNode:setScale(0.82)
end

--==============================--
--desc:初始化 按钮显示状态
--time:2018-02-23 10:24:42
--@return 
--==============================-- 
function LobbyAgentShopOwnerMediator:initBtnShowState()
    local determineBtn         = self.viewData.determineBtn
    determineBtn:setVisible(not self.isOwnShopOwner)

    local cancelBtnLayer       = self.viewData.cancelBtnLayer
    cancelBtnLayer:setVisible(self.isOwnShopOwner)
end

function LobbyAgentShopOwnerMediator:initRoleList()

    local cellCount = #self.datas
    local gridView = self.viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
    gridView:setCountOfCell(cellCount)
    gridView:setBounceable(cellCount > 4)
    gridView:reloadData()
end

---------------------------------------------------
-- update

function LobbyAgentShopOwnerMediator:updateCurrencyCountLabel()
    local currencyCountLabel   = self.viewData.currencyCountLabel
    display.commonLabelParams(currencyCountLabel, {text = CommonUtils.GetCacheProductNum(AGENT_COUPON_ID)})
end

function LobbyAgentShopOwnerMediator:updateCellSelectState(viewData, isShow)
    local frameBg = viewData.frameBg
    frameBg:setVisible(isShow)
end

function LobbyAgentShopOwnerMediator:updateCellState(viewData, id)
    local isShopOwner    = self.mangerId == id
    local bg             = viewData.bg
    local head           = viewData.head
    local headFrame      = viewData.headFrame
    local agentTimeBg    = viewData.agentTimeBg
    local agentDescLayer = viewData.agentDescLayer
    local currencyLabel  = viewData.currencyLabel
    local tipLabel       = viewData.tipLabel
    local currencyIcon   = viewData.currencyIcon
    local touchView      = viewData.touchView
    if self.isOwnShopOwner then
        touchView:setVisible(false)
        if isShopOwner then
            headFrame:setScale(1.2)
            tipLabel:setVisible(true)
            agentDescLayer:setVisible(false)
            bg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_role_bg_active.png'))
            agentTimeBg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_time_bg_active.png'))
            display.commonLabelParams(currencyLabel, {color = '#be3c3c'})
            currencyIcon:clearFilter()
            head:clearFilter()
            headFrame:clearFilter()
        else
            headFrame:setScale(1)
            agentDescLayer:setVisible(true)
            tipLabel:setVisible(false)
            bg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_role_bg_inactive.png'))
            agentTimeBg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_time_bg_inactive.png'))
            display.commonLabelParams(currencyLabel, {color = '#8c8a8a'})
            currencyIcon:setFilter(GrayFilter:create())
            headFrame:setFilter(GrayFilter:create())
            head:setFilter(GrayFilter:create())
        end
    else
        touchView:setVisible(true)
        headFrame:setScale(1)
        tipLabel:setVisible(false)
        agentDescLayer:setVisible(true)
        bg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_role_bg_active.png'))
        agentTimeBg:setTexture(_res('avatar/ui/agentShopowner/restaurant_agent_time_bg_active.png'))
        display.commonLabelParams(currencyLabel, {color = '#be3c3c'})
        currencyIcon:clearFilter()
        headFrame:clearFilter()
        head:clearFilter()
    end

end

---------------------------------------------------
-- action
function LobbyAgentShopOwnerMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.onClickCellAction)})
    end

    xTry(function()
        local data           = self.datas[index]

        local viewData       = pCell.viewData
        local head           = viewData.head
        local photoId        = data.photoId
        head:setTexture(CommonUtils.GetNpcIconPathById(photoId, NpcImagType.TYPE_HALF_BODY))

        local roleInfo       = gameMgr:GetRoleInfo(photoId)
        local headName       = viewData.headName
        display.commonLabelParams(headName, {text = tostring(roleInfo.roleName)})
        
        local currencyLabel  = viewData.currencyLabel
        currencyLabel:setString('x' .. tostring(data.num))

        local agentTimeLabel = viewData.agentTimeLabel
        display.commonLabelParams(agentTimeLabel, {text = string.format(__("委托：%s"), CommonUtils.getTimeFormatByType(checkint(data.time), 1))})
        
        self:updateCellSelectState(viewData, not self.isOwnShopOwner and self.curSelectIndex == index)
        self:updateCellState(viewData, checkint(data.id))

        local touchView      = viewData.touchView
        touchView:setTag(index)
	end,__G__TRACKBACK__)

    return pCell
end

-- 处理 cell 点击事件 
function LobbyAgentShopOwnerMediator:onClickCellAction(sender)
    local index = sender:getTag()
    if self.curSelectIndex == index then return end
    PlayAudioByClickNormal()

    self:setCellSelectState(self.curSelectIndex, false)
    self:setCellSelectState(index, true)

    self.curSelectIndex = index

    self:updateRole(index)

end

-- 处理 按钮 点击事件 
function LobbyAgentShopOwnerMediator:onButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()

    -- 委托处理
    if tag == BUTTON_TAG.DETERMINE then
        local ownCount = CommonUtils.GetCacheProductNum(AGENT_COUPON_ID)
        local data = self.datas[self.curSelectIndex] or {}
        local needCount = checkint(data.num)
        -- 1. 检查 委托券数量
        if ownCount < needCount then
            local commonTip = require( 'common.CommonTip' ).new({ text = __('委托券不足'), useAllText = __('再想想'), useOneText = __('前往购买'), descr = __('在道具商店内可以购买委托券，每周还有限量的促销包哦～'), 
            callback = function()
                PlayAudioByClickNormal()
                if GAME_MODULE_OPEN.NEW_STORE then
                    app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
                else
                    app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'goods'}})
                end
            end,
            })
            commonTip:setPosition(display.center)
            commonTip:setTag(5555)
            local scene = uiMgr:GetCurrentScene()
            scene:AddDialog(commonTip, 10)
            
            return
        end

        -- 2. 检查 是否有服务员
        if table.nums(gameMgr:GetUserInfo().waiter) <= 0 then
            uiMgr:ShowInformationTips(__('当前餐厅内没有服务员，无法雇佣代理店长哦~'))
            return
        end

        local commonTip = require( 'common.CommonTip' ).new({ text = __('确认委托吗?'), descr = __('委托开始后，委托券不予退还，请确认已熟知协议说明。'), callback = function()

            -- 3. 检查 橱窗中有没有售卖的菜
            if gameMgr:GetUserInfo().avatarCacheData.recipe == nil or next(gameMgr:GetUserInfo().avatarCacheData.recipe) == nil then
                uiMgr:ShowInformationTips(__('当前餐厅的橱窗内没有售卖中的菜品，无法雇佣代理店长哦~'))
                return
            end
            
            -- 4. 检查雇员新鲜度
            local isVigourSatisfy = false
            -- 4.1 遍历 服务员id
            for index,waiterId in pairs(gameMgr:GetUserInfo().waiter) do
                -- 4.2 获取服务员新鲜度
                local waiterInfo = gameMgr:GetCardDataById(waiterId)
                if waiterInfo and checkint(waiterInfo.vigour) > 0 then
                    isVigourSatisfy = true
                    break
                end
            end
            
            if not isVigourSatisfy then
                uiMgr:ShowInformationTips(__('所有服务员都处于新鲜度不足的状态下，无法雇佣代理店长哦~'))
                return
            end

            PlayAudioByClickNormal()
            local data = self.datas[self.curSelectIndex] or {}
            local mangerId = data.id
            self:SendSignal(POST.RESTAURANT_AGENT_SHOPOWNER.cmdName, {managerId = mangerId, num = num})
        end })
        commonTip:setPosition(display.center)
        commonTip:setTag(5555)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(commonTip, 10)
    
    -- 处理 取消按钮
    elseif tag == BUTTON_TAG.CANCEL then
        local commonTip = require( 'common.CommonTip' ).new({ text = __('取消委托吗?'), descr = __('取消后，已支付的委托券不予退还，请确认已熟知协议说明。'), callback = function()
            if self.isOwnShopOwner then
                PlayAudioByClickNormal()
                self:SendSignal(POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER.cmdName)
            else
                uiMgr:ShowInformationTips(__('该委托已过期, 不可取消'))
            end
        end })
        commonTip:setPosition(display.center)
        commonTip:setTag(5555)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(commonTip, 10)

    -- 处理 跳转按钮    
    elseif tag == BUTTON_TAG.JUMP then
        if GAME_MODULE_OPEN.NEW_STORE then
            app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
        else
            app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'goods'}})
        end
    end
end

function LobbyAgentShopOwnerMediator:setIsOwnShopOwnerById(id)
    self.mangerId = checkint(id)
    self.isOwnShopOwner = self.mangerId ~= 0
end

function LobbyAgentShopOwnerMediator:setCellSelectState(index, isShow)
    local gridView = self.viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)
    self:updateCellSelectState(cell.viewData, isShow)
end

function LobbyAgentShopOwnerMediator:enterLayer()
end

function LobbyAgentShopOwnerMediator:OnRegist(  )
    regPost(POST.RESTAURANT_AGENT_SHOPOWNER)
    regPost(POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER)
end

function LobbyAgentShopOwnerMediator:OnUnRegist(  )
    unregPost(POST.RESTAURANT_AGENT_SHOPOWNER)
    unregPost(POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER)

    local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
end

return LobbyAgentShopOwnerMediator