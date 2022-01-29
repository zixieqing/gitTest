---@class ScratcherSelectMediator : Mediator
---@field viewComponent ScratcherSelectView
local ScratcherSelectMediator = class('ScratcherSelectMediator', mvc.Mediator)

local NAME = "ScratcherSelectMediator"

function ScratcherSelectMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.data = checktable(params) or {}
      
	local t = {}      
	for n in pairs(self.data.lotteryCards) do          
		t[#t+1] = n      
	end      
	table.sort(t, function ( a, b )
		return checkint(a) < checkint(b)
	end)      
	self.poolId = t

	self.currentTarget = -1
end


function ScratcherSelectMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherSelectView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.OnConfirmBtnClickHandler))
	viewData.targetGridview:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	viewData.targetGridview:setCountOfCell(#self.poolId)
	viewData.targetGridview:reloadData()
end


function ScratcherSelectMediator:OnRegist()
	regPost(POST.FOOD_COMPARE_SELECT_POOL)
end

function ScratcherSelectMediator:OnUnRegist()
    unregPost(POST.FOOD_COMPARE_SELECT_POOL)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end


function ScratcherSelectMediator:InterestSignals()
    local signals = {
        POST.FOOD_COMPARE_SELECT_POOL.sglName,
        POST.FOOD_COMPARE_LOTTERY_HOME.sglName,
	}
	return signals
end

function ScratcherSelectMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if POST.FOOD_COMPARE_SELECT_POOL.sglName == name then
		self.data.poolId = body.requestData.poolId

		self:SendSignal(POST.FOOD_COMPARE_LOTTERY_HOME.cmdName, {activityId = self.data.requestData.activityId})
	
	elseif POST.FOOD_COMPARE_LOTTERY_HOME.sglName == name then
		local mediator = AppFacade.GetInstance():RetrieveMediator("ScratcherGameMediator")
		if mediator then
			mediator:ResetView(body, self.data.poolId)
		else
			local mediator = require('Game.mediator.scratcher.ScratcherGameMediator').new({status = body, tasks = self.data})
			AppFacade.GetInstance():RegistMediator(mediator)
		end

		app:UnRegsitMediator(NAME)
	end
end

function ScratcherSelectMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
    app:UnRegsitMediator(NAME)
    app:UnRegsitMediator("ScratcherGameMediator")
end

function ScratcherSelectMediator:OnConfirmBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	if 0 <= self.currentTarget and #self.poolId > self.currentTarget then
		self:SendSignal(POST.FOOD_COMPARE_SELECT_POOL.cmdName, {activityId = self.data.requestData.activityId, poolId = self.poolId[self.currentTarget + 1]})
	else
		app.uiMgr:ShowInformationTips(__('请先选择一个目标飨灵'))
	end
end

function ScratcherSelectMediator:OnDataSourceAction(p_convertview,idx)
	---@type ScratcherTaskCell
    local pCell = p_convertview
    if pCell == nil then
		pCell = require('Game.views.scratcher.ScratcherSelectCell').new()

		local selectToggle = pCell.viewData.selectToggle
		selectToggle:setOnClickScriptHandler(handler(self, self.OnToggleClickHandler))
	end
	xTry(function()
		self:ReloadGridViewCell(pCell, idx)
	end, __G__TRACKBACK__)
	return pCell
end

function ScratcherSelectMediator:ReloadGridViewCell( pCell, idx )
	local viewData = pCell.viewData
	local targetImage = viewData.targetImage
	local teamBg = viewData.teamBg
	local selectToggle = viewData.selectToggle
	selectToggle:setTag(idx)
	selectToggle:setChecked(self.currentTarget == idx)
	
	local cardId = self.data.lotteryCards[self.poolId[idx+1]]
	local cardConf = CommonUtils.GetConfig('cards', 'card', cardId)
	local cardSkinId = table.keys(cardConf.skin[tostring(CardUtils.SKIN_UNLOCK_TYPE.DEFAULT)])[1]
	local skinConf = CommonUtils.GetConfig('goods', 'cardSkin', cardSkinId)
	targetImage:setTexture(AssetsUtils.GetCardDrawPath(tostring(skinConf.drawId)))

	local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', skinConf.photoId)[COORDINATE_TYPE_TEAM]
	targetImage:setScale(locationInfo.scale/100)
	targetImage:setRotation((locationInfo.rotate))
	targetImage:setPosition(cc.p(locationInfo.x, (-1)*(locationInfo.y-440)))

	local qualityId = checkint(cardConf.qualityId)
	local defaultPath = CardUtils.TEAM_BG_PATH_MAP['0']
	
	local teamBgPath  = nil
	if qualityId == CardUtils.QUALITY_TYPE.UR then
		teamBgPath = skinConf.drawBackGroundId and AssetsUtils.GetCardTeamBgPath(skinConf.drawBackGroundId) or nil
	else
		teamBgPath = CardUtils.TEAM_BG_PATH_MAP[tostring(qualityId)]
	end
	viewData.teamBg:setTexture(_res(teamBgPath or defaultPath))
end

function ScratcherSelectMediator:OnToggleClickHandler( sender )
	local tag = sender:getTag()
	sender:setChecked(true)
    if self.currentTarget == tag then
        return
    end
	local lastCell = self.viewComponent.viewData.targetGridview:cellAtIndex(self.currentTarget)
	if lastCell then
		lastCell.viewData.selectToggle:setChecked(false)
	end
	self.currentTarget = tag
end

return ScratcherSelectMediator
