---
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---
---@class UnionApplySystemView
local UnionApplySystemView = class('home.UnionApplySystemView',function ()
    local node = CLayout:create( display.size)
    node.name = 'Game.views.UnionApplySystemView'
    node:enableNodeEvents()
    return node
end)
local APPLAY_SYSTEM = {
    ALLOW_ANYONE         = 1,
    NEED_PRESIDENT_ALLOW = 2,
    NOT_ALLOW_ANYONE     = 3

}
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CELL_TABLE = {
    [tostring(APPLAY_SYSTEM.ALLOW_ANYONE)] = __('允许任何人加入'),
    [tostring(APPLAY_SYSTEM.NEED_PRESIDENT_ALLOW)] = __('需要通过会长或者副会长的批准'),
    [tostring(APPLAY_SYSTEM.NOT_ALLOW_ANYONE)] = __('不允许允许任何人申请')
}
function UnionApplySystemView:ctor()
    self.nowApplyPermission = APPLAY_SYSTEM.ALLOW_ANYONE  -- 当前权限
    self.applyPermission = APPLAY_SYSTEM.ALLOW_ANYONE -- 初始权限
    self:initUI()
end

function UnionApplySystemView:initUI()
    local bgImage = display.newImageView(_res('ui/common/common_bg_7'))
    local bgSize = bgImage:getContentSize()

    local closeLayer = display.newLayer(display.cx, display.cy ,
        { ap = display.CENTER , color = cc.c4b(0,0,0,100) , enable = true , cb = function ()
            self:runAction(cc.RemoveSelf:create())
        end})
    self:addChild(closeLayer)

    local bgLayout = display.newLayer(display.width/2 ,display.height/2 ,
          {ap = display.CENTER , size = bgSize  } )
    local swallowLayer = display.newLayer(bgSize.width/2 ,bgSize.height/2 ,
          { ap = display.CENTER , size = bgSize , color  = cc.c4b(0,0,0,0) , enable = true })
    bgLayout:addChild(swallowLayer)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    bgLayout:addChild(bgImage)
    self:addChild(bgLayout)

    -- 标签
    local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5  -5 )})
    display.commonLabelParams(titleBg,
                              {text = __('申请设置'),
                               fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
                               offset = cc.p(0, -2)})
    bgImage:addChild(titleBg)


    local contentSize = cc.size(508,390)
    local contentLayout = display.newLayer(bgSize.width/2 ,bgSize.height - 60 ,
        { ap =  display.CENTER_TOP , size = contentSize } )
    bgLayout:addChild(contentLayout)
    -- 背景图片
    local contentBgImage = display.newImageView(_res('ui/common/kitchen_bg_need_food') ,
            contentSize.width /2 ,contentSize.height/2 , {ap = display.CENTER ,scale9 = true , size = contentSize } )
    contentLayout:addChild(contentBgImage)

    local listSize = cc.size(503  ,contentSize.height - 10 )
    local applyList = CListView:create(listSize)
    applyList:setDirection(eScrollViewDirectionVertical)
    applyList:setAnchorPoint(cc.p(0.5, 0.5))
    applyList:setPosition(cc.p(contentSize.width/2 , contentSize.height/2))
    contentLayout:addChild(applyList)

    local sureBtn = display.newButton(bgSize.width/2 , 45 ,{ ap = display.CENTER , n = _res('ui/common/common_btn_orange')})
    display.commonLabelParams(sureBtn , fontWithColor('14',{text = __('确定')}))
    bgLayout:addChild(sureBtn)
    self.viewData = {
        applyList = applyList ,
        sureBtn = sureBtn
    }
end
function UnionApplySystemView:CreateGridCell()

    local bgImage = display.newImageView(_res('ui/common/common_bg_list'))
    local bgSize = bgImage:getContentSize()
    bgSize = cc.size(bgSize.width , bgSize.height +5)
    local bgLayout =  display.newLayer(0,0, {size= bgSize , ap = display.CENTER })
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    bgLayout:addChild(bgImage)

    local selectBtn = display.newCheckBox(bgSize.width - 50, bgSize.height/2  ,
                                  { n = _res('ui/common/common_btn_check_default') ,
                                    s = _res('ui/common/common_btn_check_selected')
                                   })
    bgLayout:addChild(selectBtn)
    -- 系统Label
    local systemLabel = display.newLabel( 50, bgSize.height / 2, fontWithColor('16', { ap = display.LEFT_CENTER, text = __('允许任何加入') }) )
    bgLayout:addChild(systemLabel)
    bgLayout.systemLabel = systemLabel
    bgLayout.bgImage     = bgImage
    bgLayout.selectBtn   = selectBtn
    return bgLayout
end
--[[
    更新界面的信息
--]]
function UnionApplySystemView:UpdateView(applyPermission)
    self.applyPermission = applyPermission
    self.nowApplyPermission = applyPermission
    local viewData  = self.viewData
    local applyList = viewData.applyList
    for k ,v  in pairs(APPLAY_SYSTEM) do
        local cell = self:CreateGridCell()
        cell.selectBtn:setTag(checkint(v))
        cell:setTag(checkint(v))
        self:UpdateCell({  cell  = cell  })
        applyList:insertNodeAtLast(cell)
        cell.selectBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
    applyList:reloadData()
    self.viewData.sureBtn:setOnClickScriptHandler(handler(self ,self.MakeSurePermissionClick))
end
--[[
    更新cell 的信息
    {
        cell            = cell
    }
--]]
function UnionApplySystemView:UpdateCell(data)
    local cell  = data.cell
    local tag = cell:getTag()
    if cell then
        if checkint(self.nowApplyPermission) == tag  then
            cell.bgImage:setTexture(_res('ui/common/btn_selection_bg_select'))
            cell.selectBtn:setChecked(true)
            cell.selectBtn:setEnabled(false)
        else
            cell.bgImage:setTexture(_res('ui/common/common_bg_list'))
            cell.selectBtn:setChecked(false)
            cell.selectBtn:setEnabled(true)
        end
        display.commonLabelParams(cell.systemLabel , {text =  CELL_TABLE[tostring(tag)] , w = 370 , hAlign = display.TAL })
    end
end
--[[
    申请设置按钮
--]]
function UnionApplySystemView:ButtonAction(sender)
    local tag = sender:getTag()
    self.nowApplyPermission = tag
    local nodes = self.viewData.applyList:getNodes()
    for i, v in pairs(nodes) do
        self:UpdateCell({cell = v})
    end
end
--[[
    权限设置请求
--]]
function UnionApplySystemView:MakeSurePermissionClick(sender)
    if self.nowApplyPermission == self.applyPermission then
        uiMgr:ShowInformationTips(__('修改申请权限成功'))
    else
        AppFacade.GetInstance():DispatchSignal(POST.UNION_CHANGEINFO.cmdName ,  { applyPermission = self.nowApplyPermission } )
    end
    self:runAction(cc.RemoveSelf:create())
end

return UnionApplySystemView
