local function eclipse_run()
  -- ── Resolve java binary ───────────────────────────────────────────────────
  local function resolve_java()
    local managed = vim.fn.glob(
      vim.fn.stdpath('data') .. '/nvim-java/packages/openjdk/*/jdk-*/bin/java'
    )
    if managed ~= '' then return managed end

    local java_home = vim.fn.getenv('JAVA_HOME')
    if java_home and java_home ~= vim.NIL and java_home ~= '' then
      local jh = java_home .. '/bin/java'
      if vim.fn.filereadable(jh) == 1 then return jh end
    end

    local sys = vim.fn.exepath('java')
    if sys ~= '' then return sys end

    return nil
  end

  -- ── Parse .classpath ──────────────────────────────────────────────────────
  local function parse_classpath(project_dir)
    local path = project_dir .. '/.classpath'
    if vim.fn.filereadable(path) == 0 then return nil end

    local result  = { output = 'bin', jars = {} }
    local content = table.concat(vim.fn.readfile(path), '\n')

    for entry in content:gmatch('<classpathentry(.-)/>') do
      local kind     = entry:match('kind="([^"]+)"')
      local path_val = entry:match('path="([^"]+)"')
      if not kind or not path_val then goto continue end

      if kind == 'output' then
        result.output = path_val
      elseif kind == 'lib' then
        local full = path_val:sub(1, 1) == '/'
            and path_val
            or project_dir .. '/' .. path_val
        if vim.fn.filereadable(full) == 1 then
          table.insert(result.jars, full)
        else
          vim.notify('Jar not found: ' .. full, vim.log.levels.WARN)
        end
      end

      ::continue::
    end

    return result
  end

  -- ── Parse .launch file ────────────────────────────────────────────────────
  local function parse_launch(launch_path)
    local content = table.concat(vim.fn.readfile(launch_path), '\n')
    return {
      main_class   = content:match('MAIN_TYPE.-value="([^"]+)"'),
      project      = content:match('PROJECT_ATTR.-value="([^"]+)"'),
      jvm_args     = content:match('VM_ARGUMENTS.-value="([^"]+)"') or '',
      program_args = content:match('PROGRAM_ARGUMENTS.-value="([^"]+)"') or '',
    }
  end

  -- ── Find workspace root (dir containing .metadata/) ──────────────────────
  local function find_workspace(start)
    local dir = start
    for _ = 1, 6 do
      if vim.fn.isdirectory(dir .. '/.metadata') == 1 then
        return dir
      end
      local parent = vim.fn.fnamemodify(dir, ':h')
      if parent == dir then break end -- reached fs root
      dir = parent
    end
    return nil
  end

  -- ── Find project dir by name inside workspace ─────────────────────────────
  -- Handles: workspace/ProjectName and workspace/subdir/ProjectName
  local function find_project_dir(workspace, project_name)
    local direct = workspace .. '/' .. project_name
    if vim.fn.isdirectory(direct) == 1 then return direct end

    local nested = vim.fn.glob(workspace .. '/*/' .. project_name, false, true)
    if #nested > 0 then return nested[1] end

    return nil
  end

  -- ═════════════════════════════════════════════════════════════════════════
  -- MAIN LOGIC
  -- ═════════════════════════════════════════════════════════════════════════

  local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
  if not client then
    vim.notify('No JDTLS client found', vim.log.levels.ERROR)
    return
  end

  local project_root = client.config.root_dir

  -- ── Delegate Maven/Gradle to run_app ─────────────────────────────────────
  local has_maven    = vim.fn.filereadable(project_root .. '/pom.xml') == 1
  local has_gradle   = vim.fn.filereadable(project_root .. '/build.gradle') == 1
      or vim.fn.filereadable(project_root .. '/build.gradle.kts') == 1

  if has_maven or has_gradle then
    require('java').runner.built_in.run_app({})
    return
  end
  -- ── Eclipse path ──────────────────────────────────────────────────────────
  local java = resolve_java()
  if not java then
    vim.notify('No java binary found', vim.log.levels.ERROR)
    return
  end

  local workspace = find_workspace(project_root)
  if not workspace then
    vim.notify('Eclipse workspace not found (.metadata missing)', vim.log.levels.ERROR)
    return
  end

  local launches_dir = workspace
      .. '/.metadata/.plugins/org.eclipse.debug.core/.launches'

  local launch_files = vim.fn.glob(launches_dir .. '/*.launch', false, true)
  if #launch_files == 0 then
    vim.notify('No .launch files found in workspace', vim.log.levels.ERROR)
    return
  end

  -- ── Filter launches relevant to the current project ───────────────────────
  -- project_root basename = project name Eclipse knows
  local current_project = vim.fn.fnamemodify(project_root, ':t')

  local choices = {}
  for _, lf in ipairs(launch_files) do
    local parsed = parse_launch(lf)
    if parsed.main_class and parsed.project then
      -- Show all launches but mark current project ones first
      table.insert(choices, {
        label        = parsed.project .. '  →  ' .. parsed.main_class,
        main_class   = parsed.main_class,
        project      = parsed.project,
        jvm_args     = parsed.jvm_args,
        program_args = parsed.program_args,
        current      = parsed.project == current_project,
      })
    end
  end

  -- Sort: current project first, then alphabetically
  table.sort(choices, function(a, b)
    if a.current ~= b.current then return a.current end
    return a.label < b.label
  end)

  if #choices == 0 then
    vim.notify('No valid launch configurations found', vim.log.levels.ERROR)
    return
  end

  local labels = vim.tbl_map(function(c) return c.label end, choices)

  vim.ui.select(labels, { prompt = 'Select launch configuration:' }, function(choice)
    if not choice then return end

    local selected
    for _, c in ipairs(choices) do
      if c.label == choice then
        selected = c; break
      end
    end

    -- Resolve project directory
    local project_dir = find_project_dir(workspace, selected.project)
    if not project_dir then
      vim.notify('Project directory not found: ' .. selected.project, vim.log.levels.ERROR)
      return
    end

    -- Parse classpath
    local cp_data = parse_classpath(project_dir)
    if not cp_data then
      vim.notify('No .classpath found in ' .. project_dir, vim.log.levels.ERROR)
      return
    end

    -- Guard: check compiled classes exist
    local out_dir = project_dir .. '/' .. cp_data.output
    if #vim.fn.glob(out_dir .. '/**/*.class', false, true) == 0 then
      vim.notify(
        'No .class files in ' .. out_dir .. ' — build in Eclipse first (Ctrl+B)',
        vim.log.levels.WARN
      )
      return
    end

    -- Assemble classpath string
    local sep = package.config:sub(1, 1) == '\\' and ';' or ':'
    local cp_entries = { out_dir }
    for _, jar in ipairs(cp_data.jars) do
      table.insert(cp_entries, jar)
    end

    -- Assemble full command
    local parts = {
      vim.fn.shellescape(java),
      '-cp', vim.fn.shellescape(table.concat(cp_entries, sep)),
    }

    if selected.jvm_args ~= '' then
      table.insert(parts, selected.jvm_args)
    end

    table.insert(parts, selected.main_class)

    if selected.program_args ~= '' then
      table.insert(parts, selected.program_args)
    end

    local cmd = 'cd ' .. vim.fn.shellescape(project_dir)
        .. ' && ' .. table.concat(parts, ' ')

    vim.cmd('botright split | terminal ' .. cmd)
  end)
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

local function patch_imports()
  local action_path = vim.fn.stdpath('data') .. '/lazy/nvim-java/lua/java-refactor/action.lua'
  local ok, content = pcall(vim.fn.readfile, action_path)
  if not ok then return end
  local changed = false
  for i, line in ipairs(content) do
    if line:find('for _, selection in ipairs%(selections%)') and not line:find('or {}') then
      content[i] = line:gsub('ipairs%(selections%)', 'ipairs(selections or {})')
      changed = true
      break
    end
  end
  if changed then
    vim.fn.writefile(content, action_path)
  end

  local handler_path = vim.fn.stdpath('data') .. '/lazy/nvim-java/lua/java-refactor/client-command-handlers.lua'
  local ok2, content2 = pcall(vim.fn.readfile, handler_path)
  if not ok2 then return end
  local changed2 = false
  for i, line in ipairs(content2) do
    if line:find('local selections = params%[2%]') then
      if not content2[i + 1]:find('if not selections') then
        table.insert(content2, i + 1, '\t\tif not selections or #selections == 0 then return {} end')
        changed2 = true
      end
      break
    end
  end
  if changed2 then
    vim.fn.writefile(content2, handler_path)
  end
end

return {
  'nvim-java/nvim-java',
  commit = '602a5f7',
  ft = 'java',
  dependencies = {
    'neovim/nvim-lspconfig',
    'JavaHello/spring-boot.nvim',
  },
  config = function()
    patch_refactor()
    patch_test()
    patch_report()
    patch_imports()

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

    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = { '*.java', '*.xml', '*.gradle', '*.kts', '*.properties', '*.yml', '*.yaml', '.classpath', '.project' },
      callback = function()
        -- Only restart if jdtls is actually running
        local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
        if client then
          vim.cmd('LspRestart jdtls')
        end
      end,
    })
  end,
  keys = {
    -- Runner
    { '<leader>jb',  function() require('java').build.build_workspace() end,       ft = 'java',         desc = 'Build workspace' },
    { '<leader>jr',  eclipse_run,                                                  ft = 'java',         desc = 'Run app' },
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
