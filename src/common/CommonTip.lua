--[[
通用提示弹窗
@params {
    text string 标题
    descr string 附加提示
    textRich table 标题
    descrRich table 描述
    defaultRichPattern bool 是否使用默认的字体样式
    costInfo table 消耗信息 {goodsId = 0, num = 0}
    callback function 确认按钮回调
}
--]]
local GameScene = require( "Frame.GameScene" )

local CommonTip = class('CommonTip', GameScene)


local uiMgr = AppFacade.GetInstance():GetManager('UIManager')

function CommonTip:ctor( ... )
    local arg = unpack({...})
    self.args = arg
    self:init()
end


function setBtnContentSize(btn , data)
    if tolua.type(btn) == 'ccw.CButton'  then
        if not   btn:isScale9Enabled() then
            return
        end
        local label =  btn:getLabel()
        local btnSize = btn:getContentSize()
        local width = data.width or btnSize.width
        local height = data.height or btnSize.height
        local text = label:getString() or ""
        local labelSize = display.getLabelContentSize(label)
        if labelSize.width   >  width + 50 then
            display.commonLabelParams(label,{text =text , w = width - 10  , hAlign = display.TAC ,reqH =  height })
        else
            display.commonLabelParams(label,{text =text  , hAlign = display.TAC ,reqW = width -10  })
        end
        btn:setContentSize(cc.size(width , height))
    end
end


function CommonTip:init()
    self.text       = self.args.text
    self.noWidthText= self.args.noWidthText
    self.extra      = self.args.extra
    self.callback   = self.args.callback
    self.cancelBack = self.args.cancelBack
    self.isOnlyOK   = self.args.isOnlyOK == true
    self.hideAllButton = self.args.hideAllButton == true
    self.descr      =  self.args.descr
    self.useAllText         = self.args.useAllText
    self.useOneText         = self.args.useOneText

    self.textRich   = self.args.textRich
    self.descrRich  = self.args.descrRich
    self.defaultRichPattern = self.args.defaultRichPattern
    self.costInfo   = self.args.costInfo

    -- local commonBg = require('common.CloseBagNode').new(
    --     {callback = function ()
    --         self:runAction(cc.RemoveSelf:create())
    --     end})
    -- commonBg:setPosition(utils.getLocalCenter(self))
    -- self:addChild(commonBg)
    self:setName("CommonTip")
    self:setPosition(self.args.po or display.center)

    local commonBG = require('common.CloseBagNode').new({callback = function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end})
    commonBG:setPosition(utils.getLocalCenter(self))
    commonBG:setName('commonBG')
    self:addChild(commonBG)


    --view
    local view = CLayout:create()
    view:setPosition(display.cx, display.cy)
    view:setAnchorPoint(display.CENTER)
    self.view = view
    view:setName('view')

    -- --bg
    -- local frameBg = display.newImageView(_res('ui/activity/oneYuan/oneyuan_bg.png'))

    -- frameBg:setAnchorPoint(display.LEFT_BOTTOM)
    -- view:addChild(frameBg)
    -- view:setContentSize(size)

    local outline = display.newImageView(_res('ui/common/common_bg_8.png'),{
        scale9 = true, enable = true, size = cc.size(display.size.width* 0.4 ,350)
    })
    local size   = outline:getContentSize()
    outline:setAnchorPoint(display.LEFT_BOTTOM)
    view:addChild(outline)
    view:setContentSize(size)
    commonBG:addContentView(view)
    -- cancel button
    local cancelBtn = display.newButton(size.width/2 - 120 ,50,{
        n = _res('ui/common/common_btn_white_default.png'),
        cb = function(sender)
            PlayAudioByClickClose()
            if self.cancelBack then
                self.cancelBack()
            end
            self:runAction(cc.RemoveSelf:create())
        end ,scale9 = true
    })
    local tempText = __('取消')
    if self.useAllText then
        tempText = self.useAllText
    end
    display.commonLabelParams(cancelBtn,fontWithColor(14,{text = tempText }))
    -- setBtnContentSize(cancelBtn , { width = 170 , height = 70})
    view:addChild(cancelBtn)


    -- entry button
    local entryBtn = display.newButton(size.width * 0.5 + 120,50,{
       n = _res('ui/common/common_btn_orange.png'),
       cb = function(sender)
            PlayAudioByClickNormal()
            sender:setTouchEnabled(false)
            if self.callback then
                --TODO 连点奔溃处理
                local actionSeq = cc.Sequence:create(
                    cc.CallFunc:create(function ()
                        xTry(function()
                            self.callback()
                        end, __G__TRACKBACK__)
                    end),
                    cc.DelayTime:create(0.1),
                    cc.CallFunc:create(function ()
                        self:runAction(cc.RemoveSelf:create())
                    end))

                 self:runAction(actionSeq)
                return
            end
            self:runAction(cc.RemoveSelf:create())
        end ,scale9 = true
    })
    local tempText = __('确定')
    if self.useOneText then
        tempText = self.useOneText
    end
    display.commonLabelParams(entryBtn,fontWithColor(14,{text = tempText}))
    setBtnContentSize(entryBtn , { width = 170 , height =  70})
    entryBtn:setName('entryBtn')
    view:addChild(entryBtn)

    -- tips label
    local tip = nil
    if self.text then
        tip = display.newLabel(utils.getLocalCenter(view).x, size.height  - 40, {fontSize = 26, color = '#4c4c4c',w = size.width -100,h = 250})
        tip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        tip:setAnchorPoint(cc.p(0.5 ,1))
        tip:setString(string.fmt(('_text_'), {_text_ = self.text}))
        view:addChild(tip)
        if self.descr  then
            display.commonLabelParams(tip , {fontSize =  24 })
        end
    elseif self.textRich then
        if self.defaultRichPattern then
            for i,v in ipairs(self.textRich) do
                if nil == v.fontSize then
                    v.fontSize = 26
                end
                if nil == v.color then
                    v.color = '#4c4c4c'
                end
            end
        end
        tip = display.newRichLabel(utils.getLocalCenter(view).x, size.height - 40, {
            w = size.width - 75, h = 250, c = self.textRich, r = true
        })
        tip:setAnchorPoint(cc.p(0.5 ,1))
        local tipSize  = tip:getContentSize()
        if tipSize.width > 370 then
            tip:setScale(370/tipSize.width)
        end
        view:addChild(tip)
    end
    self.tip = tip
    if self.noWidthText then
        local tip = display.newLabel(utils.getLocalCenter(view).x, size.height / 2 + 50, {fontSize = 26, color = '#4c4c4c',w = size.width - 60})
        tip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        tip:setAnchorPoint(cc.p(0.5 ,0.5))
        tip:setString(string.fmt(('_text_'), {_text_ = self.noWidthText}))
        view:addChild(tip)
    end


    if self.extra then
        local exraTip = display.newLabel(size.width * 0.5 * outline:getScale(), size.height*0.8 - 30, {fontSize = 18, color = '#FF7C7C'})
        exraTip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        exraTip:setString(string.fmt(('_text_'), {_text_ = self.extra}))
        view:addChild(exraTip)
    end
    if self.descr then
        local descrTip = display.newLabel(size.width * 0.5 * outline:getScale(), size.height*0.8 - 30, { ap = cc.p(0.5,1) ,fontSize = fontWithColor('15').fontSize, color = fontWithColor('15').color,w = size.width -100,h = 200})
        descrTip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        descrTip:setString(string.fmt(('Tips: _text_'), {_text_ = self.descr }))
        view:addChild(descrTip)
        self.descrTip = descrTip
    elseif self.descrRich then
        table.insert(self.descrRich, 1, fontWithColor('15', {text = __('Tips: ')}))
        if self.defaultRichPattern then
            for i,v in ipairs(self.descrRich) do
                if nil == v.fontSize then
                    v.fontSize = fontWithColor('15').fontSize
                end
                if nil == v.color then
                    v.color = fontWithColor('15').color
                end
            end
        end
        -- 有图片的情况下不支持换行
        local descrTipW = 40
        for i, v in ipairs(checktable(self.descrRich)) do
            if v.img then
                descrTipW = 300
                break
            end
        end
        local descrTip = display.newRichLabel(size.width * 0.5 * outline:getScale(), size.height * 0.8 - 30, {
            ap = cc.p(0.5, 1), w = descrTipW,  h = 200, r = true, c = self.descrRich
        })
        view:addChild(descrTip)
        self.descrTip = descrTip
        CommonUtils.SetNodeScale(descrTip , {width = size.width - 80 })
    end
    if self.isOnlyOK then
        cancelBtn:setVisible(false)
        entryBtn:setPositionX(size.width/2)
    end

    if self.hideAllButton then
        cancelBtn:setVisible(false)
        entryBtn:setVisible(false)
        if tip then
            tip:setPositionY(utils.getLocalCenter(view).y + 15)
        end
    end

    if self.costInfo then
        local confirmBtn = display.newButton(0, 0, {
            n = _res('ui/common/common_btn_green.png'),
            cb = function(sender)
                PlayAudioByClickNormal()
                sender:setTouchEnabled(false)
                if self.callback then
                    --TODO 连点奔溃处理
                    local actionSeq = cc.Sequence:create(
                        cc.CallFunc:create(function ()
                            xTry(function()
                                self.callback()
                            end, __G__TRACKBACK__)
                        end),
                        cc.DelayTime:create(0.1),
                        cc.CallFunc:create(function ()
                            self:runAction(cc.RemoveSelf:create())
                        end))

                     self:runAction(actionSeq)
                    return
                end
                self:runAction(cc.RemoveSelf:create())
            end
        })
        display.commonUIParams(confirmBtn, {po = cc.p(size.width * 0.5, 50)})
        view:addChild(confirmBtn)

        cancelBtn:setVisible(false)
        entryBtn:setVisible(false)

        local costAmountLabel = display.newLabel(0, 0, fontWithColor('14', {text = self.costInfo.num}))
        confirmBtn:addChild(costAmountLabel)
        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(self.costInfo.goodsId)), 0, 0)
        costIcon:setScale(0.25)
        confirmBtn:addChild(costIcon)
        display.setNodesToNodeOnCenter(confirmBtn, {costAmountLabel, costIcon})
    end
end


return CommonTip
