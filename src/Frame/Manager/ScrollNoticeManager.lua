--[[
UI管理模块
场景管理相关
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class ScrollNoticeMgr
local ScrollNoticeMgr = class('ScrollNoticeMgr',ManagerBase)

ScrollNoticeMgr.instances = {}



local scheduler = require('cocos.framework.scheduler')

local ScrollNoticeNode = class('ScrollNoticeNode', function()
end)

function ScrollNoticeNode:ctor(...)
    local args = unpack({...})
    self.onFinishMove = args.cb
    self.textQueue = {} --播放的文字队列
    self.isScheduling = false --是正在播放中

end

function ScrollNoticeNode:AddNoticeInfo(noticeObj)
    table.insert(self.textQueue,noticeObj)
    if (not self.isScheduling) and (#self.textQueue > 0) then
        --显示文字执行更新
        self.updateHandler = scheduler.scheduleGlobal(handler(self, self.Update))
        self.isScheduling = true
    end
end

function ScrollNoticeNode:Update(dt)
    --如果位置信息执行完成，弹出一个列表的一数据
    --直到没有文字信息要显示时
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
    self.isScheduling = false
    if self.onFinishMove then
        self.onFinishMove(self)
    end
end

function ScrollNoticeNode:onCleanup()
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
end

--[[
--管理器的逻辑 
--]]
function ScrollNoticeMgr:ctor( key )
	self.super.ctor(self)
	if ScrollNoticeMgr.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的facade类型" )
		return
	end
	funLog(Logger.INFO, "ScrollNoticeMgr" )
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
    self.noticeNode = nil --滚动页面节点对象
    self.curNoticeObj = nil --当前正在播放的滚动公告的对象
    -- self.updateHandler = scheduler.scheduleGlobal(handler(self, self.ClearViews),3) --每2秒钟检测一次的逻辑
	ScrollNoticeMgr.instances[key] = self
end

function ScrollNoticeMgr.GetInstance(key)
	key = (key or "ScrollNoticeMgr")
	if ScrollNoticeMgr.instances[key] == nil then
		ScrollNoticeMgr.instances[key] = ScrollNoticeMgr.new(key)
	end
	return ScrollNoticeMgr.instances[key]
end

function ScrollNoticeMgr.Destroy( key )
	key = (key or "ScrollNoticeMgr")
	if ScrollNoticeMgr.instances[key] == nil then
		return
	end
    local instance = HttpManager.instances[key]
    if instance.updateHandler then
        scheduler.unscheduleGlobal(instance.updateHandler)
    end
    instance:PurgeScrollNotice()
	ScrollNoticeMgr.instances[key] = nil
end

---[[
--相关的方法
--移除滚动层的方法
--]]
function ScrollNoticeMgr:PurgeScrollNotice()
    local sceneWorld = app.uiMgr:Scene()
    if self.noticeNode then
        sceneWorld:removeFromParent(self.noticeNode,true)
    end
    self.noticeNode = nil
end
--[[
--执行滚动公告的方法
--@param notice --正要执行的公告对象{title = '', descr = '', interval = 10} --类似
--]]
function ScrollNoticeMgr:StartScrollNotice(notice)
    --引导过程出不出的逻辑
    self.curNoticeObj = notice
    self:ShowNoticeUpdate()
end

--[[
--滚动条结束移动的时候
--@param noticeNode --滚动节点
--]]
function ScrollNoticeMgr:onFinishMove(noticeNode)
    noticeNode:setVisible(false)
    scheduler:performWithDelayGlobal(handler(self, self.ShowNoticeUpdate), checkint(self.curNoticeObj.interval))
end

function ScrollNoticeMgr:ShowNoticeUpdate(dt)

    if self.noticeNode then
        self.noticeNode:setVisible(false)
    end
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
end

return ScrollNoticeMgr
