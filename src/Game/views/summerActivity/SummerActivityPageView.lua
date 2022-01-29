--[[
 * descpt : 创建工会 home 界面
]]
local VIEW_SIZE = cc.size(1035, 637)
local SummerActivityPageView = class('SummerActivityPageView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.tagMatch.SummerActivityPageView'
	node:enableNodeEvents()
	return node
end)

local cardMgr  = AppFacade.GetInstance():GetManager('CardManager')
local summerActMgr = app.summerActMgr

local CreateView         = nil
local CreateTeamCell     = nil
local CreateCardHead     = nil

local RES_DIR = {
    BG            = _res("ui/home/activity/summerActivity/entrance/activity_bg_summer.jpg"),
    ENTER_BG      = _res("ui/home/activity/summerActivity/entrance/summer_activity_bg_enter.png"),
    ORANGE_BTN    = _res('ui/common/common_btn_orange.png'),
}

local BUTTON_TAG = {
    RULE        = 100,
    FIGHT       = 101,
    SIGH_UP     = 102,
    LOOK_REWARD = 103,
    RANK        = 104,
}

function SummerActivityPageView:ctor( ... )
    self.args = unpack({...})
    self:initData()
    self:initialUI()
end

function SummerActivityPageView:initData()
    
end

function SummerActivityPageView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        display.commonUIParams(self:getViewData().view, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
        self:addChild(self:getViewData().view)
        
	end, __G__TRACKBACK__)
end

function SummerActivityPageView:updateBackground(backgroundImage)
    local viewData          = self:getViewData()
    local baseLayer         = viewData.baseLayer
    if backgroundImage then
        baseLayer:setBackground(backgroundImage)
    end
end

--[[
  更新倒计时 
  @params leftSeconds    剩余时间
]]
function SummerActivityPageView:updateCountDown(leftSeconds, timeDesc)
    local viewData          = self:getViewData()
    local baseLayer         = viewData.baseLayer
    if timeDesc then
        baseLayer:setTimeTitleLabel(timeDesc)
    end
    if leftSeconds then
        baseLayer:setTimeLabel(checkint(leftSeconds))
    end
end

--[[
  更新规则
  @params rule    规则
]]
function SummerActivityPageView:updateRule(rule)
    local baseLayer = self:getBaseLayer()
    baseLayer:setRule(rule)
end

CreateView = function ()
    local view = CLayout:create(VIEW_SIZE)
    -- local size = view:getContentSize()

    local baseLayer = require("common.CommonBaseActivityView").new({showFullRule = true})
    display.commonUIParams(baseLayer, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
    view:addChild(baseLayer)
    
    local enterBg = display.newImageView(RES_DIR.ENTER_BG, VIEW_SIZE.width - 250, 210)
    view:addChild(enterBg)

    local enterBtn = display.newButton(enterBg:getPositionX(), enterBg:getPositionY(), {n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(enterBtn, fontWithColor('14', {text = summerActMgr:getThemeTextByText(__('前 往'))}))
    view:addChild(enterBtn)

    return {
        view           = view,
        baseLayer      = baseLayer,
        enterBtn     = enterBtn,
    }
end

function SummerActivityPageView:getViewData()
	return self.viewData_
end

function SummerActivityPageView:getBaseLayer()
    return self:getViewData().baseLayer
end

return SummerActivityPageView