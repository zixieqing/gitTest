---@class ArtifactDetailView
local ArtifactDetailView = class('home.ArtifactDetailView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    --CLayout:create(cc.size(400,))
    node.name = 'Game.views.ArtifactDetailView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local TALENT_TYPE = {
    SMALL_TALENT =1 , -- 小技能天赋
    GEM_TANLENT = 2   -- 宝石技能天赋
}

function ArtifactDetailView:ctor(param)
    param = param or {}
    self.playerCardId = param.playerCardId
    self.isClick = (param.isClick == nil and true) or param.isClick
    if self.playerCardId then
        self.cardData =gameMgr:GetCardDataById(self.playerCardId) or {}
    else
        self.cardData = param.cardData
    end

    self.isAction = false
    self:initUI()
    self:UpdateUI()
end

function ArtifactDetailView:initUI()
    local closeLayer = display.newLayer(display.cx, display.cy , 
            {ap = display.CENTER , size = display.size  , color = cc.c4b(0,0,0,0) ,enable = true ,
         cb = handler(self, self.ExitAnimation) })
    self:addChild(closeLayer)
    local width = 508
    local bgSize = cc.size(width , display.height)
    local swallowLayer = display.newLayer(display.SAFE_L , display.height/2  ,
                  {ap = display.LEFT_CENTER  , size = display.size  , color1 = cc.c4b(0,0,0,0) , enable = true })
    self:addChild(swallowLayer)
    local bgLayout = display.newLayer(display.SAFE_L -5, display.height/2  ,
                                      {ap = display.LEFT_CENTER  , size = display.size  , color1 = cc.c4b(0,0,0,0)})
    self:addChild(bgLayout)
    bgLayout:setVisible(false)
    self.bgLayout = bgLayout

    -- 背景图片
    local bgImage = display.newImageView(_res('ui/artifact/core_info_bg') ,bgSize.width/2 , bgSize.height/2 ,
    {scale9 = true , size = cc.size(bgSize.width  , bgSize.height +25)  })

    bgLayout:addChild(bgImage)

    --- 神器详情的listview
    local listSize = cc.size(width -40 ,display.height -15)
    local artifactDetailList = CListView:create(listSize)
    artifactDetailList:setDirection(eScrollViewDirectionVertical)
    artifactDetailList:setAnchorPoint(display.CENTER )
    artifactDetailList:setPosition(bgSize.width/2 -12, bgSize.height/2)
    bgLayout:addChild(artifactDetailList)
    self.listSize = listSize

    local topSize =  cc.size(listSize.width, 640)
    local topLayer = display.newLayer(0,0 , { size = topSize , color1 =cc.r4b()})
    artifactDetailList:insertNodeAtLast(topLayer)

    local talentPointBg = display.newImageView(_res('ui/artifact/core_info_bg_point_actived'))
    local talentPointBgSize = talentPointBg:getContentSize()
    talentPointBg:setPosition(talentPointBgSize.width/2 , talentPointBgSize.height/2)

    local talentPointLayer = display.newLayer(topSize.width/2 , topSize.height -10 , {ap = display.CENTER_TOP ,color1 = cc.r4b() , size = talentPointBgSize })
    talentPointLayer:addChild(talentPointBg)
    topLayer:addChild(talentPointLayer)

    local talentLabel = display.newLabel(talentPointBgSize.width/2 ,  talentPointBgSize.height/4*3 , fontWithColor('10',{color = "#8d6547", text = __('当前已激活的节点')}))
    talentPointLayer:addChild(talentLabel)
    -- 收集天赋的进度
    local talentPrograssLabel =  cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
    talentPrograssLabel:setPosition(talentPointBgSize.width/2 ,  talentPointBgSize.height/4)
    talentPointLayer:addChild(talentPrograssLabel)

    local coreTitle = display.newButton(topSize.width/2 , topSize.height - 110,{ n = _res('ui/common/common_title_6'), enable = false })
    topLayer:addChild(coreTitle)
    display.commonLabelParams(coreTitle , fontWithColor('10' , {color = '#ffffff' , text = __('核心属性')}))

    local attributeBg = display.newImageView(_res('ui/artifact/core_info_bg_attribute'))
    local attributeBgSize = attributeBg:getContentSize()
    attributeBg:setPosition(attributeBgSize.width/2 , attributeBgSize.height/2)


    local attrLayout = display.newLayer(topSize.width/2 , topSize.height -135 , {ap = display.CENTER_TOP ,color1 = cc.r4b() , size = attributeBgSize})
    topLayer:addChild(attrLayout)
    attrLayout:addChild(attributeBg)

    local propertyData = {
        {pName = ObjP.ATTACK, 	    name = __('攻击力'),path = 'ui/common/role_main_att_ico.png' , attrNameColor = '#ffffff' ,attrNumColor = '#ffc438' },
        {pName = ObjP.DEFENCE, 	    name = __('防御力'),path = 'ui/common/role_main_def_ico.png', attrNameColor = '#e0cabe' ,attrNumColor = '#e0cabe' },
        {pName = ObjP.HP, 	        name = __('生命值'),path = 'ui/common/role_main_hp_ico.png', attrNameColor = '#e0cabe' ,attrNumColor = '#e0cabe' },
        {pName = ObjP.CRITRATE, 	name = __('暴击率'),path = 'ui/common/role_main_baoji_ico.png', attrNameColor = '#ffffff' ,attrNumColor = '#ffc438'},
        {pName = ObjP.CRITDAMAGE, 	name = __('暴击伤害'),path = 'ui/common/role_main_baoshangi_ico.png', attrNameColor = '#e0cabe' ,attrNumColor = '#e0cabe' },
        {pName = ObjP.ATTACKRATE, 	name = __('攻击速度'),path = 'ui/common/role_main_speed_ico.png', attrNameColor = '#e0cabe' ,attrNumColor = '#e0cabe' }
    }

    local distanceY = 10
    local lineDiatance = 40
    local  propertyCount = #propertyData
    -- 添加横线
    for i = 1, propertyCount+1 do
        local lineImage = display.newImageView(_res('ui/cards/propertyNew/card_ico_attribute_line.png'))
        lineImage:setPosition(attributeBgSize.width/2 , attributeBgSize.height - (i-1) * lineDiatance -distanceY)
        attrLayout:addChild(lineImage , 3)
    end
    -- 添加横线的labe
    for i = 1, propertyCount do
        if i % 2 == 0 then
            local bg = display.newImageView(_res('ui/common/card_bg_attribute_number.png'))
            bg:setPosition(attributeBgSize.width/2 , attributeBgSize.height - (i-0.5 ) * lineDiatance -distanceY)
            attrLayout:addChild(bg , 1)
        end
    end
    local propertyTable = {}
    for i = 1, propertyCount do
        propertyTable[i] = {}
    end
    -- 添加具体的属性
    for i = 1, propertyCount do
        local data = propertyData[i]
        local image = display.newImageView(data.path , 50 , attributeBgSize.height - (i-0.5 ) * lineDiatance -distanceY )
        attrLayout:addChild(image,2)
        local nameLabel  = display.newLabel(90,attributeBgSize.height - (i-0.5 ) * lineDiatance -distanceY ,
                fontWithColor('10', {text = data.name , ap = display.LEFT_CENTER ,color =data.attrNameColor }) )
        attrLayout:addChild(nameLabel,2)
        propertyTable[i].nameLabel = nameLabel
        local propertyLabel  = display.newLabel(408,attributeBgSize.height - (i-0.5 ) * lineDiatance -distanceY ,
                                            fontWithColor('10', {text = "0" ,  ap = display.RIGHT_CENTER ,color =data.attrNumColor }) )
        propertyTable[i].propertyLabel = propertyLabel
        attrLayout:addChild(propertyLabel,2)
    end

    local bassOneEffectImage  = display.newImageView(_res('ui/artifact/core_info_bg_skill_lock'), attributeBgSize.width/2 , attributeBgSize.height -274, {ap =display.CENTER_TOP ,enable = true ,cb = function()
        app.uiMgr:ShowInformationTips(__('对应节点未解锁'))
    end })
    attrLayout:addChild(bassOneEffectImage)
    if not  self.isClick then
        bassOneEffectImage:setTouchEnabled(false)
    end
    local bassOneEffectImageSize = bassOneEffectImage:getContentSize()
    local bassOneLabel = display.newLabel(bassOneEffectImageSize.width/2 ,bassOneEffectImageSize.height -10 , fontWithColor('10', {color = '#ffffff', ap = display.CENTER_TOP , text = "", hAlign = display.TAC,w = 400}) )
    bassOneEffectImage:addChild(bassOneLabel)
    -- 锁定的
    local lockImage = display.newImageView(_res('ui/common/common_ico_lock') , bassOneEffectImageSize.width/2 , bassOneEffectImageSize.height/2)
    bassOneEffectImage:addChild(lockImage)
    lockImage:setName("lockImage")


    local bassTwoEffectImage  = display.newImageView(_res('ui/artifact/core_info_bg_skill_lock'), attributeBgSize.width/2 , attributeBgSize.height -360, {ap =display.CENTER_TOP , enable = true ,cb = function()
                     app.uiMgr:ShowInformationTips(__('对应节点未解锁'))
    end })
    attrLayout:addChild(bassTwoEffectImage)
    if not  self.isClick then
        bassTwoEffectImage:setTouchEnabled(false)
    end
    local bassTwoLabel = display.newLabel(bassOneEffectImageSize.width/2 ,bassOneEffectImageSize.height -10 ,fontWithColor('10', {color = '#ffffff', ap = display.CENTER_TOP ,text = "", hAlign =display.TAC ,w = 400 }) )
    bassTwoEffectImage:addChild(bassTwoLabel)
    local lockImage = display.newImageView(_res('ui/common/common_ico_lock') , bassOneEffectImageSize.width/2 , bassOneEffectImageSize.height/2)
    bassTwoEffectImage:addChild(lockImage)
    lockImage:setName("lockImage")



    local gemTitle = display.newButton(topSize.width/2 , 0 ,{ n = _res('ui/common/common_title_6') , ap = display.CENTER_BOTTOM ,enable = false  })
    topLayer:addChild(gemTitle)
    display.commonLabelParams(gemTitle , fontWithColor('10' , {color = '#ffffff' , text = __('塔可效果')}))

    self.viewData = {
        artifactDetailList = artifactDetailList ,
        talentPrograssLabel = talentPrograssLabel,
        propertyTable = propertyTable ,
        bassOneEffectImage = bassOneEffectImage ,
        bassTwoEffectImage = bassTwoEffectImage  ,
        bassTwoLabel = bassTwoLabel ,
        bassOneLabel = bassOneLabel
    }

end

function ArtifactDetailView:CeateEquipGemCell()
    local listSize = self.listSize
    local cellSize = cc.size(listSize.width , 183)
    local contentSize = cc.size(460,175)

    local cell  = display.newLayer(cellSize.width/2 , cellSize.height/2 ,
                                          {ap = display.CENTER , size = cellSize})
    local contentLayer = display.newLayer(cellSize.width/2 , cellSize.height -10  ,
                                          {size = contentSize ,ap = display.CENTER_TOP } )
    cell:addChild(contentLayer)
    local bgImage = display.newImageView(_res('ui/common/common_bg_list'),
                                         contentSize.width/2 , contentSize.height ,{scale9 = true , size = contentSize , ap = display.CENTER_TOP })
    contentLayer:addChild(bgImage)

    local goodNode = require("common.GoodNode").new({goodsId = DIAMOND_ID})
    goodNode:setPosition(10, contentSize.height -5 )
    goodNode:setAnchorPoint(display.LEFT_TOP)
    contentLayer:addChild(goodNode,2)
    goodNode:setScale(0.9)

    local gemcolor = display.newImageView(_res('ui/artifact/core_info_bg_name_1') ,103 , contentSize.height -23, {ap = display.LEFT_CENTER} )
    contentLayer:addChild(gemcolor)

    local gemLabel = display.newLabel(115, contentSize.height- 23 , fontWithColor('14' , { text = "aaaa" , ap =display.LEFT_CENTER }))
    contentLayer:addChild(gemLabel)

    local effectLabel = display.newLabel(115 ,contentSize.height-42 , fontWithColor('10' , {ap = display.LEFT_TOP ,text = "好哈11" , color = "#7b5f52"  , w = 360}) )
    contentLayer:addChild(effectLabel)

    local effectDescr = display.newLabel(10 , contentSize.height-105 ,
    fontWithColor('15',{text = " ", ap = display.LEFT_TOP , hAlign = display.TAL , w = 430   }))
    contentLayer:addChild(effectDescr)
    cell.contentLayer = contentLayer
    cell.goodNode = goodNode
    cell.gemLabel = gemLabel
    cell.effectLabel = effectLabel
    cell.effectDescr = effectDescr
    cell.gemcolor = gemcolor
    cell.bgImage = bgImage
    return cell
end

function ArtifactDetailView:CreateNotEquipGemCell()
    local listSize = self.listSize
    local cellSize = cc.size(listSize.width , 86)
    local cell = display.newLayer(cellSize.width/2 , cellSize.height/2 ,
                                  {ap = display.CENTER , size = cellSize})
    local contentSize = cc.size(560,170)
    local contentLayer = display.newLayer(cellSize.width/2 , cellSize.height/2 ,{size = contentSize , ap = display.CENTER })
    cell:addChild(contentLayer)
    -- 背景图片
    local bgImage  = display.newImageView(_res('ui/artifact/core_info_bg_effect_lock_1'),contentSize.width/2 ,contentSize.height/2 , {ap = display.CENTER})
    contentLayer:addChild(bgImage)

    local unlockLayout = display.newLayer(cellSize.width/2 , cellSize.height/2 ,{size = contentSize , ap = display.CENTER })
    cell:addChild(unlockLayout)
    unlockLayout:setVisible(false)

    local notTipsLabel = display.newLabel(contentSize.width/2 , contentSize.height/2 ,
          fontWithColor('10',{ap = display.CENTER , text = __('未添加对应的塔可' ) , color = "#8f6d53"}))
    unlockLayout:addChild(notTipsLabel)

    --local richLabel =  display.newRichLabel(contentSize.width/2,50 , { ap = display.CENTER_BOTTOM ,
    --    c = {
    --        fontWithColor('15', {text = __('可以去塔可节点添加')})
    --    },
    --    r = true
    --})
    --unlockLayout:addChild(richLabel)


    local lockBg = display.newButton(  contentSize.width/2 , contentSize.height/2 , {n = _res('ui/artifact/core_put_bg_name'), cb = function()
        app.uiMgr:ShowInformationTips(__('对应塔可节点未解锁'))
    end} )
    if not self.isClick then
        lockBg:setEnabled(false)
    end
    display.commonLabelParams(lockBg, fontWithColor(10 , {text = __('暂未解锁') , color = "#ffe9d8" }))
    contentLayer:addChild(lockBg)

    local lockImage = display.newImageView(_res('ui/common/common_ico_lock'), -5 , 33/2+5)
    lockBg:addChild(lockImage)
    cell.unlockLayout = unlockLayout
    cell.lockBg = lockBg
    cell.contentLayer = contentLayer
    cell.bgImage = bgImage
    --cell.richLabel = richLabel

    return cell
end



function ArtifactDetailView:UpdateUI()
    local viewData = self.viewData
    local artifactTalent = self.cardData.artifactTalent or {}
    local talentOnePointConfig = artifactMgr:GetTalentIdPointConfigByCardId(self.cardData.cardId)
    local gemSkill = {
        equip = {},
        unlock = {},
        lock = {}
    }
    local keys = table.keys(talentOnePointConfig)
    for  i = 1, #keys do
        keys[i] = checkint(i)
    end
    table.sort(keys , function(a , b )
        if  a >= b  then
            return false
        end
        return true
    end)
    for index  = 1, #keys  do
        local  i = keys[index]
        print(" i = " , i)
        local v = talentOnePointConfig[tostring(i)]
        local data =  artifactTalent[tostring(i)] or {}
        if checkint(v.style) == TALENT_TYPE.GEM_TANLENT then
            if  checkint(data.level) > 0 and checkint(data.gemstoneId) > 0   then
                gemSkill.equip[#gemSkill.equip+1]  =  i
            elseif checkint(data.level) > 0   then
                gemSkill.unlock[#gemSkill.unlock+1] = i
            elseif checkint(data.level) == 0   then
                gemSkill.lock[#gemSkill.lock+1] = i
            end
        end
    end
    for i, v in pairs(gemSkill.equip) do
        local cell = self:CeateEquipGemCell()
        self:UpdateEqiupCell(cell, v )
        viewData.artifactDetailList:insertNodeAtLast(cell)
    end
    for i, v in pairs(gemSkill.unlock) do
        local cell = self:CreateNotEquipGemCell()
        self:UpdateNotEqiupCell(cell, v )
        viewData.artifactDetailList:insertNodeAtLast(cell)
    end
    for i, v in pairs(gemSkill.lock) do
        local cell = self:CreateNotEquipGemCell()
        self:UpdateNotEqiupCell(cell, v )
        viewData.artifactDetailList:insertNodeAtLast(cell)
    end

    self.viewData.artifactDetailList:reloadData()
    self:UpdateBaseAttrAdd()
    self:UpdateElement()
    self:EnterAnimation()
end

function ArtifactDetailView:UpdateElement()
    local viewData = self.viewData
    local propertyTable = viewData.propertyTable
    local bassSkill = {
        {
            effectImage = viewData.bassOneEffectImage,
            lockImage   = viewData.bassOneEffectImage:getChildByName("lockImage"),
            bassLabel   = viewData.bassOneLabel ,
        },
        {
            effectImage = viewData.bassTwoEffectImage,
            lockImage   = viewData.bassTwoEffectImage:getChildByName("lockImage"),
            bassLabel   = viewData.bassTwoLabel
        }
    }
    local attrTable = artifactMgr.GetArtifactTalentAllFixedPByCardData(self.cardData)
    local artifactTalentSkill = artifactMgr:GetArtifactTalentUnLockSkillIdByCardData(self.cardData)
    for i, v in pairs(propertyTable) do
        v.propertyLabel:setString( tostring( attrTable[ tostring(i)]))
    end
    dump(artifactTalentSkill)
    for i, v in pairs(artifactTalentSkill) do
        if  i <= 2  then
            local descr  = cardMgr.GetSkillDescr(v)
            bassSkill[i].lockImage:setVisible(false)
            bassSkill[i].bassLabel:setString(descr)
            bassSkill[i].effectImage:setTouchEnabled(false)
        else
            bassSkill[i].lockImage:setVisible(true)
            bassSkill[i].effectImage:setTouchEnabled(true)
        end

    end
end

--[[
    进入动画
--]]
function ArtifactDetailView:EnterAnimation()
    local bgLayout = self.bgLayout
    local bgLayoutPos = cc.p(bgLayout:getPosition())
    local startPos = cc.p(bgLayoutPos.x - 600 , bgLayoutPos.y)
    bgLayout:runAction(cc.Sequence:create(
        cc.CallFunc:create(
            function()
                bgLayout:setVisible(true )
                bgLayout:setPosition(startPos)
                bgLayout:setOpacity(0 )
            end),
        cc.Spawn:create(
            cc.EaseSineOut:create(
                    cc.MoveTo:create(0.4, bgLayoutPos)
            ),
            cc.FadeIn:create(0.4)
        ),
        cc.CallFunc:create(function()
            self.isAction = true
        end
        )
    ))
end
function ArtifactDetailView:ExitAnimation()
    if self.isAction  then
        self.isAction = false
        local bgLayout = self.bgLayout
        self:runAction(
            cc.Sequence:create(
                cc.TargetedAction:create(bgLayout ,
                    cc.Spawn:create(
                        cc.EaseSineIn:create(cc.MoveBy:create(0.2, cc.p(-600 , 0 ))) ,
                        cc.FadeOut:create(0.2)
                    )
                ),
                cc.RemoveSelf:create()
            )
        )
    end
end
--[[
    更新基本属性的加成
--]]
function ArtifactDetailView:UpdateBaseAttrAdd()
    local viewData = self.viewData
    local allPoint = artifactMgr:GetCardArtifactAllPoint(self.cardData.cardId)
    local allActivationPoint =  artifactMgr:GetCardArtifactAllActivaionPointCardData(self.cardData)
    --artifactMgr:GetCardArtifactAllActivationPoint(self.cardData.id)
    local talentPrograssLabel = viewData.talentPrograssLabel
    talentPrograssLabel:setString(string.format("%d/%d" , allActivationPoint , allPoint))
end
--[[
    更新已经装备的cell
--]]
function ArtifactDetailView:UpdateEqiupCell(cell , talentId)
    local artifactTalent = self.cardData.artifactTalent or {}
    local data = artifactTalent[tostring(talentId)] or {}

    local cardId = checkint(self.cardData.cardId)
    local gemstoneId = checkint(data.gemstoneId)

    local talentConfig = artifactMgr.GetCardTalentConfig(cardId, checkint(talentId))
    local gemstoneConfig = artifactMgr.GetGemstoneConfig(gemstoneId)

    if nil ~= talentConfig and nil ~= gemstoneConfig then

        local goodNode = cell.goodNode
        local gemLabel = cell.gemLabel
        local gemcolor = cell.gemcolor
        local effectLabel = cell.effectLabel
        local effectDescr = cell.effectDescr

        -- 刷新宝石颜色
        local color = checkint(talentConfig.gemstoneColor[1]) > 0 and checkint(talentConfig.gemstoneColor[1]) or 1
        gemcolor:setTexture(_res( string.format("ui/artifact/core_info_bg_name_%d", color)))

        -- 刷新道具node
        goodNode:RefreshSelf({goodsId = gemstoneId})

        -- 刷新宝石名字
        display.commonLabelParams(gemLabel, fontWithColor('14', {text = gemstoneConfig.name}))

        -- 刷新宝石的效果描述
        display.commonLabelParams(effectLabel, fontWithColor('10', {
            text = artifactMgr.GetGemstonePropertyAdditionDescr(gemstoneId), color = '#7b5f52', fontSize = 22
        }))

        -- 刷新宝石激活的技能效果描述
        local activeSkillId = artifactMgr.GetArtifactTalentInnateSkill(cardId, talentId, nil, gemstoneId)
        local activeSkillDescr = cardMgr.GetSkillDescr(activeSkillId)
        display.commonLabelParams(effectDescr, fontWithColor('15', {text = activeSkillDescr}))

        -- 适配描述背景大小
        local labelSize = display.getLabelContentSize(effectDescr)
        if labelSize.height > 65 then
            local bgImage = cell.bgImage
            local contentLayer = cell.contentLayer
            local bgImageSize = bgImage:getContentSize()
            local cellSize = cell:getContentSize()
            local pos = cc.p( contentLayer:getPosition())

            local height = labelSize.height - 65
            cell:setContentSize(cc.size(cellSize.width , cellSize.height + height))
            bgImage:setContentSize(cc.size(bgImageSize.width,bgImageSize.height + height ))
            contentLayer:setPosition(pos.x , pos.y + height)
        end
    end
end
--[[
    更新未解锁或者是未装备的cell
--]]
function ArtifactDetailView:UpdateNotEqiupCell(cell , talentId)
    local artifactTalent = self.cardData.artifactTalent or {}
    local talentOnePointConfig = artifactMgr:GetTalentIdPointConfigByCardId(self.cardData.cardId)
    local talentOneData = talentOnePointConfig[tostring(talentId)]
    local  data = artifactTalent[tostring(talentId)] or {}
    local lockBg  = cell.lockBg
    local bgImage = cell.bgImage
    local color = checkint(talentOneData.gemstoneColor[1]) > 0 and checkint(talentOneData.gemstoneColor[1])  or 1
    local unlockLayout = cell.unlockLayout
    local isUnlock = checkint(data.level ) ==  0 and true or false
    lockBg:setVisible(isUnlock)
    unlockLayout:setVisible(not isUnlock)
    bgImage:setTexture(_res( string.format("ui/artifact/core_info_bg_effect_lock_%d",color)))
    if isUnlock  then
        bgImage:setTouchEnabled(true)
        display.commonUIParams(bgImage , {cb = function()
                                          app.uiMgr:ShowInformationTips(__('对应塔可节点未解锁'))
        end})
    end
    if not self.isClick then
        bgImage:setTouchEnabled(false)
    end
end





return ArtifactDetailView
