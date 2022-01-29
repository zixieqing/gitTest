---
--- Created by xingweihao.
--- DateTime: 29/12/2017 12:45 AM
---
---@class UnionInforView
local UnionInforView = class('home.UnionInforView',function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.UnionInforView'
    node:enableNodeEvents()
    return node
end)
local RemindIcon = require("common.RemindIcon")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    INFORCLICK    = 1004, -- 个人信息点击事件
    APPLY_REQUEST =  RemindTag.UNION_INFO, --系统设置
}
function UnionInforView:ctor()
    self:initUI()
end

function UnionInforView:initUI()
    local bg = display.newImageView(_res('ui/common/common_bg_5.png'), 0, 0)
    local bgSize = bg:getContentSize()

    local  bgLayout =display.newLayer(display.cx -50 ,display.cy,{ap = display.CENTER , size =bgSize  , enable = true})
    bg:setPosition(cc.p(bgSize.width/2  , bgSize.height/2))
    bgLayout:addChild(bg)

    --  点击关闭层
    local  closeView = display.newLayer(display.cx,display.cy,{ap = display.CENTER , size = display.size  , enable = true, color = cc.c4b(0,0,0,100)})
    self:addChild(closeView)

    --吞噬曾
    local  swallowView = display.newLayer(bgSize.width/2, bgSize.height/2,{ap = display.CENTER , size = bgSize  , enable = true, color = cc.c4b(0,0,0,0)})
    bgLayout:addChild(swallowView)
    swallowView:setContentSize(cc.size(bgSize.width, bgSize.height ))
    bgLayout:setContentSize(cc.size(bgSize.width, bgSize.height))
    -- 这个是功能切换的按钮
    local buttonSize = cc.size(143,96)
    local buttonNameTable = {
        { name    =    __('工会信息') ,tag = BUTTON_CLICK.INFORCLICK}  ,
    }
    if checkint(gameMgr:getUnionData().job)  < UNION_JOB_TYPE.COMMON then
        buttonNameTable[#buttonNameTable+1] =  { name  =  __('工会申请') ,tag = BUTTON_CLICK.APPLY_REQUEST}
    end
    local len = table.nums(buttonNameTable)
    local buttonLayotSize = cc.size(buttonSize.width, buttonSize.height*len)
    local swallowButtonLayout = display.newLayer(buttonLayotSize.width/2  , buttonLayotSize.height/2 ,
                 { size =buttonLayotSize , enable = true , ap = display.CENTER , color = cc.c4b(0,0,0,0) })
    local buttonLayot = CLayout:create(buttonLayotSize)
    buttonLayot:addChild(swallowButtonLayout)
    buttonLayot:setPosition(cc.p(bgSize.width/2 + display.cx -70 , bgSize.height/2 + display.cy - 100))
    buttonLayot:setAnchorPoint(display.LEFT_TOP)
    self:addChild(buttonLayot ,10 )

    local buttonTable  = {}

    for  i = 1, len do
        local btn = display.newCheckBox(buttonSize.width/2,buttonLayotSize.height -((i -0.5) * buttonSize.height),
                                        {n = _res("ui/common/common_btn_sidebar_common.png"),
                                         s = _res("ui/common/common_btn_sidebar_selected.png")})
        local label = display.newLabel(buttonSize.width /2 - 5 , buttonSize.height /2 + 25 ,fontWithColor(7,{ fontSize = 22, color = '3c3c3c', ap = display.CENTER , text =buttonNameTable[i].name
        }) )
        btn:addChild(label)
        label:setTag(111)
        btn:setTag(buttonNameTable[i].tag)

        if BUTTON_CLICK.APPLY_REQUEST == buttonNameTable[i].tag then
            RemindIcon.addRemindIcon({parent = btn, tag = buttonNameTable[i].tag, po = cc.p(buttonSize.width - 25, buttonSize.height - 15)})
        end
        buttonTable[tostring(buttonNameTable[i].tag)] = btn
        buttonLayot:addChild(btn)
    end
    --右侧的Layout
    local contentSize = bgSize
    local contentLayout =  display.newLayer(bgSize.width/2 ,bgSize.height /2 , { size = contentSize   } )
    bgLayout:addChild(contentLayout)
    contentLayout:setAnchorPoint(display.CENTER)
    self:addChild(bgLayout,2)
    -- display.animationIn(bgLayout,function()
        -- PlayAudioClip(AUDIOS.UI.ui_window_open.id)
    -- end)

    self.viewData = {
        buttonTable = buttonTable ,
        contentLayout = contentLayout ,
        buttonLayot =  buttonLayot ,
        closeView = closeView ,
        bg = bg ,
    }
end
return UnionInforView
