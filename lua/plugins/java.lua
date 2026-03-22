local function eclipse_run()
  local function resolve_java(client, project_dir)
    local runtimes = vim.tbl_get(
      client, 'config', 'settings', 'java', 'configuration', 'runtimes'
    ) or {}

    local required_version = nil
    local classpath_file = project_dir .. '/.classpath'
    if vim.fn.filereadable(classpath_file) == 1 then
      local content = table.concat(vim.fn.readfile(classpath_file), '\n')
      required_version = content:match('JRE_CONTAINER/[^/]*/([^"]+)"')
    end

    if required_version then
      for _, runtime in ipairs(runtimes) do
        if runtime.name == required_version then
          local java = runtime.path .. '/bin/java'
          if vim.fn.filereadable(java) == 1 then
            return java, runtime.name
          end
        end
      end
      vim.notify(
        'No runtime for ' .. required_version .. ', falling back to default',
        vim.log.levels.WARN
      )
    end

    for _, runtime in ipairs(runtimes) do
      if runtime.default then
        local java = runtime.path .. '/bin/java'
        if vim.fn.filereadable(java) == 1 then return java, runtime.name end
      end
    end

    local java_home = vim.fn.getenv('JAVA_HOME')
    if java_home and java_home ~= vim.NIL and java_home ~= '' then
      local java = java_home .. '/bin/java'
      if vim.fn.filereadable(java) == 1 then return java, 'JAVA_HOME' end
    end

    local sys = vim.fn.exepath('java')
    if sys ~= '' then return sys, 'system' end
    return nil, nil
  end

  local function resolve_user_libraries(workspace, lib_names)
    local jars = {}
    local ul_file = workspace
        .. '/.metadata/.plugins/org.eclipse.jdt.core/UserLibraries.xml'
    if vim.fn.filereadable(ul_file) == 0 then return jars end

    local content = table.concat(vim.fn.readfile(ul_file), '\n')
    for _, name in ipairs(lib_names) do
      local lib_block = content:match(
        '<library name="' .. vim.pesc(name) .. '"(.-)</library>'
      )
      if lib_block then
        for archive in lib_block:gmatch('<archive path="([^"]+)"') do
          if vim.fn.filereadable(archive) == 1 then
            table.insert(jars, archive)
          end
        end
      end
    end
    return jars
  end

  local function parse_classpath(project_dir)
    local path = project_dir .. '/.classpath'
    if vim.fn.filereadable(path) == 0 then return nil end

    local result = { output = 'bin', jars = {}, user_libraries = {} }
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
      elseif kind == 'con' then
        local ul_name = path_val:match('USER_LIBRARY/(.+)')
        if ul_name then
          table.insert(result.user_libraries, ul_name)
        end
      end

      ::continue::
    end

    return result
  end

  local function check_stale(project_dir, cp_data)
    local out_dir = project_dir .. '/' .. cp_data.output
    local src_files = vim.fn.glob(project_dir .. '/src/**/*.java', false, true)
    local cls_files = vim.fn.glob(out_dir .. '/**/*.class', false, true)

    if #cls_files == 0 then
      return false, 'No .class files found — build in Eclipse first (Ctrl+B)'
    end

    local newest_src, newest_cls = 0, 0
    for _, f in ipairs(src_files) do
      local t = vim.fn.getftime(f)
      if t > newest_src then newest_src = t end
    end
    for _, f in ipairs(cls_files) do
      local t = vim.fn.getftime(f)
      if t > newest_cls then newest_cls = t end
    end

    if newest_src > newest_cls then
      return false, 'Source modified after last build — rebuild in Eclipse (Ctrl+B)'
    end

    return true, nil
  end

  local function parse_launch(launch_path)
    local content = table.concat(vim.fn.readfile(launch_path), '\n')
    return {
      main_class   = content:match('MAIN_TYPE.-value="([^"]+)"'),
      project      = content:match('PROJECT_ATTR.-value="([^"]+)"'),
      jvm_args     = content:match('VM_ARGUMENTS.-value="([^"]+)"') or '',
      program_args = content:match('PROGRAM_ARGUMENTS.-value="([^"]+)"') or '',
    }
  end

  local function find_workspace(start)
    local dir = start
    for _ = 1, 6 do
      if vim.fn.isdirectory(dir .. '/.metadata') == 1 then return dir end
      local parent = vim.fn.fnamemodify(dir, ':h')
      if parent == dir then break end
      dir = parent
    end
    return nil
  end

  local function find_project_dir(workspace, project_name)
    local direct = workspace .. '/' .. project_name
    if vim.fn.isdirectory(direct) == 1 then return direct end

    local dotprojects = vim.fn.glob(workspace .. '/**/.project', false, true)
    for _, dp in ipairs(dotprojects) do
      local dir = vim.fn.fnamemodify(dp, ':h')
      if vim.fn.fnamemodify(dir, ':t') == project_name then return dir end
      local pcontent = table.concat(vim.fn.readfile(dp), '\n')
      local pname = pcontent:match('<name>([^<]+)</name>')
      if pname == project_name then return dir end
    end

    return nil
  end

  local function collect_launch_files(workspace, project_dirs)
    local files        = {}
    local seen         = {}

    local metadata_dir = workspace
        .. '/.metadata/.plugins/org.eclipse.debug.core/.launches'
    for _, f in ipairs(vim.fn.glob(metadata_dir .. '/*.launch', false, true)) do
      if not seen[f] then
        seen[f] = true; table.insert(files, f)
      end
    end

    for _, dir in ipairs(project_dirs) do
      for _, f in ipairs(vim.fn.glob(dir .. '/*.launch', false, true)) do
        if not seen[f] then
          seen[f] = true; table.insert(files, f)
        end
      end
    end

    return files
  end

  local function open_terminal(cmd)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.b[buf].eclipse_run_terminal then
        vim.api.nvim_buf_delete(buf, { force = true })
        break
      end
    end

    -- Create a new empty buffer for the terminal
    local term_buf = vim.api.nvim_create_buf(false, true)
    vim.b[term_buf].eclipse_run_terminal = true

    -- Open a new window at the very bottom with fixed height
    vim.api.nvim_open_win(term_buf, true, {
      split = 'below',
      win = 0,
      height = 15,
    })

    vim.fn.jobstart(cmd, {
      term = true,
      on_exit = function(_, exit_code)
        vim.schedule(function()
          if exit_code == 0 then
            vim.notify('Program exited successfully', vim.log.levels.INFO)
          else
            vim.notify('Program exited with code ' .. exit_code, vim.log.levels.WARN)
          end
        end)
      end,
    })

    vim.cmd('startinsert')
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- MAIN
  -- ═══════════════════════════════════════════════════════════════════════════

  local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
  if not client then
    vim.notify('No JDTLS client found', vim.log.levels.ERROR)
    return
  end

  local project_root = client.config.root_dir

  -- Delegate Maven/Gradle
  if vim.fn.filereadable(project_root .. '/pom.xml') == 1
      or vim.fn.filereadable(project_root .. '/build.gradle') == 1
      or vim.fn.filereadable(project_root .. '/build.gradle.kts') == 1 then
    require('java').runner.built_in.run_app({})
    return
  end

  local workspace = find_workspace(project_root)
  if not workspace then
    vim.notify('Eclipse workspace not found (.metadata missing)', vim.log.levels.ERROR)
    return
  end

  -- Collect all project dirs in workspace (for shared launch file scanning)
  local all_project_dirs = {}
  for _, dp in ipairs(vim.fn.glob(workspace .. '/**/.project', false, true)) do
    table.insert(all_project_dirs, vim.fn.fnamemodify(dp, ':h'))
  end

  local launch_files = collect_launch_files(workspace, all_project_dirs)
  if #launch_files == 0 then
    vim.notify('No .launch files found — run the project in Eclipse first', vim.log.levels.ERROR)
    return
  end

  local current_project = vim.fn.fnamemodify(project_root, ':t')
  local choices = {}

  for _, lf in ipairs(launch_files) do
    local parsed = parse_launch(lf)
    if parsed.main_class and parsed.project then
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

    local project_dir = find_project_dir(workspace, selected.project)
    if not project_dir then
      vim.notify('Project directory not found: ' .. selected.project, vim.log.levels.ERROR)
      return
    end

    local java, java_version = resolve_java(client, project_dir)
    if not java then
      vim.notify('No java binary found', vim.log.levels.ERROR)
      return
    end
    vim.notify('Using ' .. java_version, vim.log.levels.INFO)

    local cp_data = parse_classpath(project_dir)
    if not cp_data then
      vim.notify('No .classpath found in ' .. project_dir, vim.log.levels.ERROR)
      return
    end

    -- Resolve user libraries
    local ul_jars = resolve_user_libraries(workspace, cp_data.user_libraries)
    vim.list_extend(cp_data.jars, ul_jars)

    -- Stale build check
    local ok, stale_msg = check_stale(project_dir, cp_data)
    if not ok then
      vim.notify(stale_msg, vim.log.levels.WARN)
      -- Warn but don't block — user may know what they're doing
    end

    local sep        = package.config:sub(1, 1) == '\\' and ';' or ':'
    local out_dir    = project_dir .. '/' .. cp_data.output
    local cp_entries = { out_dir }
    vim.list_extend(cp_entries, cp_data.jars)

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

    open_terminal(cmd)
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
