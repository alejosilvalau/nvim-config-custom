return {
  'rcarriga/nvim-dap-ui',
  dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
  config = function()
    local dap, dapui = require('dap'), require('dapui')

    dapui.setup()

    -- Signs
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition',
      { text = '◆', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected',
      { text = '●', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStopped', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◉', texthl = 'DapLogPoint', linehl = '', numhl = '' })

    -- Colors
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#f5a623' })
    vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#6c6c6c' })
    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379' })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef' })

    dap.listeners.before.attach.dapui_config           = function() dapui.open() end
    dap.listeners.before.launch.dapui_config           = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end
  end,
  keys = {
    { '<leader>du', function() require('dapui').toggle() end,                                       desc = 'Toggle DAP UI' },
    { '<leader>de', function() require('dapui').eval() end,                                         desc = 'Eval expression',       mode = { 'n', 'v' } },
    { '<leader>df', function() require('dapui').float_element('scopes', { enter = true }) end,      desc = 'Float scopes' },
    { '<leader>dk', function() require('dapui').float_element('stacks', { enter = true }) end,      desc = 'Float stacks' },
    { '<leader>dw', function() require('dapui').float_element('watches', { enter = true }) end,     desc = 'Float watches' },
    { '<leader>dp', function() require('dapui').float_element('breakpoints', { enter = true }) end, desc = 'Float breakpoints' },
    -- DAP control (lives here since it's tightly coupled to the UI workflow)
    { '<leader>dc', function() require('dap').continue() end,                                       desc = 'Continue' },
    { '<leader>ds', function() require('dap').terminate() end,                                      desc = 'Stop session' },
    { '<leader>dr', function() require('dap').restart() end,                                        desc = 'Restart' },
    { '<leader>db', function() require('dap').toggle_breakpoint() end,                              desc = 'Toggle breakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end,      desc = 'Conditional breakpoint' },
    { '<leader>dn', function() require('dap').step_over() end,                                      desc = 'Step over' },
    { '<leader>di', function() require('dap').step_into() end,                                      desc = 'Step into' },
    { '<leader>do', function() require('dap').step_out() end,                                       desc = 'Step out' },
  },
}
