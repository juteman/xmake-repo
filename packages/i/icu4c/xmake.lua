package("icu4c")

    set_homepage("http://site.icu-project.org/")
    set_description("C/C++ libraries for Unicode and globalization.")

    add_urls("https://github.com/unicode-org/icu/releases/download/release-$(version)-src.tgz", {version = function (version)
            return (version:gsub("%.", "-")) .. "/icu4c-" .. (version:gsub("%.", "_"))
        end})
    add_versions("68.1", "a9f2e3d8b4434b8e53878b4308bd1e6ee51c9c7042e2b1a376abefb6fbb29f2d")
    add_versions("64.2", "627d5d8478e6d96fc8c90fed4851239079a561a6a8b9e48b0892f24e82d31d6c")

    add_links("icuuc", "icutu", "icui18n", "icuio", "icudata")
    if is_plat("linux") then
        add_syslinks("dl")
    end
    if is_plat("windows") then
        add_deps("python 3.x", {kind = "binary"})
    end

    on_install("windows", function (package)
        import("package.tools.msbuild")
        import("lib.detect.find_tool")

        -- set configs
        local configs = {path.join("source", "allinone", "allinone.sln"), "/p:SkipUWP=True", "/p:_IsNativeEnvironment=true"}
        table.insert(configs, "/p:Configuration=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "/p:Platform=" .. (package:is_arch("x64") and "x64" or "Win32"))

        -- set envs
        local envs = msbuild.buildenvs(package)
        print("envs:", envs)
        print(envs.PATH)
   --     print(find_tool("cl", {envs = envs}))
        envs.PATH = package:dep("python"):installdir("bin") .. path.envsep() .. envs.PATH
        print("envs2:", envs)
        print(envs.PATH)
        print(find_tool("msbuild", {envs = envs}))

        -- build
        msbuild.build(package, configs, {envs = envs})
        os.cp("include", package:installdir())
        os.cp("bin*/*", package:installdir("bin"))
        os.cp("lib*/*", package:installdir("lib"))
        package:addenv("PATH", "bin")
    end)

    on_install("macosx", "linux", function (package)
        os.cd("source")
        local configs = {"--disable-samples", "--disable-tests"}
        if package:debug() then
            table.insert(configs, "--enable-debug")
            table.insert(configs, "--disable-release")
        end
        if package:config("shared") then
            table.insert(configs, "--enable-shared")
            table.insert(configs, "--disable-static")
        else
            table.insert(configs, "--disable-shared")
            table.insert(configs, "--enable-static")
        end
        if package:is_plat("linux") then
            table.insert(configs, "CFLAGS=-fPIC CXXFLAGS=-fPIC")
        end
        import("package.tools.autoconf").install(package, configs)
        package:addenv("PATH", "bin")
    end)

    on_test(function (package)
        assert(package:has_cfuncs("ucnv_convert", {includes = "unicode/ucnv.h"}))
    end)
