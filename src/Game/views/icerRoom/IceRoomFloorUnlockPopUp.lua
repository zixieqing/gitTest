--[[
玩家卡牌详情界面
@params table {
	cardData table 卡牌数据
	petsData table 堕神数据(新结构)
	playerData table 玩家数据
	viewType int 0 显示连携技 不显示神器  1 显示神器 不显示连携技
}
--]]
local IceRoomFloorUnlockPopUp = class('IceRoomFloorUnlockPopUp', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.iceRoom.IceRoomFloorUnlockPopUp'
	node:enableNodeEvents()
	return node
end)

--[[
constructor
--]]
function IceRoomFloorUnlockPopUp:ctor( ... )
	local args = unpack({...})
	self.roomId = args.roomId or 2
	print(self.roomId )
	self:InitUI()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化ui
--]]
function IceRoomFloorUnlockPopUp:InitUI()
	local view = require("common.TitlePanelBg").new({ title =string.format(__('扩建') , self.roomId) ,offsetX = -2, offsetY = 5,  type = 7})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	display.commonUIParams(view.viewData.eaterLayer , { cb = handler(self, self.CloseView)})
	self:addChild(view)
	view.viewData.view:setPosition(display.center)
	view.viewData.view:setAnchorPoint(display.CENTER)

	local  viewData = view.viewData
	local contentLayout = viewData.view
	local contentLayoutSize = contentLayout:getContentSize()
	local extensionLabel = display.newLabel(contentLayoutSize.width/2, contentLayoutSize.height/2 + 100,fontWithColor( 8,{fontSize = 24, 
		text = string.format(__('扩建第%s层需要以下材料') , CommonUtils.GetChineseNumber(self.roomId))
	}))
	contentLayout:addChild(extensionLabel)
	local goodLayout = self:GetUnlockGoodLayout()
	contentLayout:addChild(goodLayout)
	goodLayout:setPosition(contentLayoutSize.width/2 , contentLayoutSize.height/2)

	local extensionBtn = display.newButton(contentLayoutSize.width/2 , 70, {n = _res('ui/common/common_btn_orange.png')})
	contentLayout:addChild(extensionBtn)
	display.commonLabelParams(extensionBtn , fontWithColor(14,{text = __('扩建')}))
	display.commonUIParams(extensionBtn , {cb = handler(self, self.ExtensionIcePlace)})
end

function IceRoomFloorUnlockPopUp:GetUnlockGoodLayout()
	local  icePlaceUnlockOneConf = app.dataMgr:GetConfigDataByFileName("icePlaceUnlock", "iceBink")[tostring(self.roomId)] or {}
	local data = {}
	for k,v in pairs(icePlaceUnlockOneConf.unlockType) do
		if checkint(k) ~= UnlockTypes.AS_LEVEL and checkint(k) ~= UnlockTypes.PLAYER then

			if checkint(k) == UnlockTypes.GOLD then
				local ownNum = CommonUtils.GetCacheProductNum(GOLD_ID)
				data[#data+1] = {goodsId = GOLD_ID, showAmount = false ,  num  = ownNum .."/" .. checkint(v.targetNum)}
			elseif checkint(k) == UnlockTypes.DIAMOND then
				local ownNum = CommonUtils.GetCacheProductNum(DIAMOND_ID)
				data[#data+1] = {goodsId = DIAMOND_ID,  showAmount = false , num  = ownNum .."/" ..  checkint(v.targetNum)}
			elseif checkint(k) == UnlockTypes.GOODS then
				local ownNum = CommonUtils.GetCacheProductNum(v.targetId)
				data[#data+1] = {goodsId = checkint(v.targetId),  showAmount = false , num  =  ownNum .."/" ..  checkint(v.targetNum)}
			end

		end
	end
	local goodSize = cc.size(140* #data , 120 )
	local goodLayout = display.newLayer(0,0,{ap = display.CENTER,size = goodSize})
	for i, v in pairs(data) do
		local goodNode = require("common.GoodNode").new(v)
		goodNode:setTag(checkint(v.goodsId) )
		display.commonUIParams(goodNode , {cb = function(sender)
			app.uiMgr:AddDialog("common.GainPopup", {goodsId = sender:getTag()})
		end})
		goodLayout:addChild(goodNode)
		goodNode:setPosition(140* (i - 0.5 ), 50)
		local label = display.newLabel(60, -20 , fontWithColor(6,{ap = display.CENTER , hAlign = display.TAC ,  text = v.num}))
		goodNode:addChild(label)
	end
	return goodLayout
end

function IceRoomFloorUnlockPopUp:ExtensionIcePlace(sender)
	local  icePlaceUnlockOneConf = app.dataMgr:GetConfigDataByFileName("icePlaceUnlock", "iceBink")[tostring(self.roomId)] or {}
	local isLocked =  CommonUtils.CheckLockCondition(icePlaceUnlockOneConf.unlockType)
	if isLocked then
		app.uiMgr:ShowInformationTips(__('材料不足'))
		return
	end
	app:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = checkint(self.roomId)},'unlock')
	self:CloseView()
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------
function IceRoomFloorUnlockPopUp:CloseView()
	PlayAudioByClickClose()
	app.uiMgr:GetCurrentScene():RemoveDialog(self)
end
return IceRoomFloorUnlockPopUp
