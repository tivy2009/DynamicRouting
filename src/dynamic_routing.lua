local util = require "util"
local dyups = require "ngx.dyups"
local redis = require "redis_prefix"

local upstream_key = util.routkey()
local ups_shared = ngx.shared._upstreams:get(upstream_key);
if ups_shared ~= nil then
  ngx.var.ups = upstream_key
  print("upstream_key by shared: ",upstream_key)
  return
end

if upstream_key ~= redis.PREFIX..ngx.var.server_addr.."-"..ngx.var.server_port.."-" then
  upstream_key = redis.PREFIX..ngx.var.server_addr.."-"..ngx.var.server_port.."-"
  ups_shared = ngx.shared._upstreams:get(upstream_key);
  if ups_shared ~= nil then
    ngx.var.ups = upstream_key
    print("upstream_key by shared: ",upstream_key)
    return
  end
end

-- read upstream config from redis
local server_obj = util.routInfoByRedis(upstream_key)
upstream_key = server_obj.location
local status, rv = dyups.update(upstream_key, server_obj.server)
if status == ngx.HTTP_OK then
  ngx.var.ups = upstream_key
  print("upstream_key by redis: ",upstream_key)
  ngx.shared._upstreams:set(upstream_key, server_obj.server)
  return
else
  ngx.exit(500)
end
