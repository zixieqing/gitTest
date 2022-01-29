---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:37 AM
---
--[[
背包系统UI
--]]
---@class RealNameAuthenicationView
local GameScene = require( "Frame.GameScene" )
-- 修改玩家的头像和头像框的类
local RealNameAuthenicationView = class('RealNameAuthenicationView', GameScene)

local RES_DICT = {
    LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
    DESBG 			= 'ui/backpack/bag_bg_font.png',
    Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
    Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
    Btn_Sale 		= "ui/common/common_btn_orange.png",
    Btn_Width  		= "ui/common/common_btn_white_default.png",
    Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",

}

local BTN_TAG = {
    CANCEL_BTN = 1102,
    AUTHOR_BTN = 1103,
    NAME_TEXT  = 1104,
    ID_TEXT    = 1105,
}

function RealNameAuthenicationView:ctor(param)
    --创建页面
    ---@type TitlePanelBg
    local view = require("common.TitlePanelBg").new({ title = __('实名认证') , type = 7 , offsetY = 3 ,offsetX = 0})
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)
    view.viewData.eaterLayer:setOnClickScriptHandler(
            function()
                if param and checkint(param.canClose) == 0 then return end
                PlayAudioByClickClose()
                AppFacade.GetInstance():UnRegsitMediator("RealNameAuthenicationMediator")
            end
    )
    local function CreateTaskView( ... )
        local bgSize = view.viewData.view:getContentSize()
        -- 吞噬层
        local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER ,  size = bgSize , color = cc.c4b( 0, 0,0,0)})
        view.viewData.view:addChild(swallowLayer,9)
        view.viewData.closeBtn:setVisible(false)
        local size = cc.size(520, 484)
        local cview =  display.newLayer(bgSize.width/2  , 0 , { ap = display.CENTER_BOTTOM , size = size   })
        view.viewData.view:addChild(cview,9)


        --local topSize = cc.size(687, 504)
        --local topLayout = display.newLayer(size.width/2 , size.height , { ap = display.CENTER_TOP, size = topSize  })
        --cview:addChild(topLayout)
        ---- 顶部图片的背景
        --local topBgImage =  display.newImageView(_res('ui/common/common_bg_goods.png'),topSize.width/2,topSize.height/2,{ap =display.CENTER  , size = topSize , scale9 = true })
        --topLayout:addChild(topBgImage)
        --local taskListSize = cc.size(656 , 500)
        --
        --local taskListCellSize = cc.size(taskListSize.width/4 , 175)
        --local gridView = CGridView:create(taskListSize)
        --gridView:setSizeOfCell(taskListCellSize)
        --gridView:setColumns(4)
        --gridView:setAutoRelocate(true)
        --topLayout:addChild(gridView)
        --gridView:setAnchorPoint(cc.p(0.5, 1.0))
        --gridView:setPosition(cc.p(topSize.width/2 ,topSize.height))

        local narrateLabel = display.newLabel(size.width/2 , 472 , {fontSize = 20,   ap = display.CENTER_TOP ,hAlign = cc.TEXT_ALIGNMENT_LEFT , w = 425, color = "#5c5c5c" ,
                                                                             text = __('根据国家新闻出版署出台的《关于防止未成年人沉迷网络游戏的通知》请先登记本人的实名信息')
        })
        cview:add(narrateLabel)

        local lineImage = display.newImageView(_res('ui/home/infor/certification_line') , size.width/2,400  )
        cview:add(lineImage)

        local statementLabel = display.newLabel(size.width/2 , 324 , {fontSize = 20,   ap = display.CENTER_BOTTOM , color = "#a9764a" ,
                                                                                text = __('我们承诺严格保证您的信息安全,绝不泄露')
        })
        cview:add(statementLabel)
        local bottomSize = cc.size(280,240)
        local  bottomLayout = display.newLayer(size.width/2 , 300, { ap = display.CENTER_TOP , size = bottomSize })
        cview:add(bottomLayout)


        --local descrName = ccui.EditBox:create(cc.size(265, 160), _res('ui/home/infor/certification_bg.png'))
        local nameText = ccui.EditBox:create(cc.size(340, 40), _res('ui/home/infor/certification_bg'))
        display.commonUIParams(nameText, {po = cc.p(bottomSize.width/2, bottomSize.height -30)})
        bottomLayout:add(nameText)
        nameText:setFontSize(fontWithColor('M2PX').fontSize)
        nameText:setFontColor(ccc3FromInt('#9f9f9f'))
        nameText:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        nameText:setPlaceHolder(__('姓名'))
        nameText:setPlaceholderFontSize(22)
        nameText:setPlaceholderFontColor(ccc3FromInt('#b9b9b9'))
        --descrName:setVisible(false)
        nameText:setMaxLength(100)
        nameText:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        nameText:setTag(BTN_TAG.NAME_TEXT)
        local idNumText = ccui.EditBox:create(cc.size(340, 40), _res('ui/home/infor/certification_bg'))
        display.commonUIParams(idNumText, {po = cc.p(bottomSize.width/2, bottomSize.height - 95 )})
        bottomLayout:add(idNumText)
        idNumText:setFontSize(fontWithColor('M2PX').fontSize)
        idNumText:setFontColor(ccc3FromInt('#9f9f9f'))
        idNumText:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        idNumText:setPlaceHolder(__('身份证号'))
        idNumText:setPlaceholderFontSize(22)
        idNumText:setPlaceholderFontColor(ccc3FromInt('#b9b9b9'))
        --descrName:setVisible(false)
        idNumText:setMaxLength(100)
        idNumText:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        idNumText:setTag(BTN_TAG.ID_TEXT)

        -- 修改Btn 的按钮
        local authorBtn = display.newButton(bottomSize.width/2 + 83 , 50, {n = _res(RES_DICT.Btn_Sale)})
        display.commonLabelParams(authorBtn,fontWithColor(14,{text = __('确定')}))

        bottomLayout:add(authorBtn)
        authorBtn:setScale(0.8)
        authorBtn:setTag(BTN_TAG.AUTHOR_BTN)
        --
        local cancelBtn = display.newButton(bottomSize.width/2 - 83 , 50, {n = _res(RES_DICT.Btn_Width)})
        display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __('取消')}))

        bottomLayout:addChild(cancelBtn)
        cancelBtn:setScale(0.8)
        cancelBtn:setTag(BTN_TAG.CANCEL_BTN)
        if param and checkint(param.canClose) == 0 then
            cancelBtn:setVisible(false)
            authorBtn:setPosition(bottomSize.width/2, 50)
        end
        return {
            bgView    = cview,
            idNumText = idNumText,
            nameText  = nameText,
            authorBtn = authorBtn,
            cancelBtn = cancelBtn
        }
    end
    xTry(function()
        self.viewData_ = CreateTaskView()
    end, __G__TRACKBACK__)
end


return RealNameAuthenicationView
