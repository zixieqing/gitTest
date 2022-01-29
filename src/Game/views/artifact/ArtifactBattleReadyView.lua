--[[
神器界面战斗接口战斗准备界面
@params BattleReadyConstructorStruct 创建战斗选择界面的数据结构
--]]

local ArtifactBattleReadyView = class('ArtifactBattleReadyView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.artifact.ArtifactBattleReadyView'
    node:setName('ArtifactBattleReadyView')
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  -- 普通模式
    UNIVERSAL_TYPE = 2 -- 万能门票道具消耗
}
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function ArtifactBattleReadyView:ctor( ... )
    local args = unpack({...}) or {}

    self.selectedCenterIdx = nil

    self.battleType = checkint(args.battleType or 1)
    self.stageId = checkint(args.stageId)
    self.star = checkint(args.star)
    self.questBattleType = args.questBattleType

    self.selectedTeamIdx = nil
    if nil ~= args.teamIdx and 0 ~= args.teamIdx then
        self.selectedTeamIdx = args.teamIdx
    end

    self.equipedMagicFoodId = nil
    if nil ~= args.equipedMagicFoodId and 0 ~= args.equipedMagicFoodId then
        self.equipedMagicFoodId = args.equipedMagicFoodId
    end

    self.enterBattleRequestCommand = args.enterBattleRequestCommand
    self.enterBattleRequestData = args.enterBattleRequestData
    self.exitBattleRequestCommand = args.exitBattleRequestCommand
    self.exitBattleRequestData = args.exitBattleRequestData
    self.enterBattleResponseSignal = args.enterBattleResponseSignal
    self.exitBattleResponseSignal = args.exitBattleResponseSignal

    self.fromMediatorName = args.fromMediatorName
    self.toMediatorName = args.toMediatorName

    -- 初始化管理器
    self.enterBattleMediator = AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator')
    if not self.enterBattleMediator then
        self.enterBattleMediator = require('Game.mediator.EnterBattleMediator').new({battleReadyView = self})
        AppFacade.GetInstance():RegistMediator(self.enterBattleMediator)
    end

    self:InitUI()
end
function ArtifactBattleReadyView:destory()
    AppFacade.GetInstance():UnRegsitMediator('EnterBattleMediator')
    AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
--[[
init ui
--]]
function ArtifactBattleReadyView:InitUI()
    local eaterLayer = display.newLayer(display.cx, display.cy, {enable = true, size = display.size, color = '#000000', ap = cc.p(0.5, 0.5)})
    eaterLayer:setOpacity(0.7 * 255)
    self:addChild(eaterLayer, 1)
    -- 返回按钮
    local closeBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"),
                                              cb = function (sender)
                                                  -- 发信号 关闭
                                                  sender:setEnabled(false)
                                                  PlayAudioByClickClose()
                                                  self:destory()
                                              end})
    display.commonUIParams(closeBtn, {po = cc.p(
            display.SAFE_L + closeBtn:getContentSize().width * 0.5 + 30,
            display.height - 18 - closeBtn:getContentSize().height * 0.5
    )})
    closeBtn:setName('BTN_CLOSE')
    self:addChild(closeBtn, 20)
    self.closeBtn = closeBtn
    local centerBgSize = cc.size(630, 185)
    local belongsBgFrameSize = cc.size(375, 215)
    local cardHeadScale = 0.625
    if 1 == self.battleType or 3 == self.battleType then
        centerBgSize = cc.size(830, 206)
        cardHeadScale = 0.85
    end

    -- center bg
    local centerBg = display.newImageView(_res('ui/common/maps_fight_bg_information.png'), display.cx, display.height * 0.7,
            {scale9 = true, size = centerBgSize, enable = true, animate = false})
    self:addChild(centerBg, 5)

    -- player skill info
    local belongsBgFrame = display.newImageView(_res('ui/common/maps_fight_bg_information.png'),
            centerBg:getPositionX() - centerBgSize.width * 0.5 + belongsBgFrameSize.width * 0.5,
            centerBg:getPositionY() - centerBgSize.height * 0.5 - 80 - belongsBgFrameSize.height * 0.5,
            {scale9 = true, size = belongsBgFrameSize})
    belongsBgFrame:setName('belongsBgFrame')
    self:addChild(belongsBgFrame, 5)

    -- hint label
    local hintLabel = display.newLabel(0, 0,
            { w = 330 , text = __('点击技能图标更改主角技'), fontSize = 20, color = '#c8b3af'})
    display.commonUIParams(hintLabel, {po = cc.p(belongsBgFrameSize.width * 0.5, display.getLabelContentSize(hintLabel).height * 0.5 + 2)})
    belongsBgFrame:addChild(hintLabel)

    -- battle btn
    local battleBtn = require('common.CommonBattleButton').new({
        pattern = 1,
        clickCallback = function()
            local chooseQuestTypeView = require("Game.views.artifact.ArtifactQuestChooseTypeView").new({questId = self.stageId , callfunc = handler(self, self.EnterBattle)})
            uiMgr:GetCurrentScene():AddDialog(chooseQuestTypeView)
            chooseQuestTypeView:setPosition(display.center)
        end
    })
    battleBtn:setName('BattleBTN')
    display.commonUIParams(battleBtn, {po = cc.p(
            centerBg:getPositionX() + centerBgSize.width * 0.5 - battleBtn:getContentSize().width * 0.5,
            belongsBgFrame:getPositionY()
    )})
    self:addChild(battleBtn, 5)

    -- 消耗体力
    --local costHpLabel, costHpIcon, costHpTime = nil, nil, nil
    --local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
    --if self.stageId and stageConf then
    --    costHpLabel = display.newLabel(0, 0,
    --            fontWithColor(9, {text = __('消耗碎片进入战斗')}))
    --    self:addChild(costHpLabel, 5)
    --end
    local ticketsSize = cc.size(450, 80)
    local ticketLayout = display.newLayer(display.width , display.height -55  , {
        ap = display.RIGHT_CENTER ,  size = ticketsSize
    })
    self:addChild(ticketLayout,10)

    local commonNode = self:CreateGoodPurchaseNode()
    commonNode:setPosition(ticketsSize.width/4 , ticketsSize.height/2)
    ticketLayout:addChild(commonNode)
    local universalNode = self:CreateGoodPurchaseNode()
    universalNode:setPosition(ticketsSize.width*3/4 , ticketsSize.height/2)
    ticketLayout:addChild(universalNode)


    self.viewData = {
        centerBg = centerBg,
        belongsBgFrame = belongsBgFrame,
        hintLabel = hintLabel,
        cardHeadScale = cardHeadScale,
        battleBtn = battleBtn,
        --costHpLabel = costHpLabel,
        universalNode = universalNode ,
        commonNode = commonNode 
    }
    self:RefreshGoodPurchaseNode()
    self.centerContentData = {
        {name = __('主角技'), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)},
    }
    
    self:InitStageInfo()
    belongsBgFrame:setVisible(0 < #self.centerContentData)
    self:InitFormationContent()
    self:InitBelongings()

    self:RefreshCenterContent(self.selectedCenterIdx or 1)
end
--[[
    刷新门票显示
--]]
function ArtifactBattleReadyView:RefreshGoodPurchaseNode()
    local  viewData = self.viewData
    local  commonNode = viewData.commonNode
    local  universalNode = viewData.universalNode

    local questConf =  CommonUtils.GetQuestConf(checkint(self.stageId))
    local commonData =questConf.consumeGoods
    if next(commonData)  then
        local cardFragmentId = commonData[1].goodsId
        local universalId  = checkint(questConf.consumeTicket) > 0 and checkint(questConf.consumeTicket)  or DIAMOND_ID
        local cardFragmentNum  =  CommonUtils.GetCacheProductNum(cardFragmentId)
        local universalNum =CommonUtils.GetCacheProductNum(universalId)
        commonNode.goodNode:RefreshSelf({goodsId = cardFragmentId})
        universalNode.goodNode:RefreshSelf({goodsId = universalId})
        display.commonLabelParams(commonNode.amountLabel , {text = cardFragmentNum })
        display.commonLabelParams(universalNode.amountLabel , {text = universalNum })
        display.commonUIParams(commonNode.touchBg , {cb = function()
             uiMgr:AddDialog("common.GainPopup" , {goodsId = cardFragmentId })
        end})
        display.commonUIParams(universalNode.touchBg , {cb = function()
            uiMgr:AddDialog("common.GainPopup" , {goodsId = universalId })
        end})
    end
end
function ArtifactBattleReadyView:CreateGoodPurchaseNode()
    local DELTAX = 20
    local size = cc.size(190, 80)
    local view = display.newLayer(0,0,{
        ap = display.CENTER ,
        size = size,

    })
    local touchBg = display.newLayer(0, 0, {
        color = cc.c4b(200,200,200,0), size = size, enable = true
    })
    view:addChild(touchBg,2)
    local bg = display.newImageView(_res('ui/home/nmain/common_btn_huobi.png'), DELTAX, size.height * 0.5)
    display.commonUIParams(bg, {ap = display.LEFT_CENTER})
    view:addChild(bg)

    local amountLabel = display.newLabel(36 + DELTAX, size.height * 0.5,
            {ttf = true, font = TTF_GAME_FONT, text = "", fontSize = 21, color = '#ffffff'})
    display.commonUIParams(amountLabel, {ap = display.LEFT_CENTER})
    view:addChild(amountLabel, 6)
    local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID })
    goodNode:setAnchorPoint(display.LEFT_CENTER)
    goodNode:setPosition(cc.p(0 ,size.height/2))
    goodNode:setScale(0.5)
    touchBg:addChild(goodNode)
    view.touchBg = touchBg
    view.bg = bg
    view.goodNode = goodNode
    view.amountLabel = amountLabel
    return  view
end


--[[
初始化编队信息
--]]
function ArtifactBattleReadyView:InitFormationContent()
    self:InitTeamFormationPanel()
end
--[[
初始化编队信息以外的携带物品信息
--]]
function ArtifactBattleReadyView:InitBelongings()
    local bgSize = self.viewData.belongsBgFrame:getContentSize()
    local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

    -- 创建标签按钮
    self.viewData.centerContentTabBtns = {}
    for i,v in ipairs(self.centerContentData) do
        -- 创建标签按钮
        local tabBtn = display.newToggleView(0, 0, {n = _res('ui/common/maps_fight_btn_tab_default.png'), s = _res('ui/common/maps_fight_btn_tab_select.png') , scale9 = true , size = cc.size(200, 60) })
        display.commonUIParams(tabBtn, {po = cc.p(
                centerBgPos.x - bgSize.width * 0.5 + tabBtn:getContentSize().width * 0.5 + (i - 1) * (5 + tabBtn:getContentSize().width),
                centerBgPos.y + bgSize.height * 0.5 + tabBtn:getContentSize().height * 0.5 + 5)})
        self:addChild(tabBtn, 20)
        tabBtn:setTag(v.tag)
        table.insert(self.viewData.centerContentTabBtns, tabBtn)
        tabBtn:setOnClickScriptHandler(handler(self, self.ChangeCenterContentBtnCallback))

        local tabBtnLabel = display.newLabel(utils.getLocalCenter(tabBtn).x, utils.getLocalCenter(tabBtn).y,
                fontWithColor(12,{text = v.name , w= 180 , hAlign = display.TAC}))
        tabBtn:addChild(tabBtnLabel)
        tabBtnLabel:setTag(3)

        if v.initHandler then
            v.initHandler()
        end
    end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- player skill control begin --
---------------------------------------------------
--[[
初始化主角技选择
--]]
function ArtifactBattleReadyView:InitPlayerSkillPanel()
    local bgSize = self.viewData.belongsBgFrame:getContentSize()
    local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

    -- 可选槽
    local canSelectSlotInfo = {
        {descr = __('技能1'), roundIconPath = 'ui/map/team_lead_skill_bg_1.png'},
        {descr = __('技能2'), roundIconPath = 'ui/map/team_lead_skill_bg_2.png'},
    }

    self.equipedPlayerSkills = {}
    if gameMgr:GetUserInfo().skill and type(gameMgr:GetUserInfo().skill) == 'table' then
        for i,v in ipairs(gameMgr:GetUserInfo().skill) do
            self.equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
        end
    end

    self.allSkills = self:convertPlayerSkillData(gameMgr:GetUserInfo().allSkill)

    local canSlotAmount = table.nums(canSelectSlotInfo)
    local cellWidth = 160
    local skillIconScale = 1
    local skillInfo = nil
    self.viewData.playerSkillLabelBg = {}
    self.viewData.playerSkillIcons = {}
    self.viewData.equipSkillBtns = {}
    for i,v in ipairs(canSelectSlotInfo) do
        local labelBg = display.newNSprite(_res('ui/common/team_lead_skill_word_bg.png'), 0, 0)
        display.commonUIParams(labelBg, {po = cc.p(
                centerBgPos.x + ((i - 1) - (canSlotAmount - 1) * 0.5) * cellWidth,
                centerBgPos.y + bgSize.height * 0.5 - 25)})
        self:addChild(labelBg, 10)
        table.insert(self.viewData.playerSkillLabelBg, labelBg)

        local label = display.newLabel(utils.getLocalCenter(labelBg).x, utils.getLocalCenter(labelBg).y,
                fontWithColor(12,{text = v.descr}))
        labelBg:addChild(label)

        local skillIconPos = cc.p(labelBg:getPositionX(), labelBg:getPositionY() - labelBg:getContentSize().height * 0.5 - 75)

        skillInfo = self.equipedPlayerSkills[tostring(i)]
        local skillIcon = require('common.PlayerSkillNode').new({id = nil ~= skillInfo and skillInfo.skillId or 0})
        skillIcon:setScale(skillIconScale)
        display.commonUIParams(skillIcon, {cb = handler(self, self.ChangePlayerSkillCallback), po = cc.p(
                skillIconPos.x,
                skillIconPos.y)})
        skillIcon:setTag(i)
        self:addChild(skillIcon, 10)
        skillIcon:setVisible(false)
        table.insert(self.viewData.playerSkillIcons, skillIcon)

        local equipSkillBtn = display.newButton(0, 0, {n = _res('ui/common/common_frame_goods_1.png')})
        display.commonUIParams(equipSkillBtn, {cb = handler(self, self.ChangePlayerSkillCallback), po = cc.p(
                skillIconPos.x,
                skillIconPos.y)})
        equipSkillBtn:setTag(i)
        self:addChild(equipSkillBtn, 10)

        local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), utils.getLocalCenter(equipSkillBtn).x, utils.getLocalCenter(equipSkillBtn).y)
        equipSkillBtn:addChild(addIcon)

        table.insert(self.viewData.equipSkillBtns, equipSkillBtn)
    end
end
--[[
显示或隐藏主角技信息panel
@params visible bool 是否显示
--]]
function ArtifactBattleReadyView:ShowPlayerSkillPanel(visible)
    if true == visible then
        for i,v in ipairs(self.viewData.playerSkillLabelBg) do
            v:setVisible(true)
        end
        self.viewData.hintLabel:setString(__('点击技能图标更改主角技'))
        self.viewData.hintLabel:setVisible(true)

        self:RefreshPlayerSkillPanel()
    else
        for i,v in ipairs(self.viewData.playerSkillLabelBg) do
            v:setVisible(false)
        end
        for i,v in ipairs(self.viewData.equipSkillBtns) do
            v:setVisible(false)
        end
        for i,v in ipairs(self.viewData.playerSkillIcons) do
            v:setVisible(false)
        end
    end
end
--[[
换技能按钮回调
--]]
function ArtifactBattleReadyView:ChangePlayerSkillCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_PLAYER_SKILL", {
        allSkills = self.allSkills.activeSkill,
        equipedPlayerSkills = self.equipedPlayerSkills,
        slotIndex = tag,
        changeEndCallback = function (responseData)

            -- 刷新本地主角技数据
            gameMgr:UpdatePlayer({skill = responseData.skill})

            self.equipedPlayerSkills = {}
            for i,v in ipairs(gameMgr:GetUserInfo().skill) do
                self.equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
            end
            self:RefreshPlayerSkillPanel()
        end
    })
end
--[[
刷新主角技装备情况
--]]
function ArtifactBattleReadyView:RefreshPlayerSkillPanel()
    local skillId = 0
    if gameMgr:GetUserInfo().skill and type(gameMgr:GetUserInfo().skill) == 'table' then
        for i, v in ipairs(gameMgr:GetUserInfo().skill) do
            skillId = checkint(v)
            if 0 == skillId then
                -- 当前未装备
                self.viewData.equipSkillBtns[i]:setVisible(true)
                self.viewData.playerSkillIcons[i]:setVisible(false)
            else
                self.viewData.equipSkillBtns[i]:setVisible(false)
                self.viewData.playerSkillIcons[i]:setVisible(true)
                self.viewData.playerSkillIcons[i]:RefreshUI({id = skillId})
            end
        end
    end
end
---------------------------------------------------
-- player skill control end --
---------------------------------------------------

---------------------------------------------------
-- formation control begin --
---------------------------------------------------
--[[
初始化编队信息
--]]
function ArtifactBattleReadyView:InitTeamFormationPanel()
    local bgSize = self.viewData.centerBg:getContentSize()
    local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

    -- 队伍序号
    local teamFormationLabelBg = display.newImageView(_res('ui/common/maps_fight_bg_title_s.png'), 0, 0)
    display.commonUIParams(teamFormationLabelBg, {po = cc.p(
            centerBgPos.x - bgSize.width * 0.5 + 5 + teamFormationLabelBg:getContentSize().width * 0.5,
            centerBgPos.y + bgSize.height * 0.5 - 5)})
    self:addChild(teamFormationLabelBg, 10)

    local teamFormationLabel = display.newLabel(teamFormationLabelBg:getContentSize().width * 0.4, teamFormationLabelBg:getContentSize().height * 0.5,
            fontWithColor(3,{text = string.format(__('出战队伍%d'), 0)}))
    teamFormationLabelBg:addChild(teamFormationLabel)

    -- 队伍战斗力
    local teamBattlePointBg = display.newImageView(_res('ui/common/maps_fight_bg_sword1.png'), 0, 0)
    display.commonUIParams(teamBattlePointBg, {po = cc.p(
            centerBgPos.x + bgSize.width * 0.5 + 10 - teamBattlePointBg:getContentSize().width * 0.5,
            centerBgPos.y + bgSize.height * 0.5)})
    self:addChild(teamBattlePointBg, 10)

    local teamBattlePointLabel = display.newLabel(teamBattlePointBg:getContentSize().width * 0.55, 5,
            fontWithColor(9,{text = string.format(__('队伍灵力:%d'), 0), ap = cc.p(0.5, 0)}))
    teamBattlePointBg:addChild(teamBattlePointLabel)

    -- 调整队伍
    local changeTeamFormationBtn = display.newButton(0, 0, {scale9 = true , ap = display.RIGHT_CENTER ,  n = _res('ui/common/common_btn_orange.png')})
    display.commonUIParams(changeTeamFormationBtn, {paddingW = 10 ,  po = cc.p(
            centerBgPos.x + bgSize.width * 0.5 - changeTeamFormationBtn:getContentSize().width * 0.5 + 50 ,
            centerBgPos.y - bgSize.height * 0.5 - 15 - changeTeamFormationBtn:getContentSize().height * 0.5 ),
                                                    cb = function (sender)
                                                        PlayAudioByClickNormal()
                                                        AppFacade.GetInstance():DispatchObservers("SHOW_TEAM_FORMATION",self.selectedTeamIdx)
                                                    end
    })
    display.commonLabelParams(changeTeamFormationBtn, fontWithColor(14,{text = __('调整队伍') ,paddingW  = 10 }))
    self:addChild(changeTeamFormationBtn, 10)

    -- 前后按钮
    local preBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
    preBtn:setScaleX(-1)
    display.commonUIParams(preBtn, {po = cc.p(
            centerBgPos.x - bgSize.width * 0.5 + preBtn:getContentSize().width * 0.5 - 60,
            centerBgPos.y)})
    self:addChild(preBtn, 20)
    preBtn:setTag(1001)

    local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
    display.commonUIParams(nextBtn, {po = cc.p(
            centerBgPos.x + bgSize.width * 0.5 - nextBtn:getContentSize().width * 0.5 + 60,
            centerBgPos.y)})
    self:addChild(nextBtn, 20)
    nextBtn:setTag(1002)

    self.viewData.teamFormationLabelBg = teamFormationLabelBg
    self.viewData.teamBattlePointBg = teamBattlePointBg
    self.viewData.teamFormationLabel = teamFormationLabel
    self.viewData.teamBattlePointLabel = teamBattlePointLabel
    self.viewData.changeTeamFormationBtn = changeTeamFormationBtn
    self.viewData.preTeamBtn = preBtn
    self.viewData.nextTeamBtn = nextBtn
    self.viewData.teamTabs = {}
    self.viewData.cardHeadNodes = {}

    self:RefreshTeamFormation(gameMgr:GetUserInfo().teamFormation)
end
--[[
刷新中间队伍区域
@params data table 队伍信息
--]]
function ArtifactBattleReadyView:RefreshTeamFormation(data)
    ------------ 处理编队数据 ------------
    local teamData = {}
    for tNo, tData in ipairs(data) do
        teamData[tNo] = {teamId = tData.teamId, members = {}}
        for no, card in ipairs(tData.cards) do
            if card.id then
                local id = checkint(card.id)
                local cardData = gameMgr:GetCardDataById(id)
                table.insert(teamData[tNo].members, {id = id, isLeader = id == checkint(tData.captainId)})
            end
        end
    end
    self.teamData = teamData

    self:RefreshTeamTabs()
end
--[[
刷新队伍周围信息
--]]
function ArtifactBattleReadyView:RefreshTeamTabs()
    if table.nums(self.teamData) ~= table.nums(self.viewData.teamTabs) then
        for i,v in ipairs(self.viewData.teamTabs) do
            v:removeFromParent()
        end

        self.viewData.teamTabs = {}

        for i,v in ipairs(self.teamData) do
            local teamCircle = display.newNSprite(_res('ui/common/maps_fight_ico_round_default.png'), 0, 0)
            self:addChild(teamCircle, 5)
            table.insert(self.viewData.teamTabs, teamCircle)
        end

        display.setNodesToNodeOnCenter(self.viewData.centerBg, self.viewData.teamTabs, {spaceW = 5, y = -15})
    end

    self:RefreshTeamSelectedState(self.selectedTeamIdx or 1)
end
--[[
刷新队伍选中状态
--]]
function ArtifactBattleReadyView:RefreshTeamSelectedState(index)
    -- 刷新选中状态
    local preCircle = self.viewData.teamTabs[self.selectedTeamIdx]
    if preCircle then
        preCircle:setTexture(_res('ui/common/maps_fight_ico_round_default.png'))
    end
    local curCircle = self.viewData.teamTabs[index]
    if curCircle then
        curCircle:setTexture(_res('ui/common/maps_fight_ico_round_select.png'))
    end

    if table.nums(self.teamData) <= 1 then
        self.viewData.preTeamBtn:setVisible(false)
        self.viewData.nextTeamBtn:setVisible(false)
    elseif index == 1 then
        self.viewData.preTeamBtn:setVisible(false)
        self.viewData.nextTeamBtn:setVisible(true)
    elseif index == table.nums(self.teamData) then
        self.viewData.preTeamBtn:setVisible(true)
        self.viewData.nextTeamBtn:setVisible(false)
    else
        self.viewData.preTeamBtn:setVisible(true)
        self.viewData.nextTeamBtn:setVisible(true)
    end

    self.selectedTeamIdx = index

    -- 刷新队伍信息
    self.viewData.teamFormationLabel:setString(string.format(__('出战队伍%d'), self.selectedTeamIdx))

    self:RefreshTeamInfo(self.teamData[self.selectedTeamIdx])
end
--[[
刷新队伍信息
@params teamData table 队伍信息
--]]
function ArtifactBattleReadyView:RefreshTeamInfo(teamData)
    -- 刷新头像
    for i,v in ipairs(self.viewData.cardHeadNodes) do
        v:removeFromParent()
    end
    self.viewData.cardHeadNodes = {}

    local bgSize = self.viewData.centerBg:getContentSize()
    local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

    local totalBattlePoint = 0
    local teamMemberMax = 5
    local paddingX = 10
    local cellWidth = (bgSize.width - paddingX * 2) / teamMemberMax
    local scale = self.viewData.cardHeadScale
    for i,v in ipairs(teamData.members) do
        local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = true, showVigourState = false})
        cardHeadNode:setScale(scale)
        cardHeadNode:setPosition(cc.p(
                (centerBgPos.x - bgSize.width * 0.5 + paddingX) + cellWidth * (i - 0.5),
                centerBgPos.y - bgSize.height * 0.5 + cardHeadNode:getContentSize().height * 0.5 * scale + 15))
        self:addChild(cardHeadNode, 15)

        table.insert(self.viewData.cardHeadNodes, cardHeadNode)

        -- 计算战斗力
        totalBattlePoint = totalBattlePoint + cardMgr.GetCardStaticBattlePointById(checkint(v.id))
    end

    -- 刷新战斗力
    self.viewData.teamBattlePointLabel:setString(string.format(__('队伍灵力:%d'), totalBattlePoint))

end
--[[
显示或隐藏编队信息panel
@params visible bool 是否显示
--]]
function ArtifactBattleReadyView:ShowTeamFormationPanel(visible)
    self.viewData.teamFormationLabelBg:setVisible(visible)
    self.viewData.teamBattlePointBg:setVisible(visible)
    self.viewData.changeTeamFormationBtn:setVisible(visible)
    for i,v in ipairs(self.viewData.teamTabs) do
        v:setVisible(visible)
    end
    for i,v in ipairs(self.viewData.cardHeadNodes) do
        v:setVisible(visible)
    end
    if visible then
        self:RefreshTeamSelectedState(self.selectedTeamIdx or 1)
    else
        self.viewData.preTeamBtn:setVisible(visible)
        self.viewData.nextTeamBtn:setVisible(visible)
    end
end
---------------------------------------------------
-- formation control end --
---------------------------------------------------

---------------------------------------------------
-- pet food begin --
---------------------------------------------------
--[[
初始化堕神诱饵
--]]
function ArtifactBattleReadyView:InitMagicFoodPanel()
    local bgSize = self.viewData.belongsBgFrame:getContentSize()
    local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

    -- 选择按钮
    local magicFoodNodeScale = 1
    local equipMagicFoodNode = display.newButton(0, 0, {n = _res('ui/common/common_frame_goods_1.png'), cb = function (sender)
        PlayAudioByClickNormal()
        AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_MAGIC_FOOD", {
            equipedMagicFoodId = self.equipedMagicFoodId,
            equipCallback = handler(self, self.RefreshMagicFoodState)
        })
    end})
    equipMagicFoodNode:setScale(magicFoodNodeScale)
    display.commonUIParams(equipMagicFoodNode, {po = cc.p(centerBgPos.x, centerBgPos.y)})
    self:addChild(equipMagicFoodNode, 15)

    local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), utils.getLocalCenter(equipMagicFoodNode).x, utils.getLocalCenter(equipMagicFoodNode).y)
    equipMagicFoodNode:addChild(addIcon)

    -- 更换按钮
    local changeMagicFoodBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = function (sender)
        PlayAudioByClickNormal()
        AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_MAGIC_FOOD", {
            equipedMagicFoodId = self.equipedMagicFoodId,
            equipCallback = handler(self, self.RefreshMagicFoodState)
        })
    end})
    display.commonUIParams(changeMagicFoodBtn, {po = cc.p(centerBgPos.x, centerBgPos.y - bgSize.height * 0.5 + 10 + changeMagicFoodBtn:getContentSize().height * 0.5)})
    display.commonLabelParams(changeMagicFoodBtn, fontWithColor(14,{text = __('更换诱饵')}))
    self:addChild(changeMagicFoodBtn, 15)

    self.viewData.equipMagicFoodNode = equipMagicFoodNode
    self.viewData.magicFoodNode = nil
    self.viewData.changeMagicFoodBtn = changeMagicFoodBtn

    self:RefreshMagicFoodState(self.equipedMagicFoodId)
end
--[[
刷新诱饵状态
@params magicFoodId int 魔法食物id
--]]
function ArtifactBattleReadyView:RefreshMagicFoodState(magicFoodId)
    if nil == magicFoodId then
        self.viewData.equipMagicFoodNode:setVisible(true)
        self.viewData.changeMagicFoodBtn:setVisible(false)
        if self.viewData.magicFoodNode then
            self.viewData.magicFoodNode:setVisible(false)
        end
    else
        self.viewData.equipMagicFoodNode:setVisible(false)
        self.viewData.changeMagicFoodBtn:setVisible(true)
        if self.viewData.magicFoodNode then
            self.viewData.magicFoodNode:removeFromParent()
            self.viewData.magicFoodNode = nil
        end
        self.viewData.magicFoodNode = require('common.GoodNode').new({id = magicFoodId, showAmount = true, amount = gameMgr:GetAmountByGoodId(magicFoodId)})
        self.viewData.magicFoodNode:setScale(0.75)
        display.commonUIParams(self.viewData.magicFoodNode, {po = cc.p(self.viewData.changeMagicFoodBtn:getPositionX(), self.viewData.changeMagicFoodBtn:getPositionY() + 80)})
        self:addChild(self.viewData.magicFoodNode, 15)
    end

    self.equipedMagicFoodId = magicFoodId
end
--[[
显示或隐藏堕神诱饵信息panel
@params visible bool 是否显示
--]]
function ArtifactBattleReadyView:ShowMagicFoodPanel(visible)
    if visible then
        self:RefreshMagicFoodState(self.equipedMagicFoodId)
        self.viewData.hintLabel:setString(__('点击技能图标更改魔法食物'))
        self.viewData.hintLabel:setVisible(false)
    else
        self.viewData.equipMagicFoodNode:setVisible(false)
        self.viewData.changeMagicFoodBtn:setVisible(false)
        if self.viewData.magicFoodNode then
            self.viewData.magicFoodNode:setVisible(false)
        end
    end
end
---------------------------------------------------
-- pet food end --
---------------------------------------------------

---------------------------------------------------
-- stage info control begin --
---------------------------------------------------
--[[
初始化关卡详情
--]]
function ArtifactBattleReadyView:InitStageInfo()

    local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

    -- 关卡详情底板
    local stageInfoBgSize = cc.size(578, 605)
    local stageInfoBgPos = cc.p(display.SAFE_L + stageInfoBgSize.width * 0.5 + 30, display.height * 0.45)
    local stageInfoBg = display.newImageView(_res('ui/common/maps_fight_bg_information.png'), 0, 0,
            {scale9 = true, size = stageInfoBgSize, enable = true, animate = false})
    display.commonUIParams(stageInfoBg, {po = stageInfoBgPos})
    self:addChild(stageInfoBg, 5)

    -- 分隔线1 关卡信息
    local splitLineStageInfo = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, stageInfoBgSize.height - 70)
    stageInfoBg:addChild(splitLineStageInfo)

    local maxStarLabel = display.newLabel(
            splitLineStageInfo:getPositionX() - splitLineStageInfo:getContentSize().width * 0.5 + 5,
            splitLineStageInfo:getPositionY() + 20,
            {text = __('三星条件'), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
    stageInfoBg:addChild(maxStarLabel)

    -- 天气预报
    local forecastLabel = display.newLabel(
            maxStarLabel:getPositionX(),
            stageInfoBgSize.height * 0.575,
            {text = __('天气情况'), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
    stageInfoBg:addChild(forecastLabel)

    -- 分隔线2 关卡掉落
    local splitLineStageReward = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, 235)
    stageInfoBg:addChild(splitLineStageReward)

    -- 掉落信息
    local rewardLabel = display.newLabel(
            splitLineStageReward:getPositionX() - splitLineStageReward:getContentSize().width * 0.5 + 5,
            splitLineStageReward:getPositionY() + 20,
            {text = __('关卡掉落'), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
    stageInfoBg:addChild(rewardLabel)

    local x = 1

    local commonSweepBtn = display.newButton(0, 0, {n = _res('ui/artifact/sore_btn_saodang_1.png'), scale9 = true  , size = cc.size(230 ,70),  cb = handler(self, self.SweepBtnCallback)})
    display.commonUIParams(commonSweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5 + 30, stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + commonSweepBtn:getContentSize().height * 0.5 + 20)})
    display.commonLabelParams(commonSweepBtn, fontWithColor(14,{text = __('专属挑战券\n扫荡') , reqW = 220, hAlign = display.TAC }))
    commonSweepBtn:setTag(BATTLE_TYPE.COMMON_TYPE)
    self:addChild(commonSweepBtn, 100)


    -- 关卡评论
    local universalSweepBtn = display.newButton(0, 0, {n = _res('ui/artifact/sore_btn_saodang_2.png'), scale9 = true  , size = cc.size(230 ,70),  cb = handler(self, self.SweepBtnCallback)})
    display.commonUIParams(universalSweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5 * (1 + x) + 150, stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + universalSweepBtn:getContentSize().height * 0.5 + 20)})
    display.commonLabelParams(universalSweepBtn, fontWithColor(14,{text = __('万能挑战券\n扫荡'),  reqW = 220, hAlign = display.TAC} ))
    self:addChild(universalSweepBtn, 100)
    universalSweepBtn:setTag(BATTLE_TYPE.UNIVERSAL_TYPE)
    if stageConf then
        local stageTitleStr = stageConf.name
        local bgId = stageConf.backgroundId
        -- 垫上一张背景图
        local bgView = CLayout:create(cc.size(1336,1002))
        local bgPath = string.format('arts/maps/maps_bg_%s', bgId)
        local leftImage = display.newImageView(_res(string.format('%s_01', bgPath)), 0, 0, {ap = display.LEFT_BOTTOM})
        bgView:addChild(leftImage)
        local rightImage = display.newImageView(_res(string.format('%s_02', bgPath)), 1336, 0, {ap = display.RIGHT_BOTTOM})
        bgView:addChild(rightImage)
        display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
        fullScreenFixScale(bgView)
        self:addChild(bgView)

        -- 关卡信息
        local stageTitleBg = display.newNSprite(_res('ui/common/maps_fight_bg_title.png'), 0, 0)
        display.commonUIParams(stageTitleBg, {po = cc.p(
                self.closeBtn:getPositionX() + self.closeBtn:getContentSize().width * 0.5 + stageTitleBg:getContentSize().width * 0.5 + 10,
                self.closeBtn:getPositionY())})
        self:addChild(stageTitleBg, 5)

        local stageTitleLabel = display.newLabel(stageTitleBg:getContentSize().width * 0.4, utils.getLocalCenter(stageTitleBg).y,
                {text = stageTitleStr, fontSize = 28, reqW = 310 ,  color = '#ffffff'})
        stageTitleBg:addChild(stageTitleLabel)
        self.stageTitleText = stageTitleStr
            -- 三星条件
        local itor = 1
        local artifactQuestGrade = artifactMgr:GetArtifactQuestByQuestId(self.stageId)
        local gradeConditionIds = artifactQuestGrade.gradeConditionIds or {}
        for k,v in pairs(stageConf.allClean) do
            local clearData = CommonUtils.GetConfig('quest', 'starCondition', checkint(k))
            local descr = CommonUtils.GetFixedClearDesc(clearData, v)
            local pass = false
            local cleanLabelColor = '#ffffff'
            local data = {}
            for index, grade in pairs(gradeConditionIds) do
                if checkint(grade) == checkint(k) and checkint(k)  ~= 0  then
                    pass = true
                    break
                end
            end
            if pass then
                cleanLabelColor = '#ffd52c'
                data[#data+1] = fontWithColor('10',  { color = '#ffd52c',text = descr  })
                data[#data+1] = fontWithColor('10',  { color = '#ffffff',text = __('（已通过）')  })
            else
                data[#data+1] = fontWithColor('10',  { color = '#ffffff',text = descr  })
                data[#data+1] = fontWithColor('10',  { text = __('（未通过）')  })
            end
            local  cleanLabel = display.newRichLabel(maxStarLabel:getPositionX(), splitLineStageInfo:getPositionY() - 30 - (itor - 1) * 35, {
                c = data , r = true  , ap = display.LEFT_CENTER
            })
            CommonUtils.SetNodeScale(cleanLabel ,{width =  540 })
            stageInfoBg:addChild(cleanLabel)
            itor = itor + 1
        end

        -- 天气情况
        local weatherId = nil
        local weatherIconScale = 0.4
        for i,v in ipairs(stageConf.weatherId) do
            weatherId = checkint(v)
            local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
            local weatherBtn = display.newButton(0, 0, {
                n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
                cb = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
                end
            })
            weatherBtn:setScale(weatherIconScale)
            local pos = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(
                    forecastLabel:getPositionX() + display.getLabelContentSize(forecastLabel).width + 10 + weatherBtn:getContentSize().width * weatherIconScale * 0.5 + (((weatherBtn:getContentSize().width * weatherIconScale) + 5) * (i - 1)),
                    forecastLabel:getPositionY() + 2)))
            display.commonUIParams(weatherBtn, {po = pos})
            self:addChild(weatherBtn, 15)
        end

        -- 奖励金币和经验
        local rewardIconPerLine = 5
        local paddingX = -5
        local cellWidth = 105
        local goodNodeScale = 0.9
        local _p = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(splitLineStageReward:getPositionX(), splitLineStageReward:getPositionY())))

        -- 处理奖励信息 有的关卡存在拆分的奖励信息

        local stageRewardsInfo = {}
        if stageConf.rewards and 0 < #stageConf.rewards then
            -- 插入通常奖励
            --#stageConf.rewards
            --for i,v in ipairs(stageConf.rewards) do
            --    table.insert(stageRewardsInfo, v)
            --end
            stageRewardsInfo[#stageRewardsInfo+1] = stageConf.rewards[1]
        end

        for i,v in ipairs(stageRewardsInfo) do
            if i <= 5 then
                local function callBack(sender)
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
                end
                local goodNode = require('common.GoodNode').new({id = checkint(v.goodsId), showAmount = false, callBack = callBack})
                goodNode:setScale(goodNodeScale)
                display.commonUIParams(goodNode, {po = cc.p(
                        stageInfoBgPos.x + paddingX + (cellWidth * (((i - 1) % rewardIconPerLine + 1) - (rewardIconPerLine + 1) * 0.5)),
                        _p.y - 15 - goodNode:getContentSize().height * (0.5 + math.ceil(i / rewardIconPerLine) - 1) * goodNodeScale)})
                self:addChild(goodNode, 15)
            end
        end
    end
    -- 移动中间块位置
    self.viewData.centerBg:setPosition(cc.p(
            display.SAFE_R - self.viewData.centerBg:getContentSize().width * 0.5 - 50,
            stageInfoBgPos.y + stageInfoBgSize.height * 0.5 - self.viewData.centerBg:getContentSize().height * 0.5)
    )
    -- 移动主角技模块
    self.viewData.belongsBgFrame:setPosition(
            self.viewData.centerBg:getPositionX() - self.viewData.centerBg:getContentSize().width * 0.5 + self.viewData.belongsBgFrame:getContentSize().width * 0.5,
            stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + self.viewData.belongsBgFrame:getContentSize().height * 0.5
    )
    display.commonUIParams(self.viewData.battleBtn, {po = cc.p(
            self.viewData.centerBg:getPositionX() + self.viewData.centerBg:getContentSize().width * 0.5 - self.viewData.battleBtn:getContentSize().width * 0.5,
            self.viewData.belongsBgFrame:getPositionY() + 0)})
end
--[[
扫荡按钮回调
--]]
function ArtifactBattleReadyView:SweepBtnCallback(sender)
    PlayAudioByClickNormal()
    ---@type ArtifactManager
    local tag = sender:getTag()
    local star = checkint(artifactMgr:GetArtifactQuestStarByQuestId(self.stageId))
    local sweepView = require("Game.views.artifact.ArtifactQuestSweepView").new({
        questId = self.stageId  ,
        questType = tag ,
        star = star
    })
    sweepView:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(sweepView)
end
---------------------------------------------------
-- stage info control end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
上标签按钮点击回调
--]]
function ArtifactBattleReadyView:ChangeCenterContentBtnCallback(sender)
    PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
    local tag = sender:getTag()
    self:RefreshCenterContent(tag)
end
--[[
刷新整个中间框架
@params index int 序号
--]]
function ArtifactBattleReadyView:RefreshCenterContent(index)
    local curCenterTabBtn = self.viewData.centerContentTabBtns[index]
    if curCenterTabBtn then
        curCenterTabBtn:setChecked(true)
        display.commonLabelParams(curCenterTabBtn:getChildByTag(3), {color = fontWithColor('13').color})
    end

    if self.selectedCenterIdx == index then return end

    local preCenterTabBtn = self.viewData.centerContentTabBtns[self.selectedCenterIdx]
    if preCenterTabBtn then
        preCenterTabBtn:setChecked(false)
        display.commonLabelParams(preCenterTabBtn:getChildByTag(3), {color = fontWithColor('12').color})
    end

    local curCenterData = self.centerContentData[index]
    if curCenterData and curCenterData.showHandler then
        curCenterData.showHandler(true)
    end

    for i,v in ipairs(self.centerContentData) do
        if (index ~= i) and v.showHandler then
            v.showHandler(false)
        end
    end

    self.selectedCenterIdx = index
end
--[[
阵容前后按钮点击回调
1001 前
1002 后
--]]
function ArtifactBattleReadyView:ChangeTeamFormationBtnCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if 1001 == tag then
        self:RefreshTeamSelectedState(math.max(1, self.selectedTeamIdx - 1))
    elseif 1002 == tag then
        self:RefreshTeamSelectedState(math.min(table.nums(self.teamData), self.selectedTeamIdx + 1))
    end
end
--[[
进入战斗
--]]
function ArtifactBattleReadyView:EnterBattle(sender)
    ------------ 本地逻辑判断 ------------
    -- 是否可以进入该关卡
    local tag = sender:getTag()
    self.enterBattleRequestData.questType = tag
    self.exitBattleRequestData.questType  =  tag
    local canEnter, errLog = CommonUtils.CanEnterStageIdByStageId(self.stageId)
    if not canEnter then
        uiMgr:ShowInformationTips(errLog)
        return
    end
    ------------ 本地逻辑判断 ------------
    local selectedTeamData = self.teamData[self.selectedTeamIdx]

    if table.nums(selectedTeamData.members) == 0 then
        -- TODO 跳转编队
        local CommonTip  = require( 'common.CommonTip' ).new({text = __('队伍不能为空'),isOnlyOK = true})
        CommonTip:setPosition(display.center)
        AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
    else
        local serverCommand = BattleNetworkCommandStruct.New(
                self.enterBattleRequestCommand,
                self.enterBattleRequestData,
                self.enterBattleResponseSignal,
                self.exitBattleRequestCommand,
                self.exitBattleRequestData,
                self.exitBattleResponseSignal,
                nil,
                nil,
                nil
        )
        local fromToStruct = BattleMediatorsConnectStruct.New(
                self.fromMediatorName,
                self.toMediatorName
        )

        local battleConstructor = require('battleEntry.BattleConstructor').new()
        local canBattle, waringText = battleConstructor:CanEnterBattleByTeamId(self.selectedTeamIdx)
        if not canBattle then
            if nil ~= waringText then
                uiMgr:ShowInformationTips(waringText)
            end
            return
        end
        battleConstructor:InitByNormalStageIdAndTeamId(self.stageId, self.selectedTeamIdx, serverCommand, fromToStruct)
        GuideUtils.DispatchStepEvent()
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

    end
end
--[[
刷新剩余挑战次数
--]]
function ArtifactBattleReadyView:RefreshChallengeTime()
    if nil ~= self.challengeTimeLabel then
        local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

        self.challengeTimeLabel:setString(string.format(
                '%d/%d',
                checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]),
                checkint(stageConf.challengeTime)
        ))
    end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
转换激活的主角技数据结构
@params allSkill 所有激活的主角技数据
@return result table 转换后的数据结构
--]]
function ArtifactBattleReadyView:convertPlayerSkillData(allSkill)
    local skillId = 0
    local skillConf = nil

    local result = {
        activeSkill = {},
        passiveSkill = {}
    }

    for i,v in ipairs(allSkill) do
        skillId = checkint(v)
        skillConf = CommonUtils.GetSkillConf(skillId)
        local skillInfo = {skillId = skillId}
        if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
            -- 被动技能
            table.insert(result.passiveSkill, skillInfo)
        else
            -- 主动技能
            table.insert(result.activeSkill, skillInfo)
        end
    end

    return result
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx begin --
---------------------------------------------------
function ArtifactBattleReadyView:onEnter()
    AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , mvc.Observer.new(self.RefreshGoodPurchaseNode, self) )
end
function ArtifactBattleReadyView:onExit()
    AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , self)
end

return ArtifactBattleReadyView
