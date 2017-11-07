" hydra.vim - Temporary Remaps
" Author:   Austin W. Smith
" Version:  0.0.1
" Latest:   https://github.com/auwsmit/vim-hydra

" Inspired by https://github.com/abo-abo/hydra

" TODO: Make cool commands
" TODO: Modes other than normal mode
"       - make modes related to groups
"       - also for trigger
" TODO: Test wacky edge-cases

" VIMRC EXAMPLE:
"
" let g:hytrigger = 'z.'
" let g:hyquit  = [ 'q', '.', '<space>' ]
" let g:hykeys =  [ 'u', '<c-u>', 'd', '<c-d>' ]
" let g:hykeys += [ '[', '{',     ']', '}', ]
" call MakeHydra(g:hytrigger,g:hyquit,g:hykeys)
"
" map format: map lhs rhs
" hykeys format: [ lhs1, rhs1, lhs2, rhs2, lhs3, rhs3, etc ]
"
" EFFECTS: (currently only normal mode)
"
" - Press z. to enable hydra
" - While enabled,
"   - u is <c-u>
"   - d is <c-d>
"   - [ is {
"   - etc
" - Press q, ., or <space> to disable hydra
"   - z. would also work if it were a single key
"     because timeoutlen is disabled for the hydra

if &cp || exists('g:loaded_hydra')
  finish
endif

" only one hydra at a time
let g:hydra_enabled = 0
let g:hydra_tol = 0
let g:hydra_ttol = 0

fun! MakeHydra(trigger, quit, ...)
  let l:i = 0
  let l:grouplist = []
  for group in a:000
    let l:grouplist += [group]
    " create list for each group to hold old mappings,
    " old mappings are always group[0]
    let l:grouplist[l:i] = [[]] + group
    let l:i += 1
  endfor
  call CreateMapHelper('nnoremap',a:trigger,l:grouplist,[[]]+a:quit)
endfun

" convert < into <lt> so key-notation isn't translated
" (e.g. <c-u> will become <lt>c-u>, thus making it literal in a mapping)
fun! CreateMapHelper(map,trigger,quit,grouplist)
  let l:mapstr = ' :call ToggleHydra('.string(a:grouplist).','.string(a:quit).')'
  exec a:map.' '.a:trigger.substitute(l:mapstr,'<','<lt>','g').'<cr>'
endfun

fun! RemapOldMaps(map_save)
  " credit to https://vi.stackexchange.com/a/7735
  exec (a:map_save.noremap ? 'nnoremap' : 'nmap') .
        \ join(map(['buffer', 'expr', 'nowait', 'silent'], 'a:map_save[v:val] ? "<" . v:val . ">": ""')) .
        \ a:map_save.lhs . ' ' .
        \ substitute(a:map_save.rhs, '<SID>', '<SNR>' . a:map_save.sid . '_', 'g')
endfun

fun! ToggleHydra(quit, grouplist)
  if !g:hydra_enabled
    let g:hydra_tol = &timeoutlen
    let g:hydra_ttol = &timeoutlen
    set timeoutlen=0
    set ttimeoutlen=0
    for group in a:grouplist
      call EnableGroupKeys(group)
    endfor
    call EnableQuitKeys(a:quit, a:grouplist)
    let g:hydra_enabled = 1
    echo "Hydra Enabled"
  else
    let &timeoutlen = g:hydra_tol
    let &ttimeoutlen = g:hydra_ttol
    for group in a:grouplist
      call KillGroupKeys(group)
    endfor
    call KillQuitKeys(a:quit)
    let g:hydra_enabled = 0
    echo "Hydra Disabled"
  endif
endfun

fun! EnableGroupKeys(group)
  let l:i = 1
  let l:len = len(a:group)
  for key in a:group
    if type(key) == type([])
      continue
    endif
    let a:group[0] += [maparg(a:group[l:i],'n',0,1), 0]
    exec 'nnoremap '.a:group[l:i].' '.a:group[l:i+1]
    let l:i += 2
    if l:i == l:len
      break
    endif
  endfor
endfun

fun! KillGroupKeys(group)
  let l:i = 1
  let l:len = len(a:group)
  for key in a:group
    if type(key) == type([])
      continue
    endif
    if !empty(a:group[0][l:i])
      call RemapOldMaps(a:group[0][l:i])
    else
      exec 'nunmap '.a:group[l:i]
    endif
    let l:i += 2
    if l:i == l:len
      break
    endif
  endfor
  let a:group[0] = []
endfun

fun! EnableQuitKeys(quit, grouplist)
  " update quit old maps
  for key in a:quit
    if type(key) == type([])
      continue
    endif
    let a:quit[0] += [maparg(key,'n',0,1)]
  endfor
  for key in a:quit
    if type(key) == type([])
      continue
    endif
    call CreateMapHelper('nnoremap',key,a:grouplist,a:quit)
  endfor
endfun

fun! KillQuitKeys(quit)
  let l:i = 0
  for key in a:quit
    if type(key) == type([])
      continue
    endif
    if !empty(a:quit[0][l:i])
      call RemapOldMaps(a:quit[0][l:i])
    else
      exec 'nunmap '.key
    endif
    let l:i += 1
  endfor
  let a:quit[0] = []
endfun

let g:loaded_hydra = 1
