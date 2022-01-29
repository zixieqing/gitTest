---@class Anniversary19SuppressFilterMediator : Mediator
---@field viewComponent Anniversary19SuppressFilterView
local Anniversary19SuppressFilterMediator = class('Anniversary19SuppressFilterMediator', mvc.Mediator)

local NAME = "Anniversary19SuppressFilterMediator"

function Anniversary19SuppressFilterMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

	self.currentOwner = 3
    self.currentLevel = {}
    self.currentBoss = {}
end


function Anniversary19SuppressFilterMediator:Initial(key)
    self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.anniversary19.Anniversary19SuppressFilterView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	self.ownerToggles = {viewData.guild, viewData.friend, viewData.total}

	viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.OnConfirmBtnClickHandler))
    for key, value in pairs(self.ownerToggles) do
        value:setOnClickScriptHandler(handler(self, self.OnOwnerToggleClickHandler))
    end
    for key, value in pairs(viewData.levelToggles) do
        value:setOnClickScriptHandler(handler(self, self.OnLevelToggleClickHandler))
    end

	local bossList = app.anniversary2019Mgr:GetConfigDataByName(app.anniversary2019Mgr:GetConfigParse().TYPE.BOSS)
    local x = display.cx + 54 - (table.nums(bossList) - 1) / 2 * 130
	local index = 1
	for k, v in pairs(bossList) do
        local bg = display.newImageView(app.anniversary2019Mgr:GetResPath('ui/cards/head/kapai_frame_bg.png'), x + (index-1)*130, display.cy + 20,
        {
            ap = display.CENTER,
            scale = 0.5,
        })
        viewData.view:addChild(bg)

        local bossImage = display.newImageView(CardUtils.GetCardHeadPathByCardId(k), x + (index-1)*130, display.cy + 20,
        {
            ap = display.CENTER,
            scale = 0.5,
        })
        viewData.view:addChild(bossImage)

        local cardHeadCover = display.newImageView(app.anniversary2019Mgr:GetResPath('ui/cards/head/kapai_frame_purple.png'), x + (index-1)*130, display.cy + 20)
        cardHeadCover:setScale(0.5)
        viewData.view:addChild(cardHeadCover)

        local boss = display.newToggleView(x + (index-1)*130, display.cy + 20,
        {
            ap = display.CENTER,
            s = app.anniversary2019Mgr:GetResPath('ui/mail/common_bg_list_selected.png'),
            enable = true,
        })
        boss:setScale(0.84)
        boss:setTag(k)
        boss:setOnClickScriptHandler(handler(self, self.OnBossToggleClickHandler))
        viewData.view:addChild(boss)

		self.currentBoss[tonumber(k)] = false
		index = index + 1
	end
end


function Anniversary19SuppressFilterMediator:OnRegist()
end

function Anniversary19SuppressFilterMediator:OnUnRegist()
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end


function Anniversary19SuppressFilterMediator:InterestSignals()
    local signals = {
	}
	return signals
end

function Anniversary19SuppressFilterMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
end

function Anniversary19SuppressFilterMediator:OnConfirmBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	app:DispatchObservers("WONDERLAND_SUPPREDD_BOSS_FILTER", {owner = self.currentOwner, boss = self.currentBoss, level = self.currentLevel})
    app:UnRegsitMediator(NAME)
end

function Anniversary19SuppressFilterMediator:OnOwnerToggleClickHandler( sender )
    local tag = sender:getTag()
    if self.currentOwner == tag then
        self.ownerToggles[tag]:setChecked(true)
        return
    end
    self.ownerToggles[self.currentOwner]:setChecked(false)
    self.ownerToggles[tag]:setChecked(true)
	self.currentOwner = tag
end

function Anniversary19SuppressFilterMediator:OnLevelToggleClickHandler( sender )
	local tag = sender:getTag()
	self.currentLevel[tag] = not self.currentLevel[tag]
end

function Anniversary19SuppressFilterMediator:OnBossToggleClickHandler( sender )
	local tag = sender:getTag()
	self.currentBoss[tag] = not self.currentBoss[tag]
end

return Anniversary19SuppressFilterMediator
