function pkgexec(str; glob = false)
    if glob
        pkgexec(str, getglobaljlenv())
    else
        Pkg.REPLMode.pkgstr(str)
    end
end
pkgexec(str, env) = withjlenv(() -> pkgexec(str; glob = false), env)

function withjlenv(f, env)
    env_before = Base.active_project()
    try
        pkgexec("activate $(env)")
        f()
    finally
        pkgexec("activate $(env_before)")
    end
    return nothing
end

home() = home = get(ENV, "HOME", "~")

function getglobaljlenv()
    major = VERSION.major
    minor = VERSION.minor
    env = "v$(major).$(minor)"
    return joinpath(home(), ".julia/environments/", env)
end
