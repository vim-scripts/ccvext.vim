" Name:     ccvext.vim
" Brief:    Usefull tools reading code or coding
" Version:  2.0.0
" Date:     Sun Jan 24 02:50:48 2010
" Author:   Chen Zuopeng (EN: Daniel Chen)
" Email:    rlxtime.com@gmail.com 
"           chenzuopeng@gmail.com
"
" License:  Public domain, no restrictions whatsoever
"
" Copyright:Copyright (C) 2009-2010 Chen Zuopeng
"           Permission is hereby granted to use and distribute this code,
"           with or without modifications, provided that this copyright
"           notice is copied with it. Like anything else that's free,
"           bufexplorer.vim is provided *as is* and comes with no
"           warranty of any kind, either expressed or implied. In no
"           event will the copyright holder be liable for any damages
"           resulting from the use of this software.
"
" TODO:     Auto generate ctags and cscope database, and easy to use
"
" NOTE:     
"

"Initialization {{{
if exists("g:ccvext_version")
    finish
else
    "set autowrite
    "set autoread
endif

let g:ccvext_version = "2.0"

" Check for Vim version 600 or greater
if v:version < 600
    echo "Sorry, ccvext" . g:ccvext_version. "\nONLY runs with Vim 6.0 and greater."
    finish
endif
"}}}


"Initialization local variable platform independence {{{

"let s:ccve_debug = 'true'
let s:ccve_debug = 'false'

let s:ccve_vars = {
            \'win32':{
                \'slash':'\', 
                \'HOME':'\.symbs', 
                \'list_f':'\.symbs\.list', 
                \'env_f':'\.symbs\.env'
                \},
            \'unix':{
                \'slash':'/', 
                \'HOME':$HOME . '/.symbs', 
                \'list_f':$HOME . 
                \'/.symbs/.l', 
                \'env_f':$HOME . '/.symbs/.evn'
                \},
            \'setting':{
                \'tags_l':['./tags'],
                \'cscope.out_l':[{'idx':0}, {0:'noused'}]
                \}
            \}

let s:ccc_v = {
            \'win32':['\', '\.symbs', '\.symbs\.list', '\.symbs\.env'], 
            \'unix':['/', '/.symbs', '/.symbs/.l', $HOME . '/.symbs/.evn'], 
            \'setting':['./tags', [{'idx':0}, {0:'noused'}]]
            \}
"}}}

let g:ccve_funs = {'ListCmd':{}}

if has ('win32')
    let s:os = 'win32'
else
    let s:os = 'unix'
endif

"let s:postfix = ['"*.java"']
"let s:postfix = ['"*.py"']
"let s:postfix = ['"*.html"', '"*.xml"']
"let s:postfix = ['"*.java"', '"*.h"', '"*.c"', '"*.hpp"', '"*.cpp"', '"*.cc"']
let s:postfix = ['"*.java"', '"*.py"', '"*.h"', '"*.c"', '"*.hpp"', '"*.cpp"', '"*.cc"']

"Exame software environment {{{
if !executable ('ctags')
    echomsg 'Taglist: Exuberant ctags (http://ctags.sf.net) ' .
            \ 'not found in PATH. Plugin is not full loaded.'
endif

if !executable ('cscope')
    echomsg 'cscope: cscope (http://cscope.sourceforge.net/) ' .
            \ 'not found in PATH. Plugin is not full loaded.'
endif

if !executable ('ctags') && !executable ('cscope')
    finish
endif
"}}}

"-----------------------------------------------------------------
"Add symbs to environment
function! AddSymbs (symbs)
    if a:symbs == ""
        return 'false'
    endif
    "get directory name
    let l:name  = substitute(a:symbs, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')
    let l:cmp_s = ""

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "tags setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    "tags full path
    let l:symbs_t = s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name . s:ccve_vars[s:os]['slash'] . 'tags'

    echo l:symbs_t

    if filereadable (l:symbs_t) == 0
        echomsg 'Tags not found'
    else
        "if tags database path already set, do nothing
        for l:idx in s:ccve_vars['setting']['tags_l']
            "get dir name:
            "eg: 
            "   l:idx = '/home/user/.symbs/boost/tags'
            "   l:cmp_s = boost

            "remove '/tags'
            let l:cmp_s = substitute(l:idx, '\' . s:ccve_vars[s:os]['slash'] . 'tags', '', 'g')
            "remove '/home/user/.symbs/'
            let l:cmp_s = substitute(l:cmp_s, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')

            if s:ccve_debug == 'true'
                echo 'DEBUG: l:cmp_s:' . l:cmp_s
                echo 'DEBUG: l:name:' . l:name
            endif

            if l:cmp_s == l:name
                "tags name alread set
                break
            endif
        endfor
        "tags name not set
        if l:cmp_s != l:name
            if s:ccve_debug == 'true'
                echo 'DEBUG: add new tags' . l:symbs_t
            endif
            call add (s:ccve_vars['setting']['tags_l'], l:symbs_t)
        else
            if s:ccve_debug == 'true'
                echo 'DEBUG: tags:' . l:symbs_t . ' already set.'
            endif
        endif

        let $TAGS_PATH = ''
        for l:idx in s:ccve_vars['setting']['tags_l']
            let $TAGS_PATH = $TAGS_PATH . l:idx . ','
        endfor
        if s:ccve_debug == 'true'
            echo 'DEBUG: $TAGS_PATH:' . $TAGS_PATH
        endif
        echo ':set tags=' . $TAGS_PATH
        :set tags=$TAGS_PATH 

        if s:ccve_debug == 'true'
            echo 'DEBUG: tags_l info:' 
            echo s:ccve_vars['setting']['tags_l']
        endif
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "cscope setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    let l:symbs_c = s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name . s:ccve_vars[s:os]['slash'] . 'cscope.out'
    if filereadable (l:symbs_c) == 0
        echomsg 'Cscope.out not found'
    else
        "if cscope.out already set, do nothing
        for l:idx in keys(s:ccve_vars['setting']['cscope.out_l'][1])
            "get dir name:
            "eg: 
            "   l:idx = '/home/user/.symbs/boost/cscope.out'
            "   l:cmp_s = boost

            "remove '/cscope.out'
            let l:cscope_d = s:ccve_vars['setting']['cscope.out_l'][1]
            let l:cmp_s = substitute(l:cscope_d[l:idx], '\' . s:ccve_vars[s:os]['slash'] . 'cscope.out', '', 'g')
            "remove '/home/user/.symbs/'
            let l:cmp_s = substitute(l:cmp_s, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')

            if s:ccve_debug == 'true'
                echo 'DEBUG: l:cmp_s:' . l:cmp_s
                echo 'DEBUG: l:name:' . l:name
            endif

            if l:cmp_s == l:name
                "cscope.out alread set
                break
            endif
        endfor
        if l:cmp_s != l:name
            "cscope.out not alread set
            if s:ccve_debug == 'true'
                echo 'l:symbs_c:' . l:symbs_c
            endif
            "add record to list assume dict is not empty
            for l:idx in keys(s:ccve_vars['setting']['cscope.out_l'][1])
                if s:ccve_vars['setting']['cscope.out_l'][1][l:idx] == 'noused'
                    let s:ccve_vars['setting']['cscope.out_l'][1][l:idx] = l:symbs_c
                    break
                endif
                "there is no noused slot
                if s:ccve_vars['setting']['cscope.out_l'][0]['idx'] == l:idx
                    let l:pos = s:ccve_vars['setting']['cscope.out_l'][0]['idx']
                    let s:ccve_vars['setting']['cscope.out_l'][0]['idx'] = l:pos + 1
                    let s:ccve_vars['setting']['cscope.out_l'][1][l:pos + 1] = l:symbs_c
                endif
            endfor
            "cscope.out dict is empty (first add)
            "if empty(s:ccve_vars['setting']['cscope.out_l'][1])
            "    let s:ccve_vars['setting']['cscope.out_l'][1][0] = l:symbs_c
            "    let s:ccve_vars['setting']['cscope.out_l'][0]['idx'] = l:cpos + 1
            "endif
            let $CSCOPE_DB = l:symbs_c
            echo ':cscope add ' . $CSCOPE_DB
            :cs add $CSCOPE_DB
        else
            "cscope.out alread set
            echomsg 'Database [' . l:symbs_c  . ']' . ' already added'
        endif
        call DevLogOutput ("s:ccve_vars['setting']['cscope.out_l']", s:ccve_vars['setting']['cscope.out_l'])
    endif
endfunction

"-----------------------------------------------------------------
"Delete symbs from environment
function! DelSymbs (symbs, rm)
    if a:symbs == ""
        return 'false'
    endif
    "get directory name
    let l:name  = substitute(a:symbs, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "tags setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""

    "tags full path
    let l:symbs_t = s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name . s:ccve_vars[s:os]['slash'] . 'tags'

    "if tags database path already set, do nothing
    let l:loopIdx = 0
    for l:idx in s:ccve_vars['setting']['tags_l']
        "get dir name:
        "eg: 
        "   l:idx = '/home/user/.symbs/boost/tags'
        "   l:cmp_s = boost

        "remove '/tags'
        let l:cmp_s = substitute(l:idx, '\' . s:ccve_vars[s:os]['slash'] . 'tags', '', 'g')
        "remove '/home/user/.symbs/'
        let l:cmp_s = substitute(l:cmp_s, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')

        if s:ccve_debug == 'true'
            echo 'DEBUG: l:cmp_s:' . l:cmp_s
            echo 'DEBUG: l:name:' . l:name
        endif

        if l:cmp_s == l:name
            "if tags name exist remove it
            unlet s:ccve_vars['setting']['tags_l'][l:loopIdx]
            break
        endif
        let l:loopIdx = l:loopIdx + 1
    endfor
    "tags name not set
    if l:cmp_s != l:name
        echomsg 'Tags ' . l:symbs_t . ' not set'
    endif
    if s:ccve_debug == 'true'
        echo 'DEBUG: tags_l info:' 
        echo s:ccve_vars['setting']['tags_l']
    endif

    let $TAGS_PATH = ''
    for l:idx in s:ccve_vars['setting']['tags_l']
        let $TAGS_PATH = $TAGS_PATH . l:idx . ','
    endfor
    if s:ccve_debug == 'true'
        echo 'DEBUG: $TAGS_PATH:' . $TAGS_PATH
    endif
    echo ':set tags=' . $TAGS_PATH
    :set tags=$TAGS_PATH 

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "cscope setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    let l:symbs_c = s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name . s:ccve_vars[s:os]['slash'] . 'cscope.out'
    "if cscope.out already set, do nothing
    for l:idx in keys(s:ccve_vars['setting']['cscope.out_l'][1])
        "get dir name:
        "eg: 
        "   l:idx = '/home/user/.symbs/boost/cscope.out'
        "   l:cmp_s = boost

        "remove '/cscope.out'
        let l:cscope_d = s:ccve_vars['setting']['cscope.out_l'][1]
        let l:cmp_s = substitute(l:cscope_d[l:idx], '\' . s:ccve_vars[s:os]['slash'] . 'cscope.out', '', 'g')
        "remove '/home/user/.symbs/'
        let l:cmp_s = substitute(l:cmp_s, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')

        if s:ccve_debug == 'true'
            echo 'DEBUG: l:cmp_s:' . l:cmp_s
            echo 'DEBUG: l:name:' . l:name
        endif

        if l:cmp_s == l:name
            "cscope.out alread set, remove it
            echo 'exec :cs kill ' . l:idx
            exec ':cs kill ' . l:idx
            "remove from table
            let s:ccve_vars['setting']['cscope.out_l'][1][l:idx] = 'noused'
            break
        endif
    endfor
    if s:ccve_debug == 'true'
        echo 'DEBUG: tags_l info:' 
        echo s:ccve_vars['setting']['cscope.out_l']
    endif
    if l:cmp_s != l:name
        "cscope.out not alread set
        echomsg 'Database [' . l:symbs_c  . ']' . ' not set'
    endif
    call DevLogOutput ("s:ccve_vars['setting']['cscope.out_l']", s:ccve_vars['setting']['cscope.out_l'])

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "remove directory
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    if a:rm == 'true'
        if s:ccve_debug == 'true'
            echo 'remove '. s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name  . 'line from .env'
        endif
        let l:l = ReadConfig(s:ccve_vars[s:os]['env_f'])
        let l:loopIdx = 0
        for l:idx in l:l
            let l:cmp_s = substitute(l:idx, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')
            if l:cmp_s == l:name
                unlet l:l[l:loopIdx]
                break
            endif
            let l:loopIdx = l:loopIdx + 1
        endfor
        call writefile (l:l, s:ccve_vars[s:os]['env_f'])
        if s:ccve_debug == 'true'
            echo 'rm -rf ' . s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name
        endif
        if has ('win32')
            echo system('rd /S /q ' . s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name)
        else
            echo system('rm -rf ' . s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name)
        endif
        :close!
        call EnvConfig (ReadConfig(s:ccve_vars[s:os]['env_f']))
    endif
endfunction
"-----------------------------------------------------------------

"-----------------------------------------------------------------
"Generate tags files
function! ExecCtags (list)
    if (!executable ('ctags'))
        return 'false'
    endif
    let l:cmd = 'ctags -f ' 
                \. s:ccve_vars[s:os]['HOME'] 
                \. s:ccve_vars[s:os]['slash'] 
                \. substitute(getcwd (), '^.*' . s:ccve_vars[s:os]['slash'], '', 'g') 
                \. s:ccve_vars[s:os]['slash'] . 'tags ' 
                \. '-R --c++-kinds=+p --fields=+aiS --extra=+q --tag-relative=no' 
                \. ' -L ' 
                \. s:ccve_vars[s:os]['list_f']

    if 'false' == MakeDirP(s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . substitute(getcwd (), '^.*' . s:ccve_vars[s:os]['slash'], '', 'g'))
        echomsg 'Failed to create directory ' . s:ccve_vars[s:os]['HOME'] . '/' . substitute (getcwd (), '^.*' . s:ccve_vars[s:os]['slash'], '', 'g') . (MakeDirP returned false)'
        return 'false'
    endif
    echo l:cmd
    echo system (l:cmd)
    return 'true'
endfunction
"-----------------------------------------------------------------
"Generate cscope files
function! ExecCscope (list)
    if (!executable ('cscope'))
        return 'false'
    endif
    let l:cmd = 'cscope' 
                \. ' ' 
                \. '-Rbk' 
                \. ' ' 
                \. '-i' 
                \. ' ' 
                \. s:ccve_vars[s:os]['list_f'] 
                \. ' ' 
                \. '-f' 
                \. ' ' 
                \. s:ccve_vars[s:os]['HOME'] 
                \. s:ccve_vars[s:os]['slash']
                \. substitute(getcwd (), '^.*' . s:ccve_vars[s:os]['slash'], '', 'g') 
                \. s:ccve_vars[s:os]['slash']
                \. 'cscope.out' 
    echo l:cmd
    echo system (l:cmd)
    return 'true'
endfunction

"-----------------------------------------------------------------
"Generate file list
function! MakeList (dir)
    if 'true' == MakeDirP (s:ccve_vars[s:os]['HOME'])
        let l:cmd = g:ccve_funs.ListCmd[s:os](a:dir)
        echomsg l:cmd
        let l:list = system (l:cmd)
        call writefile (split(l:list), s:ccve_vars[s:os]['list_f'])
        "redir @a | silent! echo l:list | redir END
        if input ('System Prompt: Do you want to view file list?  Press [y] yes [any key to continue] no : ') == "y"
            "echo @a
            echo l:list
        endif
    endif
    return l:list
endfunction

"-----------------------------------------------------------------
"Generate shell command
function! g:ccve_funs.ListCmd['win32'] (dir) dict
    let l:cmd = 'dir'
    let l:cmd = l:cmd . ' ' . getcwd () . '\' . s:postfix[1]
    for l:idx in s:postfix
        let l:cmd = l:cmd . ' ' . getcwd () . '\' . l:idx
    endfor
    "remove all '"'
    let l:cmd = substitute(l:cmd, '"', '', 'g')
    let l:cmd = l:cmd . ' /b /s'
    return l:cmd
endfunction

"-----------------------------------------------------------------
"Generate shell command
function! g:ccve_funs.ListCmd['unix'] (dir) dict
    "let l:cmd = '!' . 'find'
    let l:cmd = 'find'
    let l:cmd = l:cmd . ' ' . a:dir . ' ' . '-name'. ' ' . s:postfix[1]
    for l:idx in s:postfix
        let l:cmd = l:cmd . ' ' . '-o -name' . ' ' . l:idx
    endfor
    return l:cmd
endfunction

"-----------------------------------------------------------------
"Create directory
function! MakeDirP (path)
    if !isdirectory (a:path)
        "vim feature exam 
        if !exists ('*mkdir')
            echomsg 'mkdir: this version vim is not support mkdir, ' . 
                        \'please recompile vim or create director yourself: ' . 
                        \a:path 
            return 'false'
        endif
        "if mkdir (a:path, 'p') != 0
        if mkdir (a:path) != 0
            return 'true'
        else
            return 'false'
        endif
    endif
    return 'true'
endfunction

"-----------------------------------------------------------------
"Read records from record file and remove invalid data {{{
function! ReadConfig (env_f)
    let l:l = []
    if !filereadable (a:env_f)
        return l:l
    endif

    let l:l = readfile (a:env_f)
    if filereadable (a:env_f)
        if !empty (l:l)
            for i in l:l
                "Current directory name
                let l:name = substitute(i, '^.*/', '', 'g')  
                if !filereadable (s:ccve_vars[s:os]['HOME'] . '/' . l:name . '/tags') 
                            \&& !filereadable (s:ccve_vars[s:os]['HOME'] . '/' . l:name . '/cscope.out')
                    "Remove record from record_list
                    call filter (l:l, 'v:val !~ ' . "'" . i . "'")
                endi
            endfor
        endif
        "Write record back
        call writefile (l:l, a:env_f)
    else
        echomsg 'Not found any database record.'
    endif
    return l:l
endfunction
"}}}

"-----------------------------------------------------------------
"Write a new record to file {{{
function! WriteConfig (env_f, newline)
    if a:env_f == '' 
        return 'false'
    endif

    let l:append_l = [a:newline]
    if filereadable (a:env_f)
        let l:update_l = readfile (a:env_f)
    else
        let l:update_l = []
    endif
    for i in l:update_l
        if i == a:newline
            return 'true'
        endif
    endfor
    call extend (l:update_l, l:append_l)
    call writefile (l:update_l, a:env_f)
    return 'true'
endfunction
"}}}

"-----------------------------------------------------------------
"Show list window {{{
function! EnvConfig (l)
    let l:bname = "Help -- [a] Add to environment [d] Delete from environment [D] Delete from environment and remove conspond files"
    let l:winnum =  bufwinnr (l:bname)
    "If the list window is open
    if l:winnum != -1
        if winnr() != winnum
            " If not already in the window, jump to it
            exe winnum . 'wincmd w'
        endif
        "Focuse alread int the list window
        "Close window and start a new
        :q!
    endi
    
    setlocal modifiable
    " Open a new window at the bottom
    exe 'silent! botright ' . 8 . 'split ' . l:bname
    0put = a:l

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    normal! gg
    setlocal nomodifiable

    " Create a mapping to jump to the file
    nnoremap <buffer><silent>a :call AddSymbs(getline('.')) <CR>
    nnoremap <buffer><silent><CR> :call AddSymbs(getline('.')) <CR>
    nnoremap <buffer><silent>d :call DelSymbs(getline('.'), 'false') <CR>
    nnoremap <buffer><silent>D :call DelSymbs(getline('.'), 'true') <CR>
    "nnoremap <buffer><silent><ESC> :close!<CR>
endfunction
"}}}

"-----------------------------------------------------------------
"Synchronize source
function! SynchronizeSource ()
    let l:l = MakeList (getcwd ())
    if (empty(l:l))
        let l:output_msg = 'There is no any files found in patten:'
        for l:idx in s:postfix
            let l:output_msg = l:output_msg . ' ' . '[' . l:idx . ']'
        endfor
        echomsg l:output_msg
        return 'false'
    endif

    let l:res_t = ExecCtags (l:l)
    if l:res_t  == 'false'
        echomsg 'Failed to generate ctags database.'
    endif

    let l:res_c = ExecCscope (l:l)
    if l:res_c == 'false'
        echomsg 'Failed to generate cscope database.'
    endif

    if l:res_t == 'true' || l:res_c == 'true'
        echo s:ccve_vars[s:os]['env_f']
        call WriteConfig (s:ccve_vars[s:os]['env_f'], getcwd ())
    endif
endfunction

"-----------------------------------------------------------------
" Log the supplied debug message along with the time
function! DevLogOutput (msg, list)
    if s:ccve_debug == 'true'
        if 'true' == 'true'
            exec 'redir >> ' . $HOME . '/ccvext.vim.log'
            silent echo 'DEBUG: ' . strftime('%H:%M:%S') . ': ' . a:msg . ' : ' . string(a:list)
            redir END
        endif
        echo 'DEBUG: ' . strftime('%H:%M:%S') . ': ' . a:msg . ' : ' . string(a:list) . "\n"
    endif
endfunction

"-----------------------------------------------------------------
function! TestFuncE ()
    call EnvConfig (ReadConfig(s:ccve_vars[s:os]['env_f']))
endfunction

function! TestFuncS ()
    call SynchronizeSource ()
    call AddSymbs (getcwd ())
endfunction


"-----------------------------------------------------------------
if !exists(':CCS')
	command! -nargs=0 CCS :call TestFuncS()
endif

if !exists(':CCC')
	command! -nargs=0 CCC :call TestFuncE()
endif

"{{{Hotkey setup
:map <Leader>sy :call TestFuncS() <CR>
:map <Leader>sc :call TestFuncE() <CR>
"}}}

":au BufReadPre *.h echo 'run here'

"----------------------Not used-----------------------------------
function! AutoTraceTags (tag_s)
    if a:tag_s == ''
        return 'false'
    endif

    "save current window number
    let l:winnum = winnr ()

    "If the list window is open
    if bufwinnr('tag0_window') == -1
        "open tag0_window
        exec 'silent! botright ' . 8 . 'split ' . 'tag0_window'
        
        "open tag1_window
        "exec 'silent! rightbelow ' . 8 . 'split' . 'tag1_window'
    endif

    "jump to tag0_window
    exec 'silent!' . bufwinnr ('tag0_window') . ' wincmd w'

    let l:tags_l = taglist (a:tag_s)

    let l:put_l  = []
    for l:idx in l:tags_l
        call add (l:put_l, l:idx['filename'] . ' $' . l:idx['cmd'])
    endfor

    setlocal modifiable
    if winnr () == bufwinnr('tag0_window') || winnr () == bufwinnr('tag1_window')
        set number
        exec 'normal ggdG'
        0put = l:put_l
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    "setlocal noswapfile
    "setlocal nowrap
    "setlocal nobuflisted
    "normal! gg
    "setlocal nomodifiable

    " Create a mapping to jump to the file
    let $PATTON = 'aaaaaaaaaaaaaaaaaaaaaaaaa'
    nnoremap <buffer><silent><CR> :call Test1(getline('.'), $PATTON) <CR>
    "nnoremap <buffer><silent><ESC> :close! <CR>

    "move cursor to previous window
    exec 'silent!' . l:winnum . 'wincmd w'
    return 'true'
endfunction

function! Test1(line, cmd)
    echo a:cmd
    "save current window number
    "let l:winnum = winnr ()

    "jump to tag0_window
    exec 'silent!' . bufwinnr ('tag0_window') . ' wincmd w'
    "make sure cursor is in tag0_window
    if winnr () != bufwinnr('tag0_window')
        return 'false'
    endif

    "get file name
    let l:filename = substitute (a:line, ' \$.*$', '', 'g')
    "open tag1_window
    exec 'vertical bel split' . l:filename
    set number

    "get tags command
    let l:cmd_s = substitute(a:line, '^.* \$', '', 'g')
    "remove the first '/'
    let l:cmd_s = substitute(l:cmd_s, '^\/', '', 'g')
    "remove the last '/'
    let l:cmd_s = substitute(l:cmd_s, '\/$', '', 'g')
    "escape "
    let l:cmd_s = escape(l:cmd_s, '"')
    "escape *
    let l:cmd_s = escape(l:cmd_s, '*')
    "echo search (l:cmd_s)
    call cursor(search(l:cmd_s))

    "move cursor to previous window
    "exec 'silent!' . l:winnum . 'wincmd w'
    return 'true'
endfunction

function! GoToLine(mainbuffer)
   let linenumber = expand("<cword>")
   silent bd!
   silent execute "buffer" a:mainbuffer
   silent execute ":"linenumber
   silent nunmap <Enter>
endfunction
"command -nargs=1 GoToLine :call GoToLine(<f-args>)

function! GrepToBuffer(pattern)
   let mainbuffer = bufnr("%")
   silent %yank g

   enew
   silent put! g
   execute "%!egrep -n" a:pattern "| cut -b1-80 | sed 's/:/ /'"
   silent 1s/^/\="# Press Enter on a line to view it\n"/
   silent :2

   silent execute "nmap <Enter> 0:silent GoToLine" mainbuffer "<Enter>"
   silent nmap <C-G> <C-O>:bd!<Enter>
endfunction
"command -nargs=+ Grep :call GrepToBuffer(<q-args>)
"----------------------Not used-----------------------------------

"--------------------------------EOF---------------------------------
"
