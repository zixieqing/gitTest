--[[
好友捐赠view
--]]
local FriendDonationView = class('FriendDonationView', function ()
	local node = CLayout:create(cc.size(1068, 574))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.FriendDonationView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local size = cc.size(1068, 574)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	local line = display.newImageView(_res('ui/home/friend/friend_img_fengexian.png'), 404, size.height/2)
	view:addChild(line, 10)
	-- 我的求助
	local myRequestLayout = CLayout:create(cc.size(404, size.height))
	myRequestLayout:setPosition(cc.p(202, size.height/2))
	view:addChild(myRequestLayout, 10)
	local myRequestTitle = display.newButton(202, 544, {n = _res('ui/common/common_title_5.png'), enable = false, scale9 = true })
	myRequestLayout:addChild(myRequestTitle, 10)
	display.commonLabelParams(myRequestTitle, fontWithColor(5, {text = __('我的求助') , paddingW = 30 }))
	local myRequestListBg = display.newImageView(_res('ui/home/friend/friends_bg_brown.png') , myRequestLayout:getContentSize().width/2, 268, {scale9 = true, size = cc.size(380, 500)})
	myRequestLayout:addChild(myRequestListBg, 3)
	local myRequestGridView = CGridView:create(cc.size(380, 500))
	myRequestGridView:setSizeOfCell(cc.size(380, 154))
	myRequestGridView:setDirection(eScrollViewDirectionVertical)
	myRequestGridView:setPosition(cc.p(myRequestLayout:getContentSize().width/2, 268))
	myRequestGridView:setColumns(1)
	myRequestLayout:addChild(myRequestGridView, 10)


	-- 好友求助
	local friendRequestLayout = CLayout:create(cc.size(664, size.height))
	friendRequestLayout:setPosition(cc.p(735, size.height/2))
	view:addChild(friendRequestLayout, 10)
	local friendRequestTitle = display.newButton(332, 544, {n = _res('ui/common/common_title_5.png'), enable = false})
	friendRequestLayout:addChild(friendRequestTitle, 10)
	display.commonLabelParams(friendRequestTitle, fontWithColor(5, {text = __('好友求助')}))
	local friendRequestListBg = display.newImageView(_res('ui/home/friend/friends_bg_brown.png') , friendRequestLayout:getContentSize().width/2+5, 268, {scale9 = true, size = cc.size(638, 500)})
	friendRequestLayout:addChild(friendRequestListBg, 3)
	local tipsBtn = display.newButton(438, 544, {n = _res('ui/common/common_btn_tips.png')})
	friendRequestLayout:addChild(tipsBtn, 10)
	local timesLabel = display.newLabel(650, 544, fontWithColor(16, {text = '', ap = cc.p(1, 0.5)}))
	friendRequestLayout:addChild(timesLabel, 10)
	local friendRequestGridView = CGridView:create(cc.size(638, 500))
	friendRequestGridView:setSizeOfCell(cc.size(638, 154))
	friendRequestGridView:setDirection(eScrollViewDirectionVertical)
	friendRequestGridView:setPosition(cc.p(friendRequestLayout:getContentSize().width/2, 268))
	friendRequestGridView:setColumns(1)
	friendRequestLayout:addChild(friendRequestGridView, 10)




	return {  
		view                  = view,
		myRequestGridView     = myRequestGridView, 
		friendRequestGridView = friendRequestGridView,
		friendRequestLayout  = friendRequestLayout,
		tipsBtn               = tipsBtn,
		timesLabel            = timesLabel

	}
end
-- 没有留言的时候
function FriendDonationView:CreateNoFriendNeedHelp()
	local richLabel = display.newRichLabel(400, 350 ,{ r = true  ,c ={
		{
			img = _res('ui/home/infor/personal_information_ico_reply.png'), scale = 1.2, ap = cc.p(0.3, 0.3)
		},
		fontWithColor('14',{text = __('暂无好友求助') , color = '5b3c25' , fontSize = 20   })
	}
	})
	return richLabel
end
function FriendDonationView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return FriendDonationView
