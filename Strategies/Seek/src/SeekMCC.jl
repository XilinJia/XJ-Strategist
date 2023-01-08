
ECondsUse = ECondsR
EWrappersUse = EWrappersNew1
XWrappersUse = XWrappersNew1

outlimsUse = outlimsNew

function PreliminarySeek(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = outlimsUse
    end

    EConds = ECondsUse
    println("Num of EConds: ", length(EConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end

    useX = true
    if SchemeName == "NCC"
        useX = false
    end
    XE = ExitEngine(; use=useX, XWrappers=XWrappers, Doer=DoXOnE)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, Doer=DoESameX, Inferior=XE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)
    
    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)  # trade in cash, no margin

    StartSeek(gfex, lsSchemeData)
    nothing
end

function PreliminarySeekIndX(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    EConds=ECondsUse, XConds=ECondsUse,
    outlims::Union{OutputLimits, Nothing}=nothing, useSym::Bool=false, outExt="Auto")

    if outlims === nothing
        outlims = outlimsUse 
    end

    println("Num of EConds: ", length(EConds))
    println("Num of XConds: ", length(XConds))
    # println(EConds)

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end

    XE = ExitEngine(; use=true, XConds=XConds, XWrappers=XWrappers, Doer=DoX)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, Doer=DoE, Inferior=XE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)
    
    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims, UseSym=useSym, OutExt=outExt)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)

    StartSeek(gfex, lsSchemeData)
    nothing
end

function PreliminarySeekShiftsIndX(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    EConds=ECondsUse, XConds=ECondsUse,
    outlims::Union{OutputLimits, Nothing}=nothing, useSym::Bool=false, outExt="Auto")

    if outlims === nothing
        outlims = outlimsUse 
    end

    println("Num of EConds: ", length(EConds))
    println("Num of XConds: ", length(XConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end

    XE = ExitEngine(; use=true, XConds=XConds, XWrappers=XWrappers, XShift=[0:1;], Doer=DoX)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:1;], Doer=DoE, Inferior=XE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)
    
    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims, UseSym=useSym, OutExt=outExt)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)

    StartSeek(gfex, lsSchemeData)
    nothing
end

function PreliminarySeekWithShift(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    outlims::Union{OutputLimits, Nothing}=nothing, useSym::Bool=false, outExt="Auto")

    if outlims === nothing
        outlims = outlimsUse 
    end

    EConds = ECondsUse
    println("EConds: ", EConds)
    println("Num of EConds: ", length(EConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end
    XE = ExitEngine(; use=true, XWrappers=XWrappers, Doer=DoXOnE)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:4;], Doer=DoESameX, Inferior=XE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)    

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims, UseSym=useSym, OutExt=outExt)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)

    StartSeek(gfex, lsSchemeData)

    nothing
end

function PreliminarySeekFilters(Instr::String="P"; SchemeName::String="SCC", UseSym::Bool=false, Repeats=3, 
    outlims::Union{OutputLimits, Nothing}=nothing)
    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    println("EConds: ", EConds)
    println("Num of EConds: ", length(EConds))

    useX = true
    if SchemeName == "NCC"
        useX = false
    end
    XE = ExitEngine(; use=useX, XWrappers=XWrappers, Doer=DoXOnE)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, Doer=DoESameX, Inferior=XE)
    SG = SGEngine(; Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims; OutExt="Filters", UseSym=UseSym)
    SetMaxConcurrence(lsSchemeData.port, Repeats)

    StartSeek(gfex, lsSchemeData)
    nothing
end

function SeekFilters(Instr::String="P"; SchemeName::String="SCC", UseSym::Bool=false, Repeats=3, 
    outlims::Union{OutputLimits, Nothing}=nothing)
    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end
    println("EConds: ", EConds)
    println("Num of EConds: ", length(EConds))

    useX = true
    if SchemeName == "NCC"
        useX = false
    end
    XE = ExitEngine(; use=useX, XWrappers=XWrappers, Doer=DoXOnE)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, Doer=DoESameX, Inferior=XE)
    SG = SGEngine(; Inferior=EE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims; OutExt="Filters", UseSym=UseSym)
    SetMaxConcurrence(lsSchemeData.port, Repeats)

    StartSeek(gfex, lsSchemeData)
    nothing
end

function SecondarySeek(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    outlims::Union{OutputLimits, Nothing}=nothing, useSym::Bool=false)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    println("EConds: ", EConds)
    println("FConds: ", FConds)
    println("Num of EConds: ", length(EConds), " Num of FCods: ", length(FConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end
    XE = ExitEngine(; use=true, XConds=EConds, XWrappers=XWrappers, Doer=DoX)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:1;], Doer=DoE, Inferior=XE)
    # EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:4;], Doer=DoESameX, Inferior=XE)
    FE = GFEngine(; use=true, FConds=FConds, FWrappers=FWrappers, Doer=DoF, Inferior=EE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=FE)
    gfex = GFEXStruct(;SG=SG, F=FE, E=EE, X=XE)    

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims, UseSym=useSym)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function SecondarySeekFlexFEX(Instr::String="P"; SchemeName::String="SCC", Repeats::Int=1, regimeName::String="RG_ALL", 
    FConds=FConds, EConds=EConds, XConds=EConds,
    outlims::Union{OutputLimits, Nothing}=nothing, useSym::Bool=false)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    println("Num of FConds: ", length(FConds), " Num of EConds: ", length(EConds), " Num of XConds: ", length(XConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    EWrappers = EWrappersUse
    XWrappers = XWrappersUse

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end
    XE = ExitEngine(; use=true, XConds=XConds, XWrappers=XWrappers, Doer=DoX)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:1;], Doer=DoE, Inferior=XE)
    # EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:4;], Doer=DoESameX, Inferior=XE)
    FE = GFEngine(; use=true, FConds=FConds, FWrappers=FWrappers, Doer=DoF, Inferior=EE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=FE)
    gfex = GFEXStruct(;SG=SG, F=FE, E=EE, X=XE)    

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims, UseSym=useSym)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RerunFile(Instr="P"; FileExt::String="", useScheme::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, Repeats=3, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=FileExt, Doer=RunTable, rangeFromSeg=rangeFromSeg)
    SG = SGEngine(; Inferior=TB)
    gfex = GFEXStruct(;SG=SG, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, useScheme, gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    SetMaxConcurrence(lsSchemeData.port, Repeats)

    StartSeek(gfex, lsSchemeData)

    nothing
end

function RerunFileWithRepeats(Instr="P"; FileExt::String="", Repeats::Int=1, rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=FileExt, Doer=RunTable, rangeFromSeg=rangeFromSeg)
    SG = SGEngine(; Inferior=TB)
    gfex = GFEXStruct(;SG=SG, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    SetMaxConcurrence(lsSchemeData.port, Repeats)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RerunFileWithShifts(Instr="P"; FileExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=FileExt, Doer=RunTableWithShift, rangeFromSeg=rangeFromSeg)
    EE = EntryEngine(; EShift=[0:5;])
    XE = ExitEngine(; XShift=[0:1;])
    SG = SGEngine(; Inferior=TB)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RerunFileWithFilter(Instr="P"; FileExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=FileExt, Doer=RunTable, rangeFromSeg=rangeFromSeg)
    FE = GFEngine(; use=true, FConds=FConds, FWrappers=FWrappers, Doer=DoF, Inferior=TB)
    SG = SGEngine(; Inferior=FE)
    gfex = GFEXStruct(;SG=SG, F=FE, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RunFCFiles(Instr="P"; FilterExt::String="", CondExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=CondExt, Doer=RunTable, rangeFromSeg=rangeFromSeg)
    TBF = TableEngine(; use=true, FileExt=FilterExt, Doer=RunTableAsFilters, rangeFromSeg=rangeFromSeg, Inferior=TB)
    SG = SGEngine(; Inferior=TBF)
    gfex = GFEXStruct(;SG=SG, TBF=TBF, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RunFCFilesSameLS(Instr="P"; FilterExt::String="", CondExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=CondExt, Doer=RunTableSameLS, rangeFromSeg=rangeFromSeg)
    TBF = TableEngine(; use=true, FileExt=FilterExt, Doer=RunTableAsFilters, rangeFromSeg=rangeFromSeg, Inferior=TB)
    SG = SGEngine(; Inferior=TBF)
    gfex = GFEXStruct(;SG=SG, TBF=TBF, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RunFCFilesShiftsSameLS(Instr="P"; FilterExt::String="", CondExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=CondExt, Doer=RunTableSameLS, rangeFromSeg=rangeFromSeg)
    TBF = TableEngine(; use=true, FileExt=FilterExt, Doer=RunTableAsFiltersShifts, rangeFromSeg=rangeFromSeg, Inferior=TB)
    SG = SGEngine(; Inferior=TBF)
    gfex = GFEXStruct(;SG=SG, TBF=TBF, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RunXCFCFilesSameLS(Instr="P"; FilterExt::String="", CondExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=CondExt, Doer=RunXCTableSameLS, rangeFromSeg=rangeFromSeg)
    TBXC = TableEngine(; use=true, FileExt=FilterExt, Doer=RunTableAsXCFilters, rangeFromSeg=rangeFromSeg, Inferior=TB)
    SG = SGEngine(; Inferior=TBXC)
    gfex = GFEXStruct(;SG=SG, TBXC=TBXC, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function RerunFCFiles(Instr="P"; FilterExt::String="", CondExt::String="", rangeFromSeg::Bool=false, UseSym::Bool=false, 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    TB = TableEngine(; use=true, FileExt=CondExt, Doer=RunTable, rangeFromSeg=rangeFromSeg)
    TBF = TableEngine(; use=true, useX=false, FileExt=FilterExt, Doer=UseTableCondsAsFilters, rangeFromSeg=rangeFromSeg, Inferior=TB)
    SG = SGEngine(; Inferior=TBF)
    gfex = GFEXStruct(;SG=SG, TBF=TBF, TB=TB) 

    lsSchemeData = SetupLSScheme(Instr, "", gfex, outlims; UseSym=UseSym)
    LoadTable(gfex, lsSchemeData)
    StartSeek(gfex, lsSchemeData)

    nothing
end

function TertiarySeek(Instr::String="P"; SchemeName::String="SCC", regimeName::String="RG_ALL", 
    outlims::Union{OutputLimits, Nothing}=nothing)

    if outlims === nothing
        outlims = OutputLimits(annualMinObs=2, annualMaxObs=200, maxEDD=0.3) 
    end

    println("EConds: ", EConds)
    println("FConds: ", FConds)
    println("Num of EConds: ", length(EConds), " Num of FConds: ", length(FConds))

    GConds = GCondsInRegime(Symbol(regimeName))

    useSG = true
    if regimeName == "RG_ALL"
        useSG = false
    end
    XE = ExitEngine(; use=true, XWrappers=XWrappers, Doer=DoXOnE)
    EE = EntryEngine(; use=true, EConds=EConds, EWrappers=EWrappers, EShift=[0:4;], Doer=DoESameX, Inferior=XE)
    FE = GFEngine(; use=true, FConds=FConds, FWrappers=FWrappers, Doer=DoF, Inferior=EE)
    SG = SGEngine(; use=useSG, SGName=regimeName, Inferior=FE)
    gfex = GFEXStruct(;SG=SG, E=EE, X=XE)    

    lsSchemeData = SetupLSScheme(Instr, SchemeName, gfex, outlims)
    SetMaxConcurrence(lsSchemeData.port, 1)
    SetUseEquityPC(lsSchemeData.sys, lsSchemeData.sys.contract.margin)
    StartSeek(gfex, lsSchemeData)

    nothing
end
