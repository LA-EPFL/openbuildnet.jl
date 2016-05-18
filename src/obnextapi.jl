# Pre-defined C-function API of the dynamically loaded library of openBuildNet

libobnext = C_NULL

function load_obnlibext()
    global libobnext
    if libobnext == C_NULL
        libobnext = Libdl.dlopen("libobnext-mqtt", Libdl.RTLD_GLOBAL | Libdl.RTLD_LAZY)

        if libobnext == C_NULL
            error("Failed to load the openBuildNet External Interface Library (libobnext-mqtt).")
        end
    end
end

load_obnlibext()

# The C API exported from the library
# See the header file obnnode_ext.h for details.

# Mask type to specify which blocks are to be triggered
typealias OBNUpdateMask UInt64

# Simulation time type
typealias OBNSimTimeType Int64

# Event type (C enum) and possible values
typealias OBNEI_EventType Cuint
const OBNEI_Event_INIT = convert(OBNEI_EventType, 0)
const OBNEI_Event_Y = convert(OBNEI_EventType, 1)
const OBNEI_Event_X = convert(OBNEI_EventType, 2)
const OBNEI_Event_TERM = convert(OBNEI_EventType, 3)
const OBNEI_Event_RCV = convert(OBNEI_EventType, 4)

# Type to pass arguments of an event (C struct)
immutable OBNEI_EventArg
  mask::OBNUpdateMask
  index::Csize_t
end

# Node interface
const _api_createOBNNode = Libdl.dlsym(libobnext::Ptr{Void}, :createOBNNode)
const _api_deleteOBNNode = Libdl.dlsym(libobnext::Ptr{Void}, :deleteOBNNode)
const _api_nodeStopSimulation = Libdl.dlsym(libobnext::Ptr{Void}, :nodeStopSimulation)
const _api_nodeRequestStopSimulation = Libdl.dlsym(libobnext::Ptr{Void}, :nodeRequestStopSimulation)

const _api_nodeIsStopped = Libdl.dlsym(libobnext::Ptr{Void}, :nodeIsStopped)
const _api_nodeIsError = Libdl.dlsym(libobnext::Ptr{Void}, :nodeIsError)
const _api_nodeIsRunning = Libdl.dlsym(libobnext::Ptr{Void}, :nodeIsRunning)

const _api_nodeSimulationTime = Libdl.dlsym(libobnext::Ptr{Void}, :nodeSimulationTime)
const _api_nodeWallClockTime = Libdl.dlsym(libobnext::Ptr{Void}, :nodeWallClockTime)
const _api_nodeTimeUnit = Libdl.dlsym(libobnext::Ptr{Void}, :nodeTimeUnit)

const _api_simRunStep = Libdl.dlsym(libobnext::Ptr{Void}, :simRunStep)
const _api_simRequestFutureUpdate = Libdl.dlsym(libobnext::Ptr{Void}, :simRequestFutureUpdate)

# Port interface
const _api_createInputPort = Libdl.dlsym(libobnext::Ptr{Void}, :createInputPort)
const _api_createOutputPort = Libdl.dlsym(libobnext::Ptr{Void}, :createOutputPort)
const _api_inputPending = Libdl.dlsym(libobnext::Ptr{Void}, :inputPending)
const _api_portConnect = Libdl.dlsym(libobnext::Ptr{Void}, :portConnect)
const _api_outputSendSync = Libdl.dlsym(libobnext::Ptr{Void}, :outputSendSync)
const _api_portInfo = Libdl.dlsym(libobnext::Ptr{Void}, :portInfo)
const _api_portEnableRcvEvent = Libdl.dlsym(libobnext::Ptr{Void}, :portEnableRcvEvent)

# Scalar inputs
const _api_inputScalarDoubleGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarDoubleGet)
const _api_inputScalarBoolGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarBoolGet)
const _api_inputScalarInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarInt32Get)
const _api_inputScalarInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarInt64Get)
const _api_inputScalarUInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarUInt32Get)
const _api_inputScalarUInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputScalarUInt64Get)

# Vector inputs
const _api_inputVectorDoubleGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorDoubleGet)
const _api_inputVectorDoubleRelease = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorDoubleRelease)

const _api_inputVectorBoolGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorBoolGet)
const _api_inputVectorBoolRelease = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorBoolRelease)

const _api_inputVectorInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorInt32Get)
const _api_inputVectorInt32Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorInt32Release)

const _api_inputVectorInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorInt64Get)
const _api_inputVectorInt64Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorInt64Release)

const _api_inputVectorUInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorUInt32Get)
const _api_inputVectorUInt32Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorUInt32Release)

const _api_inputVectorUInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorUInt64Get)
const _api_inputVectorUInt64Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputVectorUInt64Release)

# Matrix inputs
const _api_inputMatrixDoubleGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixDoubleGet)
const _api_inputMatrixDoubleRelease = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixDoubleRelease)

const _api_inputMatrixBoolGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixBoolGet)
const _api_inputMatrixBoolRelease = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixBoolRelease)

const _api_inputMatrixInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixInt32Get)
const _api_inputMatrixInt32Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixInt32Release)

const _api_inputMatrixInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixInt64Get)
const _api_inputMatrixInt64Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixInt64Release)

const _api_inputMatrixUInt32Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixUInt32Get)
const _api_inputMatrixUInt32Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixUInt32Release)

const _api_inputMatrixUInt64Get = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixUInt64Get)
const _api_inputMatrixUInt64Release = Libdl.dlsym(libobnext::Ptr{Void}, :inputMatrixUInt64Release)

# Scalar outputs
const _api_outputScalarDoubleSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarDoubleSet)
const _api_outputScalarBoolSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarBoolSet)
const _api_outputScalarInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarInt32Set)
const _api_outputScalarInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarInt64Set)
const _api_outputScalarUInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarUInt32Set)
const _api_outputScalarUInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputScalarUInt64Set)

# Vector outputs
const _api_outputVectorDoubleSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorDoubleSet)
const _api_outputVectorBoolSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorBoolSet)
const _api_outputVectorInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorInt32Set)
const _api_outputVectorInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorInt64Set)
const _api_outputVectorUInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorUInt32Set)
const _api_outputVectorUInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputVectorUInt64Set)

# Matrix outputs
const _api_outputMatrixDoubleSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixDoubleSet)
const _api_outputMatrixBoolSet = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixBoolSet)
const _api_outputMatrixInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixInt32Set)
const _api_outputMatrixInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixInt64Set)
const _api_outputMatrixUInt32Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixUInt32Set)
const _api_outputMatrixUInt64Set = Libdl.dlsym(libobnext::Ptr{Void}, :outputMatrixUInt64Set)


# Binary ports
const _api_inputBinaryGet = Libdl.dlsym(libobnext::Ptr{Void}, :inputBinaryGet)
const _api_inputBinaryRelease = Libdl.dlsym(libobnext::Ptr{Void}, :inputBinaryRelease)
const _api_outputBinarySet = Libdl.dlsym(libobnext::Ptr{Void}, :outputBinarySet)

# Misc
const _api_lastErrorMessage = Libdl.dlsym(libobnext::Ptr{Void}, :lastErrorMessage)
function lastErrorMessage()
  val = ccall(_api_lastErrorMessage, Ptr{UInt8}, ())
  if val == C_NULL
    error("Could not get OBN's last error message.")
  end
  bytestring(val)
end

const _api_maxUpdateID = Libdl.dlsym(libobnext::Ptr{Void}, :maxUpdateID)
max_blockid() = ccall(_api_maxUpdateID, Cint, ())

# Convert a list of block IDs into an update mask
function update_mask(blks...)
  mask = OBNUpdateMask(0)
  maxid = max_blockid()

  for id in blks
    iid = UInt64(id)  # Convert to unsigned int
    @assert iid<=maxid "Invalid block ID."

    mask |= (1 << iid)
  end
  mask
end
