module CB

using Pkg
using Random
using Dates

include("utility.jl")

@static if Sys.islinux()
    const SYS_DEPENDENT_PKGS = ["ThreadPinning"]
else
    const SYS_DEPENDENT_PKGS = String[]
end

const DEFAULT_PKGS = vcat([
                              "OhMyREPL",
                              "Cthulhu",
                              "JET",
                              "Revise",
                              "BenchmarkTools",
                              "CpuId",
                              "Hwloc",
                              "PkgTemplates",
                              "JuliaFormatter",
                              "Preferences",
                              "PreferenceTools",
                              "ThreadPinning",
                              "TestEnv",
                          ], SYS_DEPENDENT_PKGS)

function install_defaultpkgs(; glob = true)
    pkgstr = join(DEFAULT_PKGS, ' ')
    @info("Installing the following packages into the global env:", pkgstr)
    pkgexec("add $pkgstr"; glob = true)
end

function install_startupjl()
    cb_startupjl = joinpath(@__DIR__, "../startup.jl")
    config_path = joinpath(jldepot(), "config")
    sys_startupjl = joinpath(config_path, "startup.jl")
    if isfile(sys_startupjl)
        if !(first(readlines(sys_startupjl)) == "# managed by CB.jl")
            @info("Existing startup.jl found. Backing it up.")
            bkp_name = "old_$(now())_startup.jl"
            mv(sys_startupjl, joinpath(config_path, bkp_name); force = true)
        else
            @info("Existing startup.jl by CB.jl found. Will overwrite it.")
        end
    end
    if !ispath(config_path)
        @info("No prior startup.jl found.")
        mkpath(config_path)
    end
    @info("Creating new startup.jl.")
    cp(cb_startupjl, sys_startupjl; force = true)
    return nothing
end

function install()
    install_defaultpkgs()
    install_startupjl()
end

end
