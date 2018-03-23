set complete-=i
let g:cpp_plugin.indexer.builder.autoBuild = 1
call g:cpp_plugin.indexer.builder.addCustomRegex('c++', '/[ \t]*using[ \t]*([A-Za-z0-9_]*)[ \t]*=/\1/t/')
call g:cpp_plugin.indexer.builder.addCustomRegex('c++', '/[ \t]*DETAIL_JOINT_JAVA_DECLARE_JREFS[ \t]*\([^,]*,[ \t]*([A-Za-z0-9_]*)[ \t]*\)/J\1WeakRef/t/')
call g:cpp_plugin.indexer.builder.addCustomRegex('c++', '/[ \t]*DETAIL_JOINT_JAVA_DECLARE_JREFS[ \t]*\([^,]*,[ \t]*([A-Za-z0-9_]*)[ \t]*\)/J\1TempRef/t/')
call g:cpp_plugin.indexer.builder.addCustomRegex('c++', '/[ \t]*DETAIL_JOINT_JAVA_DECLARE_JREFS[ \t]*\([^,]*,[ \t]*([A-Za-z0-9_]*)[ \t]*\)/J\1LocalRef/t/')
call g:cpp_plugin.indexer.builder.addCustomRegex('c++', '/[ \t]*DETAIL_JOINT_JAVA_DECLARE_JREFS[ \t]*\([^,]*,[ \t]*([A-Za-z0-9_]*)[ \t]*\)/J\1GlobalRef/t/')
call g:cpp_plugin.indexer.builder.addCustomRegex('python', '/[ \t]*self\.([A-Za-z0-9_]*)[ \t]*=/\1/v/')
call g:cpp_plugin.indexer.builder.preprocessorIdentifiers(['JOINT_DEVKIT_NOEXCEPT', 'noexcept'])

call g:buildsystem.setAvailableBuildConfigs( { 'host': CMakeBuildConfig(4, './build/') } )


let g:include_directories = [ 'core', 'devkit', 'bindings/cpp', 'bindings/java', 'bindings/python', 'build', 'benchmarks/core', 'benchmarks' ]


function! GetCppNamespaceFromPath(path)
    let res = []
    if len(a:path) > 1 && a:path[0] == 'devkit'
        call add(res, 'joint')
        call add(res, 'devkit')
        if len(a:path) > 4 && index(['detail', 'accessors', 'proxy', 'meta'], a:path[3]) >= 0
            call add(res, a:path[3])
        endif
    endif
    if len(a:path) > 1 && a:path[0] == 'core'
        call add(res, 'joint')
        if len(a:path) > 3 && a:path[2] == 'detail'
            call add(res, a:path[2])
        endif
    endif
    if len(a:path) > 1 && a:path[0] == 'bindings'
        if len(a:path) > 2 && a:path[1] == 'cpp'
            call add(res, 'joint')
            if len(a:path) > 4 && a:path[3] == 'detail'
                call add(res, 'detail')
            endif
        endif
    endif
    return res
endf

if exists('g:c_std_includes') && exists('g:cpp_std_includes') && exists('g:platform_includes')
    let g:include_priorities = [ 'joint/.*', 'benchmarks/.*', 'cxxtest/.*', g:platform_includes, g:cpp_std_includes, g:c_std_includes ]
end

au BufNew,BufRead *.c,*.cpp,*.h,*.hpp match Error /^\(#\)\@!.*\S *\zs\t\+/
