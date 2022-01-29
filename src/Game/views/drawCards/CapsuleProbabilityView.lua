--[[
卡池概率页面view
--]]
local CapsuleProbabilityView = class('CapsuleProbabilityView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleProbabilityView'
    node:setPosition(display.center)
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function CapsuleProbabilityView:ctor( ... )
    self.args = unpack({...})
    self.probabilityDatas = checktable(self.args.rate)
    self.isControllable_ = true
    self:InitUI()
    self:EnterAction()
end
--[[
init ui
--]]
function CapsuleProbabilityView:InitUI()
    local function CreateView()
        local bg = display.newImageView(_res('ui/common/common_bg_9'), 0, 0, {enable = true})
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local title = display.newButton(bgSize.width/2, bgSize.height - 2, {ap = cc.p(0.5, 1), scale9 = true ,  n = _res('ui/common/common_bg_title_2.png')})
        view:addChild(title, 5)
        display.commonLabelParams(title, fontWithColor(18, {text = __('卡池概率'), offset = cc.p(0, 0) , paddingW = 30 }))
        local listBg = display.newImageView(_res("ui/home/capsule/draw_probability_text_bg.png"), bgSize.width/2, 20, {ap = cc.p(0.5, 0)})
        view:addChild(listBg, 1)
        -- 列表
        local gridViewSize = cc.size(listBg:getContentSize().width, listBg:getContentSize().height - 4)
        local gridViewCellSize = cc.size(gridViewSize.width, 34)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        gridView:setAnchorPoint(cc.p(0.5, 0))
        view:addChild(gridView, 5)
        gridView:setPosition(cc.p(bgSize.width/2, 22))
        return {
            view             = view,
            title            = title,
            gridView         = gridView,
            gridViewCellSize = gridViewCellSize,
        }
    end 
    -- eaterLayer
    self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    self.eaterLayer:setTouchEnabled(true)
    self.eaterLayer:setContentSize(display.size)
    self.eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(self.eaterLayer, -1)
    self.eaterLayer:setOnClickScriptHandler(function()
        if not self.isControllable_ then return end
        PlayAudioByClickClose()
        self:CloseAction()
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
        self.viewData_.gridView:setCountOfCell(#self.probabilityDatas)
        self.viewData_.gridView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
列表处理
--]]
function CapsuleProbabilityView:OnDataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData_.gridViewCellSize
    if pCell == nil then 
        pCell = require('Game.views.drawCards.CapsuleProbabilityCell').new(cSize)
    end
    xTry(function()
        if index%2 == 1 then
            pCell.bg:setVisible(true)
        else
            pCell.bg:setVisible(false)
        end
    end,__G__TRACKBACK__)
        local datas = self.probabilityDatas[index]
        pCell.nameLabel:setString(datas.descr)
        display.commonLabelParams(pCell.nameLabel , {text =  datas.descr , reqW = 240 })
        pCell.probabilityLabel:setString(datas.rateText or string.format('%0.2f%%', checkint(datas.rate)/100))
    return pCell
end
function CapsuleProbabilityView:EnterAction()
    self.isControllable_ = false
    self.eaterLayer:setOpacity(0)
    self.viewData_.view:setScaleY(0)

    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.eaterLayer, cc.FadeTo:create(actionTime, 153)),
            cc.TargetedAction:create(self.viewData_.view, cc.ScaleTo:create(actionTime, 1))
        }),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    }))
end
function CapsuleProbabilityView:CloseAction()
    self.isControllable_ = false
    self.eaterLayer:setOpacity(150)
    self.viewData_.view:setScale(1)

    local actionTime = 0.1
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.eaterLayer, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData_.view, cc.ScaleTo:create(actionTime, 1, 0))
        }),
        cc.RemoveSelf:create()
    }))
end
return CapsuleProbabilityView