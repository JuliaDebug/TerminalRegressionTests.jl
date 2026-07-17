using TerminalRegressionTests
using Test
import REPL

@testset "EmulatedTerminal" begin
    emuterm = TerminalRegressionTests.EmulatedTerminal()
    if isdefined(REPL.LineEdit, :hascolor)
        @test REPL.LineEdit.hascolor(emuterm)
    end
    try
        peek_task = @async peek(emuterm)
        wait_task = @async wait(emuterm)
        wait_done = timedwait(() -> istaskdone(wait_task), 10) == :ok
        @test wait_done
        wait_done && fetch(wait_task)
        @test emuterm.waiting
        print(emuterm.input_buffer, 'x')
        TerminalRegressionTests.notify_condition(emuterm.filled)
        peek_done = timedwait(() -> istaskdone(peek_task), 10) == :ok
        @test peek_done
        if peek_done
            @test fetch(peek_task) == UInt8('x')
            @test read(emuterm, Char) == 'x'
        end
    finally
        finalize(emuterm.pty)
    end
end

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
