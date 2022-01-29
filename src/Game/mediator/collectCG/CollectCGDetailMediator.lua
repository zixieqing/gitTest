--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class CollectCGDetailMediator :Mediator
local CollectCGDetailMediator = class("CollectCGDetailMediator", Mediator)
local NAME = "CollectCGDetailMediator"
local CGCOnfig = CommonUtils.GetConfigAllMess('cg' ,'collection')
local CGFragmentConfig = CommonUtils.GetConfigAllMess('cgFragment' ,'goods')
function CollectCGDetailMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.cgId = param.cgId or 1
    self.backpackMap = self:ConvertBackpackArrayToMap()
    self.ownerTable = self:GetCGfragementTable(self.cgId )
end

function CollectCGDetailMediator:InterestSignals()
    local signals = {
    }
    return signals
end

function CollectCGDetailMediator:ProcessSignal( signal )

end

function CollectCGDetailMediator:Initial( key )
    self.super:Initial(key)
    ---@type CollectCGDetailView
    local viewComponent = require("Game.views.collectCG.CollectCGDetailView").new()
    self:SetViewComponent(viewComponent)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    local viewData = viewComponent.viewData
    self:EnterAction()
    display.commonUIParams(viewData.closeButton , { cb = function()
        app:UnRegsitMediator(NAME)
    end})
    self:UpdateUI()
end

-- 将背包数据由array 转换为map 类型
function CollectCGDetailMediator:ConvertBackpackArrayToMap()
    local backpack = {}
    for index, goodsData in ipairs(app.gameMgr:GetUserInfo().backpack) do
        backpack[tostring(goodsData.goodsId)] = goodsData
    end
    return backpack
end
function CollectCGDetailMediator:GetCGfragementTable(cgId)
    local cgOneConfig = CGCOnfig[tostring(cgId)]
    local fragments = cgOneConfig.fragments or {}
    local ownerTable = {}
    for i, v in pairs(fragments) do
        if self.backpackMap[tostring(v)]  and
            self.backpackMap[tostring(v)].amount > 0  then
            ownerTable[#ownerTable+1] = v
        end
    end
    return ownerTable
end
--[[
　　---@Description: 获取碎片的总数量
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/20 8:30 PM
--]]
function CollectCGDetailMediator:GetCGFragementCountNum()
    local cgOneConfig = CGCOnfig[tostring(self.cgId)]  or {}
    local countNum = checkint(cgOneConfig.num)
    return countNum
end
--[[
　　---@Description: 检测碎片是否手机完成
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/18 10:53 AM
--]]
function CollectCGDetailMediator:CheckPluzzCollectComplete(data)
    local isComplete  = false
    local owerNum = #data
    if owerNum == countNum  then
        isComplete = true
    end
    return isComplete
end

--[[
　　---@Description: 获取到CG 的叙述
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/18 10:57 AM
--]]
function CollectCGDetailMediator:GetCGDescr()
    local cgOneConfig = CGCOnfig[tostring(self.cgId)]  or {}
    local descr = checkint(cgOneConfig.descr)
    return descr
end

function CollectCGDetailMediator:UpdateUI()
    ---@type CollectCGDetailView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    -- 此处要填写数据
    local cgOneConfig = CGCOnfig[tostring(self.cgId)]
    local  path  = _res(string.format("arts/common/%s.jpg",cgOneConfig.path)   )
    local isExists =  utils.isExistent(path)
    if  not  isExists then
        path = _res('arts/common/loading_view_0.jpg')
    end
    viewData.pluzzImage:setTexture(path)
    local countNum = self:GetCGFragementCountNum()
    if countNum == #self.ownerTable  then
        viewData.prograssLabel:setString(__('已完成'))
        viewData.goodsBg:setVisible(false)
        viewData.goodNode:setVisible(false)
        viewData.gridImage:setVisible(false)
        viewData.bgTextImage:setVisible(true)
        local flowersPath = _res(string.format("ui/home/cg/complete/CG_puzzle_ico_completed_%s.png",tostring(cgOneConfig.icon) )   )
        local isExists =  utils.isExistent(flowersPath)
        if  not  isExists then
            flowersPath = _res('ui/home/cg/complete/CG_puzzle_ico_completed_0.png')
        end
        viewData.flowers:setVisible(true)
        viewData.flowers:setTexture(flowersPath)
        viewData.needGoodsLabel:setVisible(false)
        viewData.pluzzImage:setTouchEnabled(true)
        viewData.cardFrameImage:setOnClickScriptHandler(function()
            local view = require("Game.views.collectCG.CGLookView").new({ path = path}  )
            view:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(view)
        end)
        viewData.pluzzDescr:setString(cgOneConfig.descr)
        local labelSize = display.getLabelContentSize(viewData.pluzzDescr)
        local bgTextImageSize  =  viewData.bgTextImage:getContentSize()
        if labelSize.height + 10 >  bgTextImageSize.height  then
            viewData.bgTextImage:setContentSize(cc.size( bgTextImageSize.width , labelSize.height + 20 ))
            viewData.pluzzDescr:setPosition(37 , labelSize.height +10)
        end
    else
        viewData.lookComplete:setVisible(false)
        viewData.flowers:setVisible(false)
        viewData.bgTextImage:setVisible(false)
        viewData.goodsBg:setVisible(false)
        viewData.goodNode:RefreshSelf({goodsId = cgOneConfig.crystalId})
        display.commonUIParams(viewData.goodNode , { cb = function()
            app.uiMgr:AddDialog("common.GainPopup" ,{goodsId = cgOneConfig.crystalId})
        end})
        display.commonLabelParams(viewData.prograssLabel , {text = string.format("%d/%d", #self.ownerTable , countNum)})

    end
    for i = 1 , #self.ownerTable do
        local  cgOneFragmentConfig = CGFragmentConfig[tostring(self.ownerTable[i])] or{}
        local cgPos = checkint(cgOneFragmentConfig.cgPosition)
        if viewData.pluzzTableImage[cgPos] then
            viewData.pluzzTableImage[cgPos]:setVisible(false)
        end
    end
end

function CollectCGDetailMediator:EnterAction()
    ---@type CollectCGDetailView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewComponent:runAction(
        cc.Sequence:create(
            cc.TargetedAction:create(
                viewData.content, cc.ScaleTo:create(0.2, 1)
            ),
            cc.TargetedAction:create(
                viewData.bottomLayout, cc.MoveBy:create(0.2 , cc.p(160, 0 ))
            )
        )
    )
end
function CollectCGDetailMediator:OnRegist(  )
    
end

function CollectCGDetailMediator:OnUnRegist(  )
    local viewComponent = self:GetViewComponent()
    if viewComponent and ( not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CollectCGDetailMediator
