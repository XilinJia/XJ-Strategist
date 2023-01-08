__precompile__(true)

module Strat2Days

using StratSysM

include("MoleWrappers.jl")
# using .Molewrappers

# *********** Next-day Strats

SchemeCCS(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrap(csign, -1, sys, M_CCS, xRat, TradeTypeNext)

SchemeCCB(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrap(csign, 1, sys, M_CCB, xRat, TradeTypeNext)

SchemeCC(csign::Int, sys::StratSys, ls::Int) =
    SchemeRunnerS(csign, sys, SchemeCCS, SchemeCCB, ls, TradeTypeNext)

function M_CC(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.EntryBits[i]
        RecordTrade(sys, tech.cl[i], tech.cl[i+1])
    else
        NoTradeUpdate(sys)
    end
    nothing
end

M_CCS = M_CC
M_CCB = M_CC
    
end     # module