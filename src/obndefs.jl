# Basic definitions of openbuildnet.jl

abstract OBNPort    # Abstract port class

# A (physical) input port
abstract OBNInputAbstract <: OBNPort

# A (physical) output port
abstract OBNOutputAbstract <: OBNPort
