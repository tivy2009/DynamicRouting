local delayInSeconds = 5  
local refreshSharedLocation = nil  
  
refreshSharedLocation = function(args)  
   ngx.log(ngx.INFO, "refreshSharedLocation......")  
   
   local ok, err = ngx.timer.at(delayInSeconds, refreshSharedLocation)
  
   if not ok then  
      ngx.log(ngx.ERR, "failed to startup refreshSharedLocation worker...", err)  
   end  
   
   os.execute("sh ../lua/_refresh_all.sh")
   
   --local shell = require "routing.shell"
   --local args = {};
   --local status, out, err = shell.execute("sh ../lualib/routing/_refresh.sh", args)
   --print("out:",out)
   
   -- local fp = io.popen("sh ../lualib/routing/_refresh.sh")
   -- local fp = io.popen("sh PWD")
   -- local a = ret:read("*all")
   -- print("--------------", a)
   -- fp:close()
   
end  
  
refreshSharedLocation()