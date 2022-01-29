
local GameScene = require( 'Frame.GameScene' )
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@class SeasonnewYearPointRewardView :GameScene
local SeasonnewYearPointRewardView = class('SeasonnewYearPointRewardView', GameScene)
local RES_DICT = {
    BG_IMAGE = _res('ui/home/activity/seasonlive/season_point_bg'),
    TOP_CENTER_IAMGE  = _res('ui/home/activity/seasonlive/season_point_bg_bar'),
    FRAME_SP =  _res('ui/home/activity/seasonlive/season_point_bg_frame_sp'),
    FRAME_DEFAULT =  _res('ui/home/activity/seasonlive/season_point_bg_frame_default'),
    FRAME_SP_ICO =  _res('ui/home/activity/seasonlive/season_point_bg_frame_sp_ico'),
    LABEL_DEFAULT = _res('ui/home/activity/seasonlive/season_point_label_default'),
    LABEL_SP = _res('ui/home/activity/seasonlive/season_point_label_sp'),
    LINE_DEFAULT = _res('ui/home/activity/seasonlive/season_point_line_default'),
    LINE_SP = _res('ui/home/activity/seasonlive/season_point_line_sp'),
    BAR_BGIMAGE       = _res('ui/home/activity/seasonlive/season_loots_bar_bg'),
    BAR_IMAGE         = _res('ui/home/activity/seasonlive/season_loots_bar'),
}

function SeasonnewYearPointRewardView:ctor()
    self.super.ctor(self,'home.SeasonnewYearPointRewardView')
    self:InitUI()
end
--==============================--
--desc:初始化界面
--time:2017-08-01 03:13:56
--@return
--==============================--
function SeasonnewYearPointRewardView:InitUI()
    local closeLayer = display.newLayer(0,0,{ ap = display.CENTER , color = cc.c4b(0,0,0,150) , enable =  true})
    closeLayer:setPosition(display.center)
    self:addChild(closeLayer)



    local bgImage = display.newImageView(RES_DICT.BG_IMAGE)
    local bgSize = bgImage:getContentSize()
    local bgLayout = display.newLayer(display.width/2 , display.height-30, { ap = display.CENTER_BOTTOM , color1 = cc.r4b() , size =bgSize})
    bgLayout:addChild(bgImage)

    bgImage:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
    self:addChild(bgLayout)

    local topCenterImage = display.newImageView(RES_DICT.TOP_CENTER_IAMGE)
    local topCenterSize  = topCenterImage:getContentSize()
    topCenterImage:setPosition(cc.p(topCenterSize.width / 2, topCenterSize.height / 2))
    local topCenterLayer = display.newLayer(bgSize.width/2, -10, { ap = display.CENTER, size = topCenterSize, color1 = cc.r4b() })
    bgLayout:addChild(topCenterLayer)
    topCenterLayer:addChild(topCenterImage)

    local progressBarThree = CProgressBar:create(RES_DICT.BAR_IMAGE)
    progressBarThree:setBackgroundImage(RES_DICT.BAR_BGIMAGE)
    progressBarThree:setDirection(eProgressBarDirectionLeftToRight)
    progressBarThree:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarThree:setPosition(cc.p(topCenterSize.width / 2, topCenterSize.height / 2))
    topCenterLayer:addChild(progressBarThree)
    progressBarThree:setMaxValue(5000)
    progressBarThree:setValue(0)
    -- 任务进度
    local progressBarOneSize = progressBarThree:getContentSize()
    local prograssThreeLabel = display.newLabel(progressBarOneSize.width / 2, progressBarOneSize.height / 2, fontWithColor('3', { text = "1111" }) )
    progressBarThree:addChild(prograssThreeLabel,10)
    -- 有奖励可以领取的时候的提示
    local pointImage = display.newImageView(RES_DICT.POINT_IMAGE, topCenterSize.width - 95, topCenterSize.height / 2 + 10 )
    topCenterLayer:addChild(pointImage)

    local centerSize = cc.size(600, 650)
    local centerLayer = display.newLayer(bgSize.width /2 , bgSize.height , { ap = display.CENTER_TOP , color1 = cc.r4b() , size = centerSize})
    bgLayout:addChild(centerLayer)
    local swallowLayer = display.newLayer(centerSize.width/2 , centerSize.height/2, { ap = display.CENTER , enable = true , color = cc.c4b(0,0,0,0) , size =centerSize})
    centerLayer:addChild(swallowLayer)
    local listSize = cc.size(440,470)
    local rewardList = CListView:create(listSize)
    rewardList:setDirection(eScrollViewDirectionVertical)
    rewardList:setAnchorPoint(display.RIGHT_TOP)
    rewardList:setPosition(cc.p(centerSize.width - 55, bgSize.height-195))
    centerLayer:addChild(rewardList)
    self.viewData = {
        bgLayout =  bgLayout ,
        topCenterLayer =  topCenterLayer ,
        centerSize =centerSize ,
        progressBarThree = progressBarThree ,
        rewardList  =rewardList ,
        prograssThreeLabel = prograssThreeLabel ,
        centerLayer = centerLayer ,
        closeLayer = closeLayer
    }
end
--[[
    创建第一个Cell
--]]
function SeasonnewYearPointRewardView:CreateOneCell(data)
    data = data or {}
    local frameImage = display.newImageView(RES_DICT.FRAME_SP)
    local frameImageSize = frameImage:getContentSize()
    local frameLayout = display.newLayer(frameImageSize.width/2 ,frameImageSize.height/2 ,
                             {ap = display.CENTER , size = frameImageSize , color1 = cc.r4b()} )
    frameImage:setPosition(cc.p(frameImageSize.width/2 , frameImageSize.height/2))
    frameLayout:addChild(frameImage)

    -- 添加icon
    local iconImage = display.newImageView(RES_DICT.FRAME_SP_ICO, 0,frameImageSize.height + 12, {ap = display.LEFT_TOP})
    frameLayout:addChild(iconImage)
    local leftSize = cc.size(150, 95)
    -- 左侧的叙述
    local leftLayout = display.newLayer(35 , frameImageSize.height/2 , { ap = display.LEFT_CENTER , color1 = cc.r4b()  , size = leftSize})
    local label = display.newLabel(0, leftSize.height - 15 , fontWithColor('10' , { ap = display.LEFT_CENTER , text = __('压岁钱达到')}))
    leftLayout:addChild(label)
    local spLine = display.newImageView(RES_DICT.LINE_SP , 0,leftSize.height - 28  , { ap = display.LEFT_CENTER})
    leftLayout:addChild(spLine)
    frameLayout:addChild(leftLayout)

    local  labelSp = display.newImageView(RES_DICT.LABEL_SP , 0,leftSize.height - 47  , { ap = display.LEFT_CENTER})
    leftLayout:addChild(labelSp)
    local newYearPoint = display.newLabel(0, leftSize.height - 47 , fontWithColor('14' , { fontSize = 22, ap = display.LEFT_CENTER , text = data.newYearPoint}))
    leftLayout:addChild(newYearPoint)
    local rewardLabel = display.newLabel(0, leftSize.height - 80 , fontWithColor('10' , { ap = display.LEFT_CENTER , text = __('可获得:')}))
    leftLayout:addChild(rewardLabel)
    local reward = data.reward or {}
    local goodsIcon = require('common.GoodNode').new({id = reward[1].goodsId, amount = reward[1].num, showAmount = true })
    --goodsIcon:setScale(0.8)
    goodsIcon:setAnchorPoint(display.CENTER)
    goodsIcon:setPosition(cc.p(frameImageSize.width/2, frameImageSize.height/2 +2 ))
    frameLayout:addChild(goodsIcon)

    display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = reward[1].goodsId, type = 1})
    end})
    local rewardBtn = display.newButton(frameImageSize.width - 45 , frameImageSize.height/2 ,
                                        {
                                            ap = display.RIGHT_CENTER ,
                                            n =_res('ui/common/common_btn_orange') ,

                                        })
    rewardBtn:setTag(checkint(data.id))
    display.commonLabelParams(rewardBtn, fontWithColor('14' ,{ text = __('领取')}) )
    frameLayout:addChild(rewardBtn)
    local cellLayout = display.newLayer(frameImageSize.width/2, frameImageSize.height/2 , {ap = display.CENTER ,size =frameImageSize , color1 = cc.r4b()  })
    cellLayout:addChild(frameLayout)
    frameLayout:setPosition(cc.p(frameImageSize.width/2 ,frameImageSize.height/2))
    cellLayout.viewData = {
        frameLayout = frameLayout ,
        rewardBtn = rewardBtn
    }
    return cellLayout
end
--[[
    创建第一个Cell
--]]
function SeasonnewYearPointRewardView:CreateTwoCell(data)
    data = data or {}
    local frameImage = display.newImageView(RES_DICT.FRAME_DEFAULT)
    local frameImageSize = frameImage:getContentSize()
    local frameLayout = display.newLayer(frameImageSize.width/2 ,frameImageSize.height/2 ,
                                         {ap = display.CENTER , size = frameImageSize , color1 = cc.r4b()} )
    frameImage:setPosition(cc.p(frameImageSize.width/2 , frameImageSize.height/2))
    frameLayout:addChild(frameImage)

    -- 添加icon
    local leftSize = cc.size(150, 95)
    -- 左侧的叙述
    local leftLayout = display.newLayer(5 , frameImageSize.height/2 , { ap = display.LEFT_CENTER , color1 = cc.r4b()  , size = leftSize})
    local label = display.newLabel(0, leftSize.height - 15 , fontWithColor('10' , { ap = display.LEFT_CENTER , text = __('压岁钱达到')}))
    leftLayout:addChild(label)
    local spLine = display.newImageView(RES_DICT.LINE_DEFAULT , 0,leftSize.height - 28  , { ap = display.LEFT_CENTER})
    leftLayout:addChild(spLine)
    frameLayout:addChild(leftLayout)

    local  labelSp = display.newImageView(RES_DICT.LABEL_DEFAULT , 0,leftSize.height - 47  , { ap = display.LEFT_CENTER})
    leftLayout:addChild(labelSp)
    local newYearPoint = display.newLabel(0, leftSize.height - 47 , fontWithColor('14' , { fontSize = 22, ap = display.LEFT_CENTER , text = data.newYearPoint}))
    leftLayout:addChild(newYearPoint)
    local rewardLabel = display.newLabel(0, leftSize.height - 80 , fontWithColor('6' , {fontSize = 20,  ap = display.LEFT_CENTER , text = __('可获得:')}))
    leftLayout:addChild(rewardLabel)
    local reward = data.reward or {}
    local goodsIcon = require('common.GoodNode').new({id = reward[1].goodsId, amount = reward[1].num, showAmount = true })
    goodsIcon:setScale(0.8)
    goodsIcon:setAnchorPoint(display.CENTER)
    goodsIcon:setPosition(cc.p(frameImageSize.width/2-10 , frameImageSize.height/2   ))
    frameLayout:addChild(goodsIcon)
    display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = reward[1].goodsId, type = 1})
    end})
    local rewardBtn = display.newButton(frameImageSize.width - 20 , frameImageSize.height/2 ,
                                        {
                                            ap = display.RIGHT_CENTER ,
                                            n =_res('ui/common/common_btn_orange')
                                        })
    rewardBtn:setTag(checkint(data.id))
    display.commonLabelParams(rewardBtn, fontWithColor('14' ,{ text = __('领取')}) )
    frameLayout:addChild(rewardBtn)
    local cellSize = cc.size(frameImageSize.width , frameImageSize.height + 5)
    local cellLayout = display.newLayer(frameImageSize.width/2, frameImageSize.height/2 , {ap = display.CENTER ,size =cellSize , color1 = cc.r4b()  })
    cellLayout:addChild(frameLayout)
    frameLayout:setPosition(cc.p(cellSize.width/2 ,cellSize.height/2))
    cellLayout.viewData = {
        frameLayout = frameLayout ,
        rewardBtn = rewardBtn
    }
    return cellLayout
end




return SeasonnewYearPointRewardView
