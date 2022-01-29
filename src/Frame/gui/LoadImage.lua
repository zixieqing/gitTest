--[[
 * author : kaishiqi
 * descpt : 加载器图片
]]
local LoadImage = class('LoadImage', function()
    local AIMG = 'ui/common/story_tranparent_bg.png'
    local node = display.newImageView(_res(AIMG), 0, 0, {ap = display.CENTER})
    node.name  = 'LoadImage'
    node:enableNodeEvents()
    node:setCascadeColorEnabled(true)
    node:setCascadeOpacityEnabled(true)
    return node
end)

local DOWNLOAD_EVENT = DOWNLOAD_DEFINE.LOAD_IMAGE.event

-- 为了防止修改后，热更新时不会及时生效，所以进行一次强行重载
unrequire('cocos.framework.filter')
filter = require('cocos.framework.filter')


function LoadImage:ctor(path, x, y, params)
    self.resPathMap_ = {}
    app:RegistObserver(DOWNLOAD_EVENT, mvc.Observer.new(self.onResDownloadedHandler_, self))
    
    if params then
        self.forceSize_   = params.forceSize
        self.isMaxRation_ = params.isMaxRation == true
        self.isMinRation_ = params.isMinRation == true
        if self.forceSize_ then
            self:setContentSize(self.forceSize_)
        end
    else
        self:setContentSize(cc.size(0,0))
    end

    -- parse args
    self:setTexture(path)
    self:setPosition(checkint(x), checkint(y))
    display.commonUIParams(self, params or {})

end


-------------------------------------------------
-- public method

function LoadImage:setTexture(path)
    self.imgPath_ = checkstr(path)

    -- clean download task
    for resPath, _ in pairs(self.resPathMap_) do
        app.downloadMgr:delResTask(resPath)
    end

    -- verify res
    local isNeedDownloadImage = false
    if string.len(self.imgPath_) > 0 then
        local isValidity, resRemoteDefine = app.gameResMgr:verifyRes(self.imgPath_)
        self.isResValidity_ = isValidity
        isNeedDownloadImage = not isValidity and resRemoteDefine
    end

    self:updateDisplayImage_()

    if isNeedDownloadImage then
        self.resPathMap_[self.imgPath_] = true
        app.downloadMgr:addResTask(self.imgPath_, DOWNLOAD_EVENT)
    end
end


-- @filterName 滤镜名字
-- @see cocos.framework.filter
function LoadImage:setFilterName(filterName, ...)
    self.imageFilterName_ = filterName
    self.imageFilterArgs_ = {...}
    self:updateDisplayImage_()
end
function LoadImage:clearFilter()
    self:setFilterName(nil)
end


function LoadImage:removeAllChildren()
    local children = self:getChildren()
    for _, child in pairs(children) do
        if child ~= self.displayImg_ then
            child:runAction(cc.RemoveSelf:create())
        end
    end
end


-------------------------------------------------
-- private method

function LoadImage:updateDisplayImage_()
    if self.displayImg_ and not tolua.isnull(self.displayImg_) then
        self.displayImg_:removeFromParent()
        self.displayImg_ = nil
    end

    if self.isResValidity_ then
        if self.imageFilterName_ then
            self.displayImg_ = FilteredSpriteWithOne:create(_res(self.imgPath_))
            self.displayImg_:setAnchorPoint(display.LEFT_BOTTOM)
            self.displayImg_:setFilter(filter.newFilter(self.imageFilterName_, self.imageFilterArgs_))
        else
            self.displayImg_ = display.newImageView(_res(self.imgPath_), 0, 0, {ap = display.LEFT_BOTTOM})
        end

        if self.forceSize_ then
            local imgSize = self.displayImg_:getContentSize()
            local scaleX  = self.forceSize_.width / imgSize.width
            local scaleY  = self.forceSize_.height / imgSize.height
            if self.isMaxRation_ then
                local maxScale = math.max(scaleX, scaleY)
                scaleX = maxScale
                scaleY = maxScale
            elseif self.isMinRation_ then
                local minScale = math.min(scaleX, scaleY)
                scaleX = minScale
                scaleY = minScale
            end
            self.displayImg_:setScaleX(scaleX)
            self.displayImg_:setScaleY(scaleY)
            self.displayImg_:setPositionX((self.forceSize_.width - imgSize.width * scaleX) / 2)
            self.displayImg_:setPositionY((self.forceSize_.height - imgSize.height * scaleY) / 2)
        else
            self:setContentSize(self.displayImg_:getContentSize())
        end

        self:addChild(self.displayImg_, -2)
    end
end


-------------------------------------------------
-- handler

function LoadImage:onEnter()
end


function LoadImage:onCleanup()
    -- clean download task
    for resPath, _ in pairs(self.resPathMap_) do
        app.downloadMgr:delResTask(resPath)
    end

    -- remove download listen
    app:UnRegistObserver(DOWNLOAD_EVENT, self)
end


function LoadImage:onResDownloadedHandler_(signal)
    if tolua.isnull(self) then return end
    local dataBody = signal:GetBody()

    -- clean download mark
    self.resPathMap_[dataBody.resPath] = nil

    if dataBody.isDownloaded and dataBody.resPath == self.imgPath_ then
        -- check downloaded
        if app.gameResMgr:verifyRes(self.imgPath_) then
            self.isResValidity_ = true
            self:updateDisplayImage_()
        end
    end
end


return LoadImage
