--[[
卡牌皮肤 live2d
@params table {
    skinId         int 皮肤id
    coordinateType int 坐标类型
    notRefresh     bool 是否需要创建时立刻刷新
    clickCB        function(cardId, skinId) 点击回调
@see CardSkinL2dNode.RefreshAvatar
@see COORDINATE_TYPE_xxxx
}
--]]
local CardL2dNode     = require('Frame.gui.CardL2dNode')
local CardSkinL2dNode = class('CardSkinL2dNode', function ()
	local node = CLayout:create()
	node.name = 'common.CardSkinL2dNode'
	node:enableNodeEvents()
	return node
end)


---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
consturctor
--]]
function CardSkinL2dNode:ctor( ... )
    app:RegistObserver(CARD_LIVE2D_NODE_INIT_ENV, mvc.Observer.new(self.onLive2dNodeInitEnvHandler_, self))
    app:RegistObserver(CARD_LIVE2D_NODE_CLEAN_ENV, mvc.Observer.new(self.onLive2dNodeCleanEnvHandler_, self))
    
    -- init node
	local args = unpack({...}) or {}
    self.coordinateType = args.coordinateType or COORDINATE_TYPE_LIVE2D_CAPSULE

	self:InitL2dNode()
    self:setClickCallback(args.clickCB or handler(self, self.onClickCallback))
    
    -- clean l2d env
    app.cardL2dNode.CleanEnv()
    
    -- init l2d env
    app.cardL2dNode.InitEnv(self.lvContainer)

    -- append globalLvContainer
    app.cardL2dNode.AppendGlobalLvContainerList(self.lvContainer)

	if not args.notRefresh then
		self:refreshL2dNode(args)
	end
end
--[[
初始化l2d
--]]
function CardSkinL2dNode:InitL2dNode()
	local bgSize = display.size
	self:setContentSize(bgSize)
    self:setAnchorPoint(cc.p(0, 0))

    self.lvContainer = display.newLayer()
    self:addChild(self.lvContainer)

    self.lvContainer.refreshFunc = function()
        if self.lvContainer and not tolua.isnull(self.lvContainer) then
            self:refreshL2dNode({
                skinId = self:getL2dSkinId(),
                bgMode = self:isOpenBgMode(),
                motion = self:getL2dMotionName(),
            })
            -- self:adjustL2dNodePoint()
        end
    end
    
    local winSize = display.size
    self.lvSize   = cc.size(display.width, display.cy - 30)
    if (winSize.width / winSize.height) <= (1024 / 768) then
        -- ipad尺寸 会将立绘额外
        self.lvSize.height = self.lvSize.height - 10
    end
    
	-- 初始化触摸监听层
	local touchSize  = cc.size(600, bgSize.height)
	self.touchLayout = display.newLayer(0, bgSize.height/2, {color = cc.r4b(0), size = touchSize, ap = display.LEFT_CENTER})
    self:addChild(self.touchLayout, 10)
    
    -- debug use
    do
        -- self:addChild(display.newLayer(0, 0, {color = cc.r4b(200), size = cc.size(100,100), ap = display.RIGHT_TOP}), 9999)
        -- self:addChild(display.newLayer(0, 0, {color = cc.r4b(200), size = cc.size(100,100), ap = display.LEFT_BOTTOM}), 9999)
        -- self:addChild(display.newLayer(display.cx, display.cy, {color = cc.r4b(200), size = cc.size(100,100), ap = display.RIGHT_TOP}), 9999)
        -- self:addChild(display.newLayer(display.cx, display.cy, {color = cc.r4b(200), size = cc.size(100,100), ap = display.LEFT_BOTTOM}), 9999)
    end

	self.touchLayout:setOnClickScriptHandler(function(sender)
		if self.clickCB then
			self.clickCB(self:getL2dCardId(), self:getL2dSkinId())
		end
	end)
end


function CardSkinL2dNode:setClickCallback(clickCB)
	self.clickCB = clickCB
	self.touchLayout:setTouchEnabled(self.clickCB ~= nil)
end
---------------------------------------------------
-- init end --
---------------------------------------------------


---------------------------------------------------
-- avatar control begin --
---------------------------------------------------
--[[
刷新live2d节点
@params skinId   int  皮肤id
@params cardId   int  卡牌id（遍历卡牌数据，找到匹配的cardId）
@params confId   int  配表id（直接卡牌牌表，找到匹配的confId）
@params cardUuid int  uuid（遍历卡牌数据，找到匹配的uuid）
@params motion   str  初始动作（默认 Idle）
@params bgMode   bool 是否使用背景（如果有的话，默认 false）
--]]
function CardSkinL2dNode:refreshL2dNode(params)
    local oldDrawName = self.drawName
    self.bgMode_ = params.bgMode
	
	-- 节点路径
	if params.confId then
		self.cardId   = checkint(params.confId)
		self.skinId   = CardUtils.GetCardSkinId(params.confId)
		self.drawName = CardUtils.GetCardDrawNameBySkinId(self.skinId)

	elseif params.skinId then
        local skinConf = CardUtils.GetCardSkinConfig(params.skinId) or {}
		self.cardId    = checkint(skinConf.cardId)
		self.skinId    = params.skinId
        self.drawName  = CardUtils.GetCardDrawNameBySkinId(self.skinId)
        
    elseif params.cardUuid then
        local cardData = app.gameMgr:GetCardDataById(params.cardUuid) or {}
        self.cardId    = checkint(cardData.cardId)
		self.skinId    = CardUtils.GetCardSkinId(self.cardId)
        self.drawName  = CardUtils.GetCardDrawNameBySkinId(self.skinId)

	else
		self.cardId   = checkint(params.cardId)
		self.skinId   = app.cardMgr.GetCardSkinIdByCardId(params.cardId)
		self.drawName = CardUtils.GetCardDrawNameBySkinId(self.skinId)
	end

    -- 清空旧的 live2d
    if oldDrawName ~= self.drawName then
        self:cleanL2dNode()
    end

    -- 创建新的 live2d
    if self.l2dNode_ == nil and CardL2dNode.GetEnvView() and CardL2dNode.GetEnvView():getParent() == self.lvContainer then
        local isUseBg = self:isOpenBgMode() and CardUtils.IsExistentGetCardLive2dModel(self.drawName, true)
        self.l2dNode_ = CardL2dNode.new({roleId = self.skinId, bgMode = isUseBg})
        self:addChild(self.l2dNode_)

        -- reset to LEFT_BOTTOM point
        self.l2dNode_:setPositionX(-self.lvSize.width/2)
        self.l2dNode_:setPositionY(-self.lvSize.height/2)
    end

    -- 设置默认动作
    self:setL2dMotionName(params.motion)

    -- update draw location
    self:adjustL2dNodePoint()
end


function CardSkinL2dNode:adjustL2dNodePoint()
    local worldPoint = self:convertToWorldSpace(PointZero)
    -- self.lvContainer:setPositionX(-worldPoint.x)
    -- self.lvContainer:setPositionY(-worldPoint.y)

    local defaultLocation    = {x = 0, y = 0, scale = 50, rotate = 0}
    local cardLocationConf   = CommonUtils.GetConfig('cards', 'coordinate', self.drawName) or {}
    local cardLocationDefine = cardLocationConf[self.coordinateType] or defaultLocation

    if self:getLive2dNode() then
        local windowSize  = display.size
        local designSize  = cc.size(1334, 750)
        local deltaHeight = (windowSize.height - designSize.height) / 2
        local l2dOffsetX  = self.lvSize.width  / display.width  * (worldPoint.x + checkint(cardLocationDefine.x))
        local l2dOffsetY  = self.lvSize.height / display.height * (worldPoint.y + checkint(cardLocationDefine.y) + deltaHeight)
        local scaleNum = cardLocationDefine.scale == '' and defaultLocation.scale or checkint(cardLocationDefine.scale)
        self.l2dNode_:setPositionX(-self.lvSize.width/2  -worldPoint.x + l2dOffsetX)
        self.l2dNode_:setPositionY(-self.lvSize.height/2 -worldPoint.y + l2dOffsetY)
        self.l2dNode_:setScale((designSize.height / windowSize.height) * scaleNum / 100)
    end
end


function CardSkinL2dNode:cleanL2dNode()
    if self.l2dNode_ and not tolua.isnull(self.l2dNode_) then
        self.l2dNode_:removeFromParent()
    end
    self.l2dNode_ = nil
end


function CardSkinL2dNode:getLive2dNode()
	return self.l2dNode_
end


function CardSkinL2dNode:isOpenBgMode()
	return self.bgMode_ == true
end


function CardSkinL2dNode:getL2dCardId()
	return self.cardId
end
function CardSkinL2dNode:getL2dSkinId()
	return self.skinId
end


function CardSkinL2dNode:getL2dMotionName()
	return self.motionName_
end
function CardSkinL2dNode:setL2dMotionName(motionName)
    self.motionName_ = 'Idle'
    if self:getLive2dNode() then
        local motionList = self:getLive2dNode():getMotionList()
        for _, motion in ipairs(motionList) do
            if motionName == motion then
                self.motionName_ = motionName
                break
            end
        end

        self:getLive2dNode():setMotion(self.motionName_)
    end
end
---------------------------------------------------
-- avatar control end --
---------------------------------------------------


function CardSkinL2dNode:onEnter()
    local worldPoint = self:convertToWorldSpace(PointZero)
    self.lvContainer:setPositionX(-worldPoint.x)
    self.lvContainer:setPositionY(-worldPoint.y)
    self:adjustL2dNodePoint()
end


function CardSkinL2dNode:onCleanup()
    app:UnRegistObserver(CARD_LIVE2D_NODE_INIT_ENV, self)
    app:UnRegistObserver(CARD_LIVE2D_NODE_CLEAN_ENV, self)

    -- 检测移除的是不是 正在显示live2d的容器
    local isNeedToNextLvContainer = false
    if CardL2dNode.GetEnvView() and CardL2dNode.GetEnvView():getParent() == self.lvContainer then
        isNeedToNextLvContainer = true
        -- clean l2d env
        app.cardL2dNode.CleanEnv()
    end
    
    -- popup globalLvContainer
    app.cardL2dNode.PopupGlobalLvContainerList(self.lvContainer, isNeedToNextLvContainer)
end


function CardSkinL2dNode:onClickCallback()
    if self:getLive2dNode() then
        local motionIndex = 0
        local motionList  = self:getLive2dNode():getMotionList()
        for index, motionName in ipairs(motionList) do
            if motionName == self:getL2dMotionName() then
                motionIndex = index
                break
            end
        end

        -- loop play motionList
        local motionName = motionList[(motionIndex >= #motionList) and 1 or (motionIndex + 1)]
        self:setL2dMotionName(motionName)
    end
end


function CardSkinL2dNode:onLive2dNodeInitEnvHandler_(signal)
    local dataBody      = signal:GetBody()
    local rootContainer = dataBody.rootContainer
end


function CardSkinL2dNode:onLive2dNodeCleanEnvHandler_(signal)
    local dataBody      = signal:GetBody()
    local rootContainer = dataBody.rootContainer

    if rootContainer == self.lvContainer then
        self:cleanL2dNode()
    end
end


return CardSkinL2dNode
