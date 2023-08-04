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
    # if !isdefined(Main, :Cthulhu)
    #     @eval using Cthulhu
    # end
    println("julia> @descend_code_warntype debuginfo = :none ", x)
    :(@descend_code_warntype debuginfo=:none $x)
end

# taken from https://github.com/fredrikekre/.dotfiles/blob/65b96f492da775702c05dd2fd460055f0706457b/.julia/config/startup.jl#L2-L25
if Base.isinteractive() &&
   (local REPL = get(Base.loaded_modules, Base.PkgId(Base.UUID("3fa0cd96-eef1-5676-8a61-b3b8758bbffb"), "REPL"), nothing); REPL !== nothing)

    # Exit Julia with :q, restart with :r
    pushfirst!(REPL.repl_ast_transforms, function(ast::Union{Expr,Nothing})
        function toplevel_quotenode(ast, s)
            return (Meta.isexpr(ast, :toplevel, 2) && ast.args[2] === QuoteNode(s)) ||
                   (Meta.isexpr(ast, :toplevel) && any(x -> toplevel_quotenode(x, s), ast.args))
        end
        if toplevel_quotenode(ast, :q)
            exit()
        elseif toplevel_quotenode(ast, :r)
            argv = Base.julia_cmd().exec
            opts = Base.JLOptions()
            if opts.project != C_NULL
                push!(argv, "--project=$(unsafe_string(opts.project))")
            end
            if opts.nthreads != 0
                push!(argv, "--threads=$(opts.nthreads)")
            end
            # @ccall execv(argv[1]::Cstring, argv::Ref{Cstring})::Cint
            ccall(:execv, Cint, (Cstring, Ref{Cstring}), argv[1], argv)
        end
        return ast
    end)

    # Automatically load tooling on demand:
    # - BenchmarkTools.jl when encountering @btime or @benchmark
    # - Cthulhu.jl when encountering @descend(_code_(typed|warntype))
    # - Debugger.jl when encountering @enter or @run
    # - Profile.jl when encountering @profile
    # - ProfileView.jl when encountering @profview
    # - Test.jl when encountering @test, @testset, @test_xxx, ...
    local tooling_dict = Dict{Symbol,Vector{Symbol}}(
        :BenchmarkTools => Symbol.(["@btime", "@benchmark"]),
        :Cthulhu        => Symbol.(["@descend", "@descend_code_typed", "@descend_code_warntype", "@d"]),
        :Debugger       => Symbol.(["@enter", "@run"]),
        :Profile        => Symbol.(["@profile"]),
        :ProfileView    => Symbol.(["@profview"]),
        :Test           => Symbol.([
                               "@test", "@testset", "@test_broken", "@test_deprecated",
                               "@test_logs", "@test_nowarn", "@test_skip",
                               "@test_throws", "@test_warn",
                           ]),
    )
    pushfirst!(REPL.repl_ast_transforms, function(ast::Union{Expr,Nothing})
        function contains_macro(ast, m)
            return ast isa Expr && (
                (Meta.isexpr(ast, :macrocall) && ast.args[1] === m) ||
                any(x -> contains_macro(x, m), ast.args)
            )
        end
        for (mod, macros) in tooling_dict
            if any(contains_macro(ast, s) for s in macros) && !isdefined(Main, mod)
                @info "Loading $mod ..."
                try
                    Core.eval(Main, :(using $mod))
                catch err
                    @info "Failed to automatically load $mod" exception=err
                end
            end
        end
        return ast
    end)

end
