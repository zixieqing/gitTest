--[[
 * author : kaishiqi
 * descpt : 游戏道具 管理器
--]]
local BaseManager = require('Frame.Manager.ManagerBase')
---@class GoodsManager:BaseManager
local GoodsManager = class('GoodsManager', BaseManager)


-------------------------------------------------
-- manager method

GoodsManager.DEFAULT_NAME = 'GoodsManager'
GoodsManager.instances_   = {}


function GoodsManager.GetInstance(instancesKey)
    instancesKey = instancesKey or GoodsManager.DEFAULT_NAME

    if not GoodsManager.instances_[instancesKey] then
        GoodsManager.instances_[instancesKey] = GoodsManager.new(instancesKey)
    end
    return GoodsManager.instances_[instancesKey]
end


function GoodsManager.Destroy(instancesKey)
    instancesKey = instancesKey or GoodsManager.DEFAULT_NAME

    if GoodsManager.instances_[instancesKey] then
        GoodsManager.instances_[instancesKey]:release()
        GoodsManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function GoodsManager:ctor(instancesKey)
    self.super.ctor(self)

    if GoodsManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function GoodsManager:initial()
    -- 初始化逻辑
    self:InitLogicUnit()
end
function GoodsManager:InitLogicUnit()
    -- 领取奖励的逻辑
    self.drawRewardsLogic = require('Frame.Manager.GoodsManagerDrawRewards')
end


function GoodsManager:release()
    -- 释放逻辑
    self:ReleaseLogicUnit()
end
function GoodsManager:ReleaseLogicUnit()
    -- 领取奖励的逻辑
    self.drawRewardsLogic = nil
end


-------------------------------------------------------------------------------
-- 关于背包数据
-------------------------------------------------------------------------------

--[[
    获取全部背包数据
    @return backpack : list    道具信息集 （好想改造成map呀，对吧伟浩）
]]
function GoodsManager:GetBackpackList()
    if not app.gameMgr:GetUserInfo().backpack then
        app.gameMgr:GetUserInfo().backpack = {}
    end
    return app.gameMgr:GetUserInfo().backpack
end


--[[
    获取指定背包菊菊，根据道具id （先把获取方法封装起来，以后从list改map方便，对吧伟浩）
    @return goodsData ：table
    {
        goodsId : int    物品id
        amount  : int    物品数量
        IsNew   : int    是否新获得（0：否，1是）
    }
]]
function GoodsManager:GetBackpackDataByGoodsId(goodsId)
    local targetGoodsId = checkint(goodsId)
    for _, goodsData in ipairs(self:GetBackpackList()) do
        if targetGoodsId == checkint(goodsData.goodsId) then
            return goodsData
        end
    end
    return nil
end


--[[
    消除背包道具的新获得状态
]]
function GoodsManager:CleanBackpackNewStatuByGoodsId(goodsId)
    local goodsData = self:GetBackpackDataByGoodsId(goodsId)
    if goodsData then
        goodsData.IsNew = 0
    end
end


--[[
    设置背包的物品数量，根据物品id
    @params goodsId    : int     物品id
    @params amount     : int     物品数量（最终值）
    @params autoRemove : bool    物品数量 <= 0 时，是否自动清除数据。默认true
--]]
function GoodsManager:SetBackpackAmountByGoodsId(goodsId, amount, autoRemove)
    local isAutoRemove  = autoRemove == nil or autoRemove == true
    local targetAmount  = checkint(amount)
    local targetGoodsId = checkint(goodsId)
	local isAppendGoods = true
    
    for goodsIndex = #self:GetBackpackList(), 1, -1 do
        local goodsData = self:GetBackpackList()[goodsIndex]
		if checkint(goodsData.goodsId) == targetGoodsId then
			isAppendGoods = false
            
			if targetAmount <= 0 and isAutoRemove then
				table.remove(self:GetBackpackList(), goodsIndex)
			else
				goodsData.amount = targetAmount
			end
			break
		end
    end
    
	if  isAppendGoods then
		table.insert(self:GetBackpackList(), { goodsId = targetGoodsId, amount = targetAmount, IsNew = 1 })
        -- 新插入背包物品显示仓库红点
        if not GoodsUtils.IsHiddenGoods(targetGoodsId) then
            app.dataMgr:AddRedDotNofication(tostring(RemindTag.BACKPACK), RemindTag.BACKPACK)
        end
    end
end


--[[
    更新背包的物品数量，根据物品id
    @params goodsId    : int     物品id
    @params addAmount  : int     物品增量（正数表示增加，负数表示减少）
    @params autoRemove : bool    物品数量 <= 0 时，是否自动清除数据。默认true
--]]
function GoodsManager:UpdateBackpackAmountByGoodsId(goodsId, addAmount, autoRemove)
    local goodsData = self:GetBackpackDataByGoodsId(goodsId)
    if goodsData then
        -- update amount
        local targetAmount = checkint(goodsData.amount) + checkint(addAmount)
        self:SetBackpackAmountByGoodsId(goodsId, targetAmount, autoRemove)
    else
        -- append amount
        self:SetBackpackAmountByGoodsId(goodsId, addAmount, autoRemove)
    end
end


--[[
    获取背包数据中，某种类型的全部道具信息
    @params goodsType : str     道具类型
    @return goodsList : list    道具数据集
--]]
function GoodsManager:GetAllGoodsDataByGoodsType(goodsType)
	local goodsList = {}
	for _, goodsData in ipairs(self:GetBackpackList()) do
		if goodsType == GoodsUtils.GetGoodsTypeById(goodsData.goodsId) then
			table.insert(goodsList, {amount = goodsData.amount, goodsId = goodsData.goodsId})
		end
	end
	return goodsList
end


--[[
　　---@Description: backpack 由 array 转化为map
　　---@param :
　  ---@return : backpackMap map 类型
　　---@author : xingweihao
　　---@date : 2018/9/21 11:00 AM
--]]
function GoodsManager:GetBackPackArrayToMap()
    local backpackMap = {}
    for _, goodsData  in pairs(self:GetBackpackList()) do
        if  checkint(goodsData.amount) > 0  then
            backpackMap[tostring(goodsData.goodsId)] = goodsData
        end
    end
    return backpackMap
end


-------------------------------------------------
-- public method

--[[
通用方法 领取奖励 更新本地数据的逻辑
@see Frame.Manager.GoodsManagerDrawRewards.DrawRewards
@params props table {
	{goodsId = id, num = 数量, --其他的一些数据}
}
@params isDelayEvent bool 如果升级了 先弹出获取界面 后升级
@params isGuide bool 是否是为了引导刚进入模块把道具插入背包
@params isRefreshGoods bool 是否发送刷新道具的事件
--]]
function GoodsManager:DrawRewards(props, isDelayEvent, isGuide, isRefreshGoods)
    return self.drawRewardsLogic:DrawRewards(props, isDelayEvent, isGuide, isRefreshGoods)
end


--[[
根据道具id获取玩家道具所持数量
@see Frame.Manager.GoodsManagerDrawRewards.GetGoodsAmountByGoodsId
@params goodsId int 道具id
@return amount int 道具数量
--]]
function GoodsManager:GetGoodsAmountByGoodsId(goodsId)
    return self.drawRewardsLogic:GetGoodsAmountByGoodsId(checkint(goodsId))
end

-- short define
function GoodsManager:getGoodsNum(goodsId)
    return self:GetGoodsAmountByGoodsId(goodsId)
end


--[[
根据道具id设置道具数量
@see Frame.Manager.GoodsManagerDrawRewards.SetGoodsAmountByGoodsId
@params goodsId int 道具id
@params amount int 道具数量 最终值
--]]
function GoodsManager:SetGoodsAmountByGoodsId(goodsId, amount)
    return self.drawRewardsLogic:SetGoodsAmountByGoodsId(checkint(goodsId), amount)
end


--[[
根据道具id更新道具数量
@see Frame.Manager.GoodsManagerDrawRewards.UpdateGoodsAmountByGoodsId
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@params goodsData table 更新的道具信息
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsAmountByGoodsId(goodsId, deltaAmount, goodsData)
    return self.drawRewardsLogic:UpdateGoodsAmountByGoodsId(checkint(goodsId), deltaAmount, goodsData)
end


-------------------------------------------------
-- private method






return GoodsManager