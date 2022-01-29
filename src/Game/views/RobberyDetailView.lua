--[[
获取途径界面
--]]
local RobberyDetailView = class('RobberyDetailView', function ()
	local clb = CLayout:create(cc.size(display.width,display.height))
    clb.name = 'common.RobberyDetailView'
    clb:enableNodeEvents()
    return clb
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function RobberyDetailView:ctor(...)
	self.args = unpack({...})
	PlayAudioClip(AUDIOS.UI.ui_window_open.id)
	self.bgLayer = nil
	self.bgImg = nil
	self.rewardBg = nil

    local contentView = CColorView:create(cc.c4b(0, 0, 0, 100))
    contentView:setContentSize(display.size)
    contentView:setTouchEnabled(true)
    self.contentView = contentView
    display.commonUIParams(contentView, {po = display.center})
    self:addChild(contentView, -1)
	-- bg
	local bgImg = display.newImageView(_res('ui/common/common_bg_3.png'))
 	self.bgImg = bgImg
 	local bgSize = bgImg:getContentSize()
 	local bgLayer = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {size = bgSize, ap = cc.p(0.5, 0.5)})
 	bgLayer:addChild(bgImg, 5)
 	display.commonUIParams(bgImg, {po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5)})
 	self:addChild(bgLayer)
 	local cover = CColorView:create(cc.c4b(0, 0, 0, 0))
	cover:setTouchEnabled(true)
	cover:setContentSize(bgSize)
	cover:setAnchorPoint(cc.p(0, 0))
	bgLayer:addChild(cover, -1)
 	self.bgLayer = bgLayer
 	-- 顶部背景
 	local bgUp = display.newButton(bgSize.width * 0.5, bgSize.height - 3,
 		{n = _res('ui/common/common_bg_title_2.png'), ap = cc.p(0.5, 1), enable = false})
 	bgLayer:addChild(bgUp, 10)
 	display.commonLabelParams(bgUp, {text = __('捣乱详情'), fontSize = 22, color = '#ffffff'})
     

 	-- 途径列表
 	local listBgFrameSize = cc.size(510,575)
 	local gainListSize = cc.size(listBgFrameSize.width, listBgFrameSize.height)
 	local gainListView = CListView:create(gainListSize)
 	gainListView:setDirection(eScrollViewDirectionVertical)
 	gainListView:setBounceable(true)
 	bgLayer:addChild(gainListView, 10)
 	gainListView:setAnchorPoint(cc.p(0.5, 0))
 	gainListView:setPosition(cc.p(bgSize.width * 0.5, 17))
 	self.gainListView = gainListView  
end

--==============================--
--@param celltype 表示cell的类型 type 1、2 是被打劫状态， 3 是打劫
--desc:创建cell的tpye
--time:2017-05-08 02:22:56
--return 
--==============================--
function RobberyDetailView:createListCellView(celltype,data)
    if celltype == 1 or celltype ==  2 then
        local cellSize = cc.size(510,118)
        local cellView = CLayout:create(cellSize)
        local contentView = display.newLayer(0,0,{ ap = display.CENTER , size = cellSize ,color = cc.c4b(0,0,0,0) , enable = true })
        contentView:setPosition(cc.p(cellSize.width/2 , cellSize.height /2))
        cellView:addChild(contentView)
        --处理背景的图片
        local cellPath =  celltype == 1 and _res('ui/home/takeaway/rob_record_bg_victory_list.png')  or  _res('ui/home/takeaway/rob_record_bg_defeat_list.png')      
        local cellImage = display.newImageView(cellPath,cellSize.width/2 , cellSize.height/2)
        contentView:addChild(cellImage)

        local cellBgSize = cellImage:getContentSize()
        local headNode = require("root.CCHeaderNode").new({url  = data.robberAvatar or  "500059" ,  pre = data.robberAvatarFrame or   "500077"})
        headNode:setAnchorPoint(display.LEFT_CENTER)
        headNode:setPosition(cc.p(15,cellBgSize.height/2 ))
        headNode:setScale(0.4)
        cellImage:addChild(headNode,10)
        local strTable= {__('你护送的'),"", "" }
        strTable[2] = data.orderName

        if checkint(data.result)  == 1 then
            strTable[3] = __('防御失败')
            cellPath = _res('ui/home/takeaway/rob_record_bg_defeat_list.png')
        elseif  checkint(data.result)  == 2 then
            cellPath =  _res('ui/home/takeaway/rob_record_bg_victory_list.png')
            strTable[3] = __('保护成功')
        end
        cellImage:setTexture(cellPath)
        -- 这个表中有三个数据 第二个是区域，第三个是是否成功

        local richLabel = display.newRichLabel(113,cellBgSize.height/2 + 25, {ap = display.LEFT_CENTER ,r = true ,c = {
            fontWithColor('4', {text = strTable[1]} ),
            {fontSize = 24 ,color = '#e04c34' , text = strTable[2]},
            fontWithColor('4', {text = strTable[3]} )
        } })
        cellImage:addChild(richLabel)

        local timestr = ""
        local timeTable = string.formattedTime((getServerTime() - data.createTime))
        if timeTable.h > 0 then
            timestr =  timestr .. __(string.format( "%d小时",timeTable.h))
        end
        if timeTable.m > 0 then
            timestr =  timestr .. __(string.format( "%d分钟",timeTable.m))
        end
        if timeTable.s > 0 then
            timestr =  timestr .. __(string.format( "%d秒",timeTable.s))
        end
        timestr = timestr .. __('前')
        -- 这个地方应该写一个秒转化成小时分钟的方法
        local timeLabel = display.newLabel(113, 20, {ap = display.LEFT_CENTER , text = timestr , color = '#5c5c5c' , fontSize = 20 })
        cellImage:addChild(timeLabel)

        local robberyBtn = display.newButton(cellBgSize.width - 45 , cellBgSize.height/2 , {n = _res('ui/common/common_btn_switch.png'), ap = display.CENTER,enable = true})
        contentView:addChild(robberyBtn)
        cellView.contentView = contentView
        cellView.robberyBtn = robberyBtn
        return cellView 
    elseif celltype ==  3 then
        local cellSize = cc.size(510,51)
        local cellView = CLayout:create(cellSize)
        local contentView = CLayout:create(cellSize)
        contentView:setPosition(cc.p(cellSize.width/2 , cellSize.height /2))
        cellView:addChild(contentView)
        local bgImage = display.newImageView(_res('ui/home/takeaway/rob_record_bg_common_list.png'),cellSize.width/2,cellSize.height/2,{ap = display.CENTER})
        contentView:addChild(bgImage)
        local bgSize = bgImage:getContentSize()
       
        local timestr = ""
        
        local timeTable = string.formattedTime( (getServerTime() - data.createTime))

        if timeTable.h > 0 then
            timestr =  timestr .. __(string.format( "%d小时",timeTable.h))
        end
        if timeTable.m > 0 then
            timestr =  timestr .. __(string.format( "%d分钟",timeTable.m))
        end
        if timeTable.s > 0 then
            timestr =  timestr .. __(string.format( "%d秒",timeTable.s))
        end
        local timeLabel = display.newLabel(500, bgSize.height/2, {ap = display.RIGHT_CENTER , text = timestr , color = '#5c5c5c' , fontSize = 20 })
        bgImage:addChild(timeLabel)
        local strTable= {__('捣乱'),"", "" }
         if checkint(data.result)  == 1 then
            strTable[3] = __('的外卖成功')
        elseif  checkint(data.result)  == 2 then
            strTable[3] = __('的外卖失败')
        end
        strTable[2]  = data.victimName
        -- 这个表中有三个数据 第二个是玩家的名字，第三个是是否成功
        local richLabel = display.newRichLabel(25,cellSize.height/2, {ap = display.LEFT_CENTER ,r = true ,c = {
        fontWithColor('11', {text = strTable[1]} ),
        {fontSize = 22 ,color = '#2f5d8c' , text = strTable[2]},
        fontWithColor('11', {text = strTable[3]} )
         } })
        cellView:addChild(richLabel)
        cellView.contentView = contentView 
        return cellView
    end
end


--==============================--
--desc:创建打劫展示详情界面
--time:2017-07-04 10:36:34
--@return 
--==============================--
function RobberyDetailView:createOneRoberryDetailView ()
    -- body
    local viewSize = cc.size(389, 389)
    local bgLayout = CLayout:create(viewSize)
    bgLayout:setPosition(cc.p(display.cx+230,display.cy))
    -- bgLayout:setColor(cc.c3b(100,10,10))
    bgLayout:setAnchorPoint(display.LEFT_CENTER)
    self:addChild(bgLayout)
    --创建吞噬层
    local swallowLayer = display.newLayer(viewSize.width/2,viewSize.height/2,{scale9 = true ,size = viewSize ,ap = display.CENTER ,color = cc.c4b(0, 0, 0 ,0) ,enable = true } )
    bgLayout:addChild(swallowLayer)
    --背景图片
    local bgImage = display.newImageView(_res('ui/common/common_bg_4.png'),viewSize.width/2,viewSize.height/2,{scale9 = true ,size = viewSize ,ap = display.CENTER} )
    bgLayout:addChild(bgImage)
    -- 防御结果
    local resultLabel = display.newLabel(13,360,{ap = display.LEFT_CENTER , fontSize = 24 , color = "5c5c5c",text = "" })
    bgLayout:addChild(resultLabel,3)
    local offsetY = -25
    local height  =20
    local headNode = require("root.CCHeaderNode").new({url  = "500058" ,  pre =  "500077"})
    headNode:setAnchorPoint(display.LEFT_BOTTOM)
    headNode:setPosition(cc.p(20,260 + offsetY +height ))
    headNode:setScale(0.4)
    bgLayout:addChild(headNode,10)
    local playerImgBg = display.newImageView(_res('ui/home/takeaway/rob_record_bg_avator.png'),13,260 + offsetY, {ap = display.LEFT_BOTTOM})
    bgLayout:addChild(playerImgBg)
    local playerImgBgSize = playerImgBg:getContentSize()
    ----任务外框
    --
    local playFrame = display.newLayer(10,playerImgBgSize.height/2+5 +height,{ap = display.LEFT_CENTER , size =  cc.size(144,144)})
    playerImgBg:addChild(playFrame)
    -- 留言展示
    local languageFram =  display.newImageView(_res('ui/home/takeaway/rob_record_bg_leave_word.png'),110,playerImgBgSize.height -50, {ap = display.LEFT_TOP})
    playFrame:addChild(languageFram,2)
    local languageLabel = display.newLabel(20,50,fontWithColor('6', { ap = display.LEFT_TOP ,Ahilgn = display.TAL,text = "" ,w = 220}))
    languageFram:addChild(languageLabel,2)
    playFrame:setScale(0.8)
    --玩家的名称
    local playerName = display.newLabel(145-30, playerImgBgSize.height/2+25,fontWithColor('4', {ap = display.LEFT_CENTER , text = " "}))
    playFrame:addChild(playerName)
    
    local teamLabel = display.newLabel( 13 ,230+offsetY,fontWithColor('4', {color = '#5c5c5c',ap = display.LEFT_BOTTOM , text = __('参与捣乱的飨灵:')}))
    bgLayout:addChild(teamLabel)

    local teamSize = cc.size(372, 70) 
    local teamLayout = CLayout:create(teamSize)
    teamLayout:setPosition(cc.p(viewSize.width/2, 155+offsetY))
    teamLayout:setAnchorPoint(display.CENTER_BOTTOM)
    bgLayout:addChild(teamLayout)
    local consumLabel = display.newLabel(13,140 + offsetY,{ap = display.LEFT_CENTER , fontSize = 24 , color = "5c5c5c",text = __('你损失的道具:') })
    bgLayout:addChild(consumLabel)
    local comsumLayout =  display.newLayer(10,43+offsetY,{ size = cc.size(400 ,70) }) -- 打劫的layout
    bgLayout:addChild(comsumLayout)
    return   {
        bgLayout = bgLayout,
        resultLabel = resultLabel ,
        playerName = playerName ,
        teamLayout = teamLayout,
        headNode = headNode,
        languageLabel = languageLabel ,
        comsumLayout = comsumLayout
    }
end

--==============================--
--desc:更新抢劫玩家的详细信息
--time:2017-05-09 02:01:39
--return 
--==============================--
function RobberyDetailView:updateOneRobberyDetailView(data , view)
    local str = ""
    if  data.result == 1 then
        str = string.format(__('你未能防止%s的捣乱:'),data.robberName)
    elseif  data.result == 2 then
        str = string.format(__('你成功防御了%s的捣乱:'),data.robberName)
    end
    view.resultLabel:setString(str)
    view.playerName:setString(data.robberName)
    view.teamLayout:removeAllChildren()
    local robberAvatar = data.robberAvatar or "500058"
    local robberAvatarFrame =CommonUtils.GetAvatarFrame(data.robberAvatarFrame)

    view.headNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(robberAvatar))
    view.headNode.preBgImage:setTexture(CommonUtils.GetGoodsIconPathById(robberAvatarFrame))
    view.teamLayout:setColor(cc.c3b(10,100,231))
    local teamSize = view.teamLayout:getContentSize()
    local cardData = {} 
    for k , v in pairs(data.robberCards or {} ) do
        if v.cardId then
            table.insert( cardData,#cardData+1 ,   v )
        end
    end
    for i,v in ipairs(cardData) do
        local cardHeadNode = require('common.CardHeadNode').new({cardData = v, showActionState = false})
        cardHeadNode:setScale(0.35)
        cardHeadNode:setPosition(cc.p((i -0.5)*74 , teamSize.height/2))
        view.teamLayout:addChild(cardHeadNode)
    end
    local node = view.comsumLayout:getChildByTag(115)
    if node then
        node:removeFromParent()
        node = nil 
    end 
    local needLayout =  self:needLayout(data.rewards or {} ) 
    needLayout:setAnchorPoint(display.LEFT_CENTER)
    needLayout:setPosition(cc.p(0,50))
    needLayout:setTag(115)
    view.comsumLayout:addChild(needLayout)
    -- 嘲讽的话的显示
    local ridiculeData = CommonUtils.GetConfigAllMess('robberyRidicule','takeaway')
    local ridiculeId = data.ridicule or 1
    local str = ridiculeData[tostring(ridiculeId)].descr
    view.languageLabel:setString(str)
    view.languageLabel:getParent():setVisible(true)
    --view.languageLabel:setVisible(false)
end

--==============================--
--desc: 被打劫后损失的道具
--time:2017-07-04 01:57:56
--@consumeData: 损失道具的具体内容
--@return 
--==============================--
function RobberyDetailView:needLayout(consumeData)
    local consume_Data = consumeData 
    local goodSize  = cc.size(80,80)
    local needSize = cc.size(goodSize.width * (table.nums(consume_Data)) ,goodSize.height)
    local needLayout = CLayout:create(needSize)
      for i =1 , #consume_Data do
        local data = consume_Data[i]
        local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true})
            display.commonUIParams(goodNode, {animate = false, cb = function (sender)
                uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
        end})
        goodNode:setAnchorPoint(cc.p(0.5,0.5))
        goodNode:setPosition(cc.p((i-0.5)*goodSize.width ,needSize.height/2))
        goodNode:setScale(0.6)
        needLayout:addChild(goodNode) 
    end  
    return needLayout
end 


return RobberyDetailView
