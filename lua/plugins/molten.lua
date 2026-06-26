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

    -- ── custom commands ───────────────────────────────────────────────────────

    -- The Ultimate Sync command: markdown is considered the source of truth
    vim.api.nvim_create_user_command("JupytextSync", function()
      local src = vim.fn.expand("%:p")
      local ext = src:match("[^.]+$")

      if ext == "ipynb" then
        local dst = src:gsub("%.ipynb$", ".md")
        if vim.fn.filereadable(dst) == 1 then
          -- Going into markdown: Jupytext natively updates the text content cells safely without --update
          run({ "jupytext", "--to", "markdown", src, "--output", dst }, "Jupytext: Merged updates into .md")
        else
          -- Companion file doesn't exist: Create the .md file fresh
          run({ "jupytext", "--to", "markdown", src, "--output", dst }, "Jupytext: Created paired .md")
        end
      elseif ext == "md" then
        local dst = src:gsub("%.md$", ".ipynb")
        if vim.fn.filereadable(dst) == 1 then
          -- Going into notebook: --update is strictly REQUIRED here to keep cell outputs and insert edits
          run({ "jupytext", "--to", "notebook", "--update", src, "--output", dst },
            "Jupytext: Merged updates into .ipynb")
        else
          -- Companion file doesn't exist: Create the .ipynb file fresh
          run({ "jupytext", "--to", "notebook", src, "--output", dst }, "Jupytext: Created paired .ipynb")
        end
      else
        vim.notify("Not a valid Jupytext format (.md or .ipynb)", vim.log.levels.WARN)
      end
    end, { desc = "Context-aware smart sync and merge for Jupytext pairings" })

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
    { "<leader>cms", "<cmd>JupytextSync<cr>", desc = "Sync and smart merge paired files" },
  },
}
