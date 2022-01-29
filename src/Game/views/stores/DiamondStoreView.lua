--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 钻石商店视图
]]
---@class DiamondStoreView
local DiamondStoreView   = class('DiamondStoreView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.DiamondStoreView'})
end)

local RES_DICT = {
    SHOP_FRAME_AD_UP              = _res('ui/stores/base/shop_frame_ad_up.png'),
    SHOP_ICO_TIME                 = _res('ui/stores/base/shop_ico_time.png'),
    SHOP_DIAMOND_BG_TIMELEFT      = _res('ui/stores/base/shop_diamond_bg_timeleft.png'),
    TEMP_AD_UP                    = _res('ui/stores/diamond/temp_ad_up.png'),
    SHOP_BTN_DIAMONDS_DEFAULT     = _res('ui/stores/diamond/shop_btn_diamonds_default.png'),
    SHOP_DIAMONDS_ICO_1           = _res('ui/stores/diamond/shop_diamonds_ico_1.png'),
}
local newImageView                 = display.newImageView
local newLabel                     = display.newLabel
local newLayer                     = display.newLayer
local CreateView = nil


function DiamondStoreView:ctor(size)
    self:setContentSize(size)

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)
end


CreateView = function(size)
    size = cc.size(1080,650 )
    local view = display.newLayer(0, 0, {size = size})
    local swallowLayer = display.newLayer(size.width/2 , size.height/2 , {ap = display.CENTER , color = cc.c4b(0,0,0,0) , enable = true })
    view:addChild(swallowLayer)
    local testLabel = display.newLabel(0, size.height, fontWithColor(9, {ap = display.LEFT_TOP}))
    view:addChild(testLabel)
    return {
        view      = view,
        testLabel = testLabel,
    }
end
function DiamondStoreView:CreateTopView(isActivity)
    if not  isActivity  then
        return {}
    end
    local topSize =  cc.size(1074, 144)
    local topLayout = newLayer(535, 643,
                               { ap = display.CENTER_TOP, size = topSize })
    self.viewData_.view:addChild(topLayout)
    local bgTopImage = newImageView(RES_DICT.SHOP_FRAME_AD_UP, 537, 72,
                                   { ap = display.CENTER, tag = 76, enable = false })
    topLayout:addChild(bgTopImage)
    local WebSprite = require('root.WebSprite')
    local activityImage = WebSprite.new({url = RES_DICT.TEMP_AD_UP,  ad = true})
    topLayout:addChild(activityImage)
    activityImage:setPosition(537, 72)

    local countDownLayout = newLayer(4, 99,
                                     { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(205, 36), enable = true })
    topLayout:addChild(countDownLayout)

    local timeLeftImage = newImageView(RES_DICT.SHOP_DIAMOND_BG_TIMELEFT, 0, 0,
                                       { ap = display.LEFT_BOTTOM, tag = 79, enable = false })
    countDownLayout:addChild(timeLeftImage)

    local icoTimeImage = newImageView(RES_DICT.SHOP_ICO_TIME, 32, 18,
                                      { ap = display.CENTER, tag = 80, enable = false })
    countDownLayout:addChild(icoTimeImage)

    local countDownLabel = newLabel(60, 18,
                                    { ap = display.LEFT_CENTER, color = '#ffb143', text = "", fontSize = 20, tag = 81 })
    countDownLayout:addChild(countDownLabel)
    local topListSize = cc.size(670,128)
    local activityList = CListView:create(topListSize)
    activityList:setDirection(eScrollViewDirectionHorizontal)
    activityList:setAnchorPoint(display.RIGHT_CENTER)
    activityList:setPosition(topSize.width-20 , topSize.height/2)
    topLayout:addChild(activityList, 11)
    table.merge(self.viewData_ ,{
        topLayout               = topLayout,
        bgTopImage              = bgTopImage,
        activityImage           = activityImage,
        countDownLayout         = countDownLayout,
        timeLeftImage           = timeLeftImage,
        icoTimeImage            = icoTimeImage,
        countDownLabel          = countDownLabel,
        activityList            = activityList,
    } )
end
--==============================--
---@Description: TODO
---@param isActivity boolean @是否存在活动的档位
---@author : xingweihao
---@date : 2019/1/16 10:20 AM
--==============================--
function DiamondStoreView:CreateGridView(isActivity)
    local grideSize = nil
    if isActivity then
        grideSize = cc.size(1080, 496)
    else
        grideSize = cc.size(1080, 640)
    end
    local gridViewCellSize =  cc.size(538,193)
    local gridView = CGridView:create(grideSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(display.CENTER_BOTTOM)
    gridView:setColumns(2)
    gridView:setAutoRelocate(true)
    self.viewData_.view:addChild(gridView)
    gridView:setPosition(548, 0)
    table.merge(self.viewData_ , {
        gridView = gridView
    } )
end
--==============================--
---@Description: 剩余结束的时间
---@author : xingweihao
---@date : 2019/1/21 4:57 PM
--==============================--

function DiamondStoreView:UpdateTopView(endTime)
    local activity = app.activityMgr:GetActivityDataByType(ACTIVITY_TYPE.STORE_DIAMOND_LIMIT)
    if activity and activity[1] and activity[1].image[i18n.getLang()]  then
        self.viewData_.activityImage:setWebURL(activity[1].image[i18n.getLang()])
    end
    self.viewData_.countDownLayout:stopAllActions()
    local  leftTimes = endTime - os.time()
    if leftTimes <=  0    then
        display.commonLabelParams(self.viewData_.countDownLabel , {text = __('当前活动已结束')})
        return
    end
    local dateStr = CommonUtils.getTimeFormatByType(leftTimes)
    display.commonLabelParams(self.viewData_.countDownLabel , {text = dateStr})
    self.viewData_.countDownLayout:runAction(cc.RepeatForever:create(
        cc.Sequence:create(
            cc.DelayTime:create(1) ,
            cc.CallFunc:create(function()
                local  leftTimes = endTime - os.time()
                if leftTimes<= 0  then
                    display.commonLabelParams(self.viewData_.countDownLabel , {text = __('当前活动已结束')})
                    self.viewData_.countDownLayout:stopAllActions()
                else
                    local dateStr = CommonUtils.getTimeFormatByType(leftTimes)
                    display.commonLabelParams(self.viewData_.countDownLabel , {text = dateStr})
                end
            end)
        )
    ) )
end
function DiamondStoreView:getViewData()
    return self.viewData_
end


return DiamondStoreView
