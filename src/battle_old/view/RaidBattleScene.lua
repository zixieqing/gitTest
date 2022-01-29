--[[
组队副本战斗场景
--]]
local GameScene = require( "Frame.GameScene" )
local BattleScene = __Require('battle.view.BattleScene')
local RaidBattleScene = class('RaidBattleScene', BattleScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

--[[
constructor
--]]
function RaidBattleScene:ctor(...)

	-- BattleScene.ctor( self, ... )

	-- debug --
	local args = unpack({...})

	GameScene.ctor(self,'battle.view.BattleScene')
	self.contextName = "battle.view.BattleScene"
	self.bgId = args.backgroundId
	self.weatherId = args.weatherId
	self.battleLayer = nil
	self:InitUI()
	BMediator:SetViewComponent(self)
	local raidBattleMediator = AppFacade.GetInstance():RetrieveMediator('RaidBattleMediator')
	raidBattleMediator:InitialActions()
	BMediator:InitBattleLogic()
	-- BMediator:GameStart()
	local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
	bsm:SendPacket(4029)
	-- debug --

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
init ui
--]]
function RaidBattleScene:InitUI()
	BattleScene.InitUI(self)

	------------ debug ------------
	-- self:DebugButtons()
	------------ debug ------------

	-- dump(cc.UserDefault:getInstance():getStringForKey('test_game_record'))
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- debug begin --
---------------------------------------------------
function RaidBattleScene:DebugButtons()
	local debugBtns = {
		{name = '攻击', cb = function (sender)
			local attacker = BMediator:IsObjAliveByTag(1)
			attacker:attack(6)
		end}
	}

	for i,v in ipairs(debugBtns) do
		local btn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = v.cb})
		display.commonUIParams(btn, {po = cc.p(btn:getContentSize().width * (i - 0.5), self:getContentSize().height - 100)})
		display.commonLabelParams(btn, {text = v.name, fontSize = 24, color = '#ffffff'})
		self:addChild(btn, 99999)
	end
end
---------------------------------------------------
-- debug end --
---------------------------------------------------

return RaidBattleScene
