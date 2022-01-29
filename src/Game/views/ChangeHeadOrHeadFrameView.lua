---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:37 AM
---
--[[
背包系统UI
--]]
---@class ChangeHeadOrHeadFrameView
local GameScene = require( "Frame.GameScene" )
-- 修改玩家的头像和头像框的类
local ChangeHeadOrHeadFrameView = class('ChangeHeadOrHeadFrameView', GameScene)

local RES_DICT = {
    LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
    DESBG 			= 'ui/backpack/bag_bg_font.png',
    Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
    Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
    Btn_Sale 		= "ui/common/common_btn_orange.png",
    Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",

}

local BTN_TAG = {
    CHANGE_BTN = 1102 ,
}

function ChangeHeadOrHeadFrameView:ctor(param)
    --创建页面
    param =param or  {}
    self.datas = param
    local title = param.title
    ---@type TitlePanelBg
    local view = require("common.TitlePanelBg").new({ title = title , type = 2 , offsetY = 3 ,offsetX = 0})
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)
    view.viewData.eaterLayer:setOnClickScriptHandler(
        function()
            PlayAudioByClickClose()
            if self.datas.callback then
                self.datas.callback()
            end
        end
    )
    local function CreateTaskView( ... )
        local bgSize = view.viewData.view:getContentSize()
        -- 吞噬层
        local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER ,  size = bgSize , color = cc.c4b( 0, 0,0,0)})
        view.viewData.view:addChild(swallowLayer,9)
        view.viewData.closeBtn:setVisible(false)
        local size = cc.size(700, 586)
        local cview =  display.newLayer(bgSize.width/2  , 0 , { ap = display.CENTER_BOTTOM , size = size  })
        view.viewData.view:addChild(cview,9)


        local topSize = cc.size(687, 504)
        local topLayout = display.newLayer(size.width/2 , size.height , { ap = display.CENTER_TOP, size = topSize  })
        cview:addChild(topLayout)
        -- 顶部图片的背景
        local topBgImage =  display.newImageView(_res('ui/common/common_bg_goods.png'),topSize.width/2,topSize.height/2,{ap =display.CENTER  , size = topSize , scale9 = true })
        topLayout:addChild(topBgImage)
        local taskListSize = cc.size(656 , 500)

        local taskListCellSize = cc.size(taskListSize.width/4 , 190)
        local gridView = CGridView:create(taskListSize)
        gridView:setSizeOfCell(taskListCellSize)
        gridView:setColumns(4)
        gridView:setAutoRelocate(true)
        topLayout:addChild(gridView)
        gridView:setAnchorPoint(cc.p(0.5, 1.0))
        gridView:setPosition(cc.p(topSize.width/2 ,topSize.height))

        -- 修改Btn 的按钮
        local changeBtn = display.newButton(size.width/2 , 43, {n = _res(RES_DICT.Btn_Sale)})
        display.commonLabelParams(changeBtn,fontWithColor(14,{text = __('更换')}))
        changeBtn:setTag(BTN_TAG.CHANGE_BTN)
        cview:addChild(changeBtn)


        return {
            bgView 			= cview,
            gridView 		= gridView,
            changeBtn			= changeBtn,
            topLayout = topLayout

        }
    end
    xTry(function()
        self.viewData_ = CreateTaskView()
    end, __G__TRACKBACK__)
end


return ChangeHeadOrHeadFrameView
