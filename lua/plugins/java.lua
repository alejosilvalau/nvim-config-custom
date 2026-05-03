return {
  'nvim-java/nvim-java',
  ft = 'java',
  dependencies = {
    'neovim/nvim-lspconfig',
    'JavaHello/spring-boot.nvim',
  },
  config = function()

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
      on_attach = function(_, bufnr)
        vim.bo[bufnr].tabstop = 4
        vim.bo[bufnr].shiftwidth = 4
        vim.bo[bufnr].softtabstop = 4
        vim.bo[bufnr].expandtab = true
      end,
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

    -- vim.api.nvim_create_autocmd('BufWritePost', {
    --   pattern = { '*.java', '*.xml', '*.gradle', '*.kts', '*.properties', '*.yml', '*.yaml', '.classpath', '.project' },
    --   callback = function()
    --     -- Only restart if jdtls is actually running
    --     local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
    --     if client then
    --       client:stop()
    --     end
    --   end,
    -- })
  end,
  keys = {
    -- Runner
    { '<leader>jb',  function() require('java').build.build_workspace() end,       ft = 'java',         desc = 'Build workspace' },
    { '<leader>jr',  function() require('java').runner.built_in.run_app({}) end,   ft = 'java',         desc = 'Run app' },
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
        }, function() end, 0)
      end,
      ft = 'java',
      desc = 'Organize imports'
    },
    {
      '<leader>jD',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.project.refreshDiagnostics',
        }, function() end, 0)
      end,
      ft = 'java',
      desc = 'Refresh diagnostics'
    },
    {
      '<leader>jx',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.decompile',
          arguments = { vim.uri_from_bufnr(0) },
        }, function(err, result)
          if err or not result then
            vim.notify('Decompile failed', vim.log.levels.ERROR)
            return
          end
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, '\n'))
          vim.bo[buf].filetype = 'java'
          vim.cmd('botright split')
          vim.api.nvim_win_set_buf(0, buf)
          vim.notify('Decompiled class', vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'Decompile class'
    },
    {
      '<leader>jSa',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.project.addToSourcePath',
          arguments = { vim.uri_from_fname(vim.fn.expand('%:p:h')) },
        }, function(err)
          if err then
            vim.notify('Failed to add source path', vim.log.levels.ERROR)
            return
          end
          vim.notify('Added to source path', vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'Add to source path'
    },
    {
      '<leader>jSr',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.project.removeFromSourcePath',
          arguments = { vim.uri_from_fname(vim.fn.expand('%:p:h')) },
        }, function(err)
          if err then
            vim.notify('Failed to remove source path', vim.log.levels.ERROR)
            return
          end
          vim.notify('Removed from source path', vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'Remove from source path'
    },
    {
      '<leader>jSl',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        client.request('workspace/executeCommand', {
          command = 'java.project.listSourcePaths',
        }, function(err, result)
          if err or not result then return end
          local lines = {}
          for _, item in ipairs(result) do
            table.insert(lines, item.path or vim.inspect(item))
          end
          vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'List source paths'
    },
    {
      '<leader>jLa',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        local jar = vim.fn.input('Jar path: ', '', 'file')
        if jar == '' then return end
        client.request('workspace/executeCommand', {
          command = 'java.project.addLibraries',
          arguments = { vim.uri_from_fname(jar) },
        }, function(err)
          if err then
            vim.notify('Failed to add library', vim.log.levels.ERROR)
            return
          end
          vim.notify('Library added: ' .. jar, vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'Add library (jar)'
    },
    {
      '<leader>jLr',
      function()
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if not client then
          vim.notify('No JDTLS client found', vim.log.levels.ERROR)
          return
        end
        local jar = vim.fn.input('Jar path: ', '', 'file')
        if jar == '' then return end
        client.request('workspace/executeCommand', {
          command = 'java.project.removeLibraries',
          arguments = { vim.uri_from_fname(jar) },
        }, function(err)
          if err then
            vim.notify('Failed to remove library', vim.log.levels.ERROR)
            return
          end
          vim.notify('Library removed: ' .. jar, vim.log.levels.INFO)
        end, 0)
      end,
      ft = 'java',
      desc = 'Remove library (jar)'
    },
    { '<leader>jc', function() require('java').build.clean_workspace() end,   ft = 'java', desc = 'Clean workspace' },
    { '<leader>jp', function() require('java').profile.ui() end,              ft = 'java', desc = 'Profiles' },
    { '<leader>jR', function() require('java').settings.change_runtime() end, ft = 'java', desc = 'Change JDK' },
  },
}
