local Mediator = mvc.Mediator
local socket = require('socket')
---@class CardEncyclopediaMediator
local CardEncyclopediaMediator = class("CardEncyclopediaMediator", Mediator)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")

local NAME = "CardEncyclopediaMediator"
local SCROLL_TIME       = 0.2
local INTERVAL_INTERVAL = 0.01   -- 惯性滑动触发时间间隔
local INTERVAL_FALL     = 0  -- 惯性滑动衰减速度
local SLIDE_RANGE       = 5     -- 滑动手势识别范围
local SELECT_BTNCHECK = {
    LINKAGE = 6,
    CARD_SP = 5,
    CARD_UR = 4,
    CARD_SR = 3 ,
    CARD_R = 2 ,
    CARD_W = 1
}
function CardEncyclopediaMediator:ctor( params,viewComponent )
    self.super:ctor(NAME,viewComponent)
	self.allCardPointInfor = {}
    self.cardOrderData = CommonUtils.GetConfigAllMess('cardOrder' , 'collection')
    local cardOrderTable = {
        {tag = SELECT_BTNCHECK.CARD_W , name = 'Frame.CardEncyclopedia.M' },
        {tag = SELECT_BTNCHECK.CARD_R , name = 'Frame.CardEncyclopedia.R' },
        {tag = SELECT_BTNCHECK.CARD_SR , name = 'Frame.CardEncyclopedia.SR' },
        {tag = SELECT_BTNCHECK.CARD_UR , name = 'Frame.CardEncyclopedia.UR' },
        {tag = SELECT_BTNCHECK.CARD_SP , name = 'Frame.CardEncyclopedia.SP' },
        {tag = SELECT_BTNCHECK.LINKAGE , name ='Frame.CardEncyclopedia.LINKAGE'  },
    }

    for i, v in pairs(cardOrderTable) do
        local cardOrder  = self.cardOrderData[tostring(v.tag)] or {}
        if table.nums(cardOrder) > 0  then
            if v.tag == SELECT_BTNCHECK.LINKAGE  then
                if isChinaSdk and  isChinaSdk() then
                    self.allCardPointInfor[v.tag] = require( v.name) 							-- 表示联动
                end
            else
                self.allCardPointInfor[v.tag] = require(v.name)
            end
        end
    end

	self.preIndex = nil            -- 记录当前点击点的index 值
	self.touchBeginPoint = nil  -- 点击开始的坐标
	self.isClickEvent = false   -- 判断是点击事件还是滑动事件
	self.viewCollect = {}       --  收集不同的view界面
    self.scrolling = true
    self.isAction = false
	self.alreadyLoad = {

	}
end


function CardEncyclopediaMediator:InterestSignals()
	local signals = {
	}
	return signals
end
function CardEncyclopediaMediator:Initial( key )
	self.super.Initial(self,key)
    ---@type CardEncyclopediaView
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.CardEncyclopediaView')
    self:SetViewComponent(viewComponent)
    self:UpdateButton()
    self:SortCardsDataAndPage()
    self.viewData = viewComponent.viewData
    local  zorder =  self:GetViewComponent():getLocalZOrder()
    self:GetViewComponent():setLocalZOrder(zorder - 1)
    self.close = true
    self.viewData.navBack:setOnClickScriptHandler(function ()
        if self.close then
            self.isAction = true
            -- 禁用点击
            self.viewData.touchMiddleLayout:setTouchEnabled(false)
            self.close = false
            --self:GetViewComponent():stopAllActions()
            AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
        end
    end)
    for k ,v in pairs(self.viewData.checkButtons) do
        v:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
    self:ButtonAction(self.viewData.checkButtons[tostring(SELECT_BTNCHECK.CARD_UR)])
    self.viewData.touchMiddleLayout:setOnTouchBeganScriptHandler(handler(self, self.TouchBeginAction) )
    self.viewData.touchMiddleLayout:setOnTouchMovedScriptHandler(handler(self, self.TouchMoveAction))
    self.viewData.touchMiddleLayout:setOnTouchEndedScriptHandler(handler(self, self.TouchEndAction))
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.CG_COLLECT) and CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.CG_COLLECT) then
        viewComponent:CreateCollectLayout()
        display.commonUIParams(self.viewData.collectLayout , {cb = function()
            local mediator =  require("Game.mediator.collectCG.CollectCGListMediator").new()
            app:RegistMediator(mediator)
        end})
        self:UpdateCollectCGLayout()
    end
end
function CardEncyclopediaMediator:UpdateCollectCGLayout()
    local backpackMap = gameMgr:GetBackPackArrayToMap()
    local CGCOnfig = CommonUtils.GetConfigAllMess('cg' ,'collection')
    local countKind =  table.nums(CGCOnfig)
    local ownNum = 0
    for id , cgOneData in pairs(CGCOnfig) do
        local isComplete = true
        for index , cgFragmentId  in pairs(cgOneData.fragments or {} ) do
            if (not  backpackMap[tostring(cgFragmentId)])   or
            (checkint(backpackMap[tostring(cgFragmentId)].amount)  == 0 )then
                isComplete = false
                break
            end
        end
        if isComplete then
            ownNum = ownNum + 1
        end
    end
    local viewData = self:GetViewComponent().viewData
    display.commonLabelParams(viewData.progressNum , {text = string.format('%d/%d' ,ownNum ,countKind  )})
end
--==============================--
--desc:这里是整理数据
--time:2017-08-03 05:08:40
--@return
--==============================--.
function CardEncyclopediaMediator:UpdateButton()
    local data= {}
    for i, v in pairs(SELECT_BTNCHECK) do
        data[tostring(v)] = {
            count =  0 ,
            owner = 0
        }
    end
    for k ,v in pairs(self.cardOrderData)   do
        local Num = tostring(k)
        data[Num].count = table.nums(self.cardOrderData[k])
        data[Num].owner = 0
        for kk ,vv in pairs(self.cardOrderData[k] )do
            local cardData =  gameMgr:GetCardDataByCardId(kk)
            if cardData then
                 data[Num].owner =  data[Num].owner + 1
            end
        end
    end
    self:GetViewComponent():UpdateButton(data)
end


function CardEncyclopediaMediator:TouchBeginAction(sender,touch)
    local scene = uiMgr:GetCurrentScene()
    local node = scene:GetDialogByName("common.GainPopup")
    if node and not tolua.isnull(node) then
        return false
    end
    local nodeTwo = scene:GetGameLayerByName("CardsFragmentComposeView")
    if nodeTwo and not tolua.isnull(nodeTwo) then
        return false
    end
    local mediator  = AppFacade.GetInstance():RetrieveMediator("ExplorationMediator")
    if   mediator then
        return false
    end
    if self.isAction then
    else
        self.touchBeginPoint = nil
        self.touchBeginPoint = touch:getLocation()
    end
    return 1
end
function CardEncyclopediaMediator:TouchMoveAction(sender,touch)
    xTry(function()
        if self.isAction then
        else
            self.movedTime_ = socket.gettime()
            local p = touch:getLocation()
            local pre = touch:getPreviousLocation()
            local offsetX = p.x - pre.x
            self.movedPoint_ = touch:getLocation()
            local pos =  cc.p(self.viewCollect[tostring(self.preIndex)]:getPositionX() ,self.viewCollect[tostring(self.preIndex)]:getPositionY())
            local _x = pos.x +  offsetX
            self.isTouchMoving_ =  math.abs(self.movedPoint_.x - self.touchBeginPoint.x) >= SLIDE_RANGE
            self.viewCollect[tostring(self.preIndex)]:setPosition( _x  ,pos.y )

            local page = math.ceil( math.abs( _x ) / display.SAFE_RECT.width)  +  1
            if self.alreadyLoad[tostring(self.preIndex) ][tostring(page)] then
                if not  self.alreadyLoad[tostring(self.preIndex) ][tostring(page)].isHave  then
                    self:AddCardImagePage(tostring(self.preIndex) ,page)
                end
            end
        end
    end,__G__TRACKBACK__)
    return true
end
function CardEncyclopediaMediator:TouchEndAction(sender,touch)
    xTry(function()
        if self.isAction then
        else
            self.endedTime_ = socket.gettime()
            self.endedPoint_ = touch:getLocation()
            local pos = touch:getLocation()
            local size = self.viewCollect[tostring(self.preIndex)]:getContentSize()
            local layoutPos = cc.p(self.viewCollect[tostring(self.preIndex)]:getPositionX() ,self.viewCollect[tostring(self.preIndex)]:getPositionY())

            if math.abs(layoutPos.x) + display.SAFE_RECT.width > (size.width + display.SAFE_L) or layoutPos.x > 0 then
                local _x =   layoutPos.x > 0 and 0 or display.SAFE_RECT.width - size.width
                local offsetW = layoutPos.x - _x
                local time = offsetW /  display.SAFE_RECT.width /5

                logInfo.add(4, 'layoutPos.x')
                logInfo.add(4, layoutPos.x)
                logInfo.add(4, display.SAFE_RECT.width)
                logInfo.add(4, size.width)
                logInfo.add(4, _x)
                self.viewCollect[tostring(self.preIndex)]:runAction(cc.Sequence:create(
                    cc.CallFunc:create(function ( )
                        self.isAction = true
                    end) ,
                    cc.EaseSineIn:create(cc.MoveTo:create(0.1 + checkint(time) ,cc.p(checkint(_x) ,0))),
                    cc.CallFunc:create(function ()
                        self.isAction = false
                    end)
                ))
                return true
            end

            if math.abs(pos.x -self.touchBeginPoint.x) < 5  then
                -- 判断是否在收集模块
                if CommonUtils.GetModuleAvailable(MODULE_SWITCH.CG_COLLECT) and CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.CG_COLLECT) then
                    local pos = touch:getLocation()
                    local viewComponent = self:GetViewComponent()
                    local collectLayout  =viewComponent.viewData.collectLayout
                    if cc.rectContainsPoint(collectLayout:getBoundingBox() , pos) then
                        local mediator = require("Game.mediator.collectCG.CollectCGListMediator").new()
                        app:RegistMediator(mediator)
                        return
                    end
                end
                local pos = self.viewCollect[tostring(self.preIndex)]:convertToNodeSpaceAR(touch:getLocation())
                local page = math.floor(pos.x / display.SAFE_RECT.width) +1
                local  isContentId = nil
                if page == 1 then
                    for k ,v in pairs(self.alreadyLoad[tostring(self.preIndex)][tostring(page)].cards) do
                        isContentId =  self:CheckPointInImage(v)
                        if isContentId then
                            break
                        end
                    end
                else
                    local data = {}
                    data[1] = self.alreadyLoad[tostring(self.preIndex)][tostring(page)]
                    if self.alreadyLoad[tostring(self.preIndex)][tostring(page-1)] then
                        table.insert(data , #data+1 , self.alreadyLoad[tostring(self.preIndex)][tostring(page-1)] )
                    end
                    for k ,v in pairs(data) do
                        if v.cards then
                            for kk , vv in pairs( v.cards ) do
                                isContentId =  self:CheckPointInImage(vv)
                                if isContentId then
                                    break
                                end
                            end
                        end
                        if isContentId then
                            break
                        end
                    end

                end
                if not  isContentId then
                    return  true
                end
                local cardData = gameMgr:GetCardDataByCardId(isContentId)
                if nil == cardData then
                    local datas = {}
                    if isChinaSdk() then
                        datas = CommonUtils.GetConfig('cards', 'onlineResourceTrigger', isContentId)
                    else
                        datas = CommonUtils.GetConfig('cards', 'card', isContentId)
                    end
                    if not  datas then
                        uiMgr:ShowInformationTips(__('该飨灵暂未开放'))
                    else
                        local cardConfig = CommonUtils.GetConfig('cards', 'card', isContentId)
                        uiMgr:AddDialog("common.GainPopup", {goodId = cardConfig.fragmentId})
                    end

                else
                    local parebtNode = self.viewCollect[tostring(self.preIndex)]:getChildByTag(isContentId)
                    if parebtNode then
                        parebtNode:setCascadeOpacityEnabled(false)
                        local cardImage = parebtNode:getChildByTag(isContentId)
                        if cardImage then
                            cardImage:setCascadeOpacityEnabled(false)
                            --local tag = 4444
                            local CardManualMediator = require( 'Game.mediator.CardManualMediator' ) -- 界面切换的动画
                            local mediator = CardManualMediator.new({tag = tag, cardId = isContentId, breakLevel = nil ~= cardData and checkint(cardData.breakLevel) or 0})
                            AppFacade.GetInstance():RegistMediator(mediator)
                            local seqAction = cc.Sequence:create(
                            cc.CallFunc:create(function()  self.isAction = true  end ),
                            cc.Spawn:create(
                            cc.TargetedAction:create(cardImage,
                            cc.Sequence:create(
                            cc.CallFunc:create(function()
                                local zorder =  self:GetViewComponent():getLocalZOrder()
                                self:GetViewComponent():setLocalZOrder(checkint(zorder ) + 129 )
                            end),
                            cc.DelayTime:create(3/30) ,
                            cc.EaseBackInOut:create(cc.ScaleTo:create((11)/30,2))
                            )
                            )
                            ,
                            cc.Sequence:create(
                                cc.DelayTime:create(5/30 ) ,
                                cc.CallFunc:create(function ()
                                    cardImage:setCascadeOpacityEnabled(true)
                                    parebtNode:setCascadeOpacityEnabled(true)
                                end),
                                cc.EaseSineInOut:create( cc.FadeOut:create(6/30))
                                ),
                                cc.TargetedAction:create( mediator:GetViewComponent() ,
                                cc.Sequence:create(
                                cc.CallFunc:create(function ()
                                    mediator:GetViewComponent():setVisible(false)
                                    mediator:GetViewComponent():setOpacity(0)
                                end),
                                cc.DelayTime:create(5/30 ),
                                cc.CallFunc:create( function ()
                                    mediator:GetViewComponent():setVisible(true)
                                end),

                                cc.EaseSineInOut:create( cc.FadeIn:create(9/30) )
                                )
                                )
                            ),
                            cc.CallFunc:create(function ()
                                local zorder =  self:GetViewComponent():getLocalZOrder()
                                self:GetViewComponent():setLocalZOrder(checkint(zorder ) - 129 )
                                cardImage:setCascadeOpacityEnabled(true)
                                parebtNode:setCascadeOpacityEnabled(true)
                                self:GetViewComponent():setOpacity(255)
                                cardImage:setScale(1)
                                self.isAction = false
                            end)
                            )
                            self:GetViewComponent():runAction(seqAction)
                            --self.viewCollect[tostring(self.preIndex)]:setOpacity(0)
                            --self:GetViewComponent():setOpacity(0)
                        end
                    end
                end
            else
                if self.movedTime_ then
                    self.offsetValue_ = layoutPos.x
                    if self.endedTime_ - self.movedTime_ < INTERVAL_INTERVAL and   self.isTouchMoving_ then
                        self.inertiaSpeed_ = (self.endedPoint_.x - self.touchBeginPoint.x) * 0.5
                        if self.inertiaUpdateHandler_ then -- 如果该定时器存在 就直接暂停该定时器
                            scheduler.unscheduleGlobal(self.inertiaUpdateHandler_)
                            self.inertiaUpdateHandler_ = nil
                        end
                        self.inertiaUpdateHandler_ = scheduler.scheduleUpdateGlobal(function()
                            self.offsetValue_ =  self.offsetValue_ + self.inertiaSpeed_
                            self.viewCollect[tostring(self.preIndex)]:setPosition(cc.p(self.offsetValue_ , 0 ))
                            if math.abs( self.offsetValue_ ) + display.SAFE_RECT.width > size.width or  self.offsetValue_  > 0  then
                                if self.inertiaUpdateHandler_ then
                                    scheduler.unscheduleGlobal(self.inertiaUpdateHandler_)
                                    self.inertiaUpdateHandler_ = nil
                                end
                                local _x =   self.offsetValue_   > 0  and 0 or display.SAFE_RECT.width - size.width
                                self.viewCollect[tostring(self.preIndex)]:runAction(cc.Sequence:create({
                                    cc.CallFunc:create(function()  self.isAction = true end ),
                                    cc.MoveTo:create(SCROLL_TIME, cc.p(_x,0)) ,
                                    cc.CallFunc:create(function()
                                        self.isAction = false
                                        if self.viewCollect[tostring(self.preIndex)] then
                                            local _x =  self.viewCollect[tostring(self.preIndex)]:getPositionX()
                                            local page = math.ceil( math.abs( _x ) / display.SAFE_RECT.width)  +  1
                                            if self.alreadyLoad[tostring(self.preIndex) ][tostring(page)] then
                                                for i = 1 , page do
                                                    if not  self.alreadyLoad[tostring(self.preIndex) ][tostring( i )].isHave  then
                                                        self:AddCardImagePage(tostring(self.preIndex) , i )
                                                    end
                                                end

                                            end
                                        end
                                    end )
                                }))
                            else
                                self.inertiaSpeed_ = self.inertiaSpeed_ * INTERVAL_FALL
                                if math.abs(self.inertiaSpeed_) < 4 then
                                    if self.inertiaUpdateHandler_ then
                                        scheduler.unscheduleGlobal(self.inertiaUpdateHandler_)
                                        self.inertiaUpdateHandler_ = nil
                                    end
                                end
                            end

                        end)
                    end
                    self.movedTime_ = nil
                    return true
                end
            end
        end
    end,__G__TRACKBACK__)

    return true
end


function CardEncyclopediaMediator:CheckPointInImage(v)
    local isInConetId = nil
    local image = self.viewCollect[tostring(self.preIndex)]:getChildByTag(checkint(v.id))
    if image then
        local iamagePos = self.viewCollect[tostring(self.preIndex)]:convertToNodeSpace(self.touchBeginPoint)
        local isIn =  self:InRectangleContent(image ,iamagePos)
        local pos = image:convertToNodeSpace(self.touchBeginPoint)
        if isIn then
            isIn = self:JuageInPolygonPoint(pos ,v.nodes)
            if isIn then
                isInConetId = v.id
            else
                isIn = self:JuageInPolygonLine(pos,v.nodes)
                if   isIn  then
                    isInConetId = v.id
                else
                    isIn = self:RadialIntersectant(pos,v.nodes)
                    if isIn then
                        isInConetId = v.id
                    end
                end
            end
        end
    end
    return isInConetId
end
--==============================--
--desc: 排序数据  规格
--[[
     {
         卡片类型={
            page = {
                isHave  =false ,
                cards = {}
                } ， page ：{ }
            }
    }
 --]]
--time:2017-08-02 03 :16:34
--@return
--==============================--
function CardEncyclopediaMediator:SortCardsDataAndPage()
    for k , v in pairs(self.cardOrderData) do
        for kk ,vv in pairs (v) do
            if  self.allCardPointInfor[checkint(k)] and self.allCardPointInfor[checkint(k)][kk]  then
                self.allCardPointInfor[checkint(k)][kk].zorder = vv
             end
        end

    end
    for  i =1 , #self.allCardPointInfor do
        if type(self.allCardPointInfor[i]) == "table"  then
            local index = tostring(i)
            if not   self.alreadyLoad[index] then
                 self.alreadyLoad[tostring(i)]  = {} -- 记录不同卡牌类型的数据
            end
            for k , v in pairs (self.allCardPointInfor[i] ) do
                v.page = math.floor(v.x/display.SAFE_RECT.width) +1
                v.page = v.page > 0 and v.page or 1
                local data = self.alreadyLoad[index][tostring(v.page)]
                if not data then -- 记录每一页的数据
                    data = {}
                    data.isHave  =  false
                    data.cards  =  {}
                end
                local count  = #data.cards
                data.cards[count+1] = v  -- 插入到
                self.alreadyLoad[index][tostring(v.page)] = data
            end
        end
    end
    self:RoundMathNum( self.alreadyLoad)
end

--[[
    给加载的页面加载顺序 ，只生成第一屏的随机数
--]]
function CardEncyclopediaMediator:RoundMathNum(alreadyLoad)
    local roundTable = {}
    for k , v in pairs(alreadyLoad) do
        roundTable[k] = {}
        if v["1"] then
            for i =1 , #v["1"].cards do -- 有多少张卡牌 ，就对应几个数据
                roundTable[k][i] = i
            end
        end
    end
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
    for k ,v in pairs(alreadyLoad) do
        if v["1"]  then
            for i =1 ,  #v["1"].cards do -- 只给第一页数据排序
                if 1 ~= #roundTable[k] then
                    local sort = math.random(1,#roundTable[k])  -- 生成随机数的顺序
                    v["1"].cards[i].sort = roundTable[k][sort] --去当前位置的顺序 的值
                    table.remove(roundTable[k], sort) -- 删除当前位置的顺序 避免重复
                else
                    v["1"].cards[i].sort = roundTable[k][1]
                end
            end
        end
    end
end

function CardEncyclopediaMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if self.preClickIndex == tag  then -- 如果点击同一个按钮不做更新处理
        return
    end
    if not self.viewCollect[tostring(tag)] then
         self.viewCollect[tostring(tag)] =  self:GetViewComponent():CreateCardLayout(tag)
         self:AddCardImagePage(tostring(tag) ,1)
    end
    self:DealWithClickButton(tag)
    self.preIndex = tag
end


function CardEncyclopediaMediator:DealWithClickButton(tag)
    local btn =  self.viewData.checkButtons[tostring(tag)]
    if  btn.bossKindsName then
        --display.commonLabelParams(btn.bossKindsName,{ fontSize = 50})
        btn.bossKindsName:setTTFConfig({fontFilePath = TTF_GAME_FONT,fontSize = 28})
    end
    if  btn.prograssName then
        display.commonLabelParams(btn.prograssName,{ fontSize = 24})
        --display.commonLabelParams(btn.collectLabel,{ fontSize = 24})
        self:UpdateOneButton(btn)
    end
    self.viewCollect[tostring(tag)]:setVisible(true)
    -- 显示当前点击按钮的界面
    btn:setNormalImage( _res( 'ui/home/handbook/pokedex_monster_tab_select.png'))
    btn:setEnabled(false)
    if self.preIndex then
        local btn =  self.viewData.checkButtons[tostring(self.preIndex)]
        if  btn.bossKindsName then
            --display.commonLabelParams(btn.bossKindsName,{ fontSize = 24})
            btn.bossKindsName:setTTFConfig({fontFilePath = TTF_GAME_FONT,fontSize = 24})

        end
        if  btn.prograssName then
            --display.commonLabelParams(btn.collectLabel,{ fontSize = 22})
            display.commonLabelParams(btn.prograssName,{ fontSize = 22})
            self:UpdateOneButton(btn)
        end
        self.viewCollect[tostring(self.preIndex)]:setVisible(false)
        -- 设置当前按钮的状态为隐藏状态
        btn:setNormalImage(_res( 'ui/home/handbook/pokedex_monster_tab_default.png'))
        btn:setEnabled(true)
    end
end
-- 更新收集显示的字体
function CardEncyclopediaMediator:UpdateOneButton(btn)
    --local v = btn
    --local prograssNameSize = display.getLabelContentSize(v.prograssName)
    --local collectLabelSize = display.getLabelContentSize(v.collectLabel)
    --local contentSize = cc.size(prograssNameSize.width + collectLabelSize.width , collectLabelSize.height)
    --v.prograssNameLayout:setContentSize(contentSize)
    --v.collectLabel:setPosition(0,contentSize.height/2)
    --v.prograssName:setPosition(cc.p(collectLabelSize.width , contentSize.height/2 ))
end
--==============================--
--desc:加载不同的card
--time:2017-08-02 02:05:44
--@type: type 表示卡牌的类型
--@page: page 表示页面
--@return
--==============================--
function CardEncyclopediaMediator:AddCardImagePage(type , page)
	if self.alreadyLoad[type] then
		if self.alreadyLoad[type][tostring(page)] and  self.alreadyLoad[type][tostring(page)].isHave then
			return
		else
            if  not  self.alreadyLoad[type][tostring(page)]  then
                self.alreadyLoad[type][tostring(page)] = {}
            end
            self.alreadyLoad[type][tostring(page)].isHave = true
			for k , v in pairs (self.alreadyLoad[tostring(type)][tostring(page)].cards or {} ) do
                local cardId = checkint(v.id)
                local datas = {}
                if isChinaSdk() then
                    datas = CommonUtils.GetConfig('cards', 'onlineResourceTrigger', cardId)
                else
                    datas = CommonUtils.GetConfig('cards', 'card', cardId)
                end
                local path = ""
                local isConfig = false

                path =_res(string.format('cards/storycard/pokedex_card_%s.png', cardId))
                if not  datas then
                    local  pathOne =  _res(string.format('cards/storycard/pokedex_card_%s_2.png', cardId))
                    if   utils.isExistent(pathOne) then
                        path = pathOne
                    end
                else
                    isConfig = true
                end
                local isHave =  gameMgr:GetCardDataByCardId(v.id )
                local cardIdImage = FilteredSpriteWithOne:create( path)
                local cardIdImageSize = cardIdImage:getContentSize()
                local cardParent = CLayout:create(cardIdImageSize)
                cardParent:setAnchorPoint(display.LEFT_BOTTOM)
                cardParent:setPosition(cc.p(v.x ,v.y))
                cardIdImage:setPosition(cc.p(cardIdImageSize.width/2, cardIdImageSize.height/2))
                cardParent:addChild(cardIdImage)
                cardParent:setTag(checkint(v.id))
                if ( not isHave)  and isConfig then
                    cardIdImage:setFilter(filter.newFilter('GRAY'))
                end
                cardIdImage:setCascadeOpacityEnabled(true)
                cardIdImage:setAnchorPoint(display.CENTER)
                cardIdImage:setTag(checkint(v.id))
                self.viewCollect[tostring(type)]:addChild(cardParent , checkint(v.zorder) )
                if page == 1 then
                    local numBei = type == 4 and 1 or 0.5
                    cardIdImage:setOpacity(0)
                    cardIdImage:setScale(1.28)
                    cardIdImage:runAction( cc.Sequence:create(
                            cc.DelayTime:create((k -1) * 2/30 * numBei) , cc.Spawn:create(
                                cc.EaseSineInOut:create(cc.ScaleTo:create(5/30 ,0.98)),
                                cc.FadeIn:create(5/30)
                            ), cc.ScaleTo:create(2/30,1)
                        )
                    )
                end
			end
		end
	end
end

--==============================--
--desc:判断是否在矩形的内部
--time:2017-07-28 08:37:33
--@return
--==============================--
function CardEncyclopediaMediator:InRectangleContent(image  , pos)
    local isIn = false
    local rect = image:getBoundingBox()
    isIn = cc.rectContainsPoint(rect,pos)
    return isIn
end


function CardEncyclopediaMediator:JuageInPolygonPoint(pos , posTable)
    local isIn = false
    for k , v in pairs (posTable) do
        if pos.x == v.x and pos.y == v.y then -- 证明改图新是在多边形的点上
            isIn = true
            break
        end
    end
    return isIn
end
--==============================--
--desc:判断是否在多边形的边上
--time:2017-07-31 02:52:56
--@pos:传入点击的点
--@posTable:传入的多边形的点
--@return
--==============================--
function CardEncyclopediaMediator:JuageInPolygonLine(pos ,posTable )
    local isIn = false
    local count = #posTable
    for i =1 , count do
        local addI = i +1
        if  addI > count then  --这个表示链接线段的点点
            addI = addI - count
        end
        -- 计算一条线的斜率
        local isParallel = false
        if (pos.x - posTable[i].x) == 0 and (posTable[addI].x - posTable[i].x) == 0  then  -- 计算线的斜率是否在竖直方向上
            isParallel = true
        elseif  (pos.x - posTable[i].x) ~= 0 and (posTable[addI].x - posTable[i].x) ~= 0 then
            local vecOneNum = (pos.y - posTable[i].y) /(pos.x - posTable[i].x)
            -- 计算第二条线的斜率
            local vecTwoNum =  (posTable[addI].y - posTable[i].y) /(posTable[addI].x - posTable[i].x)
            if vecTwoNum == vecOneNum then
                isParallel = true
            end
        end

        if isParallel then  -- 如果两条线段的斜率相等 则证明是在一条线上
            local firstSegment = math.sqrt( math.pow(pos.y - posTable[i].y ,2)  +  math.pow(pos.x - posTable[i].x ,2)  )
            local secondSegment = math.sqrt( math.pow(pos.y - posTable[addI].y ,2)  +  math.pow(pos.x - posTable[addI].x ,2)  )
            local thirdSegment = math.sqrt( math.pow(posTable[addI].y - posTable[i].y ,2)  +  math.pow(posTable[addI].x - posTable[i].x ,2)  )

            if thirdSegment > secondSegment  and thirdSegment > firstSegment then  -- 如果第三条边最长 ，证明点击的点是在该线段上
                isIn = true
                break
            end
        end
        -- 取得点与其他两点相连
    end
    return isIn
end

--==============================--
--desc:利用半线理论检测该点是否在多边形的内部
--计算点在多边形内外的算法
-- 1． 理论基础  半线理论 说明：  判断一个点是否在多边形内，只要从这个点向多边形外做一条射线（随机取极远处的一个点，以这两点为端点做一条线段即可），
--  那么统计射线和多边形的边的交点个数，如果交点个数是奇数表明点在多边形内，否则在多边形外 ，如果共享点的两边在射线的同一侧 若交点的在射线下面计数器加二 若交点在计数器上面计数器为零 记 上无下有
--time:2017-07-28 05:09:30
--@return
--==============================--
function CardEncyclopediaMediator:RadialIntersectant(pos,posTable)
    -- 以本点向右做一个射线
    local count = #posTable
    local i = 1
    local intersectantNum = 0 -- 交点坐标的记录
    while(i <= count) do
        local addI = i +1
        if addI > count then
            addI = addI - count
        end

        local maxY =(posTable[i].y >  posTable[addI].y and posTable[i].y)  or posTable[addI].y
        local minY = (posTable[i].y <  posTable[addI].y and posTable[i].y)  or posTable[addI].y
        local maxX = (posTable[i].x >  posTable[addI].x and posTable[i].x ) or posTable[addI].x
        if pos.x <= maxX and pos.y >= minY and pos.y <=maxY then --  证明射线和线段相交

            if minY ~= maxY then
                if pos.y > minY  and  pos.y < maxY then  --相交点记录
                    if posTable[i].x -  posTable[addI].x  ~= 0  then  --不在竖直方向上
                        local k = (posTable[i].y -  posTable[addI].y ) /   (posTable[i].x -  posTable[addI].x)
                        local b  =  posTable[i].y  - k * posTable[i].x
                        local _x = (pos.y  - b) / k
                        if  _x >= pos.x then
                            intersectantNum  = intersectantNum +1
                        end
                    else
                        if  posTable[i].x > pos.x then
                             intersectantNum  = intersectantNum +1
                        end
                    end

                elseif pos.y == maxY  then   -- 线段在射线下面
                    intersectantNum = intersectantNum +1
                end
            end
        end
        i = i + 1
    end
    if  intersectantNum % 2 == 0 then
        return false
    else
         return true
    end
end

function CardEncyclopediaMediator:OnRegist()
    sceneWorld:setMultiTouchEnabled(true)
end

function CardEncyclopediaMediator:OnUnRegist()
    sceneWorld:setMultiTouchEnabled(false)
end

return CardEncyclopediaMediator
