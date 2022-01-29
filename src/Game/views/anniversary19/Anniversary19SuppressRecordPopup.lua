local Anniversary19SuppressRecordPopup = class('Anniversary19SuppressRecordPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'Anniversary19SuppressRecordPopup'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    BG                                      = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_7.png'),
    TITLE_BG                                = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_title_2.png'),
    LIST_BG                                 = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_list_unselected.png'),
    COMMON_BG_CLOSE                         = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_close.png'),
    CELL_BG                                 = app.anniversary2019Mgr:GetResPath('ui/home/activity/skinCarnival/story_cap_bg_list.png')
}

function Anniversary19SuppressRecordPopup:ctor( damageRecord )
    self.damageRecord = checktable(damageRecord)
    table.sort(self.damageRecord, function ( a, b )
        return tonumber(a.damage) > tonumber(b.damage)
    end)
    self.isControllable_ = true
    self:InitUI()
    self:EnterAction()
end

function Anniversary19SuppressRecordPopup:InitUI()
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- title
        local titleBg = display.newImageView(RES_DICT.TITLE_BG, size.width / 2, size.height - 20)
        view:addChild(titleBg, 1)
        local titleLabel = display.newLabel(size.width / 2, size.height - 20, fontWithColor(1,{fontSize = 24, text = app.anniversary2019Mgr:GetPoText(__('战报')), color = 'ffffff',offset = cc.p(0, -2)}))
        view:addChild(titleLabel, 5)

        local nameLabel = display.newLabel(60, size.height - 80, {text = app.anniversary2019Mgr:GetPoText(__('昵称')), color = '#525251', fontSize = 24, ap = cc.p(0, 0.5), w = 300})
        view:addChild(nameLabel, 3)

        local damageLabel = display.newLabel(size.width - 60, size.height - 80, {text = app.anniversary2019Mgr:GetPoText(__('伤害')), color = '#525251', fontSize = 24, ap = cc.p(1, 0.5)})
        view:addChild(damageLabel, 3)

        -- listView
        local listViewSize = cc.size(503, 426)
        local listViewCellSize = cc.size(listViewSize.width, 70)
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, 8, {ap = display.CENTER_BOTTOM, Scale9 = true, size = listViewSize, capInsets = cc.rect(10, 10, 483, 98)})
        view:addChild(listBg, 1)
		local gridView = CGridView:create(listViewSize)
        gridView:setSizeOfCell(listViewCellSize)
        gridView:setAnchorPoint(display.CENTER_BOTTOM)
		gridView:setPosition(cc.p(size.width / 2, 8))
		gridView:setColumns(1)
		view:addChild(gridView, 5)

        local closeLabel = display.newButton(size.width / 2, -14,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_CLOSE,
            scale9 = true, size = cc.size(210, 26),
            enable = false,
        })
        display.commonLabelParams(closeLabel, {text = app.anniversary2019Mgr:GetPoText(__('点击空白处关闭')), fontSize = 18, color = '#ffffff', paddingW = 40, safeW = 130, offset = cc.p(0, 2)})
        view:addChild(closeLabel)

        return {
            view             = view,
            listViewSize     = listViewSize,
            listViewCellSize = listViewCellSize,
            gridView         = gridView,
		}
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function ()
        if not self.isControllable_ then return end
        PlayAudioByClickClose()
        -- self:CloseAction()
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    self.viewData = CreateView( )
    self:addChild(self.viewData.view)
    self.viewData.view:setPosition(display.center)
    self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GirdViewDataSource))
    self.viewData.gridView:setCountOfCell(#self.damageRecord)
    self.viewData.gridView:reloadData()
end
--[[
列表数据处理
--]]
function Anniversary19SuppressRecordPopup:GirdViewDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData.listViewCellSize
    if pCell == nil then 
        pCell = CGridViewCell:new()
        pCell:setContentSize(cSize)
        local bg = display.newImageView(RES_DICT.CELL_BG, cSize.width / 2, cSize.height / 2)
        pCell:addChild(bg, 1)
        pCell.bg = bg
        local nameLabel = display.newLabel(30, cSize.height / 2, {text = '', color = '#525251', fontSize = 24, ap = cc.p(0, 0.5), w = 300})
        pCell:addChild(nameLabel, 3)
        pCell.nameLabel = nameLabel

        local damageLabel = display.newLabel(cSize.width - 40, cSize.height / 2, {text = '', color = '#525251', fontSize = 24, ap = cc.p(1, 0.5)})
        pCell:addChild(damageLabel, 3)
        pCell.damageLabel = damageLabel
    end
    xTry(function()
        if index%2 == 1 then
            pCell.bg:setVisible(false)
        else
            pCell.bg:setVisible(true)
        end
        local data = self.damageRecord[index]
        pCell.nameLabel:setString(data.name)
        pCell.damageLabel:setString(data.damage)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
进入动画
--]]
function Anniversary19SuppressRecordPopup:EnterAction()
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
--[[
关闭动画
--]]
function Anniversary19SuppressRecordPopup:CloseAction()
    self.isControllable_ = false
    self.eaterLayer:setOpacity(150)
    self.viewData.view:setScale(1)

    local actionTime = 0.1
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.eaterLayer, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData.view, cc.ScaleTo:create(actionTime, 1, 0))
        }),
        cc.RemoveSelf:create()
    }))
end
--[[
获取viewData
--]]
function Anniversary19SuppressRecordPopup:GetViewData()
    return self.viewData
end
return Anniversary19SuppressRecordPopup
