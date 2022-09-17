add_repositories("tapzcrew-repo https://github.com/TapzCrew/xmake-repo main")

add_requires("cppfront")

includes("xmake/*.lua")

target("cpp2-test")
    set_kind("binary")
    set_languages("cxxlatest", "clatest")

    add_packages("cppfront")
    add_rules("cppfront")

    -- add_files("src/*.cpp")
    add_files("src/*.cpp2")

