
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---

---@class BattleScriptTeamView
local BattleScriptTeamView = class('home.BattleScriptTeamView',function ()
    local node = CLayout:create( display.size) --cc.size(984,562)
    node.name = 'Game.views.BattleScriptTeamView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_CLICK = {
    SKILL_ONE  = 11001, -- 选择的第一个更换按钮
    SKILL_TWO  = 11002, -- 选择的第二个更换按钮
    BATTLE_BTN = 11003, -- 战斗按钮
    ADD_TAG    = 10044, -- 添加的按钮的值 这里仅做标记
    CLOSE_TAG  = 10005, -- 关闭的tag
}
local BATTLE_MAX_NUMS=  5 -- 上阵的队伍最大数量
function BattleScriptTeamView:ctor(data)
    self:initUI(data)
end

function BattleScriptTeamView:initUI(data)
    local data = data  or {}
    -- 底部的Layout
    local bottomSize = cc.size(display.width , 234)
    -- 底部的Layout
    local bottomLayout = display.newLayer(display.width/2 , 0 ,
            { ap = display.CENTER_BOTTOM , size =  bottomSize , color1 = cc.r4b()})
    self:addChild(bottomLayout)

    local bottomSwallow =display.newLayer(bottomSize.width/2, 0,
            { ap = display.CENTER_BOTTOM, size = cc.size(bottomSize.width ,bottomSize.height -90)   , color =cc.c4b(0,0,0,0) , enable = true})

    bottomLayout:addChild(bottomSwallow)

    local bg = display.newImageView(_res('ui/common/discovery_ready_dg.png'),bottomSize.width/2 , bottomSize.height -210, { scale9 = true , size = cc.size(display.width , 275)} )
    bottomLayout:addChild(bg)

    local cardNodeSize = cc.size(125,125)
    -- 所有卡牌的容器
    local allCardLayout =  display.newLayer(display.width/2,10,
    {size = cc.size(cardNodeSize.width * BATTLE_MAX_NUMS ,cardNodeSize.height * BATTLE_MAX_NUMS ) , ap = display.CENTER_BOTTOM  })
    bottomLayout:addChild(allCardLayout)


    for i =1 , BATTLE_MAX_NUMS do
        local cardLayout = display.newLayer(cardNodeSize.width * (i -0.5) , cardNodeSize.height/2,
        {size = cardNodeSize , ap = display.CENTER ,enable = true  , color = cc.c4b(0,0,0,0)})
        cardLayout:setTag(i)
        local cardOneLayout = self:CreatCardOneNode()
        cardLayout:addChild(cardOneLayout )
        allCardLayout:addChild(cardLayout)
    end

    local skillBg = display.newImageView(_res('ui/common/discovery_bg_talent.png'))
    local skillSize = skillBg:getContentSize()
    local skillLayout = display.newLayer(-60 + display.SAFE_L, 0, { ap = display.LEFT_BOTTOM,  size =skillSize , color1 = cc.r4b() })
    skillBg:setPosition(cc.p(skillSize.width/2 ,skillSize.height/2))
    skillLayout:addChild(skillBg)
    -- 设置第一个技能按钮
    local skillOneLayout =  self:CreateSkillLayout()
    skillOneLayout:setPosition(cc.p(145,150))
    skillLayout:addChild(skillOneLayout)
    skillOneLayout:setTag(BUTTON_CLICK.SKILL_ONE)

    -- 设置第二个技能按钮
    local skillTwoLayout =  self:CreateSkillLayout()
    skillTwoLayout:setPosition(cc.p(skillSize.width - 164,97))
    skillLayout:addChild(skillTwoLayout)
    skillTwoLayout:setTag(BUTTON_CLICK.SKILL_TWO)
    bottomLayout:addChild(skillLayout)

    local chosenLabel = display.newLabel(130,28, fontWithColor('10', { color = "ffffff" ,reqW = 140 , fontSize = 24 ,   text  = __('选择天赋' ) }) )
    skillLayout:addChild(chosenLabel)
    local  chosenLabelSize =  display.getLabelContentSize(chosenLabel)
    chosenLabelSize.width = chosenLabelSize.width > 140 and 140  or  chosenLabelSize.width
    local distance =  chosenLabelSize.width - 120
    chosenLabel:setPositionX( distance/2 + 130 )
    local fightImage = display.newImageView(_res('ui/common/discovery_bg_fight.png')  )
    local fightImageSize =fightImage:getContentSize()
    fightImage:setPosition(cc.p(fightImageSize.width/2 ,fightImageSize.height/2))

    local fightLayout = display.newLayer(display.width + 60 - display.SAFE_L, 0 , { ap = display.RIGHT_BOTTOM ,size  = fightImageSize , color1= cc.r4b()})
    fightLayout:addChild(fightImage)
    bottomLayout:addChild(fightLayout)
    local battleBtn = require('common.CommonBattleButton').new({
        pattern = data.pattern or 1,
        battleText =data.battleText ,
        battleFontSize = data.battleFontSize ,
        clickCallback = data.callback
    })
    battleBtn:setPosition(cc.p(fightImageSize.width - 156,107))
    battleBtn:setTag(BUTTON_CLICK.BATTLE_BTN)
    fightLayout:addChild(battleBtn)
    ---- 战斗次数的Label
    local battleLabel =  display.newRichLabel(250,15 , { ap = display.RIGHT_CENTER ,  c = {
        {   fontSize= 22 , color = "#ffffff"  ,text ="" }
    } })
    --display.newLabel(180,15 ,fontWithColor('10' , { fontSize= 22 , color = "#ffffff"  ,text ="" }))
    fightLayout:addChild(battleLabel)
    self.viewData = {
        bottomLayout = bottomLayout ,
        allCardLayout = allCardLayout ,
        battleLabel = battleLabel ,
        battleBtn = battleBtn ,
        skillOneLayout = skillOneLayout ,
        skillTwoLayout =skillTwoLayout ,
    }

end

function BattleScriptTeamView:BottomRunAction(isTrue)
    local bottomSize = cc.size(display.width , 234)
    local bottomLayout = self.viewData.bottomLayout
    local action =   cc.Sequence:create(
        cc.CallFunc:create(function ()
            bottomLayout:setPosition(cc.p(display.width/2 , -  bottomSize.height))
        end),
        cc.Spawn:create(
        cc.FadeIn:create(0.2),
        cc.JumpBy:create(0.2, cc.p(0, 234 ) ,100, 1)
        )
    )
    if not  isTrue then
        action = action:reverse()
    end

    bottomLayout:runAction(
    action
    )
end

--[[
    创建技能按钮
--]]
function BattleScriptTeamView:CreateSkillLayout()
    local skillOneSize = cc.size(120,120)
    local skillLayout = display.newLayer(skillOneSize.width/2, skillOneSize.height/2 , { ap = display.CENTER , size = skillOneSize , color = cc.c4b(0,0,0,0) , enable = true })

    local skillImage = display.newImageView(_res('ui/battle/battle_bg_skill_default.png') , skillOneSize.width/2 , skillOneSize.height/2)
    skillLayout:addChild(skillImage)
    skillImage:setName("skillImage")
    local addSkillNode = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png') , skillOneSize.width/2 , skillOneSize.height/2)
    skillLayout:addChild(addSkillNode,4)
    addSkillNode:setTag(BUTTON_CLICK.ADD_TAG)
    return skillLayout
end
-- 创建cardNode 底部的Layout
function BattleScriptTeamView:CreatCardOneNode()
    local scale = 0.63
    local cardNodeSize = cc.size(125,125)
    local cardSize = cc.size(190,190)
    local cardOneLayout = display.newLayer(cardNodeSize.width/2 ,cardNodeSize.height/2, { ap = display.CENTER , size = cardSize})
    cardOneLayout:setName("cardAdd")

    local cardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'),
    cardSize.width/2, cardSize.height/2)
    cardOneLayout:addChild(cardHeadBg)

    local cardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'),
    cardSize.width/2, cardSize.height/2)
    cardOneLayout:addChild(cardHeadFrame)
    cardOneLayout:setScale(scale)
    local addSkillNode = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png') , cardSize.width/2 , cardSize.height/2)
    cardOneLayout:addChild(addSkillNode,4)
    addSkillNode:setTag(BUTTON_CLICK.ADD_TAG)
    addSkillNode:setName("addSkillNode")
    addSkillNode:setScale(1/0.63)
    return cardOneLayout
end
return BattleScriptTeamView
