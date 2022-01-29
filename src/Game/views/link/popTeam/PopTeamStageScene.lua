--[[
 * author : liuzhipeng
 * descpt : 联动 pop子 关卡Scene
--]]
local GameScene = require('Frame.GameScene')
local PopTeamStageScene = class('PopTeamStageScene', GameScene)

local RES_DICT = {
	COMMON_TITLE                    = _res('ui/common/common_title.png'),
	COMMON_TIPS                     = _res('ui/common/common_btn_tips.png'),
	COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
	BG                              = _res('ui/link/popTeam/stage/bg.png'),
	COMMON_BTN_SWITCH_LEFT          = _res('ui/common/common_btn_switch_left.png'),
	COMMON_BTN_SWITCH_RIGHT         = _res('ui/common/common_btn_switch_right.png'),
	-- spine --
}
local CreateStageCell = nil
function PopTeamStageScene:ctor( ... )
	self.super.ctor(self, 'PopTeamStageScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function PopTeamStageScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- CommonMoneyBar
		local moneyBar = require('common.CommonMoneyBar').new()
		view:addChild(moneyBar, 20)
		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
				{
					ap = display.LEFT_CENTER,
					n = RES_DICT.COMMON_BTN_BACK,
					scale9 = true, size = cc.size(90, 70),
					enable = true,
				})
		view:addChild(backBtn, 10)
		-- 标题板
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = false,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = '标题板', fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		-- local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 29)
		-- tabNameLabel:addChild(tabtitleTips, 1)
		-- 背景
		-- local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2, {isFull = true})
		-- view:addChild(bg, 1)
		-- 地图page view
		local pageSize = size
		local mapPageView = CPageView:create(pageSize)
		mapPageView:setAnchorPoint(cc.p(0.5, 0.5))
		mapPageView:setPosition(cc.p(pageSize.width * 0.5, pageSize.height * 0.5))
		mapPageView:setDirection(eScrollViewDirectionHorizontal)
		mapPageView:setSizeOfCell(pageSize)
        mapPageView:setName('CPAGE_VIEW')
		mapPageView:setBounceable(false)
		mapPageView:setDragable(false)
		mapPageView:setAutoRelocate(false)
		view:addChild(mapPageView, 3)
		-- 翻页按钮
		local prevBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		prevBtn:setScaleX(-1)
		prevBtn:setVisible(false)
		display.commonUIParams(prevBtn, {po = cc.p(display.SAFE_L + 15 + prevBtn:getContentSize().width * 0.5, size.height * 0.5)})
		view:addChild(prevBtn, 20)
		prevBtn:setTag(2001)
		local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		nextBtn:setVisible(false)
		display.commonUIParams(nextBtn, {po = cc.p(display.SAFE_R - 15 - nextBtn:getContentSize().width * 0.5, size.height * 0.5)})
		view:addChild(nextBtn, 20)
		nextBtn:setTag(2002)
		return {
			view                = view,
			moneyBar            = moneyBar,
			backBtn             = backBtn,
			tabNameLabel        = tabNameLabel,
			mapPageView         = mapPageView,
			prevBtn        	    = prevBtn,
			nextBtn        	    = nextBtn,

		}
	end
	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function PopTeamStageScene:InitMoneyBar( moneyIdMap )
	local viewData = self:GetViewData()
	viewData.moneyBar:reloadMoneyBar(moneyIdMap)
end
--[[
获取viewData
--]]
function PopTeamStageScene:GetViewData()
	return self.viewData
end
return PopTeamStageScene