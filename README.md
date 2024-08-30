# Group Project -- Group 18

Welcome! For our MATH2064 project, we have chosen **Real-Time Fluid Simulation**. To make it easier to use, we have turned the core of this project into its own Julia package [Swirl.jl](https://github.com/MATH2064-Group-18/Swirl.jl), which can be added to any project using:
```julia
Pkg.add("https://github.com/MATH2064-Group-18/Swirl.jl")
```

In this repo you will find some demos using it.


## Setup

First open a terminal window with this as the working directory.
Next start the Julia REPL with this directory as the active environment using:
```bash
julia --project
```
Finally, type `]` and run:
```julia
pkg> instantiate
```
Finished! Now you are ready to run the included demos. Inside each folder, the README contains instructions for how to run.

## Gallery

![Swirl](examples/swirl.jpg)
![Karman Vortex Street Image](examples/karman_vortex_street.png)