--[[
	流失玩家公告UI
--]]
local GameScene = require( "Frame.GameScene" )

local LossPlayerReturnNoticeView = class('LossPlayerReturnNoticeView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function LossPlayerReturnNoticeView:ctor( ... )
    --创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer, -1)
    local function CreateView( ... )
		local view = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER})
		self:addChild(view)
        
		local commontitleImage = display.newImageView('ui/common/common_title_5.png',884 , 636 , { ap = display.CENTER_TOP})
		commontitleImage:setVisible(false)
		view:addChild(commontitleImage)
		local commontitleImageSize = commontitleImage:getContentSize()
		local label = display.newLabel(884, 620, fontWithColor(16,{text = __('召回规则')}))
        view:addChild(label)
		
		local leftImg = display.newImageView(GetFullPath('recall_letter_bg_left'), display.cx - 260, display.cy)
		view:addChild(leftImg)
		
		local rightImg = display.newImageView(GetFullPath('recall_letter_bg_right'), display.cx + 334, display.cy)
        view:addChild(rightImg)

		local quitBtn = display.newButton(rightImg:getPositionX() + rightImg:getContentSize().width / 2 - 48, 
			rightImg:getPositionY() + rightImg:getContentSize().height / 2 - 58, {n = GetFullPath('recall_letter_btn_quit')})
		view:addChild(quitBtn)
		
		local dearLabel = display.newLabel(rightImg:getPositionX() - 190, rightImg:getPositionY() + 270, 
			fontWithColor(7, {color = 'dc724f', text = __('亲爱的御侍大人'), ap = display.LEFT_CENTER, fontSize = 22}))
		view:addChild(dearLabel)
		
		local cutlineUpImg = display.newImageView(GetFullPath('recall_letter_line_1'), rightImg:getPositionX(), rightImg:getPositionY() + 248)
		view:addChild(cutlineUpImg)

		local cutlineDownImg = display.newImageView(GetFullPath('recall_letter_line_1'), rightImg:getPositionX(), rightImg:getPositionY() + 8)
		view:addChild(cutlineDownImg)

		local companyLabel = display.newLabel(rightImg:getPositionX() + 190, rightImg:getPositionY() - 12, 
			fontWithColor(6, {color = 'dc724f', text = __('即将秃头的制作组'), ap = display.RIGHT_CENTER, fontSize = 20}))
		view:addChild(companyLabel)

		local desrSize = cc.size(rightImg:getContentSize().width - 220, 230)
		local desrScrollView = CScrollView:create(desrSize)
		desrScrollView:setAnchorPoint(display.LEFT_TOP)
    	desrScrollView:setPosition(cc.p(rightImg:getPositionX() - desrSize.width / 2, rightImg:getPositionY() + 128 + desrSize.height / 2))
		desrScrollView:setDirection(eScrollViewDirectionVertical)
		view:addChild(desrScrollView)
		-- desrScrollView:setBackgroundColor(cc.r4b(255))

		local desrLabel = display.newLabel(0, desrSize.height, {w = desrSize.width, ap = display.LEFT_TOP, fontSize = 20, color = '793002'})
		desrScrollView:getContainer():addChild(desrLabel)
        
		local tabletImg = display.newImageView(GetFullPath('recall_letter_bg_item'), rightImg:getPositionX(), display.cy - 152)
		view:addChild(tabletImg)

		local rewardLabelBG = display.newImageView(GetFullPath('recall_letter_label_1'), rightImg:getPositionX(), tabletImg:getPositionY() + tabletImg:getContentSize().height / 2 - 12)
		view:addChild(rewardLabelBG)

		local rewardLabel = display.newLabel(rewardLabelBG:getPositionX(), rewardLabelBG:getPositionY(), 
			{color = 'ffffff', text = __('奖励已发送至邮箱'), fontSize = 20})
		view:addChild(rewardLabel)

		local gridViewSize = cc.size(420, 90)
    	local gridViewCellSize = cc.size(88, 88)
    	local gridView = CTableView:create(gridViewSize)
    	gridView:setDirection(eScrollViewDirectionHorizontal)
    	gridView:setSizeOfCell(gridViewCellSize)
    	display.commonUIParams(gridView, {ap = display.CENTER, po = cc.p(rightImg:getPositionX(), display.cy - 120)})
    	view:addChild(gridView, 10)
	
		return {
			view        		= view,
			desrLabel			= desrLabel,
			desrScrollView		= desrScrollView,
			desrSize			= desrSize,
			-- gotoBtn				= gotoBtn,
			rightImg			= rightImg,
			quitBtn				= quitBtn,
			-- invitedCodeBtn		= invitedCodeBtn,
			gridView			= gridView,
		}
	end
	xTry(function()
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return LossPlayerReturnNoticeView