local QuestCommentCell = class('QuestCommentCell', function ()
	local QuestCommentCell = CLayout:create(cc.size(1023,100))
	QuestCommentCell.name = 'home.QuestCommentCell'
	QuestCommentCell:enableNodeEvents()
	return QuestCommentCell
end)
local ZAN = 1
function QuestCommentCell:ctor( ... )
	local size = cc.size(1023,100)
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventnode = eventNode
	local cellView = display.newImageView(_res('ui/map/comment/comment_frame_text_1.png'),utils.getLocalCenter(eventNode).x, utils.getLocalCenter(eventNode).y)
	self.cellView = cellView
	self.eventnode:addChild(cellView)
	local userNameLable = display.newLabel(212/2, size.height/2,
			{text = "", fontSize = 22, color = '#644a3a', ap = cc.p(0.5,0.5), maxW = 200 ,hAlign = display.TAC})
	self.userNameLable = userNameLable 
	self.eventnode:addChild(self.userNameLable)
	local commentsLabel = display.newLabel(244, size.height/2,
			fontWithColor(6,{text = "", ap = cc.p(0,0.5), maxW = 500 ,maxL = 2,hAlign = display.TAL}))
	self.commentsLabel = commentsLabel
	self.eventnode:addChild(self.commentsLabel)
	local thumbUp  = display.newToggleView(954,size.height/2,{
		        s = _res('ui/map/comment/comment_zan_red.png'),
		        n = _res('ui/map/comment/comment_zan_gray.png')
   			})
	self.thumbUp = thumbUp
	self.eventnode:addChild(thumbUp)
	local thumbUpNum = display.newLabel(954,35,fontWithColor(8,{text = "",ap = cc.p(0.5,1),hAlign = display.TAC}))
	self.thumbUpNum = thumbUpNum 
	self.eventnode:addChild(thumbUpNum)
	self.data = {}
end

function QuestCommentCell:updateCellUI(data,isEvenNumber)  -- 更新Cell逻辑
	self.data = data
	local ischeck = data.act 
	local userName = data.playerName or ""
	local thumbUpNum = data.upQty
	local commenttext = data.content or ""
	if ischeck  ==  ZAN then
		self.thumbUp:setChecked(true)
		self.thumbUp:setNormalImage(_res('ui/map/comment/comment_zan_red.png'))
	end
	if  thumbUpNum  then
		self.thumbUpNum:setString(thumbUpNum)
	end
	if userName then
		self.userNameLable:setString(userName)
	end
	if commenttext then
		display.commonLabelParams(self.commentsLabel,fontWithColor(6,{text = commenttext, ap = cc.p(0,0.5), w = 580 ,maxL = 2,hAlign = display.TAL}))
	end
	if isEvenNumber then
		self.cellView:setTexture(_res('ui/map/comment/comment_frame_text_1.png'))
	else
		self.cellView:setTexture(_res('ui/map/comment/comment_frame_text_2.png'))
	end
end


return QuestCommentCell