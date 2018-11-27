local _M = {}
local redis = require "redis_prefix"

function _M.split(str,reps)
    local resultStrList = {}
    string.gsub(str,"[^"..reps.."]+",function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

function _M.routkey()
  print("request_uri:",ngx.var.request_uri)
  local uri = ngx.var.request_uri
  local start_index  = string.find(uri,"[#?&]+")
  if start_index ~= nil then
    uri = string.sub(uri, 1, start_index -1 )
  end
  local redis_key = ngx.var.server_addr..":"..ngx.var.server_port.."/"
  if uri == "" or uri == "/" then
    return redis.PREFIX..string.gsub(redis_key, "([:/])", "-")
  else
    local arr = _M.split(uri,"/")
    if table.getn(arr) >= 1 then
      local start_index = string.find(arr[1],"[.]+")
      if start_index ~= nil then
        return redis.PREFIX..string.gsub(redis_key, "([:/])", "-")
      else
        redis_key = redis_key..arr[1]
      end
    end
  end
  return redis.PREFIX..string.gsub(redis_key, "([:/])", "-")
end

function _M.routInfoByRedis(key)
  print("routInfoByRedis key:",key)
  local res = ngx.location.capture("/redis", { args = { key = key } })

  if res.status ~= 200 then
    ngx.log(ngx.ERR, "redis server returned bad status: ", res.status)
    ngx.exit(res.status)
  end

  if (not res.body) or (string.gsub(res.body, "^%s*(.-)%s*$", "%1") == "$-1") then
    if key ~= redis.PREFIX..ngx.var.server_addr.."-"..ngx.var.server_port.."-" then
      key = redis.PREFIX..ngx.var.server_addr.."-"..ngx.var.server_port.."-"
      res = ngx.location.capture("/redis", { args = { key = key } })
      if res.status ~= 200 then
        ngx.log(ngx.ERR, "redis server returned bad status: ", res.status)
        ngx.exit(res.status)
      end
      if (not res.body) or (string.gsub(res.body, "^%s*(.-)%s*$", "%1") == "$-1") then
        ngx.log(ngx.ERR, "redis returned empty body again")
        ngx.exit(500)
      end
    else
      ngx.log(ngx.ERR, "redis returned empty body")
      ngx.exit(500)
    end
  end

  local parser = require "redis.parser"
  local server, typ = parser.parse_reply(res.body)
  if typ ~= parser.BULK_REPLY or not server then
    ngx.log(ngx.ERR, "bad redis response: ", res.body)
    ngx.exit(500)
  end

  ngx.log(ngx.INFO, "redis response: ", server)

  local cjson = require "cjson"
  local server_obj = cjson.decode(server)
  server_obj["location"] = key
  
  return server_obj
end

function _M.print_r( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

return _M