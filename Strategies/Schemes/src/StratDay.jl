__precompile__(true)

module StratDay

using StratSysM

include("MoleWrappers.jl")
# using .Molewrappers

# ********** Intra-day Strats

SchemeOCS(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrap(csign, -1, sys, M_OCS, 0., 0)

SchemeOCB(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrap(csign, 1, sys, M_OCB, 0., 0)

SchemeOC(csign::Int, sys::StratSys, ls::Int) =
    SchemeRunnerS(csign, sys, SchemeOCS, SchemeOCB, ls, TradeTypeIntra)

function M_OC(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.EntryBits[i]
        RecordTrade(sys, tech.op[i], tech.cl[i])
    else
        NoTradeUpdate(sys)
    end
    nothing
end

M_OCS = M_OC
M_OCB = M_OC
    

end     # module