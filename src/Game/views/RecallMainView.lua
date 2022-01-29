--[[
	召回系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallMainView = class('RecallMainView', GameScene)

local RES_DICT = {
	Btn_Normal 			= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 		= "ui/common/common_btn_sidebar_selected.png",	
}

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallMainView:ctor( ... )
	local args = unpack({ ... })
    --创建页面
	local view = require("common.TitlePanelBg").new({ title = __('御侍召回'), type = 5, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator('RecallMainMediator')
    end, offsetY = 3})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
    view.viewData.closeBtn:setVisible(false)
    local function CreateView( ... )
        local cview = CLayout:create(cc.size(1131 + 143 - 19,639))
        local size  = cview:getContentSize()
		display.commonUIParams(view.viewData.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
		view.viewData.tempLayer:setContentSize(cc.size(1131,639))
		display.commonUIParams(
			view.viewData.tempLayer, 
			{
				ap = cc.p(0, 0.5),
				po = cc.p(display.cx - size.width / 2, display.cy)
			})
        
		--添加多个按钮功能
		local taskCData = args.onlyRecalled and {} or {
			{name = __('召回'), 	tag = RecallType.RECALL},
		}
		local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
		if gameMgr:CheckIsVeteran() then
			table.insert(taskCData, {name = __('感恩'), 	tag = RecallType.RECALLED})
		end
		if gameMgr:CheckIsRecalled() and (not args.onlyRecalled) then
			table.insert(taskCData, {name = __('召回码'), 	tag = RecallType.INVITED_CODE})
		end

        local frameSize = cview:getContentSize()
		local buttons = {}
		local spinePos = nil
		for i,v in pairs(taskCData) do
			local tabButton = display.newCheckBox(0,0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed),})

			local buttonSize = tabButton:getContentSize()
			display.commonUIParams(
				tabButton, 
				{
					ap = cc.p(1, 0.5),
					po = cc.p(frameSize.width,
						frameSize.height - 110 - (i - 1) * (buttonSize.height - 0))
				})
			cview:addChild(tabButton)
			tabButton:setTag(v.tag)
			buttons[tostring( v.tag )] = tabButton

			local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y,
				{text = v.name, reqW = 130 , hAlign = display.TAC ,   color = '#5c5c5c', fontSize = 22, ap = cc.p(0.5, 0)})
			tabButton:addChild(tabNameLabel1)
			tabNameLabel1:setName('title')
			tabNameLabel1:setTag(3)
			local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 116, 96)
			remindIcon:setName('remindIcon')
			tabButton:addChild(remindIcon, 10)
			remindIcon:setVisible(false)

			if v.tag == RecallType.INVITED_CODE then
				local tabSpine = sp.SkeletonAnimation:create(
        		    'effects/recall/panzi.json',
        		    'effects/recall/panzi.atlas',
        		    1)
				tabSpine:setPosition(cc.p(buttonSize.width / 2 - 4, buttonSize.height / 2 + 15))
				spinePos = buttonSize.height / 2 + 15
        		tabButton:addChild(tabSpine, 2)
        		tabSpine:setAnimation(0, 'idle1', true)
        		tabSpine:update(0)
        		tabSpine:setToSetupPose()
				tabButton.tabSpine = tabSpine
			end
        end
        
        --剩余时间
        -- local leftBg = display.newImageView(GetFullPath('recall_acitvity_time_bg'), size.width - 304, size.height - 23)
        -- cview:addChild(leftBg)

        -- local leftLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 70 , utils.getLocalCenter(leftBg).y - 1,
        --     fontWithColor('16', {font = TTF_GAME_FONT, ttf = true, text = __('剩余时间:')}))
        -- leftBg:addChild(leftLabel)

        -- local timeLabel = display.newLabel(utils.getLocalCenter(leftBg).x - 20, utils.getLocalCenter(leftBg).y - 1,
        --     fontWithColor('10', {fontSize = 22, font = TTF_GAME_FONT, ttf = true, text = '00:00:00', ap = display.LEFT_CENTER}))
        -- leftBg:addChild(timeLabel)

		view:AddContentView(cview)
		cview:setLocalZOrder(20)

		return {
			view        = cview,
			buttons		= buttons,
			spinePos	= spinePos,
			-- timeLabel	= timeLabel,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end


return RecallMainView