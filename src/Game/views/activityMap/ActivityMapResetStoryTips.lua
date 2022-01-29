--[[
活动重置剧情tips
--]]
local ActivityMapResetStoryTips = class('ActivityMapResetStoryTips', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.activityMap.ActivityMapResetStoryTips'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function ActivityMapResetStoryTips:ctor( ... )
	self.args = unpack({...})
	self.callback = self.args.callback
	self.consume = self.args.consume
	self.rewards = self.args.rewards
	self.maxResetTimes = checkint(self.args.maxResetTimes)
	self.leftResetTimes = checkint(self.args.leftResetTimes)
	self:InitUI()
end
--[[
init ui
--]]
function ActivityMapResetStoryTips:InitUI()
	local function CreateView()
		local bg = display.newImageView(_res('ui/common/common_bg_8.png'), 0, 0, {enable = true, scale9 = true, size = cc.size(565, 370)})
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
		local strs = string.split(string.fmt(__('是否消耗|_num_|重置该剧情关卡？'),{['_num_'] = self.consume.num}), '|')
    	local richLabel = display.newRichLabel(bgSize.width / 2, bgSize.height - 80,
            {r = true, w = 40, c = {
 				{text = strs[1], fontSize = 22, color = '#4c4c4c'},
 				{text = strs[2], fontSize = 24, color = '#da3c3c'},
				-- {img = CommonUtils.GetGoodsIconPathById(self.consume.goodsId), scale = 0.2},
				{text = __('幻晶石'), fontSize = 22, color = '#4c4c4c'},
 				{text = strs[3], fontSize = 22, color = '#4c4c4c'},
        	}})
    	view:addChild(richLabel, 3)
    	leftTimesText = string.fmt(__('今日剩余重置次数 _num1_/_num2_'), {['_num1_'] = self.leftResetTimes, ['_num2_'] = self.maxResetTimes})
    	local leftTimesLabel = display.newLabel(bgSize.width/2, bgSize.height - 140, fontWithColor(6, {text = leftTimesText}))
    	view:addChild(leftTimesLabel, 3)

        local rewardTitle = display.newButton(bgSize.width/2, bgSize.height - 180, {n = _res('ui/common/common_title_5.png')})
		view:addChild(rewardTitle, 5)
        display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('可能获得'), reqW = 140}))
        -- 奖励
        local rewardsLayoutSize = cc.size(#self.rewards * 78 + (#self.rewards - 1) * 10, 90)
        local rewardsLayout = CLayout:create(rewardsLayoutSize)
        rewardsLayout:setPosition(bgSize.width/2, 120)
        view:addChild(rewardsLayout, 5)
        for i, v in ipairs(self.rewards) do
			local goodsNode = require('common.GoodNode').new({
				id = v.goodsId,
				showAmount = false,
				callBack = function (sender)
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end
			})
			goodsNode:setScale(0.7)
			goodsNode:setAnchorPoint(0, 0.5)
			goodsNode:setPosition(cc.p(88 * (i - 1), rewardsLayoutSize.height/2))
			rewardsLayout:addChild(goodsNode)
        end
        -- 按钮
   		local cancelBtn = display.newButton(bgSize.width/2 - 80,45,{
   		    n = _res('ui/common/common_btn_white_default.png'),
   		    cb = function(sender)
   		        PlayAudioByClickClose()
   		        if self.cancelBack then
   		            self.cancelBack()
   		        end
   		        self:removeFromParent()
   		    end
   		})
   		display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __('取消')}))
   		view:addChild(cancelBtn, 3)

   		-- entry button
   		local entryBtn = display.newButton(bgSize.width/2 + 80,45,{
   		   n = _res('ui/common/common_btn_orange.png'),
   		   cb = function(sender)
   		        PlayAudioByClickNormal()
   		        if self.callback then
   		            self.callback()
   		        end
   		        self:removeFromParent()
   		    end
   		})
   		display.commonLabelParams(entryBtn,fontWithColor(14,{text = __('确定')}))
   		view:addChild(entryBtn, 3)
   		return {
			view     = view,
		}
	end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end

return ActivityMapResetStoryTips