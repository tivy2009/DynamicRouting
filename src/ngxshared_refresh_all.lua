local util = require "util"
local dyups = require "ngx.dyups"
local parser = require "redis.parser"
local cjson = require "cjson"
local redis = require "redis_prefix"

local res_list = ngx.location.capture("/list")
if res_list.status == 200 and res_list ~= nil then
  local arr = util.split(res_list.body,"\n")
  for i, v in ipairs(arr) do
      ngx.log(ngx.INFO, "from capture loop upstream key: ", v)
      local v_index = string.find(v, redis.PREFIX)
      if v_index == 1 then 
          local key = v
          local res = ngx.location.capture("/redis", { args = { key = key } })
          if res.status == 200 then
              if (not res.body) or (string.gsub(res.body, "^%s*(.-)%s*$", "%1") == "$-1") then
                  ngx.shared._upstreams:delete(v)
                  dyups.delete(v)
              else
                  local server, typ = parser.parse_reply(res.body)
                  if typ == parser.BULK_REPLY and server ~= nil then
                    local server_obj = cjson.decode(server)
                    local share_upstream = ngx.shared._upstreams:get(v)
                    if nil ~= server_obj.server and server_obj.server ~= share_upstream then 
                      dyups.update(v, server_obj.server)
                      ngx.shared._upstreams:set(v, server_obj.server)
                      ngx.log(ngx.INFO, "from capture update upstream and shared by key: ", v)
                    end
                  else
                    ngx.shared._upstreams:delete(v)
                    dyups.delete(v)
                    ngx.log(ngx.INFO, "from capture delete upstream and shared by key: ", v)
                  end
              end
          end
      end
  end
end

local res_redis_keys = ngx.location.capture("/redis_keys", { args = { key = redis.PREFIX.."*" } })
if res_redis_keys.status == 200 then
  if nil ~= res_redis_keys and nil ~= res_redis_keys.body then 
    local redis_keys, typ = parser.parse_reply(res_redis_keys.body)
    if redis_keys ~= nil then 
      for i, redis_key in ipairs(redis_keys) do
        ngx.log(ngx.INFO, "from redis loop upstream key: ", redis_key)
        local res = ngx.location.capture("/redis", { args = { key = redis_key } })
        if res.status == 200 then
          if nil ~= res.body and string.gsub(res.body, "^%s*(.-)%s*$", "%1") ~= "$-1" then
            local server, typ2 = parser.parse_reply(res.body)
            if typ2 == parser.BULK_REPLY and server ~= nil then
              local server_obj = cjson.decode(server)
              local shared_server = ngx.shared._upstreams:get(redis_key)
              if nil == server_obj.server or "" == server_obj.server then 
                ngx.shared._upstreams:delete(redis_key)
                dyups.delete(redis_key)
                ngx.log(ngx.INFO, "from redis delete upstream and shared by key: ", redis_key)
              elseif server_obj.server ~= shared_server then
                dyups.update(redis_key, server_obj.server)
                ngx.shared._upstreams:set(redis_key, server_obj.server)
                ngx.log(ngx.INFO, "from redis update upstream and shared by key: ", redis_key)
              else
                ngx.log(ngx.INFO, "from redis no action upstream and shared by key: ", redis_key)
              end
            end
          end
        end
      end
    end
  end
end


local share_keys = ngx.shared._upstreams:get_keys(1024)
res_list = ngx.location.capture("/list")
if nil ~= share_keys and res_list.status == 200 and res_list ~= nil then
  local arr = util.split(res_list.body,"\n")
  for j, share_key in ipairs(share_keys) do
    local v_index = string.find(share_key, redis.PREFIX)
    if v_index ~= 1 then 
        ngx.shared._upstreams:delete(share_key)
    end
    local is_exist = false
    for i, v in ipairs(arr) do
      if share_key == v then 
        is_exist = true
        break
      end
    end
    if is_exist == false then 
      ngx.shared._upstreams:delete(share_key)
    end
  end
end

ngx.say("refresh ok!")