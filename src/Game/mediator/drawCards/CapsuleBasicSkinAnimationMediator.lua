--[[
 * author : liuzhipeng
 * descpt : 抽卡 常驻皮肤卡池动画Mediator   
--]]
local Mediator = mvc.Mediator
local CapsuleBasicSkinAnimationMediator = class("CapsuleBasicSkinAnimationMediator", Mediator)
local NAME = "CapsuleBasicSkinAnimationMediator"
function CapsuleBasicSkinAnimationMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rewardData = checktable(params.rewards)
    self.cb = params.cb
    self.animationData = {}

end

function CapsuleBasicSkinAnimationMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function CapsuleBasicSkinAnimationMediator:ProcessSignal( signal )
	local name = signal:GetName()
    print(name)
end

function CapsuleBasicSkinAnimationMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleBasicSkinAnimationView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    self:InitAnimationData()
    self:StartAnimation()
end
---------------------------------------------
------------------ init ---------------------
--[[
初始化动画数据
--]]
function CapsuleBasicSkinAnimationMediator:InitAnimationData()
    local animationData = {}
    local rewardData = self.rewardData
    local capsuleType = nil
    if #rewardData == 1 then
        if tostring(rewardData[1].type) == GoodsType.TYPE_CARD_SKIN then
            capsuleType = CAPSULE_SKIN_TYPE.ONE_CARD_SKIN
        else
            capsuleType = CAPSULE_SKIN_TYPE.ONE_GOODS
        end
    elseif #rewardData == 10 then
        capsuleType = CAPSULE_SKIN_TYPE.TEN
    end
    animationData.capsuleType = capsuleType
    animationData.rewardData = self:ConvertRewardData(rewardData)
    self:SetAnimationData(animationData)
end
------------------ init ---------------------
---------------------------------------------

---------------------------------------------
----------------- method --------------------
--[[
开始动画
--]]
function CapsuleBasicSkinAnimationMediator:StartAnimation()
    local animationData = self:GetAnimationData()
    local cb = self.cb
    self:GetViewComponent():StartAnimation(animationData, cb)
end
--[[
转换抽奖格式
--]]
function CapsuleBasicSkinAnimationMediator:ConvertRewardData( rewardData )
    local newRewardData = clone(rewardData)
    local skinNum = 0
    local goodsNum = 0
    for i, v in ipairs(rewardData) do
        if tostring(v.type) == GoodsType.TYPE_CARD_SKIN then
            skinNum = skinNum + 1
        else
            goodsNum = goodsNum + 1
        end
    end
    local skinDotIndexList = self:GetDotIndexList(skinNum)
    local goodsDotIndexList = self:GetDotIndexList(goodsNum)
    local skinIndex = 1
    local goodsIndex = 1
    for i, v in ipairs(newRewardData) do
        if tostring(v.type) == GoodsType.TYPE_CARD_SKIN then
            v.dotIndex = skinDotIndexList[skinIndex]
            skinIndex = skinIndex + 1
        else
            v.dotIndex = goodsDotIndexList[goodsIndex]
            goodsIndex = goodsIndex + 1
        end
    end
    return newRewardData
end
----------------- method --------------------
---------------------------------------------

---------------------------------------------
-------------- spine事件绑定 -----------------

-------------- spine事件绑定 -----------------
---------------------------------------------

---------------------------------------------
---------------- get / set ------------------
--[[
获取奖励
--]]
function CapsuleBasicSkinAnimationMediator:GetRewardData()
    return self.rewardData
end
--[[
获取动画数据
--]]
function CapsuleBasicSkinAnimationMediator:GetAnimationData()
    return self.animationData
end
--[[
设置动画数据
--]]
function CapsuleBasicSkinAnimationMediator:SetAnimationData( animationData )
    self.animationData = checktable(animationData)
end
--[[
获取dot位置
--]]
function CapsuleBasicSkinAnimationMediator:GetDotIndexList( num )
    local posList = {}
    local ramdomList = {}
    for i = 1, 10 do
        table.insert(posList, i)
    end
    for i = 1, num do
        local randomNum = math.random(i, #posList)
        local targetNum = posList[randomNum]
        table.insert(ramdomList, targetNum)
        posList[randomNum] = posList[i]
        posList[i] = targetNum
    end
    return ramdomList
end
---------------- get / set ------------------
---------------------------------------------
function CapsuleBasicSkinAnimationMediator:OnRegist(  )
end

function CapsuleBasicSkinAnimationMediator:OnUnRegist(  )
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleBasicSkinAnimationMediator