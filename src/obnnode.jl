# Interface with openBuildNet node

# A callback = a function + optional arguments in a tuple
typealias OBNCallback Tuple{Function,Tuple}
Base.call(f::OBNCallback) = f[1](f[2]...) # Make the callback callable
OBNCallback() = OBNCallback((() -> nothing, ()))

typealias InputPortDict Dict{Cint,OBNInputAbstract}

# An openBuildNet node
type OBNNode
  node_id::Csize_t
  valid::Bool

  # Dictionary of input ports
  input_ports::InputPortDict

  # Callbacks
  block_output_cb::Dict{Int64,OBNCallback}
  block_state_cb::Dict{Int64,OBNCallback}

  init_cb::OBNCallback
  restart_cb::OBNCallback
  term_cb::OBNCallback

  function OBNNode(name::ASCIIString, workspace::ASCIIString = "", server::ASCIIString = "")
    myid = Ref{Csize_t}(0)  # To receive the node id
    result = ccall(_api_createOBNNode, Cint, (Cstring, Cstring, Cstring, Ref{Csize_t}), name, workspace, server, myid)
    if result != 0
      error("Error creating openBuildNet node [$result]: ", lastErrorMessage())
    end

    obj = new(myid[],                       # id
              true,                         # valid
              InputPortDict(),              # dictionary of input ports
              Dict{Int64,OBNCallback}(),    # output Callbacks
              Dict{Int64,OBNCallback}(),    # state callbacks
              OBNCallback(),                # init callback
              OBNCallback(),                # restart callback
              OBNCallback())                # terminate callback
    finalizer(obj, x -> delete(x))
    obj
  end
end

# Delete / destroy a node
function delete(node::OBNNode)
  if node.valid
    ccall(_api_deleteOBNNode, Cint, (Csize_t,), node.node_id);
    node.valid = false
    true
  else
    false
  end
end

# Set callback for computing outputs of a block (UPDATE_Y)
function on_block_output(f::Function, node::OBNNode, blkid::Integer, optargs...)
  @assert node.valid "Node is not valid."

  if blkid < 0 || blkid > max_blockid()
    error("Invalid computation block ID.")
  end

  node.block_output_cb[blkid] = OBNCallback( (f, optargs) )
end

function on_block_state(f::Function, node::OBNNode, blkid::Integer, optargs...)
  @assert node.valid "Node is not valid."

  if blkid < 0 || blkid > max_blockid()
    error("Invalid computation block ID.")
  end

  node.block_state_cb[blkid] = OBNCallback( (f, optargs) )
end

function on_init(f::Function, node::OBNNode, optargs...)
  @assert node.valid "Node is not valid."

  node.init_cb = OBNCallback( (f, optargs) )
end

function on_restart(f::Function, node::OBNNode, optargs...)
  @assert node.valid "Node is not valid."

  node.restart_cb = OBNCallback( (f, optargs) )
end

function on_term(f::Function, node::OBNNode, optargs...)
  if !node.valid
    error("Node is not valid.")
  end

  node.term_cb = OBNCallback( (f, optargs) )
end

function do_updatey(node::OBNNode, mask::OBNUpdateMask)
  for (id,f) in node.block_output_cb
    if mask == 0
      break;
    end
    if (mask & (1 << id)) != 0
      # If the id is in the mask, run the callback
      f()
      mask $= (1 << id)   # reset that bit
    end
  end
end

function do_updatex(node::OBNNode, mask::OBNUpdateMask)
  for (id,f) in node.block_state_cb
    if mask == 0
      break;
    end
    if (mask & (1 << id)) != 0
      # If the id is in the mask, run the callback
      f()
      mask $= (1 << id)   # reset that bit
    end
  end
end

import Base.run

"""
    run(OBNNode, timeout, stopIfTimeout)

Run simulation

If stopIfTimeout is true [default], the node will automatically  stop if there is a timeout error

Returns: 1 if timeout; 2 if the simulation stopped properly; 3 if stopped with an error
"""
function run(node::OBNNode, timeout::Number = -1.0, stopIfTimeout::Bool = true)
  @assert node.valid "Node is not valid."

  if iserror(node)
    error("Node currently has error and cannot run; clear the error first by calling stopSimulation.")
  end

  # If the node is running --> may be not right, give a warning
  if isrunning(node)
    warn("Node is currently running; may be an error but we will run it anyway.")
  end

  # timeoutStart = tic;

  event_type = Ref{OBNEI_EventType}()
  event_args = Ref{OBNEI_EventArg}()

  result = 0

  while result == 0
    result = ccall(_api_simRunStep, Cint, (Csize_t, Cdouble, Ref{OBNEI_EventType}, Ref{OBNEI_EventArg}), node.node_id, timeout, event_type, event_args)

    if result == 0
      # Got an event
      if event_type[] == OBNEI_Event_Y
        do_updatey(node, event_args[].mask)
      elseif event_type[] == OBNEI_Event_X
        do_updatex(node, event_args[].mask)
      elseif event_type[] == OBNEI_Event_INIT
        event_result = node.init_cb()
        if isa(event_result, Integer)
          # Set the event result to OBN
          ccall(_api_simSetEventResult, Cint, (Csize_t, Int64), node.node_id, event_result)
        end
      elseif event_type[] == OBNEI_Event_TERM
        node.term_cb()
      elseif event_type[] == OBNEI_Event_RESTART
        event_result = node.restart_cb()
        if isa(event_result, Integer)
          # Set the event result to OBN
          ccall(_api_simSetEventResult, Cint, (Csize_t, Int64), node.node_id, event_result)
        end
      elseif event_type[] == OBNEI_Event_RCV
        # Port's RCV event
        portid = Cint(event_args[].index)
        if haskey(node.input_ports, portid)
          node.input_ports[portid].rcv_cb()
        else
          warn("Input port $portid does not exist.")
        end
      else
        error("Internal error: Unknown event type.")
      end
    elseif result == 1
      # Timeout
      warn("Simulation has timed out.")
      if stopIfTimeout
        # Stop the simulation immediately
        stop(node, true)
      end
      # if toc(timeoutStart) > timeout
      #     % Real timeout error occurred
      #     if stopIfTimeout
      #         this(k).stopSimulation();  % stop the simulation immediately
      #     end
      #     b(k) = false;
      # else
      #     % We can continue running the simulation
      #     status(k) = 0;
      # end
    elseif result == 2
      # Stop properly
      # disp(['Simulation of node ' this(k).obnnode_nodeName ' has stopped properly.']);
    elseif result == 3
      # Stop with error
      warn("Simulation has stopped due to an error: ", lastErrorMessage())
    else
      error("Internal error: Unknown running state ", result)
    end
  end
  result
end

# Similar to run(node) but it catches any exception (error) from Julia and will try to stop the simulation properly before re-throwing the exception.
# This could be useful for scripts (vs. the REPL) because any runtime exception will cause the script to stop abruptly and the simulation may stuck (of course the SMN may terminate the simulation manually).
# Alternatively the user can wrap run(node) inside try...catch or try...finally to achieve the same result.
function runsafe(node::OBNNode, timeout::Number = -1.0, stopIfTimeout::Bool = true)
  @assert node.valid "Node is not valid."

  result = 3
  try
    result = run(node, timeout, stopIfTimeout)
  catch
    stop(node, true)
    rethrow()
  end
  result
end

# Wait for and process the next port event (by executing its callback), up until a given
# timeout (in seconds, can be non-positive for no timeout).
# Returns true if an event has been processed; false otherwise (timeout).
# This method is useful for event-triggered processing inside another callback.
function process_port_events(node::OBNNode, timeout::Number = -1.0)
  @assert node.valid "Node is not valid."

  # Get the next port event
  event_type = Ref{OBNEI_EventType}()
  portid = Ref{Csize_t}()
  result = ccall(_api_simGetPortEvent, Cint, (Csize_t, Cdouble, Ref{OBNEI_EventType}, Ref{Csize_t}), node.node_id, timeout, event_type, portid)

  if result != 0
    return false
  end

  if event_type[] == OBNEI_Event_RCV
    # A message received at a port
    if haskey(node.input_ports, portid[])
      node.input_ports[portid[]].rcv_cb()
    else
      warn("Input port $(portid[]) does not exist.")
      return false
    end
  else
    # An unexpected event is returned -> error
    error("Internal error: unexpected event type $(event_type[]).")
  end
  return true
end

# Stop the simulation.
# If stopnow is false [default], the node will only request the SMN to stop simulation.
# If the SMN accepts the request, it will send a TERM message to all nodes, including this one.
# If stopnow is true, the node will stop its simulation immediately regardless (after sending the request to the SMN).
# Returns true if successful
function stop(node::OBNNode, stopnow::Bool = false)
  @assert node.valid "Node is not valid."

  result = stopnow?ccall(_api_nodeStopSimulation, Cint, (Csize_t,), node.node_id):ccall(_api_nodeRequestStopSimulation, Cint, (Csize_t,), node.node_id)
  result == 0
end

# Requests a triggering (i.e., update) of certain blocks at a future time (in clock ticks)
# Here the time is in the clock ticks, i.e., the number of atomic time units from the beginning of the simulation.
# Returns the status of the request:
# 0 if successful (accepted), -1 if timeout (failed), -2 if request is invalid, >0 if other errors (failed, see OBN documents for details).
import Base.schedule
function schedule(node::OBNNode, blks::OBNUpdateMask, t::OBNSimTimeType, timeout::Number = -1.0)
  @assert node.valid "Node is not valid."

  ccall(_api_simRequestFutureUpdate, Cint, (Csize_t, OBNSimTimeType, OBNUpdateMask, Cdouble), node.node_id, t, blks, timeout)
end

# Requests a triggering (i.e., update) of certain blocks at a future time.
# Here, the time is given in simulation time with a given unit (default = seconds) from the beginning of the simulation.
# Valid units are :s, :m, :h, :ms, :us
# This function converts the future time to the atomic clock ticks and call the default method
function schedule(node::OBNNode, blks::OBNUpdateMask, t::Number, tu::Symbol = :s, timeout::Number = -1.0)
  atomictu = timeunit(node)

  # Convert t to clock ticks
  const tu_scale = Dict{Symbol,Float64}(:s => 1e6, :ms => 1e3, :us => 1, :m => 60*1e6, :h => 60*60*1e6)
  clkticks = ceil(OBNSimTimeType, t*tu_scale[tu] / atomictu)

  schedule(node, blks, clkticks, timeout)
end

# Requests a triggering (i.e., update) of certain blocks at a future time.
# Here, the time is given in wallclock time.
# This function converts the future time to the atomic clock ticks and call the default method
function schedule(node::OBNNode, blks::OBNUpdateMask, t::DateTime, timeout::Number = -1.0)
  # Duration until the requested future time, in milliseconds
  dt = t - wallclock_time(node)
  @assert dt.value>0 "Requested time must be strictly in the future."

  schedule(node, blks, sim_time(node, :ms) + dt.value, :ms, timeout)
end

# Get current simulation time in given unit
# Possible units as symbols: us, ms, s, m, h
function sim_time(node::OBNNode, unit::Symbol = :s)
  @assert node.valid "Node is not valid."

  # Time unit: 0 = second, -1 = millisecond, -2 = microsecond, 1 = minute, 2 = hour
  const timeunits = Dict{Symbol,Cint}(:s => 0, :ms => -1, :us => -2, :m => 1, :h => 2)
  @assert haskey(timeunits, unit) "Invalid time unit."

  curtime = Ref{Cdouble}(0.0)
  result = ccall(_api_nodeSimulationTime, Cint, (Csize_t, Cint, Ref{Cdouble}), node.node_id, timeunits[unit], curtime)
  if result != 0
    error("Error querying the simulation time [$result]: ", lastErrorMessage())
  end
  curtime[]
end

# Returns the atomic time unit as an integer in microseconds
function timeunit(node::OBNNode)
  @assert node.valid "Node is not valid."

  tu = Ref{OBNSimTimeType}(0)
  result = ccall(_api_nodeTimeUnit, Cint, (Csize_t, Ref{OBNSimTimeType}), node.node_id, tu)
  if result != 0
    error("Error querying the time unit [$result]: ", lastErrorMessage())
  end
  tu[]
end

# Get current wallclock time as Julia's DateTime
function wallclock_time(node::OBNNode)
  @assert node.valid "Node is not valid."

  unixtime = Ref{Int64}(0)
  result = ccall(_api_nodeWallClockTime, Cint, (Csize_t, Ref{Int64}), node.node_id, unixtime)
  if result != 0
    error("Error querying the wallclock time [$result]: ", lastErrorMessage())
  end

  Dates.unix2datetime(unixtime[])
end

# Internal function to check state of node
function _is_state(node::OBNNode, api::Ptr{Void})
  @assert node.valid "Node is not valid."

  result = ccall(api, Cint, (Csize_t,), node.node_id)
  (result<0)?error("Error querying node's state."):(result>0)
end

# Check node's state
isstopped(node::OBNNode) = _is_state(node, _api_nodeIsStopped)
isrunning(node::OBNNode) = _is_state(node, _api_nodeIsRunning)
iserror(node::OBNNode) = _is_state(node, _api_nodeIsError)
