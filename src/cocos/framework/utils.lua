local utils = {}


function utils.is_array(table)
    local max = 0
    local count = 0
    for k, v in pairs(table) do
        if type(k) == 'number' then
            if k > max then max = k end
            count = count + 1
        else
            return -1
        end
    end
end


function utils.compare(v1, v2)
    local type1 = type(v1)
    if type1 ~= type(v2) then return false end

    if type1 == 'number' and v1 == v2 then return true end

    -- table compare
    if type1 == 'table' then
        local n1 = table.maxn(v1)
        local n2 = table.maxn(v2)
        if n1 ~= n2 then return false end
        local keys = {}
        for k,_v in pairs(v1) do
            keys[k] = true
        end

        for k,v in pairs(v2) do
            if not keys[k] then
                return false
            end
            if not compare(v1[k], v2[k]) then
                return false
            end
            keys[k] = nil
        end
    end
    return true
end

--[[--
得到文件的大小
@param path string get the filesize
--]]
function utils.filesize(path)
    local size = 0
    path = cc.FileUtils:getInstance():fullPathForFilename(path)
    local f = io.open(path,"r")
    if f then
        local start = f:seek()
        size = f:seek("end")
        f:seek("set")
    end
    return size
end
--[[--
字符串拷贝
@param originText string origin data
@return #string target string data
--]]
function utils.copy(originText)
    return FTUtils:copy(originText)
end
--[[--
从文本中拷贝字符串
@param originText string origin string
@param start int start position
@param len number the copy len of string
]]
function utils.copy(originText, start, len)
    return FTUtils:copy(originText,start,len)
end

--[[--
trim string
@param text string 原始字符串
@return #string 结果字符串
--]]
function utils.trim(text)
    return FTUtils:trim(text)
end
--[[--
转为小写字符串
@param text string 原始字符串
@return #string 结果字符串
--]]
function utils.tolowercase(text)
    return FTUtils:toLowercase(text)
end
--[[--
测试字符串是以某字符开始
@param text string 原始字符串
@param sub sub sub string
@return #bool yes or no
--]]
function utils.startWith(text, sub)
    return FTUtils:startsWith(text,sub)
end
--[[--
测试字符串是以某字符结束
@param text string 原始字符串
@param sub sub sub string
@return #bool yes or no
--]]
function utils.endWith(text, sub)
    return FTUtils:endsWith(text,sub)
end
--[[--
更新字符串某字符
@param text string 原始字符串
@param c string find character
@param sub sub sub string
@return #bool yes or no
--]]
function utils.replaceChar(text, c, sub)
    FTUtils:replace(text,c,sub)
end
--[[--
@param text string 原始字符串
@param c string
@param sub string target string
@return #bool yes or no
--]]
function utils.replace(text,c, sub)
    return FTUtils:replace(text,c,sub)
end
--[[--
删除某字符
@param text string 原始字符串
@param sub sub sub string
@return #bool yes or no
--]]
function utils.removeChar(text, c)
    FTUtils:removeChar(text,c)
end

--[[--
得到一个数字的字数
@param num number  origin text
@return #number len
--]]
function utils.getNumDigits(num)
    return FTUtils:getNumDigits(tonumber(num,10))
end
--[[--
Get index of last slash character, if not found, returns -1
--]]
function utils.lastSlashIndex(path)
    return FTUtils:lastSlashIndex(path)
end

function utils.lastDotIndex(path)
    return FTUtils:lastDotIndex(path)
end

--[[--
移除路径最后一希路径
* Input                 Output<br>
* "/tmp/scratch.tiff"      "/tmp"<br>
* "/tmp/scratch"           "/tmp"<br>
* "/tmp/"                  "/"<br>
* "scratch"                ""<br>
* "/"                      "/"<br>
@param path
@return #string target string return
--]]
function utils.deleteLasPathComponent(path)
    return FTUtils:deleteLastPathComponent(path)
end
--[[--
Append a path segment to another path, for example:<br>
* Input                    Output<br>
* "/tmp", "/scratch.tiff"  "/tmp/scratch.tiff"<br>
* "/tmp//", "/scratch"     "/tmp/scratch"<br>
* "/tmp", "/"              "/tmp"<br>
* "/", "tmp/"              "/tmp"<br>
--]]
function utils.appendPathComponent(path, component)
    return FTUtils:appendPathComponent(path,component)
end

--[[--
删除路径扩展
--]]
function utils.deletePathExtension(path)
    return FTUtils:deletePathExtension(path)
end
--[[--
得到路径扩展
--]]
function utils.getPathExtension(path)
    return FTUtils:getPathExtension(path)
end
--[[--
得到父路径
--]]
function utils.getParentPath(path)
    return FTUtils:getParentPath(path)
end
--[[--
扩展路径到外部存储
* map a relative path to absolute external path, do nothing if path is absolute
* in iOS, path will be appended to ~/Documents
* in Android, path will be appended to internal storage folder
--]]
function utils.externalize(path)
    return FTUtils:externalize(path)
end
--[[--
查找处部存储，如果不存在返回本地路径
--]]
function utils.getExternalOrFullPath(path)
    return FTUtils:getExternalOrFullPath(path)
end

--[[--
递归创建文件目录
@param path string 绝对路径
@return #bool is success
--]]
function utils.createFolderReverse(path)
    return FTUtils:createIntermediateFolders(path)
end

function utils.isExistent(path)
    return FTUtils:isPathExistent(path)
end
--[[--
得到应用包路径
--]]
function utils.getPackagenName()
    return FTUtils:getPackageName();
end
--[[--
创建文件夹
--]]
function utils.createFolder(path)
    return FTUtils:createFolder(path)
end

function utils.deleteFile(path)
    return FTUtils:deleteFile(path)
end

--[[--
获取结点相对父节点的坐标
vec2
@param nod cc.Node node
@return #vec2 description
--]]
function utils.getOrigin(node)
    return FTUtils:getOrigin(node)
end
--[[--
获取节点相对于父节点的中心
--]]
function utils.getCenter(node)
    return FTUtils:getCenter(node)
end

function utils.getLocalCenter(node)
    return FTUtils:getLocalCenter(node)
end
--[[--
相对父节点的比例坐标
--]]
function utils.getPoint(node, xprecent, ypercent)
    return FTUtils:getPoint(node,xprecent,ypercent)
end
----[[--
--根据父结点锚点度算node的相对坐标
----]]
--function utils.getPoint(node, anchor)
--    return FTUtils:getPoint(node,anchor)
--end

function utils.getLocalPoint(node,xpercent , ypercent)
    return FTUtils:getLocalPoint(node,xpercent,ypercent)
end
function utils.getLocalPoint(node,anchor)
    return FTUtils:getLocalPoint(node,anchor)
end
--[[--
得到节点在世界坐标中的bounding大小
--]]
function utils.getBoundingBoxInWorldSpace(node)
    return FTUtils:getBoundingBoxInWorldSpace(node)
end

function utils.getCenterRect(spriteFrame)
    if type(spriteFrame) == 'string' then
        return FTUtils:getCenterRect(spriteFrame)
    else
        return FTUtils:getCenterRect(spriteFrame)
    end
end
--[[--
获取到当前结点所属的场景
--]]
function utils.getScene(node)
    return FTUtils:getScene(node)
end

function utils.binarySearch(a, len, key)
    return FTUtils:binarySearch(a, len, key)
end
--[[--
结合两个矩形
--]]
function utils.combine(rect1, rect2)
    return FTUtils:combine(rect1,rect2)
end

function utils.hasExernalStoragePath()
    return FTUtils:hasExternalStorage()
end

function utils.getAaiableStorageSize()
    return FTUtils:getAvailableStorageSize()
end

function utils.currentTimeMillis()
    return FTUtils:currentTimeMillis()
end

--[[--
split string into components by a separator
@param text string origin text
@param sep character delimite char
@return #table
--]]
function utils.componentOfString(text, sep)
    return FTUtils:componentsOfString(text,sep)
end

--[[--
join string into components by a separator
@param text string origin text
@param sep character delimite char
@return #table
--]]
function utils.joinString(a, sep)
    return FTUtils:joinString(a,sep)
end

--[[--
\note
* for partial valid string, the result will be
* {3.2} ==> Vec2(3.2, 0)
* {,3.4} ==> Vec2(0, 3.4)
* {3.2 ==> Vec2(3.2, 0)
* {,3.4 ==> Vec2(0, 3.4)
* {2,3,4} ==> Vec2(2, 3)
* {[2,3}]) ==> Vec2(2,3)
* {,} ==> ccp(0, 0)
--]]
function utils.ccpFromString(s)
    return FTUtils:ccpFromString(s)
end
--[[--
Size
--]]
function utils.ccsFromString(s)
    return FTUtils:ccsFromString(s)
end

function utils.ccrFromString(s)
    return FTUtils:ccrFromString(s)
end
--[[--
create a Vector from a string in format {a1,a2,a3,...}. If the element is
--]]
function utils.arrayFromString(s)
    return FTUtils:arrayFromString(s)
end

function utils.arrayToString(a)
    return FTUtils:arrayToString(a)
end

function utils.setOpacityRecursively(node, o)
    FTUtils:setOpacityRecursively(node,o)
end

function utils.getChildrenByTag(parent, tag)
    return FTUtils:getChildrenByTag(parent,tag)
end

function utils.removeChildrenByTag(parent, tag)
    FTUtils:removeChildrenByTag(parent,tag)
end

function utils.purgeDefaultKey(key)
    FTUtils:purgeDefaultForKey(key)
end
--[[--
理到字符的utf长度
--]]
function utils.getUTF8Bytes(character)
    return FTUtils:getUTF8Bytes(character)
end

function utils.strlen8(s)
    return FTUtils:strlen8(s)
end

function utils.playInternalMusic()
    FTUtils:playInternalMusic();
end

function utils.stopInternalMusic()
    FTUtils:stopInternalMusic();
end

function utils.isInternalMusicPlaying()
    return FTUtils:isInternalMusicPlaying()
end

--[[--
@param root cc.Node node root the start node to be captured, so that you can only capture part of screen. However, final image file is always window size. If root is NULL, whole screen will be captured.
@param path string storage path
@param stencil bool is
@return #string the storage path
--]]
function utils.makeScreenshot(root, path, stencil)
    return FTUtils:makeScreenshot(root,path,stencil)
end


function utils.openAppInStore(appid)
    FTUtils:openAppInStore(tostring(appid))
end

function utils.openUrl(url)
    FTUtils:openUrl(url)
end

function utils.getAppVersion(isreal)
    if isreal == nil then isreal = false end
    if isreal == true then
        if _G['aversion'] then
            return _G['aversion']
        else
            return tostring(FTUtils:getAppVersion())
        end
    else
        return tostring(FTUtils:getAppVersion())
    end
end

function utils.getDeviceType()
    return FTUtils:getDeviceType()
end

function utils.getSystemVersionInt()
    return FTUtils:getSystemVersionInt()
end

function utils.getMacAddress()
    return FTUtils:getMacAddress()
end

function utils.getCountry()
    return FTUtils:getCountry()
end

function utils.registDeviceNotification(notification)
    FTUtils:registLocalNotification(notification.type,notification.content,
        notification.hours,notification.minutes,notification.seconds)
end
function utils.loadRaw(path, decFunc)
    if decFunc and type(decFunc) == 'function' then
        return FTUtils:loadRaw(path,decFunc)
    else
        return FTUtils:loadRaw(path)
    end
end

function utils.loadCString(path, decFunc)
    if decFunc and type(decFunc) == 'function' then
        return FTUtils:loadCString(path,decFunc)
    else
        return FTUtils:loadCString(path)
    end
end

function utils.loadImage(path, decFunc)
    if decFunc and type(decFunc) == 'function' then
        return FTUtils:loadImage(path,decFunc)
    else
        return FTUtils:loadImage(path)
    end
end

function utils.loadZwoptex(plistname, texturename, decFunc)
    if decFunc and type(decFunc) == 'function' then
        return FTUtils:loadZwoptex(plistname, texturename,decFunc)
    else
        return FTUtils:loadZwoptex(plistname,texturename)
    end
end
--[[--
指定精度
--]]
function utils.pround(x, precision)
    return FTUtils:pround(x,precision)
end
--[[--
指定精度
--]]
function utils.pfloor(x, precision)
    return FTUtils:pfloor(x,precision)
end

function utils.pceil(x, precison)
    return FTUtils:pceil(x,precison)
end

--[[--
线情插值
--]]
function utils.lerp(a, b ,p)
    return FTUtils:lerp(a,b,p)
end

function utils.getcommonParameters(pmap)
    return FTUtils:getCommParamters(pmap)
end

function utils.sizeOfString(args)
    local spacing = args.spacing or 0
    return FTUtils:sizeWithString(args.text,args.width,args.fontSize,spacing)
end
--
--utils handler
--
function utils.newrandomseed()
   local ok, socket = pcall(function()
       return require("socket")
   end)

   if ok then
       math.randomseed(socket.gettime() * 1000)
   else
       math.randomseed(os.time())
   end
   math.random()
   math.random()
   math.random()
   math.random()
end

-- function utils.newrandomseed()
--     math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)))
--     --    return math.randomseed(os.time())
-- end

function utils.round(value)
    return math.floor(value + 0.5)
end


function utils.angle2radian(angle)
    return angle*math.pi/180
end

function utils.radian2angle(radian)
    return radian/math.pi*180
end

--[[--
获取文件路径
--]]
function utils.getFileName(name)
    if string.find(name, '.ccz') then
        return name
    elseif string.find(name, '.json.zip') then
        return name
    elseif string.find(name, '.json') then
        if utils.isExistent(string.format('%s.zip', name)) then
            return string.format('%s.zip', name)
        end
    elseif string.find(name, '.atlas') then
        if utils.isExistent(string.format('%s.atlas', name)) then
            return string.format('%s.atlas', name)
        end
    else
        local fname = FTUtils:deletePathExtension(name)
        if utils.isExistent(string.format('%s.pvr.ccz',fname)) then
            return string.format('%s.pvr.ccz',fname)
        elseif utils.isExistent(string.format('%s.png',fname)) then
            return string.format('%s.png',fname)
        elseif utils.isExistent(string.format('%s.jpg',fname)) then
            return string.format('%s.jpg',fname)
        end
    end
    return name
end

local function seekChildNodeByTag(root, tag)
    if not root then return end
    --if root:getTag() == tag then return root end
    if tolua.type(root) ==  'ccw.CTableView' then
        return root:cellAtIndex(tag)
    elseif tolua.type(root) == 'ccw.CGridView' then
        return root:cellAtIndex(tag)
    elseif tolua.type(root) == 'ccw.CScrollView' then
        return root:getContainer():getChildByTag(tag)
    elseif tolua.type(root) == 'ccw.CListView' then
        return root:getContainer():getChildByTag(tag)
    else
        return root:getChildByTag(tag)
    end
end
--[[--
定位页面中的节点
@param root node node
@param locator string description
@param cb function callback
--]]
function utils.locateNodByLocator(root,locator,cb)
    local segments = split(locator,'#')
    local child = root
    local node = nil
    for i=1, #segments do
        child = seekChildNodeByTag(child,checkint(segments[i]))
        if not child then
            node = nil
            --cclog(segments[i]..'is not find')
            break
        end
        --cclog('tag: %s --find %s -- pos %d--%d',segments[i],tolua.type(child))
        node = child
    end
    --查找到结点，并回调
    if cb then
        cb(node)
    end
end

function utils.androidLog( str )
    -- body
    if device.platform == 'android' then
        if not str then str = '' end --防止为空引起crash
        luaj.callStaticMethod('com.duobaogame.summer.devices.DevicesUtils','ssSystemLog',{str})
    end
end
return utils
