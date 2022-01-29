--[[
 * descpt : 品鉴之旅 满星奖励 界面
]]
local VIEW_SIZE = display.size
local TastingTourQuestStarsRewardView = class('TastingTourQuestStarsRewardView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tastingTour.TastingTourQuestStarsRewardView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil

local RES_DIR = {
    BG                 = _res("ui/tastingTour/grade/fishtravel_grade_bg_awards.png"),
    BTN_ORANGE         = _res('ui/common/common_btn_orange.png'),
}

function TastingTourQuestStarsRewardView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initialUI()
end

function TastingTourQuestStarsRewardView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:initView(self.args.startNum)
        self:initAction()
	end, __G__TRACKBACK__)
end

function TastingTourQuestStarsRewardView:initView(startNum)
    local viewData = self:getViewData()
    local stageLabel = viewData.stageLabel
    display.commonLabelParams(stageLabel, {text = string.format("%s/%s", startNum, startNum)})
end

function TastingTourQuestStarsRewardView:initAction()
    local viewData = self:getViewData()
    local confirmBtn = viewData.confirmBtn
    display.commonUIParams(confirmBtn, {cb = handler(self, self.onClickShallowAction)})
end

function TastingTourQuestStarsRewardView:onClickShallowAction(sender)
    local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
    uiMgr:GetCurrentScene():RemoveDialog(self)
    
    uiMgr:AddDialog('common.RewardPopup', {rewards = self.args.rewards or {}})
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    local spineAnimation = sp.SkeletonAnimation:create(
            'effects/tastingTour/manxing.json',
            'effects/tastingTour/manxing.atlas',
            1
    )
    spineAnimation:update(0)
    spineAnimation:addAnimation(0, 'play', false)
    spineAnimation:addAnimation(0, 'idle', true)
    spineAnimation:setPosition(cc.p(display.cx, display.cy))
    shallowLayer:addChild(spineAnimation)

    view:addChild(display.newLabel(display.cx, display.cy - 30, fontWithColor(19, {text = __('星牌收集奖励')})), 1)

    local stageLabel = display.newLabel(display.cx, display.cy - 60, fontWithColor(14))
    view:addChild(stageLabel, 1)

    local bgLayer = display.newLayer(display.cx, display.cy - 110, {bg = RES_DIR.BG, ap = display.CENTER})
    local bgSize  = bgLayer:getContentSize()
    view:addChild(bgLayer)

    local confirmBtn = display.newButton(bgSize.width / 2, 44, {n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(confirmBtn, fontWithColor('14', {text = __('领取')}))
    bgLayer:addChild(confirmBtn)

    return {
        view              = view,
        shallowLayer      = shallowLayer,
        confirmBtn        = confirmBtn,
        stageLabel        = stageLabel,
    }
end

function TastingTourQuestStarsRewardView:getViewData()
	return self.viewData_
end

return TastingTourQuestStarsRewardView