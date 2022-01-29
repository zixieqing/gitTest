local _console  = {}

function _console.new(pattern)
    return function (logger, level, message, exception)
        print(logger:Format(pattern, level, message, exception))
        -- io.stdout:write(logger:Format(pattern, level, message, exception))
    end
end

return _console
