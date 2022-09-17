add_repositories("tapzcrew-repo https://github.com/TapzCrew/xmake-repo main")

add_requires("cppfront")

includes("xmake/*.lua")

set_runtimes("MD")
target("cpp2-test")
    set_kind("binary")
    set_languages("cxxlatest", "clatest")

    add_packages("cppfront")
    add_rules("cppfront")

    set_values("c++2.clean_cpp", true)
    set_values("c++2.pure_cpp", true)
    set_values("c++2.null_checks", true)
    set_values("c++2.subscript_checks", true)

    set_policy("build.c++.modules", true)

    -- add_files("src/*.cpp")
    add_files("src/*.cpp2")

