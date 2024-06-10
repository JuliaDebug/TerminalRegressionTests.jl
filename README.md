# TerminalRegressionTests - Test your terminal UIs for regressions

[![CI](https://github.com/JuliaDebug/TerminalRegressionTests.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaDebug/TerminalRegressionTests.jl/actions/workflows/CI.yml)

This package builds upon the [VT100.jl](https://github.com/Keno/VT100.jl)
package to provide automated testing of terminal based application. Both
plain text and formatted output is supported. Each test consists of

 - The system under test (specified as a callback)
 - A file specifying the expected output
 - A series of input prompts

The main interface is the `automated_test` function, which takes these three
components as arguemnts. There is also the `create_automated_test` function,
which has the same interface, but will create the output file rather than
verifying against it. The operation of the test is fairly simple:

1. An input is popped from the list of inputs
2. The input is provided to the system under test
3. The system under test is allowed to process the input until the system is
   done processing the input and has started blocking until new input is
   available
4. The output that the system writes is compared to the output file.
5. Repeat

# Usage

Consider the following example:

```
TerminalRegressionTests.automated_test(
                joinpath(thisdir,"TRT.multiout"),
                ["Julia\n","Yes!!\n"]) do emuterm
    print(emuterm, "Please enter your name: ")
    name = strip(readline(emuterm))
    print(emuterm, "\nHello $name. Do you like tests? ")
    resp = strip(readline(emuterm))
    @assert resp == "Yes!!"
end
```

Note that the callback gets an `emuterm` as an argument. This is an emulated
VT100 terminal and supports the usual operation. Note that this terminal is the
view from the program under test (i.e. reads from this terminal will obtain
the specified input data).
