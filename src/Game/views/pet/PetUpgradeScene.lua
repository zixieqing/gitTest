--[[
堕神 升级 强化 洗炼 3tab 界面
@params id int 目标堕神数据库id
--]]
local CommonDialog = require('common.CommonDialog')
local PetUpgradeScene = class('PetUpgradeScene', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
override
initui
--]]
function PetUpgradeScene:InitialUI()

	self.mainId = self.args.id

	local function CreateView()

		local petUpgradeLayer = require('Game.views.pet.PetUpgradeLayer').new({
			id = self.mainId
		})
		petUpgradeLayer:setAnchorPoint(cc.p(0.5, 0.5))
		petUpgradeLayer:setName('petUpgradeLayer')

	    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
	    backBtn:setName('backBtn')
	    display.commonUIParams(backBtn, {po = cc.p(
	    	display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,
	    	display.size.height - 18 - backBtn:getContentSize().height * 0.5
	    )})
	    self:addChild(backBtn, 5)
 
		return {
			view = petUpgradeLayer,
			backBtn = backBtn
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )

	
		self.viewData.backBtn:setOnClickScriptHandler(function( sender )
			PlayAudioByClickClose()
			self:CloseHandler()
			GuideUtils.DispatchStepEvent()
		end)

	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
@override
close handler 
--]]
function PetUpgradeScene:CloseHandler()
	-- CommonDialog.CloseHandler(self)
	local currentScene = uiMgr:GetCurrentScene()
	if currentScene then
        currentScene:RemoveDialogByTag(self.args.tag)
	end
	AppFacade.GetInstance():DispatchObservers('REMOVE_PET_UPGRADE_SCENE')
end
---------------------------------------------------
-- handler end --
---------------------------------------------------









return PetUpgradeScene
