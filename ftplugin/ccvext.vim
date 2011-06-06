" Name:     ccvext.vim (ctags and cscope vim extends script)
" Brief:    Usefull tools reading code or coding
" Version:  4.0.0
" Date:     Sun Jan 24 02:50:48 2010
" Author:   Chen Zuopeng (EN: Daniel Chen)
" Email:    chenzuopeng@gmail.com
"
" License:  Public domain, no restrictions whatsoever
"
" Copyright:Copyright (C) 2009-2010 Chen Zuopeng {{{
"           Permission is hereby granted to use and distribute this code,
"           with or without modifications, provided that this copyright
"           notice is copied with it. Like anything else that's free,
"           ccvext.vim is provided *as is* and comes with no
"           warranty of any kind, either expressed or implied. In no
"           event will the copyright holder be liable for any damages
"           resulting from the use of this software. 
"           }}}
" Todo:     Auto generate ctags and cscope database, and easy to use {{{
"           }}}
" Usage:    This file should reside in the plugin directory and be {{{
"           automatically sourced.
"           You may use the default keymappings of
"
"             <Leader>sy         - Auto synchronize files from current directory recursively.
"             <Leader>sc         - Opens config window
"
"             Command: "EnQuickSnippet" - Start source snippet (a better way to use ctags)
"             Command: "DiQuickSnippet" - Stop source snippet (a better way to use ctags) 
"           }}}
" UPDATE:   4.0.0 {{{
"             Descript :
"               - Rename commands name
"               - Auto update source snippet window
"           3.0.1
"             Fix bugs :
"               - correct the cursor position when jump global value in snippet window 
"           3.0.0
"             New Feature :
"               - Virtual tag is support, a better way to use ctags. CTRL_] is
"                 over writen.
"
"             Fix bugs :
"               - Open and close config (<Leader>sc) window vim not focuses the old window 
"                 when multi windows are opened.
"               - Fix a bug about the tips.
"           2.0.0 
"             Rewrite script the previous is JumpInCode.vim
"           }}}
"---------------------------------------------------------------------------------------------
"-------------------------------------------CCVEXT--------------------------------------------
"---------------------------------------------------------------------------------------------
"Development setting {{{
let s:debug_flg = 'false'

if s:debug_flg == 'false'
    "if exists("g:ccvext_version")
    "    finish
    "endif
else
    "null
endif
"}}}

" Check for Vim version 600 or greater {{{
let g:ccvext_version = "4.0.0"

if v:version < 600
    echo "Sorry, ccvext" . g:ccvext_version. "\nONLY runs with Vim 6.0 and greater."
    finish
endif
"}}}

"Global value declears {{{
let s:functions = {'_command':{}}
"let s:symbs_dir_name = '.symbs'
"}}}

"Initialization local variable platform independence {{{
let s:platform_inde = {
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
"}}}

"Platform check {{{
if has ('win32')
    let s:platform = 'win32'
else
    let s:platform = 'unix'
endif
"}}}

"support postfix list {{{
let s:postfix = ['"*.java"', '"*.h"', '"*.c"', '"*.hpp"', '"*.cpp"', '"*.cc"']
"}}}

"Check software environment {{{
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

"Add symbs to environment {{{
function! AddSymbs (symbs)
    if a:symbs == ""
        return 'false'
    endif
    "get directory name
    let l:name  = substitute(a:symbs, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')
    let l:cmp_s = ""

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "tags setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    "tags full path
    let l:symbs_t = s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name . s:platform_inde[s:platform]['slash'] . 'tags'

    echo l:symbs_t

    if filereadable (l:symbs_t) == 0
        echomsg 'Tags not found'
    else
        "if tags database path already set, do nothing
        for l:idx in s:platform_inde['setting']['tags_l']
            "get dir name:
            "eg: 
            "   l:idx = '/home/user/.symbs/boost/tags'
            "   l:cmp_s = boost

            "remove '/tags'
            let l:cmp_s = substitute(l:idx, '\' . s:platform_inde[s:platform]['slash'] . 'tags', '', 'g')
            "remove '/home/user/.symbs/'
            let l:cmp_s = substitute(l:cmp_s, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

            if s:debug_flg == 'true'
                echo 'debug_flg: l:cmp_s:' . l:cmp_s
                echo 'debug_flg: l:name:' . l:name
            endif

            if l:cmp_s == l:name
                "tags name alread set
                break
            endif
        endfor
        "tags name not set
        if l:cmp_s != l:name
            if s:debug_flg == 'true'
                echo 'debug_flg: add new tags' . l:symbs_t
            endif
            call add (s:platform_inde['setting']['tags_l'], l:symbs_t)
        else
            if s:debug_flg == 'true'
                echo 'debug_flg: tags:' . l:symbs_t . ' already set.'
            endif
        endif

        let $TAGS_PATH = ''
        for l:idx in s:platform_inde['setting']['tags_l']
            let $TAGS_PATH = $TAGS_PATH . l:idx . ','
        endfor
        if s:debug_flg == 'true'
            echo 'debug_flg: $TAGS_PATH:' . $TAGS_PATH
        endif
        echo ':set tags=' . $TAGS_PATH
        :set tags=$TAGS_PATH 

        if s:debug_flg == 'true'
            echo 'debug_flg: tags_l info:' 
            echo s:platform_inde['setting']['tags_l']
        endif
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "cscope setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    let l:symbs_c = s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name . s:platform_inde[s:platform]['slash'] . 'cscope.out'
    if filereadable (l:symbs_c) == 0
        echomsg 'Cscope.out not found'
    else
        "if cscope.out already set, do nothing
        for l:idx in keys(s:platform_inde['setting']['cscope.out_l'][1])
            "get dir name:
            "eg: 
            "   l:idx = '/home/user/.symbs/boost/cscope.out'
            "   l:cmp_s = boost

            "remove '/cscope.out'
            let l:cscope_d = s:platform_inde['setting']['cscope.out_l'][1]
            let l:cmp_s = substitute(l:cscope_d[l:idx], '\' . s:platform_inde[s:platform]['slash'] . 'cscope.out', '', 'g')
            "remove '/home/user/.symbs/'
            let l:cmp_s = substitute(l:cmp_s, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

            if s:debug_flg == 'true'
                echo 'debug_flg: l:cmp_s:' . l:cmp_s
                echo 'debug_flg: l:name:' . l:name
            endif

            if l:cmp_s == l:name
                "cscope.out alread set
                break
            endif
        endfor
        if l:cmp_s != l:name
            "cscope.out not alread set
            if s:debug_flg == 'true'
                echo 'l:symbs_c:' . l:symbs_c
            endif
            "add record to list assume dict is not empty
            for l:idx in keys(s:platform_inde['setting']['cscope.out_l'][1])
                if s:platform_inde['setting']['cscope.out_l'][1][l:idx] == 'noused'
                    let s:platform_inde['setting']['cscope.out_l'][1][l:idx] = l:symbs_c
                    break
                endif
                "there is no noused slot
                if s:platform_inde['setting']['cscope.out_l'][0]['idx'] == l:idx
                    let l:pos = s:platform_inde['setting']['cscope.out_l'][0]['idx']
                    let s:platform_inde['setting']['cscope.out_l'][0]['idx'] = l:pos + 1
                    let s:platform_inde['setting']['cscope.out_l'][1][l:pos + 1] = l:symbs_c
                endif
            endfor
            "cscope.out dict is empty (first add)
            "if empty(s:platform_inde['setting']['cscope.out_l'][1])
            "    let s:platform_inde['setting']['cscope.out_l'][1][0] = l:symbs_c
            "    let s:platform_inde['setting']['cscope.out_l'][0]['idx'] = l:cpos + 1
            "endif
            let $CSCOPE_DB = l:symbs_c
            echo ':cscope add ' . $CSCOPE_DB
            :cs add $CSCOPE_DB
        else
            "cscope.out alread set
            echomsg 'Database [' . l:symbs_c  . ']' . ' already added'
        endif
        call DevLogOutput ("s:platform_inde['setting']['cscope.out_l']", s:platform_inde['setting']['cscope.out_l'])
    endif
endfunction
"}}}

"Delete symbs from environment {{{
function! DelSymbs (symbs, rm)
    if a:symbs == ""
        return 'false'
    endif
    "get directory name
    let l:name  = substitute(a:symbs, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "tags setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""

    "tags full path
    let l:symbs_t = s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name . s:platform_inde[s:platform]['slash'] . 'tags'

    "if tags database path already set, do nothing
    let l:loopIdx = 0
    for l:idx in s:platform_inde['setting']['tags_l']
        "get dir name:
        "eg: 
        "   l:idx = '/home/user/.symbs/boost/tags'
        "   l:cmp_s = boost

        "remove '/tags'
        let l:cmp_s = substitute(l:idx, '\' . s:platform_inde[s:platform]['slash'] . 'tags', '', 'g')
        "remove '/home/user/.symbs/'
        let l:cmp_s = substitute(l:cmp_s, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

        if s:debug_flg == 'true'
            echo 'debug_flg: l:cmp_s:' . l:cmp_s
            echo 'debug_flg: l:name:' . l:name
        endif

        if l:cmp_s == l:name
            "if tags name exist remove it
            unlet s:platform_inde['setting']['tags_l'][l:loopIdx]
            break
        endif
        let l:loopIdx = l:loopIdx + 1
    endfor
    "tags name not set
    if l:cmp_s != l:name
        echomsg 'Tags ' . l:symbs_t . ' not set'
    endif
    if s:debug_flg == 'true'
        echo 'debug_flg: tags_l info:' 
        echo s:platform_inde['setting']['tags_l']
    endif

    let $TAGS_PATH = ''
    for l:idx in s:platform_inde['setting']['tags_l']
        let $TAGS_PATH = $TAGS_PATH . l:idx . ','
    endfor
    if s:debug_flg == 'true'
        echo 'debug_flg: $TAGS_PATH:' . $TAGS_PATH
    endif
    echo ':set tags=' . $TAGS_PATH
    :set tags=$TAGS_PATH 

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "cscope setting
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    let l:symbs_c = s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name . s:platform_inde[s:platform]['slash'] . 'cscope.out'
    "if cscope.out already set, do nothing
    for l:idx in keys(s:platform_inde['setting']['cscope.out_l'][1])
        "get dir name:
        "eg: 
        "   l:idx = '/home/user/.symbs/boost/cscope.out'
        "   l:cmp_s = boost

        "remove '/cscope.out'
        let l:cscope_d = s:platform_inde['setting']['cscope.out_l'][1]
        let l:cmp_s = substitute(l:cscope_d[l:idx], '\' . s:platform_inde[s:platform]['slash'] . 'cscope.out', '', 'g')
        "remove '/home/user/.symbs/'
        let l:cmp_s = substitute(l:cmp_s, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

        if s:debug_flg == 'true'
            echo 'debug_flg: l:cmp_s:' . l:cmp_s
            echo 'debug_flg: l:name:' . l:name
        endif

        if l:cmp_s == l:name
            "cscope.out alread set, remove it
            echo 'exec :cs kill ' . l:idx
            exec ':cs kill ' . l:idx
            "remove from table
            let s:platform_inde['setting']['cscope.out_l'][1][l:idx] = 'noused'
            break
        endif
    endfor
    if s:debug_flg == 'true'
        echo 'debug_flg: tags_l info:' 
        echo s:platform_inde['setting']['cscope.out_l']
    endif
    if l:cmp_s != l:name
        "cscope.out not alread set
        echomsg 'Database [' . l:symbs_c  . ']' . ' not set'
    endif
    call DevLogOutput ("s:platform_inde['setting']['cscope.out_l']", s:platform_inde['setting']['cscope.out_l'])

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "remove directory
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let l:cmp_s = ""
    if a:rm == 'true'
        if s:debug_flg == 'true'
            echo 'remove '. s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name  . 'line from .env'
        endif
        let l:l = LoadConfigData(s:platform_inde[s:platform]['env_f'])
        let l:loopIdx = 0
        for l:idx in l:l
            let l:cmp_s = substitute(l:idx, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')
            if l:cmp_s == l:name
                unlet l:l[l:loopIdx]
                break
            endif
            let l:loopIdx = l:loopIdx + 1
        endfor
        call writefile (l:l, s:platform_inde[s:platform]['env_f'])
        if s:debug_flg == 'true'
            echo 'rm -rf ' . s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name
        endif
        if has ('win32')
            echo system('rd /S /Q ' . s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name)
        else
            echo system('rm -rf ' . s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name)
        endif
        :close!
        call OpenConfigWnd (LoadConfigData(s:platform_inde[s:platform]['env_f']))
    endif
endfunction
"}}}

"Delete cscope symbs {{{
function! DelCscopeSymbs (symbs)
    let l:name  = substitute(a:symbs, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')
    let l:cmp_s = ""
    let l:symbs_c = s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . l:name . s:platform_inde[s:platform]['slash'] . 'cscope.out'
    "if cscope.out already set, do nothing
    for l:idx in keys(s:platform_inde['setting']['cscope.out_l'][1])
        "get dir name:
        "eg: 
        "   l:idx = '/home/user/.symbs/boost/cscope.out'
        "   l:cmp_s = boost

        "remove '/cscope.out'
        let l:cscope_d = s:platform_inde['setting']['cscope.out_l'][1]
        let l:cmp_s = substitute(l:cscope_d[l:idx], '\' . s:platform_inde[s:platform]['slash'] . 'cscope.out', '', 'g')
        "remove '/home/user/.symbs/'
        let l:cmp_s = substitute(l:cmp_s, '^.*' . s:platform_inde[s:platform]['slash'], '', 'g')

        if s:debug_flg == 'true'
            echo 'debug_flg: l:cmp_s:' . l:cmp_s
            echo 'debug_flg: l:name:' . l:name
        endif

        if l:cmp_s == l:name
            "cscope.out alread set, remove it
            echo 'exec :cs kill ' . l:idx
            exec ':cs kill ' . l:idx
            "remove from table
            let s:platform_inde['setting']['cscope.out_l'][1][l:idx] = 'noused'
            break
        endif
    endfor
    if s:debug_flg == 'true'
        echo 'debug_flg: tags_l info:' 
        echo s:platform_inde['setting']['cscope.out_l']
    endif
    if l:cmp_s != l:name
        "cscope.out not alread set
        echomsg 'Database [' . l:symbs_c  . ']' . ' not set'
    endif
    call DevLogOutput ("s:platform_inde['setting']['cscope.out_l']", s:platform_inde['setting']['cscope.out_l'])
endfunction
"}}}

"Generate tags files {{{
function! ExecCtags (list)
    if (!executable ('ctags'))
        return 'false'
    endif
    let l:cmd = 'ctags -f ' 
                \. s:platform_inde[s:platform]['HOME'] 
                \. s:platform_inde[s:platform]['slash'] 
                \. substitute(getcwd (), '^.*' . s:platform_inde[s:platform]['slash'], '', 'g') 
                \. s:platform_inde[s:platform]['slash'] . 'tags ' 
                \. '-R --c++-kinds=+p --fields=+aiS --extra=+q --tag-relative=no' 
                \. ' -L ' 
                \. s:platform_inde[s:platform]['list_f']

    if 'false' == MakeDirP(s:platform_inde[s:platform]['HOME'] . s:platform_inde[s:platform]['slash'] . substitute(getcwd (), '^.*' . s:platform_inde[s:platform]['slash'], '', 'g'))
        echomsg 'Failed to create directory ' . s:platform_inde[s:platform]['HOME'] . '/' . substitute (getcwd (), '^.*' . s:platform_inde[s:platform]['slash'], '', 'g') . (MakeDirP returned false)'
        return 'false'
    endif
    echo l:cmd
    echo system (l:cmd)
    return 'true'
endfunction
"}}}

"Generate cscope files {{{
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
                \. s:platform_inde[s:platform]['list_f'] 
                \. ' ' 
                \. '-f' 
                \. ' ' 
                \. s:platform_inde[s:platform]['HOME'] 
                \. s:platform_inde[s:platform]['slash']
                \. substitute(getcwd (), '^.*' . s:platform_inde[s:platform]['slash'], '', 'g') 
                \. s:platform_inde[s:platform]['slash']
                \. 'cscope.out' 
    echo l:cmd
    call DelCscopeSymbs (getcwd ())
    echo system (l:cmd)
    return 'true'
endfunction
"}}}

"Generate file list {{{
function! MakeList (dir)
    if 'true' == MakeDirP (s:platform_inde[s:platform]['HOME'])
        let l:cmd = s:functions._command[s:platform](a:dir)
        echomsg l:cmd
        let l:list = system (l:cmd)
        call writefile (split(l:list), s:platform_inde[s:platform]['list_f'])
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
"}}}

"Generate shell command {{{
function! s:functions._command['win32'] (dir) dict
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
function! s:functions._command['unix'] (dir) dict
    "let l:cmd = '!' . 'find'
    let l:cmd = 'find'
    let l:cmd = l:cmd . ' ' . a:dir . ' ' . '-name'. ' ' . s:postfix[1]
    for l:idx in s:postfix
        let l:cmd = l:cmd . ' ' . '-o -name' . ' ' . l:idx
    endfor
    return l:cmd
endfunction
"}}}

"Create directory {{{
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
"}}}

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
                if !filereadable (s:platform_inde[s:platform]['HOME'] . '/' . l:name . '/tags') 
                            \&& !filereadable (s:platform_inde[s:platform]['HOME'] . '/' . l:name . '/cscope.out')
                    "Remove record from record_list
                    call filter (l:l, 'v:val !~ ' . "'" . i . "'")
                endif
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

"Close config window {{{
function! CloseConfigWnd ()
    :close!
    if s:platform_inde['tmp_variable'] != -1
        exe s:platform_inde['tmp_variable'] . 'wincmd w'
        let s:platform_inde['tmp_variable'] = -1
    endif
endfunction
"}}}

"Show config window {{{
function! OpenConfigWnd (arg)
    let l:bname = "Help -- [a] Add to environment [d] Delete from environment [D] Delete from environment and remove conspond files"
    let s:platform_inde['tmp_variable'] = winnr ()
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

    " Create a mapping to control the files
    nnoremap <buffer><silent><Enter> :call AddSymbs(getline('.')) <CR>
    nnoremap <buffer><2-LeftMouse>   :call AddSymbs(getline('.')) <CR>

    nnoremap <buffer><silent>a :call AddSymbs(getline('.'))          <CR>
    nnoremap <buffer><silent>d :call DelSymbs(getline('.'), 'false') <CR>
    nnoremap <buffer><silent>D :call DelSymbs(getline('.'), 'true')  <CR>
    "nnoremap <buffer><silent><ESC> :call CloseConfigWnd() <CR>
endfunction
"}}}

"Synchronize source {{{
function! SynchronizeSource (cur_dir)
    "let l:l = MakeList (getcwd ())
    let l:l = MakeList(a:cur_dir)

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
        echo s:platform_inde[s:platform]['env_f']
        call WriteConfig (s:platform_inde[s:platform]['env_f'], getcwd ())
    endif
endfunction
"}}}

" Log the supplied debug message along with the time {{{
function! DevLogOutput (msg, list)
    if s:debug_flg == 'true'
        if 'true' == 'true'
            exec 'redir >> ' . $HOME . '/ccvext.vim.log'
            silent echo 'debug_flg: ' . strftime('%H:%M:%S') . ': ' . a:msg . ' : ' . string(a:list)
            redir END
        endif
        echo 'debug_flg: ' . strftime('%H:%M:%S') . ': ' . a:msg . ' : ' . string(a:list) . "\n"
    endif
endfunction
"}}}

"Config Symbs {{{
function! ConfigSymbs ()
	call CloseSnippedWndAndListWndOnce ()
    call OpenConfigWnd (LoadConfigData(s:platform_inde[s:platform]['env_f']))
endfunction

function! SyncSource ()
	let l:base_directory = ""
	if has ("gui")
		let l:string = "Specified database base directory:"
		let l:string_len = strlen (l:string)
		let l:expr_len = strlen (getcwd ())
		let l:dlg_size = 0
		if l:expr_len > l:string_len
			let l:dlg_size = l:expr_len - l:string_len
		endif
		if l:dlg_size > 0
			for l:offset in range(l:dlg_size * 2)
				let l:string = l:string . ' '
			endfor
		endif
		let l:base_directory = inputdialog (l:string, getcwd ())
	else
		let l:base_directory = getcwd ()
	endif

	if has ("gui")
		try   | exec "lcd " . l:base_directory 
			\ | catch /.*/
			\ | echo "The directory [" . l:base_directory . "] not exist, Opeator canceled"
			\ | return 
			\ | endtry
	endif

	if l:base_directory != ""
		call SynchronizeSource (l:base_directory)
		call AddSymbs (l:base_directory)
	else
		echo "Operation canceled"
	endif
endfunction
"}}}

"Commands {{{
if !exists(':SyncSource')
	command! -nargs=0 SyncSource :call SyncSource()
endif

if !exists(':SymbsConfig')
	command! -nargs=0 SymbsConfig :call ConfigSymbs()
endif
"}}}

"Hotkey setting {{{
:map <Leader>sy :call SyncSource()   <CR>
:map <Leader>sc :call ConfigSymbs()  <CR>
"}}}
"---------------------------------------------------------------------------------------------
"---------------------------------------CCVEXT EXTEND-----------------------------------------
"---------------------------------------------------------------------------------------------
" default colors/groups {{{
hi default_hi_color ctermbg=Cyan ctermfg=Black guibg=#8CCBEA guifg=Black
"}}}
"
"Enable quick source snippet{{{
function! EnQuickSnippet ()
    "ctags is necessary
    if !executable ('ctags')
        echomsg 'ctags error(ctags is necessary): ' . 
                    \'Exuberant ctags (http://ctags.sf.net) ' .
                    \ 'not found in PATH. Plugin is not full loaded.'
        return 'false'
    endif

    call MarkWindow ('main_source_window_mark')
    
    :let s:update_time = 600
    :exe "set updatetime=" . string(s:update_time)
    
    :au! CursorHold * nested call AutoTagTrace ()
endfunction
"}}}
"
"Disable quick source snippet {{{
function! DiQuickSnippet ()
    :au! CursorHold
    ":call GoToMaredWindow (1, 'main_source_window_mark')
    "exec 'silent! wincmd o'
    "close source snippet list window
    if FindMarkedWindow (1, 'source_snippet_list_wnd') != 0
        if GoToMaredWindow (1, 'source_snippet_list_wnd') == 'true'
			:close!
		endif
    endif
    "close source snippet window 
    if FindMarkedWindow (1, 'source_snippet_wnd') != 0
        if GoToMaredWindow (1, 'source_snippet_wnd') == 'true'
			:close!
		endif
    endif

    call GoToMaredWindow (1, 'main_source_window_mark')
    call UnmarkWindow ()
endfunction
"}}}
"
"Cscope and ctags popup menu {{{
function! CscopeCtagsMenu ()
	call OtherPluginDetect ()

	if has ("win32") || has ("win64") 
				\ && exists (":tearoff")
		:tearoff Plugin.CCVimExt
	else
		echo "Command is not supported in this version of vim."
	endif
endfunction
"}}}
"
"Temp close snipped window and list window {{{
function! CloseSnippedWndAndListWndOnce ()
    if FindMarkedWindow (1, 'source_snippet_list_wnd') != 0
        if GoToMaredWindow (1, 'source_snippet_list_wnd') == 'true'
			:close!
		endif
    endif
    "close source snippet window 
    if FindMarkedWindow (1, 'source_snippet_wnd') != 0
        if GoToMaredWindow (1, 'source_snippet_wnd') == 'true'
			:close!
		endif
    endif

    call GoToMaredWindow (1, 'main_source_window_mark')
endfunction
"}}}
"
"Trace tags {{{
function! TagTrace (tag_s)
    "ctags is necessary
    if !executable ('ctags')
        return 'false'
    endif

    if a:tag_s == ''
        return 'false'
    endif
    "save current tag for hight light
    let s:current_tag = a:tag_s

    let s:src_snippet_list_wnd = 'source_snippet_list_wnd'

    "If the list window is open
    let l:marked_wnd_num = FindMarkedWindow (1, 'source_snippet_list_wnd')
    if l:marked_wnd_num == 0
        "open s:src_snippet_list_wnd
        exec 'silent! botright ' . 12 . 'split ' . s:src_snippet_list_wnd
        call MarkWindow ('source_snippet_list_wnd')
    endif

    if s:debug_flg == 'true'
        echo a:tag_s
    endif

    "let l:escaped_tag = escape(escape(escape(escape(a:tag_s, '*'), '"'), '~'), ':')
    "let s:tags_l = taglist (l:escaped_tag)
    let s:tags_l = taglist (escape(a:tag_s, '~'))

    "debug control
    if s:debug_flg == 'true'
        echo s:tags_l
    endif

    "jump to s:src_snippet_list_wnd
    :call GoToMaredWindow (1, 'source_snippet_list_wnd')

    "tags data list
    let l:put_l  = []

    "push tags data to list
    if empty (s:tags_l)
        "call add (l:put_l, 'No symbs found in tags: ' . &tags)
		let l:tag_list_file = tagfiles ()
		if empty (l:tag_list_file)
			call add (l:put_l, 'Tags is not set, please call :SyncSource or :SymbsConfig first')
		else
			call add (l:put_l, 'No symbs found in tags:')
			for l:single in l:tag_list_file
				call add (l:put_l, l:single)
			endfor
		endif
    else
        for l:idx in s:tags_l
            call add (l:put_l, l:idx['filename'])
        endfor
    endif

    "write data to buffer
    if winnr () == bufwinnr(s:src_snippet_list_wnd)
        setlocal modifiable
        set number
        1,$d _
        0put = l:put_l

		" Mark the buffer as scratch
    	setlocal buftype=nofile
    	setlocal bufhidden=delete
    	setlocal noswapfile
    	setlocal nowrap
    	setlocal nobuflisted
    	normal!  gg
    	setlocal nomodifiable
    endif

    " Create a mapping to jump to the file
    nnoremap <buffer><silent><CR>  :call SourceSnippet()<CR>
    nnoremap <buffer><2-LeftMouse> :call SourceSnippet()<CR>

    if empty (s:tags_l)
        "do nothing
    else
        call SourceSnippet ()
    endif
    "move cursor to previous window
    :call GoToMaredWindow (1, 'main_source_window_mark')
    return 'true'
endfunction
"}}}

"Auto trace tags {{{
function! AutoTagTrace ()
    "forcus on other window
    if winnr () == FindMarkedWindow (1, 'main_source_window_mark')
        call TagTrace (expand('<cfile>'))
        return
    endif
    if winnr () == FindMarkedWindow (1, 'source_snippet_list_wnd')
        if empty (s:tags_l)
        else
            call SourceSnippet ()
        endif
        return
    endif
endfunction
"}}}

"Source Snippet {{{
function! SourceSnippet()
    "jump to s:src_snippet_list_wnd window
    "exec 'silent!' . bufwinnr (s:src_snippet_list_wnd) . ' wincmd w'
    "make sure cursor is in s:src_snippet_list_wnd

    if winnr () != bufwinnr(s:src_snippet_list_wnd)
        "Error window status
        call DevLogOutput ('SystemError:', 'Error window status')
        return
    endif

    if -1 == bufwinnr(s:src_snippet_list_wnd)
        "Unhandled error occur.
        call DevLogOutput ('SystemError:', 'Unhandled error occur')
        return 
    endif

    let l:new_line = getline('.')

    if FindMarkedWindow (1, 'source_snippet_wnd') == 0
        "open s:src_snippet_list_wnd
        exec 'vertical bel split' . ' ' . l:new_line
        call MarkWindow ('source_snippet_wnd')
    else
        call GoToMaredWindow (1, 'source_snippet_wnd')
        "close!
        "exec 'vertical bel split' . ' ' . l:new_line
        "call MarkWindow ('source_snippet_wnd')
        exec 'e!' . ' ' . l:new_line
    endif

    if winnr () == FindMarkedWindow (1, 'source_snippet_wnd')
		setlocal buftype=nofile
		setlocal bufhidden=delete
		setlocal noswapfile
		setlocal nowrap
		setlocal nobuflisted
		setlocal nomodifiable
    endif

    nnoremap <buffer><silent><Enter> :call <SID>MagicFunc () <CR>
    nnoremap <buffer><2-LeftMouse> :call <SID>MagicFunc() <CR>
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
    let l:cmd_s = escape(escape(escape(escape(l:cmd_s, '*'), '"'), '~'), ':')

    "let l:cmd_s = '\\<' . l:cmd_s . '\\>'
    "echo l:cmd_s
    call search (l:cmd_s, 'w')

    normal zt
    redraw
    exe "windo syntax clear default_hi_color"
    exe "syntax match default_hi_color" . " '" . escape (s:current_tag, "~") . "' " . "containedin=.*"

    "go back to list window
    exec 'silent! ' . bufwinnr(s:src_snippet_list_wnd) . 'wincmd w'
endfunction
"}}}

"Magic Function {{{
fu! <SID>MagicFunc ()
    let l:bufnr = bufnr ('%')
	let l:current_line_nu = line ('.')
    call GoToMaredWindow (1, 'main_source_window_mark')
    exec 'b' . ' ' . l:bufnr
	exec ':' . l:current_line_nu
    "nmapclear <buffer>
endf
"}}}

"Command setting {{{
if !exists(':EnQuickSnippet')
	command! -nargs=0 EnQuickSnippet :call EnQuickSnippet ()
endif
if !exists(':DiQuickSnippet')
	command! -nargs=0 DiQuickSnippet :call DiQuickSnippet ()
endif

"}}}

"External Function: GoToLine {{{
function! GoToLine(mainbuffer)
   let linenumber = expand("<cword>")
   silent bd!
   silent execute "buffer" a:mainbuffer
   silent execute ":"linenumber
   nunmap <Enter>
endfunction
"command -nargs=1 GoToLine :call GoToLine(<f-args>)
"}}}

"External Function: GrepToBuffer {{{
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
"}}}

"Mark window {{{
function! MarkWindow (mark_desc)
    let w:wnd_mark = a:mark_desc
endfunction
"}}}

"Unmark window {{{
function! UnmarkWindow ()
    let w:wnd_mark = ''
endfunction
"}}}

"Find marked window {{{
function! FindMarkedWindow (page_idx, mark_desc)
    let l:win_count = tabpagewinnr (a:page_idx, '$')
    for l:idx in range (1, l:win_count)
        let l:tmp = getwinvar(l:idx, 'wnd_mark')
        if l:tmp == a:mark_desc
            return l:idx
        endif
    endfor 
    return 0
endfunction
"}}}

"Go go marked window {{{
function! GoToMaredWindow (page_idx, mark_desc)
    let l:marked_wnd_num = FindMarkedWindow (a:page_idx, a:mark_desc)
	if l:marked_wnd_num != 0
		exec 'silent! ' . string(l:marked_wnd_num) . 'wincmd w'
	else
		return 'false'
	endif
	return 'true'
endfunction
"}}}

"Host key setting {{{
":map <Leader>se :call EnQuickSnippet () <CR>
":map <Leader>sd :call DiQuickSnippet () <CR>
"}}}

"Default Menu setting {{{
amenu Plugin.CCVimExt.CreateDatabase      :call SyncSource  () <CR>
amenu Plugin.CCVimExt.SelectDatabase      :call ConfigSymbs () <CR>

menu  Plugin.CCVimExt.-Sep0-	          :
amenu Plugin.CCVimExt.EnableQuickSnippet  :call EnQuickSnippet () <CR>
amenu Plugin.CCVimExt.DisableQuickSnippet :call DiQuickSnippet () <CR>

menu  Plugin.CCVimExt.-Sep1-	          :
amenu Plugin.CCVimExt.FindCalling         :cs find c <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindCalled          :cs find d <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindEgrep           :cs find e <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindThisFile        :cs find f <C-R>=expand("<cfile>")<CR><CR>
amenu Plugin.CCVimExt.FindThisDef         :cs find g <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindFileIncThisFile :cs find i <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindSymbs           :cs find s <C-R>=expand("<cword>")<CR><CR>
amenu Plugin.CCVimExt.FindAssignmentsTo   :cs find t <C-R>=expand("<cword>")<CR><CR>

menu  Plugin.CCVimExt.-Sep3-	          :
amenu Plugin.CCVimExt.Prev                :<CTRL-O> <CR><CR>
amenu Plugin.CCVimExt.Prev                :<CTRL-T> <CR><CR>

menu  Plugin.CCVimExt.-Sep2-	          :
function! CloseWindow ()
    if winnr () == FindMarkedWindow (1, 'main_source_window_mark')
        return
    endif
    if 1 == tabpagewinnr (1, '$')
		return
	endif
	:close!
endfunction
amenu Plugin.CCVimExt.CloseThisWindow     :call CloseWindow () <CR>
"}}}
"
"Other plugin detect {{{
function! CallPluginTagList ()
	try | exec ":TlistToggle" | catch /.*/ | echo "Taglist is not installed, get it from http://www.vim.org/scripts/script.php?script_id=273" | endtry
endfunction

function! CallPluginMRU ()
	call CloseSnippedWndAndListWndOnce ()
	try | exec ":MRU" | catch /.*/ | echo "MRU is not installed, get it from http://www.vim.org/scripts/script.php?script_id=521" | endtry
endfunction

function! CallPluginMark ()
	try | exec ":Mark " . expand("<cword>") | catch /.*/ | echo "Mark is not installed, get it from http://www.vim.org/scripts/script.php?script_id=1238" | endtry
endfunction

function! CallPluginNERDTree ()
	try | exec ":NERDTree" | catch /.*/ | echo "NERDTree is not installed, get it from http://www.vim.org/scripts/script.php?script_id=1658" | endtry
endfunction

function! OtherPluginDetect ()
	if exists (":TlistToggle") || exists (":MRU") || exists (":Mark") || exists (":NERDTree")
		menu  Plugin.CCVimExt.-Sep100- :
	endif
	if exists (":NERDTree")
		amenu Plugin.CCVimExt.NERDTree :call CallPluginNERDTree () <CR>
	endif
	if exists (":TlistToggle")
		amenu Plugin.CCVimExt.TList    :call CallPluginTagList () <CR>
	endif
	if exists (":Mark")
		amenu Plugin.CCVimExt.Mark     :call CallPluginMark () <CR>
	endif
	if exists (":MRU")
		amenu Plugin.CCVimExt.MRU      :call CallPluginMRU () <CR>
	endif
endfunction
"}}}
"
"Commands {{{
if !exists(':CscopeCtagsMenu')
	command! -nargs=0 CscopeCtagsMenu :call CscopeCtagsMenu ()
endif
"}}}
"
"Test Test Test Test {{{
"
"
"
"
" vim:ts=4 fdm=marker
