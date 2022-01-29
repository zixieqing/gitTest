---
--- Created by xingweihao.
--- DateTime: 23/08/2017 7:59 PM
---
---@class ActivityBannerView :Node
local ActivityBannerView = class('home.ActivityBannerView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = cc.size(400, 123)})
    --CLayout:create(cc.size(400,))
    node.name = 'Game.views.ActivityBannerView'
    node:enableNodeEvents()
    return node
end)
local WebSprite = require('root.WebSprite')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function ActivityBannerView:ctor(param)
    param = param or {}
    self.pageData = param.activity or {}
    self.currentPage =1
    self.showRemindIcon = 0 -- 是否显示小红点
    self:initUI()
end

function ActivityBannerView:initUI()
    self:setPosition(cc.p(display.SAFE_R -114, 125 -84))
    self:setAnchorPoint(display.RIGHT_BOTTOM)

    local size = self:getContentSize()
    local swallowLayer = display.newLayer(0, 0, { color = cc.c4b(0,0,0,0),size = size})
    self:addChild(swallowLayer)

    local pageSize = cc.size(358, 123)
    local activityPageView = CPageView:create(pageSize)
    activityPageView:setAnchorPoint(cc.p(0.5, 0.5))
    activityPageView:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
    activityPageView:setDirection(eScrollViewDirectionHorizontal)
    activityPageView:setSizeOfCell(pageSize)
    activityPageView:setName('CPAGE_VIEW')
    activityPageView:setBounceable(false)
    self.activityPageView = activityPageView
    self:addChild(activityPageView)
    self.activityPageView = activityPageView

    local nextBtn = display.newButton(size.width -60, size.height/2, {n = _res('ui/common/common_btn_switch.png'), ap =display.LEFT_CENTER, cb = handler(self, self.nextAndLastPage)})
    self:addChild(nextBtn,2)
    nextBtn:setName("nextBtn")

    local lastBtn = display.newButton( 60,size.height/2, {n = _res('ui/common/common_btn_switch.png'), ap =display.LEFT_CENTER,cb = handler(self, self.nextAndLastPage)})
    self:addChild(lastBtn,2)
    lastBtn:setName("lastBtn")
    lastBtn:setScale(-1)

    self.nextBtn = nextBtn
    self.lastBtn = lastBtn

    -- 判断是否显示小红点
    for _,v in pairs(checktable(gameMgr:GetUserInfo().tips)) do
        if checkint(v) == 1 then
            self.showRemindIcon = 1
            break
        end
    end

    --self:UpdateUI(gameMgr:GetUserInfo().activityHomeData)
end

function ActivityBannerView:UpdateUI(param)
    param = param or {}
    self.pageData = param.activity or {}
    local width = 15
    local size = self:getContentSize()
    local tipAllSize = cc.size(width *  #self.pageData,width)
    local node = self:getChildByName('tipAllLayout')
    if node then node:removeFromParent() end
    local tipAllLayout =  display.newLayer(size.width/2,15,{ ap = display.CENTER , size = tipAllSize , color = cc.c4b(0,0,0,0)})
    tipAllLayout:setName('tipAllLayout')
    self:addChild(tipAllLayout,4)
    self.tipTable  = {}
    for i =1 , #self.pageData do
        local tipImage = display.newImageView(_res("ui/home/activity/cover_banner_ico_point_normal.png"), width * (i - 0.5), width /2)
        tipAllLayout:addChild(tipImage, 4)
        table.insert(self.tipTable, #self.tipTable+1, tipImage)
    end
    local len = table.nums(self.pageData)
    self.nextBtn:setVisible(false)
    self.lastBtn:setVisible(false)
--[[    if len == 1 then
        self.nextBtn:setVisible(false)
        self.lastBtn:setVisible(false)
    else
        self.nextBtn:setVisible(true)
        self.lastBtn:setVisible(true)
    end
    if self.currentPage ==1 then
        self.lastBtn:setVisible(false)
    end]]
    local activityPageView =  self.activityPageView
    activityPageView:setCountOfCell(#self.pageData)
    activityPageView:setDataSourceAdapterScriptHandler(handler(self, self.PageViewDataAdapter))
    activityPageView:setOnPageChangedScriptHandler(handler(self, self.PageViewChangeHandler))
    activityPageView:reloadData()
    self:SelectPageTip()
end

function ActivityBannerView:CreatePageCell()
    local pageBg = display.newImageView(_res('ui/home/activity/cover_banner_bg.png'))
    local pageBgSize = pageBg:getContentSize()
    local pageSize = pageBgSize

    local pCell = CPageViewCell:new()
    pCell:setContentSize(cc.size(358,123))
    local pageLayout = CLayout:create(pageBgSize)
    display.commonUIParams(pageBg, {po = cc.p(pageBgSize.width/2 , pageBgSize.height/2)})
    pageLayout:addChild(pageBg,1)
    local activityBannerImage = display.newImageView(_res('ui/home/activity/activity_common_bg.jpg'),pageSize.width/2, pageSize.height/2)
    pageLayout:addChild(activityBannerImage,2)
    local bannerBgFront = display.newImageView(_res('ui/home/activity/cover_bannner_bg_front.png'), pageSize.width/2, pageSize.height/2 ,{enable = true})
    pageLayout:addChild(bannerBgFront,3)
    pageLayout:setPosition(cc.p(pageSize.width/2, pageSize.height/2))
    pCell:addChild(pageLayout)
    local webSprite = WebSprite.new({url = '', ad = true, hpath = _res('ui/home/activity/activity_common_bg.jpg'),tsize = cc.size(345,110)})
    webSprite:setName("webSprite")
    pageLayout:addChild(webSprite, 2)
    webSprite:setPosition(cc.p(348/2 ,110/2 +5))
    -- 小红点
    local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), pageBgSize.width - 20, pageBgSize.height - 20)
    pageLayout:addChild(remindIcon, 10)


    pCell.activityBannerImage = activityBannerImage
    pCell.bannerBgFront = bannerBgFront
    pCell.webSprite = webSprite
    pCell.remindIcon = remindIcon
    return pCell
end
function ActivityBannerView:PageViewDataAdapter(cell, idx)
        local index  = idx +1
        local pCell = cell
        xTry(function()
            if pCell == nil then
                pCell = self:CreatePageCell()
            end
            local image = "activity_common_bg"

            local image = self.pageData[index].image[i18n.getLang()]
            image = (image ~= "" and image)  or "activity_common_bg"

            local imagePath  = _res(string.format('ui/home/activity/%s' ,image))
            local fileUtils = cc.FileUtils:getInstance()
            local isFileExist =  fileUtils:isFileExist(imagePath)
            if not isFileExist then
                pCell.webSprite:setVisible(true)
                pCell.activityBannerImage:setVisible(false)
                pCell.webSprite:setWebURL(image)
            else
                pCell.webSprite:setVisible(false)
                pCell.activityBannerImage:setVisible(true)
                pCell.activityBannerImage:setTexture(imagePath)
            end
            pCell.bannerBgFront:setTag(self.pageData[index].activityId)
            pCell.bannerBgFront:setOnClickScriptHandler(handler(self, self.GotoActivityView))
            -- 判断小红点显示
            if self.showRemindIcon > 0 then
                pCell.remindIcon:setVisible(true)
            else
                pCell.remindIcon:setVisible(false)
            end
        end,function()
        pCell = CPageViewCell:new()
    end)
    return pCell
end
function ActivityBannerView:GotoActivityView(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},
    {name = "ActivityMediator" , params = {activityId = tag }})
end
function ActivityBannerView:PageViewChangeHandler(idx , index)

    self.currentPage = index +1
    self:UpdateCell()
    self:SelectPageTip()
end
function ActivityBannerView:nextAndLastPage(sender)
    local name = sender:getName()
    local pageSize = self.activityPageView:getContentSize()
    local num = self.currentPage
    --if name == "nextBtn" then
    --    if  self.currentPage < #self.pageData then
    --        self.activityPageView:setContentOffset(cc.p(-pageSize.width *num ,0))
    --    end
    --elseif name ==  "lastBtn" then
    --    if  self.currentPage > 1 then
    --        print(self.currentPage )
    --        self.activityPageView:setContentOffset(cc.p(-pageSize.width * (num-2),0))
    --    end
    --end
end
function ActivityBannerView:SelectPageTip()
    for i =1 , #self.tipTable do
        if i == self.currentPage then
            self.tipTable[i]:setTexture(_res("ui/home/activity/cover_banner_ico_point_selected.png"))
        else
            self.tipTable[i]:setTexture(_res("ui/home/activity/cover_banner_ico_point_normal.png"))
        end
    end
end
function ActivityBannerView:UpdateCell()
    --self.nextBtn:setVisible(true)
    --self.lastBtn:setVisible(true)
    --if self.currentPage == 1 then
    --    self.lastBtn:setVisible(false)
    --end
    --if self.currentPage == #self.pageData then
    --    self.nextBtn:setVisible(false)
    --end
end


return ActivityBannerView
