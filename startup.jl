# managed by CB.jl
ENV["JULIA_PKG_PRESERVE_TIERED_INSTALLED"] = "true"
import Pkg
Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true

atreplinit() do repl
    try
        @eval using OhMyREPL
        @eval OhMyREPL.enable_autocomplete_brackets(false)
    catch e
        @warn "error while importing OhMyREPL" e
    end

    try
        @eval using Revise
    catch e
        @warn "Error initializing Revise" exception=(e, catch_backtrace())
    end
end

import Logging
function debug_logging(activate = true)
    if activate
        logger = Logging.ConsoleLogger(stderr, Logging.Debug)
    else
        logger = Logging.ConsoleLogger(stderr, Logging.Warn)
    end
    Logging.global_logger(logger)
    return nothing
end

# Macros
macro cn(x)
    if Sys.ARCH === :x86_64
        println("julia> @code_native syntax=:intel debuginfo=:none ", x)
        :(@code_native syntax=:intel debuginfo=:none $x)
    else
        println("julia> @code_native debuginfo=:none ", x)
        :(@code_native debuginfo=:none $x)
    end
end
macro cl(x)
    println("julia> @code_llvm debuginfo = :none ", x)
    :(@code_llvm debuginfo=:none $x)
end
macro cw(x)
    println("julia> @code_warntype ", x)
    :(@code_warntype debuginfo=:none $x)
end
macro d(x)
    # if !isdefined(Main, :Cthulhu)
    #     @eval using Cthulhu
    # end
    println("julia> @descend_code_warntype debuginfo = :none ", x)
    :(@descend_code_warntype debuginfo=:none $x)
end

if isinteractive()
    import BasicAutoloads
    BasicAutoloads.register_autoloads([
        ["@b", "@be"]            => :(using Chairmarks),
        ["@benchmark", "@btime"] => :(using BenchmarkTools),
        ["@descend", "@descend_code_typed", "@descend_code_warntype", "@d"] => :(using Cthulhu),
        ["@profile"] => :(using Profile),
        ["@enter", "@run"] => :(using Debugger),
        ["@test", "@testset", "@test_broken", "@test_deprecated", "@test_logs",
        "@test_nowarn", "@test_skip", "@test_throws", "@test_warn", "@inferred"] =>
                                    :(using Test),
        ["@about"]               => :(using About; macro about(x) Expr(:call, About.about, x) end),
    ])
end
