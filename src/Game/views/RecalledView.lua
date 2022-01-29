--[[
	被召回UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecalledView = class('RecalledView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecalledView:ctor( ... )
    --创建页面
    local function CreateView( ... )
		local size = cc.size(1131,639)
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0, 0)})
        self:addChild(view)

        -- 7天任务
		local dailyBg = display.newImageView(GetFullPath('recall_activity_7tian'), 266, 14, {ap = cc.p(0.5, 0)})
        view:addChild(dailyBg)
        
		local dailyTitleBg = display.newImageView(GetFullPath('recall_bg_title_zhuanshu'), -2, dailyBg:getContentSize().height - 12, {ap = display.LEFT_TOP})
        dailyBg:addChild(dailyTitleBg)
        
		local dailyTitleLabel = display.newLabel(10, 18, fontWithColor('14', {text = __('感恩福利一：7天活动得UR'), color = '#fff8e7', outline = '#5b3c25', ap = display.LEFT_CENTER}))
        dailyTitleBg:addChild(dailyTitleLabel)

		local dailyBtn = display.newButton(266, 60, {n = GetFullPath('recall_title_7tian') ,scale9 = true , size = cc.size(430 , 80)})
		view:addChild(dailyBtn)
		display.commonLabelParams(dailyBtn, {text = __('完成任务获得自选UR'), reqW = 370 , offset = cc.p(0, -1),  fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})

		local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), dailyBtn:getContentSize().width-20, dailyBtn:getContentSize().height-17)
		remindIcon:setName('remindIcon')
		dailyBtn:addChild(remindIcon, 10)
		remindIcon:setVisible(false)

        -- 回归礼包
		local giftPackageBg = display.newImageView(GetFullPath('recall_bg_libao'), 808, 14, {ap = display.CENTER_BOTTOM})
        view:addChild(giftPackageBg)
        
		local giftPackageTitleBg = display.newImageView(GetFullPath('recall_bg_title_zhuanshu'), -2, giftPackageBg:getContentSize().height - 12, {ap = display.LEFT_TOP})
        giftPackageBg:addChild(giftPackageTitleBg)
        
		local giftPackageTitleLabel = display.newLabel(10, 18, fontWithColor('14', {text = __('感恩福利三：感恩礼包'), color = '#fff8e7', outline = '#5b3c25', ap = display.LEFT_CENTER}))
        giftPackageTitleBg:addChild(giftPackageTitleLabel)

		local buyBtn = display.newButton(808, 80, {n = _res('ui/common/common_btn_green.png')})
		view:addChild(buyBtn)

		local limitLabel = display.newLabel(giftPackageBg:getContentSize().width / 2, 20, fontWithColor('10', {text = ''}))
        giftPackageBg:addChild(limitLabel)

        -- 被召回奖励
		local rewardBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 808, 296, {scale9 = true, size = cc.size(296 * 2, 145 * 2), ap = display.CENTER_BOTTOM})
		view:addChild(rewardBg)
		
		local rewardTitleBg = display.newImageView(GetFullPath('recall_title_white'), 808, 553)
        view:addChild(rewardTitleBg)

		local rewardTabletBg = display.newImageView(GetFullPath('recall_bg_title_zhuanshu'), rewardBg:getPositionX() - 2 - rewardBg:getContentSize().width / 2, 
			rewardBg:getPositionY() - 12 + rewardBg:getContentSize().height, {ap = display.LEFT_TOP}) 
		view:addChild(rewardTabletBg)
		
		local rewardTitleLabel = display.newLabel(10, 18, fontWithColor('14', {text = __('感恩福利二：登录奖励'), color = '#fff8e7', outline = '#5b3c25', ap = display.LEFT_CENTER}))
		rewardTabletBg:addChild(rewardTitleLabel)
		
        --剩余时间
        local leftBg = display.newImageView(GetFullPath('recall_acitvity_time_bg'), size.width - 180, size.height - 23)
        view:addChild(leftBg)

        local leftLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 70 , utils.getLocalCenter(leftBg).y - 1,
            fontWithColor('16', {font = TTF_GAME_FONT, ttf = true, text = __('剩余时间:')}))
        leftBg:addChild(leftLabel)

        local timeLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 20, utils.getLocalCenter(leftBg).y - 1,
            fontWithColor('10', {fontSize = 22, font = TTF_GAME_FONT, ttf = true, text = '00:00:00', ap = display.LEFT_CENTER}))
		leftBg:addChild(timeLabel)
		
		local gridView = CGridView:create(cc.size(296 * 2, 110 * 2))
		gridView:setSizeOfCell(cc.size(296 * 2, 150))
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(512, 300))
		
		return {
            view        	= view,
            dailyBtn    	= dailyBtn,
			gridView    	= gridView,
			buyBtn			= buyBtn,
			limitLabel		= limitLabel,
			remindIcon		= remindIcon,
			timeLabel		= timeLabel,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end


return RecalledView