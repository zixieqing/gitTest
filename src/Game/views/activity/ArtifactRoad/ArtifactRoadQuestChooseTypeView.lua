local ArtifactRoadQuestChooseTypeView = class('ArtifactQuestChooseTypeView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'ArtifactRoadQuestChooseTypeView'
    node:enableNodeEvents()
    return node
end)

---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  	-- 普通模式
    PAID_TYPE 	= 2 	-- 付费模式
}
function ArtifactRoadQuestChooseTypeView:ctor(param)
    self.isAction = false
    param = param or {}
    self.questId = param.questId
    self.callfunc = param.callfunc
    self:initUI()
    self:UpdateUI()
end

function ArtifactRoadQuestChooseTypeView:initUI()
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
    {text = __('请选择一种消耗方式挑战关卡'), w = 300, hAlign= display.TAC  }) )
    bgLayout:addChild(tipLabel)

    local qban = display.newImageView(_res('ui/artifact/core_qban') ,82, bgSize.height - 35 )
    bgLayout:addChild(qban)
    
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
    local universalConsumeLabel = display.newRichLabel(bgSize.width /2 + 140 ,145 , {ap = display.RIGHT_CENTER ,  r = true , c = {
            fontWithColor('10', {text = "111111"})
        }
    })
    bgLayout:addChild(universalConsumeLabel,2)
    
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
    local commonConsumeLabel = display.newRichLabel(bgSize.width /2 - 150 ,145 , { ap = display.RIGHT_CENTER ,  r = true ,
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

function ArtifactRoadQuestChooseTypeView:UpdateUI()
    local viewData = self.viewData
    local universalConsumeLabel = viewData.universalConsumeLabel
    local universalBtn          = viewData.universalBtn
    local universalNode         = viewData.universalNode
    local commonBtn             = viewData.commonBtn
    local commonConsumeLabel    = viewData.commonConsumeLabel
    local commonNode            = viewData.commonNode

    local questId = self.questId or  12001
    local artifacOneQuest =  CommonUtils.GetQuestConf(checkint(self.questId))
    local num = checkint(artifacOneQuest.consumeHp)
    local goodsId = HP_ID
    local consumeGoodsId = checkint(artifacOneQuest.consumeGoodsId)
    local consumeGoodsNum = checkint(artifacOneQuest.consumeGoodsNum)
    display.reloadRichLabel(universalConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(consumeGoodsNum)})
    }})
    universalNode:RefreshSelf({goodsId =  consumeGoodsId})
    display.reloadRichLabel(commonConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(num)})
    }})
    commonNode:RefreshSelf({goodsId = goodsId })
    local callfunc = function(sender)
        local type = sender:getTag()
        local goodsId = type == BATTLE_TYPE.COMMON_TYPE  and goodsId or consumeGoodsId
        local num =  type == BATTLE_TYPE.COMMON_TYPE  and num or consumeGoodsNum
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
                local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
                uiMgr:ShowInformationTips(string.format( __("%s不足"),  goodsConfig.name))
            end
        end
    end
    display.commonUIParams(universalBtn , {cb = callfunc})
    display.commonUIParams(commonBtn , {cb = callfunc})
end

return ArtifactRoadQuestChooseTypeView
