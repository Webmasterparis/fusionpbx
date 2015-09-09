-- @usage cache = require "resources.functions.cache"
-- value = cache.get(key)
-- if not value then
--   ...
--   cache.set(key, value, expire)
-- end
--

require "resources.functions.trim";

local api = api or freeswitch.API();

local Cache = {}

local function check_error(result)
  result = trim(result or '')

  if result and result:sub(1, 4) == '-ERR' then
    return nil, trim(result:sub(5))
  end

  if result == 'INVALID COMMAND!' and not Cache.support() then
      return nil, 'INVALID COMMAND'
  end

  return result
end

function Cache.support()
  -- assume it is not unloadable
  if Cache._support then
    return true
  end
  Cache._support = (trim(api:execute('module_exists', 'mod_memcache')) == 'true')
  return Cache._support
end

--- Get element from cache
--
-- @tparam key string
-- @return[1] string value
-- @return[2] nil
-- @return[2] error string `e.g. 'NOT FOUND'
-- @note error string does not contain `-ERR` prefix
function Cache.get(key)
  local result, err = check_error(api:execute('memcache', 'get ' .. key))
  if not result then return nil, err end
  return (result:gsub("&#39;", "'"))
end

function Cache.set(key, value, expire)
  value = value:gsub("'", "&#39;"):gsub("\\", "\\\\")
  expire = expire and tostring(expire) or ""
  return check_error(api:execute("memcache", "set " .. key .. " '" .. value .. "' " .. expire))
end

function Cache.del(key)
  local result, err = check_error(api:execute("memcache", "set " .. key .. " '" .. value .. "' " .. expire))
  if not result then
    if err == 'NOT FOUND' then
      return true
    end
    return nil, err
  end
  return result == '+OK'
end

return Cache
