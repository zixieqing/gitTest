--[[
世界boss主场景
--]]
---@class UnionWarBattleBossView
local UnionWarBattleBossView = class('UnionWarBattleBossView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.union.UnionWarBattleBossView'
    node:enableNodeEvents()
    node:setAnchorPoint(display.CENTER)
    return node
end)
local unionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
local RES_DICT = {
    UI_WORLDBOSS_HOME_WORLDBOSS_BG          = _res('ui/union/wars/map/gvg_maps_bg_2_2.jpg'),
    UI_COMMON_COMMON_TITLE_NEW              = _res('ui/common/common_title_new.png'),
    UI_COMMON_COMMON_BTN_TIPS               = _res('ui/common/common_btn_tips.png'),
    UI_COMMON_COMMON_BTN_BACK               = _res('ui/common/common_btn_back.png'),
    UI_WORLDBOSS_HOME_WORLDBOSS_BG_BELOW    = _res('ui/worldboss/home/worldboss_bg_below.png'),
    UI_WORLDBOSS_HOME_WORLDBOSS_TEAM_BG     = _res('ui/worldboss/home/worldboss_team_bg.png'),
    UI_COMMON_KAPAI_FRAME_BG_NOCARD         = _res('ui/common/kapai_frame_bg_nocard.png'),
    UI_COMMON_KAPAI_FRAME_NOCARD            = _res('ui/common/kapai_frame_nocard.png'),
    UI_COMMON_MAPS_FIGHT_BTN_PET_ADD        = _res('ui/common/maps_fight_btn_pet_add.png'),
    UI_HOME_TEAMFORMATION_TEAM_ICO_CAPTAIN  = _res('ui/home/teamformation/team_ico_captain.png'),
    UI_UNION_HUNT_GUILD_HUNT_BG_MOSTER_INFO = _res('ui/union/hunt/guild_hunt_bg_moster_info.png'),
    UI_COMMON_COMMON_BTN_WHITE_DEFAULT      = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN_TIPS                         = _res('ui/common/common_btn_tips.png'),
}
------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ define ------------
local SceneZorder = {
    BASE 				= 1,
    MONSTER_SPINE 		= 2,
    UI 					= 20,
    TOP 				= 9
}
local UnionWarsModelFactory = require('Game.models.UnionWarsModelFactory')
local cardHeadNodeSize = cc.size(96, 96)
------------ define ------------

--[[
constructor
--]]
function UnionWarBattleBossView:ctor(...)
    local args = unpack({...})

    self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function UnionWarBattleBossView:InitUI()

    local function CreateView()
        local size = self:getContentSize()

        local bg = display.newImageView(RES_DICT.UI_WORLDBOSS_HOME_WORLDBOSS_BG , 0, 0 , {enable = true })
        display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self:addChild(bg)

        -- 标题版
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n =RES_DICT.UI_COMMON_COMMON_TITLE_NEW, enable = true, ap = cc.p(0, 0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('挑战工会BOSS'), fontSize = 27, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel, SceneZorder.TOP)

        local tipButton = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 257, 30, { ap = display.CENTER, tag = 72 })
        tipButton:setScale(1, 1)
        tabNameLabel:addChild(tipButton)

        -- 返回按钮
        local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.UI_COMMON_COMMON_BTN_BACK})
        self:addChild(backBtn, SceneZorder.TOP + 10)

        -- 底部选卡界面
        local bottomBg = display.newImageView(RES_DICT.UI_WORLDBOSS_HOME_WORLDBOSS_BG_BELOW, 0, 0, {scale9 = true})
        display.commonUIParams(bottomBg, {po = cc.p(
                size.width * 0.5,
                bottomBg:getContentSize().height * 0.5
        )})
        self:addChild(bottomBg, SceneZorder.UI)
        bottomBg:setContentSize(cc.size(size.width, bottomBg:getContentSize().height))

        local teamBg = display.newImageView(RES_DICT.UI_WORLDBOSS_HOME_WORLDBOSS_TEAM_BG, 0, 0)
        display.commonUIParams(teamBg, {po = cc.p(
                display.SAFE_L - 60 + teamBg:getContentSize().width * 0.5,
                teamBg:getContentSize().height * 0.5
        )})
        self:addChild(teamBg, SceneZorder.UI)

        local emptyCardNodes = {}
        local addBtns = {}
        for i = 1, MAX_TEAM_MEMBER_AMOUNT do
            local emptyCardHeadBg = display.newImageView(RES_DICT.UI_COMMON_KAPAI_FRAME_BG_NOCARD)
            local scale = cardHeadNodeSize.width / emptyCardHeadBg:getContentSize().width
            emptyCardHeadBg:setScale(scale)
            display.commonUIParams(emptyCardHeadBg, {po = cc.p(
                    teamBg:getPositionX() + (emptyCardHeadBg:getContentSize().width * scale + 10) * (i - 0.5 - MAX_TEAM_MEMBER_AMOUNT * 0.5),
                    teamBg:getPositionY() - 30
            )})
            self:addChild(emptyCardHeadBg, SceneZorder.UI + 1)

            local emptyCardHeadFrame = display.newImageView(RES_DICT.UI_COMMON_KAPAI_FRAME_NOCARD, 0, 0)
            display.commonUIParams(emptyCardHeadFrame, {po = utils.getLocalCenter(emptyCardHeadBg)})
            emptyCardHeadBg:addChild(emptyCardHeadFrame)

            local addIcon = display.newNSprite(RES_DICT.UI_COMMON_MAPS_FIGHT_BTN_PET_ADD, 0, 0)
            display.commonUIParams(addIcon, {po = utils.getLocalCenter(emptyCardHeadBg)})
            addIcon:setScale(1 / scale)
            emptyCardHeadBg:addChild(addIcon)

            local btn = display.newButton(0, 0, {size = cardHeadNodeSize})
            display.commonUIParams(btn, {po = cc.p(
                    emptyCardHeadBg:getPositionX(),
                    emptyCardHeadBg:getPositionY()
            )})
            self:addChild(btn, SceneZorder.UI + 2)
            addBtns[#addBtns+1] = btn

            -- 添加队长标识
            if 1 == i then
                local captainMark = display.newImageView(RES_DICT.UI_HOME_TEAMFORMATION_TEAM_ICO_CAPTAIN, 0, 0)
                display.commonUIParams(captainMark, {po = cc.p(
                        emptyCardHeadBg:getPositionX(),
                        emptyCardHeadBg:getPositionY() + emptyCardHeadBg:getContentSize().height * 0.5 * scale
                )})
                self:addChild(captainMark, SceneZorder.TOP)
            end
            emptyCardNodes[i] = {emptyCardHeadBg = emptyCardHeadBg}
        end

        -- 奖励 说明部分
        local descrBg = display.newImageView(RES_DICT.UI_UNION_HUNT_GUILD_HUNT_BG_MOSTER_INFO, 0, 0)
        local descrLayerSize = descrBg:getContentSize()

        local descrLayer = display.newLayer(0, 0, {size = descrLayerSize})
        display.commonUIParams(descrLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
                display.SAFE_L + descrLayerSize.width * 0.5 + 10,
                bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5 + descrLayerSize.height * 0.5 - 20
        )})
        self:addChild(descrLayer, SceneZorder.TOP)

        local previewRewardLabel = display.newLabel(15 , descrLayerSize.height -15 , fontWithColor(14 ,{ap = display.LEFT_TOP,  text = __('奖励预览')}))
        descrLayer:addChild(previewRewardLabel,SceneZorder.TOP)

        local noteLabel = display.newLabel(427 ,descrLayerSize.height - 15 , fontWithColor(14, { ap = display.LEFT_TOP,  text = __('注:') , color = "#ffcb31", outline = false  }))
        descrLayer:addChild(noteLabel,SceneZorder.TOP)

        local explainLabel = display.newLabel(427 ,descrLayerSize.height - 60 , fontWithColor(10 , { ap = display.LEFT_CENTER, color = "#ffffff", text = "cccc" , outline = false  , fontSize = 24 }))
        descrLayer:addChild(explainLabel,SceneZorder.TOP)

        display.commonUIParams(descrBg, {po = utils.getLocalCenter(descrLayer)})
        descrLayer:addChild(descrBg)


        -- boss详情按钮
        local bossDetailBtn = display.newButton(0, 0, {n = RES_DICT.UI_COMMON_COMMON_BTN_WHITE_DEFAULT, cb = handler(self, self.BossDetailBtnClickHandler)})
        display.commonUIParams(bossDetailBtn, {po = cc.p(
                descrLayerSize.width - 25 - bossDetailBtn:getContentSize().width * 0.5,
                descrLayerSize.height/2
        )})
        display.commonLabelParams(bossDetailBtn, fontWithColor('14', {fontSize = 22 ,  text = __('boss详情')}))
        descrLayer:addChild(bossDetailBtn)
        local battleBtn = require('common.CommonBattleButton').new({
                                                                       pattern =  6 ,
                                                                       battleText =__('挑战'),
                                                                       battleFontSize = 40  ,
                                                                   })
        battleBtn:setPosition( display.SAFE_R - 35 - 70 , bottomBg:getPositionY() + 50)
        self:addChild(battleBtn, SceneZorder.UI)


        local battleBtnX = battleBtn:getPositionX()
        local residueTimeDescr  = display.newLabel(battleBtnX , 45 , {text = __('当前剩余次数') , fontSize = 22 })
        self:addChild(residueTimeDescr ,  SceneZorder.UI)


        local residueTimeLabel  = display.newLabel(battleBtnX , 20 , {text = __('当前剩余次数') , fontSize = 22 })
        self:addChild(residueTimeLabel ,  SceneZorder.UI)
        return {
            bg = bg ,
            tabNameLabel      = tabNameLabel,
            bossDetailBtn     = bossDetailBtn,
            explainLabel      = explainLabel,
            addBtns           = addBtns,
            bottomBg          = bottomBg,
            descrLayer        = descrLayer,
            battleBtn         = battleBtn,
            bossSpineNode     = nil,
            bossBgSpineNode   = nil,
            bossFgSpineNode   = nil,
            teamCardHeadNodes = {},
            emptyCardNodes    = emptyCardNodes,
            residueTimeLabel  = residueTimeLabel,
            backBtn           = backBtn
        }
    end

    xTry(function ( )
        self.viewData = CreateView()
    end, __G__TRACKBACK__)
    -- 弹出标题班
    local action = cc.Sequence:create(
            cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80))),
            cc.CallFunc:create(function ()
                display.commonUIParams(self.viewData.tabNameLabel, {cb = function (sender)
                    PlayAudioByClickNormal()
                    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_WARS)]})
                end})
            end)
    )
    self.viewData.tabNameLabel:runAction(action)

end
--[[
刷新队伍阵容界面
@params teamData table
--]]
function UnionWarBattleBossView:RefreshTeamMember(teamData)
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardHeadNode = self.viewData.teamCardHeadNodes[i]
        if nil ~= cardHeadNode then
            cardHeadNode:removeFromParent()
        end
    end
    self.viewData.teamCardHeadNodes = {}
    for i,v in ipairs(teamData) do
        local nodes = self.viewData.emptyCardNodes[i]
        if nil ~= v.id and 0 ~= checkint(v.id) then
            local c_id = checkint(v.id)
            local cardHeadNode = require('common.CardHeadNode').new({
                id = c_id,
                showBaseState = true,
                showActionState = false,
                showVigourState = false
            })
            local scale = (cardHeadNodeSize.width) / cardHeadNode:getContentSize().width
            cardHeadNode:setScale(scale)
            display.commonUIParams(cardHeadNode, {po = cc.p(
                    nodes.emptyCardHeadBg:getPositionX(),
                    nodes.emptyCardHeadBg:getPositionY()
            )})
            self:addChild(cardHeadNode, SceneZorder.UI + 1)
            self.viewData.teamCardHeadNodes[i] = cardHeadNode
        end
    end
end

--[[
根据关卡id刷新中间spine
@params questId
--]]
function UnionWarBattleBossView:RefreshBossSpine(questId)
    local size = self:getContentSize()
    local questConfig = CommonUtils.GetQuestConf(questId)
    if nil ~= questConfig then
        if nil ~= self.viewData.bossSpineNode then
            self.viewData.bossSpineNode:removeFromParent()
            self.viewData.bossSpineNode = nil
        end
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        local pageId  =  unionWarsModel:getMapPageIndex()
        local UnionWarsModel        = UnionWarsModelFactory.UnionWarsModel
        local bossSiteDefine = UnionWarsModel.BOSS_SITE_DEFINES[checkint(pageId)]
        local bossQuestConf  = CommonUtils.GetConfig('union', unionConfigParser.TYPE.WARS_BOSS_QUEST, questId) or {}
        local unionPetConf   = app.cardMgr.GetBeastBabyFormConfig(bossSiteDefine.petId, checkint(bossQuestConf.level), 1) or {}
        local spineNode = AssetsUtils.GetCardSpineNode({skinId = checkint(unionPetConf.skinId), scale = 0.25 * checknumber(unionPetConf.scale)})
        spineNode:update(0)
        spineNode:setScaleX(-1 * spineNode:getScaleX())

        local viewBox = spineNode:getBorderBox('viewBox')

        spineNode:setPosition(cc.p(
                size.width * 0.675,
                size.height * 0.5 - viewBox.height * 0.5 - viewBox.y
        ))
        self:addChild(spineNode, SceneZorder.BASE)
        self.viewData.bossSpineNode = spineNode

        spineNode:setAnimation(0, 'idle', true)

        -- 修正一次spine火位置
        if nil ~= self.viewData.bossBgSpineNode then
            self.viewData.bossBgSpineNode:setPosition(cc.p(
                    spineNode:getPositionX(),
                    spineNode:getPositionY()
            ))
        end
    end
end

--==============================--
---@Description: 更新界面的UI
---@param unionWBossQuestId number @工会Boss 的关卡ID 
---@param totalAttachNum number @总共的进攻次数
---@param leftAttachNum number 剩余的进攻次数
---@author : xingweihao
---@date : 2019/4/17 10:41 AM
--==============================--

function UnionWarBattleBossView:UpdateView(unionWBossQuestId , totalAttachNum , leftAttachNum  )
    local viewData = self.viewData
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    local mapIndex  =  unionWarsModel:getMapPageIndex()
    local bgTexture = _res('ui/union/wars/map/gvg_maps_bg_2_1.jpg')
    if checkint(mapIndex)  == 2 then
        bgTexture=_res('ui/union/wars/map/gvg_maps_bg_2_2.jpg')
    end
    viewData.bg:setTexture(bgTexture)
    display.commonLabelParams(viewData.residueTimeLabel , {text = string.format('%d/%d' ,checkint(leftAttachNum ) , checkint(totalAttachNum) ) })
    local warsBeastQuestConf = CommonUtils.GetConfigAllMess('warsBeastQuest' , 'union')
    local warsBeastQuestOneConf = checktable(warsBeastQuestConf[tostring(unionWBossQuestId)])
    local rewards = checktable(warsBeastQuestOneConf.rewards)
    local rewardSize = cc.size(#rewards * 90 , 90  )
    local rewardLayout = display.newLayer(130,0, {ap = display.LEFT_BOTTOM, size = rewardSize })
    viewData.descrLayer:addChild(rewardLayout)
    for i, v in pairs(rewards) do
        local goodNode = require('common.GoodNode').new({ goodsId = v.goodsId , showAmount = false})
        goodNode:setPosition(90 * (i - 0.5) , 60)
        rewardLayout:addChild(goodNode)
        goodNode:setScale(0.8)
    end
    local questOneConfig = CommonUtils.GetConfigAllMess(unionConfigParser.TYPE.WARS_BOSS_LIMIT , 'union')[tostring(unionWBossQuestId)] or {}
    display.commonLabelParams(viewData.explainLabel, {text = tostring(questOneConfig.descr) })
    self:RefreshBossSpine(unionWBossQuestId)
end
return UnionWarBattleBossView
