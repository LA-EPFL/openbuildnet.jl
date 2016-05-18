module openbuildnet

export
# Basics
OBNUpdateMask, OBNSimTimeType,

# Node interface
OBNNode, delete,
on_block_output, on_block_state, on_init, on_term,
run, stop, schedule,
isstopped, isrunning, iserror,
sim_time, timeunit, wallclock_time,

# Port interface
create_input, create_output,
get, set, sendsync, pending, connectfrom, portinfo,

# Misc
lastErrorMessage, max_blockid,
update_mask

include("obnextapi.jl")
include("obnnode.jl")
include("obnport.jl")

end # module
