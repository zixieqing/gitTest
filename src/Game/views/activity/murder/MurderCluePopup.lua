--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）
--]]
local MurderCluePopup = class('MurderCluePopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.MurderCluePopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG           = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_bg_text.png'),
    LOCK_IMG     = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_bg_lock.png'),
    MAIL_LINE    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_open_line_1.png'),
    COMMON_BTN_N = app.murderMgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_BTN_D = app.murderMgr:GetResPath('ui/common/activity_mifan_by_ico.png'),
    
}
function MurderCluePopup:ctor( ... )
    local args = unpack({...})
    self.clueData = args.data
    self.isLock = args.isLock
    self:InitUI()
end
--[[
init ui
--]]
function MurderCluePopup:InitUI()
    local isLock = self.isLock
    local clueData = self.clueData
    local nextClockLevel = app.murderMgr:GetClockLevel() + 1
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        local bgSize = bg:getContentSize()
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        if isLock then
            -- lockLayout
            local lockLayout = CLayout:create(bgSize)
            lockLayout:setPosition(size.width / 2, size.height / 2)
            view:addChild(lockLayout, 2)
            local lockImg = display.newImageView(RES_DICT.LOCK_IMG, bgSize.width / 2, bgSize.height / 2)
            lockLayout:addChild(lockImg, 1)
            local numPoint = app.murderMgr:GetNumTimes( nextClockLevel * 2)
            local lockLabel = display.newLabel(bgSize.width / 2, bgSize.height / 2 - 50, {text = string.fmt(app.murderMgr:GetPoText(__('时针指向_num_点解锁')), {['_num_'] =numPoint}), color = '#ffffff', fontSize = 22})
            lockLayout:addChild(lockLabel, 2)
            local clockIcon = display.newImageView(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/murder_chess_img_clock_%d', nextClockLevel)),bgSize.width / 2 - 15, bgSize.height / 2 + 100, {ap = display.CENTER_BOTTOM})
            lockLayout:addChild(clockIcon, 2)
        else
            -- drawLayout
            local drawLayout = CLayout:create(bgSize)
            drawLayout:setPosition(size.width / 2, size.height / 2)
            view:addChild(drawLayout, 2)
            local textLabel = display.newLabel(0, 0, {text = clueData.descr, color = '#ffcc86', fontSize = 24, w = 630, ap = cc.p(0, 0)})
            local layout = CLayout:create(cc.size(630, display.getLabelContentSize(textLabel).height))
            layout:addChild(textLabel, 1)
            local listViewSize = cc.size(630, 300)
            local listView = CListView:create(listViewSize)
            listView:setDirection(eScrollViewDirectionVertical)
            listView:setAnchorPoint(cc.p(0.5, 1))
            listView:setPosition(cc.p(bgSize.width / 2, bgSize.height - 50))
            drawLayout:addChild(listView, 10)
            listView:insertNodeAtLast(layout)
            listView:reloadData()

            local descrLabel = display.newLabel(95, 215, {text = app.murderMgr:GetPoText(__('线索奖励:')), fontSize = 20, color = '#dcc7a9', ap = display.LEFT_CENTER})
            drawLayout:addChild(descrLabel, 3)
            local line = display.newImageView(RES_DICT.MAIL_LINE, bgSize.width / 2, 195)
            drawLayout:addChild(line, 1)
            local drawBtn = display.newButton(bgSize.width - 180, 125, {n = RES_DICT.COMMON_BTN_N, d = RES_DICT.COMMON_BTN_D, cb = handler(self, self.DrawButtonCallback)})
            drawLayout:addChild(drawBtn, 5)
            local btnText = app.murderMgr:GetPoText(__('领取'))
            if clueData.isDrawn then
                btnText = app.murderMgr:GetPoText(__('已领取'))
                drawBtn:setEnabled(false)
            end
            display.commonLabelParams(drawBtn, fontWithColor(14, {text = btnText}))
            for i, v in ipairs(checktable(clueData.rewards)) do
                local goodsNode = require('common.GoodNode').new({
                    id = v.goodsId,
                    amount = v.num,
                    showAmount = true,
                    callBack = function (sender)
                        PlayAudioByClickNormal()
                        app.uiMgr:ShowInformationTipsBoard({
                            targetNode = sender, iconId = checkint(v.goodsId), type = 1	
                        })
                    end
                })
                goodsNode:setPosition(cc.p(24 + 120 * i, 125))
                drawLayout:addChild(goodsNode, 10) 
            end
        end
        return {
            bg               = bg,
            view             = view,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function() 
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
领取按钮点击回调
--]]
function MurderCluePopup:DrawButtonCallback( sender )
	AppFacade.GetInstance():DispatchObservers('MURDER_CLUE_DRAW_EVENT', {
        clueId = self.clueData.id
	})
    self:runAction(cc.RemoveSelf:create())
end
--[[
获取viewData
--]]
function MurderCluePopup:GetViewData()
    return self.viewData
end

return MurderCluePopup