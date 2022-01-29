--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 探索主页面 场景
]]
---@class Anniversary20ExploreHomeScene:GameScene
local Anniversary20ExploreHomeScene = class('Anniversary20ExploreHomeScene', require('Frame.GameScene'))
local anniv2020Mgr = app.anniv2020Mgr
local _res = _res
local RES_DICT = {
    --            = top
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR = _res('ui/common/common_title.png'),
    COM_TIPS_ICON = _res('ui/common/common_btn_tips.png'),
    --            = center
    BG_IMAGE      = _res('arts/stage/bg/main_bg_69.jpg'),
    DOOR      = _spn("ui/anniversary20/explore/effects/wonderland_tower_tea_door"),
    WONDERLAND_TOWER_BTN_FLAG      = _spn("ui/anniversary20/explore/effects/wonderland_tower_btn_flag"),
    WONERLAND_TOWER_TEA_BOTTLE     = _spn("ui/anniversary20/explore/effects/wonerland_tower_tea_bottle"),


    WONDERLAND_TOWER_BG_CONDITION            = _res("ui/anniversary20/explore/exploreStep/wonderland_tower_bg_condition.png"),
    WONDERLAND_TOWER_BG_CONDITION_AREA       = _res("ui/anniversary20/explore/exploreStep/wonderland_tower_bg_condition_area.png"),
    ATTACK                                   = _res("ui/anniversary20/explore/exploreStep/attack.png"),
    WONDERLAND_EXPLORE_GO_LABEL_TITLE        = _res("ui/anniversary20/explore/exploreStep/wonderland_explore_go_label_title.png")

}

local EXPLORE_STATUS = {
    NOT_CLICK     = 1,
    CAN_CLICK     = 2,
    ALREADY_CLICK = 3
}
function Anniversary20ExploreHomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.anniversary20.Anniversary20ExploreHomeScene')

    -- create view
    self.viewData_ = Anniversary20ExploreHomeScene.CreateView()
    self:addChild(self.viewData_.view)
end


function Anniversary20ExploreHomeScene:getViewData()
    return self.viewData_
end


function Anniversary20ExploreHomeScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function Anniversary20ExploreHomeScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / black / block layer
    local entranceConf    = CONF.ANNIV2020.EXPLORE_ENTRANCE:GetValue(anniv2020Mgr:getExploringId())
    local exploreBgPath   = _res(string.fmt('ui/anniversary20/explore/%1', entranceConf.bgImgName))
    local backGroundGroup = view:addList({
        ui.image({img = exploreBgPath, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local doorSpine = display.newPathSpine(RES_DICT.DOOR)
    doorSpine:setPosition(cc.p(display.cx , display.cy + 147))
    doorSpine:setAnimation(0, string.fmt('idle_num_', {_num_ = anniv2020Mgr:getExploringId()}) , true)
    centerLayer:add(doorSpine,20)
    local cellSize = cc.size(210 , 135)
    local conterSize = cc.size(cellSize.width * 4 , cellSize.height * 4)
    local conterLayer = display.newLayer(display.cx , display.cy-55 , {size = conterSize ,ap = display.CENTER})
    centerLayer:addChild(conterLayer)
    local touchLayer = display.newLayer(display.cx + 0, display.cy  + -109.7 ,{ap = display.CENTER,size = cc.size(1092.2,504.7)})
    centerLayer:addChild(touchLayer, 10)
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_ROWS
    local fourMatrixViewData = {
        {1,1,1,1},
        {1,1,1,1},
        {1,1,1,1},
        {1,1,1,1}
    }
    local zonecp = cc.p(0,0 )
    local fourMatrixTouchData = {
        {
            {x = 168 ,  y = 89 , size = cc.size(192, 144) ,pos = zonecp },
            {x = 424 ,  y = 89 , size = cc.size(209, 144) ,pos = zonecp },
            {x = 666 ,  y = 89 , size = cc.size(209, 144) ,pos = zonecp },
            {x = 922 ,  y = 89 , size = cc.size(192, 144) ,pos = zonecp },
        },
        {
            {x = 213 ,  y = 244 , size = cc.size(174, 113) ,pos = zonecp},
            {x = 435 ,  y = 244 , size = cc.size(196, 113) ,pos = zonecp},
            {x = 654 ,  y = 244 , size = cc.size(196, 113) ,pos = zonecp},
            {x = 875 ,  y = 244 , size = cc.size(174, 113) ,pos = zonecp},
        },
        {
            {x = 248 ,  y = 364 , size = cc.size(153, 95.5) ,pos = zonecp},
            {x = 449 ,  y = 364 , size = cc.size(169.4, 95.5) ,pos = zonecp},
            {x = 640 ,  y = 364 , size = cc.size(169.4, 95.5) ,pos = zonecp},
            {x = 841 ,  y = 364 , size = cc.size(153, 95.5) ,pos = zonecp},
        },
        {
            {x = 277 ,  y = 455.75 , size = cc.size(143 ,74.4) ,pos = zonecp},
            {x = 457 ,  y = 455.75 , size = cc.size(154 ,74.4) ,pos = zonecp},
            {x = 633 ,  y = 455.75 , size = cc.size(154 ,74.4) ,pos = zonecp},
            {x = 810 ,  y = 455.75 , size = cc.size(143 ,74.4) ,pos = zonecp},

        }
    }
    for i = 1, rows do
        for j = 1, col do
            fourMatrixTouchData[i][j].pos = cc.p(cellSize.width * (j-0.5) , cellSize.height * (i-0.5))
        end
    end

    local pos = cc.p(0,0)
    local exploreModuleId = anniv2020Mgr:getExploringId()
    local elementPathTable = {
        _res(string.format("ui/anniversary20/explore/grid/under_%d_2" ,exploreModuleId) ),
        _res(string.format("ui/anniversary20/explore/grid/air_%d" ,exploreModuleId) ),
        _res(string.format("ui/anniversary20/explore/grid/light_%d" ,exploreModuleId)),
        _res(string.format("ui/anniversary20/explore/grid/top_%d_2" ,exploreModuleId)),
    }
    local touchData = nil

    for i = 1, rows do
        for j = 1, col do
            touchData = fourMatrixTouchData[i][j]
            pos = fourMatrixTouchData[i][j].pos
            local bottomImage =  display.newImageView(elementPathTable[1],pos.x , pos.y )
            bottomImage:setLocalZOrder(1)
            conterLayer:addChild(bottomImage)

            local bossImage = display.newImageView(elementPathTable[2] ,pos.x , pos.y )
            bossImage:setLocalZOrder(2)
            conterLayer:addChild(bossImage)

            local lightImage = display.newImageView(elementPathTable[3] , pos.x , pos.y )
            lightImage:setLocalZOrder(3)
            conterLayer:addChild(lightImage)
            lightImage:setVisible(false)
            local topImage = display.newImageView(elementPathTable[4] , pos.x , pos.y )
            topImage:setLocalZOrder(4)
            conterLayer:addChild(topImage)
            local touchNode = display.newButton(touchData.x , touchData.y , {
                size = touchData.size ,
                ap = display.CENTER ,
                enable = true})
            touchLayer:addChild(touchNode,10)
            touchNode:setTag((i - 1) * 4 + j)

            local viewData = {
                bottomImage = bottomImage,
                bossImage   = bossImage,
                lightImage  = lightImage,
                topImage    = topImage,
                touchNode   = touchNode
            }
            fourMatrixViewData[i][j] = viewData
        end
    end
    conterLayer:setRotation3D(cc.vec3(-35,0,0))

    centerLayer:setOpacity(0)
    centerLayer:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.FadeIn:create(0.2)
    ) )
    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = tostring(entranceConf.name), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    local rightLayout = display.newLayer(display.cx + 581, display.cy  + 167 ,{ap = display.CENTER,size = cc.size(374,244)})
    topLayer:addChild(rightLayout,0)
    local rightBgImage = display.newImageView( RES_DICT.WONDERLAND_TOWER_BG_CONDITION ,187, 122,{ap = display.CENTER})
    rightLayout:addChild(rightBgImage,0)
    local rightTopImage = display.newImageView( RES_DICT.WONDERLAND_TOWER_BG_CONDITION_AREA ,170, 201,{ap = display.CENTER})
    rightLayout:addChild(rightTopImage,0)
    local zoneLabel = display.newLabel(30, 204 , {fontSize = 24,text = "",color = '#30312F',ap = display.LEFT_CENTER})
    rightLayout:addChild(zoneLabel,4)
    local clearConditionLabel = display.newLabel(30, 126+ 30  , {fontSize = 24,text = __('通关条件'),color = '#A99D86',ap = display.LEFT_CENTER})
    rightLayout:addChild(clearConditionLabel,4)
    local clearCondition =  display.newRichLabel(25, 126  ,{ ap = display.LEFT_CENTER , c = {}})

    --display.newLabel(30, 126 , {fontSize = 22,text = "",color = '#FFFFFF',ap = display.LEFT_CENTER})
    rightLayout:addChild(clearCondition,4)
    local giveUpLayout = display.newButton(169, 48 ,{ap = display.CENTER,size = cc.size(311,74),enable = true})
    rightLayout:addChild(giveUpLayout,0)
    local flagSpine = display.newPathSpine(RES_DICT.WONDERLAND_TOWER_BTN_FLAG)
    flagSpine:setAnimation(0 , "animation" , true)
    flagSpine:setPosition(311/2+15, 37)
    giveUpLayout:addChild(flagSpine)
    local nextSize = cc.size( 280 , 120 )
    local nextLayout = display.newButton(display.cx , display.cy + 200 , {
        size = nextSize,
        ap = display.CENTER
    })
    topLayer:addChild(nextLayout , 20)
    local nextTopBtn = display.newButton(nextSize.width/2 , nextSize.height /2 , {
        n = RES_DICT.WONDERLAND_EXPLORE_GO_LABEL_TITLE
    })
    nextLayout:addChild(nextTopBtn)
    nextLayout:setVisible(false)
    display.commonLabelParams(nextTopBtn , {text = __('下一区域' ) , fontSize = 24 , color = "#ffffff" })

    local giveUpLabel = display.newLabel(160.5, 40 ,fontWithColor(14 , {outline = "462020",text = __('放弃探索'),ap = display.CENTER}))
    giveUpLayout:addChild(giveUpLabel,4)
    local rewardTotalLayout = display.newLayer(display.SAFE_L + 32.59998, display.cy + 54.20001 ,{ap = display.LEFT_CENTER,size = cc.size(142.4,149.5),color = cc.c4b(0,0,0,0),enable = true})
    topLayer:addChild(rewardTotalLayout,0)

    local rewardSpine = display.newPathSpine(RES_DICT.WONERLAND_TOWER_TEA_BOTTLE)
    rewardSpine:setAnimation(0, "idle" , true)
    rewardTotalLayout:addChild(rewardSpine)
    rewardSpine:setPosition(71.2, 100)
    local rewardTotalLabel = display.newLabel(71.20001, 23.75 ,fontWithColor(14 , {outline = "45403C",fontSize = 24,text = __('奖励总计'),ap = display.CENTER}))
    rewardTotalLayout:addChild(rewardTotalLabel,0)
    local skillBtn = display.newLayer(display.SAFE_L + -63, display.cy + 202 ,{ap = display.LEFT_CENTER,size = cc.size(220,90),color = cc.c4b(0,0,0,0),enable = true})
    topLayer:addChild(skillBtn,0)
    local skillImage = display.newImageView( RES_DICT.ATTACK ,102, 45,{ap = display.CENTER})
    skillBtn:addChild(skillImage,0)
    skillBtn:setVisible(false)

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ anniv2020Mgr:getHpGoodsId() })
    topLayer:add(moneyBar)



    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        fourMatrixViewData = fourMatrixViewData ,
        fourMatrixTouchData = fourMatrixTouchData ,
        backBtn         = backBtn,
        --              = center
        centerLayer     = centerLayer,
        doorSpine       = doorSpine,
        moneyBar       = moneyBar,

        rightLayout               = rightLayout,
        rightBgImage              = rightBgImage,
        rightTopImage             = rightTopImage,
        zoneLabel                 = zoneLabel,
        clearConditionLabel       = clearConditionLabel,
        giveUpLayout              = giveUpLayout,
        giveUpLabel               = giveUpLabel,
        rewardTotalLayout         = rewardTotalLayout,
        rewardTotalLabel          = rewardTotalLabel,
        rewardSpine               = rewardSpine,
        skillBtn                  = skillBtn,
        clearCondition            = clearCondition,
        touchLayer                = touchLayer,
        nextLayout                = nextLayout ,
        nextTopBtn                = nextTopBtn ,
        skillImage                = skillImage
    }
end
function Anniversary20ExploreHomeScene:UpdateView(pathMaps)
    self:UpdateTopLayer()
    self:UpdateBossLight()
    self:UpdateMapImage(pathMaps)
end

function Anniversary20ExploreHomeScene:UpdateTopLayer()
    self:UpdateRightTopLayout()
    self:UpdateBuffLayout()
    self:UpdateShowNextLayoutAndSpine()
end

function Anniversary20ExploreHomeScene:UpdateShowNextLayoutAndSpine()
    local isPassed = anniv2020Mgr:isExploreingFloorPassed()
    local viewData_ = self.viewData_
    viewData_.nextLayout:setVisible(false)
    if not isPassed then return end
    local isLastFloor = anniv2020Mgr:isExploreingLastFloor()
    if isLastFloor then
        display.commonLabelParams(viewData_.nextTopBtn , { text = __('已通关')})
    end
    viewData_.doorSpine:setToSetupPose()
    viewData_.doorSpine:setAnimation(0 , string.format("play1_%d" , anniv2020Mgr:getExploringId()) , false)
end
function Anniversary20ExploreHomeScene:UpdateRightTopLayout()
    local viewData_ = self:getViewData()
    display.commonLabelParams(viewData_.zoneLabel , {text = string.fmt(__('第_num_个区域') , { _num_ = anniv2020Mgr:getExploreingFloor()})})
    local explorRateConf = anniv2020Mgr:getExploreingFloorPassData(anniv2020Mgr:getExploringId() ,anniv2020Mgr:getExploreingFloor())
    display.reloadRichLabel(viewData_.clearCondition , {
        c = {
            {fontSize = 22,text = explorRateConf.descr .. "  ",color = '#FFFFFF',ap = display.LEFT_CENTER} ,

            fontWithColor(10, {fontSize = 24 ,  text = app.anniv2020Mgr:GetExploreProgressStr()})
        }
    })
end

function Anniversary20ExploreHomeScene:UpdateBuffLayout()
    local buffs = anniv2020Mgr:getExploreingBuffs()
    local buffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
    local buffPath = nil
    for i, buffId in pairs(buffs) do
        if checkint(buffConf[tostring(buffId)].type) == 1 then
            local image = buffConf[tostring(buffId)].image
            buffPath = _res(string.format("ui/anniversary20/explore/exploreStep/%s" , image))
            break
        end
    end
    if buffPath then
        self.viewData_.skillBtn:setVisible(true)
        self.viewData_.skillImage:setTexture(buffPath)
    else
        self.viewData_.skillBtn:setVisible(false)
    end
end
function Anniversary20ExploreHomeScene:UpdateRewardTotalLayout()
    local viewData_ = self.viewData_
    -- TODO 可以领取奖励先不判断 条件不充足
    local isRewards = false
    local isBossQuest = anniv2020Mgr:isExploreingBossFloor()
    if isBossQuest  then
        local isPassed =  app.anniv2020Mgr:isExploreingFloorPassed()
        isRewards = isPassed
    end

    if not isRewards then
        viewData_.rewardSpine:setToSetupPose()
        viewData_.rewardSpine:setAnimation(0, "idle" , true)
    else
        viewData_.rewardSpine:setToSetupPose()
        viewData_.rewardSpine:setAnimation(0, "play2" , true)
    end
end

function Anniversary20ExploreHomeScene:UpdateBossLight()
    local mapDatas = anniv2020Mgr:getExploreingMapDatas()
    local EXPLORE_TYPE = FOOD.ANNIV2020.EXPLORE_TYPE
    local fourMatrixViewData = self.viewData_.fourMatrixViewData
    local DEFINE = FOOD.ANNIV2020.DEFINE
    for key, v in pairs(mapDatas) do
        if checkint(v.type) == EXPLORE_TYPE.MONSTER_BOSS then
            local col = DEFINE.EXPLORE_MAP_COLS
            local i = math.ceil(key/col)
            local mod = key % col
            mod = mod == 0 and col  or mod % col
            fourMatrixViewData[i][mod].lightImage:setTexture("ui/anniversary20/explore/grid/boss_light")
        end
    end
end
function Anniversary20ExploreHomeScene:updateMoneyBarGoodNum()
    self:getViewData().moneyBar:updateMoneyBar()
end
function Anniversary20ExploreHomeScene:UpdateMapImage(pathMaps)
    local exploreModuleId =  anniv2020Mgr:getExploringId()
    local fourMatrixViewData = self.viewData_.fourMatrixViewData
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_COLS
    for i = 1, rows do
        for j = 1, col do
            local status = pathMaps[i][j]
            local matrixViewData = fourMatrixViewData[i][j]
            local mapGridPath = nil
            local topImagePath = nil
            local underImagePath = nil
            if status == EXPLORE_STATUS.NOT_CLICK then
                topImagePath   = _res(string.format("ui/anniversary20/explore/grid/top_%d_2", exploreModuleId))
                underImagePath = _res(string.format("ui/anniversary20/explore/grid/under_%d_2", exploreModuleId))
                mapGridPath    = _res(string.format('ui/anniversary20/explore/grid/air_%d' , exploreModuleId))
                matrixViewData.bossImage:setOpacity(255)
            else
                mapGridPath = anniv2020Mgr:getMapGridPath((i-1)*4+j)
                if status == EXPLORE_STATUS.CAN_CLICK then
                    matrixViewData.bossImage:setOpacity(255)
                    topImagePath   = _res(string.format("ui/anniversary20/explore/grid/top_%d_1", exploreModuleId))
                    underImagePath = _res(string.format("ui/anniversary20/explore/grid/under_%d_1", exploreModuleId))
                elseif status == EXPLORE_STATUS.ALREADY_CLICK then
                    matrixViewData.bossImage:setOpacity(255*0.3)
                    topImagePath   = _res(string.format("ui/anniversary20/explore/grid/top_%d_3", exploreModuleId))
                    underImagePath = _res(string.format("ui/anniversary20/explore/grid/under_%d_3", exploreModuleId))
                end
            end
            matrixViewData.bottomImage:setTexture(underImagePath)
            matrixViewData.bossImage:setTexture(mapGridPath)
            matrixViewData.topImage:setTexture(topImagePath)
        end
    end
end

function Anniversary20ExploreHomeScene:RunActionLightAction(pathDatas)
    local viewData_ = self:getViewData()
    local fourMatrixViewData = viewData_.fourMatrixViewData
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_COLS
    for i = 1, rows do
        for j = 1, col do
            local lightImage =  fourMatrixViewData[i][j].lightImage
            if pathDatas[i][j] == EXPLORE_STATUS.CAN_CLICK then
                lightImage:stopAllActions()
                lightImage:setOpacity(0)
                lightImage:setVisible(true)
                lightImage:runAction(
                    cc.Repeat:create(
                       cc.Sequence:create(
                           cc.FadeIn:create(0.2),
                           cc.DelayTime:create(0.2),
                           cc.FadeOut:create(0.2)
                       ),5
                    )
                )
            else
                lightImage:setVisible(false)
            end
        end
    end
end
function Anniversary20ExploreHomeScene:StepRewardAnimation(rewardData , mapGridId)
    local posTab = {
        cc.p(0,60),
        cc.p(-20,30),
        cc.p(25,30),
        cc.p(-30,-30),
        cc.p(30,-30),
        cc.p(math.random(10),math.random(90)),
        cc.p(math.random(30),math.random(70)),
        cc.p(math.random(50),math.random(50)),
        cc.p(math.random(70),math.random(30)),
        cc.p(math.random(90),math.random(10))
    }
    local spawnTable  = {}
    local imagePathTable  = {
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
    }
    if #rewardData == 0 then
        return
    end

    local tables = {}
    for i, v in pairs(rewardData) do
        tables[#tables+1] = CommonUtils.GetGoodsIconPathById(v.goodsId)
    end
    local count = #tables+1
    for i =1 , #imagePathTable do
         local mode =  i %count == 0 and count or i %count
        imagePathTable[i] = tables[mode]
    end
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local col = DEFINE.EXPLORE_MAP_COLS
    local line = math.ceil(mapGridId / col)
    local colu  = mapGridId % col == 0 and col or mapGridId % col
    local touchLayer = self.viewData_.touchLayer
    local topLayer = self.viewData_.topLayer
    local rewardTotalLayout = self.viewData_.rewardTotalLayout
    local elementPos  = self.viewData_.fourMatrixTouchData[line][colu]
    local initPos =topLayer:convertToNodeSpace(touchLayer:convertToWorldSpace(cc.p(elementPos.x , elementPos.y)))
    local endPos  = cc.p(rewardTotalLayout:getPosition())
    endPos = cc.p(endPos.x + 50 , endPos.y + 40)
    local scale = 0.4
    for i=1,table.nums(posTab) do
        local img= display.newImageView(imagePathTable[i],0,0,{as = false})
        img:setPosition(initPos)
        img:setTag(555)
        img:setVisible(false)
        topLayer:addChild(img,30)
        spawnTable[#spawnTable+1] =  cc.TargetedAction:create(img ,
              cc.Sequence:create(
                  cc.Show:create(),
                  cc.Spawn:create(
                      cc.ScaleTo:create(0.2, scale),
                      cc.MoveBy:create(0.3,posTab[i])
                  ),
                  cc.MoveBy:create(0.1+i*0.11,cc.p(math.random(15),math.random(15))),
                  cc.DelayTime:create(i*0.01),
                  cc.Spawn:create(
                      cc.MoveTo:create(0.4, endPos),
                      cc.ScaleTo:create(0.4, 0.2)
                  ),
                  cc.RemoveSelf:create()
              )
        )
    end

    topLayer:runAction(
        cc.Spawn:create(
            cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.Spawn:create(spawnTable)
            ),
            cc.Sequence:create(
                cc.DelayTime:create(1.3),
                cc.CallFunc:create(function()
                    self.viewData_.rewardSpine:setToSetupPose()
                    self.viewData_.rewardSpine:setAnimation(0,"play1" , false)
                end)
            )
        )
    )


end


return Anniversary20ExploreHomeScene
