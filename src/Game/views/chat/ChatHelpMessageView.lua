local ChatHelpMessageView = class('ChatHelpMessageView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.ChatHelpMessageView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function ChatHelpMessageView:ctor( ... )
	local datas = unpack({...})
	self.helpDatas = datas.helpDatas or {}
	self.playerDatas = datas.playerDatas or {}
	local helpType = self.helpDatas.helpType or HELP_TYPES.RESTAURANT_LUBY
	local typeDatas = {
		{size = cc.size(498, 138), name = 'bobi'},
		{size = cc.size(498, 138), name = 'bawangcan'},
		{size = cc.size(498, 180), name = 'juanzeng'},
	}

	local function CreateView()
		local helpDatas = datas.helpDatas
		local playerDatas = datas.playerDatas
		local size = typeDatas[checkint(helpType)].size
		local view = CLayout:create(size)
		view:setPosition(size.width/2, size.height/2)
		self:setContentSize(size)
		local bg = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_' .. typeDatas[checkint(helpType)].name .. '.png'), size.width/2, 0, {ap = cc.p(0.5, 0)})
		view:addChild(bg, 10)
		-- 头像
		local headImg = require('common.FriendHeadNode').new({
            enable = true, scale = 0.56, avatar = playerDatas.avatar, avatarFrame = playerDatas.avatarFrame, showLevel = true, level = playerDatas.level, callback = function ( sender )
            	uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = playerDatas.friendId, type = HeadPopupType.FRIEND})
            end
        })
        headImg:setPosition(cc.p(62, size.height - 58))
        view:addChild(headImg, 10)
        -- 名称
        local nameLabel = display.newLabel(110, size.height - 34, fontWithColor(16, {ap = cc.p(0, 0.5), text = string.format('[%s]', playerDatas.name)}))
        view:addChild(nameLabel, 10)

        local numLabel = nil
		if helpType ==  HELP_TYPES.RESTAURANT_LUBY then -- 露比
			local timeLabel = display.newLabel(110 + display.getLabelContentSize(nameLabel).width + 10, size.height - 34, {ap = cc.p(0, 0.5), fontSize = 22, color = '#ad9595', text = os.date(" %H:%M", helpDatas.helpTime  + getLoginClientTime() - getLoginServerTime())})
			view:addChild(timeLabel, 10)
			local strs = string.split(__('求助| 露比 |捣乱了餐厅'), '|')
			local descrLabel = display.newRichLabel(110, size.height - 54, {ap = cc.p(0, 1), r = true, c =
				{
        	    	{fontSize = 20, color = '#5c5c5c', text = strs[1]},
        	    	{fontSize = 20, color = '#d23d3d', text = strs[2]},
        	   		{fontSize = 20, color = '#5c5c5c', text = strs[3]}
				}
			})
			view:addChild(descrLabel, 10)
			local enterBtn = display.newButton(424, size.height - 78, {n = _res('ui/common/common_btn_orange.png'), tag = checkint(helpType)})
			enterBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
			enterBtn:setScale(0.8)
			view:addChild(enterBtn, 10)
			display.commonLabelParams(enterBtn, {text = __('前往'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
			local buttonIcon = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_' .. typeDatas[checkint(helpType)].name .. '.png'), 386, size.height - 40)
			view:addChild(buttonIcon, 10)
		elseif helpType == HELP_TYPES.RESTAURANT_BATTLE then -- 霸王餐
			local timeLabel = display.newLabel(110 + display.getLabelContentSize(nameLabel).width + 10, size.height - 34, {ap = cc.p(0, 0.5), fontSize = 22, color = '#ad9595', text = os.date(" %H:%M", helpDatas.helpTime + getLoginClientTime() - getLoginServerTime())})
			view:addChild(timeLabel, 10)
			local strs = string.split(__('正在请求| 霸王餐 |协助'), '|')
			local descrLabel = display.newRichLabel(110, size.height - 54, {ap = cc.p(0, 1), r = true, c =
				{
        	    	{fontSize = 20, color = '#5c5c5c', text = strs[1]},
        	    	{fontSize = 20, color = '#d23d3d', text = strs[2]},
        	   		{fontSize = 20, color = '#5c5c5c', text = strs[3]}
				}
			})
			view:addChild(descrLabel, 10)
			local enterBtn = display.newButton(424, size.height - 78, {n = _res('ui/common/common_btn_orange.png'), tag = checkint(helpType)})
			enterBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
			enterBtn:setScale(0.8)
			view:addChild(enterBtn, 10)
			display.commonLabelParams(enterBtn, {text = __('前往'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
			local buttonIcon = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_' .. typeDatas[checkint(helpType)].name .. '.png'), 386, size.height - 40)
			view:addChild(buttonIcon, 10)
		elseif helpType == HELP_TYPES.FRIEND_DONATION then -- 好友捐助
			local goodsName = CommonUtils.GetConfig('goods', 'goods', helpDatas.goodsId).name
			local str = string.fmt(__('求施舍，急缺:|【_name_】'), {['_name_'] = goodsName})
			local strs = string.split(str, '|')
			local descrLabel = display.newRichLabel(110, size.height - 54, {ap = cc.p(0, 1), r = true, c =
				{
        	    	{fontSize = 20, color = '#5c5c5c', text = strs[1]},
        	    	{fontSize = 20, color = '#d23d3d', text = strs[2]},
				}
			})
			view:addChild(descrLabel, 10)
			local goodsIcon = require('common.GoodNode').new({id = helpDatas.goodsId})
			goodsIcon:setScale(0.7)
			display.commonUIParams(goodsIcon, {po = cc.p(424, size.height - 58), animate = false, cb = function (sender)
				uiMgr:AddDialog("common.GainPopup", {goodId = helpDatas.goodsId})
			end})
			view:addChild(goodsIcon, 10)

			local numStr = string.fmt(__('您有:|_num_'), {['_num_'] = gameMgr:GetAmountByGoodId(helpDatas.goodsId)})
			local numStrs = string.split(numStr, '|')
			numLabel = display.newRichLabel(424, size.height - 110, {r = true, c =
				{
        	    	{fontSize = 20, color = '#5c5c5c', text = numStrs[1]},
        	    	{fontSize = 20, color = '#d23d3d', text = numStrs[2]},
				}
			})
			view:addChild(numLabel, 10)
			local enterBtn = display.newButton(424, size.height - 148, {n = _res('ui/common/common_btn_orange.png'), tag = checkint(helpType)})
			enterBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
			enterBtn:setScale(0.8)
			view:addChild(enterBtn, 10)
			display.commonLabelParams(enterBtn, {text = __('捐助'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
			local timeLabel = display.newLabel(28, size.height - 154, fontWithColor(6, {ap = cc.p(0, 0.5), text = os.date(" %H:%M", helpDatas.helpTime + getLoginClientTime() - getLoginServerTime())}))
			view:addChild(timeLabel, 10)
		end

		return {
		    view = view,
		    numLabel = numLabel
		}
	end
	self.viewData = CreateView()
	self:addChild(self.viewData.view)
	self:RefreshSelf()
end

function ChatHelpMessageView:ButtonCallback( sender )
	local helpType = sender:getTag()
	if helpType ==  HELP_TYPES.RESTAURANT_LUBY then
        local FriendAvatarMediator = require( 'Game.mediator.FriendAvatarMediator' )
        local mediator = FriendAvatarMediator.new({friendId = self.playerDatas.friendId})
        AppFacade.GetInstance():RegistMediator(mediator)
        AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
	elseif helpType ==  HELP_TYPES.RESTAURANT_BATTLE then
        local FriendAvatarMediator = require( 'Game.mediator.FriendAvatarMediator' )
        local mediator = FriendAvatarMediator.new({friendId = self.playerDatas.friendId})
        AppFacade.GetInstance():RegistMediator(mediator)
        AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
	elseif helpType ==  HELP_TYPES.FRIEND_DONATION then
		if gameMgr:GetAmountByGoodId(self.helpDatas.goodsId) > 0 then
        	local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
        	mediator:SendSignal(COMMANDS.COMMAND_Chat_Assistance, {assistanceId = self.helpDatas.assistanceId})
        	AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
		else
			if GAME_MODULE_OPEN.NEW_STORE and checkint(self.helpDatas.goodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips()
			else
				uiMgr:ShowInformationTips(__('物品不足'))
			end
        end
	end
end
function ChatHelpMessageView:RefreshSelf()
	local viewData = self.viewData
	if self.helpType == HELP_TYPES.FRIEND_DONATION then
		local str = string.fmt(__('您有:|_num_'), {['_num_'] = gameMgr:GetAmountByGoodId(self.helpDatas.goodsId)})
		local strs = string.split(numStr, '|')
		display.reloadRichLabel(viewData.numLabel, {
			c = {
    	    	{fontSize = 20, color = '#5c5c5c', text = strs[1]},
    	    	{fontSize = 20, color = '#d23d3d', text = strs[2]},
			}
		})
	end
end
return ChatHelpMessageView
