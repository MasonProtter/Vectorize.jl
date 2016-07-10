############################## VECTORIZE.jl #############################
##                                                                     ##
## This script performs the build and install process for Vectorize.jl ##
##                                                                     ##
############################### #########################################

# erase old function definitions to prevent issues
currdir = @__FILE__
pkgdir = currdir[1:end-13]
function_location = pkgdir*"src/Functions.jl"
run(`rm $(function_location)`)
run(`touch $(function_location)`)

# 
include("benchmark.jl")

"""
`trycmd(cmd::Cmd, msg::ASCIIString="", err::ASCIIString="")::ASCIIString`
This function attemps to run the shell command specified by `cmd` using `run`.
If `cmd` returns successfully, it will print `msg` using info().
If `readall(cmd)` throws an exception (the shell command returns non-zero),
then the function throws an error and prints the `err` argument.

Note: This function does not return the value of the command to the caller. However,
prints to STD_OUT by the `run` command will print automatically from the shell process.
"""
function trycmd(cmd::Cmd; msg::ASCIIString="", err::ASCIIString="")
    try
        run(cmd)
        if msg == "" return else info(msg) end
    catch
        if err != ""
            error(err)
        end
    end
end

"""
`trycmd_read(cmd::Cmd, msg::ASCIIString="", err::ASCIIString="")::ASCIIString`
This function attemps to run the shell command specified by `cmd` using `readall`.
If `cmd` returns successfully, it will return its result to the caller and print `msg`.
If `readall(cmd)` throws an exception (the shell command returns non-zero),
then the function throws an error and prints the `err` argument.
"""
function trycmd_read(cmd::Cmd; msg::ASCIIString="", err::ASCIIString="")
    try
        result = readall(cmd)
        if msg == "" return result else info(msg) end
        return result
    catch
        if err != ""
            error(err)
        end
    end
end

"""
`prompt_yn(prompt::ASCIIString)::Bool`

Prompts the user for a y or n response (y/n). Continually prompts
until user enters a valid response. Prompt string should be provided without
colon and whitespace.
"""
function prompt_yn(prompt::ASCIIString)
    print(prompt, " [y/n]:  ")
    input = chomp(readline())
    while input != "y" && input != "n"
        print("You did not enter y or n. Please enter a valid response: [y/n]  ")
        input = chomp(readline())
    end

    return (input == "y") ? true : false
end


##### ARCHITECTURE ####
if Sys.ARCH != :x86_64
    error("Vectorize.jl currently only supports x86_64; your detected architecture is $(Sys.ARCH)")
end

#### DEPENDENCIES ####
## We first check whether all binary dependencies are available on the system
# deps = ["cmake", "wget"]
# for dep in deps
#     err = ("$dep is not installed. Please install $dep, ensure that it is in your"*
#            "PATH,  and run Pkg.build(\"Vectorize\") again.")
#     location = trycmd_read(`command -v $dep`, err=err)[1:end-1]
#     info("Using $dep found at $location.")
# end

#### Yeppp ####
# if prompt_yn("Would you like to install Yeppp! into the local directory?")
if isfile("downloads/yeppp-1.0.0.tar.bz2") || (Libdl.find_library(["libyeppp"]) != "")
else
    info("====== Installing Yeppp! into local directory ======")
    trycmd(`mkdir $(pkgdir)deps/downloads`)
    trycmd(`mkdir $(pkgdir)deps/src`)
    trycmd(`mkdir $(pkgdir)deps/src/yeppp`)
    run(pipeline(`curl -L http://bitbucket.org/MDukhan/yeppp/downloads/yeppp-1.0.0.tar.bz2`, stdout="$(pkgdir)deps/downloads/yeppp-1.0.0.tar.bz2"))
    trycmd(`tar -xjvf $(pkgdir)deps/downloads/yeppp-1.0.0.tar.bz2 -C $(pkgdir)deps/src/yeppp --strip-components=1`)
    info("====== Successfully installed Yeppp! ======")
end
# end

# Have to import vectorize after Yeppp is downloaded
import Vectorize: functions

# BENCHMARK
N = 1_000
file = open("$(pkgdir)src/Functions.jl", "a")
for ((f, T), options) in functions
    if length(T) == 1
        benchmarkSingleArgFunction(f, options, T[1], file, 1_000)
    elseif length(T) == 2
        benchmarkTwoArgFunction(f, options, T, file, 1_000)
    elseif length(T) == 3
        benchmarkThreeArgFunction(f, options, T, file, 1_000)
    end
end
close(file)

#### VectorizePass ####
## We then run `make clean` before starting a fresh build of Vectorize.jl
# currdir = @__FILE__
# makedir = currdir[1:end-13]*"src/Vectorize/"
# msg = "Vectorize.jl was built successfully!"
# err = "Vectorize.jl failed to build correctly; please create an issue on"*
# "GitHub and copy the output of the build process above; we will endeavour"*
# "to fix your issue as soon as possible"
# trycmd(`make -C $makedir clean`)
# info("====== Successfully cleaned Vectorize.jl build directory ======")
# info("====== Attempting to build Vectorize.jl ======")
# trycmd(`make -C $makedir`, msg=msg, err=msg) ## BUILD COMMAND
