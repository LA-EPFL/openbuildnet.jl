# Interface for openBuildNet's ports

type OBNInput{T} <: OBNInputAbstract
  name::String
  node::OBNNode
  portid::Cint
  strict::Bool
  rcv_cb::OBNCallback    # Callback for message receive

  function OBNInput(name::String, node::OBNNode, portid::Cint, strict::Bool)
    obj = new(name, node, portid, strict, OBNCallback())
    node.input_ports[portid] = obj    # Add the input port object to the node, so we can refer to it later on
    finalizer(obj, x -> delete!(x.node.input_ports, x.portid))  # Remove the port from node if it's deleted
    obj
  end
end

type OBNOutput{T} <: OBNOutputAbstract
  name::String
  node::OBNNode
  portid::Cint
end

typealias OBNEI_PortType Cuint
typealias OBNEI_ContainerType Cuint
typealias OBNEI_ElementType Cuint
typealias OBNEI_FormatType Cuint

# Type to pass port's info
type OBNEI_PortInfo
  port_type::OBNEI_PortType
  container_type::OBNEI_ContainerType
  element_type::OBNEI_ElementType
  strict::Cuchar
end

const OBNEI_Port_Input = convert(OBNEI_PortType, 0)
const OBNEI_Port_Output = convert(OBNEI_PortType, 1)
const OBNEI_Port_Data = convert(OBNEI_PortType, 2)

# const OBNEI_Container_Scalar = convert(OBNEI_ContainerType, 0)
# const OBNEI_Container_Vector = convert(OBNEI_ContainerType, 1)
# const OBNEI_Container_Matrix = convert(OBNEI_ContainerType, 2)
# const OBNEI_Container_Binary = convert(OBNEI_ContainerType, 3)

elementtypeid(::Type{Bool}) = convert(OBNEI_ElementType, 0)
elementtypeid(::Type{Float64}) = convert(OBNEI_ElementType, 1)
elementtypeid(::Type{Int32}) = convert(OBNEI_ElementType, 2)
elementtypeid(::Type{Int64}) = convert(OBNEI_ElementType, 3)
elementtypeid(::Type{UInt32}) = convert(OBNEI_ElementType, 4)
elementtypeid(::Type{UInt64}) = convert(OBNEI_ElementType, 5)

function obntypeid{T}(::Type{T})
  (convert(OBNEI_ContainerType, 0), elementtypeid(T))
end

function obntypeid{T}(::Type{Vector{T}})
  (convert(OBNEI_ContainerType, 1), elementtypeid(T))
end

function obntypeid{T}(::Type{Matrix{T}})
  (convert(OBNEI_ContainerType, 2), elementtypeid(T))
end

const OBNEI_Format_ProtoBuf = convert(OBNEI_FormatType, 0)

# Create an input / output port on a node
# Currently only ProtoBuf (format = :PB) is supported
function create_input(node::OBNNode, name::String, T::DataType, strict::Bool = false, format::Symbol = :PB)
  @assert node.valid "Not allowed to create ports on non-valid node."

  if format == :PB || format == :ProtoBuf
    # Get the container and element types
    container, elementtype = obntypeid(T)
    result = ccall(_api_createInputPort, Cint, (Csize_t, Cstring, OBNEI_FormatType, OBNEI_ContainerType, OBNEI_ElementType, Cuchar),
                   node.node_id, name, OBNEI_Format_ProtoBuf, container, elementtype, strict)
    if result < 0
      error("Error creating input port [$result]: ", lastErrorMessage())
    else
      return OBNInput{T}(name, node, result, strict)
    end
  else
    error("Unsupported format: ", format)
  end
end

function create_output(node::OBNNode, name::String, T::DataType, format::Symbol = :PB)
  @assert node.valid "Not allowed to create ports on non-valid node."

  if format == :PB || format == :ProtoBuf
    # Get the container and element types
    container, elementtype = obntypeid(T)
    result = ccall(_api_createOutputPort, Cint, (Csize_t, Cstring, OBNEI_FormatType, OBNEI_ContainerType, OBNEI_ElementType),
                   node.node_id, name, OBNEI_Format_ProtoBuf, container, elementtype)
    if result < 0
      error("Error creating output port [$result]: ", lastErrorMessage())
    else
      return OBNOutput{T}(name, node, result)
    end
  else
    error("Unsupported format: ", format)
  end
end

# Read a Vector port, with possibly a default value (in case a strict port has no pending value to read from)
# function get{T}(port::OBNInput{Vector{T}}, defval = nothing)
# end

_scalar_input_api(::Type{Float64}) = _api_inputScalarDoubleGet
_scalar_input_api(::Type{Int32}) = _api_inputScalarInt32Get
_scalar_input_api(::Type{Int64}) = _api_inputScalarInt64Get
_scalar_input_api(::Type{UInt32}) = _api_inputScalarUInt32Get
_scalar_input_api(::Type{UInt64}) = _api_inputScalarUInt64Get
_scalar_input_api(::Type{Bool}) = _api_inputScalarBoolGet

_vector_input_api(::Type{Float64}) = (_api_inputVectorDoubleGet, _api_inputVectorDoubleRelease)
_vector_input_api(::Type{Int32}) = (_api_inputVectorInt32Get, _api_inputVectorInt32Release)
_vector_input_api(::Type{Int64}) = (_api_inputVectorInt64Get, _api_inputVectorInt64Release)
_vector_input_api(::Type{UInt32}) = (_api_inputVectorUInt32Get, _api_inputVectorUInt32Release)
_vector_input_api(::Type{UInt64}) = (_api_inputVectorUInt64Get, _api_inputVectorUInt64Release)
_vector_input_api(::Type{Bool}) = (_api_inputVectorBoolGet, _api_inputVectorBoolRelease)

_matrix_input_api(::Type{Float64}) = (_api_inputMatrixDoubleGet, _api_inputMatrixDoubleRelease)
_matrix_input_api(::Type{Int32}) = (_api_inputMatrixInt32Get, _api_inputMatrixInt32Release)
_matrix_input_api(::Type{Int64}) = (_api_inputMatrixInt64Get, _api_inputMatrixInt64Release)
_matrix_input_api(::Type{UInt32}) = (_api_inputMatrixUInt32Get, _api_inputMatrixUInt32Release)
_matrix_input_api(::Type{UInt64}) = (_api_inputMatrixUInt64Get, _api_inputMatrixUInt64Release)
_matrix_input_api(::Type{Bool}) = (_api_inputMatrixBoolGet, _api_inputMatrixBoolRelease)

import Base.get

# Read a scalar port, with possibly a default value (in case a strict port has no pending value to read from)
function get{T}(port::OBNInput{T}, defval = nothing)
  @assert port.node.valid

  val = Ref{T}()
  result = ccall(_scalar_input_api(T), Cint, (Csize_t, Csize_t, Ref{T}), port.node.node_id, port.portid, val)

  if result < 0
    error("Error reading from input [$result]: ", lastErrorMessage())
  end
  (result==0)?val[]:defval
end

# function get(port::OBNInput{Bool}, defval = nothing)
#   @assert port.node.valid
#
#   val = Ref{Cuchar}()
#   result = ccall(_api_inputScalarBoolGet, Cint, (Csize_t, Csize_t, Ref{Cuchar}), port.node.node_id, port.portid, val)
#
#   if result < 0
#     error("Error reading from input [$result]", lastErrorMessage())
#   end
#   (result==0)?convert(Bool,val[]):defval
# end

# Read a vector port, with possibly a default value (in case a strict port has no pending value to read from)
function get{T}(port::OBNInput{Vector{T}}, defval = nothing)
  @assert port.node.valid

  (getapi, releaseapi) = _vector_input_api(T)

  manobj = Ref{Ptr{Void}}()
  nelems = Ref{Csize_t}(0)
  result = ccall(getapi, Cint, (Csize_t, Csize_t, Ref{Ptr{Void}}, Ptr{Ptr{T}}, Ref{Csize_t}), port.node.node_id, port.portid, manobj, C_NULL, nelems)

  if result < 0
    error("Error reading from input [$result]: ", lastErrorMessage())
  end

  if result == 0
    val = Vector{T}(nelems[])
    if nelems[] > 0
      ccall(releaseapi, Void, (Ptr{Void}, Ref{T}), manobj[], val)
    else
      ccall(releaseapi, Void, (Ptr{Void}, Ptr{T}), manobj[], C_NULL)
    end
    val
  else
    defval
  end
end

# function get(port::OBNInput{Vector{Bool}}, defval = nothing)
#   @assert port.node.valid
#
#   manobj = Ref{Ptr{Void}}()
#   nelems = Ref{Csize_t}(0)
#   result = ccall(_api_inputVectorBoolGet, Cint, (Csize_t, Csize_t, Ref{Ptr{Void}}, Ptr{Ptr{Cuchar}}, Ref{Csize_t}), port.node.node_id, port.portid, manobj, C_NULL, nelems)
#
#   if result < 0 || nelems[] < 0
#     error("Error reading from input [$result]", lastErrorMessage())
#   end
#
#   if result == 0
#     val = Vector{Bool}(nelems[])
#     if nelems[] > 0
#       ccall(_api_inputVectorBoolRelease, Void, (Ptr{Void}, Ref{Cuchar}), manobj[], val)
#     else
#       ccall(_api_inputVectorBoolRelease, Void, (Ptr{Void}, Ptr{Cuchar}), manobj[], C_NULL)
#     end
#     val
#   else
#     defval
#   end
# end

# Read a matrix port, with possibly a default value (in case a strict port has no pending value to read from)
function get{T}(port::OBNInput{Matrix{T}}, defval = nothing)
  @assert port.node.valid

  (getapi, releaseapi) = _matrix_input_api(T)

  manobj = Ref{Ptr{Void}}()
  nrows = Ref{Csize_t}(0)
  ncols = Ref{Csize_t}(0)
  result = ccall(getapi, Cint, (Csize_t, Csize_t, Ref{Ptr{Void}}, Ptr{Ptr{T}}, Ref{Csize_t}, Ref{Csize_t}), port.node.node_id, port.portid, manobj, C_NULL, nrows, ncols)

  if result < 0
    error("Error reading from input [$result]: ", lastErrorMessage())
  end

  if result == 0
    val = Matrix{T}(nrows[], ncols[])
    if nrows[] > 0 && ncols[] > 0
      ccall(releaseapi, Void, (Ptr{Void}, Ref{T}), manobj[], val)
    else
      ccall(releaseapi, Void, (Ptr{Void}, Ptr{T}), manobj[], C_NULL)
    end
    val
  else
    defval
  end
end


# Ask an output port to send (Synchronously)
# Returns true if successful; check lastErrorMessage() otherwise
function sendsync(port::OBNOutputAbstract)
  @assert port.node.valid
  result = ccall(_api_outputSendSync, Cint, (Csize_t, Csize_t), port.node.node_id, port.portid)
  result == 0
end

function sendsync(port::OBNOutputAbstract, val)
  set(port, val)
  sendsync(port)
end

_scalar_output_api(::Type{Float64}) = _api_outputScalarDoubleSet
_scalar_output_api(::Type{Int32}) = _api_outputScalarInt32Set
_scalar_output_api(::Type{Int64}) = _api_outputScalarInt64Set
_scalar_output_api(::Type{UInt32}) = _api_outputScalarUInt32Set
_scalar_output_api(::Type{UInt64}) = _api_outputScalarUInt64Set
_scalar_output_api(::Type{Bool}) = _api_outputScalarBoolSet

_vector_output_api(::Type{Float64}) = _api_outputVectorDoubleSet
_vector_output_api(::Type{Int32}) = _api_outputVectorInt32Set
_vector_output_api(::Type{Int64}) = _api_outputVectorInt64Set
_vector_output_api(::Type{UInt32}) = _api_outputVectorUInt32Set
_vector_output_api(::Type{UInt64}) = _api_outputVectorUInt64Set
_vector_output_api(::Type{Bool}) = _api_outputVectorBoolSet

_matrix_output_api(::Type{Float64}) = _api_outputMatrixDoubleSet
_matrix_output_api(::Type{Int32}) = _api_outputMatrixInt32Set
_matrix_output_api(::Type{Int64}) = _api_outputMatrixInt64Set
_matrix_output_api(::Type{UInt32}) = _api_outputMatrixUInt32Set
_matrix_output_api(::Type{UInt64}) = _api_outputMatrixUInt64Set
_matrix_output_api(::Type{Bool}) = _api_outputMatrixBoolSet

# Write to a scalar port
function set{T}(port::OBNOutput{T}, val::T)
  @assert port.node.valid
  result = ccall(_scalar_output_api(T), Cint, (Csize_t, Csize_t, T), port.node.node_id, port.portid, val)

  if result < 0
    error("Error writing to output [$result]: ", lastErrorMessage())
  end
  result
end

# function set(port::OBNOutput{Bool}, val::Bool)
#   @assert port.node.valid
#   result = ccall(_api_outputScalarBoolSet, Cint, (Csize_t, Csize_t, Cuchar), port.node.node_id, port.portid, val)
#
#   if result < 0
#     error("Error writing to output [$result]", lastErrorMessage())
#   end
# end

# Write to a vector port
function set{T}(port::OBNOutput{Vector{T}}, val::Vector{T})
  @assert port.node.valid
  result = ccall(_vector_output_api(T), Cint, (Csize_t, Csize_t, Ref{T}, Csize_t), port.node.node_id, port.portid, val, length(val))

  if result < 0
    error("Error writing to output [$result]: ", lastErrorMessage())
  end
  result
end

# Write to a matrix port
function set{T}(port::OBNOutput{Matrix{T}}, val::Matrix{T})
  @assert port.node.valid
  nr, nc = size(val)
  result = ccall(_matrix_output_api(T), Cint, (Csize_t, Csize_t, Ref{T}, Csize_t, Csize_t), port.node.node_id, port.portid, val, nr, nc)

  if result < 0
    error("Error writing to output [$result]: ", lastErrorMessage())
  end
  result
end

# Query if a port has a pending value
function pending(port::OBNInputAbstract)
  @assert port.node.valid
  result = ccall(_api_inputPending, Cint, (Csize_t, Csize_t), port.node.node_id, port.portid)
  result > 0
end

# Connect a given port to an input port
# Returns true if successful; check lastErrorMessage() otherwise
function connectfrom(port::OBNInputAbstract, other::String)
  @assert port.node.valid
  result = ccall(_api_portConnect, Cint, (Csize_t, Csize_t, Cstring), port.node.node_id, port.portid, other)
  result == 0
end

# Get port's information
function portinfo(port::OBNPort)
  @assert port.node.valid

  info = Ref{OBNEI_PortInfo}()
  result = ccall(_api_portInfo, Cint, (Csize_t, Csize_t, Ref{OBNEI_PortInfo}), port.node.node_id, port.portid, info)

  if result != 0
    error("Error getting port information [$result]: ", lastErrorMessage())
  end
  info[]
end

# Callback when a message is received on an input port
# Returns true if successful
function on_receive(f::Function, port::OBNInputAbstract, optargs...)
  @assert port.node.valid
  result = ccall(_api_portEnableRcvEvent, Cint, (Csize_t, Csize_t), port.node.node_id, port.portid)
  if result == 0
    port.rcv_cb = OBNCallback( (f, optargs) )
    return true
  else
    return false
  end
end
