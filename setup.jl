import Pkg

Pkg.activate((@__DIR__))

Pkg.add(url="https://github.com/MATH2064-Group-18/Swirl.jl", rev="release-0.2.1")

Pkg.instantiate()