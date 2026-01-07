local a = require('plenary.async')
local config = require('kalker.config')
local logger = require('kalker.logger')
local list = require('kalker.utils.list')
local str = require('kalker.utils.string')
local debounce = require('kalker.utils.debounce')
local Kalker = require('kalker.runner')

local M = {
  __ns_id = vim.api.nvim_create_namespace('kalker.nvim'),
}

---@param opts? KalkerOptions
function M.setup(opts)
  config.apply(opts)
  logger:init(config)

  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*.kalker',
    callback = function(ev)
      local run = debounce(function(bufnr)
        M.run(bufnr)
      end, config.debounce)

      vim.api.nvim_create_autocmd(
        { 'InsertLeave', 'TextChanged', 'TextChangedT' },
        {
          buffer = ev.buf,
          callback = function()
            M.clear(ev.buf)
            run(ev.buf)
          end
        })

      M.run(ev.buf)
    end
  })
end

---@param bufnr integer
function M.run(bufnr)
  logger:debug('[kalker.nvim](run)', 'bufnr', bufnr)
  a.void(function()
    M.__calculate(bufnr)
  end)()
end

---@param bufnr integer
function M.__calculate(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local kalker = Kalker:new(config.calculations.timeout)
  logger:debug('[kalker.nvim](__calculate)', 'stating kalker', kalker)

  local diagnostics = {}

  kalker:on_result(function(result)
    if result.text == nil or result.text == '' then return end

    logger:debug('[kalker.nvim](__calculate -> on_result) adding extmark', 'result', result)
    vim.api.nvim_buf_set_extmark(bufnr, M.__ns_id, result.line.row - 1, 0, {
      virt_text = { { result.text, 'Comment' } },
    })
  end)
  kalker:on_diagnostic(function(diagnostic)
    logger:debug('[kalker.nvim](__calculate -> on_diagnostic) adding diagnostic', 'diagnostic', diagnostic)
    table.insert(diagnostics, {
      lnum = diagnostic.line.row - 1,
      col = 0,
      end_lnum = diagnostic.line.row - 1,
      end_col = #diagnostic.line.text - 1,
      severity = diagnostic.severity,
      message = diagnostic.text,
      source = "kalker.nvim",
    })
  end)
  kalker:on_done(function()
    vim.diagnostic.set(M.__ns_id, bufnr, diagnostics, {
      virtual_text = true,
      underline = true,
      signs = true,
    })
    kalker:done()
  end)

  lines = vim.tbl_filter(
    function(line)
      return #line.text > 0 and not str.startswith(line.text, '--')
    end,
    list.map(lines, function(text, row)
      return { row = row, text = text }
    end)
  )
  logger:debug('[kalker.nvim](__calculate)', 'lines', lines)

  kalker:process_lines(lines)
end

---@param bufnr integer
function M.clear(bufnr)
  logger:debug('[kalker.nvim](clear_results)', 'bufnr', bufnr)

  local marks = vim.api.nvim_buf_get_extmarks(bufnr, M.__ns_id, 0, -1, {})
  for _, mark in pairs(marks) do
    vim.api.nvim_buf_del_extmark(bufnr, M.__ns_id, mark[1])
  end

  vim.diagnostic.reset(M.__ns_id, bufnr)
end

return M
