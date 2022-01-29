--[[
公告界面
--]]

local QuestCommentView = class('QuestCommentView', function()
	local node = CLayout:create(display.size)
	node.name = 'common.QuestCommentView'
	node:enableNodeEvents()
	return node
end)

function QuestCommentView:ctor( ... )
	self.args = unpack({...}) or {}
	self.stageTitleText =self.args.stageTitleText
	self.viewData = nil
	--创建页面
	local view = require("common.TitlePanelBg").new({ title = self.stageTitleText ..  __('关卡评论'), type = 5, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("QuestCommentMediator")
    end})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)

	local function CreateView()

		local bgSize = cc.size(1131, 639)
		local emptyView = CLayout:create(bgSize)
		display.commonUIParams(emptyView,{ap = display.LEFT_BOTTOM , po = cc.p(0,0),color = '#3e1509'})
		view:AddContentView(emptyView)
		-- 上部区域
		local topSzie = cc.size(1024,70)
		local topLayout = CLayout:create(topSzie)
		display.commonUIParams(topLayout,{po = cc.p(50,86+450),ap = display.LEFT_BOTTOM})
		emptyView:addChild(topLayout)
		local fontTable = {
			selectStatus = {fontSize = 22 ,color = '#3e1509'},
			normalStatus = {fontSize = 22 ,color = '#ecb78c'}
			}
		-- 三中评论的tag值
		local HOT_COMMENT = 2
		local NEW_COMMENT = 1
		local MY_COMMENT = 3
		local toggleSize = cc.size(170,49)
		local commentTable ={
			{ name = __('热门评论') , fontTable = fontTable , po = cc.p(20+toggleSize.width/2,topSzie.height/2-10), tag = HOT_COMMENT },
			{ name = __('最新评论') , fontTable = fontTable , po = cc.p(20+(1+0.5)*toggleSize.width+7,topSzie.height/2-10) ,tag = NEW_COMMENT  },
			{ name = __('我的评论') , fontTable = fontTable , po = cc.p(20+ (2+0.5)*toggleSize.width +14,topSzie.height/2-10) , tag = MY_COMMENT}
		}
		local toggleTable = {}
		for i =1 , 3  do
			local toggleView = display.newToggleView(commentTable[i].po.x,commentTable[i].po.y,{
		        s = _res('ui/map/comment/comment_tab_selected.png'),
		        n = _res('ui/map/comment/comment_tab_unused.png')
   			})
   			toggleView:setTag(commentTable[i].tag)
	   		local label = display.newLabel(toggleView:getContentSize().width*0.5,toggleView:getContentSize().height*0.5 - 5,{
	        	fontSize = commentTable[i].fontTable.normalStatus.fontSize ,
	        	text = commentTable[i].name,
	        	color = commentTable[i].fontTable.normalStatus.color ,
				 reqW= 160
	    	})
	    	label:setTag(1)
	    	toggleView.data = commentTable[i]
	    	toggleView:addChild(label)
	    	table.insert(toggleTable,#toggleTable+1,toggleView)
	    	topLayout:addChild(toggleView)
		end
		-- 中间区域
		local middleSize = cc.size( 1024,460)
		local middleLayout = CLayout:create(middleSize)
		display.commonUIParams(middleLayout,{ap = display.LEFT_BOTTOM , po = cc.p(50,86)})
		local imageView = display.newImageView(_res('ui/common/common_bg_list_1.png'),middleSize.width/2,middleSize.height/2)
		middleLayout:addChild(imageView)
		local annoListSize = cc.size(1023, 400)
		local gridView =  CListView:create(annoListSize)
		gridView:setDirection(eScrollViewDirectionVertical)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(0, 50))
		gridView:setBounceable(true)
		middleLayout:addChild(gridView)
		-- 在 中部片下面的翻页控制
		local bottomMiddleSize = cc.size(1023,60)
		local norImage = _res('ui/common/common_btn_switch_disabled.png')
		local selectIamge =  _res('ui/common/common_btn_switch.png')
		local leftButton = display.newButton(bottomMiddleSize.width/2 -50 ,bottomMiddleSize.height/2, {n = norImage,s = selectIamge})
		leftButton:setScale(-0.8)
   		local rightButton  = display.newButton(bottomMiddleSize.width/2 + 50,bottomMiddleSize.height/2, {n = norImage ,s = selectIamge})
   		rightButton:setScale(0.8)
   		local pageName = display.newLabel(bottomMiddleSize.width/2,bottomMiddleSize.height/2,fontWithColor(14,{text = ""} ))
   		local bottomMiddleLayout = CLayout:create(bottomMiddleSize)
   		bottomMiddleLayout:addChild(pageName)
   		bottomMiddleLayout:addChild(rightButton)
   		bottomMiddleLayout:addChild(leftButton)
   		display.commonUIParams(bottomMiddleLayout,{ap = display.LEFT_BOTTOM , po = cc.p(0,0)})
   		middleLayout:addChild(bottomMiddleLayout)
		emptyView:addChild(middleLayout)
		-- 下部区域
		local buttomSzie = cc.size(1023,86)
		local bottomLayout = CLayout:create(buttomSzie)
		display.commonUIParams(bottomLayout,{ap = display.LEFT_BOTTOM , po = cc.p(50,10)})

		-- 文本框的输入
		local editbox = ccui.EditBox:create(cc.size(863,63), _res('ui/map/comment/commcon_bg_text.png'))
		editbox:setAnchorPoint(cc.p(display.LEFT_CENTER))
	    editbox:setPosition(cc.p(0,buttomSzie.height/2))
	    editbox:setFontSize(16)
	    editbox:setFontColor(ccc3FromInt('#979797'))
	    editbox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		editbox:setPlaceholderFontSize(22)
	    editbox:setPlaceholderFontColor(cc.c3b(155,155,155))
	    editbox:setPlaceHolder(__('点击输入（54个字以内）'))
	    bottomLayout:addChild(editbox,1)

	    local sendMessage = display.newButton(buttomSzie.width,0,{
        	n = _res('ui/common/common_btn_orange.png'),
   		})

		display.commonLabelParams(sendMessage,fontWithColor(14,{text = __('发  送'),ap = cc.p(0.5,0.5)}))
   		sendMessage:setPosition(cc.p(buttomSzie.width - sendMessage:getContentSize().width/2,buttomSzie.height/2))
   		bottomLayout:addChild(sendMessage)
   		emptyView:addChild(bottomLayout)
   		-- emptyView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
   		-- bottomLayout:setBackgroundColor(cc.c4b(23, 40, 40, 128))
   		-- middleLayout:setBackgroundColor(cc.c4b(70,70, 40, 128))
   		-- topLayout:setBackgroundColor(cc.c4b(70,70, 23, 128))
   		-- gridView:setBackgroundColor(cc.c4b(70,70, 23, 128))
   		-- bottomMiddleLayout:setBackgroundColor(cc.c4b(70,70, 23, 128))
		--空白的内容区域的页面视图

		return {
			-- view       = bgData.view,
			emptyView  = emptyView,
			editbox = editbox,
			gridView   = gridView,
			pageName   = pageName ,
			leftButton = leftButton,
			-- titleLabel = titleLabel,
			rightButton = rightButton,
			sendMessage = sendMessage,
			toggleTable = toggleTable
		}
	end
	self.viewData = CreateView()
end
return QuestCommentView

