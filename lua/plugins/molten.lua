return {
  "benlubas/molten-nvim",
  version = "^1.0.0",
  build = ":UpdateRemotePlugins",
  init = function()
    vim.g.molten_output_win_max_height = 12
    vim.g.molten_auto_open_output = true
    vim.g.molten_auto_update_output = true
    vim.g.molten_image_provider = "image.nvim"

    -- Point Molten's python host at the active venv (venv or pyenv),
    -- falling back to the system python3. Must be set before the plugin
    -- initialises, so it lives in `init` rather than `config`.
    local venv = vim.env.VIRTUAL_ENV or vim.env.PYENV_VIRTUAL_ENV
    if venv then
      vim.g.python3_host_prog = venv .. "/bin/python3"
    else
      local pyenv_root = vim.env.PYENV_ROOT
      if pyenv_root then
        local pyenv_python = pyenv_root .. "/shims/python3"
        if vim.fn.executable(pyenv_python) == 1 then
          vim.g.python3_host_prog = pyenv_python
        end
      end
    end
  end,

  config = function()
    -- ── helpers ──────────────────────────────────────────────────────────────

    --- Run a shell command and notify with its result.
    ---@param cmd string|table
    ---@param label string
    local function run(cmd, label)
      local result = vim.fn.system(cmd)
      local ok = vim.v.shell_error == 0
      vim.notify(
        label .. (ok and " ✓" or ("\n" .. result)),
        ok and vim.log.levels.INFO or vim.log.levels.ERROR
      )
    end

    --- Convert src → tmp, then merge tmp into dst with `git merge-file`.
    --- If dst doesn't exist yet, simply move tmp into place.
    ---@param src string  absolute path of the source file
    ---@param dst string  absolute path of the destination file
    ---@param convert fun(src: string, tmp: string)
    local function convert_with_merge(src, dst, convert)
      -- Keep the correct extension so jupytext doesn't reject the output path.
      -- e.g. dst = "/foo/notes.md"  →  tmp = "/tmp/jupytext_123456_notes.md"
      local ext      = dst:match("[^.]+$")
      local basename = dst:match("([^/]+)$")
      local tmp      = string.format("/tmp/jupytext_%d_%s", os.time(), basename)
      -- Sanity-check: ensure extension wasn't lost in the basename substitution
      if not tmp:match("%." .. ext .. "$") then
        tmp = tmp .. "." .. ext
      end
      convert(src, tmp)
      if vim.v.shell_error ~= 0 then return end

      if vim.fn.filereadable(dst) == 1 then
        -- git merge-file writes the result in-place to the first argument;
        -- we pass dst as both current and base so only new content is added.
        vim.fn.system({
          "git", "merge-file", "--theirs",
          dst, -- current  (ours)
          dst, -- base     (common ancestor — same, so only additions land)
          tmp, -- other    (newly converted)
        })
        vim.fn.delete(tmp)
        local ok = vim.v.shell_error == 0
        vim.notify(
          (ok and "Merged into: " or "Merge conflict in: ") .. dst,
          ok and vim.log.levels.INFO or vim.log.levels.WARN
        )
      else
        vim.loop.fs_rename(tmp, dst)
        vim.notify("Created: " .. dst, vim.log.levels.INFO)
      end
    end

    -- ── custom commands ───────────────────────────────────────────────────────

    -- .ipynb → .md  (merges if .md already exists)
    vim.api.nvim_create_user_command("JupytextToMarkdown", function()
      local src = vim.fn.expand("%:p")
      if not src:match("%.ipynb$") then
        vim.notify("Not an .ipynb file", vim.log.levels.WARN); return
      end
      local dst = src:gsub("%.ipynb$", ".md")
      convert_with_merge(src, dst, function(s, t)
        run({ "jupytext", "--to", "markdown", s, "--output", t }, "jupytext →md")
      end)
    end, { desc = "Convert .ipynb → .md (merge if exists)" })

    -- .md → .ipynb  (merges if .ipynb already exists)
    vim.api.nvim_create_user_command("JupytextToNotebook", function()
      local src = vim.fn.expand("%:p")
      if not src:match("%.md$") then
        vim.notify("Not a .md file", vim.log.levels.WARN); return
      end
      local dst = src:gsub("%.md$", ".ipynb")
      convert_with_merge(src, dst, function(s, t)
        run({ "jupytext", "--to", "notebook", s, "--output", t }, "jupytext →ipynb")
      end)
    end, { desc = "Convert .md → .ipynb (merge if exists)" })

    -- Sync paired files in both directions
    vim.api.nvim_create_user_command("JupytextSync", function()
      local file = vim.fn.expand("%:p")
      run({ "jupytext", "--sync", file }, "Synced " .. file)
    end, { desc = "Sync paired jupytext files" })

    -- Init kernel that matches the active venv/pyenv automatically
    vim.api.nvim_create_user_command("MoltenInitVenv", function()
      local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
      if venv then
        local name = venv:match("/.+/(.+)$") or "python3"
        vim.cmd("MoltenInit " .. name)
      else
        vim.cmd("MoltenInit python3")
      end
    end, { desc = "Init Molten kernel matching the active venv" })
  end,

  keys = {
    -- ── Kernel ───────────────────────────────────────────────────────────────
    { "<leader>cmi", "<cmd>MoltenInitVenv<cr>", desc = "Init kernel (auto venv)" },
    { "<leader>cmI", "<cmd>MoltenInit<cr>", desc = "Init kernel (pick)" },
    { "<leader>cmq", "<cmd>MoltenDeinit<cr>", desc = "Quit kernel" },
    { "<leader>cmr", "<cmd>MoltenRestart<cr>", desc = "Restart kernel" },
    { "<leader>cmx", "<cmd>MoltenInterrupt<cr>", desc = "Interrupt kernel" },
    { "<leader>cm?", "<cmd>MoltenInfo<cr>", desc = "Kernel info" },

    -- ── Evaluate ─────────────────────────────────────────────────────────────
    { "<leader>cme", "<cmd>MoltenEvaluateOperator<cr>", desc = "Evaluate (operator)", mode = { "n" } },
    { "<leader>cme", ":<C-u>MoltenEvaluateVisual<cr>", desc = "Evaluate selection", mode = { "v" } },
    { "<leader>cml", "<cmd>MoltenEvaluateLine<cr>", desc = "Evaluate line" },
    { "<leader>cmE", "<cmd>MoltenReevaluateCell<cr>", desc = "Re-evaluate cell" },
    { "<leader>cmR", "<cmd>MoltenReevaluateAll<cr>", desc = "Re-evaluate all" },
    { "<leader>cmd", "<cmd>MoltenDelete<cr>", desc = "Delete cell" },

    -- ── Navigate ──────────────────────────────────────────────────────────────
    { "<leader>cmn", "<cmd>MoltenNext<cr>", desc = "Next cell" },
    { "<leader>cmp", "<cmd>MoltenPrev<cr>", desc = "Prev cell" },
    { "<leader>cmg", "<cmd>MoltenGoto<cr>", desc = "Goto cell" },

    -- ── Output ───────────────────────────────────────────────────────────────
    { "<leader>cmos", "<cmd>MoltenShowOutput<cr>", desc = "Show output" },
    { "<leader>cmoh", "<cmd>MoltenHideOutput<cr>", desc = "Hide output" },
    { "<leader>cmoe", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Enter output window" },
    { "<leader>cmob", "<cmd>MoltenOpenInBrowser<cr>", desc = "Open output in browser" },
    { "<leader>cmop", "<cmd>MoltenImagePopup<cr>", desc = "Pop image output" },

    -- ── Save / Load ───────────────────────────────────────────────────────────
    { "<leader>cmw", "<cmd>MoltenSave<cr>", desc = "Save outputs" },
    { "<leader>cmL", "<cmd>MoltenLoad<cr>", desc = "Load outputs" },
    { "<leader>cmX", "<cmd>MoltenExportOutput<cr>", desc = "Export → .ipynb" },
    { "<leader>cmO", "<cmd>MoltenImportOutput<cr>", desc = "Import ← .ipynb" },

    -- ── Jupytext ──────────────────────────────────────────────────────────────
    { "<leader>cjm", "<cmd>JupytextToMarkdown<cr>", desc = "Convert .ipynb → .md" },
    { "<leader>cjn", "<cmd>JupytextToNotebook<cr>", desc = "Convert .md → .ipynb" },
    { "<leader>cjs", "<cmd>JupytextSync<cr>", desc = "Sync paired notebook" },
  },
}
