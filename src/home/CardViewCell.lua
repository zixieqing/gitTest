local CardViewCell = class('home.CardViewCell',function ()
    local pageviewcell = CTableViewCell:new()
    pageviewcell.name = 'home.CardViewCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

local img = {
    {image = 'ui/common/card_job_def.png'},
    {image = 'ui/common/card_job_atk.png' },
    {image = 'ui/common/card_job_arrow.png' },
    {image = 'ui/common/card_job_heart.png'},
    -- {image = 'ui/home/teamformation/card_job_heart.png'},
}
local RankImg = {
    {image = 'ui/home/teamformation/choosehero/team_card_ico_white.png'},
    {image = 'ui/home/teamformation/choosehero/team_card_ico_blue.png'},
    {image = 'ui/home/teamformation/choosehero/team_card_ico_purple.png' },
    {image = 'ui/home/teamformation/choosehero/team_card_ico_orange.png'},
    -- {image = 'ui/home/teamformation/card_job_heart.png'},
}
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
function CardViewCell:ctor( ... )
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    self.cells = {} --保存的格子
end

local function CreateCardCell( size )
    local view = CLayout:create(size)
    local rankBg = display.newImageView(_res('ui/home/teamformation/choosehero/team_bg_card_thumb_1.png'), size.width * 0.5, size.height * 0.5)
    view:addChild(rankBg)
    -- 描述文字
    local desLabel = display.newLabel(size.width /2 - 4,size.height /2 - 10,
        {text = __('移除编队'), fontSize = 24, color = '#5c5c5c', ap = cc.p(0.5, 0.5)})
    rankBg:addChild(desLabel)
    desLabel:setVisible(false)
    local desLabelSize = display.getLabelContentSize(desLabel)
    if desLabelSize.width > 110  then
        display.commonLabelParams(desLabel , {hAlign = display.TAC , w = 110 })
    end

    local heroBg = display.newImageView(_res('ui/home/teamformation/choosehero/team_card_bg_parten.png'), size.width * 0.5, size.height,{
        scale9 = true, size = cc.size(168,168)
    })
    heroBg:setAnchorPoint(cc.p(0.5,0))
    heroBg:setPositionY( size.height - heroBg:getContentSize().height - 24 )
    view:addChild(heroBg,-2)
    heroBg:setVisible(true)

    local lightBg = display.newImageView(_res('ui/home/teamformation/choosehero/team_ico_inlight.png'), 0, 0)
    lightBg:setAnchorPoint(cc.p(0.5,0.5))
    lightBg:setPosition(utils.getLocalCenter(heroBg))
    heroBg:addChild(lightBg,1)

    -- 背景
    -- local bgClippingNode = cc.ClippingNode:create()
    -- bgClippingNode:setContentSize(cc.size(heroBg:getContentSize().width, heroBg:getContentSize().height))
    -- bgClippingNode:setAnchorPoint(0.5, 0)
    -- bgClippingNode:setPosition(cc.p(size.width * 0.5, size.height - heroBg:getContentSize().height - 24))
    -- bgClippingNode:setInverted(false)
    -- view:addChild(bgClippingNode, 1)

    -- local cutLayer = display.newNSprite(_res('ui/home/teamformation/choosehero/team_bg_mask.png'), utils.getLocalCenter(bgClippingNode).x, utils.getLocalCenter(bgClippingNode).y, {ap = cc.p(0.5, 0.5)})

    local heroImage = display.newImageView(
        _res('ui/home/teamformation/choosehero/team_bg_avater.png'),0, 0)
    heroImage:setPosition(utils.getLocalCenter(view))

    heroImage:setAnchorPoint(0.5, 0)
    heroImage:setPosition(cc.p(size.width * 0.5, size.height - heroBg:getContentSize().height - 24))
    -- heroImage:setPosition(cc.p(size.width * 0.5, size.height  - 24))
    view:addChild(heroImage,-1)
    heroImage:setVisible(true)

    -- bgClippingNode:setStencil(cutLayer)
    -- bgClippingNode:setAlphaThreshold(0.01)


    local  numLabel = display.newLabel(size.width * 0.5 ,7,{
        fontSize = 22, color = 'ffffff', w = 144,h = 36,text = ' '
    }) 
    numLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
    numLabel:setAnchorPoint(cc.p(0.5,0))
    view:addChild(numLabel)
    numLabel:setVisible(true)

    local levelBtn = display.newButton(0, 0, {n = _res('ui/home/teamformation/choosehero/team_card_bg_level.png')})
    display.commonUIParams(levelBtn, {po = cc.p(8, size.height - 20),ap = cc.p(0,1)})
    display.commonLabelParams(levelBtn,{fontSize = 22, color = '#ffffff', text = ' ',offset = cc.p(0,0)})
    view:addChild(levelBtn,3)


    local imgbg = display.newButton(0, 0, {n = _res('ui/home/teamformation/choosehero/card_order_ico_selected.png')})
    display.commonUIParams(imgbg, {po = cc.p(size.width + 1, 64),ap = cc.p(1,0)})
    view:addChild(imgbg,13)
    imgbg:setTouchEnabled(false)
    imgbg:setScale(0.55)
    local pos = imgbg:getContentSize()
    local  buildImg = display.newImageView(_res('ui/home/teamformation/card_job_heart.png'))
    buildImg:setPosition(cc.p(pos.width * 0.5,pos.height * 0.5))
    imgbg:addChild(buildImg)
    imgbg:setVisible(true)

    -- numberBg = display.newButton(0, 0, {n = _res('ui/home/teamformation/choosehero/team_bg_number_team.png')})
    -- display.commonUIParams(numberBg, {po = cc.p(10,size.height - 28),ap = cc.p(0,1)})
    -- display.commonLabelParams(numberBg,{fontSize = 24, color = '#ffffff', text = __('1'),offset = cc.p(0,-6)})
    -- view:addChild(numberBg,12)
    -- numberBg:setTouchEnabled(false)
    -- numberBg:setVisible(true)

    local starlayout = CLayout:create()
    starlayout:setAnchorPoint(cc.p(0.5,0.5))
    starlayout:setPosition(cc.p(size.width * 0.5,numLabel:getBoundingBox().height + 16 ))
    view:addChild(starlayout)
    starlayout:setVisible(true)
    local clickAction = display.newImageView(_res('ui/common/story_tranparent_bg.png'),checkint(size.width /2),checkint(size.height / 2),{
        scale9 = true, enable = true, size = size
    })
    view:addChild(clickAction,20)


    local  statusBg = display.newButton(0, 0, {n = _res('ui/home/teamformation/choosehero/team_card_bg_state.png')})
    display.commonUIParams(statusBg, {po = cc.p(5,numLabel:getBoundingBox().height + 41),ap = cc.p(0,0.5)})
    display.commonLabelParams(statusBg,{fontSize = 20, color = '#5c5c5c', text = ' ',offset = cc.p(20,0)})
    view:addChild(statusBg,2)
    statusBg:setTouchEnabled(false)
    statusBg:setVisible(false)

    return {
        view    = view,
        rankBg  = rankBg,
        clickAction = clickAction,
        desLabel = desLabel,
        heroBg  = heroBg,
        heroImage = heroImage,
        numLabel    = numLabel,
        imgbg       = imgbg,
        buildImg    = buildImg,
        -- numberBg    = numberBg,
        starlayout  = starlayout,
        levelBtn    = levelBtn,
        statusBg    = statusBg,
    }

end

--[[
    创建单元格根据数据
]]
function CardViewCell:CreateCells( sliceDatas )
    local contentView = self:getChildByTag(8888)
    if not contentView then
        contentView = CLayout:create(self:getContentSize())
        contentView:setPosition(utils.getLocalCenter(self))
        contentView:setTag(8888)
        self:addChild(contentView, 2)
        local cellSize = cc.size( self:getContentSize().width / 6, self:getContentSize().height )
        for i, cardData in ipairs(sliceDatas) do
            local x = (i - 0.5)
            local cardHeadNode = require('common.CardHeadNode').new({id = checkint(cardData.id), showActionState = true})
            cardHeadNode:setScale(0.5)
            cardHeadNode:setPosition(cc.p(x * cellSize.width, cellSize.height * 0.5 ))
            contentView:addChild(cardHeadNode)
            cardHeadNode:setTag(checkint(cardData.index))
            cardHeadNode:runAction(cc.Sequence:create(
                cc.Spawn:create(cc.FadeIn:create(0.4), cc.ScaleTo:create(0.4,0.95)),
                cc.CallFunc:create(function ()
                    cardHeadNode:setOnClickScriptHandler(handler(self,self.CellButtonAction))
                end))
            )
            table.insert( self.cells,cardHeadNode )
        end
    else
        --更新数据
        local dataLen = #sliceDatas
        for i=1,6 do
            local cardHeadNode = self.cells[i]
            if i > dataLen then
                if cardHeadNode then
                    cardHeadNode:setVisible(false)
                    cardHeadNode:setScale(0.95)
                end
            else
                local cardData = sliceDatas[i]
                if not cardHeadNode then
                    local cellSize = cc.size( self:getContentSize().width / 6, self:getContentSize().height )
                    local x = (i - 0.5)
                    cardHeadNode = require('common.CardHeadNode').new({id = checkint(cardData.id), showActionState = true})
                    cardHeadNode:setScale(0.95)
                    cardHeadNode:setPosition(cc.p(x * cellSize.width, cellSize.height * 0.5 ))
                    contentView:addChild(cardHeadNode)
                    cardHeadNode:setOnClickScriptHandler(handler(self,self.CellButtonAction))
                    table.insert( self.cells,cardHeadNode )
                else
                    cardHeadNode:setScale(0.95)
                end
                cardHeadNode:RefreshUI({id = checkint(cardData.id), showActionState = true})
                cardHeadNode:setVisible(true)
                cardHeadNode:setTag(checkint(cardData.index))
            end
        end
    end
end

function CardViewCell:CellButtonAction( sender )
    local index = sender:getTag()
    AppFacade.GetInstance():DispatchObservers("CardDetailActionSignal", index)
end

function CardViewCell:onExit(  )
    for i,viewData in ipairs(self.cells) do
        viewData:setScale(1.0)
        viewData:setOpacity(255)
    end
end
--[[
    更新单元格根据数据
]]
-- function CardViewCell:UpdateCell(viewData, datas )
--     local CardData = CommonUtils.GetConfig('cards', 'card', datas.cardId)
--     local qualityId = checkint(CardData.qualityId)
--     local star = checkint(datas.breakLevel)
    


--     viewData.statusBg:setVisible(false)
--     local str = ' '
--     if gameMgr:GetUserInfo().kitchenAssistantId then --是否为厨房看板娘
--         if checkint(gameMgr:GetUserInfo().kitchenAssistantId) == checkint(datas.id) then
--             str = '厨房中'
--         end
--     end
--     if gameMgr:GetUserInfo().takeAwayAssistantId then --是否为外卖看板娘
--         if checkint(gameMgr:GetUserInfo().takeAwayAssistantId) == checkint(datas.id) then
--             str = '外卖中'
--         end
--     end
--     if gameMgr:GetUserInfo().lobbyAssistantId then --是否为大堂看板娘
--         if checkint(gameMgr:GetUserInfo().lobbyAssistantId) == checkint(datas.id) then
--             str = '大堂中'
--         end
--     end
--     if str == ' ' then
--         viewData.statusBg:setVisible(false)
--     else
--         viewData.statusBg:setVisible(true)
--         viewData.statusBg:getLabel():setString(string.fmt(__('_status_'),{_status_ = str}))
--     end



--     -- viewData.numberBg:setVisible(false)
--     -- viewData.statusBg:setVisible(false)
--     local temp_teamid  = 0
--     for k,v in ipairs((AppFacade.GetInstance():GetManager("GameManager")):GetUserInfo().teamFormation) do
--         for i,v in ipairs(v.cards) do
--             if v.id == datas.id then
--                 temp_teamid = k
--                 break
--             end
--         end
--     end
--     if temp_teamid ~= 0 then
--         -- viewData.numberBg:setVisible(true)
--         -- viewData.numberBg:setPositionX(4)
--         -- viewData.numberBg:getLabel():setString(tostring(temp_teamid))
--         viewData.statusBg:getLabel():setString(__('编队中'))
--         viewData.statusBg:setVisible(true)
--     end

--     viewData.levelBtn:setVisible(true)
--     viewData.levelBtn:getLabel():setString(tostring(datas.level))

--     viewData.numLabel:setVisible(true)
--     viewData.numLabel:setString(string.fmt(__('_name_'),{_name_ = CardData.name}))


--     -- viewData.numLabel:setVisible(true)
--     -- viewData.numLabel:setString(__('等级：')..tostring(datas.level))
--     viewData.heroImage:setVisible(true)
--     viewData.starlayout:setVisible(true)
--     viewData.imgbg:setVisible(true)
--     -- viewData.imgbg:setPositionX(1)
--     viewData.rankBg:setTexture(_res(RankImg[rangeId(checkint(datas.qualityId),4)].image))
--     viewData.desLabel:setVisible(false)
--     viewData.starlayout:setContentSize(cc.size(20* star,20))
--     viewData.starlayout:removeAllChildren()
    
--     for i=1, star do
--         local lightStar = display.newImageView(_res('ui/common/common_star_l_ico.png'), 0, 0,{ap = cc.p(0.5, 0.5)})
--         viewData.starlayout:addChild(lightStar)
--         lightStar:setScale(0.5)
--         lightStar:setPosition(cc.p(8+20*(i-1),10))
--     end

--     viewData.buildImg:setTexture(_res(img[rangeId(checkint(CardData.career),4)].image))
-- end


return CardViewCell
