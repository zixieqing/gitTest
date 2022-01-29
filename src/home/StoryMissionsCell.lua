local StoryMissionsCell = class('home.StoryMissionsCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.StoryMissionsCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function StoryMissionsCell:ctor(...)
    local arg = {...}
    local size = cc.size(430,96)
    self:setContentSize(size)

    local eventNode = CLayout:create(cc.size(430,96))
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode

    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/home/story/gut_task_btn_branch.png')
    })
    -- toggleView:setScale(0.95)
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView)

    local selectImg = display.newImageView(_res('ui/home/story/gut_task_btn_select.png'),0,0,{as = false})
    -- selectImg:setScale(0.92)
    selectImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    self.eventnode:addChild(selectImg)
    self.selectImg = selectImg
    self.selectImg:setVisible(false)

    local typeLabel = display.newLabel(14, size.height - 16, fontWithColor(16, {text = '', ap = display.LEFT_TOP}))
    self.eventnode:addChild(typeLabel,5)
    self.typeLabel = typeLabel

    local unlockImg = display.newImageView(_res('ui/common/summer_activity_task_unlock.png'), size.width * 0.5,size.height * 0.5)
    self.unlockImg = unlockImg
    self.eventnode:addChild(unlockImg)
    self.unlockImg:setVisible(false)

    local labelName = display.newLabel(24, size.height - 42,fontWithColor(15,{ color = '5c5c5c',text = '', w = 300, h = 120}))
    display.commonUIParams(labelName, {ap = cc.p(0, 1)})
    self.eventnode:addChild(labelName,5)
    self.labelName = labelName

    local redPointImg = display.newImageView(_res('ui/common/common_ico_red_point.png'),0,0,{as = false})
    redPointImg:setPosition(cc.p(size.width - 20,size.height - 16 ))
    self.eventnode:addChild(redPointImg,10)
    redPointImg:setScale(0.75)
    self.redPointImg = redPointImg
    -- self.redPointImg:setVisible(false)

    local npcImg = display.newImageView(_res(CommonUtils.GetNpcIconPathById('role_1',3)), self.eventnode:getContentSize().width - 6 ,  self.eventnode:getContentSize().height*0.5,
    {ap = cc.p(1, 0.5)})
    self.eventnode:addChild(npcImg,2)
    npcImg:setVisible(false)
    self.npcImg = npcImg

    local lockImg = display.newNSprite(_res('ui/common/common_ico_lock.png'), size.width - 28, size.height / 2, {ap = display.RIGHT_CENTER})
    lockImg:setScale(0.75)
    lockImg:setVisible(false)
    self.lockImg = lockImg
    self.eventnode:addChild(lockImg, 2)
end
return StoryMissionsCell
