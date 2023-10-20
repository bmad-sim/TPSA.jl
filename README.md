# TPSA

This package provides a full-featured Julia interface to the Generalised Truncated Power Series Algebra library MAD TPSA. The package will consist of two layers: a low-level, 1-to-1 Julia layer with the MAD TPSA C code, and a high-level, user-friendly layer that cleans up the notation for manipulating TPSAs, manages temporaries generated during evaluation, and properly manages the memory in C when variables go out of scope in Julia.

Currently, the first layer is complete, and development of the second layer is in progress.

For instructions on using TPSA.jl in its present development stage, see *Setup for Development* at https://bmad-sim.github.io/TPSA.jl/.
