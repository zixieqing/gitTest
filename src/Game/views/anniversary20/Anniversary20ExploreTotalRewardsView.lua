--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 挂机游戏 视图
]]
---@class Anniversary20ExploreTotalRewardsView : Node
local Anniversary20ExploreTotalRewardsView = class('Anniversary20ExploreTotalRewardsView', function()
	return CLayout:create(display.size)
end)

local RES_DICT={
	WONDERLAND_TOWER_BG_PRESENT              = _res("ui/anniversary20/explore/exploreStep/wonderland_tower_bg_present.png"),
	WONDERLAND_TOWER_CUT_HEAD                = _res("ui/anniversary20/explore/exploreStep/wonderland_tower_cut_head.png"),
	COMMON_BTN_ORANGE                        = _res("ui/common/common_btn_orange.png"),
	COMMON_BTN_ORANGE_DISABLE                = _res("ui/common/common_btn_orange_disable.png")
}


function Anniversary20ExploreTotalRewardsView:ctor()
	self:InitUI()
end

function Anniversary20ExploreTotalRewardsView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{
		ap = display.CENTER,size = display.size , color = cc.c4b(0,0,0,0) , enable = true
	})
	self:addChild(closeLayer,0)
	local centerLayout = display.newLayer(display.cx + 0, display.cy  + 34 ,{ap = display.CENTER,size = cc.size(617,316)})
	self:addChild(centerLayout,0)
	local centerSwallowLayer = display.newLayer(308.5, 158 ,{
		ap = display.CENTER,size = cc.size(617,316),color = cc.c4b(0,0,0,0),enable = true})
	centerLayout:addChild(centerSwallowLayer,0)
	local centerBgImage = display.newImageView( RES_DICT.WONDERLAND_TOWER_BG_PRESENT ,308.5, 158,{ap = display.CENTER})
	centerLayout:addChild(centerBgImage,0)
	local titleImage = display.newImageView( RES_DICT.WONDERLAND_TOWER_CUT_HEAD ,303.5, 284,{ap = display.CENTER})
	centerLayout:addChild(titleImage,0)
	local tilteLabel = display.newLabel(308.5, 289 , {fontSize = 24,text = __('奖励总计'),color = '#FEC450',ap = display.CENTER})
	centerLayout:addChild(tilteLabel,0)
	local tilteDescr = display.newLabel(308.5, 235 , {fontSize = 24,text = __('每通过10幕梦境可领取一次奖励'),color = '#A99D86',ap = display.CENTER})
	centerLayout:addChild(tilteDescr,0)
	local rewardLayout = display.newLayer(308.5, 148 ,{ ap = display.CENTER,size = cc.size(617,316)})
	centerLayout:addChild(rewardLayout,0)
	local rewardBtn = display.newButton(309.5, 47 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	centerLayout:addChild(rewardBtn,0)
	display.commonLabelParams(rewardBtn ,fontWithColor(14 , {fontSize = 20,text = __('领取'),color = '#ffffff',paddingW  = 20,safeW = 83}))
	self.viewData = {
		centerLayout              = centerLayout,
		centerSwallowLayer        = centerSwallowLayer,
		centerBgImage             = centerBgImage,
		titleImage                = titleImage,
		tilteLabel                = tilteLabel,
		tilteDescr                = tilteDescr,
		rewardLayout              = rewardLayout,
		rewardBtn                 = rewardBtn,
		closeLayer                = closeLayer
	}
end

function Anniversary20ExploreTotalRewardsView:UpdateView()
	-- 更新按钮的状态
	self:UpdateRewardsBtnStatus()
	--更新道具显示
	self:UpdateRewardLayout()
end
function Anniversary20ExploreTotalRewardsView:UpdateRewardsBtnStatus()
	local isRewards = false
	local isBossFloor = app.anniv2020Mgr:isExploreingBossFloor()
	local isPassed =  app.anniv2020Mgr:isExploreingFloorPassed()
	if isBossFloor and isPassed then
		isRewards = isPassed
	end
	local viewData = self.viewData
	if not isRewards then
		viewData.rewardBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
		viewData.rewardBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
	end
end

function Anniversary20ExploreTotalRewardsView:UpdateRewardLayout()
	local stashRewards = app.anniv2020Mgr:getExploreingRewards()
	local viewData = self.viewData
	viewData.rewardLayout:removeAllChildren()
	local count = #stashRewards
	local rewardLayoutSize =  viewData.rewardLayout:getContentSize()
	if count == 0 then
		local  notGoodsLabel = display.newLabel(rewardLayoutSize.width/2 , rewardLayoutSize.height /2 , {
			fontSize = 24 , text = __('暂无道具可以领取')
		} )
		viewData.rewardLayout:addChild(notGoodsLabel)
	else
		---@type GoodNode
		local GoodNode = require("common.GoodNode")
		local goodSize = cc.size(120, 120 )
		rewardLayoutSize = cc.size(goodSize.width  * count , goodSize.height)
		viewData.rewardLayout:setContentSize(rewardLayoutSize)
		for i = 1 , count do
			local data = stashRewards[i]
			local goodNode =  GoodNode.new({goodsId = data.goodsId , num = data.num , showAmount = true})
			goodNode:setAnchorPoint(display.CENTER)
			goodNode:setTag(checkint(data.goodsId))
			display.commonUIParams(goodNode , {cb = function(sender)
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
			end})
			goodNode:setPosition(goodSize.width * (i - 0.5 ) ,goodSize.height/2)
			viewData.rewardLayout:addChild(goodNode)
		end
	end
end


return Anniversary20ExploreTotalRewardsView
