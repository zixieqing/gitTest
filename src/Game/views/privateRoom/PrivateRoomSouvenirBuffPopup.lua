--[[
包厢纪念品buff效果 popup
--]]
local PrivateRoomSouvenirBuffPopup = class('PrivateRoomSouvenirBuffPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'privateRoom.PrivateRoomSouvenirBuffPopup'
    node:enableNodeEvents()
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local RES_DICT = {
    BG = _res('ui/common/common_bg_9.png'),
    TILTE_BG = _res('ui/common/common_bg_title_2.png'),
    LIST_BG = _res('ui/home/capsule/draw_probability_text_bg.png')
}
function PrivateRoomSouvenirBuffPopup:ctor( ... )
    self.args = unpack({...})
    self.wallData = self.args.wallData or {}
    self.isControllable_ = true
    self.buffData = {}
    self:InitData()
    self:InitUI()
    self:EnterAction()
end
--[[
init ui
--]]
function PrivateRoomSouvenirBuffPopup:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- title
        local titleBg = display.newButton(size.width / 2, size.height - 20, {n = RES_DICT.TILTE_BG, enable = false})
        display.commonLabelParams(titleBg, fontWithColor('14', {text = __('统计'), offset = cc.p(0, -2)}))
        view:addChild(titleBg, 3)
        -- 列表
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width/2, 20, {ap = cc.p(0.5, 0)})
        view:addChild(listBg, 1)
        local gridViewSize = listBg:getContentSize()
        local gridViewCellSize = cc.size(gridViewSize.width, 50)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        gridView:setAnchorPoint(cc.p(0.5, 0))
        view:addChild(gridView, 5)
        gridView:setPosition(cc.p(size.width/2, 22))
        
        return {
            view             = view,
            gridView         = gridView,
            gridViewCellSize = gridViewCellSize,
        }
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self.eaterLayer = eaterLayer
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function ()
        if not self.isControllable_ then return end
        PlayAudioByClickClose()
        self:CloseAction()
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
        self.viewData.gridView:setCountOfCell(#self.buffData)
        self.viewData.gridView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
初始化数据
--]]
function PrivateRoomSouvenirBuffPopup:InitData()
    local wallData = self.wallData
    self.buffData = {}
    for i,v in orderedPairs(wallData) do
        if v ~= '' then 
            local buff = app.privateRoomMgr:GetBuffDescrByGoodsId(v)
            table.insert(self.buffData, buff.name)
            table.insert(self.buffData, buff.buffDescr)
        end
    end
end
--[[
列表处理
--]]
function PrivateRoomSouvenirBuffPopup:OnDataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData.gridViewCellSize
    if pCell == nil then 
        pCell = require('Game.views.drawCards.CapsuleProbabilityCell').new(cSize)
        pCell.probabilityLabel:setVisible(false)
    end
    xTry(function()
        if index%2 == 1 then
            pCell.bg:setVisible(true)
            display.commonLabelParams(pCell.nameLabel , {text =self.buffData[index] })
        else
            pCell.bg:setVisible(false)
            display.commonLabelParams(pCell.nameLabel , {text =  self.buffData[index]  , w = 320   })
        end
    end,__G__TRACKBACK__)
    return pCell
end
function PrivateRoomSouvenirBuffPopup:EnterAction()
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
function PrivateRoomSouvenirBuffPopup:CloseAction()
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
return PrivateRoomSouvenirBuffPopup