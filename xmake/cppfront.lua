rule("cppfront")
    add_deps("c++")
    add_deps("c++.build.modules")
    set_extensions(".cpp2")

    on_load(function(target)
        import("lib.detect.find_tool")

        local outputdir = target:extraconf("rules", "cppfront", "outputdir") or path.join(target:autogendir(), "rules", "cppfront")
        
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end

        target:data_set("cppfront_outputdir", outputdir)
    end)

    -- parallel build support to accelerate `xmake build` 
    before_build_files(function(target, batchjobs, sourcebatch, opt)
        import("core.project.depend")
        import("utils.progress")
        import("core.tool.compiler")

        local outputdir = target:data("cppfront_outputdir")
        local common_flags = { }
        if target:values("c++2.clean_cpp") then
            table.insert(common_flags, "-c")
        end
        if target:values("c++2.pure_cpp") then
            table.insert(common_flags, "-p")
        end
        if target:values("c++2.add_source_info") then
            table.insert(common_flags, "-a")
        end
        if target:values("c++2.null_checks") then
            table.insert(common_flags, "-n")
        end
        if target:values("c++2.subscript_checks") then
            table.insert(common_flags, "-s")
        end
        if target:values("c++2.debug") then
            table.insert(common_flags, "-d")
        end

        opt.rootjob = batchjobs:group_leave() or opt.rootjob
        batchjobs:group_enter(target:name() .. "/build_c++2", {rootjob = opt.rootjob})
        for _, cpp2file in ipairs(sourcebatch.sourcefiles) do
            local cpp2file_copied = path.join(outputdir, path.filename(cpp2file))
            local cppfile = cpp2file_copied:sub(1, -2)

            batchjobs:addjob(cpp2file, function(index, total)
                local objectfile = target:objectfile(cppfile)

                depend.on_changed(function()
                    local dependfile = target:dependfile(cpp2file)
                    local dependinfo = depend.load(dependfile) or { files = {cpp2file }}
                    os.cp(cpp2file, outputdir)

                    progress.show((index * 100) / total, "${color.build.object}compiling.cpp2 %s", cpp2file)

                    local flags = { cpp2file_copied }

                    local _, err = os.iorunv("cppfront", table.join(flags, common_flags))
                    assert(err == "", err)

                    if not os.isdir(path.directory(objectfile)) then
                        os.mkdir(path.directory(objectfile))
                    end

                    compiler.compile(cppfile, objectfile, {target = target})

                    depend.save(dependinfo, dependfile)

                end, {dependfile = target:dependfile(cpp2file), files = {cpp2file, cppfile}})

                sourcebatch.objectfiles = sourcebatch.objectfiles or {}
                table.insert(sourcebatch.objectfiles, target:objectfile(cppfile))
            end, { rootjob = opt.rootjob })
        end
    end, {batch = true})