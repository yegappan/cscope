# Cscope Vim Plugin

The cscope plugin integrates the [Cscope](http://cscope.sourceforge.net/) tool to browse source files with Vim.

This plugin works with both Vim and Neovim and will work on all the platforms where Vim/Neovim are supported.  This plugin will work in both console and GUI Vim.
You will need the cscope tool to use this plugin.

## Installation

You can install this plugin directly from github using the following steps:

```
    $ mkdir -p $HOME/.vim/pack/downloads/opt/cscope
    $ cd $HOME/.vim/pack/downloads/opt/cscope
    $ git clone https://github.com/yegappan/cscope
```

After installing the plugin using the above steps, add the following line to
your $HOME/.vimrc file:

```
    packadd cscope
```

You can also install and manage this plugin using any one of the Vim plugin managers (dein.vim, pathogen, vam, vim-plug, volt, Vundle, etc.).

## Supported Commands

The following commands are provided by this plugin:

Command|Description
-------|-----------
:CsFindSymbol|Find a symbol
:CsFindDef|Find a definition
:CsFindCalled|Find functions called by  a function
:CsFindCalling|Find function calling a function
:CsFindText|Find a text
:CsFindPattern|Find a pattern.
:CsFindFile|Find a file
:CsFindIncluding|Find file #including the specified file
:CsPop|Pop the cscope query results stack
:CsShow|Show the cscope query results stack

## Configuration

The following configuration variables are supported. You can set these variables in your `.vimrc` file.

Variable|Description
--------|-----------
Cscope_Cmd|Location and name of the cscope tool. By default, this is set to 'cscope'.
Cscope_Args|Arguments to pass to cscope. By default, this is set to '-q'
Cscope_Cr_File|Cscope cross-reference file name. By default, this variable is set to 'cscope.out'
Cscope_Prepend_Path|Path to prepend to file names in the cscope query result. By default, the directory of the cscope cross-reference file is pre-pended to the file names.

