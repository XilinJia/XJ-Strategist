__precompile__(true)

module SchemeSCCM

using StratSysM

export M_SCCS, M_SCCB
export M_SCCSLS, M_SCCSLB
export M_SCCNS, M_SCCNB
export M_SCCNLS, M_SCCNLB

export OEntrySchemes, OEntrySchemesStr

function M_WrapSCC(i::Int, sys::StratSys, atomEntry::TE, atomExit::TX, xRat::Float64) where TE <: Function where TX <: Function
    if sys.TMan.curPositions[i]>0
        for j=1:sys.TMan.MaxRepeatingTrades
            if IsEmptySlot(sys.TMan, j)
                continue
            end
            atomExit(i, j, sys, xRat)
        end
    end
    if sys.TMan.curPositions[i]<sys.TMan.MaxRepeatingTrades
        atomEntry(i, sys, xRat)
    end
    RecordEndOfDay(sys)
    nothing
end

function A_Entry_SCC(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.EntryBits[i]
        ProcessEntry(sys, tech.cl[i], i)
    end
    nothing
end

function A_Exit_SCC(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i]
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCSLS(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] ||
        tech.cl[i] - sys.TMan.positions[j].entryPrice > 2. * tech.fe2trD[i]
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCSLB(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] ||
        tech.cl[i] - sys.TMan.positions[j].entryPrice < -2. * tech.fe2trD[i]
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCNS(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] || i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCNB(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] || i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCNLS(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] || 
        (i-sys.TMan.positions[j].entryDay>=sys.nBarExit && 
            tech.cl[i] > sys.TMan.positions[j].entryPrice)
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Exit_SCCNLB(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.ExitBits[i] ||
        (i-sys.TMan.positions[j].entryDay>=sys.nBarExit &&
            tech.cl[i] < sys.TMan.positions[j].entryPrice)
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

function A_Entry_SCCS(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.EntryBits[i]
        if tech.mid[i] <= tech.fe20mid[i] + 3.0*tech.fe2trD[i]
            ProcessEntry(sys, tech.cl[i], i)
        end
    end
    nothing
end

function A_Entry_SCCB(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if sys.csign == sys.EntryBits[i]
        if tech.mid[i] >= tech.fe20mid[i] - 3.0*tech.fe2trD[i]
            ProcessEntry(sys, tech.cl[i], i)
        end
    end
    nothing
end

M_SCCS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCC, xRat)

M_SCCB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCC, xRat)

M_SCCSLS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCSLS, xRat)

M_SCCSLB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCSLB, xRat)

M_SCCNS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCNS, xRat)

M_SCCNB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCNB, xRat)

M_SCCNLS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCNLS, xRat)

M_SCCNLB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapSCC(i, sys, A_Entry_SCC, A_Exit_SCCNLB, xRat)

const OEntrySchemes = Function[]
const OEntrySchemesStr = Array{String,1}(undef, 0)

const OExitSchemes = Function[]
const OExitSchemesStr = Array{String,1}(undef, 0)

end     # module