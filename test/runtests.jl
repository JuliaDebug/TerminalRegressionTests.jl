using TerminalRegressionTests
using Test

const thisdir = dirname(@__FILE__)
TerminalRegressionTests.automated_test(
                joinpath(thisdir,"TRT.multiout"),
                ["Julia\n","Yes!!\n"]) do emuterm
    print(emuterm, "Please enter your name: ")
    name = strip(readline(emuterm))
    print(emuterm, "\nHello $name. Do you like tests? ")
    resp = strip(readline(emuterm))
    @assert resp == "Yes!!"
end

mktemp() do _, io
    redirect_stderr(io) do
        redirect_stdout(io) do
            @test_throws ErrorException TerminalRegressionTests.automated_test(
                            joinpath(thisdir,"TRT2.multiout"),
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
const cmp(a, b, decorator) = compare_replace(a, b; replace="wurld"=>"world")
TerminalRegressionTests.automated_test(cmp,
                joinpath(thisdir,"TRT2.multiout"),
                [""]) do emuterm
    println(emuterm, "Hello, world!")
    readline(emuterm)
end
