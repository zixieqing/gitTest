--[[
	召回UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallView = class('RecallView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallView:ctor( ... )
    --创建页面
    local function CreateView( ... )
		local size = cc.size(1131,639)
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0, 0)})
        self:addChild(view)

        local ruleBtn = display.newButton(size.width / 2 + 160, size.height - 21, {n = _res('ui/common/common_btn_tips.png')})
        view:addChild(ruleBtn)
        
        -- 打开h5
		local h5Bg = display.newImageView(GetFullPath('recall_activity_choujiang'), 266, 14, {ap = cc.p(0.5, 0)})
        view:addChild(h5Bg)
		
		local gotoh5Btn = display.newButton(266, 60, {scale9 = true ,  n = _res('ui/common/common_btn_orange.png')})
		view:addChild(gotoh5Btn)
        display.commonLabelParams(gotoh5Btn, fontWithColor('14', {text = __('前往抽奖') , paddingW = 20 }))

		local h5RemindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), gotoh5Btn:getContentSize().width-5, gotoh5Btn:getContentSize().height-5)
		h5RemindIcon:setName('h5RemindIcon')
		gotoh5Btn:addChild(h5RemindIcon, 10)
		h5RemindIcon:setVisible(false)

        -- 召回码
		local inviteBg = display.newImageView(GetFullPath('recall_bg_code'), 266, 404, {ap = display.CENTER_BOTTOM})
		view:addChild(inviteBg)
		
        local inviteSpine = sp.SkeletonAnimation:create(
            'effects/recall/yqm_bk.json',
            'effects/recall/yqm_bk.atlas',
            1)
		inviteSpine:setPosition(cc.p(266, 404 + inviteBg:getContentSize().height / 2))
		view:addChild(inviteSpine, 2)
        inviteSpine:setAnimation(0, 'idle', true)
        inviteSpine:update(0)
        inviteSpine:setToSetupPose()

		local inviteTitleLabel = display.newLabel(310, 150, {text =__('我的召回码'), fontSize = 22, color = '#883101', font = TTF_GAME_FONT, ttf = true})
        inviteBg:addChild(inviteTitleLabel)

		local inviteCodeBg = display.newImageView(_res('ui/common/common_bg_input_default.png'), 310, 110)
        inviteBg:addChild(inviteCodeBg)

		local inviteCodeLabel = display.newLabel(310, 110, {text = '', fontSize = 28, color = '#d23d3d'})
		inviteBg:addChild(inviteCodeLabel)

        local shareBtn = display.newButton(340, 450, {n = _res('ui/common/common_btn_blue_default.png')})
        view:addChild(shareBtn)
		display.commonLabelParams(shareBtn, fontWithColor(14, {text = __('去邀请')}))

		local rewardBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 808, 14, {scale9 = true, size = cc.size(296 * 2, 285 * 2), ap = display.CENTER_BOTTOM})
		view:addChild(rewardBg)
		
		local rewardTitleBg = display.newImageView(GetFullPath('recall_title_white'), 808, 553)
        view:addChild(rewardTitleBg)
		
        -- 召回奖励
		local rewardLabel = display.newLabel(528, 554, {text =__('召回奖励'), ap = display.LEFT_CENTER ,  fontSize = 22, color = '#883101', font = TTF_GAME_FONT, ttf = true})
        view:addChild(rewardLabel)

		-- 回归御侍
        local recalledMasterBtn = display.newButton(1080, 554, { scale9 = true ,  ap = display.RIGHT_CENTER , n = _res('ui/tower/library/btn_selection_unused.png')})
        view:addChild(recalledMasterBtn)
		display.commonLabelParams(recalledMasterBtn, fontWithColor(18, {text = __('回归御侍') , paddingW = 20 }))
		
		local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 118, 42)
		remindIcon:setName('remindIcon')
		recalledMasterBtn:addChild(remindIcon, 10)
		remindIcon:setVisible(false)

        --剩余时间
        local leftBg = display.newImageView(GetFullPath('recall_acitvity_time_bg'), size.width - 180, size.height - 23)
        view:addChild(leftBg)

        local leftLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 20 , utils.getLocalCenter(leftBg).y - 1,
            fontWithColor('16', {ap = display.RIGHT_CENTER ,  font = TTF_GAME_FONT, ttf = true, text = __('剩余时间:')}))
        leftBg:addChild(leftLabel)

        local timeLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 20, utils.getLocalCenter(leftBg).y - 1,
            fontWithColor('10', {ap = display.LEFT_CENTER ,  fontSize = 22, font = TTF_GAME_FONT, ttf = true, text = '00:00:00', ap = display.LEFT_CENTER}))
		leftBg:addChild(timeLabel)
		
		local gridView = CGridView:create(cc.size(296 * 2, 254 * 2 - 6))
		gridView:setSizeOfCell(cc.size(296 * 2, 150))
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(512, 14 + 3))
		
		return {
			view        		= view,
			gotoh5Btn			= gotoh5Btn,
			recalledMasterBtn	= recalledMasterBtn,
			gridView			= gridView,
			inviteCodeLabel		= inviteCodeLabel,
			shareBtn			= shareBtn,
			ruleBtn				= ruleBtn,
			remindIcon			= remindIcon,
			h5RemindIcon		= h5RemindIcon,
			timeLabel			= timeLabel,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end


return RecallView