module openbuildnet

export
# Basics
OBNUpdateMask, OBNSimTimeType,

# Node interface
OBNNode, delete,
on_block_output, on_block_state, on_init, on_term, on_restart,
run, runsafe, process_port_events, stop, schedule,
isstopped, isrunning, iserror,
sim_time, timeunit, wallclock_time,

# Port interface
OBNPort, OBNInputAbstract, OBNOutputAbstract, OBNInput, OBNOutput,
create_input, create_output,
get, set, sendsync, pending, connectfrom, portinfo,
on_receive,

# Misc
lastErrorMessage, max_blockid,
update_mask

include("obndefs.jl")
include("obnextapi.jl")
include("obnnode.jl")
include("obnport.jl")

end # module
