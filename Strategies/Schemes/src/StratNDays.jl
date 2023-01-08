__precompile__(true)

module StratNDays

export SchemeNCCS, SchemeNCCB, SchemeNCC, OEntrySchemes, OEntrySchemesStr

using TechnicalsM
using StratSysM

include("MoleWrappers.jl")

# *** Multi-day Strats  **************

function M_WrapNMRM(i::Int, sys::StratSys, atomEntry::TE, atomExit::TX, xRat::Float64) where TE <: Function where TX <: Function
    if sys.TMan.curPositions[i]<sys.TMan.MaxRepeatingTrades
        if sys.csign == sys.EntryBits[i]
            atomEntry(i, sys, xRat)
        end
    end
    if sys.TMan.curPositions[i]>0
        for j=1:sys.TMan.MaxRepeatingTrades
            if IsEmptySlot(sys.TMan, j) || i-sys.TMan.positions[j].entryDay==0
                continue
            end
            atomExit(i, j, sys, xRat)
        end
    end
    RecordEndOfDay(sys)
    nothing
end

function M_WrapNC(i::Int, sys::StratSys, atomEntry::TE, atomExit::TX, xRat::Float64) where TE <: Function where TX <: Function
    if sys.TMan.curPositions[i]>0
        for j=1:sys.TMan.MaxRepeatingTrades
            if IsEmptySlot(sys.TMan, j)
                continue
            end
            atomExit(i, j, sys, xRat)
        end
    end
    if sys.TMan.curPositions[i]<sys.TMan.MaxRepeatingTrades
        if sys.csign == sys.EntryBits[i]
            atomEntry(i, sys, xRat)
        end
    end
    RecordEndOfDay(sys)
    nothing
end

function MoleculeWrapN(csign::Int, ls::Int, sys::StratSys, MoleculeTrade::T, xRat::Float64) where T <: Function
    ResetStratSys(sys, ls, csign, xRat, TradeTypeMulti)
    for i = sys.sStart:sys.sEnd
        MoleculeTrade(i, sys, xRat)
    end
    PreserveCRet(sys)
    nothing
end

SchemeNCCS(csign::Int, sys::StratSys, xRat::Float64=0.) =
    MoleculeWrapN(csign, -1, sys, M_NCCS, xRat)

SchemeNCCB(csign::Int, sys::StratSys, xRat::Float64=0.) =
    MoleculeWrapN(csign, 1, sys, M_NCCB, xRat)

SchemeNCC(csign::Int, sys::StratSys, ls::Int) =
    SchemeRunnerS(csign, sys, SchemeNCCS, SchemeNCCB, ls, TradeTypeMulti)

SchemeNMRWMS(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrapN(csign, -1, sys, M_NMRWMS, xRat)

SchemeNMRWMB(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrapN(csign, 1, sys, M_NMRWMB, xRat)

SchemeNMRWM(csign::Int, sys::StratSys, ls::Int) =
    SchemeRunnerMNoOpt(csign, sys, SchemeNMRWMS, SchemeNMRWMB, sys.stratRanges.NCMSRange,
            sys.stratRanges.NCMBRange, ls, TradeTypeMulti)

SchemeNCWMS(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrapN(csign, -1, sys, M_NCWMS, xRat)

SchemeNCWMB(csign::Int, sys::StratSys, xRat::Float64) =
    MoleculeWrapN(csign, 1, sys, M_NCWMB, xRat)

SchemeNCWM(csign::Int, sys::StratSys, ls::Int) =
    SchemeRunnerMNoOpt(csign, sys, SchemeNCWMS, SchemeNCWMB, sys.stratRanges.NCMSRange,
            sys.stratRanges.NCMBRange, ls, TradeTypeMulti)


function StratReturnsDict(tech::Technicals)
    Dict(SchemeCCS=>tech.CCR, SchemeCCB=>tech.CCR,
        SchemeOCS=>tech.OCR, SchemeOCB=>tech.OCR,
        # why are the shifts needed? To ensure about forward looking tradeData
        SchemeNCCS=>[0.;0.;0.;0.;0.;tech.C5CR], SchemeNCCB=>[0.;0.;0.;0.;0.;tech.C5CR],
        # SchemeNCWMS=>[0.,0.,0.,0.,0.,tech.HLR5;], SchemeNCWMB=>[0.,0.,0.,0.,0.,tech.LHR5;],
        SchemeNCWMS=>[0.;0.;0.;0.;0.;tech.CLR5], SchemeNCWMB=>[0.;0.;0.;0.;0.;tech.CHR5],
        SchemeNMRWMS=>[0.;0.;0.;0.;0.;tech.HLR5], SchemeNMRWMB=>[0.;0.;0.;0.;0.;tech.LHR5])
end

function A_Entry_NMRWMS(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    strikePrice = tech.wlo[i-1] + 0.2*(tech.awrange[i-1])   # trying to better use the factor here
    shortPrice = ifelse(tech.op[i]>=strikePrice, tech.op[i], strikePrice)
    ProcessEntry(sys, shortPrice, i)
    nothing
end

function A_Exit_NMRWMS(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit ||
        (i-sys.TMan.positions[j].entryDay>2 && tech.cl[i]>tech.facl[i]+tech.fe2trD[i])
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0 + +xRat*tech.faC5wLR[i-1])
        ExitPrice = ifelse(tech.op[i]<=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

function A_Exit_NMRWMSNoStop(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0+xRat*tech.faC5wLR[i-1])
        ExitPrice = ifelse(tech.op[i]<=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

function A_Exit_NMRWMSNoStop1(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0-xRat)
        ExitPrice = ifelse(tech.op[i]<=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

M_NMRWMS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNMRM(i, sys, A_Entry_NMRWMS, A_Exit_NMRWMS, xRat)

function A_Entry_NMRWMB(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    strikePrice = tech.whi[i-1] - 0.2*(tech.awrange[i-1])   # trying to better use the factor here
    buyPrice = ifelse(tech.op[i]<=strikePrice, tech.op[i], strikePrice)
    ProcessEntry(sys, buyPrice, i)
    nothing
end

function A_Entry_NMRWMBTrend(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if tech.mid[i-1] >= tech.fe20mid[i-1] - tech.awrange[i-1]
        strikePrice = tech.whi[i-1] - 0.2*(tech.awrange[i-1])   # trying to better use the factor here
        buyPrice = ifelse(tech.op[i]<=strikePrice, tech.op[i], strikePrice)
        ProcessEntry(sys, buyPrice, i)
    end
    nothing
end

function A_Exit_NMRWMB(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit ||
        (i-sys.TMan.positions[j].entryDay>2 && tech.cl[i]<tech.facl[i]-tech.fe2trD[i])
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0+ xRat*tech.faC5wHR[i-1])
        ExitPrice = ifelse(tech.op[i]>=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

function A_Exit_NMRWMBNoStop(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0+xRat*tech.faC5wHR[i-1])
        ExitPrice = ifelse(tech.op[i]>=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

function A_Exit_NMRWMBNoStop1(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit
        ExitPrice = tech.cl[i]
    else
        strikePrice = sys.TMan.positions[j].entryPrice * (1.0+xRat)
        ExitPrice = ifelse(tech.op[i]>=strikePrice, tech.op[i], strikePrice)
    end
    ProcessExit(sys, j, ExitPrice, i)
    nothing
end

M_NMRWMB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNMRM(i, sys, A_Entry_NMRWMB, A_Exit_NMRWMB, xRat)

function A_Entry_NCWM(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    ProcessEntry(sys, tech.cl[i], i)
    nothing
end

function A_Entry_NCWMS(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if tech.mid[i] <= tech.fe20mid[i] + tech.fawrange[i]
        ProcessEntry(sys, tech.cl[i], i)
    end
    nothing
end

function A_Entry_NCWMB(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if tech.mid[i] >= tech.fe20mid[i] - tech.fawrange[i]
        ProcessEntry(sys, tech.cl[i], i)
    end
    nothing
end

M_NCWMS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNC(i, sys, A_Entry_NCWMS, A_Exit_NMRWMSNoStop, xRat)

M_NCWMB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNC(i, sys, A_Entry_NCWMB, A_Exit_NMRWMBNoStop, xRat)

# M_NCWMS(i::Int, sys::StratSys, xRat::Float64) =
#     M_WrapNC(i, sys, A_Entry_NCWM, A_Exit_NMRWMS, xRat)
#
# M_NCWMB(i::Int, sys::StratSys, xRat::Float64) =
#     M_WrapNC(i, sys, A_Entry_NCWM, A_Exit_NMRWMB, xRat)

function A_Entry_NCCS(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    ProcessEntry(sys, tech.cl[i], i)
    nothing
end

function A_Entry_NCCB(i::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    ProcessEntry(sys, tech.cl[i], i)
    nothing
end

function A_Exit_NCC(i::Int, j::Int, sys::StratSys, xRat::Float64)
    tech = sys.tech
    if i-sys.TMan.positions[j].entryDay>=sys.nBarExit ||
        sys.csign == sys.ExitBits[i]
        ProcessExit(sys, j, tech.cl[i], i)
    else
        HoldPosition(sys, j, tech.cl)
    end
    nothing
end

M_NCCB(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNC(i, sys, A_Entry_NCCB, A_Exit_NCC, xRat)

M_NCCS(i::Int, sys::StratSys, xRat::Float64) =
    M_WrapNC(i, sys, A_Entry_NCCS, A_Exit_NCC, xRat)


const OEntrySchemes = [SchemeNMRWM]
const OEntrySchemesStr = map(string, OEntrySchemes)
    
end     #module