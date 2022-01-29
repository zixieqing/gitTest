--[[
邮箱界面
--]]
---@class PetOneKeyUpgradeView
local PetOneKeyUpgradeView = class('PetOneKeyUpgradeView', function()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(display.CENTER)
    node.name = 'home.PetOneKeyUpgradeView'
    node:enableNodeEvents()
    return node
end)
local newImageView         = display.newImageView
local newLabel             = display.newLabel
local newNSprite           = display.newNSprite
local newButton            = display.newButton
local newLayer             = display.newLayer
---@type GameManager
local gameMgr = app.gameMgr
---@type PetManager
local petMgr = app.petMgr
local RES_DICT             = {
    PET_LVUP_ICO_LINE                     = _res('ui/pet/keyUpgrade/pet_lvup_ico_line.png'),
    CARD_PREVIEW_BG_LOADING_FRAGMENT      = _res('ui/pet/card_preview_bg_loading_fragment.png'),
    COMMON_BG_TITLE_2                     = _res('ui/common/common_bg_title_2.png'),
    COMMON_BTN_ORANGE                     = _res('ui/common/common_btn_orange.png'),
    PET_LVUP_ICO_CHOICE_NUM               = _res('ui/pet/keyUpgrade/pet_lvup_ico_choice_num.png'),
    CARD_SKILL_ICO_SWORD                  = _res('ui/pet/card_skill_ico_sword.png'),
    COMMON_BG_7                           = _res('ui/common/common_bg_7.png'),
    PET_LVUP_BG_CHOICE                    = _res('ui/pet/keyUpgrade/pet_lvup_bg_choice.png'),
    CARD_PREVIEW_ICO_LOADING_FRAGMENT_NOT = _res('ui/pet/card_preview_ico_loading_fragment_not.png'),
    COMMON_FRAME_GOODS_1                  = _res('ui/common/common_frame_goods_1.png'),
    COMMON_FRAME_GOODS_3                  = _res('ui/common/common_frame_goods_3.png'),
    COMMON_FRAME_GOODS_4                  = _res('ui/common/common_frame_goods_4.png'),
}
function PetOneKeyUpgradeView:ctor(param)
    param = param or {}
    self.selectTable = { 1,1,0 } -- 表示选择的状态 初始都为零
    self.id = checkint(param.id)
    self.kindNumTable = nil
    self.isClose = false
    self.oneKeyTable = {}
    self:InitUI()
    self:UpdatePetNum()
    local pets = app.gameMgr:GetUserInfo().pets
    local petData =  pets[tostring(self.id)]
    self.preLevel =checkint(petData.level)
    self.curLevel = self.preLevel
    self:UpgrageCallBack()
    --self:RefreshPrograss(petData.exp , self.preLevel)
end

function PetOneKeyUpgradeView:InitUI()
    local view       = newLayer(display.cx, display.cy, { ap = display.CENTER, size = display.size })
    self:addChild(view)
    local closeLayer = newLayer(display.cx , display.cy , { ap = display.CENTER, color = cc.c4b(0,0,0,175), size = cc.size(display.width, display.height), enable = true  , cb = function()
        if not self.isClose then
            self:runAction(cc.RemoveSelf:create())
            self.isClose = true
        end
    end})
    view:addChild(closeLayer)

    local contentLayer = newLayer(display.cx , display.cy ,
                                  { ap = display.CENTER, size = cc.size(558, 539) })
    view:addChild(contentLayer)

    local swallowLayer = newLayer(0, 0,
                                  { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(558, 539), enable = true })
    contentLayer:addChild(swallowLayer)

    local bgImage = newNSprite(RES_DICT.COMMON_BG_7, 0, 0,
                               { ap = display.LEFT_BOTTOM, tag = 671 })
    bgImage:setScale(1, 1)
    contentLayer:addChild(bgImage)

    local titleBtn = newButton(282, 519, { ap = display.CENTER, n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 673 })
    display.commonLabelParams(titleBtn, fontWithColor(14, { text = __('一键升级'), fontSize = 24, color = '#ffffff' }))
    contentLayer:addChild(titleBtn)
    local tipImage = display.newImageView(_res('ui/common/common_btn_tips.png') , 200, 18)
    titleBtn:addChild(tipImage)
    display.commonUIParams(titleBtn, {cb = function(sender)
        app.uiMgr:ShowIntroPopup({moduleId = '-27'})
    end})
    local kindLayout = newLayer(0, 183,
                                { ap = display.LEFT_BOTTOM, size = cc.size(558, 200) })
    contentLayer:addChild(kindLayout)

    local levelBgImage = newNSprite(RES_DICT.PET_LVUP_BG_CHOICE, 279, 100,
                                    { ap = display.CENTER, tag = 683 })
    levelBgImage:setScale(1, 1)
    kindLayout:addChild(levelBgImage)

    local lineImage = newNSprite(RES_DICT.PET_LVUP_ICO_LINE, 279, 420,
                                 { ap = display.CENTER, tag = 684 })
    lineImage:setScale(1, 1)
    contentLayer:addChild(lineImage)

    local arrowImage = newImageView(RES_DICT.CARD_SKILL_ICO_SWORD, 275, 118,
                                    { ap = display.CENTER, tag = 685, enable = false })
    contentLayer:addChild(arrowImage)

    local leftLabel = newLabel(245, 118,
                               { ap = display.RIGHT_CENTER, color = '#7e6454', text = "", fontSize = 22, tag = 686 })
    contentLayer:addChild(leftLabel)

    local rightLabel = newLabel(306, 118,
                                { ap = display.LEFT_CENTER, color = '#7e6454', text = "", fontSize = 22, tag = 687 })
    contentLayer:addChild(rightLabel)

    local topLabel = newLabel(287, 423,
                              { ap = display.CENTER_BOTTOM, color = '#7c7c7c', text = __('请选择你要消耗的堕神类型'), fontSize = 24, tag = 708 })
    contentLayer:addChild(topLabel)

    local bottomLabel = newLabel(287, 415,
                                 { ap = display.CENTER_TOP, color = '#76553b', text = __('（优先消耗低品质的低级堕神）'), fontSize = 22, tag = 709 })
    contentLayer:addChild(bottomLabel)

    local barImage = newImageView(RES_DICT.CARD_PREVIEW_BG_LOADING_FRAGMENT, 288, 147,
                                  { ap = display.CENTER, tag = 711, enable = false, scale9 = true, size = cc.size(312, 23) })
    contentLayer:addChild(barImage)
    local  petPrograss = display.newImageView(RES_DICT.CARD_PREVIEW_ICO_LOADING_FRAGMENT_NOT , 0, 11.5,{ap = display.LEFT_CENTER , scale9 = true,size =  cc.size(312, 23)})
    barImage:addChild(petPrograss)


    local prograssLabel = newLabel(156, 11,
                                   { ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 717 })
    barImage:addChild(prograssLabel,10)

    local upgradeBtn = newButton(268, 52, fontWithColor(14, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 718 , cb = handler(self,self.OneKeyClick) }))
    display.commonLabelParams(upgradeBtn, fontWithColor(14, { text =  __('一键升级'), fontSize = 24, color = '#ffffff' }))
    contentLayer:addChild(upgradeBtn)
    local kindTable = {
        {image = RES_DICT.COMMON_FRAME_GOODS_1 , tag = 1 , pos =cc.p(150 -30 , 100) },
        {image = RES_DICT.COMMON_FRAME_GOODS_3 , tag = 2  , pos = cc.p(279, 100)  },
        {image = RES_DICT.COMMON_FRAME_GOODS_4 , tag = 3,pos = cc.p(408 + 30 , 100)},
    }
    local  selectTable = {}
    for i, v in ipairs(kindTable) do
        local selectLayout = newLayer(93, 100,
                                      { ap = display.CENTER, color = cc.r4b(0), size = cc.size(108, 108), enable = true , cb =handler(self, self.SelectBtn) })
        kindLayout:addChild(selectLayout)
        selectLayout:setTag(v.tag)
        selectLayout:setPosition(v.pos)
        local kindImage = newNSprite(v.image ,  0, 0,
                                     { ap = display.LEFT_BOTTOM, tag = 676 })
        kindImage:setScale(1, 1)
        selectLayout:addChild(kindImage)
        kindImage:setName("kindImage")

        local selectImage = newNSprite(RES_DICT.PET_LVUP_ICO_CHOICE_NUM, 53, 53,
                                       { ap = display.CENTER, tag = 680 })
        selectImage:setScale(1, 1)
        selectLayout:addChild(selectImage)
        selectImage:setName("selectImage")
        selectImage:setVisible( self.selectTable[i] == 1)

        local kindNum = newLabel(54, -15,
                                 { ap = display.CENTER, color = '#5c5c5c', text = "", fontSize = 22, tag = 681 })
        selectLayout:addChild(kindNum)
        kindNum:setName("kindNum")
        selectTable[i] = selectLayout
    end
    self.viewData =  {
        closeLayer    = closeLayer,
        contentLayer  = contentLayer,
        swallowLayer  = swallowLayer,
        bgImage       = bgImage,
        titleBtn      = titleBtn,
        kindLayout    = kindLayout,
        levelBgImage  = levelBgImage,
        lineImage     = lineImage,
        arrowImage    = arrowImage,
        leftLabel     = leftLabel,
        rightLabel    = rightLabel,
        topLabel      = topLabel,
        bottomLabel   = bottomLabel,
        barImage      = barImage,
        prograssLabel = prograssLabel,
        upgradeBtn    = upgradeBtn,
        selectTable    = selectTable,
        petPrograss   = petPrograss
    }
end
function PetOneKeyUpgradeView:UpdatePetNum()
    local pets = app.gameMgr:GetUserInfo().pets
    local petConfig = CommonUtils.GetConfigAllMess('pet','pet')
    -- 统计可以以熔炼宠物的数量
    local kindTableNum = {
        0,0,0
    }
    local petOneConfig = nil
    local petType = 1
    for id , petData in pairs(pets) do
        if checkint(petData.isProtect) ~= 1 and self.id  ~=  checkint(petData.id)
        and  checkint(petData.playerCardId) == 0  and checkint(petData.breakLevel) <= 0  then
            petOneConfig = petConfig[tostring(petData.petId)]
            petType = checkint(petOneConfig.type)
            kindTableNum[petType] = kindTableNum[petType] +1
        end
    end
    for i, selectLayout  in ipairs(self.viewData.selectTable) do
        local kindNum = selectLayout:getChildByName("kindNum")
        display.commonLabelParams(kindNum , {text = string.format(__('数量：%d') ,kindTableNum[i] )})
        if kindTableNum[i]  == 0  then
            local selectImage = selectLayout:getChildByName("selectImage")
            selectImage:setVisible(false)
            self.selectTable[i] = 0
        end
    end
    self.kindNumTable = kindTableNum
end
function PetOneKeyUpgradeView:SelectBtn(sender)
    local tag = sender:getTag()
    local maxLevel  = petMgr.GetPetMaxLevel()
    if self.curLevel >= maxLevel   then
        app.uiMgr:ShowInformationTips(__('该堕神已达到最大等级'))
        return
    end
    if self.preLevel == maxLevel and self.selectTable[tag] == 0   then
        local petLevelConfig = CommonUtils.GetConfigAllMess('level' , 'pet')
        local totalExp = checkint(petLevelConfig[tostring(maxLevel)].totalExp)
        if  checkint(self.preExp)  >= totalExp  then
            app.uiMgr:ShowInformationTips(__('堕神的已达到最大的值'))
            return
        end
    end
    if  checkint(self.kindNumTable[tag]) >  0  then

        local callfunc= function()
            self.selectTable[tag] = self.selectTable[tag] == 0 and  1 or 0
            local selectImage = sender:getChildByName("selectImage")
            selectImage:setVisible(self.selectTable[tag] == 1)
            self:UpgrageCallBack()
        end
        if tag ~= 3  then
            callfunc()
        else
            if self.selectTable[tag] == 1 then
                callfunc()
            else
                app.uiMgr:AddCommonTipDialog({callback = callfunc , descr = __('你勾选了稀有紫色堕神作为升级消耗材料')} )
            end
        end

    else
        app.uiMgr:ShowInformationTips(__('暂无该种类的堕神'))
    end
end
function PetOneKeyUpgradeView:UpgrageCallBack()
    local pets = app.gameMgr:GetUserInfo().pets
    local petConfig = CommonUtils.GetConfigAllMess('pet','pet')
    -- 统计可以以熔炼宠物的数量
    local petOneConfig = nil
    local petType = 1
    local consumeTable = {
        ["1"] = {} ,
        ["2"] = {} ,
        ["3"] = {}
    }
    for id , petData in pairs(pets) do
        if checkint(petData.isProtect) ~= 1  and self.id  ~=  checkint(petData.id)
        and  checkint(petData.playerCardId) == 0  and  checkint(petData.breakLevel)  <= 0  then
            petOneConfig = petConfig[tostring(petData.petId)]
            petType = checkint(petOneConfig.type)
            if self.selectTable[petType]  == 1 then
                consumeTable[tostring(petType)][#consumeTable[tostring(petType)]+1] = petData
            end
        end
    end
    for petType, kindPetData in pairs(consumeTable) do
        if table.nums(kindPetData) > 0  then
            table.sort(kindPetData , function(aPetData, bPetData)
                if checkint(aPetData.level) >= checkint(bPetData.level) then
                    return false
                end
                return true
            end)
        end
    end

    local isSelect = false
    local selectTable =  {}
    local level =  pets[tostring(self.id)].level
    local maxLevel  = petMgr.GetPetMaxLevel()
    if checkint(level) ==  maxLevel then
        return
    end
    local curExp =  pets[tostring(self.id)].exp
    local preExp = curExp
    local petLevelConfig = CommonUtils.GetConfigAllMess('level' , 'pet')
    local maxExp = petLevelConfig[tostring(maxLevel)].totalExp
    for i = 1, 3 do
        if table.nums(consumeTable[tostring(i)]) > 0  then
            for index, petData  in ipairs(consumeTable[tostring(i)]) do
                local deltaExp = petMgr.GetPetExpByPetIdAndLevel(checkint(petData.petId), checkint(petData.level))
                selectTable[#selectTable+1] = petData.id
                preExp = deltaExp + preExp
                if maxExp <=  preExp then
                    isSelect = true
                    break
                end
            end
        end
        if isSelect then
            break
        end
    end
    self.oneKeyTable = selectTable
    self:RefreshPrograss( checkint(preExp) ,  checkint(level)  )
end
function PetOneKeyUpgradeView:GetPreLevelByExp(exp)
    local petLevelConfig = CommonUtils.GetConfigAllMess('level' , 'pet')
    local maxLevel  = petMgr.GetPetMaxLevel()
    for i = 1 , maxLevel do
        local totalExp =  petLevelConfig[tostring(i)].totalExp
        if  checkint(totalExp) >  checkint(exp)   then
            return  i  , petLevelConfig[tostring(i)]
        end
    end
    return maxLevel ,  petLevelConfig[tostring(maxLevel)]
end
function PetOneKeyUpgradeView:RefreshPrograss( preExp , curLevel   )
    local preLevel ,petOneConfig = self:GetPreLevelByExp(preExp)
    local preTotalExp = petOneConfig.totalExp
    local exp = petOneConfig.exp
    local lastTotalExp = preTotalExp - exp
    local value =  preExp - lastTotalExp
    local viewData = self.viewData
    if curLevel > preLevel then
        preLevel =  curLevel
    end
    self.preExp = checkint(preExp)
    self.preLevel =  preLevel
    display.commonLabelParams(viewData.leftLabel , {text = string.format(__('等级%d') , curLevel )  })
    display.commonLabelParams(viewData.rightLabel , {text =string.format(__('等级%d') , value > exp and  preLevel  or preLevel - 1 )   })
    local scaleSizeX = value/ exp <1 and value/ exp or 1
    if scaleSizeX < 0.4  then
        viewData.petPrograss:setContentSize( cc.size(312 , 23))
        viewData.petPrograss:setScaleX(scaleSizeX)
    else
        viewData.petPrograss:setScaleX(1)
        viewData.petPrograss:setContentSize( cc.size(312*scaleSizeX , 23))
    end
    display.commonLabelParams(viewData.prograssLabel , {text = string.format('%d/%d' ,value ,  exp)})
end

function PetOneKeyUpgradeView:OneKeyClick(sender)
    if table.nums(self.oneKeyTable) > 0   then
        local consumeStr =  table.concat(self.oneKeyTable , ",")

        app:DispatchSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLevelUp ,{playerPetId = self.id, petFoods = consumeStr })
        self:runAction(cc.RemoveSelf:create())
        self.isClose = true
    else
        app.uiMgr:ShowInformationTips(__('请勾选堕神'))
    end
end
return PetOneKeyUpgradeView
