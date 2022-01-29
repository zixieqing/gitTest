--[[
 * created 	: 招财活动界面
 * descpt 	:
]]
local CommonDialog = require('common.CommonDialog')


local ActivityLuckCatView = class("ActivityLuckCatView", CommonDialog)

local RES_DICT = {
	BG = _res("ui/home/activity/luckycat/activity_fortunecat_bg.png"),
	MACHINE_BG = _res("ui/home/activity/luckycat/activity_fortunecat_bg_machine.png"),
	ENTRY_BUTTON = _res("ui/home/activity/luckycat/activity_fortunecat_btn.png"),
	CORE_BG = _res("ui/home/activity/luckycat/activity_fortunecat_bg_yellow.png"),
	ARROR_RIGHT = _res("ui/home/activity/luckycat/activity_fortunecat_ico_arrow.png"),
	SCORE_IMG_BG = _res("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_bg.png"),
	SCORE_0 = _res("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_0.png"),
	NOTICE_BG = _res('ui/home/activity/luckycat/activity_fortunecat_notice_bg.png'),
    LIGHT_BG = _res("ui/home/activity/luckycat/activity_fortunecat_light_bg_machine.png")

}


local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local utf8 = require("root.utf8")

--整数中获取某一位数字
local function get_one_bit_num(num, unit)
    if unit == 1 then
        return num % 10
    end
    local last_residue_num = num % math.pow(10, unit - 1)
    local now_residue_num = num % math.pow(10, unit)
    return (now_residue_num - last_residue_num) / math.pow(10, unit - 1)
end


function ActivityLuckCatView:InitialUI()

    shareFacade:RegistObserver( POST.ACTIVITY_LUCKY_CAT.sglName, mvc.Observer.new(handler(self, self.EntryCallback), self))

	local iconId = self.args.iconId or DIAMOND_ID
	local function CreateView()
        -- bg
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local bgSize = bg:getContentSize()
        -- bg view
        local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
        display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
        view:addChild(bg)
        view:setName('view')

        local rightMachine = display.newImageView(RES_DICT.MACHINE_BG, bgSize.width - 36, 30, {ap = display.RIGHT_BOTTOM})
        view:addChild(rightMachine,1)

        local x =  bgSize.width - 36 - rightMachine:getContentSize().width * 0.5
        local drawButton = display.newButton(x, 160, {
        		n = RES_DICT.ENTRY_BUTTON,
        	})
        display.commonLabelParams(drawButton, fontWithColor(14, {fontSize = 26, text = __("抽他喵的"), color = 'ffffff', outline = "5b3c25", outlineSize = 1, offset = cc.p(0, 14)}))
        view:addChild(drawButton,2)
        local cRichTable = {
            fontWithColor(6,{text = "0", fontSize = 24, color = 'd23d3d'}),
            {img = CommonUtils.GetGoodsIconPathById(iconId), scale = 0.18},
        }
        local consumeLabel = display.newRichLabel( 180, 44, {r = true,
            c = cRichTable})
        drawButton:addChild(consumeLabel, 4)
        display.commonUIParams(consumeLabel, {po = cc.p(180, 56)})
        consumeLabel:setVisible(false)


        local catImage = display.newImageView(RES_DICT.LIGHT_BG, rightMachine:getContentSize().width * 0.5 + 4, 458)
        rightMachine:addChild(catImage,2)
        local catSpine = sp.SkeletonAnimation:create("ui/home/activity/luckycat/jiqi.json","ui/home/activity/luckycat/jiqi.atlas", 1.0)
        catSpine:setPosition(cc.p(840, 334))
        catSpine:setAnimation(0, 'idle', true)
        catSpine:setName("AddVigourEffect")
        view:addChild(catSpine,5)

        -- view:addChild(catImage,2)

        local remainDrawLabel = display.newLabel(x, 88, fontWithColor(6, {fontSize = 24, color = '5b3c25', text = string.fmt(__('剩余次数: _num_'), {_num_ = 0})}))
        view:addChild(remainDrawLabel, 2)
        local showRichTable = {
            fontWithColor(6,{fontSize = 24, text = __("本次可获得 "), color = "5b3c25"}) ,
            fontWithColor(6,{text = "", fontSize = 24, color = 'd23d3d'}),
            {img = CommonUtils.GetGoodsIconPathById(iconId), scale = 0.18},
        }
        local getInfoLabel = display.newRichLabel(x , 240, {ap = display.CENTER, r = true,
                c = showRichTable})
        view:addChild(getInfoLabel, 4)
        local coreBg = display.newImageView(RES_DICT.CORE_BG, x, 376)
        view:addChild(coreBg,2)

        local arrowY = coreBg:getPositionY()
        -- local rightArrorImage = display.newImageView(RES_DICT.ARROR_RIGHT, x + rightMachine:getContentSize().width * 0.5 - 30, arrowY)
        -- view:addChild(rightArrorImage, 6)
        -- local leftArrorImage = display.newImageView(RES_DICT.ARROR_RIGHT, x - rightMachine:getContentSize().width * 0.5 + 30, arrowY)
        -- view:addChild(leftArrorImage, 6)
        -- leftArrorImage:setScaleX(-1)


        local clipView = CLayout:create(rightMachine:getContentSize())
        display.commonUIParams(clipView, {po = cc.p(bgSize.width - 36, 30),ap = display.RIGHT_BOTTOM})
        view:addChild(clipView, 100)
        local lsize = cc.size(499 , 136)
        local roleClippingNode = cc.ClippingNode:create()
        roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height))
        roleClippingNode:setAnchorPoint(0, 0)
        -- roleClippingNode:setPosition(cc.p(  x - rightMachine:getContentSize().width * 0.5, arrowY - 100))
        roleClippingNode:setPosition(cc.p(0, 278))
        roleClippingNode:setInverted(false)
        clipView:addChild(roleClippingNode, 10)
        local cutLayer = display.newLayer(
        0,
        0,
        {
            size = roleClippingNode:getContentSize(),
            ap = cc.p(0, 0),
            color = '#ffcc00'        })

        roleClippingNode:setStencil(cutLayer)

        local scoreImages = {}
        local startX = x - 192
        local ScrollNumNode = require("Game.views.activity.ScrollNumNode")
        for i=1,5 do
        	local px = startX + (i - 1) * 96
        	local scoreBg = display.newImageView(RES_DICT.SCORE_IMG_BG, px, arrowY)
        	-- local numFontImage = display.newImageView(RES_DICT.SCORE_0, 49, 79)
            local numFontImage = ScrollNumNode.new()
            display.commonUIParams(numFontImage, {po = cc.p(74 + (i - 1) * 96, 68)})
        	-- view:addChild(numFontImage, 6)
        	view:addChild(scoreBg, 3)
            roleClippingNode:addChild(numFontImage,1)
        	table.insert(scoreImages, numFontImage)
        end

        --left
        -- local cardIcon = display.newImageView(RES_DICT.CARD_IMG, 304, 468)
        -- cardIcon:setScale(0.96)
        local cardSpine = sp.SkeletonAnimation:create("ui/home/activity/luckycat/mao.json","ui/home/activity/luckycat/mao.atlas", 1.0)
        cardSpine:setPosition(cc.p(304,258))
        cardSpine:setAnimation(0, 'idle', true)
        cardSpine:setName("AddVigourEffect")
        view:addChild(cardSpine,5)

        -- view:addChild(cardIcon, 2)
        local noticeBg = display.newImageView(RES_DICT.NOTICE_BG, 290, 148)
        view:addChild(noticeBg, 2)

        local wSize = noticeBg:getContentSize()
	    --scrollview
	    local pscroll = CScrollView:create(cc.size(wSize.width-20, wSize.height-4))
	    pscroll:ignoreAnchorPointForPosition(true)
	    pscroll:setAnchorPoint(cc.p(0.5,0.5))
	    pscroll:setBounceable(false)
	    -- pscroll:getContainer():setBackgroundColor(cc.c4b(100,100,100,100))
	    pscroll:setPosition(cc.p(50, 40))
	    pscroll:setTag(881)
	    pscroll:setDragable(false)
	    pscroll:setDirection(eScrollViewDirectionVertical)
	    view:addChild(pscroll,4)
        return {
        	view = view,
        	drawButton = drawButton,
            consumeLabel = consumeLabel,
        	remainDrawLabel = remainDrawLabel,
        	getInfoLabel = getInfoLabel,
            -- rightArrorImage = rightArrorImage,
            -- leftArrorImage = leftArrorImage,
            cardSpine = cardSpine,
            catSpine = catSpine,
        	scoreImages = scoreImages,
        	scrollView = pscroll,
    	}
    end

     xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.drawButton:setOnClickScriptHandler(handler(self, self.DrawAction))
    end, __G__TRACKBACK__)

    app:DispatchSignal(POST.ACTIVITY_LUCKY_CAT.cmdName, {activityId = self.args.activityId})

    shareFacade:RegistObserver( "LUCK_DRAW_START_ANIMATION", mvc.Observer.new(handler(self, self.AnimationAction), self))
end

function ActivityLuckCatView:AnimationAction( stage, signal )
    uiMgr:GetCurrentScene():AddViewForNoTouch()
    PlayAudioClip(AUDIOS.UI.ui_cat_start.id)
    app:DispatchSignal(POST.ACTIVITY_LUCKY_CAT.cmdName, {activityId = self.args.activityId})
    -- local leftArrorImage = self.viewData.leftArrorImage
    -- local rightArrorImage = self.viewData.rightArrorImage
    local body = signal:GetBody()
    CommonUtils.DrawRewards(body.rewards)
    local no = checkint(body.rewards[1].num)
    --开始播放spine动画的逻辑
    local viewData = self.viewData
    self:runAction(cc.Sequence:create(
        cc.CallFunc:create(function()
            viewData.catSpine:setAnimation(0,"idle2",true)
            viewData.cardSpine:setAnimation(0, "idle2",true)
        end), cc.DelayTime:create(4), cc.CallFunc:create(function ( )
            --是否发送请求的逻辑
            viewData.catSpine:setAnimation(0,"idle",true)
            viewData.catSpine:setToSetupPose()
            viewData.cardSpine:setAnimation(0, "idle",true)
            viewData.cardSpine:setToSetupPose()
            PlayAudioClip(AUDIOS.UI.ui_cat_end.id)
            uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(body.rewards), addBackpack = false})
            uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        end)))
    self:SetTargetNumber(no)
end

function ActivityLuckCatView:SetTargetNumber(numNo)
    local viewData = self.viewData
    if viewData and viewData.scoreImages then
        for i=1,5 do
            local sign_num = get_one_bit_num(numNo, i)
            local numNode = viewData.scoreImages[ 5 - i + 1]
            numNode:setTag(i)
            numNode:ScrollNumber(sign_num)
        end
    end
end

function ActivityLuckCatView:EntryCallback(stage, signal)
    --入口更新界面
    if tolua.isnull(self) then return end
    local body = signal:GetBody()
    local viewData = self.viewData
    if body.currency then
        viewData.consumeLabel:setVisible(true)
        local showRichTable = {
            fontWithColor(6,{text = tostring(body.price), fontSize = 24, color = 'd23d3d'}),
            {img = CommonUtils.GetGoodsIconPathById(body.currency), scale = 0.18},
        }
        display.reloadRichLabel(viewData.consumeLabel, {c = showRichTable})
        viewData.drawButton:setTag(checkint(body.currency))
        viewData.drawButton:setUserTag(checkint(body.price))
    end
    if body.min then
        local showRichTable = {
            fontWithColor(6,{fontSize = 24, text = __("本次可获得 "), color = "5b3c25"}) ,
            fontWithColor(6,{text = tostring(body.min) .. " - ", fontSize = 24, color = 'd23d3d'}),
            fontWithColor(6,{text = tostring(body.max), fontSize = 24, color = 'd23d3d'}),
            {img = CommonUtils.GetGoodsIconPathById(body.currency), scale = 0.18},
        }
        display.reloadRichLabel(viewData.getInfoLabel, {c = showRichTable})
    end
    if body.leftTimes then
        --更新剩余次数
        viewData.remainDrawLabel:setString(string.fmt(__('剩余次数: _num_'), {_num_ = body.leftTimes}))
        if checkint(body.leftTimes) <= 0 then
            viewData.consumeLabel:setVisible(false)
            display.commonLabelParams(viewData.drawButton, fontWithColor(14, {fontSize = 26, text = __("本次活动已结束"), color = 'ffffff', outline = "5b3c25", outlineSize = 1, offset = cc.p(0, -14)}))
            viewData.getInfoLabel:setVisible(false)
            viewData.drawButton:setEnabled(false)
            -- viewData.drawButton:setOnClickScriptHandler(function(sender)
                -- PlayAudioByClickNormal()
                -- uiMgr:ShowInformationTips(__("本"))
            -- end)
        end
    end

    if body.history then
        self:ReloadMessages(body.history)
    end
end


function ActivityLuckCatView:ReloadMessages( datas )
    local pWordsLayers = {}
    --[[ local datas = {treasure = { ]]
    -- {playerName = '周周',from = 100,to = 120},
    -- {playerName = '周周2',from = 100,to = 121},
    -- {playerName = '周周',from = 100,to = 122},
    -- {playerName = '周周22',from = 100,to = 120},
    -- {playerName = '周周',from = 100,to = 121},
    -- {playerName = '周周',from = 100,to = 122},
    -- {playerName = '周周222',from = 100,to = 121},
    -- {playerName = '周周',from = 100,to = 122},

    -- }
    -- }
    self.pWordsLayers =pWordsLayers
    if datas then
        self.viewData.scrollView:getContainer():removeChildByName("CONTENT")
        local listData = checktable(datas)
        local tempLayer = CLayout:create()
        tempLayer:setName("CONTENT")
        tempLayer:setAnchorPoint(cc.p(0,0))
        self.viewData.scrollView:getContainer():addChild(tempLayer)


        local iHeight = 36*table.nums(listData)
        if iHeight < self.viewData.scrollView:getContentSize().height then
            iHeight = self.viewData.scrollView:getContentSize().height
        end
        self.iHeight =iHeight
        tempLayer:setPosition(0,iHeight)
        for i =1,2 do
            local pLayer = CLayout:create()
            pLayer:setContentSize(cc.size(400,iHeight))
            pLayer:setAnchorPoint(cc.p(0,1))
            tempLayer:addChild(pLayer)
            pLayer:setPosition(0,0-(i-1)*iHeight)
            for k =1,table.nums(listData) do
                local pCell = self:createWordCell(listData[k])
                pCell:setAnchorPoint(cc.p(0.5,1))
                pCell:setPosition(cc.p(pLayer:getContentSize().width/2,iHeight-36*(k-1)))
                pLayer:addChild(pCell)
            end

            table.insert(self.pWordsLayers,pLayer)
        end
        if not self.scheduleId then
            self.scheduleId = self:getScheduler():scheduleScriptFunc(handler(self,self.updateWords),0.05,false)
        end
    end
end

function ActivityLuckCatView:updateWords(dt)
	-- body
	for i =1,table.nums(self.pWordsLayers) do
		 local pLayer = self.pWordsLayers[i]
		 local curPos = cc.p(pLayer:getPosition())
		 curPos.y =curPos.y+1
		 if curPos.y >= self.iHeight then
		 	pLayer:setPosition(curPos.x,-1*self.iHeight)
		 else
		 	pLayer:setPosition(curPos.x,curPos.y)
		 end
	end
end

local function fixLabelText(label, params)
    local str = params.text
    local maxW = params.maxW
    if maxW > 0 and display.getLabelContentSize(label).width > maxW then
        local len = utf8.len(str)
        if len > 22 then len = 22 end
        for i = len - 1, 1, -2 do
            local t = utf8.sub(str, 1, i)
            label:setString(t)
            if display.getLabelContentSize(label).width <= maxW then
                len = i
                break
            end
        end
        label:setString(utf8.sub(str, 1, len - 1) .. '...')
    end
end

function ActivityLuckCatView:createWordCell(info)
	local cellSize = cc.size(406,36)
	local cell = CLayout:create()
    cell:setAnchorPoint(display.CENTER)
    cell:setContentSize(cellSize)
    -- local des = ""
    -- local t = CommonUtils.GetConfig('goods', 'goods',currency) or {}
    -- if t and t.name then
        -- des = t.name
    -- end


    local playerName = tostring(info.playerName)
    local playerNameLabel = display.newLabel(6,cellSize.height * 0.5, {
            ap = display.LEFT_CENTER,
            text = playerName, fontSize = 20, color = 'ffc039'
        })
    cell:addChild(playerNameLabel,1)
    fixLabelText(playerNameLabel,{text = playerName, maxW = 200})
    local offsetX = display.getLabelContentSize(playerNameLabel).width
    local wordText = display.newRichLabel(6 + offsetX + 2, cellSize.height * 0.5,{
        ap = cc.p(0,0.5),c = {
            -- {text = __('哇塞! '), fontSize = 20,color = 'ffffff'},
            -- {text = playerName,fontSize = 20,color = 'ffc039'},
            {text = string.fmt(__('用_from_'), {_from_ = checkint(info.from)}), fontSize = 20,color = 'ffffff'},
			{img = CommonUtils.GetGoodsIconPathById(info.currency), scale = 0.15},
            {text = string.fmt(__('招财获得_to_'), {_to_= checkint(info.to)}), fontSize = 20,color = 'ffffff'},
			{img = CommonUtils.GetGoodsIconPathById(info.currency), scale = 0.15}
        }
    })
    cell:addChild(wordText)
    wordText:reloadData()
    return cell
end

function ActivityLuckCatView:DrawAction(sender)
    PlayAudioByClickNormal()
    local currency = sender:getTag()
    local price = sender:getUserTag()
    local num = gameMgr:GetAmountByIdForce(currency)
    if price > num then
        --不足
        if GAME_MODULE_OPEN.NEW_STORE and checkint(currency) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            local des = ""
            local t = CommonUtils.GetConfig('goods', 'goods',currency) or {}
            if t and t.name then
                des = t.name
            end
            uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
        end
    else
        --可以抽
        app:DispatchSignal(POST.ACTIVITY_LUCKY_CAT_DRAW.cmdName, {activityId = self.args.activityId, currency = currency, price = price})
	end
end


function ActivityLuckCatView:CloseHandler()
    local currentScene = uiMgr:GetCurrentScene()
    if currentScene then
        AppFacade.GetInstance():DispatchObservers('CLOSE_COMMON_DIALOG')
        currentScene:RemoveDialogByTag(self.args.tag)
    end
end

function ActivityLuckCatView:onCleanup()
    shareFacade:UnRegistObserver(POST.ACTIVITY_LUCKY_CAT.sglName,self)
    shareFacade:UnRegistObserver("LUCK_DRAW_START_ANIMATION",self)
	if self.scheduleId then
		self:getScheduler():unscheduleScriptEntry(self.scheduleId)
	end
end

return ActivityLuckCatView
