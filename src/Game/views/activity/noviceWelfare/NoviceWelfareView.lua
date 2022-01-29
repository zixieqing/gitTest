--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利View
--]]
local RemindIcon =  require('common.RemindIcon')
local NoviceWelfareView = class('NoviceWelfareView', function ()
    local node = CLayout:create(display.size)
    node.name = 'NoviceWelfareView'
    node:enableNodeEvents()
    return node
end)
local VIEW_TYPE = {
    WAIT_VIEW     = 1,
    ACTIVITY_VIEW = 2,
}
local TAB_TYPE = {
    NOVICE_WEIFARE_DAILY      = 1,
    NOVICE_WEIFARE_TASK_LIMIT = 2,
    NOVICE_WEIFARE_GIFT_LIMIT = 3,
}
local RES_DICT = {
    VIEW_BG            = _res('ui/home/activity/noviceWelfare/tast_big_bg.png'),
    VIEW_WAIT_BG       = _res('ui/home/activity/noviceWelfare/gift_bag_big_bg.png'),
    TIPS_BTN           = _res('ui/common/common_btn_tips.png'),
    WAIT_ROLE_IMG      = _res('ui/home/activity/noviceWelfare/activity_task_role.png'),
    DIALOG             = _res('ui/home/activity/noviceWelfare/dialogue_bg_2.png'),
    RULE_BG            = _res('ui/home/activity/noviceWelfare/activity_task_bg_words.png'),
    TAB_BTN_N          = _res('ui/common/common_btn_sidebar_common.png'),
    TAB_BTN_S          = _res('ui/common/common_btn_sidebar_selected.png'),
}
local createView = nil 
local createWaitView = nil 
function NoviceWelfareView:ctor( ... )
    local args = unpack({...})
    self:SetType(checkint(args.type))
    self:InitUI()
end
--[[
init ui
--]]
function NoviceWelfareView:InitUI()
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        if self.type == VIEW_TYPE.WAIT_VIEW then
            self.viewData = createWaitView( )
        elseif self.type == VIEW_TYPE.ACTIVITY_VIEW then
            self.viewData = createView( )
        else
            return 
        end
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(display.cx, display.cy + 55))

        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
创建活动页面
--]]
function createView()
    local TAB_DEFINE = {
        {name = __('日常任务'), tag = TAB_TYPE.NOVICE_WEIFARE_DAILY},
        {name = __('限时任务'), tag = TAB_TYPE.NOVICE_WEIFARE_TASK_LIMIT},
        {name = __('限时特惠'), tag = TAB_TYPE.NOVICE_WEIFARE_GIFT_LIMIT},
    }
    local bg = display.newImageView(RES_DICT.VIEW_BG, 0, 0)
    local size = cc.size(bg:getContentSize().width + 150, bg:getContentSize().height)
    local view = CLayout:create(size)
    bg:setPosition(cc.p(size.width / 2, size.height / 2))
    view:addChild(bg, 1)
    -- mask --
    local mask = display.newLayer(size.width/2 - 24,size.height/2 - 35,{ap = display.CENTER , size = cc.size(bg:getContentSize().width - 90, bg:getContentSize().height - 80), enable = true, color = cc.c4b(0,0,0,0)})
    view:addChild(mask, -1)
    -- mask --
    -- 提示
    local tipsBtn = display.newButton(size.width / 2 + 214, size.height / 2 + 282, {n = RES_DICT.TIPS_BTN})
    view:addChild(tipsBtn , 5)
    -- 标题
    local titleLabel = display.newLabel(size.width / 2, size.height / 2 + 286, {text = __('新手福利'), fontSize = 28, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
    view:addChild(titleLabel, 5)
    -- 页签
    local tabMask = display.newLayer(size.width - 80, size.height - 350,{ap = display.CENTER , size = cc.size(150, 310), enable = true, color = cc.c4b(0,0,0,0)})
    view:addChild(tabMask, -1)
    local tabBtnDict = {}
    for i,v in ipairs(TAB_DEFINE) do
        local tabButton = display.newCheckBox(0,0,
            {n = _res(RES_DICT.TAB_BTN_N),
            s = _res(RES_DICT.TAB_BTN_S),})

        local buttonSize = tabButton:getContentSize()

        display.commonUIParams(
            tabButton,
            {
                ap = cc.p(0, 0.5),
                po = cc.p(size.width - 150, size.height - 160 - (i) * (buttonSize.height - 20))
            })
        view:addChild(tabButton, 5)
        tabButton:setTag(v.tag)
        tabBtnDict[tostring( v.tag )] = tabButton

        local tabNameLabel = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y + 4,
            fontWithColor(2,{text = v.name, color = '#5c5c5c', fontSize = 20, ap = cc.p(0.5, 0)}))
        tabButton:addChild(tabNameLabel)
        tabNameLabel:setName('title')
        tabNameLabel:setTag(3)
        local remindIcon = RemindIcon.addRemindIcon({parent = tabButton, tag = v.tag, po = cc.p(buttonSize.width/2 + 48, buttonSize.height/2 + 35)})
        remindIcon:setName('remindIcon')
    end
    -- centerLayout
    local centerLayoutSize = cc.size(1150, 600)
    local centerLayout = CLayout:create(centerLayoutSize)
    centerLayout:setPosition(cc.p(size.width / 2 - 70, size.height / 2 - 75))
    view:addChild(centerLayout, 1) 
    return {
        view                = view,
        tipsBtn             = tipsBtn,
        tabBtnDict          = tabBtnDict,
        centerLayout        = centerLayout,
    }
end
--[[
创建等待页面
--]]
function createWaitView()
    local bg = display.newImageView(RES_DICT.VIEW_WAIT_BG, 0, 0)
    local size = bg:getContentSize()
    local view = CLayout:create(size)
    bg:setPosition(cc.p(size.width / 2, size.height / 2))
    view:addChild(bg, 1)
    
    -- mask --
    local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
    view:addChild(mask, -1)
    -- mask --

    -- 提示
    local tipsBtn = display.newButton(size.width / 2 + 214, size.height / 2 + 282, {n = RES_DICT.TIPS_BTN})
    view:addChild(tipsBtn , 5)
    -- 标题
    local titleLabel = display.newLabel(size.width / 2, size.height / 2 + 286, {text = __('新手福利'), fontSize = 28, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
    view:addChild(titleLabel, 5)

    -- centerLayout -- 
    local centerLayoutSize = cc.size(1015, 600)
    local centerLayout = CLayout:create(centerLayoutSize)
    centerLayout:setPosition(cc.p(size.width / 2, size.height / 2 - 80))
    view:addChild(centerLayout, 1)
    -- 角色立绘
    local roleImg = display.newImageView(RES_DICT.WAIT_ROLE_IMG, -14, 21, {ap = display.LEFT_BOTTOM})
    centerLayout:addChild(roleImg, 1)
    -- 气泡
    local dialog = display.newImageView(RES_DICT.DIALOG, centerLayoutSize.width / 2 + 178, centerLayoutSize.height / 2 + 76)
    centerLayout:addChild(dialog, 1)
    local dialogLabel = display.newLabel(dialog:getContentSize().width / 2, dialog:getContentSize().height / 2, {text = '', fontSize = 30, color = '#b92c2c', ttf = true, font = TTF_GAME_FONT, reqW = 500})
    dialog:addChild(dialogLabel, 1)
    -- 规则
    local ruleBg = display.newImageView(RES_DICT.RULE_BG, centerLayoutSize.width / 2 - 3, centerLayoutSize.height / 2 + 5)
    centerLayout:addChild(ruleBg, 1)
    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))[tostring(INTRODUCE_MODULE_ID.NOVICE_WELFARE_WAIT)] or {}
    local ruleLabel = display.newLabel(50, 95, {text = moduleExplainConf.descr or '', fontSize = 24, color = '#ffffff', ap = display.LEFT_TOP, w = 910})
    ruleBg:addChild(ruleLabel, 1)
    -- centerLayout -- 
    return {
        view                = view,
        tipsBtn             = tipsBtn,
        dialogLabel         = dialogLabel,
    }
end

--[[
进入动画
--]]
function NoviceWelfareView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function NoviceWelfareView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
更新等待页面倒计时
--]]
function NoviceWelfareView:UpdateWaitTimeLabel( seconds )
    if self:GetType() ~= VIEW_TYPE.WAIT_VIEW or not seconds then return end
    local viewData = self:GetViewData()
    viewData.dialogLabel:setString(string.fmt(__('任务开启倒计时:_time_'), {['_time_'] = CommonUtils.GetFormattedTimeBySecond(seconds, ':')}))
end
--[[
刷新页签红点状态 
@params tag   int  页签tag
@params state bool 红点状态 
--]]
function NoviceWelfareView:RefreshTabRemindIcon( tag, state )
    local viewData = self:GetViewData()
    local btn = viewData.tabBtnDict[tostring(tag)]
    if not btn then return end
    local remindIcon = btn:getChildByName('remindIcon')
    remindIcon:Animate(state)
end
--[[
改变页面类型
--]]
function NoviceWelfareView:ChangeViewType( viewType )
    self:removeAllChildren()
    self:SetType(viewType)
    self:InitUI()
end
--[[
设置type
--]]
function NoviceWelfareView:SetType( type )
    self.type = type
end
--[[
获取type
--]]
function NoviceWelfareView:GetType( )
    return self.type
end
--[[
获取viewData
--]]
function NoviceWelfareView:GetViewData()
    return self.viewData
end
return NoviceWelfareView