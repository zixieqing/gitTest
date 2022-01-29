--[[
拼图活动 cell
--]]
local ActivityBinggoCell = class('ActivityBinggoCell', function ()
	local ActivityBinggoCell = CGridViewCell:new()
	ActivityBinggoCell.name = 'home.ActivityBinggoCell'
	ActivityBinggoCell:enableNodeEvents()
	return ActivityBinggoCell
end)

local RES_DIR = {
    TASK_BG          = _res("ui/home/activity/puzzle/activity_puzzle_task_bg.png"),
    TASK_BG_BLACK    = _res("ui/home/activity/puzzle/activity_puzzle_task_bg_black.png"),
}

local createView = nil

function ActivityBinggoCell:ctor( ... )

    xTry(function()
        -- dump(self:getContentSize(), 'GGGGGGGGGGG')
        self.viewData_ = createView()
        self:addChild(self:getViewData().layer)
        self:setContentSize(self:getViewData().bgSize)
        -- display.commonUIParams(self, {ap = display.CENTER})
	end,__G__TRACKBACK__)
    
end

function ActivityBinggoCell:getViewData()
    return self.viewData_
end

createView = function ()
    local bg = display.newImageView(RES_DIR.TASK_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local bgSize = bg:getContentSize()
    local layer = display.newLayer(bgSize.width / 2 + 5, bgSize.height / 2, {ap = display.CENTER, size = bgSize})
    layer:addChild(bg)
    
    local bgBlack = display.newImageView(RES_DIR.TASK_BG_BLACK, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER})
    layer:addChild(bgBlack, 1)

    local descLabel = display.newLabel(15, bgSize.height / 2, fontWithColor(16, {ap = display.LEFT_CENTER, text = '不打孔费卡巴，模板，王贝贝马上办就把我能解决', w = 200}))
    layer:addChild(descLabel)
    
    local progressLabel = display.newRichLabel(230, descLabel:getPositionY(), {ap = display.LEFT_CENTER})
    layer:addChild(progressLabel)
    
    -- local box = display.newButton(bgSize.width - 5, descLabel:getPositionY(), {ap = display.RIGHT_CENTER, n = _res('arts/goods/goods_icon_190100.png'), animate = false})
    -- box:setScale(0.6)
    -- layer:addChild(box)
    -- dump(box:getContentSize(), '22233getContentSize')
    local boxSize = cc.size(80, 80)
    local boxLayer = display.newLayer(bgSize.width - 5, descLabel:getPositionY(), {ap = display.RIGHT_CENTER, size = boxSize, enable = true, color = cc.c4b(0, 0, 0, 0)})
    layer:addChild(boxLayer)

    -- 宝箱
    local rewardBox = sp.SkeletonAnimation:create("effects/baoxiang/baoxiang8.json","effects/baoxiang/baoxiang8.atlas", 0.7)
    rewardBox:setPosition(cc.p(boxSize.width / 2, boxSize.height / 2))
    rewardBox:update(0)
    rewardBox:setAnimation(0, 'stop', true)
    boxLayer:addChild(rewardBox)

    return {
        layer  = layer,
        bgSize = bgSize,
        bgBlack = bgBlack,
        descLabel = descLabel,
        progressLabel = progressLabel,
        boxLayer = boxLayer,
        rewardBox = rewardBox,
    }
end

return ActivityBinggoCell
