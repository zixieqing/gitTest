--[[
主界面顶部信息栏
@params {
	iconIds table 顶部显示的图标群
	callback funtion 返回按钮回调
}
--]]
---@class HomeTopLayer
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local RemindIcon = require('common.RemindIcon')

local HomeTopLayer = class('HomeTopLayer', function ()
	local node = CLayout:create()
	node.name = 'home.HomeTopLayer'
	node:enableNodeEvents()
	return node
end)

local HEIGHT = 110

local UI_DICT = {
	NAV_BACK = _res("ui/common/common_btn_back.png"),
}
local RED_TAG = 1115
function HomeTopLayer:ctor(...)
	self.args = unpack({...}) or {}
	local isElex = false
	if isElexSdk and   isElexSdk() then
		HEIGHT = HEIGHT + 50
		isElex = true
	end
	local bgSize = cc.size(display.width, HEIGHT)
	self:setContentSize(bgSize)
	self.viewData = nil



	local function CreateView()
		local view = display.newLayer(0, 0, {size = bgSize})
		view:setName('homeTopView')
		self:addChild(view)

		-------------------------------------------------
		-- back button
		local backBtn = display.newButton(0, 0, {n = UI_DICT.NAV_BACK})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
        backBtn:setName('NAV_BACK')
		view:addChild(backBtn, 5)
		backBtn:setVisible(false)

		-------------------------------------------------
		-- profile info
		local titleLabel = display.newLabel(backBtn:getPositionX() + backBtn:getContentSize().width * 0.5 + 20, backBtn:getPositionY(),
		{text = '', fontSize = 40, color = '#ff8875', ap = cc.p(0, 0.5)})
		view:addChild(titleLabel, 5)
		local header = require('common.ProfileNode').new({ pre = gameMgr:GetUserInfo().avatarFrame, isTop = true , animate = true,
		enable = true , cb = function ()
				PlayAudioByClickNormal()
				if self:isControllable() then
					local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = gameMgr:GetUserInfo().playerId   })
					AppFacade.GetInstance():RegistMediator(mediator)
				end
			end
		})


		header:setTag(RemindTag.MYSELF_INFOR)
		RemindIcon.addRemindIcon({parent = header , tag = RemindTag.MYSELF_INFOR , po = cc.p(header:getContentSize().width * 0.5 - 50 , header:getContentSize().height * 0.5 + 40)})
		display.commonUIParams(header, {ap = display.LEFT_TOP, po = cc.p(display.SAFE_L, bgSize.height - (isElex and 50 or 0 ) )})
		view:addChild(header, 5)
		-- --经验进度
        local expBar = CProgressBar:create(_res('ui/home/nmain/main_ico_exp_loading.png'))
        expBar:setBackgroundImage(_res('ui/home/nmain/main_bg_exp.png'))
        expBar:setDirection(eProgressBarDirectionLeftToRight)
        expBar:setMaxValue(100)
        expBar:setValue(0)
        expBar:setShowValueLabel(true)
        expBar:setPosition(cc.p(184, 52))
        header:addChild(expBar, 10)
		local worldTimeLayout = nil
		if isElex then
			local worldTimeBg  = display.newImageView(_res('ui/home/nmain/main_bg_world_time.png'))
			local worldTimeBgSize = worldTimeBg:getContentSize()
			worldTimeLayout = display.newLayer(display.SAFE_L, bgSize.height -5, {size = worldTimeBgSize , ap = display.LEFT_TOP , color =  cc.c4b(0,0,0,0) })
			worldTimeLayout:setTouchEnabled(true)
			display.commonUIParams(worldTimeLayout , {cb = handler(self , self.UTCTimeClick)})
			worldTimeLayout:addChild(worldTimeBg)
			worldTimeBg:setPosition(worldTimeBgSize.width/2 , worldTimeBgSize.height/2)
			view:addChild(worldTimeLayout)

			local clockImage = display.newImageView(_res('ui/home/nmain/restaurant_kitchen_ico_making.png') ,30 , worldTimeBgSize.height /2 )
			worldTimeLayout:addChild(clockImage)

			local icoMake = display.newImageView(_res('ui/home/nmain/main_ico_world_time_line.png') ,125, worldTimeBgSize.height/2 )
			worldTimeLayout:addChild(icoMake)

			local tipBtn = display.newImageView(_res('ui/common/common_btn_tips.png') , worldTimeBgSize.width - 25 , worldTimeBgSize.height/2)
			worldTimeLayout:addChild(tipBtn)

			local dataLabel = display.newLabel(55,worldTimeBgSize.height/2 , fontWithColor(5,{fontSize = 24,  color = '#ffffff',  ap = display.LEFT_CENTER , text = '02/23'}) )
			worldTimeLayout:addChild(dataLabel)
			dataLabel:setName("dataLabel")
			local hoursLabel = display.newLabel(137,worldTimeBgSize.height/2 , fontWithColor(5,{fontSize = 24,color = '#ffffff',  ap = display.LEFT_CENTER , text = '02:23:00'}) )
			worldTimeLayout:addChild(hoursLabel)
			hoursLabel:setName("hoursLabel")
			app.timerMgr:AddTimer({name = "World_Clock_Time", countdown = 259200})
		end


		-------------------------------------------------
	    -- money info
	    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
		scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R),54)})

		-- scale9 = true, size = cc.size(860,54)})
		-- scale9 = true, size = cc.size(1125,54)})
		display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width, HEIGHT)})
		view:addChild(imageImage)

	    local moneyNods = {}
	    local moneyNodsPos = {}
		-- local iconData = self.args.iconIds or {COOK_ID,TIPPING_ID,HP_ID, GOLD_ID, DIAMOND_ID}
		-- local iconData = self.args.iconIds or {COOK_ID,HP_ID, GOLD_ID, DIAMOND_ID}
		local iconData = self.args.iconIds or {HP_ID, GOLD_ID, DIAMOND_ID}
		local len = #iconData
		for i,v in ipairs(iconData) do
			local isShowHpTips = (v == HP_ID) and 1 or -1

			local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
			display.commonUIParams(purchaseNode,
				{ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( len - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
				view:addChild(purchaseNode, 5)
			purchaseNode.viewData.touchBg:setTag(checkint(v))
			-- purchaseNode.viewData.actionButton:setTag(i)
			moneyNods[tostring( v )] = purchaseNode
			moneyNodsPos[tostring( v )] = cc.p(purchaseNode:getPositionX(),purchaseNode:getPositionY())
		end

		return {
			view = view,
			navBackButton = backBtn,
			titleLabel = titleLabel,
			profileNode = header,
			worldTimeLayout = worldTimeLayout ,
			moneyNods	= moneyNods,
			moneyNodsPos = moneyNodsPos,
			imageImage = imageImage,
			expBar = expBar
		}
		end

	xTry(function ( )
		self.viewData = CreateView( )

		-- 刷新经验条
		self:RefreshLevelAndExp()
		for k, v in pairs( self.viewData.moneyNods ) do
			-- v:SetCallback(handler(self,self.PurchargeAction))
			v:updataUi(checkint(k))
		end

		-- in stage action
		local initOffsetY     = 150
		self.viewData.viewPos = cc.p(self.viewData.view:getPosition())
		self.viewData.view:setPositionY(self.viewData.viewPos.y + initOffsetY)

		self:setControllable(true)
		--self:UpdateUTCTime()
	end, __G__TRACKBACK__)

end
--[[
	世界时间展示
--]]
function HomeTopLayer:UTCTimeClick(sender)
	uiMgr:AddDialog("Game.views.WorldClockView")
end

function HomeTopLayer:UpdateUTCTime()
	if self.viewData.worldTimeLayout and (not tolua.isnull(self.viewData.worldTimeLayout)) then
		local hoursLabel = self.viewData.worldTimeLayout:getChildByName("hoursLabel")
		local dataLabel = self.viewData.worldTimeLayout:getChildByName("dataLabel")
		local severTime = getServerTime()
		local timeTable = os.date("!*t",severTime )
		display.commonLabelParams(hoursLabel , {text = string.format('%02d:%02d:%02d',checkint(timeTable.hour)  , checkint(timeTable.min),checkint(timeTable.sec) )})
		display.commonLabelParams(dataLabel , {text = string.format('%02d/%02d',checkint(timeTable.month)  , checkint(timeTable.day) )})

	end

end
function HomeTopLayer:isControllable()
	return self.isControllable_
end
function HomeTopLayer:setControllable(isControllable)
	self.isControllable_ = isControllable == true

	for _, purchaseNode in pairs(checktable(self.viewData).moneyNods or {}) do
		purchaseNode:setControllable(self.isControllable_)
	end
end


function HomeTopLayer:initShow(actionTime)
	local actionTime = actionTime or 0.2
	local showAction = {
		cc.TargetedAction:create(self.viewData.view, cc.MoveTo:create(actionTime, self.viewData.viewPos)),
	}
	self:runAction(cc.Spawn:create(showAction))
end
--- 刷新玩家的姓名
function HomeTopLayer:RefreshPlayerName()
	self.viewData.profileNode.viewData.nameLabel:setString(tostring(gameMgr:GetUserInfo().playerName))

end
-- 修改头像
function HomeTopLayer:RefreshHeadAvatar()
	---@type ProfileNode
	local profileNode =   self.viewData.profileNode
	if profileNode.viewData then
		local viewData = profileNode.viewData
		local headerNode = viewData.headIcon
		local avatarFrame = gameMgr:GetUserInfo().avatarFrame
		if avatarFrame and avatarFrame ~= "" then
			headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(gameMgr:GetUserInfo().avatarFrame))
		end
		headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(gameMgr:GetUserInfo().avatar))
	end

end

--更新数量ui值
function HomeTopLayer:UpdateCountUI(params)
	if self.viewData.moneyNods then
		for id,v in pairs(self.viewData.moneyNods) do
			v:updataUi(checkint(id), params) --刷新每一个金币数量
		end
	end
end

--[[
--更新显示主角经验的逻辑
--]]
function HomeTopLayer:RefreshLevelAndExp()
    local mainExp = checkint(gameMgr:GetUserInfo().mainExp)
    local curExpData,nextExpData = gameMgr:GetPlayerNextLevelExpData()
    if curExpData and nextExpData then
        local expPercent = (mainExp - checkint(curExpData.totalExp))/ checkint(nextExpData.exp)
        self.viewData.expBar:setMaxValue(100)
        self.viewData.expBar:setValue(expPercent * 100)
        display.commonLabelParams(self.viewData.expBar:getLabel(), {fontSize = 20, text = string.format("%d/%d",  mainExp - checkint(curExpData.totalExp), checkint(nextExpData.exp)),color = 'ffffff'})
        self.viewData.profileNode.viewData.lvLabel:setString(tostring(gameMgr:GetUserInfo().level))
    end
    -- self.viewData.expBar:getLabel():setString(string.format("%d/%d", mainExp, totalExp))
end

function HomeTopLayer:updateImageView( cardId )
	-- self.viewData.profileNode:updateImageView( )
end
-- 刷新绑定手机号的小红点的显示
function HomeTopLayer:RefreshBindingPhoneRed()
	-- 检测是否删除主界面小红点
	app.badgeMgr:CheckHomeInforRed()
end

function HomeTopLayer:ChangeState( state)
	if state == "show" then
		self.viewData.navBackButton:setVisible(true)
		self.viewData.titleLabel:setVisible(false)
		self.viewData.profileNode:setVisible(false)
		if self.viewData.worldTimeLayout and ( not tolua.isnull(self.viewData.worldTimeLayout)) then
			self.viewData.worldTimeLayout:setVisible(false)
		end
    elseif state == 'GONE' then
        self:setVisible(false)
    elseif state == 'OPEN' then
        self:setVisible(true)
	elseif state == 'hide' then
		self.viewData.navBackButton:setVisible(false)
		self.viewData.titleLabel:setVisible(true)
		self.viewData.profileNode:setVisible(true)
		if self.viewData.worldTimeLayout and ( not tolua.isnull(self.viewData.worldTimeLayout)) then
			self.viewData.worldTimeLayout:setVisible(true)
		end
		self.viewData.imageImage:stopAllActions()
		self.viewData.imageImage:setPosition(cc.p(display.width,HEIGHT ))
        for k, v in pairs( self.viewData.moneyNods ) do
			if v then
				v:stopAllActions()
                v:setPosition(cc.p(self.viewData.moneyNodsPos[k].x, self.viewData.moneyNodsPos[k].y))
            end
        end

	elseif state == 'allhide' then
		self.viewData.navBackButton:setVisible(false)
		self.viewData.titleLabel:setVisible(false)
		self.viewData.profileNode:setVisible(false)
		if self.viewData.worldTimeLayout and ( not tolua.isnull(self.viewData.worldTimeLayout)) then
			self.viewData.worldTimeLayout:setVisible(false)
		end
	elseif state == 'rightHide' then
        self.viewData.navBackButton:setVisible(true)
        self.viewData.titleLabel:setVisible(false)
        self.viewData.profileNode:setVisible(false)
		if self.viewData.worldTimeLayout and ( not tolua.isnull(self.viewData.worldTimeLayout)) then
			self.viewData.worldTimeLayout:setVisible(false)
		end
		self.viewData.imageImage:stopAllActions()
		self.viewData.imageImage:runAction(
	        cc.Sequence:create(--cc.DelayTime:create(0.02),
	        	cc.EaseOut:create(cc.MoveBy:create(0.3, cc.p(0,500)), 1)
	        ))
		for k, v in pairs( self.viewData.moneyNods ) do
			if v then
				v:stopAllActions()
				v:runAction(
			        cc.Sequence:create(--cc.DelayTime:create(0.02),
			        	cc.EaseOut:create(cc.MoveBy:create(0.3, cc.p(0,500)), 1)
			        ))
			end
		end

	elseif state == 'rightShow' then
        self.viewData.navBackButton:setVisible(true)
        self.viewData.titleLabel:setVisible(false)
        self.viewData.profileNode:setVisible(false)
		if self.viewData.worldTimeLayout and ( not tolua.isnull(self.viewData.worldTimeLayout)) then
			self.viewData.worldTimeLayout:setVisible(false)
		end
		self.viewData.imageImage:stopAllActions()
		self.viewData.imageImage:runAction(
	        cc.Sequence:create(--cc.DelayTime:create(0.02),
	        	cc.EaseOut:create(cc.MoveTo:create(0.3, cc.p(display.width,HEIGHT)), 1)
	        ))

		for k, v in pairs( self.viewData.moneyNods ) do
			if v then
				v:stopAllActions()
				v:runAction(
			        cc.Sequence:create(--cc.DelayTime:create(0.02),
			        	cc.EaseOut:create(cc.MoveTo:create(0.3,cc.p(self.viewData.moneyNodsPos[k].x,self.viewData.moneyNodsPos[k].y)), 1)
			        ))
			end
		end

	end
end

function HomeTopLayer:onCleanup()
end

return HomeTopLayer
