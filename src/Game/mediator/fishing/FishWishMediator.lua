---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/8/7 4:31 PM
---
local Mediator = mvc.Mediator
---@class FishWishMediator :Mediator
local FishWishMediator = class("FishWishMediator", Mediator)
---@type FishConfigParser
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
local prayNumConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY_NUM , 'fish')
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local NAME = "FishWishMediator"
local BTN_TAG = {
    CLOSE_TAG = 11001,
    BUY_TAG = 11002
}

function FishWishMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = app.fishingMgr:GetFishHomeData()
    self.currentClick = 0
    self.isAction = true
    self.prayConfig = {}
    self.freeTimes = self:GetFreePrayTimes()
end

function FishWishMediator:InterestSignals()
    local signals = {
        POST.FISHPLACE_PRAY.sglName 
    }
    return signals
end

function FishWishMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = checktable(signal:GetBody())
    if name == POST.FISHPLACE_PRAY.sglName  then
        app.uiMgr:ShowInformationTips(__('祈愿成功'))
        local requestData = body.requestData
        local prayNum = checkint(body.prayNum  or self:GetHomeDataByKey('prayNum') +1 )
        self:SetHomeDataByKeyalue("prayNum", prayNum)
        local prayConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY,'fish')
        local diamonNum = checkint(body.diamond)
        local ownerDiamond =   CommonUtils.GetCacheProductNum(DIAMOND_ID)
        self:SetHomeDataByKeyalue("buff" , {buffId = requestData.buffId , leftSeconds = prayConfig[tostring(requestData.buffId)].buffTime ,buffSeverTime = getServerTime() } ,false)
        CommonUtils.DrawRewards({{goodsId = DIAMOND_ID , num = (diamonNum  - ownerDiamond) }})
        self:GetFacade():UnRegsitMediator(NAME)
    end
end

function FishWishMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type FishingWishView
    local viewComponent = require("Game.views.fishing.FishingWishView").new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    ---@type GameScene
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    local prayConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY,'fish') or {}
    for i, v in pairs(prayConfig) do
        table.insert(self.prayConfig , #self.prayConfig+1 , v  )
    end
    table.sort(self.prayConfig , function(a , b )
        if checkint(a.id) > checkint(b.id)  then
            return false
        end
        return true
    end)
    self.currentClick = self:GetCurrentClick()
    -- 购买的按钮
    local buyBtn = viewData.buyBtn
    buyBtn:setTag(BTN_TAG.BUY_TAG)
    display.commonUIParams(buyBtn , {cb =  handler(self, self.ButtonAction)})
    -- 关闭按钮
    local closeLayer = viewData.closeLayer
    closeLayer:setTag(BTN_TAG.CLOSE_TAG)
    display.commonUIParams(closeLayer , {cb =  handler(self, self.ButtonAction),animate = false })

    local gridView = viewData.gridView
    gridView:setCountOfCell(#self.prayConfig)
    gridView:setDataSourceAdapterScriptHandler(handler(self ,self.OnDataSource))
    gridView:reloadData()
    viewComponent:runAction(self:OnEnterAction())
    self:UpdateUI()
end
--[[
　　---@Description: 获取到免费的祈愿次数
　　---@param :
　  ---@return : count number 类型
　　---@author : xingweihao
　　---@date : 2018/8/8 8:15 PM
--]]
function FishWishMediator:GetFreePrayTimes()
    local count  = 0
    for i, v in pairs(prayNumConfig) do
        if  v.price  and checkint(v.price) == 0  then
            count = count +1
        end
    end
    return count
end
--[[
　　---@Description: 获取到当前点击的click
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 9:35 PM
--]]
function FishWishMediator:GetCurrentClick()
    local buffData  = app.fishingMgr:GetHomeDataByKey('buff') or {}
    local buffId = checkint(buffData.buffId)
    local currentClick = 0 
    for i, v in pairs(self.prayConfig) do
        if checkint(v.id) ==  buffId then
            currentClick = i
            break
        end
    end
    return currentClick
end
function FishWishMediator:ButtonAction(sender)
    if self.isAction then
        return
    end
    local tag = sender:getTag()
    if tag == BTN_TAG.CLOSE_TAG then
        self.isAction = true
        sender:setEnabled(false)
        self:GetFacade():UnRegsitMediator(NAME)
    elseif tag == BTN_TAG.BUY_TAG  then

        local prayNum = app.fishingMgr:GetHomeDataByKey("prayNum")
        local nextPrayNum =  prayNum +1
        nextPrayNum = nextPrayNum >  table.nums(prayNumConfig) and table.nums(prayNumConfig) or nextPrayNum
        if nextPrayNum > self.freeTimes then
            local diamondNum = checkint(prayNumConfig[tostring(nextPrayNum)].price)
            local ownNum = checkint(CommonUtils.GetCacheProductNum(DIAMOND_ID))
            if diamondNum > 0 and  diamondNum >  ownNum  then
                if GAME_MODULE_OPEN.NEW_STORE then
                    app.uiMgr:showDiamonTips()
                else
                    uiMgr:ShowInformationTips(__('幻晶石不足'))
                end
                return
            end
        end
        local buffData = app.fishingMgr:GetHomeDataByKey('buff') or {}
        local leftSeconds =  checkint(buffData.leftSeconds)
        local index = self.currentClick
        local descr = ""
        if leftSeconds > 0  then
            descr = __('确定要使用当前选择的天气效果么？（当前使用中的天气效果会被覆盖）')
        else
            if self.currentClick == 0  then
                app.uiMgr:ShowInformationTips(__('请先选择天气效果'))
                return
            end
            descr =  __('确定要使用当前选择的天气效果么？')
        end
        local commonTip = require('common.CommonTip').new({descr = descr , callback = function ()
            self:SendSignal(POST.FISHPLACE_PRAY.cmdName , {buffId = self.prayConfig[index].id })
        end})
        uiMgr:GetCurrentScene():AddDialog(commonTip)
        commonTip:setPosition(display.center)
    end
end
function FishWishMediator:OnDataSource(cell, index)
    local pcell = cell
    local index = index +1
    if  not  pcell then
        pcell = self:GetViewComponent():CreateWishkindsCell()
        local  cellLayout =  pcell:getChildByName("cellLayout")
        cellLayout:runAction(
                cc.Sequence:create(
                        cc.MoveBy:create(0, cc.p(0, -400)),
                        cc.DelayTime:create(0.05* (index-1)),
                        cc.Spawn:create(
                                cc.JumpBy:create(0.35, cc.p(0, 400) , 150 ,1),
                                cc.FadeIn:create(0.35)
                        )

                )
        )
    end
    xTry(function()
        local cellLayout   = pcell:getChildByName("cellLayout")
        local bgLight      = cellLayout:getChildByName("bgLight")
        local bgImage      = cellLayout:getChildByName("bgImage")
        local nameLabel    = cellLayout:getChildByName("nameLabel")
        local iconImage    = cellLayout:getChildByName("iconImage")
        local weatherLabel = cellLayout:getChildByName("weatherLabel")
        local effectLabel  = cellLayout:getChildByName("effectLabel")
        bgImage:setTag(index)
        display.commonLabelParams(nameLabel , {text = self.prayConfig[index].name or ""})
        display.commonLabelParams(weatherLabel , {text = self.prayConfig[index].weatherDescr or ""})
        display.commonLabelParams(effectLabel , {text = self.prayConfig[index].descr or ""})
        display.commonUIParams(bgImage , {cb = handler(self, self.CellBtnClick) , animate = false})
        iconImage:setTexture(_res('ui/common/' .. self.prayConfig[index].icon))
        if self.currentClick == index then
            bgLight:setVisible(true)
         else
            bgLight:setVisible(false)
        end
    end,__G__TRACKBACK__)
    return pcell
end
--[[
　　---@Description: 更新Button 按钮的显示
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 8:22 PM
--]]
function FishWishMediator:UpdateUI()
    local viewData         = self:GetViewComponent().viewData
    local freeLabel        = viewData.freeLabel
    local richLabel        = viewData.richLabel
    local prayNum = app.fishingMgr:GetHomeDataByKey("prayNum")
    local nextPrayNum =  prayNum +1
    local countNum = table.nums(prayNumConfig)
    nextPrayNum = nextPrayNum > countNum  and countNum or nextPrayNum
    if nextPrayNum > self.freeTimes then
        freeLabel:setVisible(false)
        richLabel:setVisible(true)
        display.reloadRichLabel(richLabel ,{
            c = {
                fontWithColor('14' ,{text = prayNumConfig[tostring(nextPrayNum)].price}),
                {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , scale = 0.2 },
                fontWithColor('14' ,{text = __('购买')})
            }
        })
        CommonUtils.AddRichLabelTraceEffect(richLabel)
    else
        richLabel:setVisible(true)
        display.reloadRichLabel(richLabel ,{
            c = {
                fontWithColor('14' ,{text = __('购买')})
            }
        })
        CommonUtils.AddRichLabelTraceEffect(richLabel)
        freeLabel:setVisible(true)
        display.commonLabelParams(freeLabel , { text = string.format(__('今日剩余免费次数：%d'),self.freeTimes - prayNum) })
    end
end
--[[
　　---@Description: 设置homeData 的数据
　　---@param : key homeData 的键值 value 对应的值 isMagre 是否合并数据
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 8:53 PM
--]]
function FishWishMediator:SetHomeDataByKeyalue(key , value, isMagre)
    app.fishingMgr:SetHomeDataByKeyalue(key , value , isMagre )
end
--[[
　　---@Description: 获取到homeData 的某项键值
　　---@param : key homeData 的键值 value 对应的值
　  ---@return : homeData 对应键的value 值
　　---@author : xingweihao
　　---@date : 2018/8/8 8:53 PM
--]]
function FishWishMediator:GetHomeDataByKey(key)
    return app.fishingMgr:GetHomeDataByKey(key)
end

function FishWishMediator:CellBtnClick(sender)
    if self.isAction  then
        return
    end
    local tag = sender:getTag()
    if self.currentClick == tag then
        return
    end
    local viewData = self:GetViewComponent().viewData
    local preCell = viewData.gridView:cellAtIndex(self.currentClick -1)
    if preCell and (not tolua.isnull(preCell)) then
        local cellLayout = preCell:getChildByName("cellLayout")
        local bgLight    = cellLayout:getChildByName("bgLight")
        bgLight:setVisible(false)
    end
    self.currentClick = tag
    local currentCell = viewData.gridView:cellAtIndex(self.currentClick -1)
    if currentCell and (not tolua.isnull(currentCell)) then
        local cellLayout = currentCell:getChildByName("cellLayout")
        local bgLight    = cellLayout:getChildByName("bgLight")
        bgLight:setVisible(true)
    end
end
function FishWishMediator:OnEnterAction()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local buyBtn = viewData.buyBtn
    local wishLabel = viewData.wishLabel
    local seqAction =cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(
                buyBtn , cc.Sequence:create(
                        cc.DelayTime:create(0.2) ,
                        cc.FadeIn:create(0.3)
                )
            ),
            cc.TargetedAction:create(
                wishLabel , cc.Sequence:create(
                        cc.DelayTime:create(0.2) ,
                        cc.FadeIn:create(0.3)
                )
            )
        ),
        cc.CallFunc:create(function()
            self.isAction = false
        end)
    )
    return seqAction
end
function FishWishMediator:OnExitAction()
    local viewComponent = self:GetViewComponent()
    local seqAction = cc.Sequence:create(
            cc.Spawn:create(
                    cc.TargetedAction:create(viewComponent.viewData.blackLayer ,cc.FadeOut:create(0.4) ) ,
                    cc.Sequence:create(cc.FadeOut:create(0.4))
            ),
            cc.DelayTime:create(0.02),
            cc.RemoveSelf:create()
    )
    return seqAction
end
function FishWishMediator:OnRegist()
    regPost(POST.FISHPLACE_PRAY)
end

function FishWishMediator:OnUnRegist(  )
    unregPost(POST.FISHPLACE_PRAY)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(self:OnExitAction())
    end
end

return FishWishMediator