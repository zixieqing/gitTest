--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖 稀有奖励View
--]]
local MurderExCapsuleView = class('MurderExCapsuleView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.MurderExCapsuleView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function MurderExCapsuleView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function MurderExCapsuleView:InitUI()
    local function CreateView()
        local bg = display.newImageView(app.murderMgr:GetResPath('ui/common/common_bg_3'), 0, 0, {enable = true})
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local title = display.newButton(bgSize.width/2, bgSize.height - 2, {ap = cc.p(0.5, 1), n = app.murderMgr:GetResPath('ui/common/common_bg_title_2.png')})
        view:addChild(title, 5)
        display.commonLabelParams(title, fontWithColor(18, {text = app.murderMgr:GetPoText(__('稀有奖励一览')), offset = cc.p(0, -2)}))      
         -- mask
		local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
		mask:setTouchEnabled(true)
		mask:setContentSize(bgSize)
		mask:setAnchorPoint(cc.p(0.5, 0.5))
		mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
		view:addChild(mask, -1)
        -- 列表
        local gridViewSize = cc.size(bgSize.width - 20, 586)
        local gridViewCellSize = cc.size(bgSize.width - 20, 130)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setAnchorPoint(cc.p(0.5, 1))
        gridView:setColumns(1)
        -- gridView:setAutoRelocate(true)
        view:addChild(gridView, 10)
        gridView:setPosition(cc.p(bgSize.width/2, bgSize.height - 45))
        -- gridView:setCountOfCell(table.nums(rankDatas.rankList))
        -- gridView:reloadData()

        return {
            view             = view,
            gridViewSize     = gridViewSize,
            gridViewCellSize = gridViewCellSize,
            gridView         = gridView,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("MurderExCapsuleMediator")
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
return MurderExCapsuleView