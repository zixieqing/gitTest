--[[
--@modify 2017-7-18 将拖人上去改为点击直接上冰场的逻辑
--]]
local IceRoomHeroCell = class('IceRoomHeroCell',function ()
    local pageviewcell = CLayout:create()
    pageviewcell.name = 'views.IceRoomHeroCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")

local img = {
    {image = 'ui/common/card_job_def.png'},
    {image = 'ui/common/card_job_atk.png' },
    {image = 'ui/common/card_job_arrow.png' },
    {image = 'ui/common/card_job_heart.png'},
    -- {image = 'ui/home/teamformation/card_job_heart.png'},
}

local RankImg = {
    {image = 'ui/home/teamformation/choosehero/team_card_ico_white.png'},
    {image = 'ui/home/teamformation/choosehero/team_card_ico_blue.png'},
    {image = 'ui/home/teamformation/choosehero/team_card_ico_purple.png' },
    {image = 'ui/home/teamformation/choosehero/team_card_ico_orange.png'},
    -- {image = 'ui/home/teamformation/card_job_heart.png'},
}

function IceRoomHeroCell:ctor(...)
    local args = unpack({...})
    local ssize = args.size
    self:setContentSize(ssize)

    self.viewData = nil
    self.isShow = false
    self.isRemove = false

    xTry(function()
        local size = cc.size(174,218)
        local view = CLayout:create()
        view:setContentSize(size)
        view:setPosition(utils.getLocalCenter(self))
        self:addChild(view)

        local eventNode = CColorView:create(cc.c4b(10,10,100,0))
        eventNode:setContentSize(size)
        eventNode:setTouchEnabled(true)
        eventNode:setPosition(utils.getLocalCenter(self))
        self:addChild(eventNode,40)
        local cardHeadNode = require('common.CardHeadNode').new({
			cardData = {cardId = 200001}
		})
		cardHeadNode:setScale(0.9)
        display.commonUIParams(cardHeadNode, {ap = display.CENTER_TOP, po = cc.p(size.width * 0.5 + 4, size.height)})
		self:addChild(cardHeadNode)

        local progressBG = display.newImageView(_res('ui/home/teamformation/newCell/refresh_bg_tired_2.png'), {
            scale9 = true, size = cc.size(size.width - 14,28)
        })
        display.commonUIParams(progressBG, {po = cc.p(size.width * 0.5 + 4, 32)})
        self:addChild(progressBG,2)

        local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_red.png'))
        operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
        operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
        operaProgressBar:setMaxValue(100)
        operaProgressBar:setValue(0)
        operaProgressBar:setPosition(cc.p(20, 30))
        self:addChild(operaProgressBar,5)
        local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
        vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
        vigourProgressBarTop:setPosition(cc.p(16,30))
        self:addChild(vigourProgressBarTop,6)

        local vigourLabel = display.newLabel(20 + operaProgressBar:getContentSize().width + 4, operaProgressBar:getPositionY(),{
            ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = ""
        })
        self:addChild(vigourLabel, 6)
        self.viewData = {
            view              = view,
            cardHeadNode      = cardHeadNode,
            vigourProgressBar = operaProgressBar,
            vigourLabel       =  vigourLabel,
        }

        eventNode:setOnClickScriptHandler(function(sender)
            --上场小人的逻辑功能
            PlayAudioByClickNormal()
            local p = cc.p(display.cx, display.cy)
            shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="finish", position = p, id = self:getTag()})
        end)
        --[[
        eventNode:setOnTouchMovedScriptHandler(function(sender, touch)
            xTry(function()
                local p = touch:getLocation()
                if p.y > 250 then
                    if not self.isShow then
                        self.isShow = true
                        self.isRemove = true
                        --第一次的添加内容操作
                        shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="show", position = p, id = self:getTag()})
                    else
                        --正常的移动操作
                        shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="move", position = p, id = self:getTag()})
                    end
                else
                    --需要移除的操作
                    if self.isRemove then
                        self.isRemove = false
                        self.isShow = false
                        shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="remove", position = p, id = self:getTag()})
                    end
                end
            end, __G__TRACKBACK__)
            return false
        end)

        eventNode:setOnTouchEndedScriptHandler(function(sender, touch)
            xTry(function()
                self.isShow = false
                self.isRemove = false
                local p = touch:getLocation()
                if p.y > 250 then
                    --需要添加上去的角色位置
                    shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="finish", position = p, id = self:getTag()})
                else
                    --移除的操作
                    shareFacade:DispatchObservers(SIGNALNAMES.ICEROOM_MOVE_EVENT,{event="remove", position = p, id = self:getTag()})
                end
                print('========= end=======',p.x, p.y)
            end, __G__TRACKBACK__)
            return false --继续事件处理
        end)
    --]]
    end,__G__TRACKBACK__)
end

function IceRoomHeroCell:UpdateUI(datas)
    self.viewData.cardHeadNode:RefreshUI({
        id = checkint(datas.id),
        showActionState = true
    })
    local vigour = checkint(datas.vigour)
    self.viewData.vigourLabel:setString(tostring(vigour))
    local maxVigour = app.restaurantMgr:getCardVigourLimit(datas.id)
    local ratio = (vigour / maxVigour) * 100
    self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
    if (ratio > 40 and (ratio <= 60)) then
      self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
    elseif ratio > 60 then
      self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
    else
      self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_red.png')
    end
    --TODO 是否清缓存下
    display.removeUnusedSpriteFrames() --测试清除缓存
end

return IceRoomHeroCell
