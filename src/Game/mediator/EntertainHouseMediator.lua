---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:25 PM
---

local Mediator = mvc.Mediator
---@class EntertainHouseMediator :Mediator
local EntertainHouseMediator = class("EntertainHouseMediator", Mediator)
local NAME = "EntertainHouseMediator"
local CARD_MAX_NUM = 6
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local contentTag = 1114 -- layout内容的tag 值
local addCardTag = 1115 -- 添加卡牌的tag
local addTeamTag = 1116 -- 添加任务小加tag
function EntertainHouseMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.data = param or {}
    self.cardHouse = self.data.cardHouse  or {} -- 勋章墙数据
    self.preIndex = nil  -- 上一次点击
    self.exchangeNum = ""
end

function EntertainHouseMediator:InterestSignals()
    local signals = {
        POST.PERSON_CHANGE_HOUSE_CARD.sglName ,
    }
    return signals
end
function EntertainHouseMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type EntertainHouseView
    self.viewComponent = require('Game.views.EntertainHouseView').new()
    self:SetViewComponent(self.viewComponent)
    local viewData = self.viewComponent.viewData
    local bgLayout = viewData.bgLayout

    if  CommonUtils.JuageMySelfOperation(self.data.playerId)  then
        for i =1 , CARD_MAX_NUM do
            local node = bgLayout:getChildByTag(i)
            local addLayout = node:getChildByTag(addCardTag)
            -- 注册事件
            addLayout:setOnClickScriptHandler(handler(self, self.ButtonAction))
        end
        self:ShowAddTeamImage()
    else    --不是自己的显示修改
        for i =1 , CARD_MAX_NUM do
            self:SetAddImageVisibleOrNot(i, false )
        end
    end
    self:EnterViewAction()
    self.viewComponent:retain()
end
-- 进入页面要做的操作
function EntertainHouseMediator:EnterViewAction()
    local   count = 0
    local function delayTimeLoad()
        count = count +1
        if count <= CARD_MAX_NUM then
            if self.cardHouse[tostring(count)]  then
                self.viewComponent:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(0.2) ,
                    cc.CallFunc:create(function ()
                        self:CreateEntertainLayout(count)
                        delayTimeLoad()
                    end)
                    )
                )
            else
                delayTimeLoad()
            end
        end
    end
    delayTimeLoad()
end
function EntertainHouseMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.PERSON_CHANGE_HOUSE_CARD.sglName then
        local requestData = data.requestData
        if requestData then
            local cardPosition = requestData.cardPosition
            local playerCardId = requestData.playerCardId
            if checkint(playerCardId) == 0 then
                self.cardHouse[tostring(cardPosition)] = nil
                self:RemoveEntertainLayout(cardPosition)
            else

                local position  = self:GetCardsCurrentPos(playerCardId)
                if position ~= 0 then -- 说明该飨灵并没有在飨灵屋内
                    self.cardHouse[tostring(position)] = nil
                    self:RemoveEntertainLayout(position)
                end
                local currentPosId =  0
                local cardPosData =  self.cardHouse[tostring(cardPosition)]
                if type(cardPosData) == 'table' and checkint(cardPosData.playerCardId) > 0   then
                    currentPosId  = cardPosData.playerCardId
                end
                if checkint(currentPosId ) ~= 0 then -- 判断当前位置是否有飨灵
                    self:RemoveEntertainLayout(cardPosition)
                    self.cardHouse[tostring(cardPosition)] = nil
                end

                local cardData = gameMgr:GetCardDataById(playerCardId)
                self.cardHouse[tostring(cardPosition)] = {
                    playerCardId = playerCardId ,
                    cardId = cardData.cardId ,
                    level =  cardData.level ,
                    breakLevel = cardData.breakLevel ,
                    defaultSkinId = cardData.defaultSkinId
                }

                self:CreateEntertainLayout(cardPosition )
            end
            self:ShowAddTeamImage()
        end
    end
end
-- 获取卡牌所在的当前位置 如果没有就返回零
function EntertainHouseMediator:GetCardsCurrentPos(playerCardId)
    local pos = 0
    for k , v in pairs(self.cardHouse) do
        if type(v) == 'table' and  checkint(v.playerCardId) == checkint(playerCardId)    then
             pos = checkint(k)
            break
        end
    end
    return pos
    
end
-- 要删除的id
function EntertainHouseMediator:RemoveEntertainLayout(index)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local bgLayout = viewData.bgLayout
    local node =  bgLayout:getChildByTag(index)
    if node and ( not  tolua.isnull(node) )then
        local contentLayout = node:getChildByTag(contentTag)
        if contentLayout and  ( not  tolua.isnull(contentLayout) )then
            contentLayout:removeFromParent()
        end
    end
end
-- 创建新的展示飨灵
function EntertainHouseMediator:CreateEntertainLayout( index)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local bgLayout = viewData.bgLayout
    local layout =  bgLayout:getChildByTag(index)
    local cardData  =  self.cardHouse[tostring(index)]
    -- 卡牌的数据表
    local cardsOneTables = CommonUtils.GetConfigAllMess('card', 'card' )[tostring(cardData.cardId)]
    local colorTable = {
        "#feebc3",
        "#aae6ff",
        "#e596ff",
        "#ffa82c",
        "#ff4040"
    }
    local color = colorTable[checkint(cardsOneTables.qualityId)]
    local cardsKindsText = CardUtils.GetCardQualityName(cardsOneTables.qualityId)
    local starNums =checkint(cardData.breakLevel)
    local sizee = cc.size(201, 248)
    local contentLayout = display.newLayer(sizee.width/2 , sizee.height/2 ,{ap = display.CENTER , size = sizee })
    contentLayout:setTag(contentTag)
    layout:addChild(contentLayout)
    local titleImage = display.newImageView(_res('ui/home/infor/personal_information_bg_card_star.png'))
    local cardKindsSize = titleImage:getContentSize()
    titleImage:setPosition(cc.p(cardKindsSize.width/2 , cardKindsSize.height/2))
    local cardsLabelLayout = display.newLayer(sizee.width/2, 20  , {ap =  display.CENTER,size =  cardKindsSize } )
    cardsLabelLayout:addChild(titleImage)
    contentLayout:addChild(cardsLabelLayout)
    -- 当且只有一个种类的Label的时候
    local kindsLabel = display.newLabel(10 , cardKindsSize.height /2 , fontWithColor('14' ,{text =  cardsKindsText , color = color , ap = display.LEFT_CENTER }))
    cardsLabelLayout:addChild(kindsLabel)

    local startWidth  =  50
    local width = 17
    for i = 1 , 5  do
        local   starImage = nil
        if i <= starNums  then
            starImage  = display.newImageView(_res('ui/cards/head/kapai_star_colour.png') , startWidth +  (i - 0.5 ) * width,cardKindsSize.height /2 )
            cardsLabelLayout:addChild(starImage,5 - i )
            starImage:setScale(0.8)
        else
            starImage = display.newImageView(_res('ui/common/kapai_star_white_blank.png') , startWidth +  (i - 0.5 ) * width,cardKindsSize.height /2 )
            cardsLabelLayout:addChild(starImage,5 - i  )
            starImage:setScale(0.5)
        end
    end
    local qAvatar = AssetsUtils.GetCardSpineNode({skinId = cardData.defaultSkinId, scale = 0.7})
    qAvatar:update(0)
    qAvatar:setTag(1)
    qAvatar:setAnimation(0, 'idle', true)
    contentLayout:addChild(qAvatar)
    qAvatar:setPosition(cc.p(sizee.width/2, 45 ))
    qAvatar:setScale(0.55)
    qAvatar:setOpacity(0)
    qAvatar:runAction(cc.FadeIn:create(0.5))
end

-- 创建显示添加飨灵队员图片的位置
function EntertainHouseMediator:ShowAddTeamImage()
    local isHave = true -- 初次显示加号
    local data ={}
    for i=1 , CARD_MAX_NUM do
        data = self.cardHouse[tostring(i)]
        if  not ( data and type(data) == "table" and   checkint(data.playerCardId) ~= 0 )    then
            self:SetAddImageVisibleOrNot(i, true )
        else
            self:SetAddImageVisibleOrNot(i, false )
        end
    end
end
-- 设置添加队伍按钮 image 是否可见
function EntertainHouseMediator:SetAddImageVisibleOrNot(index , visible)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local bgLayout = viewData.bgLayout
    local node =  bgLayout:getChildByTag(index)
    if node and ( not  tolua.isnull(node) )then
        local addLayout  = node:getChildByTag(addCardTag) -- 获取添加队伍的layout
        if addLayout and ( not  tolua.isnull(addLayout) )then
            local addTeamImage = addLayout:getChildByTag(addTeamTag)
            if addTeamImage and ( not  tolua.isnull(addTeamImage) )then
                addTeamImage:setVisible(visible)
            end
        end
    end
end
function EntertainHouseMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == addCardTag then
        local parentNode = sender:getParent()
        local pos = parentNode:getTag() -- 获取到点击的位置
        local playerCardId = checkint(self.cardHouse[tostring(pos)])
        local cardPosData = self.cardHouse[tostring(pos)] or {}
        if type(cardPosData) ==  "table" then
            playerCardId = checkint(cardPosData.playerCardId)
        end
        local  tempData ={}
        if playerCardId > 0  then  -- 如果当前数据的像数大于零的时候
            tempData.id = playerCardId
            tempData.callback = handler(self, self.chooseHeroCallBack)
            tempData.clickHeroTag = pos
            tempData.teamId = pos
        else
            tempData.callback = handler(self, self.chooseHeroCallBack)
            tempData.clickHeroTag = pos
        end
        local cardHouseData = {}
        for k ,v in pairs(self.cardHouse) do
            if v.playerCardId then
                cardHouseData[tostring( v.playerCardId)] = true
            end
        end
        tempData.cardHouseData = cardHouseData
        local ChooseCardsHouseView  = require( 'Game.views.ChooseCardsHouseView' ).new(tempData)
        ChooseCardsHouseView:setName('ChooseBattleHeroView')
        ChooseCardsHouseView:RefreshUI()
        ChooseCardsHouseView:setPosition(display.center)
        ChooseCardsHouseView:setTag(9999)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(ChooseCardsHouseView)
        ChooseCardsHouseView.eaterLayer:setOnClickScriptHandler(function (sender)
            --关闭页面
            if scene:GetDialogByTag(9999) then
                scene:RemoveDialogByTag(9999)
            end

        end)
    end
end
-- 更换位置的回调
function EntertainHouseMediator:chooseHeroCallBack(data)
    if data then
        if data.id then
            local pos = self:GetCardsCurrentPos(data.id)
            if checkint(pos) == data.clickHeroTag then
                uiMgr:ShowInformationTips(__('飨灵屋没有发生任何改变'))
                return
            end
            self:SendSignal(POST.PERSON_CHANGE_HOUSE_CARD.cmdName , {playerCardId = data.id ,cardPosition  =  data.clickHeroTag})
        else
            self:SendSignal(POST.PERSON_CHANGE_HOUSE_CARD.cmdName , {cardPosition  =  data.clickHeroTag})
        end
    end
end

function EntertainHouseMediator:OnRegist()
    regPost(POST.PERSON_CHANGE_HOUSE_CARD)
end

function EntertainHouseMediator:OnUnRegist()
    unregPost(POST.PERSON_CHANGE_HOUSE_CARD)
end

return EntertainHouseMediator



