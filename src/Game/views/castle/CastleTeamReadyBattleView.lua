---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/3/1 4:28 PM
---
---@class CastleTeamReadyBattleView
local CastleTeamReadyBattleView = class('CastleTeamReadyBattleView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.castle.CastleTeamReadyBattleView'
    node:setName('CastleTeamReadyBattleView')
    node:enableNodeEvents()
    return node
end)
---@type SpringActivityConfigParser
local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser')
local GoodNode = require('common.GoodNode')
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
    CASTLE_MAP_BATTLE_BTN_DEFAULT    = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_btn_default.png'),
    COMMON_BTN_BACK                  = app.activityMgr:CastleResEx('ui/common/common_btn_back.png'),
    CASTLE_MAP_ICO_1                 = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_ico_1.png'),
    CASTLE_MAP_LABEL_TITLE           = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_label_title.png'),
    CASTLE_BG_COMMON_BOARD           = app.activityMgr:CastleResEx('ui/castle/common/castle_bg_common_board.png'),
    CASTLE_MAP_ICO_4                 = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_ico_4.png'),
    CASTLE_MAP_BATTLE_BG_BOSS        = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_bg_boss.png'),
    COMMON_BTN_ORANGE_DISABLE        = app.activityMgr:CastleResEx('ui/common/common_btn_orange_disable.png'),
    COMMON_TITLE_3                   = app.activityMgr:CastleResEx('ui/common/common_title_3.png'),
    CASTLE_MAP_BATTLE_LINE_2         = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_line_2.png'),
    CASTLE_MAP_BATTLE_LINE_3         = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_line_3.png'),
    CASTLE_MAP_BATTLE_BG_NORMAL      = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_bg_normal.png'),
    CASTLE_MAP_BATTLE_FRAME_SELECTED = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_frame_selected.png'),
    CASTLE_MAP_BATTLE_LINE_1         = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_line_1.png'),
    CASTLE_MAP_BATTLE_BAR            = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_bar.png'),
    CASTLE_MAP_BATTLE_ICO_STAR       = app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_battle_ico_star.png'),
}

function CastleTeamReadyBattleView:ctor(params )
    self:InitUI()
end

function CastleTeamReadyBattleView:InitUI()

    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    self:addChild(view)

    local swallowView = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size , enable = true , color = cc.c4b(0,0,0,175)
    } )
    view:addChild(swallowView)

    local moduleInfoLayout = newLayer(666, 438,
                                      { ap = display.CENTER, size = cc.size(915, 566) })
    moduleInfoLayout:setPosition(display.cx + -1, display.cy + 63)
    view:addChild(moduleInfoLayout)

    local infoBgImage = newImageView(RES_DICT.CASTLE_BG_COMMON_BOARD, 460, 283,
                                     { ap = display.CENTER, tag = 801, enable = true , size = cc.size(934, 584) ,scale9 = true ,capInsets = cc.rect(120, 120, 30, 30)})
    moduleInfoLayout:addChild(infoBgImage)

    local lineTwo = newNSprite(RES_DICT.CASTLE_MAP_BATTLE_LINE_2, 271, 120,
                               { ap = display.CENTER, tag = 805 })
    lineTwo:setScale(1, 1)
    moduleInfoLayout:addChild(lineTwo)

    local moduleName = newLabel(271, 144+5,
                                fontWithColor(14 ,{ap = display.CENTER, color = '#ffffff', text = "", fontSize = 40, tag = 809 }))
    moduleInfoLayout:addChild(moduleName)
    moduleName:setCascadeOpacityEnabled(true)

    local moduleDecr = newLabel(271, 102+7,
                                { hAlign = display.TAC,  ap = display.CENTER_TOP, text = "", fontSize = 24 , color = "#ffd3a7", tag = 810  ,w = 400 })
    moduleInfoLayout:addChild(moduleDecr)
    moduleInfoLayout:setOpacity(0)
    swallowView:setOpacity(0)
    moduleDecr:setCascadeOpacityEnabled(true)
    self.viewData = {

        view                    = view,
        moduleInfoLayout        = moduleInfoLayout,
        swallowView             = swallowView,
        infoBgImage             = infoBgImage,
        lineTwo                 = lineTwo,
        moduleName              = moduleName,
        moduleDecr              = moduleDecr,
    }
end

function CastleTeamReadyBattleView:CreateCommonView()
    local commonModule = newLayer(0, 0,
                                  { ap = display.LEFT_BOTTOM, size = cc.size(915, 566) })
    self.viewData.moduleInfoLayout:addChild(commonModule)

    local commonModleImage = newNSprite(RES_DICT.CASTLE_MAP_ICO_1, 257, 168+20,
                                        { ap = display.CENTER_BOTTOM, tag = 820 })
    commonModleImage:setScale(1, 1)
    commonModule:addChild(commonModleImage)

    local commonLayout = newLayer(537, 43,
                                  { ap = display.LEFT_BOTTOM, size = cc.size(334, 504)})
    commonModule:addChild(commonLayout)

    local normalBgImage = newNSprite(RES_DICT.CASTLE_MAP_BATTLE_BG_NORMAL, 0, 0,
                                     { ap = display.LEFT_BOTTOM, tag = 802 })
    normalBgImage:setScale(1, 1)
    commonLayout:addChild(normalBgImage)

    local recommendLevel = newLabel(167, -20,
                                    { ap = display.CENTER, color = '#ffd3a7', text = "", fontSize = 20, tag = 821 })
    commonLayout:addChild(recommendLevel)

    local fourTable = {
        {name = app.activityMgr:GetCastleText(__('??????')) , recommendName = app.activityMgr:GetCastleText(__('??????(??????)')) , tag = 1},
        {name = app.activityMgr:GetCastleText(__('??????')) , recommendName = app.activityMgr:GetCastleText(__('??????(??????)')) , tag = 2},
        {name = app.activityMgr:GetCastleText(__('??????')) , recommendName = app.activityMgr:GetCastleText(__('??????(??????)')) , tag = 3},
        {name = app.activityMgr:GetCastleText(__('??????')) , recommendName = app.activityMgr:GetCastleText(__('??????(??????)')) , tag = 4},
    }
    local difficultTable = {}
    for i = 1 , #fourTable do
        local difficultLayout = newLayer(167, 434 - (i - 1) * 57 ,
                                         { ap = display.CENTER, size = cc.size(302, 57), enable = true , tag = fourTable[i].tag})
        difficultLayout:setTag(fourTable[i].tag)
        commonLayout:addChild(difficultLayout)
        local battleFrame = newImageView(RES_DICT.CASTLE_MAP_BATTLE_FRAME_SELECTED, 151, 28,
                                         { ap = display.CENTER, tag = 825, enable = false })
        difficultLayout:addChild(battleFrame)
        battleFrame:setName("battleFrame")
        battleFrame:setVisible(false)
        battleFrame:setCascadeOpacityEnabled(true)
        local defaultImage = newImageView(RES_DICT.CASTLE_MAP_BATTLE_BTN_DEFAULT, 151, 28,
                                          { ap = display.CENTER, enable = true , tag = fourTable[i].tag })
        difficultLayout:addChild(defaultImage)
        defaultImage:setName("defaultImage")
        local lineOne = newImageView(RES_DICT.CASTLE_MAP_BATTLE_LINE_1 ,143, 0  )
        defaultImage:addChild(lineOne)
        lineOne:setCascadeOpacityEnabled(true)
        local lineTwo = newImageView(RES_DICT.CASTLE_MAP_BATTLE_LINE_1 ,143, 58  )
        defaultImage:addChild(lineTwo)
        local defaultLabel = newLabel(151, 28,
                                      fontWithColor(14,{ ap = display.CENTER, color = '#ffffff', text = fourTable[i].name, fontSize = 24, tag = 826 }))
        difficultLayout:addChild(defaultLabel)
        defaultLabel:setName("defaultLabel")
        difficultTable[#difficultTable+1] = difficultLayout
        defaultLabel.name = fourTable[i].name
        defaultLabel.recommendName = fourTable[i].recommendName
    end

    local chooseLabel = newLabel(167, 484,
                                 { ap = display.CENTER, color = '#fed2a6', text = app.activityMgr:GetCastleText(__('????????????')), fontSize = 20, tag = 827 })
    commonLayout:addChild(chooseLabel)

    local sweepBtn = newButton(167, 37, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE_DISABLE, d = RES_DICT.COMMON_BTN_ORANGE_DISABLE, s = RES_DICT.COMMON_BTN_ORANGE_DISABLE, scale9 = true, size = cc.size(123, 62), tag = 828 })
    display.commonLabelParams(sweepBtn, fontWithColor(14,{paddingW = 30 ,  text = app.activityMgr:GetCastleText(__('????????????')), fontSize = 22, color = '#ffffff'}))
    commonLayout:addChild(sweepBtn)

    local dropOutBtn = newButton(167, 195, { ap = display.CENTER ,  n = RES_DICT.COMMON_TITLE_3, d = RES_DICT.COMMON_TITLE_3, s = RES_DICT.COMMON_TITLE_3, scale9 = true, size = cc.size(186, 31), tag = 829 })
    display.commonLabelParams(dropOutBtn, {paddingW = 30 ,  text = app.activityMgr:GetCastleText(__('????????????')), fontSize = 22, color = '#966746'})
    local rewardsLayout =  display.newLayer(167 , 170 , { ap = display.CENTER_TOP , size = cc.size(270 , 90  )})

    commonLayout:addChild(dropOutBtn)
    commonLayout:addChild(rewardsLayout)
    self.commonLayoutView = {
        commonModule = commonModule ,
        commonModleImage = commonModleImage ,
        commonLayout = commonLayout ,
        recommendLevel = recommendLevel ,
        difficultTable = difficultTable ,
        sweepBtn = sweepBtn ,
        dropOutBtn = dropOutBtn ,
        rewardsLayout = rewardsLayout ,
    }
end

function  CastleTeamReadyBattleView:CreateSpecialView()
    local specialModule = newLayer(0, 0,
                                   { ap = display.LEFT_BOTTOM, size = cc.size(915, 566) })
    self.viewData.moduleInfoLayout:addChild(specialModule)
    local specicalmoduleImage = newNSprite(RES_DICT.CASTLE_MAP_ICO_4, 257, 168 +20 ,
                                           { ap = display.CENTER_BOTTOM, tag = 811 })
    -- specicalmoduleImage:setScale(0.75)
    specialModule:addChild(specicalmoduleImage)
    local titleBg = newImageView(RES_DICT.CASTLE_MAP_LABEL_TITLE ,257, 525-20 )
    specialModule:addChild(titleBg)
    local lineOne = newNSprite(RES_DICT.CASTLE_MAP_BATTLE_LINE_3, 261, 525-20,
                               { ap = display.CENTER, tag = 804})
    specialModule:addChild(lineOne)
    lineOne:setScaleX(0.85)
    local hurtLabel = newLabel(261, 537-20 ,
                               { ap = display.CENTER, color = '#f5bb28', text = app.activityMgr:GetCastleText(__('????????????????????????')), fontSize = 20, tag = 807 })
    specialModule:addChild(hurtLabel)

    local hurtNum = newLabel(261, 510-20 ,
                            fontWithColor( 14, { ap = display.CENTER, color = '#ffffff', text = "", fontSize = 24, tag = 808 }))
    specialModule:addChild(hurtNum)

    local listView =  CListView:create(cc.size(324,480) )
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint( 0.000000 , 0.000000)
    listView:setPosition(562,50)
    specialModule:addChild(listView,2)
    --local specialRewardBg = newNSprite(RES_DICT.CASTLE_MAP_BATTLE_BG_BOSS, 724, 285,
    --                                   { ap = display.CENTER, tag = 812 })
    --specialRewardBg:setScale(1, 1)
    --specialModule:addChild(specialRewardBg)

    self.specialLayoutView = {
        specialModule = specialModule ,
        hurtLabel = hurtLabel ,
        hurtNum = hurtNum ,
        listView = listView ,
        --specialRewardBg = specialRewardBg ,
        specicalmoduleImage = specicalmoduleImage
    }

end
function CastleTeamReadyBattleView:CreateModuleData(data , atkNumRank )
    local text = ""
    if atkNumRank.high then
        text = string.format(app.activityMgr:GetCastleText(__('????????????%s-%s????????????')) ,atkNumRank.low , atkNumRank.high )
    else
        text = string.format(app.activityMgr:GetCastleText(__('??????????????????%s????????????')) ,atkNumRank.low )
    end
    local goodData = data
    local goodsLayoutSize = cc.size(#goodData* 100 , 100 )
    local goodsLayout = display.newLayer(0,0,{size = goodsLayoutSize , ap = display.CENTER_BOTTOM })
    for i = 1 , #goodData do
        local rewardsData = clone(goodData)
        rewardsData[i].showAmount = true
        local goodNode = GoodNode.new(rewardsData[i])
        goodNode:setPosition(100 * (i - 0.5 ) ,goodsLayoutSize.height/2)
        goodNode:setScale(0.8)
        goodsLayout:addChild(goodNode)
        display.commonUIParams(goodNode , { animate = false ,  cb =  function(sender)
        app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
    end})
    end
    local line = newImageView(RES_DICT.CASTLE_MAP_BATTLE_LINE_3)
    local descrLabel = display.newLabel(0,0,fontWithColor(10, { color = "#e8af76", ap = display.LEFT_BOTTOM , hAlign = display.TAL, text = text , w = 300}))
    local descrLabelSize = display.getLabelContentSize(descrLabel)
    local height = goodsLayoutSize.height + descrLabelSize.height + 10
    local cellSize = cc.size(324 ,height )
    local cellLayout = newLayer(0,0 ,{ size = cellSize  })
    cellLayout:addChild(goodsLayout)
    cellLayout:addChild(line)
    cellLayout:addChild(descrLabel)
    goodsLayout:setPosition(cellSize.width/2 , 0 )
    line:setPosition(cellSize.width/2 , 100 )
    descrLabel:setPosition(12, 100 )
    local bgImage = display.newImageView(RES_DICT.CASTLE_MAP_BATTLE_BG_BOSS,cellSize.width/2 , cellSize.height/2 , {
        scale9 = true ,size= cc.size(cellSize.width , cellSize.height - 5 )
    })
    cellLayout:addChild(bgImage , -1)
    return cellLayout
end

function CastleTeamReadyBattleView:CreateBossLayout()
    local battleBarSize = cc.size(189, 585)
    local battleLayout = display.newLayer(display.cx  + 550 , display.cy + 63 , {
        ap = display.CENTER ,
        size = battleBarSize
    } )
    self.viewData.view:addChild(battleLayout)

    local battleBarImage = display.newImageView(RES_DICT.CASTLE_MAP_BATTLE_BAR , battleBarSize.width/2 , battleBarSize.height/2)
    battleLayout:addChild(battleBarImage)

    self.headViewData = self:CreateBossHead()
    local layer = self.headViewData.headButton
    battleLayout:addChild(layer)
    layer:setPosition(99.5 , 550)
    self.viewData.headButton = layer

    local size = cc.size(100, 100)
    local starLayout = display.newLayer(99.5 , 420, {ap = display.CENTER_TOP ,  size = size, color = cc.c4b(0,0,0,0), enable = true, cb = handler(self, self.ShowCardAdditionCallBack)})
    local starImage = display.newImageView(app.activityMgr:CastleResEx(RES_DICT.CASTLE_MAP_BATTLE_ICO_STAR), size.width / 2, size.height / 2, {ap = display.CENTER})
    starLayout:addChild(starImage)
    battleLayout:addChild(starLayout)
    local nameLabel = display.newLabel(size.width/2 , 0 , fontWithColor(14, {outline = "#392a2a" , outlineSize = 2, w = 160 , hAlign = display.TAC ,   text =app.activityMgr:GetCastleText(__('??????????????????'))}))
    starLayout:addChild(nameLabel)
    self.viewData.starLayout = starLayout


end
--==============================--
---@Description: ???????????????UI??????
---@author : xingweihao
---@date : 2019/3/6 2:52 PM
--==============================--
function CastleTeamReadyBattleView:UpdateSameUI(questType)
    local questTypeConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , "springActivity")
    local questOneType  =  questTypeConfig[tostring(questType)] or {}
    display.commonLabelParams(self.viewData.moduleName , {text = questOneType.name  } )
    display.commonLabelParams(self.viewData.moduleDecr , {text = questOneType.descr  } )
end
--==============================--
---@Description: ???????????????UI??????
---@param questType number ???????????????
---@param index number ????????????
---@param isSweep boolean ??????????????????
---@author : xingweihao
---@date : 2019/3/6 2:52 PM
--==============================--

function CastleTeamReadyBattleView:UpdateCommonUI(questType , index , isSweep)
    index = checkint(index) <= 0 and  1 or index
    questType = checkint(questType)
    local questConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST , "springActivity")
    local questOneConfig = {}
    for i, questData in pairs(questConfig) do
        if checkint(questData.type)  == questType  then
            questOneConfig[tostring(questData.difficulty)] = questData
        end
    end
    local commonLayoutView = self.commonLayoutView
    local isRecommemd = false

    for i = 4 , 1, -1 do
        local difficultLayout =  commonLayoutView.difficultTable[i]
        local battleFrame = difficultLayout:getChildByName("battleFrame")
        local defaultImage = difficultLayout:getChildByName("defaultImage")
        local defaultLabel = difficultLayout:getChildByName("defaultLabel")
        local questData =  questOneConfig[tostring(i)]
        if  checkint(questData.recommendLevel) <=  app.gameMgr:GetUserInfo().level and  (not isRecommemd) then
            isRecommemd = true
            display.commonLabelParams(defaultLabel ,{text = defaultLabel.recommendName })
        else
            display.commonLabelParams(defaultLabel ,{text = defaultLabel.name  })
        end

        if i == index  then
            battleFrame:setVisible(true)
            difficultLayout:setLocalZOrder(4)
            defaultImage:setTexture(app.activityMgr:CastleResEx("ui/castle/battleMaps/castle_map_battle_btn_selected.png"))
            display.commonLabelParams(commonLayoutView.recommendLevel , {text = string.format(app.activityMgr:GetCastleText(__('????????????:%d')) , questData.recommendLevel)})
        else
            difficultLayout:setLocalZOrder(1)
            battleFrame:setVisible(false)
            defaultImage:setTexture(app.activityMgr:CastleResEx("ui/castle/battleMaps/castle_map_battle_btn_default.png"))
        end
    end
    local sweepBtn = commonLayoutView.sweepBtn 
    if isSweep then 
        sweepBtn:setNormalImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange.png'))
        sweepBtn:setSelectedImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange.png'))
        sweepBtn:setDisabledImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange.png'))
    else 
        sweepBtn:setNormalImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange_disable.png'))
        sweepBtn:setSelectedImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange_disable.png'))
        sweepBtn:setDisabledImage(app.activityMgr:CastleResEx('ui/common/common_btn_orange_disable.png'))
    end
    local rewardsLayout = commonLayoutView.rewardsLayout
    -- ??????index ??????????????? ????????????????????????????????????
    rewardsLayout:removeAllChildren()
    for i, goodsData in pairs(questOneConfig[tostring(index)].rewards) do
        local goodsData = clone(goodsData)
        goodsData.showAmount = true 
        local goodNode = GoodNode.new(goodsData)
        goodNode:setScale(0.7)
        goodNode:setPosition(90 *( i- 0.5 ) , 90/2)
        rewardsLayout:addChild(goodNode)

        display.commonUIParams(goodNode , { animate = false ,  cb =  function(sender)
            app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
        end})
    end
    local commonModleImage = self.commonLayoutView.commonModleImage
    local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser').new()
    local questTypeConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , "springActivity")
    local moduleData = questTypeConfig[tostring(questType)]
    commonModleImage:setTexture(app.activityMgr:CastleResEx(string.format('ui/castle/battleMaps/castle_map_ico_%d.png', checkint(moduleData.iconId) ) ))
    rewardsLayout:setContentSize(cc.size(90* #questOneConfig[tostring(index)].rewards , 90  ))
end

--==============================--
---@Description: ?????????????????????UI??????
---@author : xingweihao
---@date : 2019/3/6 2:52 PM
--==============================--

function CastleTeamReadyBattleView:UpdateSpecialUI(highAttkNum , questType)
    local questTypeConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , "springActivity")
    local specialQuestPointRewardsConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.SPECIAL_QUEST_POINT_REWARDS , "springActivity")
    local atkNumRankTable = {
    }
    local count   = table.nums(specialQuestPointRewardsConfig)
    for i = 1, count do
        atkNumRankTable[#atkNumRankTable+1] = {}
        atkNumRankTable[i].low = specialQuestPointRewardsConfig[tostring(i)].atkNum
        if i < count  then
            atkNumRankTable[i].high = specialQuestPointRewardsConfig[tostring(i+1)].atkNum
        end
    end
    local specialLayoutView = self.specialLayoutView
    -- ??????UI ??????
    for i = 1, count do
        local cell = self:CreateModuleData(specialQuestPointRewardsConfig[tostring(i)].rewards , atkNumRankTable[i])
        specialLayoutView.listView:insertNodeAtLast(cell)
    end
    specialLayoutView.listView:reloadData()
    specialLayoutView.specicalmoduleImage:setTexture(app.activityMgr:CastleResEx(string.format('ui/castle/battleMaps/castle_map_ico_%d.png' ,checkint(questTypeConfig[tostring(questType)].iconId) )))
    display.commonLabelParams(specialLayoutView.hurtNum, {text = checkint(highAttkNum)})
end
function CastleTeamReadyBattleView:EnterAction()
    local viewData = self.viewData
    viewData.moduleInfoLayout:setScale(0.8)
    viewData.swallowView:runAction( cc.FadeTo:create(0.25,175))
    viewData.moduleInfoLayout:runAction(
            cc.Spawn:create(
                    cc.ScaleTo:create(0.25,1),
                    cc.FadeIn:create(0.25)
            )
    )
end

--==============================--
--desc:????????????boss ????????????
--time:2017-07-05 08:17:59
--@return
--==============================--
function CastleTeamReadyBattleView:CreateBossHead()

    local size = cc.size(100, 100)
    local layer = display.newLayer(550, display.height - 100, {ap = display.CENTER_TOP ,  size = size, color = cc.c4b(0,0,0,0), enable = true, cb = handler(self, self.ShowMonsterDetailInfoCallBack)})

    layer:addChild(display.newImageView(app.activityMgr:CastleResEx('ui/common/maps_boss_head_1.png'), size.width / 2, size.height / 2, {ap = display.CENTER}))

    --local iconMonsterConf = CardUtils.GetCardConfig(questData.icon) or {}
    local icon = 300010
    local headIconPath = AssetsUtils.GetCardHeadPath(icon)
    local headIcon = display.newImageView(headIconPath, 0, 0)

    local clippingNode = cc.ClippingNode:create()
    clippingNode:setInverted(false)
    clippingNode:setPosition(utils.getLocalCenter(layer))
    layer:addChild(clippingNode)

    local drawnode = cc.DrawNode:create()
    local radius = size.width - 10
    drawnode:drawSolidCircle(cc.p(0,0),radius - 10,0,220,1.0,1.0,cc.c4f(0,0,0,1))
    clippingNode:setStencil(drawnode)
    clippingNode:addChild(headIcon)
    clippingNode:setScale(0.5)

    layer:addChild(display.newImageView(app.activityMgr:CastleResEx('ui/common/maps_boss_head_2.png'), size.width / 2, size.height / 2, {ap = display.CENTER}))

    local bossName = display.newLabel(size.width / 2, 0,  fontWithColor(14, {outline = "#392a2a" , outlineSize = 2,  text =app.activityMgr:GetCastleText(__('BOSS??????'))}))
    layer:addChild(bossName)
    return {
        headButton = layer ,
        headIcon = headIcon ,
    }
end

function CastleTeamReadyBattleView:ShowMonsterDetailInfoCallBack()
    AppFacade.GetInstance():DispatchObservers("SHOW_MONSTER_DETAIL_INFO_EVENT" , {})
end
function CastleTeamReadyBattleView:ShowCardAdditionCallBack()
    AppFacade.GetInstance():DispatchObservers("SHOW_CARD_ADDITION_DETAIL_EVENT" , {})
end
---==============================--
---@Description: TODO
---@param monsterTexture userdata ???????????????
--==============================--
function CastleTeamReadyBattleView:UpdateHeadNode(  monsterTexture )
    local isVisible = false
    if string.len(monsterTexture) > 0  then
        isVisible = true
    end
    if isVisible then
        if not  self.headViewData then
            if GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN then
                self:CreateBossLayout()
            else
                self.headViewData =  self:CreateBossHead()
                local layer = self.headViewData.headButton
                self.viewData.moduleInfoLayout:addChild(layer)
                layer:setPosition(450,460)
            end
            self.headViewData.headButton:setVisible(true)
            self.headViewData.headButton:setScale(0.9)
        end
        self.headViewData.headButton:setVisible(true)
        self.headViewData.headIcon:setTexture(monsterTexture)
    else
        if  self.headViewData then
            self.headViewData.headButton:setVisible(false)
        end
    end
end

return CastleTeamReadyBattleView
