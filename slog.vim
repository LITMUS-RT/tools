" .vim/syntax/slog.vim

" Also add this line to your .vimrc
" autocmd BufRead,BufNewFile *.slog set filetype=slog

" Match on the sequence number at the start of the line.
" Sequence number is always in the log.
:syn match logSeqNo /^\d\+/ nextgroup=logProcessorNo skipwhite

" Match on the processor number.
" This is always in the log, but what comes next varies.
:syn match logProcessorNo /P\d\+/ nextgroup=logFunctInfo,logProcessInfo skipwhite

" Match on the function info, e.g. [reclaim_pages@litmus/color.c:203]:
" It contains function, file, and line.
:syn match logFunctInfo "\[[^\]]*\]" contains=logFunction,logFile,logLineNo nextgroup=logProcessInfo skipwhite
" Don't highlight the bracket or @ sign
:syn match logFunction "\[\w\+@"hs=s+1,he=e-1 contained nextgroup=logFile
:syn match logFile "[A-Za-z0-9_./]\+:"he=e-1 contained nextgroup=logLineNo
:syn match logLineNo "\d\+]"he=e-1 contained

:syn match logProcessInfo "([^)]*)" contains=logProcess,logPid,logJob skipwhite
:syn match logProcess "([^/]*/"hs=s+1,he=e-1 contained nextgroup=logPid
:syn match logPid "\d\+:"he=e-1 contained nextgroup=logJob
:syn match logJob "\d\+)"he=e-1 contained

" Now make them appear:
hi def link logSeqNo		Constant
hi def link logProcessorNo	Todo
hi def link logFunction		String
hi def link logFile		Comment
hi def link logLineNo		Number
hi def link logProcess		Comment
hi def link logPid		Constant
hi def link logJob		Number

let b:current_syntax = "slog"
