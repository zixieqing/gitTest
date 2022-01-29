---
--- Created by xingweihao.
--- DateTime: 27/10/2017 4:02 PM
---
---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:29 PM
---
---@class ChangeCardSkinView
local ChangeCardSkinView = class('home.ChangeCardSkinView',function ()
    local node = CLayout:create( display.size ) --cc.size(984,562)
    node.name = 'Game.views.ChangeCardSkinView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
--[[
    @param callback  选中皮肤的时候的回调
    @param id  选中的卡牌

--]]
function ChangeCardSkinView:ctor(params )
    params = params or {}
    params.id = params.id
    self.callback = params.callback
    self.cardDatas = params.cardDatas
    self:initUI()
end


function ChangeCardSkinView:initUI()
    -- body
    local closeLayer = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = display.size , color = cc.c4b(0,0,0,100 ) , enable  = true ,cb = function ()
        self:removeFromParent()
    end})
    self:addChild(closeLayer)

    local switchBgImage = display.newImageView(_res('ui/union/lobby/guild_switch_bg'))
    local switchBgImageSize = switchBgImage:getContentSize()
    switchBgImage:setPosition(cc.p(switchBgImageSize.width/2  , switchBgImageSize.height/2))

    local switchBgLayout = display.newLayer(display.cx , display.cy  , { ap = display.CENTER  , size  = switchBgImageSize})
    switchBgLayout:addChild(switchBgImage)
    self:addChild(switchBgLayout)

    local swallowLayout =  display.newLayer(switchBgImageSize.width/2  , switchBgImageSize.height/2,
                                            { ap = display.CENTER  , size  = switchBgImageSize , color = cc.c4b(0,0,0,0) , enable = true })
    switchBgLayout:addChild(swallowLayout)
    local contentLayout = display.newLayer(switchBgImageSize.width/2 ,switchBgImageSize.height/2 + 40,{ap =display.CENTER , size = display.size })
    switchBgLayout:addChild(contentLayout)

    local titleBtn = display.newButton(switchBgImageSize.width/2 , switchBgImageSize.height  + 20 , { n = _res('ui/union/lobby/guild_switch_title')})
    switchBgLayout:addChild(titleBtn)
    display.commonLabelParams(titleBtn, fontWithColor('6', {color = "ffffff" , text = __('选择外观形象')}))
    local sizee = nil
    local cardSkinConfig = CommonUtils.GetConfigAllMess('cardSkin','goods' ) or {}
    for i = 1, #self.cardDatas do
        local  cardHeadNode = require('common.CardHeadNode').new({showName = true,cardData = self.cardDatas[i],
                                                           showActionState = false ,showBaseState = true })
        if not  sizee then
            sizee = cardHeadNode:getContentSize()
        end
        cardHeadNode:setPosition(cc.p(sizee.width*(i - 0.5 ) , sizee.height /2 ))
        contentLayout:addChild(cardHeadNode)
        cardHeadNode:setScale(0.9)
        -- 设置tag值
        cardHeadNode:setTag(checkint(self.cardDatas[i].skinId) )
        cardHeadNode:setOnClickScriptHandler(handler(self, self.ButtonAction))
        local cardSkinData = cardSkinConfig[tostring(self.cardDatas[i].skinId) ]
        -- 选择皮肤的数据
        if cardSkinData then
            local name = cardSkinData.name or ""
            local nameLabel = cardHeadNode.viewData.nameLabel
            if nameLabel and not tolua.isnull(nameLabel) then
                display.commonLabelParams(nameLabel,   fontWithColor('14',{text =name  }))
            end
        end
    end
    if sizee then
        contentLayout:setContentSize(cc.size(sizee.width*  #self.cardDatas , sizee.height))
    end
end

function ChangeCardSkinView:ButtonAction(sender)
    if self and not tolua.isnull(self) then
        local tag = sender:getTag()
        if self.callback then
            self.callback(tag)
            if self and ( not  tolua.isnull(self)) then
                self:runAction(cc.RemoveSelf:create())
            end
        end
    end
end
return ChangeCardSkinView