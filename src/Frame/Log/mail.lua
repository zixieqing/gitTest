local _mail = {}

local smtp = require('socket.smtp')
local log = require('Frame.Log.logger')

--[[
--@param mail mail information
--  {headers = {from= '', to = '', subject = ''}, body = {}}
--]]
function _mail.new(mail, threshold, host, port, uname, password)
    assert(type(mail) == 'table', 'mail information must provide')

    smtpImpl = smtpImpl or smtp
    local subjectPattern = mail.headers.subject
    local bodyPattern = mail.body
    
    return function (logger, level, message, exception)
        if threshold == nil or log.LEVELS[level] >= log.LEVELS[threshold] then
             mail.headers.subject = logger:Format(subjectPattern, level, message, exception, country)
             mail.body = logger:Format(bodyPattern, level, message, exception, country)
             -- Replace plain \n by \r\n to comply to RFC 822
             mail.body = string.gsub(mail.body, "(\r\n", "\n")
             mail.body = string.gsub(mail.body, "(\n", "\r\n")
             local result, err = smtpImpl.send{
                 from = mail.headers.from,
                 rcpt = mail.headers.to,
                 source = smtpImpl.message(mail),
                 server = host,
                 port = port,
                 user = uname,
                 password = password 
             }
             if (not result) then
                 print("Error: Sending of email with body '" .. tostring(mail.body) .. "' failed. Reason: " .. tostring(err))
             end
        end
    end
end
return _mail
