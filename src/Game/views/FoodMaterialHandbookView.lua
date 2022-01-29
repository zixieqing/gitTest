---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:37 AM
---
--[[
背包系统UI
--]]
---@class FoodMaterialHandbookView
local GameScene = require( "Frame.GameScene" )

local FoodMaterialHandbookView = class('FoodMaterialHandbookView', GameScene)

local RES_DICT = {
    LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
    DESBG 			= 'ui/backpack/bag_bg_font.png',
    Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
    Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
    Btn_Sale 		= "ui/common/common_btn_orange.png",
    Img_cartoon 	= "ui/common/common_ico_cartoon_1.png",
    Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",

}

local BTN_TAG = {
    SALE = 1,
    GET = 2,
}

function FoodMaterialHandbookView:ctor( ... )
    --创建页面
    local view = require("common.TitlePanelBg").new({ title = __('食材图鉴'), type = 11, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("FoodMaterialHandbookMediator")
    end})
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)

    local function CreateTaskView( ... )
        local size = cc.size(1046,590)
        local cview = CLayout:create(size)

        local kongBg = CLayout:create(cc.size(900,590))
        -- kongBg:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(0,0)})
        view.viewData.view:addChild(kongBg,9)

        local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
        display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,size.height * 0.5)})
        display.commonLabelParams(dialogue_tips,{text = __('当前页面暂时为空'), fontSize = 24, color = '#4c4c4c'})
        kongBg:addChild(dialogue_tips, 6)

        -- 中间小人
        local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
        kongBg:addChild(loadingCardQ, 6)
        loadingCardQ:setScale(0.7)
        kongBg:setVisible(false)

        --添加多个按钮功能
        local buttonGroupView = CLayout:create(size)
        display.commonUIParams(buttonGroupView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        view.viewData.view:addChild(buttonGroupView, 30)

        local img_cartoon = display.newImageView(_res(RES_DICT.Img_cartoon), 0, 0)
        display.commonUIParams(img_cartoon, {ap = cc.p(1,0), po = cc.p(70,510)})
        buttonGroupView:addChild(img_cartoon,11)

        local taskCData = {
            {name = __('食材'), 	 	tag = 1004},
        }
        local buttons = {}
        for i,v in ipairs(taskCData) do
            local tabButton = display.newCheckBox(0,0,
            {n = _res(RES_DICT.Btn_Normal),
                s = _res(RES_DICT.Btn_Pressed),})
            local buttonSize = tabButton:getContentSize()
            display.commonUIParams(
            tabButton,
            {
                ap = cc.p(1, 0.5),
                po = cc.p(size.width + 4,
                size.height + 20 - (i) * (buttonSize.height - 30))
            })
            buttonGroupView:addChild(tabButton,-1)
            tabButton:setTag(v.tag)
            buttons[tostring( v.tag )] = tabButton


            local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 ,utils.getLocalCenter(tabButton).y,
            {ttf = true, font = TTF_GAME_FONT, text = v.name, fontSize = 22, color = '3c3c3c', ap = cc.p(0.5, 0)})--2b2017
            tabButton:addChild(tabNameLabel1)
            tabNameLabel1:setTag(3)
        end
        --滑动层背景图
        local ListBg = display.newImageView(_res(RES_DICT.LISTBG), 428, size.height - 10,--
        {scale9 = true, size = cc.size(450, 550),ap = cc.p(0, 1)})	--630, size.height - 20
        cview:addChild(ListBg)
        local ListBgFrameSize = ListBg:getContentSize()
        --添加列表功能
        local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
        local taskListCellSize = cc.size(taskListSize.width/4 , 114)

        local gridView = CGridView:create(taskListSize)
        gridView:setSizeOfCell(taskListCellSize)
        gridView:setColumns(4)
        gridView:setAutoRelocate(true)
        cview:addChild(gridView)
        gridView:setAnchorPoint(cc.p(0, 1.0))
        gridView:setPosition(cc.p(ListBg:getPositionX() + 4, ListBg:getPositionY() - 2))


        local Bg_describe = display.newImageView(_res(RES_DICT.Bg_describe),0,0)
        cview:addChild(Bg_describe,2)
        display.commonUIParams(Bg_describe, {ap = cc.p(0,0), po = cc.p(48, 104)})




        local reward_rank = display.newImageView(_res('ui/common/common_frame_goods_1.png'),0,1.0,{as = false})
        cview:addChild(reward_rank,1)
        reward_rank:setScale(1.1)
        display.commonUIParams(reward_rank, {ap = cc.p(0,0), po = cc.p(73, 435)})

        local reward_img = display.newImageView(('ui/home/task/task_ico_active.png'),0,0)
        reward_rank:addChild(reward_img,1)
        reward_img:setPosition(cc.p(reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2 ))
        reward_img:setVisible(false)
        local pox = reward_rank:getPositionX() + reward_rank:getContentSize().width  + 25
        local poy = reward_rank:getPositionY() + reward_rank:getContentSize().height - 8


        local fragmentPath = _res('ui/common/common_ico_fragment_1.png')
        local fragmentImg = display.newImageView(_res(fragmentPath), reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2,{as = false})
        reward_rank:addChild(fragmentImg,6)
        fragmentImg:setVisible(false)

        local bgName = display.newImageView(('ui/backpack/bag_bg_font_name.png'),0,0)
        bgName:setAnchorPoint(cc.p(0,1))
        cview:addChild(bgName)
        bgName:setPosition(cc.p(pox - 10, poy))

        local DesNameLabel = display.newLabel(0 , 0,
        {text = ' ', fontSize = 24, color = 'be462a', ap = cc.p(0, 1)})
        cview:addChild(DesNameLabel)
        DesNameLabel:setPosition(cc.p(pox, poy))


        local DesNumLabel = display.newLabel(0, 0,
        {text = ' ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0, 0.5)})
        cview:addChild(DesNumLabel)
        DesNumLabel:setPosition(cc.p(pox, poy - 80))

        local DesPriceLabel = display.newLabel(0 , 0,
        {text = ' ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0, 0.5)})
        cview:addChild(DesPriceLabel)
        DesPriceLabel:setPosition(cc.p(pox  , poy - 50))



        --物品描述文字背景图
        local desBg = display.newImageView(_res(RES_DICT.DESBG), 73, 120,{scale9 = true, size = cc.size(325, 303)})
        display.commonUIParams(desBg, {ap = display.LEFT_BOTTOM})
        cview:addChild(desBg)

        local DesLabel = display.newLabel(0, 0,
        {text = '', fontSize = 22, color = '#5c5c5c', w = 275, h = 292})
        DesLabel:setPosition(cc.p(desBg:getContentSize().width * 0.5 + 5, desBg:getContentSize().height - 30))
        display.commonUIParams(DesLabel, {ap = cc.p(0.5 ,1)})
        DesLabel:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
        desBg:addChild(DesLabel)

        local saleBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale)})
        display.commonUIParams(saleBtn, {ap = cc.p(0,0), po = cc.p(73,32)})
        display.commonLabelParams(saleBtn,fontWithColor(14,{text = __('出售')}))
        saleBtn:setTag(BTN_TAG.SALE)
        cview:addChild(saleBtn)

        local getBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale)})
        display.commonUIParams(getBtn, {ap = cc.p(0,0), po = cc.p(258,32)})
        display.commonLabelParams(getBtn,fontWithColor(14,{text = __('获取')}))
        getBtn:setTag(BTN_TAG.GET)
        cview:addChild(getBtn)

        view:AddContentView(cview)

        return {
            bgView 			= cview,
            -- tabNameLabel 	= tabNameLabel,
            buttons 		= buttons,
            gridView 		= gridView,
            ListBg 			= ListBg,
            reward_rank		= reward_rank,
            reward_img 		= reward_img,
            DesNameLabel 	= DesNameLabel,
            -- DesTypeLabel 	= DesTypeLabel,
            DesNumLabel 	= DesNumLabel,
            DesPriceLabel 	= DesPriceLabel,
            DesLabel 		= DesLabel,
            saleBtn			= saleBtn,
            getBtn			= getBtn,
            kongBg 			= kongBg,
            img_cartoon 	= img_cartoon,
            buttonGroupView = buttonGroupView ,
            fragmentImg 	= fragmentImg,
        }
    end
    xTry(function()
        self.viewData_ = CreateTaskView()
    end, __G__TRACKBACK__)

    local action = cc.Sequence:create(cc.DelayTime:create(0.1),cc.MoveBy:create(0.2,cc.p(0, - 500)))
    self.viewData_.img_cartoon:runAction(action)
end


return FoodMaterialHandbookView
