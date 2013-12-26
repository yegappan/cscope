" File: cscope.vim
" Author: Yegappan Lakshmanan
" Version: 1.0
" Last Modified: December 22, 2006
"
" Plugin for interacting with the cscope tool
"
" The following commands are defined by this plugin:
"
" CsFindSymbol - Find symbol
" CsFindDef - Find definition
" CsFindCalled - Find functions called by  a function
" CsFindCalling - Find function calling a function
" CsFindText - Find a text
" CsFindPattern - Find a pattern.
" CsFindFile - Find a file
" CsFindIncluding - Find file #including the specified file
"
" CsPop - Pop the cscope query results stack
" CsShow - Show the cscope query results stack
"
" The following configuration variables are supported:
"
" Cscope_Cmd          - Location and name of the cscope tool. By default, this
"                       is set to 'cscope'.
" Cscope_Args         - Arguments to pass to cscope. By default, this is set
"                       to '-q'
" Cscope_Cr_File      - Cscope cross-reference file name. By default, this
"                       variable is set to 'cscope.out'
" Cscope_Prepend_Path - Path to prepend to file names in the cscope query
"                       result. By default, the directory of the cscope
"                       cross-reference file is pre-pended to the file names.

" --------------------- Do not modify after this line ---------------------
if exists('loaded_cscope')
    finish
endif
let loaded_cscope=1

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" Path to cscope
if !exists('Cscope_Cmd')
    let Cscope_Cmd = 'cscope'
endif

" Arguments to cscope
if !exists('Cscope_Args')
    let Cscope_Args = '-q'
endif

" Location of the cscope cross-reference file
if !exists('Cscope_Cr_File')
    let Cscope_Cr_File = 'cscope.out'
endif

" Path to prepend to file names in cscope query result
if !exists('Cscope_Prepend_Path')
    let Cscope_Prepend_Path=''
endif

let s:cs_query_0_name = 'find symbol'
let s:cs_query_0_msg = 'Find Symbol: '
let s:cs_query_1_name = 'find definition'
let s:cs_query_1_msg = 'Find Definition: '
let s:cs_query_2_name = 'find called'
let s:cs_query_2_msg = 'Find functions called by: '
let s:cs_query_3_name = 'find calling'
let s:cs_query_3_msg = 'Find functions calling: '
let s:cs_query_4_name = 'find text'
let s:cs_query_4_msg = 'Find text: '
let s:cs_query_6_name = 'find pattern'
let s:cs_query_6_msg = 'Find pattern: '
let s:cs_query_7_name = 'find file'
let s:cs_query_7_msg = 'Find file: '
let s:cs_query_8_name = 'find files including'
let s:cs_query_8_msg = 'Find files including: '

let s:cs_stack_idx = 0

" Cscope_Msg
function! s:Cscope_Msg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

" Cscope_Find_DB
" Search for the specified cscope cross-reference file.
" Recursively search in the parent directories.
function! s:Cscope_Find_DB(db_name)
    let dir = getcwd()

    while 1
        let db = dir . '/' . a:db_name
        if filereadable(db)
            " Remove symbolic references
            return resolve(fnamemodify(db, ':p'))
        endif

        " Get the parent directory
        let pdir = fnamemodify(dir, ':h')
        if pdir == dir
            " Reached the root directory
            return ''
        endif

        let dir = pdir
    endwhile
endfunction

" Cscope_Get_Cr_File
" Return the cscope cross reference file to use
function! s:Cscope_Get_Cr_File()
    " First locate a valid cscope.out file
    let db = g:Cscope_Cr_File
    if filereadable(db)
        return db
    endif

    " Search in the parent directories
    let db = s:Cscope_Find_DB(g:Cscope_Cr_File)
    if db != ''
        return db
    endif

    " Repeat the search with the default cscope.out file name
    let db = s:Cscope_Find_DB('cscope.out')
    if db != ''
        return db
    endif

    call s:Cscope_Msg('Error: Cscope cross-reference file (' .
                \ g:Cscope_Cr_File . ') is not found')
    let db = input('Enter location of cscope cross-reference file: ',
                \ g:Cscope_Cr_File)
    if db == ''
        return ''
    endif
    if !filereadable(db)
        call s:Cscope_Msg('Error: File ' . db . ' is not readable')
        return ''
    endif

    let g:Cscope_Cr_File = db

    return db
endfunction

" Cscope_Resolve_File
" Resolve the filename in the cscope query output
" If it is a absolute path name, then ignore it
" Otherwise, prepend 'ppath' to the pathname
function! s:Cscope_Resolve_File(mtxt, ppath)
    if a:mtxt == ''
        return ''
    endif

    if a:mtxt[0] == '/'
        return a:mtxt
    endif

    if has('win32')
        if a:mtxt[0] == '\\' || a:mtxt[1] == ':'
            return a:mtxt
        endif
    endif

    if a:mtxt =~ '^' . a:ppath
        return a:mtxt
    endif

    return a:ppath . '/' . a:mtxt
endfunction

" Cscope_Find
" Run a Cscope query
function! s:Cscope_Find(cmd_idx, ...)
    " Get the cscope cross reference file
    let db = s:Cscope_Get_Cr_File()
    if db == ''
        return
    endif

    let pattern = ''
    let cscope_opt = ''
    " Parse the arguments
    " cscope command-line flags are specified using the "-flag" format
    " the next argument is assumed to be the pattern
    let argcnt = 1
    while argcnt <= a:0
        if a:{argcnt} =~ '^-'
            let cscope_opt = cscope_opt . ' ' . a:{argcnt}
        else
            let pattern = a:{argcnt}
        endif
        let argcnt = argcnt + 1
    endwhile

    if pattern == ''
        " Get the pattern from the user (default current word)
        if a:cmd_idx == 7 || a:cmd_idx == 8
            " Find file command. Use the filename under the cursor
            let defpat = expand('<cfile>')
        else
            " Other commands. Use the word under the cursor
            let defpat = expand('<cword>')
        endif

        let msg = s:cs_query_{a:cmd_idx}_msg
        let pattern = input(msg, defpat)
        if pattern == ''
            return
        endif
    endif

    let cscope_opt = cscope_opt . ' -d -L ' . g:Cscope_Args
    let cmd = g:Cscope_Cmd . ' ' . cscope_opt . ' -f ' . db .
                \ ' -' . a:cmd_idx .' ' . pattern

    let cmd_output = system(cmd)
    if cmd_output == ''
        call s:Cscope_Msg('Error: Pattern ' . pattern . ' is not found')
        return
    endif

    if v:shell_error
        call s:Cscope_Msg('Error: Failed to run cscope (' . cmd_output . ')')
        return
    endif

    " Save the current file name, line number and line in the stack
    let s:cs_stack_idx = s:cs_stack_idx + 1
    let s:cs_stack_{s:cs_stack_idx}_filename = fnamemodify(expand('%'), ':p')
    let s:cs_stack_{s:cs_stack_idx}_lnum = line('.')

    " The output from cscope is of the format:
    "     <filename> <functionname> <linenumber> <text>
    "
    " Move the function name after the line number in the output
    let spat = '\(.\{-}\) \(.\{-}\) \(\d\+\) ' . "\\([^\n]\\+\n\\)"
    let rpat = '\1 \3 <\2> \4'
    let cmd_output = substitute(cmd_output, spat, rpat, 'g')

    let ppath = g:Cscope_Prepend_Path
    if ppath == ''
        " Prepend path is not specified by user. Use the path of the
        " cscope.out file
        let ppath = fnamemodify(db, ':h')
    endif

    " Prepend path to all the filenames in the cscope query output.
    if ppath != ''
        let cmd_output = substitute(cmd_output, "[^\n]\\+",
                    \ '\=s:Cscope_Resolve_File(submatch(0), ppath)', 'g')
    endif

    echo "\r"

    let tmpfile = tempname()

    let old_verbose = &verbose
    set verbose&vim

    exe "redir! > " . tmpfile
    silent echon '[Cscope query (' . s:cs_query_{a:cmd_idx}_name . ') for ' .
                \ pattern . "]\n"
    silent echon cmd_output
    redir END

    let &verbose = old_verbose

    let old_efm = &efm
    set efm=%f\ %l\ %m

    if exists(":cgetfile")
        execute "silent! cgetfile " . tmpfile
    else
        execute "silent! cfile " . tmpfile
    endif

    let &efm = old_efm

    call delete(tmpfile)

    " Open the quickfix window below the current window
    botright copen
endfunction

" Cs_Stack_Pop
" Jump to the filename and line number at the top of the stack
function! s:Cs_Stack_Pop(entry_count)
    if s:cs_stack_idx == 0
        call s:Cscope_Msg("Cscope stack is empty")
        return
    endif

    let i = 1

    let pop_count = a:entry_count
    if pop_count > s:cs_stack_idx
        let pop_count = s:cs_stack_idx
    endif

    " Pop the specified number of entries
    while i < pop_count
        unlet! s:cs_stack_{s:cs_stack_idx}_filename
        unlet! s:cs_stack_{s:cs_stack_idx}_lnum
        let s:cs_stack_idx = s:cs_stack_idx - 1

        let i = i + 1
    endwhile

    " Jump to the last specified entry
    let fname = s:cs_stack_{s:cs_stack_idx}_filename
    let lnum = s:cs_stack_{s:cs_stack_idx}_lnum

    unlet! s:cs_stack_{s:cs_stack_idx}_filename
    unlet! s:cs_stack_{s:cs_stack_idx}_lnum
    let s:cs_stack_idx = s:cs_stack_idx - 1

    exe 'edit +' . lnum . ' ' . fname
endfunction

" Cs_Stack_Show
" Display the entries in the cscope stack
function! s:Cs_Stack_Show()
    if s:cs_stack_idx == 0
        call s:Cscope_Msg("Cscope stack is empty")
        return
    endif

    echo "Cscope stack"
    echo "#\tlnum\tfile"

    " Display the stack with the topmost entry first
    let i = s:cs_stack_idx
    let entry = 1
    while i >= 1
        " Show only the last 50 characters in the file name
        let fname = fnamemodify(s:cs_stack_{i}_filename, ':.')
        let len = strlen(fname)
        let fname = strpart(fname, len-50)
        echo entry . "\t" . s:cs_stack_{i}_lnum . "\t" . fname
        let i = i - 1
        let entry = entry + 1
    endwhile
endfunction

" Define user commands to interface with cscope
command! -nargs=* -complete=tag CsFindSymbol call s:Cscope_Find(0, <f-args>)
command! -nargs=* -complete=tag CsFindDef call s:Cscope_Find(1, <f-args>)
command! -nargs=* -complete=tag CsFindCalled call s:Cscope_Find(2, <f-args>)
command! -nargs=* -complete=tag CsFindCalling call s:Cscope_Find(3, <f-args>)
command! -nargs=* -complete=tag CsFindText call s:Cscope_Find(4, <f-args>)
command! -nargs=* -complete=tag CsFindPattern call s:Cscope_Find(6, <f-args>)
command! -nargs=* -complete=file CsFindFile call s:Cscope_Find(7, <f-args>)
command! -nargs=* -complete=file CsFindIncluding call s:Cscope_Find(8, <f-args>)

command! -count=1 CsPop call s:Cs_Stack_Pop(<count>)
command! CsShow call s:Cs_Stack_Show()

" When running GUI Vim, add menu entries for the cscope commands
if has("gui_running")
    anoremenu <silent> Tools.Cscope.Find\ Symbol<Tab>:CsFindSymbol
                \ :CsFindSymbol <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ Definition<Tab>:CsFindDef
                \ :CsFindDef <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ Called<Tab>:CsFindCalled
                \ :CsFindCalled <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ Calling<Tab>:CsFindCalling
                \ :CsFindCalling <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ Text<Tab>:CsFindText
                \ :CsFindText <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ Pattern<Tab>:CsFindPattern
                \ :CsFindPattern <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.Find\ File<Tab>:CsFindFile
                \ :CsFindFile <C-R><C-W><CR>
    anoremenu <silent> Tools.Cscope.-Sep- :
    anoremenu <silent> Tools.Cscope.Show\ Stack<Tab>:CsShow
                \ :CsShow<CR>
    anoremenu <silent> Tools.Cscope.Pop\ Stack<Tab>:CsPop
                \ :CsPop<CR>

    " Add the popup menu
    anoremenu <silent> PopUp.Cscope.Find\ Symbol<Tab>:CsFindSymbol
                \ :CsFindSymbol <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ Definition<Tab>:CsFindDef
                \ :CsFindDef <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ Called<Tab>:CsFindCalled
                \ :CsFindCalled <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ Calling<Tab>:CsFindCalling
                \ :CsFindCalling <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ Text<Tab>:CsFindText
                \ :CsFindText <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ Pattern<Tab>:CsFindPattern
                \ :CsFindPattern <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.Find\ File<Tab>:CsFindFile
                \ :CsFindFile <C-R><C-W><CR>
    anoremenu <silent> PopUp.Cscope.-Sep- :
    anoremenu <silent> PopUp.Cscope.Show\ Stack<Tab>:CsShow
                \ :CsShow<CR>
    anoremenu <silent> PopUp.Cscope.Pop\ Stack<Tab>:CsPop
                \ :CsPop<CR>
endif

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
