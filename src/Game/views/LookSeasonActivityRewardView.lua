local GameScene                    = require( 'Frame.GameScene' )
---@class LookSeasonActivityRewardView :GameScene
local LookSeasonActivityRewardView = class('LookSeasonActivityRewardView', GameScene)
local RES_DICT                     = {
    CELL_BG_IMAGE       = _res('ui/home/activity/seasonlive/season_loots_label_goods'),
    CELL_BG_BLOCK_IMAGE = _res('ui/home/activity/seasonlive/season_loots_label_goods_bk'),
    COMMON_BG           = _res('ui/common/common_bg_goods'),
    COMMON_BG_IMAGE     = _res('ui/common/common_bg_4'),
    COMMON_TITLE        = _res('ui/common/common_title_5'),
    LINE_IMAGE          = _res('ui/common/season_loots_line_1'),
    POOL_TWO_IMAGE      = _res('ui/home/activity/seasonlive/season_loots_bg_egg_2'),
    POOL_ONE_IMAGE      = _res('ui/home/activity/seasonlive/season_loots_bg_egg_1'),
    REWARD_BTN_ONE      = _res('ui/home/activity/seasonlive/season_loots_btn_rewards_1'),
    REWARD_BTN_TWO      = _res('ui/home/activity/seasonlive/season_loots_btn_rewards_2'),

}
local DRAW_POOL_WAY           = {-- 抽奖池的方式
    ONE = 1, -- 第一种抽奖池
    TWO = 2 -- 第二种抽奖池
}
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
local rewardPoolConfig        = CommonUtils.GetConfigAllMess('rewardPool', 'seasonActivity')
local rewardPoolConsumeConfig = CommonUtils.GetConfigAllMess('rewardPoolConsume','seasonActivity')
function LookSeasonActivityRewardView:ctor(param)
    param = param or {}
    self.super.ctor(self, 'home.LookSeasonActivityRewardView')
    self.type = param.type
    self.receivedRewards = param.receivedRewards
    self:InitUI()
    self.receivedData = self:GetRewardPoolGoodsByPoolId(self.type)
    self.allCount , self.alreadyCount = self:GetAllRewardAndAlreadyCountNumByPooId(self.type)
    self:UpdateView()
end
--==============================--
--desc:初始化界面
--time:2017-08-01 03:13:56
--@return
--==============================--
function LookSeasonActivityRewardView:InitUI()
    local closeLayer = display.newLayer(0, 0, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true ,cb = function()
        self:removeFromParent()
    end })
    closeLayer:setPosition(display.center)
    self:addChild(closeLayer)
    -- 背景图片
    local bgSize   = cc.size(982, 652)
    local bgImage  = display.newImageView(RES_DICT.COMMON_BG_IMAGE, bgSize.width / 2, bgSize.height / 2, { scale9 = true, size = bgSize } )
    local bgLayout = display.newLayer(display.width / 2, display.height / 2, { ap = display.CENTER, color1 = cc.r4b(), size = bgSize })
    bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
    bgLayout:addChild(bgImage)
    local swallowLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true } )
    bgLayout:addChild(swallowLayer)
    local leftSize = cc.size(680, bgSize.height)
    -- 左侧的layout
    local leftLayout = display.newLayer(0, bgSize.height, { ap = display.LEFT_TOP, color1 = cc.r4b(), size = leftSize })
    bgLayout:addChild(leftLayout)
    self:addChild(bgLayout)

    local verticalLine = display.newImageView(RES_DICT.LINE_IMAGE)
    verticalLine:setPosition(cc.p(leftSize.width, leftSize.height/2))
    verticalLine:setRotation(90)
    leftLayout:addChild(verticalLine)

    -- 标签
    local titleBtn     = display.newButton(leftSize.width / 2, leftSize.height - 35, { n = RES_DICT.COMMON_TITLE, scale9 = true } )
    display.commonLabelParams(titleBtn, fontWithColor('6', { paddingW = 30, text = '' }))
    leftLayout:addChild(titleBtn)
    -- 获取显示
    local obatinLabel = display.newLabel(leftSize.width - 20, leftSize.height - 50,
                                         fontWithColor('8', { ap = display.RIGHT_CENTER, text = string.format(__('已获取: %s/%s' ), 30, 100) }) )
    leftLayout:addChild(obatinLabel)



    -- 左侧中部的内容
    local centerSize  = cc.size(645, 540)
    local centerLayer = display.newLayer(leftSize.width / 2, leftSize.height - 70,
                                         { ap = display.CENTER_TOP, color1 = cc.r4b(), size = centerSize })
    leftLayout:addChild(centerLayer)
    -- 右侧的Layout
    local rightSize   = cc.size(300, bgSize.height)
    local rightLayout = display.newLayer(bgSize.width, rightSize.height / 2, { ap = display.RIGHT_CENTER, size = rightSize })
    bgLayout:addChild(rightLayout)
    -- 奖池的图片
    local poolImage  = display.newImageView(RES_DICT.POOL_ONE_IMAGE, rightSize.width/2 , -20 , { ap = display.CENTER_BOTTOM})
    rightLayout:addChild(poolImage)

    -- 奖励图片
    local rewardBtn = display.newImageView(RES_DICT.REWARD_BTN_ONE, rightSize.width -50, rightSize.height -40)
    rightLayout:addChild(rewardBtn)




    local centerBg = display.newImageView(RES_DICT.COMMON_BG, centerSize.width / 2, centerSize.height / 2
    , { size = centerSize, scale9 = true } )
    centerLayer:addChild(centerBg)

    local listSize   = centerSize
    local rewardList = CListView:create(listSize)
    rewardList:setDirection(eScrollViewDirectionVertical)
    rewardList:setAnchorPoint(display.CENTER)
    rewardList:setPosition(cc.p(centerSize.width / 2, centerSize.height / 2))
    centerLayer:addChild(rewardList)
    self.viewData = {
        poolImage   = poolImage,
        rightSize   = rightSize,
        rewardBtn   = rewardBtn,
        listSize    = listSize,
        titleBtn    = titleBtn,
        obatinLabel = obatinLabel,
        rewardList  = rewardList,
    }

end
--[[
    返回总数量和已经获取的数量
--]]
function LookSeasonActivityRewardView:GetAllRewardAndAlreadyCountNumByPooId(poolId)
    local rewardOnePoint = rewardPoolConfig[tostring(poolId)]
    local count          = 0
    local alreadyCount = 0
    for i, v in pairs(rewardOnePoint) do
        for kk ,vv in pairs(v.reward) do
            count = count + checkint(v.getNum)
            alreadyCount =checkint( self.receivedRewards[i]) +  alreadyCount
        end
    end
    return count ,alreadyCount
end

--[[
    根据奖池获取该奖池的ID该奖池所有的的道具
    道具分为稀有和非稀有
--]]
function LookSeasonActivityRewardView:GetRewardPoolGoodsByPoolId(poolId)
    local data                = self.receivedRewards
    -- 获取奖池的配置
    local rewardPoolConfig    = CommonUtils.GetConfigAllMess('rewardPool', 'seasonActivity')
    local rewardOnePoolConfig = rewardPoolConfig[tostring(poolId)]
    -- rewardPoolData 主要用于存放稀有和不稀有的道具
    local unCommon            = {}
    local common              = {}
    local rewardPoolData      = { unCommon = unCommon, common = common }
    local onwerTimes          = 0 -- 已经拥有的数量
    local rewardData          = nil
    for i, v in pairs(rewardOnePoolConfig) do
        -- 获取已经抽到该卡池的次数
        onwerTimes = checkint(data[tostring(i)])
        rewardData = clone(v.reward)
        for kk, vv in pairs(rewardData) do
            vv.onwerTimes = onwerTimes
            vv.getNum = v.getNum
            vv.goodsSort = v.goodsSort
            if checkint(v.rareGoods) > 0 then
                -- 稀有道具
                unCommon[#unCommon + 1] = vv
            else
                --非稀有道具
                common[#common + 1] = vv
            end
        end
    end
    table.sort(rewardPoolData.unCommon ,
   function (a , b )
       if checkint(a.goodsSort) >=  checkint(b.goodsSort) then
           return false
       end
       return true
   end)
    table.sort(rewardPoolData.common ,
   function (a , b )
       if checkint(a.goodsSort) >=  checkint(b.goodsSort) then
           return false
       end
       return true
   end)
    dump(rewardPoolData.common)
    return rewardPoolData
end
--[[

--]]
function LookSeasonActivityRewardView:CreateLayoutByUnCommon(isTrue)
    local viewData = self.viewData
    local cellSize = cc.size(120, 151)
    local width    = viewData.listSize.width
    local distance = ( viewData.listSize.width - cellSize.width * 5) / 2
    local layout = nil
    local data = self.receivedData.common or {}
    local str = __('其他')
    if isTrue then
        str  = __('稀有')
        data = self.receivedData.unCommon or {}
    end
    local count     = #data
    if count > 0 then
        local fiveCount = math.ceil(count /5)  * 5
        local height =  math.ceil(count /5)* cellSize.height + 35
        local layoutSize = cc.size(width,height)
        layout = display.newLayer(width/2 , height, {color1 = cc.r4b() , size =layoutSize })
        local label = display.newLabel(distance -5 , height -20 , fontWithColor('8' ,{ap = display.LEFT_CENTER ,  text = str}) )
        layout:addChild(label)
        local line = display.newImageView(RES_DICT.LINE_IMAGE,width/2 , height -35  )
        layout:addChild(line)
        for i, v in pairs(data) do
            local gridCellLayout = self:CreateGridCell(v)
            local heightline  = math.floor(((fiveCount -  i-0.5 + 1)/5))+0.5
            local widthline = (i-0.5 )%5
            gridCellLayout:setPosition(cc.p( cellSize.width*widthline  +distance , heightline *cellSize.height ))
            layout:addChild(gridCellLayout)
        end
    end
    return layout or CLayout:create(cc.size(0,0))
end


function LookSeasonActivityRewardView:UpdateView()
    local viewData = self.viewData
    if self.type == DRAW_POOL_WAY.ONE then
        viewData.poolImage:setTexture(RES_DICT.POOL_ONE_IMAGE)
        viewData.poolImage:setPosition(cc.p(viewData.rightSize.width/2 ,0 ))
        viewData.rewardBtn:setTexture(RES_DICT.REWARD_BTN_ONE)
    elseif self.type == DRAW_POOL_WAY.TWO then
        viewData.poolImage:setTexture(RES_DICT.POOL_TWO_IMAGE)
        viewData.poolImage:setPosition(cc.p(viewData.rightSize.width/2 ,-20 ))
        viewData.rewardBtn:setTexture(RES_DICT.REWARD_BTN_TWO)
        viewData.rewardBtn:setPosition(cc.p(viewData.rightSize.width -50 ,viewData.rightSize.height-30 ))
    end
    local data = rewardPoolConsumeConfig[tostring(self.type) ]
    if data then
        local name  = data.name2
        display.commonLabelParams( viewData.titleBtn, { paddingW = 40 , text = name  })
        display.commonLabelParams(viewData.obatinLabel, {text = string.format(__('剩余: %s/%s') ,self.allCount -  self.alreadyCount , self.allCount)})
    end
    local unCommonLayout =self:CreateLayoutByUnCommon(true)
    local commonLayout =self:CreateLayoutByUnCommon(false )
    viewData.rewardList:insertNodeAtLast(unCommonLayout)
    viewData.rewardList:insertNodeAtLast(commonLayout)
    viewData.rewardList:reloadData()
end
function LookSeasonActivityRewardView:CreateGridCell(data)
    data  = data or {}

    local bgImage = display.newImageView(RES_DICT.CELL_BG_IMAGE)
    local bgSize = bgImage:getContentSize()
    local bgLayout = display.newLayer(bgSize.width/2 ,bgSize.height/2 ,{ap = display.CENTER , size = bgSize , color1 = cc.r4b()} )
    bgLayout:addChild(bgImage)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local goodNode = require("common.GoodNode").new({id = data.goodsId ,showAmount = true , num = checkint(data.num) })
    bgLayout:addChild(goodNode)
    goodNode:setScale(0.8)
    goodNode:setPosition(cc.p(bgSize.width/2 , bgSize.height -60))
    local numLabel = display.newLabel(bgSize.width/2 , 25 ,fontWithColor('6',
                             { text = string.format("%d/%d" , checkint(data.getNum) - checkint(data.onwerTimes) , checkint(data.getNum))}))
    bgLayout:addChild(numLabel)
    display.commonUIParams(goodNode, {animate = false, cb = function (sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
    end})
    if checkint(data.getNum) - checkint(data.onwerTimes) ==0 then
        local blackImage = display.newImageView(RES_DICT.CELL_BG_BLOCK_IMAGE , bgSize.width/2 ,bgSize.height/2)
        bgLayout:addChild(blackImage)
    end
    return bgLayout
end
return LookSeasonActivityRewardView
