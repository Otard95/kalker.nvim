---@param fn function
---@param ms number
---@return function
local function debounce(fn, ms)
  local timer ---@type uv_timer_t|nil

  return function(...)
    local args = { ... }

    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end

    timer = vim.uv.new_timer()
    timer:start(ms, 0, vim.schedule_wrap(function()
      timer:stop()
      timer:close()
      timer = nil
      fn(unpack(args))
    end))
  end
end

return debounce
