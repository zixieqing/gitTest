--[[
图鉴功能Mediator
--]]
local Mediator = mvc.Mediator
---@class HandbookMediator:Mediator
local HandbookMediator = class("HandbookMediator", Mediator)

local NAME = "HandbookMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function HandbookMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
end

function HandbookMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function HandbookMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
end


function HandbookMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.HandbookView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	viewComponent:setTag(1111)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	viewComponent.eaterLayer:setOnClickScriptHandler(function()
		-- 添加点击音效
		PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator("HandbookMediator")
	end)
	self:AddTypeButton()
end
function HandbookMediator:AddTypeButton()
	local viewData = self:GetViewComponent().viewData_
	local btnData = {
		{name = __('大陆概述'), icon = _res('ui/home/handbook/pokedex_main_btn_maps.png'), tag = 1001},
		{name = __('飨灵百科'), icon = _res('ui/home/handbook/pokedex_main_btn_card.png'), tag = 1003},
		{name = __('冒险经历'), icon = _res('ui/home/handbook/pokedex_main_btn_course.png'), tag = 1004},
		{name = __('角色介绍'), icon = _res('ui/home/handbook/pokedex_main_btn_npc.png'), tag = 1005},
	}
	if GAME_MODULE_OPEN.NEW_PLOT then
		btnData[3].moduleTag = RemindTag.PLOT_COLLECT
	end

	if CommonUtils.GetModuleAvailable(MODULE_SWITCH.CARD_GATHER) then
		local cardCollData = {name = __('飨灵收集'), icon = _res('ui/home/handbook/pokedex_main_btn_card_collect.png'), tag = 1006}
		table.insert(btnData, cardCollData)
	end

	if GAME_MODULE_OPEN.SKIN_COLLECTION then
		local skinCollData = {name = __('外观收藏'), icon = _res('ui/home/handbook/pokedex_main_btn_skin.png'), tag = 1007}
		table.insert(btnData, skinCollData)
	else
		local felGodData = {name = __('堕神物语'), x = 130, y = 569, icon = _res('ui/home/handbook/pokedex_main_btn_boss.png'), tag = 1002}
		table.insert(btnData, felGodData)
	end

	table.sort(btnData, function(btnDataA, btnDataB)
		return btnDataA.tag < btnDataB.tag
	end)

	local radius = math.floor(360 / table.nums(btnData))
	for i=1, table.nums(btnData) do
		local button = ui.button({n = btnData[i].icon, tag = btnData[i].tag, p = inCirclePos(cc.p(350, 520), 200, 200, radius * (i-1))})
		viewData.view:addChild(button, 5)
		button:setScale(0)
		local function CreateBtnEffect()
			local buttonEffect = sp.SkeletonAnimation:create(
				'effects/handbook/tujian.json',
				'effects/handbook/tujian.atlas',
				1)
			viewData.view:addList(buttonEffect, 7):alignTo(button, ui.cc)
			buttonEffect:update(0)
			buttonEffect:setToSetupPose()
			buttonEffect:setAnimation(0, 'play', false)
			buttonEffect:addAnimation(0, 'idle', true)
		end
		local function AddNameLabel()
			local nameLabelBg = ui.image({img = _res('ui/home/Handbook/pokedex_main_name_short.png')})
			viewData.view:addList(nameLabelBg, 9):alignTo(button, ui.cc, {offsetY = -60})
			nameLabelBg:setCascadeOpacityEnabled(true)
			local nameLabel = display.newLabel(nameLabelBg:getContentSize().width/2, 25, { text = btnData[i].name, color = 'ffffff', fontSize = 20, font = TTF_GAME_FONT, ttf = true, outline = '311717', outlineSize = 1})
			nameLabel:setCascadeOpacityEnabled(true)
			local lwidth = display.getLabelContentSize(nameLabel).width
			local lheight = 35
			if lwidth < 130 then
				lwidth = 140

			elseif lwidth < 180 then
				lwidth = lwidth + 10
			elseif lwidth > 180 then
				lwidth = 190
				lheight= 50
				display.commonLabelParams(nameLabel ,{hAlign = display.TAC,text = btnData[i].name, w = 200 , reqW = 180 })
			end

			nameLabelBg:setContentSize(cc.size(lwidth, lheight))
			nameLabelBg:addChild(nameLabel, 10)
			nameLabel:setPosition(lwidth * 0.5 , lheight * 0.5 )
			nameLabelBg:setOpacity(0)
			nameLabelBg:runAction(cc.FadeIn:create(0.2))
			-- local explessLabel = display.newLabel(btnData[i].x, btnData[i].y - 90, {text = '100%', color = 'ffc64c', fontSize = 20, font = TTF_GAME_FONT, ttf = true, outline = '311717', outlineSize = 1})
			-- explessLabel:setOpacity(0)
			-- viewData.view:addChild(explessLabel, 10)
			-- explessLabel:runAction(cc.FadeIn:create(0.1))
			button:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		end
		local action = cc.Sequence:create(
		-- cc.DelayTime:create((i-1)*0.1),
				cc.CallFunc:create(CreateBtnEffect),
				cc.DelayTime:create(0.1),
				cc.EaseBackOut:create(cc.ScaleTo:create(1, 1)),
				cc.CallFunc:create(AddNameLabel)
		)
		button:runAction(action)

		local lockIcon = display.newImageView('ui/common/common_ico_lock.png')
		lockIcon:setVisible(btnData[i].moduleTag and CommonUtils.UnLockModule(btnData[i].moduleTag) == false)
		lockIcon:setPosition(utils.getLocalCenter(button))
		button:addChild(lockIcon)
	end
end


--[[
类别按钮回调
--]]
function HandbookMediator:ButtonCallback( sender )
	PlayAudioByClickNormal()

	local tag = sender:getTag()
	if tag == 1001 then
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'MapOverviewMediator'})

	elseif tag == 1002 then
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'BossStoryMediator'})

	elseif tag == 1003 then
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'CardEncyclopediaMediator'})

	elseif tag == 1006 then -- 飨灵收集奖励
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'CardGatherRewardMediator'})

	elseif tag == 1004 then
		if GAME_MODULE_OPEN.NEW_PLOT then
			if CommonUtils.UnLockModule(RemindTag.PLOT_COLLECT, true) then
				app.router:Dispatch({name = 'HomeMediator'}, {name = 'plotCollect.PlotCollectMediator'})
			end
		else
			app.router:Dispatch({name = 'HomeMediator'}, {name = 'StoryMissionsCollectionMediator'})
		end

	elseif tag == 1005 then
		if GAME_MODULE_OPEN.SKIN_COLLECTION then
			app.router:Dispatch({name = 'HomeMediator'}, {name = "collection.roleIntroduction.RoleIntroductionMainMediator"})
		else
			app.router:Dispatch({name = 'HomeMediator'}, {name = 'NPCManualHomeMediator'})
		end

	elseif tag == 1007 then
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'collection.skinCollection.SkinCollectionMainMediator'})
	end
end


function HandbookMediator:OnRegist(  )
end

function HandbookMediator:OnUnRegist(  )
	---@type GameScene
	-- 层级的切换会自动删除当前的dialog  所以不用主动的删除 就会引起二次删除
	--if self:GetFacade():RetrieveMediator("HomeMediator")  then
	if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
		self:GetViewComponent():runAction(cc.RemoveSelf:create())
		self:SetViewComponent(nil)
	end
	--end
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end
return HandbookMediator
