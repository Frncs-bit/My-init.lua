-- ===========================================================================
-- init.lua - Configuração principal do Neovim
-- ===========================================================================

-- Define a variável global para o caminho de dados do Neovim
local vim_data_path = vim.fn.stdpath("data")

-- =============================================
--           SETUP LAZY.NIM
-- =============================================

local lazypath = vim_data_path .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- =============================================
--            OPÇÕES GLOBAIS DO NVIM
-- =============================================

vim.opt.clipboard = 'unnamedplus'
vim.opt.nu = true
vim.opt.tabstop = 4           -- Tamanho de uma tabulação
vim.opt.softtabstop = 4       -- Adicionado: Largura de um tab ao editar
vim.opt.shiftwidth = 4        -- Espaços usados para auto-indent
vim.opt.expandtab = true      -- Usar espaços em vez de tabulações
vim.opt.smartindent = true    -- Indentação inteligente
vim.opt.hlsearch = true       -- Destacar resultados da pesquisa
vim.opt.incsearch = true      -- Pesquisa incremental
vim.opt.termguicolors = true  -- Ativar cores verdadeiras no terminal (para temas)
vim.opt.scrolloff = 8         -- Linhas de contexto acima/abaixo do cursor ao rolar
vim.opt.isfname:append("@-@") -- Caracteres que podem fazer parte do nome do arquivo
vim.opt.signcolumn = "yes"    -- Sempre mostrar a coluna dos sinais (diagnósticos LSP)
vim.opt.cmdheight = 1         -- Altura da linha de comando
vim.opt.shortmess:append("c") -- Ocultar algumas mensagens de introdução
vim.opt.background = 'dark'   -- Definir o fundo como escuro (para temas transparentes)
vim.opt.updatetime = 300      -- Adicionado: Tempo para o Neovim escrever o swapfile (diagnósticos LSP)
vim.g.mapleader = " "

-- =============================================
--              PLUGINS
-- =============================================

require("lazy").setup({
  -- Temas
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'auto', -- Ou 'catppuccin', 'tokyonight'
         component_separators = { '', '' },
          section_separators = { '', '' },
          disabled_filetypes = { 'NvimTree', 'packer', 'alpha', 'lazy' },
          always_divide_middle = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        extensions = { 'nvim-tree', 'lazy' }
      })
    end,
  },

  -- Tokyodark
  {
    "tiagovla/tokyodark.nvim",
    opts = {},
    config = function(_, opts)
      require("tokyodark").setup(opts)
    end,
  },
  
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- Necessário para autocompletar e snippets com LSP
    },
    config = function()
      local lspconfig = require('lspconfig')
      local cmp_nvim_lsp = require('cmp_nvim_lsp')

      -- Configuração para capacidades do LSP (útil para nvim-cmp)
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Função para configurar keymaps básicos do LSP ao anexar o servidor
      local on_attach = function(client, bufnr)
        -- Habilita formatação automática ao salvar (se o servidor suportar)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("LspFormatting", {}),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end

        -- Mapeamentos de tecla básicos para LSP
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
      end

      -- Configuração do servidor LSP para C++ (clangd)
      lspconfig.clangd.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      -- Configuração do servidor LSP para Python (pyright)
      lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      -- Configuração de diagnóstico para exibir erros/avisos
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
      })
    end,
  },
        
  -- Telescope
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Nenhuma configuração específica de setup para Telescope aqui,
      -- pois é principalmente configurado via keymaps
    end,
  },

  -- Nvim-Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'master',
    lazy = false,
    build = ":TSUpdate", -- Comando para instalar os parsers
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          "c", "lua", "vim", "vimdoc", "query", "html", "css",
          "javascript", "typescript", "json", "yaml", "markdown",
          "cpp", "python", "bash", -- Adicionado: bash
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- Mini.nvim
  {
    'echasnovski/mini.nvim',
    version = '*',
    config = function()
      require('mini.pairs').setup()
    end,
  },

  -- Neo-tree.nvim
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require('neo-tree').setup({
        close_if_last_window = true,
        filesystem = {
          filtered_items = {
            visible_in_plus_file = true,
            hide_dotfiles = false,
            hide_git_ignored = false,
            hide_hidden = false,
          },
          window = {
            mappings = {
              ["<space>"] = "none",
            }
          }
        },
        window = {
          position = "left",
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
        },
        default_component_configs = {
          container = {
            enable_character_fade = true
          },
          indent = {
            indent_size = 2,
            padding = 1,
            tree_indent_markers = { "│" },
            parent_edge_markers = { "─" },
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "",
            folder_empty_open = "",
            default = "",
          },
          git_status = {
            symbols = {
              added     = "✚",
              modified  = "",
              deleted   = "✖",
              renamed   = "➜",
              untracked = "",
              ignored   = "",
              unstaged  = "",
              staged    = "",
              conflict  = "",
            },
          },
        },
      })
    end,
  },

  -- Nvim-cmp (autocompletar)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
      "hrsh7th/cmp-nvim-lsp", -- Adicionado: Fonte para sugestões do LSP
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- Adicionado: Sugestões do LSP
          { name = 'luasnip' },  -- Sugestões de snippets
          { name = 'buffer' },
          { name = 'path' },
        }),
      })

      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'cmdline' }
        })
      })
    end,
  },
})

-- =============================================
--             TEMA
-- =============================================

 vim.cmd.colorscheme("catppuccin")
-- vim.cmd([[colorscheme tokyodark]]) -- Deixei comentado caso queira usar tokyodark
require("catppuccin").setup({
    flavour = "macchiato", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = true, -- disables setting the background color.
    show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
    term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
    dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
    },
    no_italic = false, -- Force no italic
    no_bold = false, -- Force no bold
    no_underline = false, -- Force no underline
    styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { "italic" }, -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
    },
    color_overrides = {},
    custom_highlights = {},
    default_integrations = true,
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
            enabled = true,
            indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
    },
})

-- setup must be called before loading
vim.cmd.colorscheme "catppuccin"


-- setup must be called before loading

-- =============================================
--         C++ CODE RUNNER SIMPLES
-- =============================================

-- Função para compilar e rodar um arquivo C++
local function run_cpp_code()
  local current_file = vim.fn.expand('%:p') -- Obtém o caminho absoluto do arquivo atual
  local file_name_no_ext = vim.fn.expand('%:t:r') -- Obtém o nome do arquivo sem extensão
  local output_dir = vim.fn.fnamodify(current_file, ':h') -- Obtém o diretório do arquivo atual
  local output_executable = output_dir .. '/' .. file_name_no_ext

  -- Comando de compilação (usando g++)
  local compile_command = string.format('g++ -std=c++17 -O2 -Wall "%s" -o "%s"', current_file, output_executable)

  -- Comando de execução
  local run_command = string.format('"%s"', output_executable)

  -- Comando completo para ser executado no terminal
  local full_command = string.format('%s && %s || echo "Falha na compilação ou execução."', compile_command, run_command)

  -- Abre um terminal em uma nova janela dividida horizontalmente
  -- e executa o comando completo
  vim.cmd('split | terminal')
  -- Envia o comando para o terminal
  vim.api.nvim_chan_send(vim.api.nvim_get_current_buf(), full_command .. '\n')

  -- Opcional: ajustar o tamanho da janela do terminal
  -- vim.cmd('resize 10')
end

-- ===========================================================================
--            ATALHOS / COMANDOS
-- ===========================================================================

local builtin = require("telescope.builtin") -- Necessário para os atalhos do Telescope

vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { noremap = true, silent = true, desc = "Toggle Neo-tree" })
vim.keymap.set('n', "<M-Down>", "yyp", { silent = true, desc = "Duplicate line down" })
vim.keymap.set('v', "<M-Down>", ":t.<CR>", { silent = true, desc = "Duplicate selection down" })


vim.keymap.set('n', '<leader>t', function()
  local width = vim.fn.winwidth(0) -- Obtém a largura da janela atual
  local target_width = math.floor(width * 0.30) -- Calcula 30% da largura
  vim.cmd('botright vnew | terminal') -- Abre um terminal em um novo split vertical na parte inferior direita
  vim.cmd('vertical resize ' .. target_width) -- Redimensiona para a largura desejada
end, { desc = "Open terminal on right (30% width)" })
-- Nota: Este mapeamento funcionará no modo normal e no modo terminal.
-- Se houver outros mapeamentos para <C-Tab> de outros plugins, este pode sobrescrevê-los.
vim.keymap.set({'n', 't'}, '<Esc>1', '<C-w>w', { desc = 'Switch to next window' })
vim.api.nvim_set_keymap('t', '<Esc><Esc>', '<C-\\><C-n>', { noremap = true, silent = true })

-- ===========================================================================
-- Fim do init.lua
-- ===========================================================================


