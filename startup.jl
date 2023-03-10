# managed by CB.jl
atreplinit() do repl
    try
        @eval using OhMyREPL
        @eval OhMyREPL.enable_autocomplete_brackets(false)
    catch e
        @warn "error while importing OhMyREPL" e
    end
end

import Pkg
Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true

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
    if !isdefined(Main, :Cthulhu)
        @eval using Cthulhu
    end
    println("julia> @descend_code_warntype debuginfo = :none ", x)
    :(@descend_code_warntype debuginfo=:none $x)
end
