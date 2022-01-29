---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/9/18 11:56 AM
---
local newImageView = display.newImageView
local newLayer = display.newLayer
local RES_DICT = {
    CG_PUZZLE_FRAME               = _res('ui/home/cg/CG_puzzle_frame.png'),
    CG_MAIN_BG_CARD               = _res('ui/home/cg/CG_main_bg_card.png'),
    CG_PUZZLE_FRAME_GAP           = _res('ui/home/cg/CG_puzzle_frame_gap.png'),
    LOADING_VIEW                  = _res('arts/common/loading_view_0.jpg'),
}

---@class CGRewardsLayer
local CGRewardsLayer = class('home.CGRewardsLayer', function()
    local node = CLayout:create(display.size)
    node.name  = 'Game.views.CGRewardsLayer'
    node:enableNodeEvents()
    return node
end)
local CGFragmentConfig = CommonUtils.GetConfigAllMess('cgFragment' ,'goods')
local CGCOnfig = CommonUtils.GetConfigAllMess('cg' ,'collection')
function CGRewardsLayer:ctor(param)
    param     = param or {}
    self.data = param.data or {}
    self.backPackMap = app.gameMgr:GetBackPackArrayToMap()
    self.rewardsData = self:GetRewardsDataCGKey()
    self.ownersData = self:GetOwnerData()
    self.isAction =  true
    self:InitUI()
    self:RunActionRewards()
end
--[[
　　---@Description: 给获取的奖励分类
　　---@param :
　  ---@return :{cgId ：{ cgFragmentId : true  } }
　　---@author : xingweihao
　　---@date : 2018/9/27 10:56 AM
--]]
function CGRewardsLayer:GetRewardsDataCGKey()
    local rewardsData = {}
    local goodsId = nil
    for index , cgFragmentData in pairs(self.data) do
        goodsId = tostring(cgFragmentData.goodsId)
        local cgOneFragmentConfData = CGFragmentConfig[tostring(goodsId)]
        local cgId = cgOneFragmentConfData.cgId
        if not  rewardsData[tostring(cgId)] then
            rewardsData[tostring(cgId)] = {}
        end
        rewardsData[tostring(cgId)][goodsId] = true
    end
    return rewardsData
end
--[[
　　---@Description: 获取已拥有的cg 碎片 刚获取的除外
　　---@param :
　  ---@return :{cgId ：{ cgFragmentId : true  } }
　　---@author : xingweihao
　　---@date : 2018/9/27 10:52 AM
--]]
function CGRewardsLayer:GetOwnerData()
    local ownersData = {}
    for cgId , cgFragmentDatas  in pairs(self.rewardsData) do
        local cgId = tostring(cgId)
        local cgfragments = CGCOnfig[cgId].fragments or {}
        for index , cgFragmentId in pairs(cgfragments) do
            cgFragmentId = tostring(cgFragmentId)
            if  not  self.rewardsData[cgId][cgFragmentId]  and self.backPackMap[tostring(cgFragmentId)] and self.backPackMap[tostring(cgFragmentId)].amount > 0  then
                if (not  ownersData[cgId]  )  then
                    ownersData[cgId] = {}
                end
                ownersData[cgId][cgFragmentId] = true
            end
        end
    end
    return ownersData
end
function CGRewardsLayer:InitUI()
    local closeLayer = display.newLayer(display.cx , display.cy ,
    {ap = display.CENTER , color = cc.c4b(0,0,0,175) , enable = true , cb = function()
        if self.isAction then
            return
        end
        self:stopAllActions()
        self:removeFromParent()
    end })
    self:addChild(closeLayer)
end
function CGRewardsLayer:RunActionRewards()
    local viewsTable = {}
    local collectKey = {}
    for i, v in pairs(self.rewardsData) do
        collectKey[#collectKey+1] = i
    end
    local   count = 0
    local function delayTimeLoad()
        count = count +1
        local index = count
        viewsTable[#viewsTable+1] =  self:CreateCGView()
        local  viewData =  viewsTable[#viewsTable].viewData
        self:addChild(viewData.view)
        self:UpdateCreateCGUI(self.ownersData[tostring(collectKey[index]) ] , viewsTable[#viewsTable] , collectKey[index] )
        local data = self.rewardsData[tostring(collectKey[index]) ]
        local spineTable = {}
        local pluzzImageMarkTable = {}
        local pluzzImageTable = {}
        for cgFragmentId, v in pairs(data) do
            local CGFragmentOneConfig = CGFragmentConfig[tostring(cgFragmentId)]
            local index = checkint(CGFragmentOneConfig.cgPosition)
            local spineAnimation = sp.SkeletonAnimation:create(
                    'effects/cgCollect/CG_get_puzzle.json',
                    'effects/cgCollect/CG_get_puzzle.atlas',
                    1
            )
            --spineAnimation:update(0)
            spineAnimation:setToSetupPose()
            spineAnimation:setVisible(false)
            --spineAnimation:setAnimation(0, 'play', false)
            viewData.cardFrameImage:addChild(spineAnimation,12)
            spineTable[#spineTable+1] = spineAnimation
            local pos = cc.p(viewData.pluzzTableImage[index]:getPosition())
            spineAnimation:setPosition(pos)
            local pluzzImage = display.newImageView(_res(string.format('ui/home/cg/pluzz/CG_ico_puzzle_static_%d.png' , index ) ) , pos.x , pos.y )
            pluzzImage:setLocalZOrder(11)
            pluzzImage:setOpacity(0)
            viewData.cardFrameImage:addChild(pluzzImage)
            -- 记录图片动画遮罩
            pluzzImageMarkTable[#pluzzImageMarkTable+1] = pluzzImage
            -- 记录碎片的table
            pluzzImageTable[#pluzzImageTable+1] = { index = index , image = viewData.pluzzTableImage[index] }
        end
        local spawnTable  =  {}
        local  distanceTime = 0.8
        local countTime =  2+ 0.25 + 0.25 + 0.5 + 0.5+ 0.2 * (#pluzzImageMarkTable - 1) * distanceTime
        for i = 1 ,#pluzzImageMarkTable do
            spawnTable[#spawnTable+1] = cc.TargetedAction:create(
                pluzzImageMarkTable[i] ,
                cc.Sequence:create(
                   cc.DelayTime:create((i -1)  * distanceTime),
                   cc.CallFunc:create(
                   function()
                       spineTable[i]:setVisible(true)
                       spineTable[i]:setAnimation(0, 'play', false)
                    end
                   ),
                  cc.DelayTime:create(2),
                   cc.CallFunc:create(function()
                       pluzzImageTable[i].image:setTexture(_res(string.format('ui/home/cg/pluzz/CG_ico_puzzle_move_%d.png' , pluzzImageTable[i].index ) ))
                       pluzzImageTable[i].image:setLocalZOrder(10)
                   end),
                   cc.TargetedAction:create( pluzzImageTable[i].image , cc.Sequence:create(
                           cc.ScaleTo:create(0.25 , 1.3) ,
                           cc.ScaleTo:create(0.25 , 1)
                   ) )  ,
                   cc.CallFunc:create(
                           function()
                               pluzzImageMarkTable[i]:setOpacity(125)
                           end
                   ),
                    cc.Spawn:create(
                            cc.FadeOut:create(0.5 ) ,
                            cc.ScaleTo:create(0.5,1.3)
                    ),
                   cc.TargetedAction:create(
                           pluzzImageTable[i].image , cc.FadeOut:create(0.2)
                   )  ,
                   cc.DelayTime:create( countTime -  (2+ 0.25 + 0.25 + 0.5 + 0.5 + 0.2 * (i - 1) * distanceTime)  )
                )
            )
        end
        local viewSeq = {}
        viewSeq[#viewSeq+1] =    cc.MoveTo:create(0.5 , cc.p(display.cx , display.cy)  )
        viewSeq[#viewSeq+1] = cc.Spawn:create(spawnTable)
        viewSeq[#viewSeq+1] =  cc.CallFunc:create(
                function()
                    if  count ~= #collectKey then
                        delayTimeLoad()
                    else
                        self.isAction = false
                    end
                end
        )
        if count ~=  #collectKey then
            viewSeq[#viewSeq+1]   = cc.MoveTo:create(0.5 , cc.p(-display.cx , display.cy)  )
        end
        viewData.view:runAction(
            cc.Sequence:create(
                    viewSeq
            )
        )
     end
    delayTimeLoad()
end
--[[
　　---@Description: 创建cg 的view
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/27 10:37 AM
--]]
function CGRewardsLayer:CreateCGView()
    local view = newLayer(display.cx + display.width , display.cy,{ap = display.CENTER, size = display.size})
    local cardFrameImage = newLayer(display.cx , display.cy ,
                                    { ap = display.CENTER, color = cc.r4b(0), size = cc.size(1036, 631), enable = true })
    view:addChild(cardFrameImage)

    local cardBottom = newImageView(RES_DICT.CG_MAIN_BG_CARD, -16, -15,
                                    { ap = display.LEFT_BOTTOM, tag = 96, enable = false, scale9 = true, size = cc.size(1061, 655) })
    cardFrameImage:addChild(cardBottom)
    local cardFrameImageSize = cardFrameImage:getContentSize()
    local pluzzImage = display.newImageView(RES_DICT.LOADING_VIEW ,cardFrameImageSize.width/2 , cardFrameImageSize.height/2 ,{scale  =  0.65 } )
    cardFrameImage:addChild(pluzzImage)
    local imageFrame = newImageView(RES_DICT.CG_PUZZLE_FRAME, -22, -35,
                                    { ap = display.LEFT_BOTTOM, tag = 30, enable = false })
    cardFrameImage:addChild(imageFrame)
    local pluzzTableImage = {}
    local image = nil
    local height =  156
    local width = 172
    local gridImage = display.newImageView(RES_DICT.CG_PUZZLE_FRAME_GAP , cardFrameImageSize.width /2 , cardFrameImageSize.height/2 - 15)
    cardFrameImage:addChild(gridImage)
    for i = 1 , 24  do
        local divisor =  math.floor((i-1) / 4)
        local mod  = (i-1)  % 4
        image = display.newImageView( _res( string.format('ui/home/cg/pluzz/CG_ico_puzzle_static_%s.png' , i ) ) ,divisor  *width + 95  , height * mod +78, {ap = display.CENTER}  )
        cardFrameImage:addChild(image )
        pluzzTableImage[i] = image
    end
    view.viewData =  {
        cardFrameImage          = cardFrameImage,
        cardBottom              = cardBottom,
        imageFrame              = imageFrame,
        gridImage               = gridImage,
        pluzzTableImage         = pluzzTableImage ,
        pluzzImage              = pluzzImage ,
        view                    = view
    }
    return view 
end
--[[
　　---@Description: 更新显示cg 的ui
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/27 10:41 AM
--]]
function CGRewardsLayer:UpdateCreateCGUI(ownersData  , view , cgId )
    local cgId = cgId
    local viewData = view.viewData
    for cgFragmentId, v in pairs(ownersData or {}) do
        local CGFragmentOneConfig = CGFragmentConfig[tostring(cgFragmentId)]
        local index = checkint(CGFragmentOneConfig.cgPosition)
        viewData.pluzzTableImage[index]:setVisible(false)
    end
    local cgOneConfig = CGCOnfig[tostring(cgId)]
    local  path  = _res(string.format("arts/common/%s",cgOneConfig.path)   )
    local isExists =  utils.isExistent(path)
    if  not  isExists then
        path = _res('arts/common/loading_view_0.jpg')
    end
    if viewData and viewData.pluzzImage then
        viewData.pluzzImage:setTexture(path)
    end
end

return CGRewardsLayer