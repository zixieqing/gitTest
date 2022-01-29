--[[
    卡牌预览展示界面
    @params table {
        confId int 卡牌id
        skinId int 皮肤id
        cardDrawChangeType  int 立绘切换类型 （1： 立绘只能切换为默认卡牌皮肤或突破后的皮肤 2: 所有卡牌皮肤都可切换 ）
    }
--]]
---@class CardPreviewView
local CardPreviewView = class('CardPreviewView', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.CardPreviewView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    CARD_CONTRACT_BG_MEMORY           = _res('ui/cards/marry/card_contract_bg_memory.jpg'),
    PET_INFO_ICO_EXCLUSIVE_PET_NORMAL = _res('ui/cards/petNew/pet_info_ico_exclusive_pet_normal.png'),
    CARD_ATTRIBUTE_BG_NAME            = _res('ui/cards/propertyNew/card_attribute_bg_name.png'),
    CARD_SKILL_BG_SKILL               = _res('ui/cards/skillNew/card_skill_bg_skill.png'),
    COMMON_BTN_BACK                   = _res('ui/common/common_btn_back.png'),
    COMMON_TITLE_5                    = _res('ui/common/common_title_5.png'),
    PREVIEW_CARD_LINE_1               = _res('ui/common/preview_card_line_1.png'),
    PREVIEW_CARD_LABEL_RARE           = _res('ui/common/preview_card_label_rare.png'),
    CARD_CONTRACT_LABEL_TEXT_BG       = _res('ui/cards/marry/card_contract_label_text_bg')
}

local CreateView       = nil
local CreateSkillCell  = nil
local CreateQAavatar   = nil
local CreateCardDraw   = nil

function CardPreviewView:ctor(...)
    local args = unpack({...}) or {}
    self.cardDrawChangeType = args.cardDrawChangeType or 1
    self.aniIndex = 1
    self:InitUI()
    self:RefreshUI(args)
end

function CardPreviewView:InitUI()
    xTry(function ( )
		self.viewData = CreateView()
        self:addChild(self.viewData.view)
        self:InitView()
	end, __G__TRACKBACK__)
end

function CardPreviewView:IninValue(args)
    self.curSelectSkinIndex = 1
    self.confId = nil
    if args.confId then
        self.confId = args.confId
    elseif args.skinId then
        self.confId = CardUtils.GetCardIdBySkinId(args.skinId)        
    end

    self.cardDatas = CardUtils.GetCardConfig(self.confId) or {}
    self.skinDatas = self:InitSkinDatasByType(self.cardDrawChangeType, self.cardDatas)
    self.maxSelectSkinIndex = #self.skinDatas
    self.skillDatas = self:InitSkillDatas(self.confId, self.cardDatas)
    
end

function CardPreviewView:InitView()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.backBtn, {cb = handler(self, self.OnCloseViewAction), animate = false})

    display.commonUIParams(viewData.cardDrawTouchView, {cb = handler(self, self.OnClickCardDrawAction)})
    
    display.commonUIParams(viewData.qAvatarLayer, {cb = handler(self, self.OnClickQAvatarAction)})
    
    display.commonUIParams(viewData.exclusiveBtn, {cb = handler(self, self.OnClickExclusiveBtnAction)})
    
    viewData.skillList:setDataSourceAdapterScriptHandler(handler(self, self.OnSkillListDataAdapter))
end

function CardPreviewView:RefreshUI(args)
    self:IninValue(args)
    if self.confId then
        self:UpdateUI()
    end
end

function CardPreviewView:UpdateUI()
    local viewData = self:GetViewData()
    local confId   = self.confId

    local cardGrade = viewData.cardGrade
    cardGrade:setTexture(CardUtils.GetCardQualityTextPathByCardId(confId))

    local careerIconBg = viewData.careerIconBg
    careerIconBg:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(confId))

    local careerIcon = viewData.careerIcon
    careerIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(confId))
    
    local cardNameLabel = viewData.cardNameLabel
    display.commonLabelParams(cardNameLabel, {text = tostring(self.cardDatas.name)})
    
    local cvLabel = viewData.cvLabel
    display.commonLabelParams(cvLabel, {text = CommonUtils.GetCurrentCvAuthorByCardId(confId)})

    self:UpdateSkinBySkinIndex(self.curSelectSkinIndex)

    local skillList         = viewData.skillList
    skillList:setCountOfCell(#self.skillDatas)
    skillList:reloadData()
end

--==============================--
--desc: 通过皮肤数据下标更新卡牌皮肤
--@params index int 皮肤数据下标
--@return 
--==============================--
function CardPreviewView:UpdateSkinBySkinIndex(index)
    local skinId = self:GetSkinIdByIndex(self:CheckSkinIndex(index))
    self:UpdateSkinBySkinId(skinId)
end

--==============================--
--desc: 通过皮肤id更新卡牌皮肤
--@params skinId int 皮肤id
--@return 
--==============================--
function CardPreviewView:UpdateSkinBySkinId(skinId)
    self:UpdateCardDraw(skinId)
    self:UpdateCardQAvatar(skinId)
end

--==============================--
--desc: 更新卡牌皮肤
--@params skinId int 皮肤id
--@return 
--==============================--
function CardPreviewView:UpdateCardDraw(skinId)
    local viewData = self:GetViewData()
    local cardDraw = viewData.cardDraw
    if cardDraw == nil then
        cardDraw = CreateCardDraw(skinId)
        viewData.view:addChild(cardDraw)
        viewData.cardDraw = cardDraw
    else
        viewData.cardDraw:RefreshAvatar({skinId = skinId})
    end
end

--==============================--
--desc: 更新q版卡牌
--@params skinId int 皮肤id
--@return 
--==============================--
function CardPreviewView:UpdateCardQAvatar(skinId)
    local viewData = self:GetViewData()
    local qAvatar = viewData.qAvatar
    local qAvatarLayer = viewData.qAvatarLayer
    
    if qAvatar ~= nil then
        qAvatar:runAction(cc.RemoveSelf:create())
        viewData.qAvatar = nil
    end

    local cskinId = checkint(skinId)
    local qAvatar = CreateQAavatar(cskinId)
    qAvatarLayer:setTag(cskinId)
    local qAvatarLayerSize = qAvatarLayer:getContentSize()
    qAvatar:setPosition(cc.p(qAvatarLayerSize.width / 2, 0))
    qAvatarLayer:addChild(qAvatar)

    viewData.qAvatar = qAvatar
end

--==============================--
--desc: 更新技能cell
--@params viewData table cell视图数据
--@params data table     技能数据
--@return 
--==============================--
function CardPreviewView:UpdateSkillCell(viewData, data)
    local skillImg       = viewData.skillImg
    skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(data.skillId)))

    local skillPropertyLabel = viewData.skillPropertyLabel
    display.commonLabelParams(skillPropertyLabel, {text = data.skillPropertyName})

    local skillName      = viewData.skillName
    display.commonLabelParams(skillName, {text = data.skillName})
end

function CardPreviewView:OnCloseViewAction(sender)
    PlayAudioByClickClose()
    local scene = app.uiMgr:GetCurrentScene()
    if scene then
        scene:RemoveDialog(self)
    end
end

function CardPreviewView:OnClickCardDrawAction(sender)
    PlayAudioByClickNormal()
    self:UpdateSkinBySkinIndex(self.curSelectSkinIndex + 1)
end

function CardPreviewView:OnClickQAvatarAction(sender)
    PlayAudioByClickNormal()
    local viewData = self:GetViewData()
    local qAvatar = viewData.qAvatar
    if qAvatar == nil then return end
    local actionList = {
        'idle',
        'run',
        'attack',
        'skill1',
        'skill2'
    }

    if self.aniIndex == 5 then
        self.aniIndex = 1
    end
    self.aniIndex = self.aniIndex + 1
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, actionList[self.aniIndex], true)
    -- qAvatar:setTag(tag)
end


function CardPreviewView:OnClickSkillBtnAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data = self.skillDatas[tag] or {}
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, title = data.skillName, descr = data.skillDescr, 
    sub = data.skillPropertyName, viewTypeData = data.concertSkillTip , type = 16})
end


function CardPreviewView:OnClickExclusiveBtnAction(sender)
    PlayAudioByClickNormal()

    local iconIds = {}
	local sss = string.split(self.cardDatas.exclusivePet, ';')
	for i,v in ipairs(sss) do
		local t = {}
		t.goodsId = v
		t.num = 1
		table.insert(iconIds,t)
    end
    local descrStr
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PET_EVOL) then
        descrStr = string.format(
            __('本命堕神提供的属性额外增加%d%%，异化后可提升至%d%%。'),
            math.floor(PetUtils.GetExclusiveAddition() * 100),
            math.floor(PetUtils.GetExclusiveAddition(nil, 1) * 100)
        )
    else
        descrStr = string.format(
            __('本命堕神提供的属性额外增加%d%%'),
            math.floor(PetUtils.GetExclusiveAddition() * 100)
        )
    end
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender,title = __('专属堕神'),descr = descrStr, showAmount = false,iconIds = iconIds, type = 4})
end

function CardPreviewView:OnSkillListDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local skillList = self:GetViewData().skillList
        pCell = CreateSkillCell(skillList:getSizeOfCell())
        display.commonUIParams(pCell.viewData.skillBtn, {cb = handler(self, self.OnClickSkillBtnAction), animate = false})
    end

    xTry(function()
        local viewData = pCell.viewData
        self:UpdateSkillCell(viewData, self.skillDatas[index])
        viewData.skillBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
    
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newLayer(0,0,{size = size, color = cc.c4b(0,0,0,130), ap = display.LEFT_BOTTOM, enable = true}))

    -- bg
    view:addChild(display.newNSprite(RES_DICT.CARD_CONTRACT_BG_MEMORY, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        scale9 = true, size = cc.size(90, 70),
        enable = true,
    })
    view:addChild(backBtn, 10)

    local cardGradeBg = display.newNSprite(RES_DICT.PREVIEW_CARD_LABEL_RARE, display.SAFE_L, display.height - 144,
    {
        ap = display.LEFT_CENTER,
    })
    view:addChild(cardGradeBg, 1)

    local cardGrade = display.newNSprite('', display.SAFE_L + 88, display.height - 149,
    {
        ap = display.CENTER,
    })
    view:addChild(cardGrade, 1)

    -- card draw
    local cardDrawTouchView = display.newLayer(50 + display.SAFE_L, display.cy, {color = cc.c4b(0,0,0,0), size = cc.size(600, display.height * 0.8), enable = true, ap = display.LEFT_CENTER})
    view:addChild(cardDrawTouchView)
    -- local cardDraw = require( "common.CardSkinDrawNode" ).new({confId = 200012, coordinateType = COORDINATE_TYPE_CAPSULE})
    -- cardDraw:setPositionX(display.SAFE_L)
    -- view:addChild(cardDraw)

    -------------skillPreviewLayer start--------------
    local skillPreviewLayerSize = cc.size(466, 580)
    local skillPreviewLayer = display.newLayer(display.SAFE_R - 121, display.cy + 65,
    {
        ap = display.RIGHT_CENTER,
        size = skillPreviewLayerSize,
        enable = true,
    })
    view:addChild(skillPreviewLayer, 1)

    skillPreviewLayer:addChild(display.newImageView(RES_DICT.CARD_CONTRACT_LABEL_TEXT_BG, skillPreviewLayerSize.width  / 2, skillPreviewLayerSize.height / 2, {scale9 = true, size = skillPreviewLayerSize}))

    local skillPreviewTitle = display.newButton(232, 518,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_TITLE_5,
        scale9 = true, size = cc.size(186, 31),
        enable = false,
    })
    display.commonLabelParams(skillPreviewTitle, {text = __('技能预览'), fontSize = 20, color = '#5b3c25' , paddingW = 20 })
    skillPreviewLayer:addChild(skillPreviewTitle)

    local exclusiveBtn = display.newButton(408, 516,
    {
        ap = display.CENTER,
        n = RES_DICT.PET_INFO_ICO_EXCLUSIVE_PET_NORMAL,
        scale9 = true, size = cc.size(87, 85),
        enable = true,
    })
    display.commonLabelParams(exclusiveBtn, {text = __('专属堕神'), fontSize = 22, color = '#ffd69c', offset = cc.p(0,-34)})
    skillPreviewLayer:addChild(exclusiveBtn)
    


    -- local skillList = CListView:create(cc.size(400, 430))
    -- skillList:setPosition(cc.p(33, 48))
    -- skillList:setAnchorPoint(display.LEFT_BOTTOM)
    -- skillList:setDirection(eScrollViewDirectionVertical)
    -- skillPreviewLayer:addChild(skillList)

    local skillListSize = cc.size(400, 430)
    local skillList = CTableView:create(skillListSize)
    display.commonUIParams(skillList, {po = cc.p(33, 48), ap = display.LEFT_BOTTOM})
    skillList:setDirection(eScrollViewDirectionVertical)
    -- skillList:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    skillList:setSizeOfCell(cc.size(skillListSize.width, 110))
    skillPreviewLayer:addChild(skillList)

    ---------------cardInfoLayer start----------------
    local cardInfoLayer = display.newLayer(display.SAFE_R - 142, 38,
    {
        ap = display.RIGHT_BOTTOM,
        size = cc.size(500, 110),
        enable = true,
    })
    view:addChild(cardInfoLayer, 1)

    cardInfoLayer:addChild(display.newNSprite(RES_DICT.CARD_ATTRIBUTE_BG_NAME, 251, 34, {ap = display.CENTER}))

    local careerIconBg = display.newNSprite('', 57, 56,
    {
        ap = display.CENTER,
    })
    careerIconBg:setScale(1.6, 1.6)
    cardInfoLayer:addChild(careerIconBg)

    local careerIcon = display.newNSprite('', 57, 57,
    {
        ap = display.CENTER,
    })
    careerIcon:setScale(1.1, 1.1)
    cardInfoLayer:addChild(careerIcon)

    local cardNameLabel = display.newLabel(96, 73, fontWithColor(20, {
        ap = display.LEFT_CENTER,
        fontSize = 32,
        color = '#ffcc60',
        outline = '#4b2214',
    }))
    cardInfoLayer:addChild(cardNameLabel)

    local cvLabel = display.newLabel(103, 17,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffe5d7',
    })
    cardInfoLayer:addChild(cvLabel)

    ----------------cardInfoLayer end-----------------
    local qAvatarLayerSize = cc.size(140, 300)
    local qAvatarLayer = display.newLayer(display.SAFE_R - 160, 20, {ap = display.CENTER_BOTTOM, size = qAvatarLayerSize, enable = true, color = cc.c4b(0, 0, 0, 0)})
    view:addChild(qAvatarLayer, 1)

    -- local qAvatar = AssetsUtils.GetCardSpineNode({skinId = 250120, scale = 0.7})
    -- qAvatar:update(0)
    -- qAvatar:setToSetupPose()
    -- qAvatar:setAnimation(0, 'idle', true)
    -- qAvatar:setScaleX(-1)
    -- qAvatar:setPosition(cc.p(qAvatarLayerSize.width / 2, 0))
    -- qAvatarLayer:addChild(qAvatar)

    return {
        view              = view,
        backBtn           = backBtn,
        cardGrade         = cardGrade,
        cardDrawTouchView = cardDrawTouchView,
        skillPreviewTitle = skillPreviewTitle,
        exclusiveBtn      = exclusiveBtn,
        skillList         = skillList,
        careerIconBg      = careerIconBg,
        careerIcon        = careerIcon,
        cardNameLabel     = cardNameLabel,
        cvLabel           = cvLabel,
        qAvatarLayer      = qAvatarLayer,

        cardDraw          = nil,
        qAvatar           = nil,
    }
end

CreateSkillCell = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    -----------------skillLayer start------------------
    local skillLayer = display.newLayer(size.width / 2, size.height / 2,
    {
        ap = display.CENTER,
        size = size,
    })
    cell:addChild(skillLayer)

    ------------------skillBtn start------------------
    local skillBtn = display.newButton(54, 55,
    {
        ap = display.CENTER,
        n = _res('ui/cards/skillNew/card_skill_bg_skill.png'),--RES_DICT.CARD_SKILL_BG_SKILL,
        enable = true,
    })
    -- display.commonLabelParams(skillBtn, fontWithColor(14, {text = ''})
    skillBtn:setScale(0.8)
    skillLayer:addChild(skillBtn)

    local skillImg = display.newNSprite("", 62, 62,
    {
        ap = display.CENTER,
    })
    skillImg:setScale(0.67)
    skillBtn:addChild(skillImg)

    -------------------skillBtn end-------------------
    local skillPropertyLabel = display.newLabel(113, 75,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#dab79e',
    })
    skillLayer:addChild(skillPropertyLabel)

    local skillLine = display.newNSprite(RES_DICT.PREVIEW_CARD_LINE_1, 110, 57,
    {
        ap = display.LEFT_CENTER,
    })
    skillLayer:addChild(skillLine)

    local skillName = display.newLabel(113, 50,
    {
        ap = display.LEFT_TOP,
        fontSize = 22,
        color = '#ffffff',
        w = 260
    })
    skillLayer:addChild(skillName)

    ------------------skillLayer end-------------------

    cell.viewData = {
        skillBtn       = skillBtn,
        skillImg       = skillImg,
        skillPropertyLabel = skillPropertyLabel,
        skillName      = skillName,
    }
    return cell
end

CreateCardDraw = function (skinId)
    local cardDraw = require( "common.CardSkinDrawNode" ).new({skinId = skinId, coordinateType = COORDINATE_TYPE_CAPSULE})
    cardDraw:setPositionX(display.SAFE_L)
    return cardDraw
end

CreateQAavatar = function (skinId)
    local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.7})
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setScaleX(-1)
    return qAvatar
end

--==============================--
--desc: 通过立绘切换类型 初始化卡牌皮肤数据
--@params cardDrawChangeType int    立绘切换类型
--@params cardDatas          table  卡牌数据
--@return skinDatas table  卡牌皮肤数据
--==============================--
function CardPreviewView:InitSkinDatasByType(cardDrawChangeType, cardDatas)
    -- 如果 skinUnlocks 为nil 则 默认可切换所有皮肤
    local skinUnlockMap = self:GetSkinUnlocksByType(cardDrawChangeType) or CardUtils.SKIN_UNLOCK_TYPE
    local allSkinMap = cardDatas.skin or {}
    
    local skinDatas = {}
    for k, unlockType in pairs(skinUnlockMap) do
        local skinList = allSkinMap[tostring(unlockType)]
        if skinList then
            for i, skinId in pairs(skinList) do
                table.insert(skinDatas, checkint(skinId))
            end
        end
    end

    if next(skinDatas) ~= nil then
        table.sort(skinDatas)
    end

    return skinDatas
end

--==============================--
--desc: 初始化卡牌技能数据
--@params confId     int    卡牌配表id
--@params cardDatas  table  卡牌数据
--@return skillDatas table  卡牌技能数据
--==============================--
function CardPreviewView:InitSkillDatas(confId, cardDatas)
    local skillDatas = {}

    -- 1. 获取需要显示的卡牌技能数据
    local skillShowConfData = CommonUtils.GetConfig('cards', "show", confId) or {}
    local skillIds = skillShowConfData.skillId or {}
    local skillLevels = skillShowConfData.skillLevel or {}
    local skillTypes = skillShowConfData.skillType or {}
    local businessSkill = {}
    -- 2. 获取卡牌经营技能  并初始化需要显示的卡牌技能数据
    for i, skillId_ in ipairs(skillIds) do
        local skillProperty = skillTypes[i]
        local skillPropertyName = CardUtils.GetSkillPropertyName(skillProperty)
        local skillLevel = skillLevels[i] or 1

        -- 2.1 检查是否是卡牌经营技能
        local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId_)
        if skillSectionType == SkillSectionType.CARD_MANAGER_SKILL then
            businessSkill[tostring(skillId_)] = {level = skillLevel}
        else
            local skillConf = CommonUtils.GetSkillConf(skillId_) or {}
            local skillDescr = app.cardMgr.GetSkillDescr(skillId_, skillLevel)
            local concertSkillTip = nil
            if skillProperty == CardUtils.CARD_SKILL_PROPERTY.CONNECT then
                concertSkillTip = self:GetConcertSkillTip(cardDatas)
            end
            table.insert(skillDatas, {
                skillPropertyName = skillPropertyName,
                skillName  = tostring(skillConf.name),
                skillDescr = skillDescr,
                skillId    = skillId_,
                concertSkillTip = concertSkillTip
            })
        end
    end

    -- 3. 检查是否有卡牌经营技能  有则初始化需要显示的卡牌经营技能数据
    if next(businessSkill) ~= nil then
        local cardAllBusinessSkill = CommonUtils.GetBusinessSkillByCardId(confId, {from = 3, cardData = {businessSkill = businessSkill}})
        for i, businessSkillData in ipairs(cardAllBusinessSkill) do
            local skillId = businessSkillData.skillId
            if businessSkill[tostring(skillId)] then
                table.insert(skillDatas, {
                    skillPropertyName = CardUtils.GetSkillPropertyName(CardUtils.CARD_SKILL_PROPERTY.MANAGER),
                    skillName  = tostring(businessSkillData.name),
                    skillDescr = tostring(businessSkillData.descr),
                    skillId    = businessSkillData.skillId,
                })
            end
        end
    end
    return skillDatas
end

--==============================--
--desc: 通过立绘切换类型 获取皮肤解锁类型
--@params cardDrawChangeType     int    立绘切换类型
--@return skinUnlocks table  皮肤解锁类型
--==============================--
function CardPreviewView:GetSkinUnlocksByType(cardDrawChangeType)
    local skinUnlocks = nil
    if cardDrawChangeType == 1 then
        skinUnlocks = {
            DEFAULT   = CardUtils.SKIN_UNLOCK_TYPE.DEFAULT, 
            FIVE_STAR = CardUtils.SKIN_UNLOCK_TYPE.FIVE_STAR
        }
    end
    return skinUnlocks
end

--==============================--
--desc: 获取连携技提示
--@params cardData        table   卡牌数据
--@return concertSkillTip string  连携技提示
--==============================--
function CardPreviewView:GetConcertSkillTip(cardData)
    local tempStr = ''
    local concertSkill = cardData.concertSkill or {}
    for i, cardId in pairs(concertSkill) do
        
        local concertCardData = CommonUtils.GetConfig('cards', 'card', cardId)
    
        local cardName = ''
        if nil == concertCardData then
            ------------ 卡牌表不存在连携对象 ------------
            cardName = __('???')
            ------------ 卡牌表不存在连携对象 ------------
        else
            cardName = tostring(concertCardData.name)
        end

        if i == 1 then
            tempStr = cardName
        else
            tempStr = isJapanSdk() and (tempStr..'、'..cardName) or (tempStr..','.. cardName)
        end
    end
    local companion = isJapanSdk() and (cardData.name..'、'..tempStr..'、') or (cardData.name..'，'..tempStr)
    return string.fmt(__('_des_一起进入战斗时，该技能激活，并替换能量技。'),{_des_ = companion})  
end

--==============================--
--desc: 检查皮肤下标
--@params index     int   皮肤下标
--@return skinIndex int   皮肤下标
--==============================--
function CardPreviewView:CheckSkinIndex(index)
    if index > self.maxSelectSkinIndex then
        self.curSelectSkinIndex = 1
    else
        self.curSelectSkinIndex = index
    end
    return self.curSelectSkinIndex
end

function CardPreviewView:GetSkinIdByIndex(index)
    return self.skinDatas[index]
end

function CardPreviewView:GetViewData()
    return self.viewData
end

return CardPreviewView