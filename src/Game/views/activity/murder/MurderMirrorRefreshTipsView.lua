--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖刷新提示 view
--]]
local MurderMirrorRefreshTipsView = class('MurderMirrorRefreshTipsView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.activity.murder.MurderMirrorRefreshTipsView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
    TIPS_BG  = app.murderMgr:GetResPath('ui/home/activity/murder/murder_draw_bg_empty.png'),
}
local function CreateView( )
    local size = display.size
	local view = CLayout:create(size)
	local bg = display.newImageView(RES_DICT.TIPS_BG, size.width / 2, size.height / 2)
	bg:setPosition(size.width/2, size.height/2)
	view:addChild(bg, 2)
	
	local scrollViewSize = cc.size(470, 140)
	local scrollView = cc.ScrollView:create()
    scrollView:setPosition(cc.p(display.cx - scrollViewSize.width / 2 + 60, display.cy - scrollViewSize.height / 2 - 7))
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.CENTER)
	scrollView:setViewSize(scrollViewSize)
	view:addChild(scrollView, 5)
	
	local tipsLabel = display.newLabel(0, 0, {text = app.murderMgr:GetPoText(__('本轮奖池已抽完，重置至下一轮')), fontSize = 24, color = '#c99f60', w = scrollViewSize.width, hAlign = display.TAL})
	scrollView:setContainer(tipsLabel)
	local tipsLabelSize = display.getLabelContentSize(tipsLabel)
    local descrScrollTop = scrollView:getViewSize().height - tipsLabelSize.height
	scrollView:setContentOffset(cc.p(0, descrScrollTop))
	return {
		view             = view,

	}
end
function MurderMirrorRefreshTipsView:ctor( ... )
	self.activityDatas = unpack({...}) or {}
	-- eaterLayer
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.60))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(function () 
        self:runAction(cc.RemoveSelf:create())
	end)
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData = CreateView()
	self.viewData.view:setPosition(display.cx, display.cy)
	self:addChild(self.viewData.view, 1)
end
return MurderMirrorRefreshTipsView
