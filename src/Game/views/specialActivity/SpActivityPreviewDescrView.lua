--[[
特殊活动 活动预览详情页签view
--]]
local SpActivityPreviewDescrView = class('SpActivityPreviewDescrView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.SpActivityPreviewDescrView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DICT = {
    COMMON_BG      = _res('ui/common/common_bg_4.png'),
}
function SpActivityPreviewDescrView:ctor( ... )
    self.args = unpack({...}) or {}
    self.isControllable_ = true
    self:InitUI()
end
--[[
init ui
--]]
function SpActivityPreviewDescrView:InitUI()
    local function CreateView()
        local size = cc.size(590, 340)
        local view = CLayout:create(size)
        -- mask
		local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
		mask:setTouchEnabled(true)
		mask:setContentSize(size)
		mask:setAnchorPoint(cc.p(0.5, 0.5))
		mask:setPosition(cc.p(size.width/2, size.height/2))
		view:addChild(mask, -1)
        -- 背景
        local bgImg = display.newImageView(RES_DICT.COMMON_BG, size.width / 2, size.height / 2, {scale9 = true, size = size})
        bgImg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bgImg, 1)
        -- 列表
        local listView = CListView:create(cc.size(size.width, size.height - 10))
		listView:setBounceable(true)
		listView:setDirection(eScrollViewDirectionVertical)
        listView:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(listView, 1)
        return {
            view             = view,
            size             = size,
            listView         = listView,

        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self.eaterLayer = eaterLayer
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        if self.isControllable_ then
            self:runAction(cc.RemoveSelf:create())
        end
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:RefreshUI()
        self:EnterAction()
    end, __G__TRACKBACK__)
end
function SpActivityPreviewDescrView:RefreshUI()
    local data = self.args.data or {}
    local viewData = self.viewData
    local titleLabel = display.newLabel(0, 0, {fontSize = 32, color = '#5b3c25', text = data.name, ap = cc.p(0.5, 1)})
    local timeLabel = display.newLabel(0, 0, {fontSize = 22, color = '#5b3c25', text = string.format('%s~%s', data.begin, data['end']), ap = cc.p(0.5, 1)})
    local descrLabel = display.newLabel(0, 0 ,{fontSize = 22, color = '#5b3c25', text = data.descr, ap = cc.p(0, 1), w = 520})
    local layoutSizeH = display.getLabelContentSize(titleLabel).height + display.getLabelContentSize(timeLabel).height + display.getLabelContentSize(descrLabel).height + 65
    local layoutSize = cc.size(viewData.size.width, layoutSizeH)
    local layout = CLayout:create(layoutSize)
    titleLabel:setPosition(layoutSize.width / 2, layoutSize.height - 20)
    timeLabel:setPosition(layoutSize.width / 2, titleLabel:getPositionY() - display.getLabelContentSize(titleLabel).height)
    descrLabel:setPosition(30, timeLabel:getPositionY() - 30 - display.getLabelContentSize(timeLabel).height)
    layout:addChild(titleLabel, 1)
    layout:addChild(timeLabel, 1)
    layout:addChild(descrLabel, 1)
    viewData.listView:insertNodeAtLast(layout)
    viewData.listView:reloadData()

end
function SpActivityPreviewDescrView:EnterAction()
    self.isControllable_ = false
    self.eaterLayer:setOpacity(0)
    self.viewData.view:setScaleY(0)

    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.eaterLayer, cc.FadeTo:create(actionTime, 153)),
            cc.TargetedAction:create(self.viewData.view, cc.ScaleTo:create(actionTime, 1))
        }),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    }))
end
return SpActivityPreviewDescrView