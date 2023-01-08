__precompile__(true)

module StratSysM

using ChiefOffice
using Contracts_CFG
using TechnicalsM
using AtomsM

export StratSys, TradeData

export RunSystem, ResetResults
export ProcessEntry, ProcessExit, RecordEndOfDay, HoldPosition
export GetAtomValues, GetAtomRanges
export ResetStratFilters, ResetStratSys

# utils functions
export BarsWithWinningTrades, BarsWithLosingTrades
export PrintTrades, EndPrintTrades, StartSaveTrades, EndSaveTrades
export BCandFC!, BCorFC!, BCnorFC!, CreateConsArray
export RightShiftArrays!

# TradesManager functions
export CalcLots
export IsEmptySlot, SetMaxRepeatingTrades, SetInitialEquity, SetUseEquityPC

# TradeStats functions
export Nonzeros, ComptCRet
export AnnualRet, computeHeadTailRets, ComputeHeadTailStats
export ComputeDrawdowns, ComputeHeadTailDD, ComputeStats, RegreteCRet, ComputeStats, TradeInfoExtras
export NativeCorrelation, CorVarUnit, MySharpe

export TradeTypeIntra, TradeTypeNext, TradeTypeMulti

const TradeTypeIntra=0
const TradeTypeNext=1
const TradeTypeMulti=2

include("Structs.jl")
include("utils.jl")
include("TradeStats.jl")
include("TradesManager.jl")
include("SysRoutines.jl")

end     # module