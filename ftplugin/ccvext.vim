" Name:     ccvext.vim (ctags and cscope vim extends script)
" Brief:    Usefull tools reading code or coding
" Version:  3.0.2
" Date:     Sun Jan 24 02:50:48 2010
" Author:   Chen Zuopeng
" Email:    chenzuopeng@gmail.com
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
" TODO:     Auto generate ctags and cscope database, and easy to use.
"
" Usage:    This file should reside in the plugin directory and be
"           automatically sourced.
"
"           1. You can use "<Leader>sy" auto synchronize files from current directory recursively.
"           2. You can use "<Leader>sc" open config window.
"           3. You can use ":VTStart" command to start virual tags mode. Virtual tags mode over 
"              load hot key "<C_]>" and "<ESC>", a quite way snippet source.
"           4. You can use ":VTStop" command quite virutal tags mode
"                
" UPDATE:
"          2.0.0
"            Rewrite script the previous version is JumpInCode.vim
"          3.0.0
"            Fix bugs:
"              - Open and close config (<Leader>sc) window vim not focuses the old window 
"                when multi windows are opened.
"              - Fix a bug about the tips.
"
"            Add new feature
"              - Virtual tags is supported, a better way to use ctags. "<C_]>" and "<ESC>" is
"                over loaded.
"          3.0.1
"            Fix bugs:
"              - correct the cursor position when jump global value in snippet
"                window
"          3.0.2
"            Update comments
"
" HELP:    Who can tell me how to write a help doc?
"        

"Initialization {{{
if exists("g:ccvext_version")
    finish
else
    "set autowrite
    "set autoread
endif

" Check for Vim version 600 or greater
if v:version < 600
    echo "Sorry, ccvext" . g:ccvext_version. "\nONLY runs with Vim 6.0 and greater."
    finish
endif
"}}}

let g:ccvext_version = "2.10"

"Initialization local variable platform independence {{{

"let s:ccve_debug = 'true'
let s:ccve_debug = 'false'

let s:ccve_vars = {
            \'win32':{
                \'slash':'\', 'HOME':'\.symbs', 'list_f':'\.symbs\.list', 'env_f':'\.symbs\.env'
                \},
            \'unix':{
                \'slash':'/', 'HOME':$HOME . '/.symbs', 'list_f':$HOME . '/.symbs/.l', 'env_f':$HOME . '/.symbs/.evn'
                \},
            \'setting':{
                \'tags_l':['./tags'], 'cscope.out_l':[{'idx':0}, {0:'noused'}]
                \},
            \'tmp_variable':0
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

"support java, c and c++
let s:postfix = ['"*.java"', '"*.h"', '"*.c"', '"*.hpp"', '"*.cpp"', '"*.cc"']

"Check software environment {{{
if !executable ('ctags')
    echomsg 'ccvext: Exuberant ctags (http://ctags.sf.net) ' .
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
        let l:l = LoadConfigData(s:ccve_vars[s:os]['env_f'])
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
            echo system('rd /S /Q ' . s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name)
        else
            echo system('rm -rf ' . s:ccve_vars[s:os]['HOME'] . s:ccve_vars[s:os]['slash'] . l:name)
        endif
        :close!
        call OpenConfigWnd (LoadConfigData(s:ccve_vars[s:os]['env_f']))
    endif
endfunction
"-----------------------------------------------------------------
"
function! DelCscopeSymbs (symbs)
    let l:name  = substitute(a:symbs, '^.*' . s:ccve_vars[s:os]['slash'], '', 'g')
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
endfunction

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
    call DelCscopeSymbs (getcwd ())
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
        else
            echo " "
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
        if mkdir (a:path, 'p') != 0
        "if mkdir (a:path) != 0
            return 'true'
        else
            return 'false'
        endif
    endif
    return 'true'
endfunction

"-----------------------------------------------------------------
"Read records from record file and remove invalid data {{{
function! LoadConfigData (env_f)
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
"Close config window
function! CloseConfigWnd ()
    :close!
    if s:ccve_vars['tmp_variable'] != -1
        exe s:ccve_vars['tmp_variable'] . 'wincmd w'
        let s:ccve_vars['tmp_variable'] = -1
    endif
endfunction

"Show config window {{{
function! OpenConfigWnd (arg)
    let l:bname = "Help -- [a] Add to environment [d] Delete from environment [D] Delete from environment and remove conspond files"
    let s:ccve_vars['tmp_variable'] = winnr ()
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
    0put = a:arg

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
    nnoremap <buffer><silent><ESC> :call CloseConfigWnd() <CR>
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
function! ConfigSymbs ()
    call OpenConfigWnd (LoadConfigData(s:ccve_vars[s:os]['env_f']))
endfunction

function! SyncSymbs ()
    call SynchronizeSource ()
    call AddSymbs (getcwd ())
endfunction


"-----------------------------------------------------------------
if !exists(':CCS')
	command! -nargs=0 CCS :call SyncSymbs()
endif

if !exists(':CCC')
	command! -nargs=0 CCC :call ConfigSymbs()
endif

if !exists(':VTStart')
	command! -nargs=0 VTStart :call VTStartImpl ()
endif

if !exists(':VTStop')
	command! -nargs=0 VTStop :call VTStopImpl ()
endif

"{{{Hotkey setup
:map <Leader>sy :call SyncSymbs() <CR>
:map <Leader>sc :call ConfigSymbs() <CR>
"}}}

":au BufReadPre *.h echo 'run here'

"--------------------------Not used-----------------------------------
function! VTStartImpl ()
    "ctags is necessary
    if !executable ('ctags')
        echomsg 'ctags error(ctags is necessary): ' . 
                    \'Exuberant ctags (http://ctags.sf.net) ' .
                    \ 'not found in PATH. Plugin is not full loaded.'
        return 'false'
    endif
    :map <C-]> : call AutoTraceTags(expand('<cfile>')) <CR>
    "if !has ('win32')
    "    set mouse=a
    "endif
endfunction

function! VTStopImpl ()
    "if !has ('win32')
    "    set mouse=
    "endif

    :unmap <C-]>

    "exec 'silent' . bufwinnr(getwinvar(bufwinnr(s:deamon_wnd), 'snippet_wnd')) . ' wincmd w'
    "if winnr () == bufwinnr(getwinvar(bufwinnr(s:deamon_wnd), 'snippet_wnd'))
    "    close!
    "endif

    "exec 'silent!' . bufwinnr (s:deamon_wnd) . ' wincmd w'
    "if winnr () == bufwinnr(s:deamon_wnd)
    "    close!
    "endif
endfunction

"-----------------------------------------------------------------
function! AutoTraceTags (tag_s)
    "ctags is necessary
    if !executable ('ctags')
        return 'false'
    endif

    if a:tag_s == ''
        return 'false'
    endif

    "let s:deamon_wnd = 'Help Press entern to view source snippet'
    let s:deamon_wnd = 'Help'

    "save current window number
    let l:winnum = winnr ()

    "If the list window is open
    if bufwinnr(s:deamon_wnd) == -1
        "open s:deamon_wnd
        exec 'silent! botright ' . 10 . 'split ' . s:deamon_wnd
        "local buffer initial
        let w:snippet_wnd = -1 
        let w:main_wnd    = l:winnum
    endif

    "jump to s:deamon_wnd
    exec 'silent!' . bufwinnr (s:deamon_wnd) . ' wincmd w'

    let s:tags_l = taglist (a:tag_s)
    "echo s:tags_l

    let l:put_l  = []
    for l:idx in s:tags_l
        call add (l:put_l, l:idx['filename'])
    endfor

    setlocal modifiable
    if winnr () == bufwinnr(s:deamon_wnd)
        set number
        exec 'normal ggdG'
        0put = l:put_l
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    normal!  gg
    setlocal nomodifiable

    " Create a mapping to jump to the file
    nnoremap <buffer><silent><CR> :call SourceSnippet() <CR>
    nnoremap <buffer><silent><ESC> :call <SID>MagicFunc1 ()<CR>
    "nnoremap <buffer><2-LeftMouse> :call SourceSnippet()<CR>

    "move cursor to previous window
    "exec 'silent!' . l:winnum . 'wincmd w'
    return 'true'
endfunction

function! SourceSnippet()
    "jump to s:deamon_wnd window
    exec 'silent!' . bufwinnr (s:deamon_wnd) . ' wincmd w'
    "make sure cursor is in s:deamon_wnd
    if winnr () != bufwinnr(s:deamon_wnd)
        "Error window status
        call DevLogOutput ('SystemError:', 'Error window status')
        return
    endif

    if -1 == bufwinnr(s:deamon_wnd)
        "Unhandled error occur.
        call DevLogOutput ('SystemError:', 'Unhandled error occur')
        return 
    endif

    let l:new_line = getline('.')
    exec 'silent!' . ' ' . getwinvar(bufwinnr(s:deamon_wnd), 'snippet_wnd') . ' wincmd w'
    echo 'exec ' . 'silent!' . ' ' . getwinvar(bufwinnr(s:deamon_wnd), 'snippet_wnd') . ' wincmd w'

    if winnr() != getwinvar(bufwinnr(s:deamon_wnd), 'snippet_wnd')
        exec 'silent!' . bufwinnr (s:deamon_wnd) . ' wincmd w'
        exec 'vertical bel split' . ' ' . l:new_line
        "setlocal buftype=nofile
        "setlocal bufhidden=delete
        "setlocal noswapfile
        "setlocal nowrap
        "setlocal nobuflisted
        "setlocal nomodifiable
    endif

    "open source code
    exec 'e' . ' ' . l:new_line
    call setwinvar (bufwinnr(s:deamon_wnd), 'snippet_wnd', bufwinnr(l:new_line))
    nnoremap <buffer><silent><ESC> :call <SID>MagicFunc0 () <CR>
    nnoremap <buffer><silent><Enter> :call <SID>MagicFunc2 () <CR>
    set number

    let l:cmd_s = 'v_null'
    for l:idx in s:tags_l
        if l:idx['filename'] == l:new_line
            let l:cmd_s = matchstr(l:idx['cmd'], '\^.*\$')
            if l:cmd_s == ''
                let l:cmd_s = matchstr(l:idx['name'], '.*')
            endif
        endif
    endfor
    let l:cmd_s = escape(escape(l:cmd_s, '*'), '"')

    "echo l:cmd_s
    call search (l:cmd_s)
endfunction

fu! <SID>MagicFunc0 ()
    exec 'silent!' . ' ' . bufwinnr(s:deamon_wnd) . ' wincmd w'
endf

fu! <SID>MagicFunc1 ()
    let l:nu = getwinvar(bufwinnr(s:deamon_wnd), 'main_wnd')
    exec 'silent!' . ' ' l:nu . ' wincmd w'
endf

fu! <SID>MagicFunc2 ()
    let l:bufnr = bufnr ('%')
    call setwinvar (bufwinnr(s:deamon_wnd), 'snippet_wnd', '-1')
    exec 'close!'
    exec getwinvar(bufwinnr(s:deamon_wnd), 'main_wnd') . ' wincmd w'
    exec 'b' . ' ' . l:bufnr
    nmapclear <buffer>
endf

function! GoToLine(mainbuffer)
   let linenumber = expand("<cword>")
   silent bd!
   silent execute "buffer" a:mainbuffer
   silent execute ":"linenumber
   nunmap <Enter>
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

"--------------------------------EOF---------------------------------
