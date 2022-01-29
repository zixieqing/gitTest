--[[
卡池选择页面view
--]]
local CapsuleChooseView = class('CapsuleChooseView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleChooseView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function CapsuleChooseView:ctor( ... )
    self.args = unpack({...})
    self.cardPoolDatas = checktable(self.args.cardPoolDatas)
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleChooseView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        -- 列表
        local tableView = CTableView:create(cc.size(display.width - 2*display.SAFE_L, display.height))
        tableView:setSizeOfCell(cc.size(600, display.height))
        tableView:setDirection(eScrollViewDirectionHorizontal)
        tableView:setPosition(display.center)
        view:addChild(tableView, 10)

        return {
            view             = view, 
            tableView        = tableView
        }

    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self.eaterLayer = eaterLayer
    self:addChild(eaterLayer, -1)
    -- eaterLayer:setOnClickScriptHandler(function()
    --     PlayAudioByClickClose()
    -- end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.tableView:setDataSourceAdapterScriptHandler(handler(self, self.DataSourceAction))
        self.viewData_.tableView:setCountOfCell(#self.cardPoolDatas)
        self.viewData_.tableView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
列表处理
--]]
function CapsuleChooseView:DataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(600, display.height)

    if pCell == nil then
        pCell = require('Game.views.drawCards.CapsuleCell').new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.ChooseButtonCallback))
        pCell.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    end
    xTry(function()
        local datas = self.cardPoolDatas[index]
        pCell.bgSpine:update(0)
        pCell.bgSpine:setToSetupPose()
        if datas.activityId then 
            pCell.bgSpine:setAnimation(0, 'idle2', true)
        else
            pCell.bgSpine:setAnimation(0, 'idle1', true)
        end
        if datas.activityId then
            pCell.nameBg:getLabel():setString(datas.poolName[i18n.getLang()])
            pCell.adImage:setTexture(_res('ui/home/capsule/activityCapsule/' .. tostring(datas.masterView[i18n.getLang()]) .. '.png'))
            pCell.adImage:setVisible(true)
        else
            pCell.nameBg:getLabel():setString(__('普通召唤'))
            pCell.adImage:setVisible(false)
        end
        pCell.bgBtn:setTag(index)
        pCell.tipsBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
卡池选择按钮点击回调
--]]
function CapsuleChooseView:ChooseButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    AppFacade.GetInstance():DispatchObservers(CAPSULE_CHOOSE_CARDPOOL, {index = tag})
end
--[[
卡池详情按钮点击回调
--]]
function CapsuleChooseView:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local capsulePrizeView = require( 'Game.views.drawCards.CapsulePrizeView' ).new({cardPoolDatas = self.cardPoolDatas[tag]})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsulePrizeView)
end
return CapsuleChooseView