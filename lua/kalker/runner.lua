local Job = require('plenary.job')
local config = require('kalker.config')
local logger = require('kalker.logger')
local list = require('kalker.utils.list')
local str = require('kalker.utils.string')

---@class Line
---@field row integer
---@field text string

---@class Output
---@field text string
---@field error boolean

---@class CalcResult
---@field line Line
---@field text string

---@class CalcError
---@field line Line
---@field text string

--- @alias ResultCallback fun (res: CalcResult): nil
--- @alias ErrorCallback fun (res: CalcError): nil
--- @alias DoneCallback fun (): nil

---@class Kalker
---@field __job Job
---@field __queue Line[]
---@field __pending Line|nil
---@field __buffer Output[]
---@field __marker string
---@field __timeout integer
---@field __timeout_timer uv_timer_t|nil
---@field __on_result_callbacks ResultCallback[]
---@field __on_error_callbacks ErrorCallback[]
---@field __on_done_callbacks DoneCallback[]
local Kalker = {}
Kalker.__index = Kalker

local function createMarker()
  local components = {}
  for _ = 1, 10, 1 do
    table.insert(components, math.floor(math.random(1000)))
  end
  return '(' .. table.concat(components, ', ') .. ')'
end

---Create a Kalker instance
---@param timeout integer Timeout in milliseconds for each calculation
function Kalker:new(timeout)
  local _self = setmetatable({
    __job = nil,
    __queue = {},
    __pending = nil,
    __buffer = {},
    __marker = createMarker(),
    __timeout = timeout,
    __timeout_timer = nil,

    __on_result_callbacks = {},
    __on_error_callbacks = {},
    __on_done_callbacks = {},
  }, self)

  _self.__job = Job:new({
    command = 'kalker',
    interactive = true,

    on_stdout = vim.schedule_wrap(function(err, data)
      logger:debug('[Kalker.__job:on_stdout]', 'data', data, 'err', err)
      if not data or data == "" then return end
      _self:__on_line(data, true)
    end),

    on_stderr = vim.schedule_wrap(function(err, data)
      logger:debug('[Kalker.__job:on_stderr]', 'data', data, 'err', err)
      if not data or data == "" then return end
      _self:__on_line(data, false)
    end),

    on_exit = function(j, code, signal)
      logger:debug('[Kalker.__job:on_exit]', 'code', code, 'signal', signal)
    end,
  })
  _self.__job:start()
  _self.__job:send('__kalker_nvim_marker = ' .. _self.__marker .. '\n')

  return _self
end

function Kalker:to_string()
  return vim.inspect({
    queue = self.__queue,
    pending = self.__pending,
    buffer = self.__buffer,
    marker = self.__marker,
  })
end

---Add a callback to be called for each line result
---@param callback ResultCallback
function Kalker:on_result(callback)
  table.insert(self.__on_result_callbacks, callback)
end

---Add a callback to be called for each error
---@param callback ErrorCallback
function Kalker:on_error(callback)
  table.insert(self.__on_error_callbacks, callback)
end

---Add a callback to be called when queue is empty
---@param callback DoneCallback
function Kalker:on_done(callback)
  table.insert(self.__on_done_callbacks, callback)
end

---@param result CalcResult
function Kalker:__emit_result(result)
  for _, cb in ipairs(self.__on_result_callbacks) do
    cb(result)
  end
end

---@param error CalcError
function Kalker:__emit_error(error)
  for _, cb in ipairs(self.__on_error_callbacks) do
    cb(error)
  end
end

function Kalker:__emit_done()
  for _, cb in ipairs(self.__on_done_callbacks) do
    cb()
  end
end

function Kalker:__start_timeout_timer()
  self:__stop_timeout_timer()
  self.__timeout_timer = vim.defer_fn(function()
    self:__handle_timeout()
  end, self.__timeout)
end

function Kalker:__stop_timeout_timer()
  if self.__timeout_timer then
    self.__timeout_timer:stop()
    self.__timeout_timer = nil
  end
end

function Kalker:__handle_timeout()
  logger:debug('[Kalker:__handle_timeout]', 'state', self:to_string())

  self:__emit_error({ line = self.__pending, text = "Calculation timed out" })

  for _, line in ipairs(self.__queue) do
    self:__emit_error({ line = line, text = "Skipped (previous calculation timed out)" })
  end

  self.__queue = {}
  self.__pending = nil
  self:__emit_done()
end

---@param lines Line[]
function Kalker:process_lines(lines)
  self.__queue = vim.deepcopy(lines)
  self:__send_next()
end

---@param line string
---@return boolean
function Kalker:__is_marker(line)
  return str.endswith(line, self.__marker)
end

function Kalker:__complete_pending()
  logger:debug('[Kalker:__complete_pending]', 'state', self:to_string())

  self:__stop_timeout_timer()
  self.__marker = createMarker()

  for _, out in ipairs(self.__buffer) do
    if out.error then
      self:__emit_error({ line = self.__pending, text = out.text })
    else
      self:__emit_result({ line = self.__pending, text = out.text })
    end
  end

  self.__pending = nil

  self:__send_next()
end

---Process any output from the kalker process
---@param data string
---@param stdout boolean Is from stdout, as apposed to stderr
function Kalker:__on_line(data, stdout)
  if self.__pending == nil then return end

  local line = data:gsub("%s+$", "")

  logger:debug('[Kalker:__on_line]', 'line', line, 'state', self:to_string())

  if stdout and self:__is_marker(line) then
    self:__complete_pending()
    return
  end

  if not self:__is_marker(line) then
    table.insert(self.__buffer, { text = line, error = not stdout })
  end

  logger:debug('[Kalker:__on_line] got unexpected line', 'line', line, 'state', self:to_string())
end

function Kalker:__send_next()
  if #self.__queue == 0 then return self:__emit_done() end
  if self.__pending then return end

  self.__pending = table.remove(self.__queue, 1)
  self.__buffer = {}

  logger:debug('[Kalker:__send_next]', 'state', self:to_string())

  self:__start_timeout_timer()
  self.__job:send(self.__pending.text .. '\n')
  self.__job:send('__kalker_nvim_marker = ' .. self.__marker .. '\n')
  self.__job:send("__kalker_nvim_marker\n")
end

function Kalker:done()
  logger:debug('[Kalker:done] stopping kalker')
  self:__stop_timeout_timer()
  self.__job:shutdown()
end

return Kalker
