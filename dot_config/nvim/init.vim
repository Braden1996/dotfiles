" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

" Declare the list of plugins.
Plug 'tpope/vim-sensible'
Plug 'airblade/vim-gitgutter'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'crusoexia/vim-dracula'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" Enable true colors if available
set termguicolors

fun! s:Dra()
    colorscheme dracula
    set background=dark
    syntax on
endfunction
command Dra call s:Dra()

highlight Comment cterm=italic gui=italic

" Indent with 2 spaces
set expandtab
set shiftwidth=2
set softtabstop=2

" Hybride line numbers
set numberwidth=4
set number relativenumber
