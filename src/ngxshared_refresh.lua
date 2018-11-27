local util = require "util"
local dyups = require "ngx.dyups"
local parser = require "redis.parser"
local cjson = require "cjson"
local redis = require "redis_prefix"

local redis_key = ngx.var.arg_key
if redis_key == nil then
  ngx.say('{"result":"failed","message":"arg key is required!"}')
  return
end
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
        ngx.say('{"result":"success","type":"delete","message":"delete ',redis_key,' ok!"}')
      else
        dyups.update(redis_key, server_obj.server)
        ngx.shared._upstreams:set(redis_key, server_obj.server)
        ngx.log(ngx.INFO, "from redis update upstream and shared by key: ", redis_key)
        ngx.say('{"result":"success","type":"update","message":"refresh ',redis_key,' ok!", "server":"',server_obj.server,'"}')
      end
    else
      ngx.say('{"result":"failed","message":"parser redis response error,refresh ',redis_key,' failed!"}')
    end
  else
    ngx.say('{"result":"failed","message":"redis response is empty,refresh ',redis_key,' failed!"}')
  end
else
  ngx.say('{"result":"failed","message":"access redis failed,refresh ',redis_key,' failed!"}')
end