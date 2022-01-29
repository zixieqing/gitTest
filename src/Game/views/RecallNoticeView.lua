--[[
	召回公告UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallNoticeView = class('RecallNoticeView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallNoticeView:ctor( ... )
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
		view:addChild(commontitleImage)
		local commontitleImageSize = commontitleImage:getContentSize()
		local label = display.newLabel(884, 620, fontWithColor(16,{text = __('召回规则')}))
        view:addChild(label)
		
		local leftImg = display.newImageView(GetFullPath('recall_letter_bg_left'), display.cx - 260, display.cy)
		view:addChild(leftImg)
		
		local tipsBG = display.newImageView(GetFullPath('recall_letter_bg_tips'), leftImg:getPositionX() + 78, display.cy - 278)
        view:addChild(tipsBG)

		local tipsLabel = display.newLabel(tipsBG:getPositionX() - 30, tipsBG:getPositionY(), 
			{color = 'ffffff', text = __('与邀请您回归的御侍大人成为伙伴，获取更多奖励'), fontSize = 20, w = 220})
		view:addChild(tipsLabel)

		local invitedCodeBtn = display.newButton(tipsBG:getPositionX() + 160, tipsBG:getPositionY(), {n = _res('ui/common/common_btn_white_default.png')})
		view:addChild(invitedCodeBtn)
		display.commonLabelParams(invitedCodeBtn, fontWithColor('14', {text = __('填写召回码')}))
		
		local rightImg = display.newImageView(GetFullPath('recall_letter_bg_right'), display.cx + 334, display.cy)
        view:addChild(rightImg)

		local quitBtn = display.newButton(rightImg:getPositionX() + rightImg:getContentSize().width / 2 - 48, 
			rightImg:getPositionY() + rightImg:getContentSize().height / 2 - 58, {n = GetFullPath('recall_letter_btn_quit')})
		view:addChild(quitBtn)
		
		local dearLabel = display.newLabel(rightImg:getPositionX() - 190, rightImg:getPositionY() + 250, 
			fontWithColor(7, {color = 'dc724f', text = __('亲爱的御侍大人'), ap = display.LEFT_CENTER, fontSize = 22}))
		view:addChild(dearLabel)
		
		local cutlineUpImg = display.newImageView(GetFullPath('recall_letter_line_1'), rightImg:getPositionX(), rightImg:getPositionY() + 228)
		view:addChild(cutlineUpImg)

		local cutlineDownImg = display.newImageView(GetFullPath('recall_letter_line_1'), rightImg:getPositionX(), rightImg:getPositionY() + 8)
		view:addChild(cutlineDownImg)

		local companyLabel = display.newLabel(rightImg:getPositionX() + 190, rightImg:getPositionY() - 12, 
			fontWithColor(6, {color = 'dc724f', text = __('即将秃头的制作组'), ap = display.RIGHT_CENTER, fontSize = 20}))
		view:addChild(companyLabel)

		local desrSize = cc.size(rightImg:getContentSize().width - 220, 210)
		local desrScrollView = CScrollView:create(desrSize)
		desrScrollView:setAnchorPoint(display.LEFT_BOTTOM)
    	desrScrollView:setPosition(cc.p(rightImg:getPositionX() - desrSize.width / 2, rightImg:getPositionY() + 118 - desrSize.height / 2))
		desrScrollView:setDirection(eScrollViewDirectionVertical)
		view:addChild(desrScrollView)
		-- desrScrollView:setBackgroundColor(cc.r4b(255))

		local desrLabel = display.newRichLabel(0, 0, {w = 32, ap = display.LEFT_BOTTOM, sp = 7})
		desrScrollView:getContainer():addChild(desrLabel)
        
		local tabletImg = display.newImageView(GetFullPath('recall_letter_bg_item'), rightImg:getPositionX(), display.cy - 152)
		view:addChild(tabletImg)

		local rewardLabelBG = display.newImageView(GetFullPath('recall_letter_label_1'), rightImg:getPositionX(), tabletImg:getPositionY() + tabletImg:getContentSize().height / 2 - 12)
		view:addChild(rewardLabelBG)

		local rewardLabel = display.newLabel(rewardLabelBG:getPositionX(), rewardLabelBG:getPositionY(), 
			{color = 'ffffff', text = __('奖励已发送至邮箱'), fontSize = 20})
		view:addChild(rewardLabel)
		
		local gotoBtn = display.newButton(rightImg:getPositionX(), display.cy - 260, {n = _res('ui/common/common_btn_orange.png')})
		view:addChild(gotoBtn)
        display.commonLabelParams(gotoBtn, fontWithColor('14', {text = __('前往活动')}))

		return {
			view        		= view,
			desrLabel			= desrLabel,
			desrScrollView		= desrScrollView,
			desrSize			= desrSize,
			gotoBtn				= gotoBtn,
			rightImg			= rightImg,
			quitBtn				= quitBtn,
			invitedCodeBtn		= invitedCodeBtn,
		}
	end
	xTry(function()
        self.viewData_ = CreateView()

		-- local rule = CommonUtils.GetConfigAllMess('rule','recall')
		-- self.viewData_.ruleLabel:setString(rule['2'].descr)
		-- local labelSize = display.getLabelContentSize(self.viewData_.ruleLabel)
		-- self.viewData_.ruleScrollView:setContainerSize(cc.size(labelSize.width, labelSize.height))
		-- self.viewData_.ruleScrollView:setContentOffsetToTop()
		-- if self.viewData_.ruleSize.height > labelSize.height then
		-- 	self.viewData_.ruleLabel:setPositionY(self.viewData_.ruleSize.height - labelSize.height)
		-- end

        -- self.viewData_.view:setOpacity(0)
        -- self.viewData_.view:runAction(cc.FadeIn:create(0.15))
	end, __G__TRACKBACK__)
end

function RecallNoticeView:GotoButtonCallback( sender )
    PlayAudioByClickNormal()

    self:removeFromParent()
end

return RecallNoticeView