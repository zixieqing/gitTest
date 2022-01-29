--[[--
network remote sprite
--]]
local WebSprite = class('WebSprite',function()
    local graySprite = FilteredSpriteWithOne:create()
    graySprite.name  = 'WebSprite'
    graySprite:enableNodeEvents()
    return graySprite
end)


local URLParser = require('cocos.cocos2d.URL')
local storePath = HEADER_ABSOLUTE_PATH
local shareFacade = AppFacade.GetInstance()


--[[
--初始化相关的数据
--@url  http url地址
--@tsize 表示需要适配的node节点的大小
--@hpath 表示初始的默认图标
--]]
function WebSprite:ctor(...)
    local arg = unpack({...})
    self.__md5 = nil
    self.spriteMD5 = nil
    self.hasBackup = false
    if arg then
        self.__fill = arg.fill
        self.__url = arg.url
        self.__msize = arg.tsize
        self.__dHeader = arg.hpath
        self.__isAd = (arg.ad or false)
        self:setContentSize(checktable(arg.size))
        if self.__url and not self:_isRemoteFileURL(self.__url) then
            if string.match(self.__url, '^%d+') then
                local lpath = _res(string.format('ui/head/avator_icon_%s',self.__url))
                if utils.isExistent(lpath) then
                    self:setTexture(lpath)
                else
                    self:setTexture(self.__dHeader)--设置初始头像
                end
            else
                self:setTexture(self.__dHeader)--设置初始头像
            end
            self:adjustSize()
        else
            self:initWithURL()
        end
    end
end


function WebSprite:adjustSize()
    if self.__fill then
        local w1 = self:getContentSize().width
        local h1 = self:getContentSize().height
        local w0 = self.__msize and self.__msize.width or w1
        local h0 = self.__msize and self.__msize.height or h1
        self:setScaleX(w0 / w1)
        self:setScaleY(h0 / h1)
    else
        local r1 = self:getContentSize().width
        local r0 = self.__msize and self.__msize.width or r1
        self:setScale(r0 / r1)
    end
end


function WebSprite:getURLMd5()
    local tempmd5 = crypto.md5(self.__url)
    local filename = storePath .. tempmd5
    if utils.isExistent(filename) then
        return true, filename
    end
    return false, filename
end

function WebSprite:initWithURL()
    local urlInfo = URLParser.parse(self.__url)
    if urlInfo and urlInfo.path then
        local path = urlInfo.path
        local urlName = FTUtils:lastPathComponent(path)
        self.__md5 = self.spriteMD5 or FTUtils:deletePathExtension(urlName)
        if string.len(self.__md5) ~= 32 then
            self.__md5 = nil
        end
    end
    local isExist, fileName = self:getURLMd5()
    if isExist then
        local showTarget = 1
        if self.__md5 then
            local lmd5 = crypto.md5file(fileName)
            if lmd5 and lmd5 ~= self.__md5 then
                --图片片md5正常
                showTarget = 0
                --删除内容不正确的图片,此处可能存在一个bug
                -- FTUtils:deleteFile(fileName)
            end
        end
        if showTarget == 1 then
            self:setTexture(fileName)
            self:adjustSize()
        else
            self:setTexture(self.__dHeader)--设置初始头像
            self:adjustSize()
            self:updateTexture(fileName) --更新纹理 --更新失败后会请求
        end
    else
        self:setTexture(self.__dHeader)--设置初始头像
        self:adjustSize()

        if self:_isRemoteFileURL(self.__url) then
            --如果不存在的时候，启动http下载
            if network.getInternetConnectionStatus() == 0 then
                return
            end
            local fileName = crypto.md5(self.__url)
            app.downloadMgr:addUrlTask(self.__url, DOWNLOAD_DEFINE.HEADER_IMG.event, storePath, fileName)
        end
    end
end

function WebSprite:updateTexture(fileName)
    if FTUtils:isPathExistent(fileName) then --修正文件不存在的bug
        if self.__md5 then
            local lmd5 = crypto.md5file(fileName)
            if lmd5 == nil then
                --文件不正常
                FTUtils:deleteFile(fileName)
                return
            end
            if lmd5 and lmd5 ~= self.__md5 then
                --图片片md5异常
                --删除内容不正确的图片
                FTUtils:deleteFile(fileName)
                return
            end
        end
        xTry(function()
            local sprite = display.newSprite(fileName) --创建下载成功的sprite
            if not sprite then return end
            local texture = sprite:getTexture()--获取纹理
            local size = texture:getContentSize()
            self:setTexture(texture)--更新自身纹理
            self:setTextureRect(cc.rect(0,0,size.width,size.height))
            -- local r1 = size.width
            -- local r0 = self.__msize and self.__msize.width or r1
            -- self:setScale(r0 / r1)
            self:adjustSize()
        end,__G__TRACKBACK__)
    end
end

function WebSprite:setWebURL(purl)
    if (not purl) then
        self:setTexture(self.__dHeader)--设置初始头像
        self:adjustSize()
        return
    end
    local canInitURL = (self.__url ~= purl)
    self.__url = purl
    if self:_isRemoteFileURL(purl) then
        if canInitURL then
            self:initWithURL()
        end
    else
        if string.match(self.__url, '^%d+') then
            local lpath = _res(string.format('ui/head/avator_icon_%s',self.__url))
            if utils.isExistent(lpath) then
                self:setTexture(lpath)
            else
                self:setTexture(self.__dHeader)--设置初始头像
            end
        else
            if utils.isExistent(self.__url) then
                self:setTexture(self.__url)
            else
                self:setTexture(self.__dHeader)--设置初始头像
            end
        end
        self:adjustSize()
    end
end

function WebSprite:_isRemoteFileURL(url)
    if url and string.len(url) > 0 and (string.find(url,'http://') or string.find(url,'https://')) then
        return true
    end
    return false
end

function WebSprite:setTargetContentSize(size)
    self.__msize = size
end

function WebSprite:setSpriteMD5(md5)
    self.spriteMD5 = md5
end

function WebSprite:onExit()
    local tempmd5 = crypto.md5(self.__url)
    local filename = storePath .. tempmd5
    display.removeImage(filename)
end

function WebSprite:onEnter()
    shareFacade:RegistObserver(DOWNLOAD_DEFINE.HEADER_IMG.event, mvc.Observer.new(self.onDownload_, self))
end
function WebSprite:onCleanup()
    shareFacade:UnRegistObserver(DOWNLOAD_DEFINE.HEADER_IMG.event, self)
end

function WebSprite:onDownload_(signal)
    --下载成功的逻辑
    if tolua.isnull(self) then return end
    local dataBody = signal:GetBody()
    if self.__url == dataBody.targetUrl then
        local tempmd5 = crypto.md5(self.__url)
        local filename = storePath .. tempmd5
        self:updateTexture(filename)
    end
end

return WebSprite
