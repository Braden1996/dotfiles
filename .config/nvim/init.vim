" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

" Declare the list of plugins.
Plug 'tpope/vim-sensible'
Plug 'arcticicestudio/nord-vim'
Plug 'airblade/vim-gitgutter'
Plug 'jeffkreeftmeijer/vim-numbertoggle'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" Colour scheme 
colorscheme nord

" Indent with 2 spaces
set expandtab
set shiftwidth=2
set softtabstop=2

" Hybride line numbers
set numberwidth=4
set number relativenumber
