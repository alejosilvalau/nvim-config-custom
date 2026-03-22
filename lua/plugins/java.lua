local function eclipse_run()
  -- ═══════════════════════════════════════════════════════════════════════════
  -- XML HELPERS
  -- ═══════════════════════════════════════════════════════════════════════════

  local xml = {}

  -- Decode the five predefined XML entities
  function xml.decode_entities(s)
    return (s
      :gsub('&amp;', '&')
      :gsub('&lt;', '<')
      :gsub('&gt;', '>')
      :gsub('&quot;', '"')
      :gsub('&apos;', "'"))
  end

  -- Return the value of a named attribute from a tag string (handles any attr order,
  -- single/double quotes, and entity-encoded values).
  function xml.attr(tag, name)
    local v = tag:match(name .. '%s*=%s*"([^"]*)"')
        or tag:match(name .. "%s*=%s*'([^']*)'")
    return v and xml.decode_entities(v) or nil
  end

  -- Flatten a multi-line XML file into a single line so that cross-line patterns work.
  function xml.flatten(lines)
    return table.concat(lines, ' '):gsub('%s+', ' ')
  end

  -- Iterate over every self-closing or paired tag whose name matches `tag_name`.
  -- Yields the full inner content string for paired tags, or the attribute string
  -- for self-closing ones.
  function xml.each_tag(flat, tag_name)
    local i = 1
    return function()
      while i <= #flat do
        -- self-closing  <tag_name ... />
        local s, e, inner = flat:find('<' .. tag_name .. '(%s[^>]*/?>)', i)
        -- paired  <tag_name ...>...</tag_name>
        local s2, e2, inner2 = flat:find(
          '<' .. tag_name .. '(.-)' .. '</' .. tag_name .. '>', i)

        if not s and not s2 then return nil end

        if s and (not s2 or s < s2) then
          i = e + 1
          return inner
        else
          i = e2 + 1
          return inner2
        end
      end
    end
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- SHELL-ARG SPLITTING
  -- ═══════════════════════════════════════════════════════════════════════════

  -- Split a shell-like argument string into a table of tokens,
  -- respecting single quotes, double quotes, and backslash escapes.
  local function split_args(s)
    local args = {}
    local i = 1
    local len = #s
    while i <= len do
      -- skip whitespace
      while i <= len and s:sub(i, i):match('%s') do i = i + 1 end
      if i > len then break end

      local token = ''
      local c = s:sub(i, i)

      if c == "'" then
        -- single-quoted: no escapes inside
        i = i + 1
        local j = s:find("'", i, true)
        if not j then j = len + 1 end
        token = s:sub(i, j - 1)
        i = j + 1
      elseif c == '"' then
        -- double-quoted: backslash escapes only for \\ and \"
        i = i + 1
        while i <= len and s:sub(i, i) ~= '"' do
          if s:sub(i, i) == '\\' and i < len then
            local next = s:sub(i + 1, i + 1)
            token = token .. ((next == '"' or next == '\\') and next or ('\\' .. next))
            i = i + 2
          else
            token = token .. s:sub(i, i)
            i = i + 1
          end
        end
        i = i + 1 -- skip closing "
      else
        -- unquoted token
        while i <= len and not s:sub(i, i):match('%s') do
          if s:sub(i, i) == '\\' and i < len then
            token = token .. s:sub(i + 1, i + 1)
            i = i + 2
          else
            token = token .. s:sub(i, i)
            i = i + 1
          end
        end
      end

      if token ~= '' then
        table.insert(args, token)
      end
    end
    return args
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- JAVA RESOLUTION
  -- ═══════════════════════════════════════════════════════════════════════════

  local function resolve_java(client, project_dir)
    local runtimes = vim.tbl_get(
      client, 'config', 'settings', 'java', 'configuration', 'runtimes'
    ) or {}

    local required_version = nil
    local classpath_file = project_dir .. '/.classpath'
    if vim.fn.filereadable(classpath_file) == 1 then
      local flat = xml.flatten(vim.fn.readfile(classpath_file))
      -- Match JRE_CONTAINER entries for required version
      for entry in xml.each_tag(flat, 'classpathentry') do
        local kind = xml.attr(entry, 'kind')
        local path = xml.attr(entry, 'path')
        if kind == 'con' and path then
          required_version = path:match('JRE_CONTAINER/[^/]*/([^/"]+)')
          if required_version then break end
        end
      end
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

  -- ═══════════════════════════════════════════════════════════════════════════
  -- USER LIBRARIES
  -- ═══════════════════════════════════════════════════════════════════════════

  local function resolve_user_libraries(workspace, lib_names)
    local jars = {}
    local ul_file = workspace
        .. '/.metadata/.plugins/org.eclipse.jdt.core/UserLibraries.xml'
    if vim.fn.filereadable(ul_file) == 0 then return jars end

    local flat = xml.flatten(vim.fn.readfile(ul_file))

    for _, name in ipairs(lib_names) do
      -- Find the <library name="..."> block using the xml helper
      for lib_block in xml.each_tag(flat, 'library') do
        local lib_name = xml.attr(lib_block, 'name')
        if lib_name == name then
          for archive_tag in xml.each_tag(lib_block, 'archive') do
            local path = xml.attr(archive_tag, 'path')
            if path and vim.fn.filereadable(path) == 1 then
              table.insert(jars, path)
            end
          end
        end
      end
    end
    return jars
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- LINKED RESOURCES
  -- ═══════════════════════════════════════════════════════════════════════════

  -- Returns a table mapping virtual name → real path for all linked resources.
  local function resolve_linked_resources(project_dir)
    local links = {}
    local dot_project = project_dir .. '/.project'
    if vim.fn.filereadable(dot_project) == 0 then return links end

    local flat = xml.flatten(vim.fn.readfile(dot_project))

    for link_block in xml.each_tag(flat, 'link') do
      local vname    = xml.attr(link_block, 'name')
      local loc      = xml.attr(link_block, 'location')
      local loc_uri  = xml.attr(link_block, 'locationURI')

      local resolved = loc or loc_uri
      if resolved and vname then
        -- locationURI may use Eclipse path variables like PROJECT_LOC or PARENT-1-PROJECT_LOC
        resolved = resolved
            :gsub('PROJECT_LOC', project_dir)
            :gsub('PARENT%-(%d+)%-PROJECT_LOC', function(n)
              local dir = project_dir
              for _ = 1, tonumber(n) do
                dir = vim.fn.fnamemodify(dir, ':h')
              end
              return dir
            end)
        links[vname] = resolved
      end
    end
    return links
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- CLASSPATH PARSING
  -- ═══════════════════════════════════════════════════════════════════════════

  local function parse_classpath(project_dir)
    local path = project_dir .. '/.classpath'
    if vim.fn.filereadable(path) == 0 then return nil end

    local result = {
      output         = 'bin',
      jars           = {},
      user_libraries = {},
      module_path    = {}, -- jars that belong on --module-path
      is_modular     = false,
    }

    local flat   = xml.flatten(vim.fn.readfile(path))
    local linked = resolve_linked_resources(project_dir)

    -- Detect module-info.java anywhere under src/
    if #vim.fn.glob(project_dir .. '/src/**/module-info.java', false, true) > 0
        or vim.fn.filereadable(project_dir .. '/src/module-info.java') == 1 then
      result.is_modular = true
    end

    -- Resolve Eclipse path variables (e.g. CLASSPATH_VAR/foo → real path)
    local function resolve_variable(path_val)
      -- Try Eclipse variable substitution from jdtls settings if available
      -- Common variables: M2_REPO, GRADLE_USER_HOME, etc.
      local var_name, rest = path_val:match('^([^/]+)/(.+)$')
      if not var_name then return nil end

      -- Check environment variables
      local env_val = vim.fn.getenv(var_name)
      if env_val and env_val ~= vim.NIL and env_val ~= '' then
        return env_val .. '/' .. rest
      end

      -- Fallback: warn
      vim.notify(
        'Unresolved classpath variable: ' .. path_val,
        vim.log.levels.WARN
      )
      return nil
    end

    for entry in xml.each_tag(flat, 'classpathentry') do
      local kind     = xml.attr(entry, 'kind')
      local path_val = xml.attr(entry, 'path')
      local module   = xml.attr(entry, 'module') -- module="true" attribute

      if kind then
        if kind == 'output' and path_val then
          result.output = path_val
        elseif kind == 'lib' and path_val then
          local full
          if path_val:sub(1, 1) == '/' then
            full = path_val
          else
            -- Could be a linked resource name
            local link_resolved = linked[path_val]
            if link_resolved then
              full = link_resolved
            else
              full = project_dir .. '/' .. path_val
            end
          end

          if vim.fn.filereadable(full) == 1 then
            if module == 'true' or result.is_modular then
              table.insert(result.module_path, full)
            else
              table.insert(result.jars, full)
            end
          else
            vim.notify('Jar not found: ' .. full, vim.log.levels.WARN)
          end
        elseif kind == 'var' and path_val then
          -- Eclipse classpath variable (e.g. M2_REPO/group/artifact/x.jar)
          local resolved = resolve_variable(path_val)
          if resolved and vim.fn.filereadable(resolved) == 1 then
            table.insert(result.jars, resolved)
          end
        elseif kind == 'con' and path_val then
          local ul_name = path_val:match('USER_LIBRARY/(.+)')
          if ul_name then
            table.insert(result.user_libraries, ul_name)
          end
          -- JRE_CONTAINER is intentionally skipped — java binary handles it
        elseif kind == 'src' and path_val then
          -- Source folders: output may be overridden per source entry
          local src_output = xml.attr(entry, 'output')
          if src_output then
            -- Per-source output dir: add it alongside the main output
            local full_out = project_dir .. '/' .. src_output
            if vim.fn.isdirectory(full_out) == 1 then
              table.insert(result.jars, full_out) -- treat as extra classpath dir
            end
          end
        end
      end
    end

    return result
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- STALE BUILD CHECK
  -- ═══════════════════════════════════════════════════════════════════════════

  local function check_stale(project_dir, cp_data)
    local out_dir   = project_dir .. '/' .. cp_data.output
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

  -- ═══════════════════════════════════════════════════════════════════════════
  -- LAUNCH FILE PARSING
  -- ═══════════════════════════════════════════════════════════════════════════

  local function parse_launch(launch_path)
    local flat = xml.flatten(vim.fn.readfile(launch_path))

    local function get_attr(key_name)
      -- <stringAttribute key="KEY_NAME" value="..."/>  or mapAttribute variant
      local val = flat:match(
        'key%s*=%s*"' .. vim.pesc(key_name) .. '"%s+value%s*=%s*"([^"]*)"'
      ) or flat:match(
        'value%s*=%s*"([^"]*)"%s+key%s*=%s*"' .. vim.pesc(key_name) .. '"'
      )
      return val and xml.decode_entities(val) or nil
    end

    return {
      main_class   = get_attr('org.eclipse.jdt.launching.MAIN_TYPE'),
      project      = get_attr('org.eclipse.jdt.launching.PROJECT_ATTR'),
      jvm_args     = get_attr('org.eclipse.jdt.launching.VM_ARGUMENTS') or '',
      program_args = get_attr('org.eclipse.jdt.launching.PROGRAM_ARGUMENTS') or '',
    }
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- WORKSPACE / PROJECT DISCOVERY
  -- ═══════════════════════════════════════════════════════════════════════════

  local function find_workspace(start)
    local dir = start
    -- Raised to 12 levels to handle deeply nested monorepo structures
    for _ = 1, 12 do
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
      local flat  = xml.flatten(vim.fn.readfile(dp))
      local pname = flat:match('<name>%s*([^<]+)%s*</name>')
      if pname and xml.decode_entities(pname) == project_name then return dir end
    end

    return nil
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- LAUNCH FILE COLLECTION
  -- ═══════════════════════════════════════════════════════════════════════════

  local function collect_launch_files(workspace, project_dirs)
    local files = {}
    local seen  = {}

    local function add(f)
      if not seen[f] then
        seen[f] = true; table.insert(files, f)
      end
    end

    -- Eclipse metadata launches
    local metadata_dir = workspace
        .. '/.metadata/.plugins/org.eclipse.debug.core/.launches'
    for _, f in ipairs(vim.fn.glob(metadata_dir .. '/*.launch', false, true)) do
      add(f)
    end

    -- Per-project launches — search recursively (not just project root)
    for _, dir in ipairs(project_dirs) do
      for _, f in ipairs(vim.fn.glob(dir .. '/**/*.launch', false, true)) do
        add(f)
      end
    end

    return files
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- TERMINAL
  -- ═══════════════════════════════════════════════════════════════════════════

  local function open_terminal(cmd, label)
    -- Kill previous run terminal if it exists
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.b[buf].eclipse_run_terminal then
        vim.api.nvim_buf_delete(buf, { force = true })
        break
      end
    end

    local term_buf = vim.api.nvim_create_buf(false, true)
    vim.b[term_buf].eclipse_run_terminal = true
    vim.api.nvim_buf_set_name(term_buf, 'EclipseRun ' .. label)

    vim.api.nvim_open_win(term_buf, true, {
      split  = 'below',
      win    = 0,
      height = 15,
    })

    vim.fn.jobstart(cmd, {
      term = true,
      on_exit = function(_, exit_code)
        vim.schedule(function()
          if exit_code == 0 then
            vim.notify('[' .. label .. '] exited successfully', vim.log.levels.INFO)
          else
            vim.notify('[' .. label .. '] exited with code ' .. exit_code, vim.log.levels.WARN)
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
    end

    local sep     = package.config:sub(1, 1) == '\\' and ';' or ':'
    local out_dir = project_dir .. '/' .. cp_data.output

    -- ── Build the command parts ─────────────────────────────────────────────

    local parts   = { vim.fn.shellescape(java) }

    -- Module path (Java 9+ modular projects)
    if #cp_data.module_path > 0 then
      local mp_entries = { out_dir }
      vim.list_extend(mp_entries, cp_data.module_path)
      table.insert(parts, '--module-path')
      table.insert(parts, vim.fn.shellescape(table.concat(mp_entries, sep)))
      table.insert(parts, '--add-modules')
      table.insert(parts, 'ALL-MODULE-PATH')
    end

    -- Classpath
    local cp_entries = { out_dir }
    vim.list_extend(cp_entries, cp_data.jars)
    table.insert(parts, '-cp')
    table.insert(parts, vim.fn.shellescape(table.concat(cp_entries, sep)))

    -- JVM args: split properly so quoted/spaced args don't break the command
    if selected.jvm_args ~= '' then
      for _, arg in ipairs(split_args(selected.jvm_args)) do
        table.insert(parts, vim.fn.shellescape(arg))
      end
    end

    table.insert(parts, selected.main_class)

    -- Program args: same proper splitting
    if selected.program_args ~= '' then
      for _, arg in ipairs(split_args(selected.program_args)) do
        table.insert(parts, vim.fn.shellescape(arg))
      end
    end

    local cmd = 'cd ' .. vim.fn.shellescape(project_dir)
        .. ' && ' .. table.concat(parts, ' ')

    local label = selected.project .. ':' .. selected.main_class:match('[^.]+$')
    open_terminal(cmd, label)
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
