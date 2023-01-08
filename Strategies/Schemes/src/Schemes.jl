__precompile__(true)

module Schemes

export GetSchemeFunc, SchemeLSTuples, isSchemeOEntry, isSchemeOExit

export OEntrySchemes, OEntrySchemesStr, OExitSchemes, OExitSchemesStr

using StratSysM

include("SchemeSCCM.jl")
using .SchemeSCCM
export M_SCCS, M_SCCB
export M_SCCSLS, M_SCCSLB
export M_SCCNS, M_SCCNB
export M_SCCNLS, M_SCCNLB

include("SchemeNCCM.jl")
using .SchemeNCCM
export M_NCCS, M_NCCB
# export SchemeNCCS, SchemeNCCB, SchemeNCC

include("StratNDays.jl")

const OEntrySchemes = [SchemeSCCM.OEntrySchemes; SchemeNCCM.OEntrySchemes]
const OEntrySchemesStr = map(string, OEntrySchemes)

const OExitSchemes = [SchemeSCCM.OExitSchemes; SchemeNCCM.OExitSchemes]
const OExitSchemesStr = map(string, OExitSchemes)

function dummyFunc(i::Int, sys::StratSys, xRat::Float64)
    nothing
end

function GetSchemeFunc(LS::Int, schemeName::AbstractString)
    if LS == -1
        if schemeName == "M_SCC"
            return M_SCCS
        elseif schemeName == "M_SCCSL"
            return M_SCCSLS
        elseif schemeName == "M_SCCN"
            return M_SCCNS
        elseif schemeName == "M_SCCNL"
            return M_SCCNLS
        elseif schemeName == "M_NCC"
            return M_NCCS
        end
    elseif LS == 1
        if schemeName == "M_SCC"
            return M_SCCB
        elseif schemeName == "M_SCCSL"
            return M_SCCSLB
        elseif schemeName == "M_SCCN"
            return M_SCCNB
        elseif schemeName == "M_SCCNL"
            return M_SCCNLB
        elseif schemeName == "M_NCC"
            return M_NCCB
        end
    end
    println("*** Only SCC, SCCSL, SCCN, SCCNL, and NCC schemes are supproted currently!")
    dummyFunc
end

function SchemeLSTuples(schemeName::AbstractString)
    if schemeName == "M_SCC"
        return ((-1, M_SCCS), (1, M_SCCB))
    elseif schemeName == "M_SCCSL"
        return ((-1, M_SCCSLS), (1, M_SCCSLB))
    elseif schemeName == "M_SCCN"
        return ((-1, M_SCCNS), (1, M_SCCNB))
    elseif schemeName == "M_SCCNL"
        return ((-1, M_SCCNLS), (1, M_SCCNLB))
    elseif schemeName == "M_NCC"
        return ((-1, M_NCCS), (1, M_NCCB))
    end
    println("*** Only SCC, SCCSL, SCCN, SCCNL, and NCC schemes are supproted currently!")
    ((0, dummyFunc),)
end

function isSchemeOEntry(SchemeStr::AbstractString)
    in(SchemeStr, OEntrySchemesStr)
end

function isSchemeOExit(SchemeStr::AbstractString)
    in(SchemeStr, OExitSchemesStr)
end

end     # module
