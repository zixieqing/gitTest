---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/4/4 2:44 PM
---
--[[
探索系统探索页面UI
--]]

---@class ExchangeCardCell
local ExchangeCardCell = class('ExchangeCardCell', function ()
    local node = CGridViewCell:new()
    node.name = 'Game.views.exchange.ExchangeCardCell'
    node:enableNodeEvents()
    node:setAnchorPoint(cc.p(0, 0))
    return node
end)
local RES_DICT = {
    ACTIVITY_DEBRIS_BG               = _res("ui/home/activity/exchangeCard/activity_debris_bg.png"),
    ACTIVITY_DEBRIS_BTN_ADD          = _res("ui/home/activity/exchangeCard/activity_debris_btn_add.png"),
    ACTIVITY_DEBRIS_BTN_MINUS        = _res("ui/home/activity/exchangeCard/activity_debris_btn_minus.png"),
    ACTIVITY_DEBRIS_EXCHANGE         = _res("ui/home/activity/exchangeCard/activity_debris_exchange.png"),
    ACTIVITY_DEBRIS_EXCHANGE_BG      = _res("ui/home/activity/exchangeCard/activity_debris_exchange_bg.png"),
    ACTIVITY_DEBRIS_GOODS_BG_DEFAULT = _res("ui/home/activity/exchangeCard/activity_debris_goods_bg_default.png"),
    ACTIVITY_DEBRIS_GOODS_BG_SELECT  = _res("ui/home/activity/exchangeCard/activity_debris_goods_bg_select.png"),
    ACTIVITY_DEBRIS_ICON_UR          = _res("ui/home/activity/exchangeCard/activity_debris_icon_ur.png"),
    ACTIVITY_DEBRIS_LIST_BG          = _res("ui/home/activity/exchangeCard/activity_debris_list_bg.png"),
    ACTIVITY_DEBRIS_Q_MIFAN          = _res("ui/home/activity/exchangeCard/activity_debris_q_mifan.png"),
    ACTIVITY_DEBRIS_RUMBER_BG        = _res("ui/home/activity/exchangeCard/activity_debris_rumber_bg.png"),
    ACTIVITY_DEBRIS_RUMBER_BG_SHADOW = _res("ui/home/activity/exchangeCard/activity_debris_rumber_bg_shadow.png"),
    COOKING_LEVEL_UP_ICO_ARROW       = _res("ui/home/activity/exchangeCard/cooking_level_up_ico_arrow.png"),
}
local BackpackCell = require('home.BackpackCell')
local cardFragmentConf = CommonUtils.GetConfigAllMess('cardFragment' , 'goods')

function ExchangeCardCell:ctor( ... )
    local cellSize = cc.size(180,180)
    self:setContentSize(cellSize)
    local view = display.newLayer(cellSize.width/2 ,cellSize.height/2, {ap = display.CENTER , size = cellSize  })
    self:addChild(view)
    -- 背景图片
    local bgImage = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_GOODS_BG_DEFAULT , cellSize.width/2 , cellSize.height/2)
    view:addChild(bgImage)

    local touchView = display.newLayer(cellSize.width/2 ,cellSize.height/2, {ap = display.CENTER , size = cellSize , color = cc.c4b(0,0,0,0) , enable = true })
    view:addChild(touchView)

    local heightLine = 20
    -- 输入数字的回调
    local editBoxSize = cc.size(110 , 45 )
    local  editBox = display.newLayer(cellSize.width/2 , heightLine , {ap = display.CENTER_BOTTOM , size = editBoxSize , color = cc.c4b(0,0,0,0) , enable= true  })
    view:addChild(editBox)
    local editBoxImage = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_RUMBER_BG , editBoxSize.width/2 , editBoxSize.height/2 )
    editBox:addChild(editBoxImage)

    local numLabel = display.newLabel(0,0,fontWithColor(17, {text = "" , fontSize = 24 }))
    numLabel:setAnchorPoint(display.CENTER)
    numLabel:setHorizontalAlignment(display.TAR)
    numLabel:setPosition(editBoxSize.width/2, editBoxSize.height/2)
    editBox:addChild(numLabel)
    numLabel:setString('10')
    editBox:setVisible(false)

    --减少的按钮
    local reductionBtn = display.newButton(cellSize.width/2 - 55 , heightLine + 21, { n = RES_DICT.ACTIVITY_DEBRIS_BTN_MINUS  } )

    view:addChild(reductionBtn)
    reductionBtn:setVisible(false)

    -- 添加的按钮
    local addBtn = display.newButton(cellSize.width/2  +  55 , heightLine+ 21 , { n = RES_DICT.ACTIVITY_DEBRIS_BTN_ADD  } )

    view:addChild(addBtn)
    addBtn:setVisible(false)

    local  bgShadow = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_RUMBER_BG_SHADOW , cellSize.width/2 , heightLine + 20 )
    view:addChild(bgShadow)
    bgShadow:setVisible(true   )

    local  pCell = BackpackCell.new( cc.size(108, 115))

    touchView:addChild(pCell)
    pCell:setPosition(cellSize.width/2 ,cellSize.height /2 +30 )
    pCell:setScale(0.9)
    pCell:setAnchorPoint(display.CENTER)
    self.viewData = {
        bgImage = bgImage ,
        pCell = pCell ,
        bgShadow = bgShadow ,
        numLabel = numLabel ,
        addBtn = addBtn ,
        editBox = editBox ,
        reductionBtn = reductionBtn ,
        touchView = touchView
    }
end
--==============================--
---@Description: 设置cell 是否为选中状态
---@author : xingweihao
---@date : 2019/4/4 3:53 PM
--==============================--
function ExchangeCardCell:SetCellIsSelect(isSelect)
    self.viewData.addBtn:setVisible(isSelect)
    self.viewData.reductionBtn:setVisible(isSelect)
    self.viewData.editBox:setVisible(isSelect)
    local texture = isSelect and RES_DICT.ACTIVITY_DEBRIS_GOODS_BG_SELECT  or RES_DICT.ACTIVITY_DEBRIS_GOODS_BG_DEFAULT
    self.viewData.bgImage:setTexture(texture)
    self.viewData.pCell.selectImg:setVisible(isSelect)
    self.viewData.bgShadow:setVisible(not  isSelect)
end

--==============================--
---@Description: 更新UI
---@param itemData table 表示的卡牌碎片的具体数据
---@param isSelect boolean 是否被选中
---@param selectNum number 数量
---@author : xingweihao
---@date : 2019/4/4 4:04 PM
--==============================--
function ExchangeCardCell:UpdateUI(itemData , isSelect , selectNum)
    local data = cardFragmentConf[tostring(itemData.goodsId)]
    local quality = 1
    if data then
        if data.quality then
            quality = data.quality
        end
    end
    local pCell = self.viewData.pCell
    pCell.maskImg:setVisible(false)
    local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
    local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
    if not utils.isExistent(drawBgPath) then
        drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
        fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(1)..'.png')
    end
    pCell.fragmentImg:setTexture(fragmentPath)
    pCell.toggleView:setNormalImage(drawBgPath)
    pCell.toggleView:setSelectedImage(drawBgPath)
    pCell.toggleView:setScale(0.92)
    if data then
        pCell.fragmentImg:setVisible(true)
    else
        pCell.fragmentImg:setVisible(false)
    end
    pCell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_select.png'))
    pCell.numLabel:setString(tostring(itemData.amount))
    pCell.goodsImg:setVisible(true)
    local node = pCell.goodsImg
    local goodsId = itemData.goodsId
    local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
    node:setTexture(_res(iconPath))
    self:SetCellIsSelect(isSelect)
    selectNum = checkint(selectNum)
    self:UpdateNum(selectNum)
end
function ExchangeCardCell:UpdateNum(selectNum)
    display.commonLabelParams(self.viewData.numLabel, {text = tostring(selectNum) } )
end

return ExchangeCardCell