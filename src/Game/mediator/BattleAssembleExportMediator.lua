--[[
历练界面UI
--]] 
local RemindIcon = require('common.RemindIcon')
local BattleAssembleExportMediator = class("BattleAssembleExportMediator", mvc.Mediator)
local NAME = "BattleAssembleExportMediator"

local BattleConfig = {
	[MODULE_DATA[tostring(RemindTag.TOWER)]]        = {path = 'ui/home/nmain/mode_select_modeico_tower.png',        mediatorName = 'TowerQuestHomeMediator', 		        backMediatorName = NAME},
	[MODULE_DATA[tostring(RemindTag.PVC)]]          = {path = 'ui/home/nmain/mode_select_modeico_pvp.png',          mediatorName = 'PVCMediator', 					        backMediatorName = NAME},
	[MODULE_DATA[tostring(RemindTag.THREETWORAID)]] = {path = 'ui/home/nmain/mode_select_modeico_team.png',         mediatorName = 'RaidHallMediator', 				        backMediatorName = NAME},
	[MODULE_DATA[tostring(RemindTag.MATERIAL)]]     = {path = 'ui/home/nmain/mode_select_modeico_material.png',     mediatorName = 'MaterialTranScriptMediator', 	        backMediatorName = NAME},
	[MODULE_DATA[JUMP_MODULE_DATA.LUNA_TOWER]]      = {path = 'ui/home/nmain/mode_select_modeico_lunata.png',       mediatorName = 'lunaTower.LunaTowerHomeMediator',       backMediatorName = NAME},
	[MODULE_DATA[tostring(RemindTag.CHAMPIONSHIP)]] = {path = 'ui/home/nmain/mode_select_modeico_championship.png', mediatorName = 'championship.ChampionshipHomeMediator', backMediatorName = NAME, remind = RemindTag.CHAMPIONSHIP},
}

local PreviewDefine = {
	-- ["6"] = {
    --     id         = 6,
    --     functionId = "113",
    --     name       = "凌云争锋",
    --     descr      = "踏碎云霄\\攻擂争锋",
    --     sequence   = "6",
    -- },
}


local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = app.gameMgr
function BattleAssembleExportMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.clickTag = 0
	self.allBattleData = {}

end


function BattleAssembleExportMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function BattleAssembleExportMediator:ProcessSignal(signal )
	local name = signal:GetName() 
	local data = signal:GetBody()
end


function BattleAssembleExportMediator:Initial( key )
	self.super.Initial(self,key)
	
	-- 创建界面
	self:InitScene()
end

---InitScene 初始化场景
function BattleAssembleExportMediator:InitScene()
	-- 现在做成单独的跳转场景
	local scene = uiMgr:SwitchToTargetScene('Game.views.BattleAssembleExportView')
	self:SetViewComponent(scene)

	local viewComponent = self:GetViewComponent()
	self.viewData = viewComponent.viewData

	--返回按钮
	display.commonUIParams(self.viewData.backBtn, {cb = handler(self, self.BackButtonClickHandler)})

	-- 初始化列表
	for k,v in pairs(CONF.COMMON.TRIALS_ENTRANCE:GetAll()) do
		if CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(v.functionId)]) then
			table.insert(self.allBattleData,v)
		end
	end
	for k,v in pairs(PreviewDefine) do
		table.insert(self.allBattleData,v)
	end
	sortByMember(self.allBattleData, "sequence", true)
	-- dump(self.allBattleData)
	local gridView = viewComponent.viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	gridView:setCountOfCell(table.nums(self.allBattleData))
	gridView:reloadData()
end

---BackButtonClickHandler 返回键按钮回调
function BattleAssembleExportMediator:BackButtonClickHandler(sender)
	PlayAudioByClickClose()
	self:GetFacade():RetrieveMediator('Router'):Dispatch({name = NAME}, {name = 'HomeMediator'})
end

function BattleAssembleExportMediator:OnDataSourceAction(p_convertview,idx)
	local pCell = p_convertview
	local index = idx + 1
	local cardHeadNode = nil
	local tempBtn = nil
	local nameBtn = nil
	local buyBtn = nil
	local tempBG = nil
	local desLabel1 = nil
	local desLabel2 = nil
	local  unlockImg = nil
	local tempImg = nil
	local remindIcon = nil
	local raidActivityButton
	local bg = self.viewData.gridView
	local sizee = bg:getSizeOfCell()
	-- local data = self.allTeamBossMess[index]
	local data = self.allBattleData[index]
	if data then
		if nil ==  pCell  then
			pCell = CGridViewCell:new()
			pCell:setContentSize(sizee)
			-- pCell:add(ui.layer({size = sizee, color = cc.r4b(150)}))

			local layer = display.newLayer(0, 0, {ap = cc.p(0.5, 0.5)})--bg = _res('ui/home/raidMain/raid_mode_bg_active.png'),
			display.commonUIParams(layer, {po = utils.getLocalCenter(pCell)})
			pCell:addChild(layer)

			tempBG = display.newButton(utils.getLocalCenter(pCell).x,utils.getLocalCenter(pCell).y + 10,{n = _res('ui/home/battleAssemble/mode_select_bg_active.png'),scale9 = true ,size = cc.size(370 ,500)} )
			pCell:addChild(tempBG)
			local bgSize = tempBG:getContentSize()
			layer:setContentSize(bgSize)
			tempBG:setTag(6)
			tempBG:setOnClickScriptHandler(handler(self,self.CellButtonAction))

			tempBtn = display.newButton(0, 0, {n = _res('ui/home/battleAssemble/mode_select_bg_frame.png'),enable = false})
			display.commonUIParams(tempBtn, {po = cc.p(utils.getLocalCenter(pCell).x ,utils.getLocalCenter(pCell).y + 105),ap = cc.p(0.5,0.5)})
			pCell:addChild(tempBtn)
			tempBtn:setTag(7)

		    unlockImg = display.newImageView(_res('ui/home/battleAssemble/mode_select_mask_locked.png'),utils.getLocalCenter(pCell).x ,utils.getLocalCenter(pCell).y + 105)
			pCell:addChild(unlockImg, 6)
			unlockImg:setVisible(false)
			unlockImg:setTag(8)

			local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), 
  				unlockImg:getContentSize().width/2, unlockImg:getContentSize().height/2)
			unlockImg:addChild(lockIcon)


			local lockLabel = display.newLabel(unlockImg:getContentSize().width/2, unlockImg:getContentSize().height/2 - 40,
				{text = '', fontSize = 22, color = '#ffffff'})
			unlockImg:addChild(lockLabel)
			lockLabel:setTag(1)

			local path = _res('ui/home/nmain/main_btn_tower.png')
			if BattleConfig[checkint(data.functionId)] then
				path = _res(BattleConfig[checkint(data.functionId)].path)
			end
			local tempImg = display.newImageView(path,tempBtn:getContentSize().width*0.5, tempBtn:getContentSize().height*0.5)
			tempBtn:addChild(tempImg, 6)

		 	local lineImg = display.newNSprite(_res('ui/home/battleAssemble/mode_select_bg_line1.png'), utils.getLocalCenter(pCell).x, utils.getLocalCenter(pCell).y - 45)
		 	pCell:addChild(lineImg, 5)


			desLabel1 = display.newLabel(utils.getLocalCenter(pCell).x, utils.getLocalCenter(pCell).y - 20,
		  		{text = '', fontSize = 22, color = '#b58a79'})
		  	pCell:addChild(desLabel1)
		  	desLabel1:setTag(11)

			desLabel2 = display.newLabel(utils.getLocalCenter(pCell).x, utils.getLocalCenter(pCell).y - 75,
				{text = '', fontSize = 22, color = '#b58a79'})
			pCell:addChild(desLabel2)
			desLabel2:setTag(12)

			nameBtn = display.newButton(0, 0, {n = _res('ui/home/battleAssemble/mode_select_btn_active.png'),enable = false})
			display.commonUIParams(nameBtn, {po = cc.p(utils.getLocalCenter(pCell).x ,utils.getLocalCenter(pCell).y - 130),ap = cc.p(0.5,0.5)})
			display.commonLabelParams(nameBtn, fontWithColor(14,{text = ' ',color = 'ffffff'}))
			pCell:addChild(nameBtn)
			nameBtn:setTag(9)

			buyBtn = display.newButton(0, 0, {n = _res('ui/home/battleAssemble/mode_btn_addchance.png'),enable = true})
			display.commonUIParams(buyBtn, {po = cc.p(utils.getLocalCenter(pCell).x ,0),ap = cc.p(0.5,0)})
			display.commonLabelParams(buyBtn, fontWithColor(14,{text = ' ',color = 'ffffff',offset = cc.p(-20,0)}))
			pCell:addChild(buyBtn)
			buyBtn:setTag(10)
			buyBtn:setOnClickScriptHandler(handler(self,self.BuyButtonActions))

			if utils.isExistent(_res("ui/home/activity/doubleActivity/raid_activity_label_slice")) then
				raidActivityButton = display.newButton(sizee.width /2 , sizee.height - 279, {n = _res('ui/home/activity/doubleActivity/raid_activity_label_slice') , scale9 =true  , size = cc.size(300, 35) })
				pCell:addChild(raidActivityButton )			
				raidActivityButton:setTag(13)
				raidActivityButton:setVisible(false)

				local raidActivityButtonSize = raidActivityButton:getContentSize()
				local raidActivityLabel = display.newButton(raidActivityButtonSize.width/2 , raidActivityButtonSize.height/2 , {n = _res('ui/home/activity/doubleActivity/raid_activity_label_star')   })
				raidActivityButton:addChild(raidActivityLabel)
				display.commonLabelParams(raidActivityButton , fontWithColor('14' , { reqW = 300 , text =  __('超稀有掉落限时概率up！'),fontSize = 21   }))
			end

			remindIcon = RemindIcon.addRemindIcon({parent = tempBG, tag = -1, po = cc.p(tempBG:getContentSize().width - 50, tempBG:getContentSize().height - 25)})
			remindIcon:setName('remindIcon')
		else

			tempBG = pCell:getChildByTag(6)
			tempBtn = pCell:getChildByTag(7)
			unlockImg = pCell:getChildByTag(8)
			nameBtn = pCell:getChildByTag(9)
			buyBtn = pCell:getChildByTag(10)
			desLabel1 = pCell:getChildByTag(11)
			desLabel2 = pCell:getChildByTag(12)
			raidActivityButton = pCell:getChildByTag(13)
			tempImg = tempBtn:getChildByTag(14)
			remindIcon = tempBG:getChildByName('remindIcon')
		end

		xTry(function()
			local remindTag = BattleConfig[checkint(data.functionId)].remind or -1
			if remindIcon then
				remindIcon:setRemindTag(remindTag)
			end

			buyBtn:setVisible(false)
			tempBtn:setVisible(true)
			nameBtn:setVisible(true)
			unlockImg:setVisible(false)
			desLabel1:setString('') 
			desLabel2:setString('') 
			buyBtn:getLabel():setString(string.fmt(('剩余次数：_num_'), {_num_ = data.freeTimes}))
			nameBtn:getLabel():setString(data.name)

			local sss = string.split(data.descr, '\\')
			--desLabel1:setString(sss[1])
			if sss[2] then
				display.commonLabelParams(desLabel2 ,{text = sss[2] ,} )
				local desLabel2Size  = display.getLabelContentSize(desLabel2)
				if desLabel2Size.width >250   then
					display.commonLabelParams(desLabel2 ,{text = sss[2] , w = 400 , reqW = 300,hAlign = display.TAC  } )
				end
			end
			display.commonLabelParams(desLabel1 ,{text = sss[1] } )
			local desLabel1Size  = display.getLabelContentSize(desLabel1)
			if  desLabel1Size.width > 250  then
				display.commonLabelParams(desLabel1 ,{text = sss[1] , w = 400 ,reqW = 300 ,hAlign = display.TAC } )
			end
			if checkint(JUMP_MODULE_DATA.TEAM_BATTLE_SCRIPT) ==  checkint(data.functionId) then
				local data = app.activityMgr:GetActivityDataByType(ACTIVITY_TYPE.TEAM_QUEST_ACTIVITY)
				if raidActivityButton then
					if #data > 0  then
						raidActivityButton:setVisible(true)
					else
						raidActivityButton:setVisible(false)
					end
				end
			end
			if CommonUtils.UnLockModule(data.functionId) then 
				tempBG:setNormalImage(_res('ui/home/battleAssemble/mode_select_bg_active.png'))
				tempBG:setSelectedImage(_res('ui/home/battleAssemble/mode_select_bg_active.png'))
				nameBtn:setNormalImage(_res('ui/home/battleAssemble/mode_select_btn_active.png'))
				nameBtn:setSelectedImage(_res('ui/home/battleAssemble/mode_select_btn_active.png'))
				
			else
				tempBG:setNormalImage(_res('ui/home/battleAssemble/mode_select_bg_locked.png'))
				tempBG:setSelectedImage(_res('ui/home/battleAssemble/mode_select_bg_locked.png'))
				nameBtn:setNormalImage(_res('ui/home/battleAssemble/mode_select_btn_locked.png'))
				nameBtn:setSelectedImage(_res('ui/home/battleAssemble/mode_select_btn_locked.png'))
				unlockImg:setVisible(true)
				local moduleData = CommonUtils.GetConfigAllMess('module')[tostring(data.functionId)]
				local lockLabel = unlockImg:getChildByTag(1)
				lockLabel:setString(string.fmt(__('需要_num_级解锁'), {_num_ = moduleData.openLevel}))
			end
		end,__G__TRACKBACK__)
		pCell:setTag(index)
		-- pCell:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		return pCell
	end
end


--[[
@param sender button对象
--]]
function BattleAssembleExportMediator:CellButtonAction( sender )
	PlayAudioByClickNormal()
	local tag = sender:getParent():getTag()
	local data = self.allBattleData[tag]
	local preDef = PreviewDefine[tostring(tag)]
	if preDef then
		app.uiMgr:ShowInformationTips(__('该功能即将开放，敬请期待'))
		return
	end
	if not CommonUtils.UnLockModule(data.functionId ,true) then 
		return
	end

	local info = checktable(BattleConfig[checkint(data.functionId)])

	self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "BattleAssembleExportMediator"},
		{name = info.mediatorName, params = {backMediatorName = info.backMediatorName}}) --,{isBack = true}
	GuideUtils.DispatchStepEvent()
end

function BattleAssembleExportMediator:numkeyboardCallBack( data )
	-- body
	-- dump(data)
end

--[[
购买次数
@param sender button对象
--]]
function BattleAssembleExportMediator:BuyButtonActions( sender )
	local tag = sender:getParent():getTag()
	local data = self.allBattleData[tag]

	local layer = require('common.CommonTip').new({
		text = string.format(__('追加1次挑战次数')),
		descr = string.format(__(data.name))
	})
	layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)

	self.clickTag = tag
end

function BattleAssembleExportMediator:OnRegist(  )
	-- 隐藏顶部栏
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function BattleAssembleExportMediator:OnUnRegist(  )
	--显示顶部栏
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end

return BattleAssembleExportMediator
