local function smart_run()
  local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
  if not client then
    vim.notify('No JDTLS client found', vim.log.levels.ERROR)
    return
  end

  local root = client.config.root_dir
  local module_info = vim.fn.glob(root .. '/src/**/module-info.java')

  if module_info ~= '' then
    -- Modular project
    local java = vim.fn.glob(vim.fn.stdpath('data') .. '/nvim-java/packages/openjdk/*/jdk-*/bin/java')
    client.request('workspace/executeCommand', { ---@diagnostic disable-line: param-type-mismatch
      command = 'vscode.java.resolveMainClass',
      arguments = { root },
    }, function(err, result) ---@diagnostic disable-line: param-type-mismatch
      if err or not result or #result == 0 then
        vim.notify('No main class found', vim.log.levels.ERROR)
        return
      end
      local choices = {}
      for _, item in ipairs(result) do
        table.insert(choices, item.mainClass)
      end
      vim.ui.select(choices, { prompt = 'Select main class:' }, function(choice)
        if not choice then return end
        vim.cmd('botright split | terminal ' .. java .. ' --module-path ' .. root .. '/bin -m ' .. choice)
      end)
    end)
  else
    -- Non-modular project
    require('java').runner.built_in.run_app({})
  end
end

local function patch_refactor()
  local action_path = vim.fn.stdpath('data') .. '/lazy/nvim-java/lua/java-refactor/action.lua'
  local ok, content = pcall(vim.fn.readfile, action_path)
  if ok then
    local patched = false
    for i, line in ipairs(content) do
      if line:find('for _, rename in ipairs%(params%)') then
        content[i] = line:gsub('ipairs%(params%)', 'ipairs(params or {})')
        patched = true
        break
      end
    end
    if patched then
      vim.fn.writefile(content, action_path)
    end
  end
end

local function patch_test()
  local test_api_path = vim.fn.stdpath('data') .. '/lazy/nvim-java/lua/java-test/api.lua'
  local ok2, content2 = pcall(vim.fn.readfile, test_api_path)
  if ok2 then
    local changed = false
    for i, line in ipairs(content2) do
      -- Fix #nil guards
      local new_line = line:gsub('if #(%w+) < 1 then', 'if not %1 or #%1 < 1 then')
      -- Fix ipairs(nil) in get_test_methods
      new_line = new_line:gsub('for (.-) in ipairs%(classes%) do', 'for %1 in ipairs(classes or {}) do')
      if new_line ~= line then
        content2[i] = new_line
        changed = true
      end
    end
    if changed then
      vim.fn.writefile(content2, test_api_path)
    end
  end
end

local function patch_report()
  local junit_path = vim.fn.stdpath('data') .. '/lazy/nvim-java/lua/java-test/reports/junit.lua'
  local ok3, content3 = pcall(vim.fn.readfile, junit_path)
  if ok3 then
    local changed = false
    for i, line in ipairs(content3) do
      if line:find('return self.result_parser:get_test_details%(%)')
          and not content3[i - 1]:find('if not self.result_parser') then
        table.insert(content3, i, '\tif not self.result_parser then return {} end')
        changed = true
        break
      end
    end
    if changed then
      vim.fn.writefile(content3, junit_path)
    end
  end
end

return {
  'nvim-java/nvim-java',
  ft = 'java',
  dependencies = {
    'neovim/nvim-lspconfig',
    'JavaHello/spring-boot.nvim',
  },
  config = function()
    patch_refactor()
    patch_test()
    patch_report()

    require('java').setup({})
    vim.lsp.config('jdtls', {
      settings = {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-25",
                path = vim.fn.expand('$HOME') .. '/.local/share/nvim/nvim-java/packages/openjdk/25/jdk-25.0.2',
                default = true,
              }
            }
          }
        }
      },
      root_dir = vim.fs.root(0, {
        '.project',
        '.classpath',
        'pom.xml',
        'build.gradle',
        'build.gradle.kts',
        'settings.gradle',
        'settings.gradle.kts',
        'mvnw',
        'gradlew',
      }),
    })
    vim.lsp.enable('jdtls')

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == 'jdtls' then
          vim.notify('[JDTLS ready]', vim.log.levels.INFO)
        end
      end,
    })
  end,
  keys = {
    -- Runner
    { '<leader>jb',  function() require('java').build.build_workspace() end,       ft = 'java',         desc = 'Build workspace' },
    { '<leader>jr',  smart_run,                                                    ft = 'java',         desc = 'Run app' },
    { '<leader>js',  function() require('java').runner.built_in.stop_app() end,    ft = 'java',         desc = 'Stop app' },
    { '<leader>jl',  function() require('java').runner.built_in.toggle_logs() end, ft = 'java',         desc = 'Toggle logs' },

    -- Tests
    { '<leader>jtc', function() require('java').test.run_current_class() end,      ft = 'java',         desc = 'Test class' },
    { '<leader>jtm', function() require('java').test.run_current_method() end,     ft = 'java',         desc = 'Test method' },
    { '<leader>jtr', function() require('java').test.view_last_report() end,       ft = 'java',         desc = 'Test report' },

    -- Debug tests via DAP-UI
    { '<leader>jtD', function() require('java').test.debug_current_class() end,    ft = 'java',         desc = 'Debug class' },
    { '<leader>jtd', function() require('java').test.debug_current_method() end,   ft = 'java',         desc = 'Debug method' },

    -- Refactor
    { '<leader>jev', function() require('java').refactor.extract_variable() end,   mode = { 'v', 'n' }, ft = 'java',             desc = 'Extract variable' },
    { '<leader>jem', function() require('java').refactor.extract_method() end,     mode = { 'v', 'n' }, ft = 'java',             desc = 'Extract method' },
    { '<leader>jec', function() require('java').refactor.extract_constant() end,   mode = { 'v', 'n' }, ft = 'java',             desc = 'Extract constant' },

    -- Misc
    {
      '<leader>jo',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.edit.organizeImports',
        }, nil, 0)
      end,
      ft = 'java',
      desc = 'Organize imports'
    },
    { '<leader>jc', function() require('java').build.clean_workspace() end,   ft = 'java', desc = 'Clean workspace' },
    { '<leader>jp', function() require('java').profile.ui() end,              ft = 'java', desc = 'Profiles' },
    { '<leader>jR', function() require('java').settings.change_runtime() end, ft = 'java', desc = 'Change JDK' },
  },
}
