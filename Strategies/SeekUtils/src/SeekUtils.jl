__precompile__(true)

module SeekUtils

using Statistics

using TechnicalsM
using AtomsM
using StratSysM
using StratPortM

export DForNT
export PrintAllTrades
export RetStats

export BitsOfEntryCond, BitsOfEntryCond1, BitsOfEntryFilter, BitsOfExitFilter, BitsOfExitCond
export StratBitsFromNTEntry, StratFromNTEntry, HasKey
export RegimeBits, RegimesFilter, RegimesFilter!, RegimesFilterV!
export FillRegimeFilter!, FillRegimeFilterV!, Test2Shift

export deleterow, deleterows, SortFileByKey, DropRowsByKeyVal, KeepRowsBetweenVals, CombineDFs

export ReviewStrats, ReviewStratsSegV, ExtractTopConds, ReviewStratsNew

include("RegimeRoutines.jl")
include("TableEntries.jl")
include("DataFrameUtils.jl")
include("tools.jl")

end     # module