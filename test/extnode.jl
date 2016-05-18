# Runs this script from the ../src folder.

include("../src/openbuildnet.jl")
importall openbuildnet

# Create the node
node = OBNNode("extnode", "testext")

# Create the ports
udouble = create_input(node, "input_scalardouble", Float64)
ydouble = create_output(node, "output_scalardouble", Float64)

uvector = create_input(node, "input_vectordouble", Vector{Float64})
yvector = create_output(node, "output_vectordouble", Vector{Float64})

umatrix = create_input(node, "input_matrixdouble", Matrix{Float64})
ymatrix = create_output(node, "output_matrixdouble", Matrix{Float64})

# Create Callbacks
on_init(node) do
  println("INIT")
end

on_term(node) do
  println("TERMINATE")
end

const MAINBLOCK = 0
d = 1.0
v = [2.1, 0.9]
m = [1.0 2.0; 3.0 4.0]

on_block_output(node, MAINBLOCK) do
  println("Current time is ", sim_time(node), "s.")
  #println("Current time is ", wallclock_time(node))
  println("Scalar double: ", get(udouble))
  println("Vector double: ", get(uvector))
  println("Matrix double: ", get(umatrix))

  global d
  set(ydouble, d)
  d += 1.0

  global v
  set(yvector, v)
  v += 0.5

  global m
  set(ymatrix, m)
  m += eye(2)

  schedule(node, update_mask(MAINBLOCK), sim_time(node)+0.5, :s, 1.0)
end

# Test the optional parameters given to callbacks
type TheState
  x::Float64
end
mystate = TheState(0.0)

on_block_state(node, MAINBLOCK, mystate) do s
  s.x += get(udouble)
  println("My new state: ", s.x)
end

println("Ready to start simulation...")
status = run(node, 20)
println("Final status: ", status)
