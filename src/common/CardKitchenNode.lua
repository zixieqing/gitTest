--[[
卡牌node
@params table {
	id int card id
}
--]]
local CardKitchenNode = class('CardKitchenNode', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.CardKitchenNode'
    node:setBackgroundColor(cc.c4b(0,0,0,100))
	node:enableNodeEvents()
	return node
end)


local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CardKitchenNode:ctor( ... )
	local args = unpack({...})
    self.preIndex = nil  -- 记录上一次点击的值 初始为空
    local id = args.id
    local from = args.from
    local moduleId = args.moduleId
    
    local touchView = CColorView:create(cc.c4b(0,0,0,150))
    touchView:setContentSize(display.size)
    touchView:setTouchEnabled(true)
    display.commonUIParams(touchView, {po = display.center})
    touchView:setOnClickScriptHandler(function(sender)
        self:setVisible(false)
    end)
    self:addChild(touchView)
    local cardInfo = {}
    if args.friendData then
        cardInfo = {
            cardId        = checkint(args.friendData.cardId),
            breakLevel    = checkint(args.friendData.breakLevel),
            businessSkill = checktable(args.friendData.businessSkill),
            skinId        = checkint(args.friendData.skinId)
        }
    else
        cardInfo = gameMgr:GetCardDataById(args.id)
    end
    self.viewData = nil
    local breakLevel = rangeId(checkint(cardInfo.breakLevel),CARD_BREAK_MAX)
    -- 立绘
    local cardDrawNode = require('common.CardSkinDrawNode').new({cardId = cardInfo.cardId, skinId = cardInfo.skinId, coordinateType = COORDINATE_TYPE_HOME})
    -- cardDrawNode:setContentSize(cc.size(1334,display.height))
    -- display.commonUIParams(cardDrawNode, {ap = display.CENTER_BOTTOM})
    cardDrawNode:setPositionX(display.SAFE_L + 60)
    self:addChild(cardDrawNode,1)


    local nameBgImage = display.newImageView(_res('avatar/ui/draw_card_bg_name'),758  + display.SAFE_L, 610, {
        ap = display.LEFT_BOTTOM
    })
    self:addChild(nameBgImage,2)


    local employee = checktable(gameMgr:GetUserInfo().employee)
    local tId = nil
    if args.friendData then
        tId = checkint(args.friendData.siteId)
    else
        for key,val in pairs(employee) do
            if checkint(val) == id then
                tId = key
                break
            end
        end
    end
    local cp = utils.getLocalCenter(nameBgImage)
    local nameLabel = display.newRichLabel(20,cp.y)
    display.commonUIParams(nameLabel, {ap = display.LEFT_CENTER})
    nameBgImage:addChild(nameLabel)

    local texts = {c = {}}
    local cardConfig = CardUtils.GetCardConfig(cardInfo.cardId)
    if tId then
        -- 存在厨房类型
        local employeeInfo = CommonUtils.GetConfigNoParser('restaurant', 'employee', tId)
        table.insert(texts.c, fontWithColor(14, {text = employeeInfo.name, fontSize = 26, color = 'ffffff'}))
    end
    table.insert(texts.c, fontWithColor(14, {text = cardConfig.name, fontSize = 32, color = 'ffdf89'}))
    display.reloadRichLabel(nameLabel, texts)
    local skillDetailDatas = {}
    if args.friendData then
        skillDetailDatas = CommonUtils.GetBusinessSkillByCardId(cardInfo.cardId, {cardData = args.friendData}) or {}
    else
        skillDetailDatas = CommonUtils.GetBusinessSkillByCardId(cardInfo.cardId, {from = from, moduleId = moduleId}) or {}
    end
    local skillContentData = self:createSkillContent()
    local skillIConLayoutSize = cc.size(table.nums(skillDetailDatas)*140 ,140)
    local swallowLayer = display.newLayer(skillIConLayoutSize.width/2,skillIConLayoutSize.height/2,{ap = display.CENTER ,size = skillIConLayoutSize  ,enable =true ,color = cc.c4b(0,0,0,0)})

    local skillIConLayout = CLayout:create(skillIConLayoutSize)
    skillIConLayout:addChild(swallowLayer)
    skillIConLayout:setAnchorPoint(display.LEFT_CENTER)
    skillIConLayout:setPosition(cc.p(745 + display.SAFE_L,506))
    skillContentData.view:setAnchorPoint(display.LEFT_CENTER)
    skillContentData.view:setPosition(cc.p(752 + display.SAFE_L,103))
    self:addChild(skillIConLayout ,2)
    self:addChild(skillContentData.view ,2)
    local skillLockSort = {}
    local collectSkillNodeTable = {} -- 用于收集技能的table
    local isInBusunessSkill =  function (skillId)
        local isIn = false
        if cardInfo.businessSkill[tostring(skillId) ] then
            isIn = true
        end
        return isIn
    end
    for k ,v in pairs(skillDetailDatas) do

        if not isInBusunessSkill(v.skillId) then -- 把解锁的放在最前面 未解锁放后面
            table.insert(skillLockSort, #skillLockSort+1,v)
        else
            table.insert(skillLockSort, 1,v)
        end
    end
    if table.nums(skillDetailDatas) == 0 then
        local noSkillLabel = display.newLabel( 200,-200,fontWithColor(14, {text = __('此飨灵无经营技能'), fontSize = 26}))
        nameBgImage:addChild(noSkillLabel)
    end
    local introduceSkillCallback = function (sender) -- 技能介绍的显示
        local tag = sender:getTag()
        if self.preIndex then
            if self.preIndex  == tag  then  --点击相同的不做任何的处理
                return
            end
            collectSkillNodeTable[self.preIndex]:setEnabled(true)
            collectSkillNodeTable[self.preIndex]:setChecked(false)
        end
        if skillLockSort[tag] then
            skillContentData.skillName:setString("")
            skillContentData.skillLevel:setString("")
            skillContentData.skillContent:setString("")
            sender:setEnabled(false)
            self.preIndex = tag
            collectSkillNodeTable[tag]:setChecked(true)
            skillContentData.view:setVisible(true)
            local posX = collectSkillNodeTable[tag]:getPositionX()
            local contentSize = skillContentData.view:getContentSize()
            if posX > contentSize.width then
                skillContentData.view:setAnchorPoint(display.RIGHT_BOTTOM)
                skillContentData.view:setPosition(cc.p(690 + posX + 70 + display.SAFE_L,103))
                skillContentData.cornerMark:setPosition(cc.p(contentSize.width - 66,contentSize.height-1.5))
            else
                skillContentData.view:setAnchorPoint(display.LEFT_BOTTOM)
                skillContentData.view:setPosition(cc.p(690+70 + display.SAFE_L,103))
                skillContentData.cornerMark:setPosition(cc.p(140*(tag - 1) + 55,contentSize.height-1.5))
            end
            if  skillLockSort[tag].unlock == 0 then
                skillContentData.skillContent:setString(string.format(__("该飨灵星级需达到%s星解锁%s"),skillLockSort[tag].openBreakLevel,skillLockSort[tag].name))
            else
                if  not isInBusunessSkill(skillLockSort[tag]["skillId"]) then
                    skillContentData.skillContent:setString(__("技能需要手动解锁"))
                else
                    skillContentData.skillName:setString(skillLockSort[tag].name)
                    skillContentData.skillLevel:setString(__('等级:').. cardInfo.businessSkill[skillLockSort[tag].skillId].level)
                    skillContentData.skillContent:setString(skillLockSort[tag].descr)
                end

            end
        end
    end
    for i =1 , table.nums(skillLockSort) do

        local skillNodeData = self:createSkillNode(skillLockSort[i].skillId)
        skillIConLayout:addChild(skillNodeData.view)
        skillNodeData.view:setPosition(cc.p(140*(i-0.5) , 70))
        skillNodeData.btn:setOnClickScriptHandler(introduceSkillCallback)
        skillNodeData.btn:setTag(i)
        if  not isInBusunessSkill(skillLockSort[i].skillId)  then
            skillNodeData.skillImage:setFilter(filter.newFilter('GRAY'))
        end
        collectSkillNodeTable[i] =  skillNodeData.btn
    end

    if table.nums(collectSkillNodeTable) > 1 then
        introduceSkillCallback(collectSkillNodeTable[1])
    end
    ---显示厨房技能的逻辑
    self.viewData = {
        cardView = cardDrawNode,
        nameLabel = nameLabel,
    }
end

-- 创建的技能叙述
function CardKitchenNode:createSkillContent()
    local bgImage = display.newImageView(_res('avatar/ui/cooking_skill_bg_words.png'))
    local bgSize = bgImage:getContentSize()
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local skillLayout =  CLayout:create(bgSize)
    -- CLayout:create(bgSize)
    skillLayout:setVisible(false)
    skillLayout:addChild(bgImage)
    local cornerMark = display.newImageView(_res('avatar/ui//cooking_skill_ico_arrow.png'),70,bgSize.height-2 , {ap = display.CENTER_BOTTOM})
    skillLayout:addChild(cornerMark)
    local skillName  = display.newLabel(32,bgSize.height -36,{ ap = display.LEFT_CENTER ,fontSize =28 , color = "#ffeac5" ,text = "" })
    skillLayout:addChild(skillName)
    local skillLevel  = display.newLabel(32,bgSize.height - 75 ,{ ap = display.LEFT_CENTER ,fontSize =28 , color = "#ffffff" ,text = "" })
    skillLayout:addChild(skillLevel)
    local skillContent = display.newLabel(32 ,bgSize.height - 112 ,fontWithColor('18', { ap = display.LEFT_TOP , w = 430 ,hAlign = display.TAL ,text = "" }))
    skillLayout:addChild(skillContent)
    cornerMark:setVisible(true)
    return {
        view = skillLayout ,
        skillName = skillName ,
        skillLevel = skillLevel ,
        skillContent = skillContent ,
        cornerMark = cornerMark
    }
end
-- 技能node
function CardKitchenNode:createSkillNode(skillId)
    local skillNodeSize = cc.size(140,140)
    local imageLight = display.newCheckBox(skillNodeSize.width/2 ,skillNodeSize.height/2, { n =  _res('avatar/ui/team_lead_skill_frame_l.png'), s = _res('avatar/ui/team_lead_skill_frame_light.png')} )
    imageLight:setPosition(cc.p(skillNodeSize.width/2 ,skillNodeSize.height/2))
    local skillLayout = CLayout:create(skillNodeSize)
    --  CLayout:create(skillNodeSize)
    skillLayout:addChild(imageLight,2)
    local skillBg= display.newImageView(_res('avatar/ui/team_lead_skill_frame_l.png'),skillNodeSize.width/2 ,skillNodeSize.height/2)
    skillLayout:addChild(skillBg,2)
    local skillImage =   FilteredSpriteWithOne:create(_res(CommonUtils.GetSkillIconPath(skillId)))
    skillImage:setPosition(cc.p(skillNodeSize.width/2 ,skillNodeSize.height/2))
    skillLayout:addChild(skillImage)
    skillImage:setScale(0.7)
    return  {
        view  = skillLayout ,
         btn  =  imageLight ,
         skillImage = skillImage
    }
end
return CardKitchenNode
