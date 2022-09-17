rule("cppfront")
    set_extensions(".cpp2")

    on_load(function(target)
        import("lib.detect.find_tool")

        local outputdir = target:extraconf("rules", "cppfront", "outputdir") or path.join(target:autogendir(), "rules", "cppfront")
        
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end

        target:data_set("cppfront_outputdir", outputdir)
    end)

    -- parallel build support to accelerate `xmake build` to build modules
    before_build_files(function(target, batchjobs, sourcebatch, opt)
        import("core.project.depend")
        import("utils.progress")

        local outputdir = target:data("cppfront_outputdir")

        for _, cpp2file in ipairs(sourcebatch.sourcefiles) do
            local cpp2file_copied = path.join(outputdir, path.filename(cpp2file))
            local cppfile = cpp2file_copied:sub(1, -2)
            local objectfile = target:objectfile(cppfile:sub(1, -5))
            if not os.isdir(path.directory(objectfile)) then
                os.mkdir(path.directory(objectfile))
            end

            opt.rootjob = batchjobs:group_leave() or opt.rootjob
            batchjobs:group_enter(target:name() .. "/build_cpp2", {rootjob = opt.rootjob})
            batchjobs:addjob(cpp2file, function(index, total)
                depend.on_changed(function()
                    os.cp(cpp2file, outputdir)

                    local flags = {cpp2file_copied}

                    progress.show((index * 100) / total, "${color.build.object}compiling.cpp2 %s", path.filename(cpp2file))

                    if is_plat("windows") then
                        local compinst = target:compiler("cxx")
                        local msvc = target:toolchain("msvc")
                        local _, err = os.iorunv("cppfront", winos.cmdargv(flags))
                        assert(os.exists(cppfile), err)
                        os.vrunv(compinst:program(), winos.cmdargv(table.join(compinst:compflags({target = target}), {cppfile, "-Fo" .. objectfile})), {envs = msvc:runenvs()})
                    else
                        local compinst = target:compiler("cxx")
                        local _, err = os.iorunv("cppfront", winos.cmdargv(flags))
                        assert(os.exists(cppfile), err)
                        os.vrunv(compinst:program(), table.join(compinst:compflags({target = target}), {cppfile, "-Fo" .. objectfile}))
                    end

                end, {dependfile = target:dependfile(objectfile), files = {cpp2file}})
            end, { rootjob = opt.rootjob })

            sourcebatch.objectfiles = sourcebatch.objectfiles or {}
            table.insert(sourcebatch.objectfiles, objectfile)
        end
    end, {batch = true})