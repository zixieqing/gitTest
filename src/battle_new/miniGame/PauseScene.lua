--[[
cutin 场景
@params args table {
	
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local PauseScene = class('PauseScene', BaseMiniGameScene)
--[[
@override
--]]
function PauseScene:init()
	self:initView()
end
--[[
@override
--]]
function PauseScene:initView()
	BaseMiniGameScene.initView(self)

	self.viewData = nil

	local function CreateView()
		local btnsInfo = {
			{text = __('退出战斗'), icon = 'ui/battle/battle_ico_back.png', tag = 1003},
			{text = __('重新开始'), icon = 'ui/battle/battle_ico_restart.png', tag = 1004},
			{text = __('继续战斗'), icon = 'ui/battle/battle_ico_continue.png', tag = 1005},
		}
		local actionButtons = {}
		for i,v in ipairs(btnsInfo) do
			local btn = display.newButton(0, 0, {n = _res('ui/battle/battle_btn.png')})
			display.commonUIParams(btn, {po = cc.p(display.cx, ((table.nums(btnsInfo) + 1) * 0.5 - i) * (btn:getContentSize().height + 15) + display.height * 0.5)})
			self:addChild(btn)
			btn:setTag(v.tag)

			local icon = display.newNSprite(_res(v.icon), utils.getLocalCenter(btn).x - 70, utils.getLocalCenter(btn).y)
			btn:addChild(icon)

			local label = display.newLabel(
				utils.getLocalCenter(btn).x - 50, utils.getLocalCenter(btn).y,
				{fontSize = fontWithColor('M1PX').fontSize, text = v.text, color = fontWithColor('NC2').color, ap = cc.p(0, 0.5)}
			)
			btn:addChild(label)

			table.insert(actionButtons, btn)
		end
		return {
			actionButtons = actionButtons,
		}
	end

	self.viewData = CreateView()
end
--[[
@override
开始游戏
--]]
function PauseScene:start()

end
--[[
@override
游戏结束
--]]
function PauseScene:over()

end
--[[
@override
update
--]]
function PauseScene:update(dt)
	
end

function PauseScene:GoogleBack()
	local viewData = self.viewData
	if G_BattleRenderMgr and G_BattleRenderMgr.ButtonsClickHandler then
		for index, sender in pairs(viewData.actionButtons) do
			local tag = sender:getTag()
			if tag == 1005 then
				G_BattleRenderMgr:ButtonsClickHandler(sender)
				break
			end
		end
	end
end
---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function PauseScene:onTouchBegan_(touch, event)
	return true
end
function PauseScene:onTouchMoved_(touch, event)

end
function PauseScene:onTouchEnded_(touch, event)
	
end
function PauseScene:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

return PauseScene
