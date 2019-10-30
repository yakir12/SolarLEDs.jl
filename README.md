# SolarLEDs.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/yakir12/SolarLEDs.jl.svg?branch=master)](https://travis-ci.com/yakir12/SolarLEDs.jl)
[![codecov.io](http://codecov.io/github/yakir12/SolarLEDs.jl/coverage.svg?branch=master)](http://codecov.io/github/yakir12/SolarLEDs.jl?branch=master)

This is a package for controlling LED strips and simulating multiple "sun"s. 


## How to install
1. If you haven't already, install the current release of [Julia](https://julialang.org/downloads/) -> you should be able to launch it (some icon on the Desktop or some such).
2. Start Julia -> a Julia-terminal popped up.
3. type closed-square-bracket `]` once, you'll see the promt changing from `julia>` to `(v1.2) pkg>`
3. Copy: 
   ```julia
   add https://github.com/yakir12/SolarLEDs.jl
   ```
   and paste it in the newly opened Julia-terminal (make sure you ), press Enter (this may take some time), and when it's done press BackSpace (or Delete) until the promt changes back to `julia>`.

## How to run
1. Copy: 
   ```julia
   main()
   ```
   and paste it in the newly opened Julia-terminal (make sure you ), press Enter (this may take some time).
2. A GUI-window will pop up, use this to control your LED strip and set the IR remote control.
