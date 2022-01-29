--[[
 * author : liuzhipeng
 * descpt : 活动 连续活跃活动 rewardNode
--]]
local ActivityContinuousActiveWeeklyNode = class('ActivityContinuousActiveWeeklyNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()   
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node.name = 'ActivityContinuousActiveWeeklyNode'
    return node
end)
local NODE_SIZE = cc.size(100, 210)
local RES_DICT = {
    BG_FINISH         = _res('ui/home/activity/continuousActive/activeness_bg_week_task_finish.png'),
    BG_UNDO           = _res('ui/home/activity/continuousActive/activeness_bg_week_task_undo.png'),
    BG_UNFINISH       = _res('ui/home/activity/continuousActive/activeness_bg_week_task_unfinish.png'),
    COMMON_BTN_ORANGE = _res('ui/common/common_btn_orange.png'),
    LINE              = _res('ui/home/activity/continuousActive/activeness_img_week_bar_line.png')
}
function ActivityContinuousActiveWeeklyNode:ctor(...)
    local args = unpack({...})
    self.callback = nil 
    self:InitUI()
end
--[[
初始化UI
--]]
function ActivityContinuousActiveWeeklyNode:InitUI()
    local CreateView = function (size)
        local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        local bg = display.newImageView(RES_DICT.BG_FINISH, size.width / 2, size.height / 2 + 10)
        view:addChild(bg , 1)
        local titleLabel = display.newLabel(size.width / 2, size.height - 20, fontWithColor(4, {text = '111'}))
        view:addChild(titleLabel, 5)
        local supplementBtn = display.newButton(size.width / 2, 30, {n = RES_DICT.COMMON_BTN_ORANGE})
        display.commonLabelParams(supplementBtn, fontWithColor(14, {text = __('恢复')}))
        supplementBtn:setScale(0.8)
        view:addChild(supplementBtn, 5)
        local line = display.newImageView(RES_DICT.LINE, size.width, size.height - 20)
        view:addChild(line, 5)
        view:setVisible(false)
        return {
            view          = view,
            supplementBtn = supplementBtn,
            bg            = bg,
            titleLabel    = titleLabel,
        }
    end
    xTry(function ( )
        self.viewData = CreateView(NODE_SIZE)
        self:setContentSize(NODE_SIZE)
        self:addChild(self.viewData.view)
        self.viewData.supplementBtn:setOnClickScriptHandler(handler(self, self.SupplementButtonCallback))
	end, __G__TRACKBACK__)
end  
--[[
初始化节点
@params {
}
--]]
function ActivityContinuousActiveWeeklyNode:RefreshNode( params )
    local viewData = self:GetViewData()
    viewData.titleLabel:setString(params.title or '')
    viewData.supplementBtn:setTag(checkint(params.tag))
    if params.callback then
        self.callback = params.callback
    end
    if params.state then
        self:SetState(params.state)
    end
    -- 显示动画
    viewData.view:stopAllActions()
    viewData.view:setOpacity(0)
    viewData.view:runAction(
        cc.Sequence:create{
            cc.Hide:create(),
            cc.DelayTime:create((params.tag - 1) * 0.05),
            cc.Show:create(),
            cc.FadeIn:create(0.5)
        }
    )
end
--[[
设置节点状态
@params state int 节点状态 1：已达成 2：未达成 3：日期未达到
--]]
function ActivityContinuousActiveWeeklyNode:SetState( state )
    local viewData = self:GetViewData()
    if state == 1 then
        viewData.bg:setTexture(RES_DICT.BG_FINISH)
        viewData.supplementBtn:setVisible(false)
    elseif state == 2 then
        viewData.bg:setTexture(RES_DICT.BG_UNFINISH)
        viewData.supplementBtn:setVisible(true)
    elseif state == 3 then
        viewData.bg:setTexture(RES_DICT.BG_UNDO)
        viewData.supplementBtn:setVisible(false)
    end
end
--[[
补签按钮点击回调
--]]
function ActivityContinuousActiveWeeklyNode:SupplementButtonCallback( sender )
    if self.callback then
        self.callback(sender)
    end
end
--[[
获取viewData
--]]
function ActivityContinuousActiveWeeklyNode:GetViewData()
    return self.viewData
end
return ActivityContinuousActiveWeeklyNode