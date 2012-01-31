-- Lua Sandbox
--
-- Copyright 2012, Cameron Moy <cameronmmoy@gmail.com>
-- Released under the zlib license.
-- 
--
-- Public: Creates sandbox and runs string.
-- 
-- str - Code to execute in form of a string.
--
-- Examples
-- 
-- callSandbox('print "Hi"')
-- # => {"Hi"}
-- 
-- Returns printed values in a table.
local function callSandbox(str)
    local result = {}
    local suc
    local err

    local function copyTable(tab)
        local new = {}

        for k,v in pairs(tab) do
            new[k] = v
        end

        return new
    end

    -- load chunk
    local chunk, err = loadstring(str)

    -- construct sandbox
    local env = copyTable(_G)
    local blacklist = {'getfenv', 'setfenv', 'io', 'newproxy', 'os', 'debug', 'load', 'dofile', 'require', 'package', 'loadstring'}

    -- blacklist evil functions
    for i,v in ipairs(blacklist) do
        env[v] = nil
    end

    -- wrap tables into userdata
    for k,v in pairs(env) do
        if type(v) == 'table' then
            local wrapper = newproxy(true)
            getmetatable(wrapper).__index = copyTable(v)
            env[k] = wrapper
        end
    end

    -- special cases
    env._G = env

    env.getmetatable = function(tab)
        -- prevent altering string type metatable
        if tab ~= 'table' then
            error 'cannot alter metatable'
        else
            return getmetatable(tab)
        end
    end

    env.print = function(...)
        for i,v in ipairs({...}) do
            table.insert(result, tostring(v))
        end
    end

    -- no compliation errors
    if chunk then
        -- prevent hanging
        debug.sethook(function()
            error 'application caught hanging'
        end, '', 10000)

        -- run chunk
        suc, err = pcall(setfenv(chunk, env))

        -- clear hook
        debug.sethook()
    else
        suc, err = false, err
    end

    return not suc and {err} or (#result ~= 0 and result or {})
end
