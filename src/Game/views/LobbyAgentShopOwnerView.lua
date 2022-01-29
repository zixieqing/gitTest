local LobbyAgentShopOwnerView = class('LobbyAgentShopOwnerView',
    function ()
        local node = CLayout:create(display.size)
        node.name = 'Game.views.LobbyAgentShopOwnerView'
        node:enableNodeEvents()
        return node
    end
)

local RES_DIR = {
    BACK                    =  _res("ui/common/common_btn_back"),
    TITLE                   =  _res('ui/common/common_title.png'),
    RULE_BG                 =  _res("ui/home/raidMain/raid_mode_bg_active.png"),
    QUESTION_MARK           =  _res('ui/common/common_btn_tips.png'),
    ROLE_CHOICE_BG          =  _res('avatar/ui/agentShopowner/restaurant_agent_role_choice_bg.png'),
    AGENT_COUPON_BG         =  _res('ui/home/nmain/common_btn_huobi.png'),
    ROLE_SPLIT_LINE         =  _res('avatar/ui/agentShopowner/restaurant_agent_role_split_line.png'),
    CELL_BG_ACTIVE          =  _res('avatar/ui/agentShopowner/restaurant_agent_role_bg_active.png'),
    CELL_BG_INACTIVE        =  _res('avatar/ui/agentShopowner/restaurant_agent_role_bg_inactive.png'),
    CELL_SELECTED_FRAME     =  _res('ui/mail/common_bg_list_selected.png'),
    BTN_ORANGE              =  _res('ui/common/common_btn_orange.png'),
    BTN_WHITE               =  _res('ui/common/common_btn_white_default.png'),
    COUNT_DOWN_BG           =  _res('ui/common/common_btn_white_default_2.png'),
    HEAD_FRAME              =  _res('ui/common/common_frame_food.png'),
    AGENT_TIME_BG_ACTIVE    =  _res('avatar/ui/agentShopowner/restaurant_agent_time_bg_active.png'),
    AGENT_TIME_BG_INACTIVE  =  _res('avatar/ui/agentShopowner/restaurant_agent_time_bg_inactive.png'),
    ROLE_NAME_BG            =  _res('avatar/ui/agentShopowner/restaurant_agent_role_name_bg.png'),
    ROLE_NAME_SELECTED_BG   =  _res('avatar/ui/agentShopowner/restaurant_agent_role_name_selected_bg.png'),
    
}

local CreateView      = nil
local CreateCell_     = nil
local CreateRoleHead  = nil

function LobbyAgentShopOwnerView:ctor( ... )
    self.args = unpack({...})
    self:initUi()
end

function LobbyAgentShopOwnerView:initUi()
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    display.commonUIParams(self.viewData_.backBtn, {cb = handler(self, self.CloseHandler)})
end

function LobbyAgentShopOwnerView:getArgs()
    return self.args
end

function LobbyAgentShopOwnerView:getViewData()
    return self.viewData_
end

function LobbyAgentShopOwnerView:CloseHandler()
	local args = self:getArgs()
	-- local tag = args.tag
	local mediatorName = args.mediatorName
	
	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end
	
end

function LobbyAgentShopOwnerView:CreateCell(size)
    return CreateCell_(size)
end

CreateView = function ()
    local bgSize = display.size

    local view = display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_BOTTOM})
    local touchLayer = display.newLayer(0, 0, {size = bgSize, color = cc.c4b(0,0,0,156), enable = true, ap = display.LEFT_BOTTOM})
    view:addChild(touchLayer)

    local backBtn = display.newButton(0, 0, {n = RES_DIR.BACK})
    display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
    view:addChild(backBtn, 5)

    local titleLabel = display.newButton(display.SAFE_L + 130, display.height + 2 ,{n = RES_DIR.TITLE, enable = false, ap = cc.p(0, 1)})
    display.commonLabelParams(titleLabel, {ttf = true, font = TTF_GAME_FONT, text = __('代理店长'), fontSize = 30, reqW = 250 ,  color = '#473227',offset = cc.p(0,-8)})
    view:addChild(titleLabel,5)

    -- role_2 密特拉 role_4 奥丽薇亚 role_1 伊祁 role_48 伊蕾娜
    -- role
    local roleLayer = display.newLayer()
	local roleNode = CommonUtils.GetRoleNodeById('role_2', 1)
    roleNode:setAnchorPoint(display.CENTER_TOP)
    roleNode:setPosition(cc.p(display.cx, display.height + 20))
    roleLayer:addChild(roleNode)
    roleNode:setScale(0.82)
    local roleNodeSize = roleNode:getContentSize()
    view:addChild(roleLayer)

    -- rule
    local ruleBgLayerSize = cc.size(376, 472)
    local ruleBgLayer = display.newLayer(display.cx - 285, display.cy, {ap = display.RIGHT_CENTER, size = ruleBgLayerSize})
    local ruleBg = display.newImageView(RES_DIR.RULE_BG, ruleBgLayerSize.width / 2, ruleBgLayerSize.height / 2, {ap = display.CENTER, size = ruleBgLayerSize, scale9 = true})
    ruleBgLayer:addChild(ruleBg)
    view:addChild(ruleBgLayer)

    local ruleTitle = display.newLabel(ruleBgLayerSize.width / 2, ruleBgLayerSize.height - 70, {ap = display.CENTER, font = TTF_GAME_FONT, ttf = true, fontSize = 28, color = '#e97a38', text = __('协议说明')})
    ruleBgLayer:addChild(ruleTitle)
    
    local ruleTitleSize = display.getLabelContentSize(ruleTitle)
    
    local scrollViewSize = cc.size(ruleBgLayerSize.width - 70, ruleBgLayerSize.height - 160)
    local scrollView = CScrollView:create(scrollViewSize)
    scrollView:setPosition(cc.p(ruleBgLayerSize.width / 2, ruleBgLayerSize.height - 92))
    scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.CENTER_TOP)
    ruleBgLayer:addChild(scrollView)

    local ruleLabel = display.newLabel(0, 0, {ap = display.LEFT_BOTTOM, w = 300})
    scrollView:getContainer():addChild(ruleLabel)

    -- 确定和取消
    local determineBtn = display.newButton(ruleBgLayer:getPositionX() - ruleBgLayerSize.width / 2, ruleBgLayer:getPositionY() - ruleBgLayerSize.height / 2 - 50, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE ,scale9 = true  } )
    display.commonLabelParams(determineBtn, fontWithColor(14, {text = __('委托') , paddingW = 20 }))
    view:addChild(determineBtn)
    determineBtn:setVisible(false)
    
    local cancelBtnLayerSize = cc.size(ruleBgLayerSize.width, 100)
    local cancelBtnLayer = display.newLayer(determineBtn:getPositionX(), determineBtn:getPositionY(), {ap = display.CENTER, size = cancelBtnLayerSize})
    view:addChild(cancelBtnLayer)
    cancelBtnLayer:setVisible(false)

    local countDownBg = display.newImageView(RES_DIR.COUNT_DOWN_BG, cancelBtnLayerSize.width / 2 - 5, cancelBtnLayerSize.height / 2, {ap = display.LEFT_CENTER})
    cancelBtnLayer:addChild(countDownBg)
    
    local countDownBgSize = countDownBg:getContentSize()
    local leftTimeLabel = display.newLabel(countDownBgSize.width / 2, countDownBgSize.height - 15, {ap = display.CENTER, fontSize = 18, color = '#5c5c5c', text = __('剩余时间')})
    countDownBg:addChild(leftTimeLabel)

    local countDownLabel = display.newLabel(countDownBgSize.width / 2, 20, {ap = display.CENTER, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#e55858', outlineSize = 1})
    countDownBg:addChild(countDownLabel)
    
    local cancelBtn = display.newButton(cancelBtnLayerSize.width / 2 + 5, cancelBtnLayerSize.height / 2, {ap = display.RIGHT_CENTER, n = RES_DIR.BTN_WHITE})
    display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
    cancelBtnLayer:addChild(cancelBtn)

    -- role choice layer
    local roleChoiceLayer = display.newLayer(display.SAFE_R - 50, display.cy, {ap = display.RIGHT_CENTER, bg = RES_DIR.ROLE_CHOICE_BG , scale9 = true, size =  cc.size(470,670) })
    view:addChild(roleChoiceLayer)
    
    local roleChoiceLayerSize = roleChoiceLayer:getContentSize()
    local agentCouponCountBg = display.newImageView(RES_DIR.AGENT_COUPON_BG, roleChoiceLayerSize.width / 2, roleChoiceLayerSize.height - 22, {ap = display.CENTER_TOP  })
    roleChoiceLayer:addChild(agentCouponCountBg)

    local agentCouponCountBgSize = agentCouponCountBg:getContentSize()
    
    local currencyIcon = display.newButton(roleChoiceLayerSize.width / 2 - agentCouponCountBgSize.width / 2 + 28, roleChoiceLayerSize.height - 40, {
        ap = display.RIGHT_CENTER, 
        n = _res(string.format( "arts/goods/goods_icon_%d.png", AGENT_COUPON_ID)),
        cb = function (sender)
            local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
            uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = AGENT_COUPON_ID, type = 1 })
        end
    })
    currencyIcon:setScale(0.375)
    roleChoiceLayer:addChild(currencyIcon)

    local currencyCountLabel = display.newLabel(agentCouponCountBgSize.width / 2 - 17, agentCouponCountBgSize.height / 2, fontWithColor(3, {ap = display.CENTER}))
    agentCouponCountBg:addChild(currencyCountLabel)
    

    local jumpLayer = display.newLayer(agentCouponCountBg:getPositionX() + agentCouponCountBgSize.width / 2, agentCouponCountBg:getPositionY(), {ap = display.RIGHT_TOP, enable = true, color = cc.c4b(0, 0, 0, 0), size = cc.size(45, agentCouponCountBgSize.height)})
    roleChoiceLayer:addChild(jumpLayer)

    -- local line = display.newImageView(RES_DIR.ROLE_SPLIT_LINE, roleChoiceLayerSize.width / 2, roleChoiceLayerSize.height - 86, {ap = display.CENTER})
    -- roleChoiceLayer:addChild(line)

    local tipsLabel = display.newLabel(40, roleChoiceLayerSize.height - 66, {ap = display.LEFT_TOP, w = roleChoiceLayerSize.width - 80, fontSize = 18, color = '#473227', text = __('Tips: 消耗一定量的委托券后，可以雇佣代理店长照顾餐厅。')})
    roleChoiceLayer:addChild(tipsLabel)

    local gridViewSize = cc.size(roleChoiceLayerSize.width - 60, roleChoiceLayerSize.height - 140)
    local gridViewCellSize = cc.size(202, 235) -- cc.size(roleChoiceLayerSize.width / 2, roleChoiceLayerSize.height / 2)
    local gridView = CGridView:create(gridViewSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(2)
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setPosition(cc.p(roleChoiceLayerSize.width / 2, roleChoiceLayerSize.height - 180))
    roleChoiceLayer:addChild(gridView)

    return {
        view                 = view,
        backBtn              = backBtn,
        scrollView           = scrollView,
        ruleLabel            = ruleLabel,
        roleLayer            = roleLayer,
        determineBtn         = determineBtn,
        cancelBtnLayer       = cancelBtnLayer,
        cancelBtn            = cancelBtn,
        countDownLabel       = countDownLabel,
        jumpLayer            = jumpLayer,
        currencyCountLabel   = currencyCountLabel,
        gridView             = gridView,
    }
end

CreateCell_ = function (size)
    local cell = CGridViewCell:new()

    local bg = display.newImageView(RES_DIR.CELL_BG_ACTIVE, 0, 0, {ap = display.CENTER})
    local bgSize = bg:getContentSize()
    display.commonUIParams(bg, {po = cc.p(bgSize.width / 2, bgSize.height / 2)})
    cell:setContentSize(bgSize)
    cell:addChild(bg)

    local frameBg = display.newImageView(RES_DIR.CELL_SELECTED_FRAME, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER, scale9 = true, size = cc.size(bgSize.width - 5, bgSize.height - 5)})
    cell:addChild(frameBg)
    frameBg:setVisible(false)

    local touchView = display.newLayer(bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,0)})
    cell:addChild(touchView)

    local headFrame, head, headName = CreateRoleHead('role_2', '11')
    display.commonUIParams(headFrame, {po = cc.p(bgSize.width / 2, bgSize.height - 35), ap = display.CENTER_TOP})
    -- headFrame:setScale(1.2)
    cell:addChild(headFrame)

    local tipLabel = display.newLabel(bgSize.width / 2, 45, {ap = display.CENTER, fontSize = 22, color = '#473227', text = __('已上任')})
    cell:addChild(tipLabel)
    tipLabel:setVisible(false)

    local headFrameSize = headFrame:getContentSize()
    local agentDescLayerSize = cc.size(bgSize.width, headFrame:getPositionY() - headFrameSize.height)
    local agentDescLayer = display.newLayer(bgSize.width / 2, agentDescLayerSize.height, {ap = display.CENTER_TOP, size = agentDescLayerSize})
    bg:addChild(agentDescLayer)
    -- agentDescLayer:setVisible(false)

    local currencyIcon = FilteredSpriteWithOne:create(_res(string.format( "arts/goods/goods_icon_%d.png", AGENT_COUPON_ID)))
    display.commonUIParams(currencyIcon, {po = cc.p(agentDescLayerSize.width / 2, agentDescLayerSize.height - 20), ap = display.RIGHT_CENTER})
    -- currencyIcon:setFilter(GrayFilter:create())
    currencyIcon:setScale(0.1875)

    local currencyLabel = display.newLabel(agentDescLayerSize.width / 2, agentDescLayerSize.height - 20, {ap = display.LEFT_CENTER, fontSize = 20, color = '#be3c3c', font = TTF_GAME_FONT, ttf = true, text = 'x1'})
    agentDescLayer:addChild(currencyIcon)
    agentDescLayer:addChild(currencyLabel)

    local agentTimeBg = display.newImageView(RES_DIR.AGENT_TIME_BG_ACTIVE, agentDescLayerSize.width / 2, 35, {ap = display.CENTER})
    agentDescLayer:addChild(agentTimeBg)

    local agentTimeLabel = display.newLabel(agentDescLayerSize.width / 2, 35, {fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#532314', outlineSize = 1})
    agentDescLayer:addChild(agentTimeLabel)

    cell.viewData = {
        bg             = bg,
        frameBg        = frameBg,
        touchView      = touchView,
        headFrame      = headFrame,
        head           = head,
        headName       = headName,
        agentDescLayer = agentDescLayer,
        currencyIcon   = currencyIcon,
        currencyLabel  = currencyLabel,
        agentTimeBg    = agentTimeBg,
        agentTimeLabel = agentTimeLabel,
        tipLabel       = tipLabel,
    }

    return cell
end

CreateRoleHead = function (id, name)
    -- local headFrame = display.newImageView(RES_DIR.HEAD_FRAME, 0, 0)
    local headFrame = FilteredSpriteWithOne:create(RES_DIR.HEAD_FRAME)

    local headFrameSize = headFrame:getContentSize()
    -- local head = display.newImageView(CommonUtils.GetNpcIconPathById(id, NpcImagType.TYPE_HALF_BODY), headFrameSize.width / 2, headFrameSize.height - 3, {ap = display.CENTER_TOP})
    -- headFrame:addChild(head)

    local head = FilteredSpriteWithOne:create(CommonUtils.GetNpcIconPathById(id, NpcImagType.TYPE_HALF_BODY))
    head:setAnchorPoint(display.CENTER_TOP)
    head:setPosition(cc.p(headFrameSize.width / 2, headFrameSize.height - 3))
    headFrame:addChild(head)
    -- head:setFilter(GrayFilter:create())

    local headNameBg = display.newImageView(RES_DIR.ROLE_NAME_BG, head:getPositionX(), 5, {ap = display.CENTER_BOTTOM})
    headNameBg:setScaleY(0.875)
    headFrame:addChild(headNameBg)


    local headName = display.newLabel(head:getPositionX(), 16, {ap = display.CENTER, text = tostring(name), fontSize = 20, color = '#5b3c25'})
    headFrame:addChild(headName)

    return headFrame, head, headName
end

return LobbyAgentShopOwnerView
