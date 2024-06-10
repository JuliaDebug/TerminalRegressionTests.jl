using TerminalRegressionTests
using Test

TerminalRegressionTests.automated_test(
                joinpath(@__DIR__, "TRT.multiout"),
                ["Julia\n","Yes!!\n"]) do emuterm
    print(emuterm, "Please enter your name: ")
    name = strip(readline(emuterm))
    @test name == "Julia"
    print(emuterm, "\nHello $name. Do you like tests? ")
    resp = strip(readline(emuterm))
    @test resp == "Yes!!"
end

mktemp() do _, io
    redirect_stderr(io) do
        redirect_stdout(io) do
            @test_throws ErrorException TerminalRegressionTests.automated_test(
                            joinpath(@__DIR__, "TRT2.multiout"),
                            [""]) do emuterm
                println(emuterm, "Hello, world!")   # generate with "wurld" rather than "world"
                readline(emuterm)   # needed to produce output?
            end
        end
    end
end

function compare_replace(em, output; replace=nothing)
    buf = IOBuffer()
    decoratorbuf = IOBuffer()
    TerminalRegressionTests.VT100.dump(buf,decoratorbuf,em)
    outbuf = take!(buf)
    if replace !== nothing
        output = Base.replace(output, replace)
    end
    TerminalRegressionTests._compare(Vector{UInt8}(codeunits(output)), outbuf) || return false
    return true
end

cmp(a, b, decorator) = compare_replace(a, b; replace="wurld"=>"world")
TerminalRegressionTests.automated_test(cmp,
                joinpath(@__DIR__, "TRT2.multiout"),
                [""]) do emuterm
    println(emuterm, "Hello, world!")
    readline(emuterm)
end
