local GameScene = require('Frame.GameScene')
local BattleAssembleExportView = class('BattleAssembleExportView', GameScene)

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")


function BattleAssembleExportView:ctor( ... )
	-- GameScene.ctor(self,'views.BattleAssembleExportView')
	
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)


	self.args = unpack({...}) or {}
	local function CreateView()

		local view = CLayout:create(display.size)
		view:setName('view')
		local bg = display.newImageView(_res('ui/home/raidMain/raid_bg.jpg'), display.cx, display.cy)
		self:addChild(bg)

		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 75, self:getContentSize().height - 52, {n = _res('ui/common/common_btn_back.png')})
		self:addChild(backBtn, 99)


		local bgSize  = bg:getContentSize()
		local ListBgFrameSize = cc.size(1330, 550)
		--添加列表功能
		local menuListSize = cc.size(ListBgFrameSize.width, ListBgFrameSize.height - 10)
		local menuListCellSize = cc.size(menuListSize.width/4, menuListSize.height - 60)


		local gridView = CGridView:create(menuListSize)
		gridView:setName('gridView')
		gridView:setSizeOfCell(menuListCellSize)
		gridView:setAutoRelocate(true)
		gridView:setDirection(eScrollViewDirectionVertical)
		gridView:setColumns(4)
		-- gridView:setBackgroundColor(cc.r4b(150))
		view:addChild(gridView,1)
		gridView:setAnchorPoint(cc.p(0.5, 0.5))
		gridView:setPosition(cc.p(display.cx, display.cy - 40))
		return {
			view 		= view,
			backBtn 	= backBtn,
			bg 			= bg,
			gridView	= gridView,
			-- searchBtn 	= searchBtn,
		}
	end
	xTry(function ( )
		self.viewData = CreateView()
		display.commonUIParams(self.viewData.view, {po = display.center})
		self:addChild(self.viewData.view,1)
	end, __G__TRACKBACK__)
end

return BattleAssembleExportView
