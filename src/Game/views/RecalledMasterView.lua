--[[
	召回的玩家列表UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecalledMasterView = class('RecalledMasterView', GameScene)

function RecalledMasterView:ctor( ... )
    --创建页面
    local view = require("common.TitlePanelBg").new({ title = __('召回御侍'), type = 3, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator('RecalledMasterMediator')
    end, offsetY = 3, offsetX = 1})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)
    view.viewData.closeBtn:setVisible(false)
    local function CreateView( ... )
        local cview = CLayout:create(cc.size(558,639))
        local size  = cview:getContentSize()
		view.viewData.view:setContentSize(size)
		display.commonUIParams(view.viewData.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
		view.viewData.tempLayer:setContentSize(size)
		display.commonUIParams(view.viewData.tempLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})

		local gridView = CGridView:create(cc.size(520, 584))
		gridView:setSizeOfCell(cc.size(520, 124))
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		cview:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(19, 10))
        
		view:AddContentView(cview)

		return {
            view        = cview,
            gridView    = gridView,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end


return RecalledMasterView