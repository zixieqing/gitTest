---@class ArtifactQuestChooseTypeView
local ArtifactQuestChooseTypeView = class('home.ArtifactQuestChooseTypeView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'Game.views.ArtifactQuestChooseTypeView'
    node:enableNodeEvents()
    return node
end)
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")

---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  -- 普通模式
    UNIVERSAL_TYPE = 2 -- 万能门票道具消耗
}
function ArtifactQuestChooseTypeView:ctor(param)
    self.isAction = false
    param = param or {}
    self.questId = param.questId
    self.callfunc = param.callfunc
    self:initUI()
    self:UpdateUI()
end

function ArtifactQuestChooseTypeView:initUI()
    local closeLayer = display.newLayer(display.cx, display.cy ,
            {ap = display.CENTER , size = display.size  , color = cc.c4b(0,0,0,100) ,enable = true ,
             cb = function()
                 self:runAction(cc.RemoveSelf:create())
             end })
    self:addChild(closeLayer)
    local bgSize = cc.size(617 , 318)
    local bgLayout = display.newLayer(display.width/2, display.height/2  ,
            {ap = display.CENTER  , size = bgSize})
    self:addChild(bgLayout)
    self.bgLayout = bgLayout
    -- 吞噬层
    local swallowLayer = display.newLayer(display.width/2, display.height/2  ,
            {ap = display.CENTER  , size = bgSize ,enable = true })
    self:addChild(swallowLayer)
    -- 背景图片
    local bgImage = display.newImageView(_res('ui/artifact/core_bg_fight') ,bgSize.width/2 , bgSize.height/2 )
    bgLayout:addChild(bgImage)

    local tipLabel = display.newLabel(bgSize.width /2 ,bgSize.height - 58 , fontWithColor('6' ,
    {text = __('请选择一种碎片消耗方式进入战斗') ,  w = 300, hAlign= display.TAC }) )
    bgLayout:addChild(tipLabel)

    local qban = display.newImageView(_res('ui/artifact/core_qban') ,82, bgSize.height - 35 )
    bgLayout:addChild(qban)
    -- 万能消耗挑战
    local  universalBtn = display.newButton(bgSize.width/2 + 150 , 110 ,
            {n = _res('ui/home/talent/talent_tips_btn_1.png')}
    )
    bgLayout:addChild(universalBtn)

    local universalBtnSize = universalBtn:getContentSize()
    local universalLabel = display.newLabel(universalBtnSize.width/2 , 40 ,
            fontWithColor('14' , {text =__('进入战斗') , outline = false}))
    universalBtn:addChild(universalLabel)

    local universalNode = require("common.GoodNode").new({id = DIAMOND_ID})
    bgLayout:addChild(universalNode)
    universalNode:setPosition(bgSize.width /2 + 185,145 )
    universalNode:setScale(0.5)
    local universalConsumeLabel = display.newRichLabel(bgSize.width /2 + 100 ,145 , {r = true , c = {
            fontWithColor('10', {text = "111111"})
        }
    })
    bgLayout:addChild(universalConsumeLabel,2)
    -- 普通挑战
    local  commonBtn = display.newButton(bgSize.width/ 2 - 150 , 110 ,
            {n = _res('ui/home/talent/talent_tips_btn_2.png')}
    )
    bgLayout:addChild(commonBtn)

    local commonLabel = display.newLabel(universalBtnSize.width/2 , 40,
            fontWithColor('14' , {text =__('进入战斗') , outline = false}))
    commonBtn:addChild(commonLabel)


    local commonNode = require("common.GoodNode").new({id = DIAMOND_ID})
    bgLayout:addChild(commonNode)
    commonNode:setPosition(bgSize.width /2 - 113  ,145 )
    commonNode:setScale(0.5)
    local commonConsumeLabel = display.newRichLabel(bgSize.width /2 - 190,145 , { r = true ,
        c = {
            fontWithColor('10', {text = "111111"})
        }
    })
    bgLayout:addChild(commonConsumeLabel)
    universalBtn:setTag(2)
    commonBtn:setTag(1)
    self.viewData = {
        universalConsumeLabel = universalConsumeLabel,
        universalLabel        = universalLabel,
        universalBtn          = universalBtn,
        universalNode         = universalNode,
        commonBtn             = commonBtn,
        commonConsumeLabel    = commonConsumeLabel,
        commonLabel           = commonLabel,
        commonNode            = commonNode
    }
end

function ArtifactQuestChooseTypeView:UpdateUI()
    local viewData = self.viewData
    local universalConsumeLabel = viewData.universalConsumeLabel
    local universalBtn          = viewData.universalBtn
    local universalNode         = viewData.universalNode
    local commonBtn             = viewData.commonBtn
    local commonConsumeLabel    = viewData.commonConsumeLabel
    local commonNode            = viewData.commonNode

    local questId = self.questId or  12001
    local parserConfig = artifactMgr:GetConfigParse()
    local artifactQuestConfig = artifactMgr:GetConfigDataByName(parserConfig.TYPE.QUEST)
    local artifacOneQuest =  artifactQuestConfig[tostring(questId)] or {}
    local consumeData = artifacOneQuest.consumeGoods  and  artifacOneQuest.consumeGoods[1] or  {}
    local num = checkint(consumeData.num)
    local goodsId =  consumeData.goodsId
    local consumeTicketId = checkint(artifacOneQuest.consumeTicket)
    local consumeTicketNum = checkint(artifacOneQuest.consumeTicketNum)
    display.reloadRichLabel(universalConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(consumeTicketNum)})
    }})
    universalNode:RefreshSelf({goodsId =  consumeTicketId})
    display.reloadRichLabel(commonConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(num)})
    }})
    commonNode:RefreshSelf({goodsId = goodsId })
    local callfunc = function(sender)
        local type = sender:getTag()
        local goodsId = type == BATTLE_TYPE.COMMON_TYPE  and goodsId or consumeTicketId
        local num =  type == BATTLE_TYPE.COMMON_TYPE  and num or consumeTicketNum
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        if ownNum  >= num  then
            -- 前往战斗界面
            if self.callfunc then
                self.callfunc(sender)
                self:runAction(cc.RemoveSelf:create())
            end
        else
            if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                app.uiMgr:showDiamonTips()
            else
                uiMgr:ShowInformationTips(__("道具不足"))
            end
        end
    end
    display.commonUIParams(universalBtn , {cb = callfunc})
    display.commonUIParams(commonBtn , {cb = callfunc})
end



return ArtifactQuestChooseTypeView
