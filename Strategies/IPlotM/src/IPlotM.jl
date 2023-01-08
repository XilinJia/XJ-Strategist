__precompile__(true)

module IPlotM

export IPlot

using Statistics
using Plots
using DataFrames
using CSV

using Contracts_CFG
using TechnicalsM
using AtomsM
using StratPortM
using StratSysM
using Schemes
using Seek
using SeekUtils

gr()

include("structs.jl")
include("prints.jl")
include("IPlotUtils.jl")
include("StratOps.jl")


function IPlot(Instr::String, StratFExt::String = ""; 
    WF::Int = 1, StratDir::String = "",
    useSym::Bool = false, ETech::Bool = false)

    port = StratPort([Instr], UseSymData = useSym, UseWFData = WF)
    println("Sizeof(port)= ", Base.summarysize(port))

    global contract = port.contracts[1]

    LoadStrats = false
    stratfname = ""
    if StratFExt != ""
        LoadStrats = true
        ETech = true
        stratfname = contract.basedir * "/" * StratDir *"/" * Instr * StratFExt * ".csv"
        if stat(stratfname).size < 300
            println(stratfname, ": Wrong strat file, ignored!")
            LoadStrats = false
        end
    end
    
    global Conds = [port.AllAtoms;]
    global AtomsStringVec = [string(nameof(Conds[j])) for j in eachindex(Conds)]

    global tech = port.techs[1]
    println("Sizeof(tech)= ", Base.summarysize(tech))

    global techFields = fieldnames(typeof(tech))

    global instrDatadir = datadir * contract.InstrName * "/"
    dataFiles = readdir(instrDatadir)

    wfData = contract.WalkForwardData
    if WF == 2 
        wfData = contract.FullWFData 
    end

    idata = 0
    for i in eachindex(dataFiles)
        if occursin(dataFiles[i], wfData)
            idata = i
            break
        end
    end
    println("Using data file: ", wfData, " ", idata)

    replot = true

    global plotOps = PlotOps()
    PrepareOnTech(ETech)
    
    global stratOps = StratOps(LoadStrats, port)

    println("StartBar= ", plotOps.xStart, " EndBar= ", plotOps.xEnd)
    colors = [:red, :blue, :yellow, :black, :green]

    if LoadStrats == true
        IntakeStratFile(stratfname)
    end

    zzfac = 5. 

    while true
        if replot
            if plotOps.replotMain || stratOps.showTrades
                PlotMains()
                if plotOps.showZZ
                    PlotZigzag(zzfac)
                end
                if LoadStrats && stratOps.showTrades
                    PlotTrades(stratOps.sys, plotOps.xStart, plotOps.xEnd)
                end
            end
            if plotOps.scatterPlot
                plot(plotOps.Psc, size = (600, 600))
            else
                PlotInds()

                if LoadStrats && stratOps.drawCRet
                    if stratOps.replotCRet
                        plotOps.PS = PlotCRet(plotOps.xStart, plotOps.xEnd)
                    end
                end

                PlotLayout(stratOps.drawCRet)
            end
            gui()
            replot = false
        end

        for i = 1:5
            println("Input the variable, or formula of variables with 'tech', '.' to end, 'q' to quit")
            tt = readline(stdin)
            tt = chomp(tt)
            println("got text: ", tt)

            plotOps.scatterPlot = false
            
            if tt == "."
                break
            elseif tt == "Z"
                plotOps.showZZ = !plotOps.showZZ
                plotOps.replotMain = true
                replot = true
                break     
            elseif tt == "ZZ"  # Input the zigzag percent
                println("Input the zigzag percent")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                zzfac = parse(Float64, tt)
                plotOps.replotMain = true
                replot = true
                break
            elseif tt == "DT"
                DeTrend()
                replot = true
                break
            elseif tt == "DDT"
                DDeTrend()
                replot = true
                break
            elseif tt == "DDDT"
                DDDeTrend()
                replot = true
                break
            elseif tt == "PT" # print trades to file
                if LoadStrats
                    stratOps.strat = PrintStratTrades(StratFExt)
                else
                    println("Strats not loaded, ignored")
                end
                break
            elseif tt == "STR"  # plot TradeRet as indicator
                if LoadStrats
                    PlotRetOnInd(stratOps.sys.tradeData.TradeRet)
                else
                    println("Strats not loaded, ignored")
                end
                replot = true
                break
            elseif tt == "SDR"  # plot DailyERet as indicator
                if LoadStrats
                    PlotRetOnInd(stratOps.sys.tradeData.DailyERet)
                else
                    println("Strats not loaded, ignored")
                end
                replot = true
                break
            elseif tt == "SDD"  # plot DailyEDD as indicator
                if LoadStrats
                    ComputeDrawdowns(stratOps.sys.tradeData)
                    PlotRetOnInd(stratOps.sys.tradeData.DailyEDD)
                else
                    println("Strats not loaded, ignored")
                end
                replot = true
                break
          elseif tt == "ST" # show trades on the main plot
                if LoadStrats
                    ToggleShowTrades()
                    replot = true
                    plotOps.replotMain = true
                else
                    println("Strats not loaded, ignored")
                end
                break
            elseif tt == "SS"     # show stats of strat
                if LoadStrats
                    stratOps.showStats = !stratOps.showStats
                    if stratOps.showPort
                        PrintPortStats()
                    else
                        if stratOps.showStats
                            StartSaveTrades(stratOps.sys)
                            PrintStats()
                        else
                            EndSaveTrades(stratOps.sys)
                        end
                    end
                else
                    println("Strats not loaded, ignored")
                end
                break
            elseif tt == "SST"     # seek strats with Conds
                println("input entry cond")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                ECond = BAtomExact(tt)
                if ECond === nothing 
                    println("Cond not exist. abort")
                    break 
                end
                EConds = Function[ECond]
                println(EConds)
                println("input exit cond")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                XCond = BAtomExact(tt)
                if XCond === nothing 
                    println("Cond not exist. abort")
                    break 
                end
                XConds = Function[XCond]
                println(XConds)
                PreliminarySeekShiftsIndX(Instr, EConds=EConds, XConds=XConds, outExt="PlotTmp")

                LoadStrats = ShowTmpStrats(LoadStrats)
                plotOps.replotMain = true
                replot = true
                GC.gc()
                break
            elseif tt == "SLT" # show losing trades on the main plot
                if LoadStrats
                    plotOps.x1 = PickLosingTrades()
                    println("bars with losing trades: ", length(plotOps.x1))
                    plotOps.showMC = true
                    replot = true
                    plotOps.replotMain = true
                else
                    println("Strats not loaded, ignored")
                end
                break
            elseif tt == "SWT" # show losing trades on the main plot
                if LoadStrats
                    plotOps.x1 = PickWinningTrades()
                    println("bars with winning trades: ", length(plotOps.x1))
                    plotOps.showMC = true
                    replot = true
                    plotOps.replotMain = true
                else
                    println("Strats not loaded, ignored")
                end
                break
            elseif tt == "TI"  # toggle indicator plot
                plotOps.drawInd = !plotOps.drawInd
                println("plotOps.drawInd: ", plotOps.drawInd)
                if plotOps.drawInd
                    PrepareTech()
                    plotOps.editMain = false
                    plotOps.replotInd = true
                else
                    plotOps.editMain = true
                end
                replot = true
                break
            elseif tt == "TS"  # toggle Strat plot
                if LoadStrats
                    stratOps.drawCRet = !stratOps.drawCRet
                    println("stratOps.drawCRet: ", stratOps.drawCRet)
                    if stratOps.drawCRet
                        stratOps.replotCRet = true
                    end
                    replot = true
                else
                    println("Strats not loaded. Ignored")
                end
                break
            elseif tt == "TQ"     # toggle plot quantils on Ind
                ToggleQuantile()
                replot = true
                break
            elseif tt == "TSEG"   # toggle using Seg directly in computing Strat
                if LoadStrats
                    ToggleSEG()
                    replot = true
                else
                    println("Strats not loaded. Ignored")
                end
                break
            elseif tt == "S"   # toggle scatter plot
                replot = true
                ToggleScatter()
                if plotOps.scatterPlot
                    PrepareTech()
                    ExpUpdateTechElem(tech, :C5CR)
                    if LoadStrats && stratOps.drawCRet
                        StratBitsFromNTEntry(stratOps.sys, RowOf(stratOps.stratDF, stratOps.sii))
                        BC = stratOps.sys.EntryBits
                        NZ = findall(x->x!=0, BC[1:end-5])
                        plotOps.xScatter = plotOps.yIndS[1][NZ]
                        plotOps.yScatter = tech.C5CR[NZ.+5]
                        println("Scatter filtered")
                    else
                        plotOps.xScatter = plotOps.yIndS[1][51:end-5]
                        plotOps.yScatter = tech.C5CR[56:end]    
                    end
                    println("Scatter: ", length(plotOps.xScatter), " ", length(plotOps.yScatter))
                    plotOps.Psc = scatter(plotOps.xScatter, plotOps.yScatter, xguide = plotOps.indLabel, yguide = "C5CR")
                end
                break
            elseif tt == "SCC"   # scatter plot of two columns
                if LoadStrats
                    replot = true
                    plotOps.scatterPlot = true
                    setScatterParams()

                    cnames = names(stratOps.stratDF)
                    tx = ""
                    while tx == "" || !(tx in cnames) || typeof(stratOps.stratDF[1,Symbol(tx)]) == String
                        println("input X column name - column has to be numeric")
                        tx = readline(stdin)
                    end
                    plotOps.xScatter = stratOps.stratDF[!, Symbol(tx)]
                    ty = ""
                    while ty == "" || !(ty in cnames) || typeof(stratOps.stratDF[1,Symbol(ty)]) == String
                        println("input Y column name - column has to be numeric")
                        ty = readline(stdin)
                    end
                    plotOps.yScatter = stratOps.stratDF[!, Symbol(ty)]
                    plotOps.Psc = scatter(plotOps.xScatter, plotOps.yScatter, xguide = tx, yguide = ty)
                else
                    println("Strats not loaded.  Ignored!")
                end
                break
            elseif tt == "SCN"   # print strat df column names
                println(names(stratOps.stratDF))
                break
            elseif tt == "SBC"   # sort strats by column
                cnames = names(stratOps.stratDF)
                t1 = ""
                while t1 == "" || !(t1 in cnames)
                    println("input column name")
                    t1 = readline(stdin)
                end
                global curCName = t1
                global curCReverse = true
                println("sorting on :", curCName, " reverse=", curCReverse)
                sort!(stratOps.stratDF, order(Symbol(curCName), rev=curCReverse))
                PrepNewDF()
                replot = true
                break
            elseif tt == "SCR"  # reverse current sort
                curCReverse = !curCReverse
                println("sorting on :", curCName, " reverse=", curCReverse)
                sort!(stratOps.stratDF, order(Symbol(curCName), rev=curCReverse))
                PrepNewDF()
                replot = true
                break
            elseif tt == "EM"  # toggle main plot
                plotOps.editMain = !plotOps.editMain
                println("plotOps.editMain: ", plotOps.editMain)
                break
            elseif tt == "DDIR"
                println("current instrDatadir: ", instrDatadir)
                println("root instrDatadir is: ", datadir * contract.InstrName)
                println("input sub directory")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                instrDatadir = datadir * contract.InstrName * "/" * tt * "/"
                println("set instrDatadir to: ", instrDatadir)
                dataFiles = readdir(instrDatadir)
                idata = 1
                break
            elseif tt == "CD"  # Change data set
                idata, WFDataFile = ChangeDataFile(idata, dataFiles, contract)
                println("Changing WF data to: ", WFDataFile)
                ChangeData(port, WFDataFile)
                global tech = port.techs[1]
                PrepareOnTech(ETech)

                if LoadStrats
                    ResetStratOps()
                end
                replot = true
                GC.gc()
                break
            elseif tt == "SD"  # Select a new data set
                idata, WFDataFile = SelectDataFile(idata, dataFiles, contract)
                println("Changing WF data to: ", WFDataFile)
                ChangeData(port, WFDataFile)
                global tech = port.techs[1]
                PrepareOnTech(ETech)

                if LoadStrats
                    ResetStratOps()
                end
                replot = true
                GC.gc()
                break
           elseif tt == "CS"  # Change stratOps.strat file
                LoadStrats = ShowInputStrats(LoadStrats, StratDir)
                plotOps.replotMain = true
                replot = true
                GC.gc()
                break
            elseif tt == "CSS"  # Change stratOps.strat file
                LoadStrats = ShowInputSynStrats(LoadStrats)
                # plotOps.replotInd=true
                plotOps.replotMain = true
                replot = true
                GC.gc()
                break
            elseif tt == "XDT" # print the datetime of an x value
                println("Input the x value")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                println(tech.baseT.dt[parse(Int, tt)])
                break
            elseif tt == "x"  # change rangeD in x
                SetXRange()
                stratOps.replotCRet = true
                replot = true
                break
            elseif tt == ">"  # shift graph to the right
                RightShift()
                stratOps.replotCRet = true
                replot = true
                break
            elseif tt == "<"  # shift graph to the left
                LeftShift()
                stratOps.replotCRet = true
                replot = true
                break
            elseif tt == "-"  # zoom out in x
                ZoomOut()
                stratOps.replotCRet = true
                replot = true
                break
            elseif tt == "+"  # zoom in in x
                ZoomIn()
                stratOps.replotCRet = true
                replot = true
                break
            elseif tt == "n"  # input a stratOps.strat index in the performance file
                if LoadStrats
                    println("Input the stratOps.strat index")
                    tt = ""
                    while tt == ""
                        tt = readline(stdin)
                    end
                    CompStrat(parse(Int, tt))
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "u"  # decrease the stratOps.strat index
                if LoadStrats
                    CompStrat(stratOps.sii - 1)
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "d"  # increase the stratOps.strat index
                if LoadStrats
                    CompStrat(stratOps.sii + 1)
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "TLS"    # toggle long/short of stratOps.strat
                if LoadStrats
                    ToggleLongShort()
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "NRG"    # disable regime for strat
                if LoadStrats
                    StratRegimeOff()
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "NEF"    # disable entry filter for strat
                if LoadStrats
                    StratEntryFilterOff()
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "NXF"    # disable exit filter for strat
                if LoadStrats
                    StratExitFilterOff()
                    replot = true
                else
                    println("Strats not loaded")
                end
                break
            elseif tt == "TCR"   # toggle show stratOps.CRet
                if LoadStrats
                    replot = ToggleCR()
                else
                    println("Strats not loaded, ignored")
                end
                break
           elseif tt == "F"  # plot function test_y1 as indicator
                plotOps.y1 = test_y1()
                println("plotting test_y1() as indicator")
                if length(plotOps.y1) < length(tech.cl)
                    println("Extra number of elements being added: ", length(tech.cl) - length(plotOps.y1))
                    plotOps.y1 = [zeros(Float64, length(tech.cl) - length(plotOps.y1)); plotOps.y1]
                end
                plotOps.drawInd = true
                plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
                push!(plotOps.yIndS, plotOps.y1)
                if plotOps.editMain
                    plotOps.replotMain = true
                else
                    plotOps.replotInd = true
                    if plotOps.showQT
                        ComputeQuantile()
                    end
                end
                replot = true
                break
            elseif tt == "PQ"     # print rangeD values of indicator
                println(plotOps.indQ)
                break
            elseif tt == "nt"  # input an index in tech fields
                println("Input the tech index")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                PlotTechField(parse(Int, tt))
                replot = true
                break
            elseif tt == "r"  # Decrease index of Tech fields
                PlotTechField(plotOps.fii - 1)
                replot = true
                break
            elseif tt == "v"  # Increase index of Tech fields
                PlotTechField(plotOps.fii + 1)
                replot = true
                break
            elseif tt == "RC" # re-assemble Conds
                Conds = ReAssembleConds()
                AtomsStringVec = [string(nameof(Conds[j])) for j in eachindex(Conds)]
                break
            elseif tt == "nc"  # input an index in Conds
                println("Input the Conds index")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                PlotCond(parse(Int, tt))
                replot = true
                break
            elseif tt == "j"  # Decrease index of Conds fields
                PlotCond(plotOps.ifc - 1)
                replot = true
                break
            elseif tt == "k"  # Increase index of Conds fields
                PlotCond(plotOps.ifc + 1)
                replot = true
                break
            elseif tt == "CV"     # plot tech fields of cond
                PlotCondV()
                replot = true
                break
            elseif tt == "TM"
                plotOps.showMC = !plotOps.showMC
                println("plotOps.showMC: ", plotOps.showMC)
                plotOps.replotMain = true
                replot = true
                break
            elseif tt == "MC"  # mark condition on main plot
                println("Input condition")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                println("Got condition: ", tt)
                if occursin("tech.", tt) && occursin("[i", tt)
                    exps = "plotOps.x1=Vector{Int}(undef, 0) \n" *
                           "for i=50:length(tech.cl) \n" *
                           "if " * tt * "\n" *
                           "push!(plotOps.x1, i) \n" *
                           "end \n" *
                           "end \n" *
                           "plotOps.x1"
                    ExpUpdateTechElems(tech, ExtractTechFieldsOffString(string(tt)))
                    plotOps.x1 = include_string(IPlotM, exps)
                    plotOps.replotMain = true
                    replot = true
                    plotOps.showMC = true
                else
                    println("condition not supported")
                end
                break
            elseif tt == "RG" # plot the regime on Main
                println("Input the regime tuple: (GCond, gwrapper, gi, gi1)")
                tt = ""
                while tt == ""
                    tt = readline(stdin)
                end
                println("Got condition: ", tt)
                if occursin("(", tt)
                    at = include_string(IPlotM, tt)
                else
                    at = RG_Regimes[Symbol(tt)]
                end
                plotOps.x1 = BarsWithValidCond(RegimesFilter(tech, at, stratOps.port.NFRanges))
                println("num of bars: ", length(plotOps.x1))
                plotOps.showMC = true
                replot = true
                plotOps.replotMain = true
                break
            elseif tt == "1"  # Plot the first cond in stratOps.strat as indicator
                if LoadStrats
                    print("Plot Filter/Regime ")
                    PlotCond(stratOps.ifc1)
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "2"  # Plot the second cond in stratOps.strat as indicator
                if LoadStrats
                    print("Plot Entry Cond ")
                    PlotCond(stratOps.ifc2)
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "3"  # Plot the third cond in stratOps.strat as indicator
                if LoadStrats
                    print("Plot Exit Cond ")
                    PlotCond(stratOps.ifc3)
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "4"  # Plot the fourth cond in stratOps.strat as indicator
                if LoadStrats
                    print("Plot Exit Cond ")
                    PlotCond(stratOps.ifc4)
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "mr"  # mark the regeme in stratOps.strat on main plot
                if LoadStrats
                    println("Mark on Main stratOps.strat regeme # ", stratOps.ifc1)
                    PrintRegime(RowOf(stratOps.stratDF, stratOps.sii))
                    plotOps.x1 = BarsWithValidCond(stratOps.sys.RegimeBits)
                    plotOps.showMC = true
                    plotOps.replotMain = true
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "mf"  # mark the filter in stratOps.strat on main plot
                if LoadStrats
                    println("Mark on Main stratOps.strat filter # ", stratOps.ifc1)
                    PrintFilter(RowOf(stratOps.stratDF, stratOps.sii))
                    plotOps.x1 = BarsWithValidCond(stratOps.sys.EntryFBits)
                    plotOps.showMC = true
                    plotOps.replotMain = true
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "mc"  # mark the entry cond in stratOps.strat on main plot
                if LoadStrats
                    println("Mark on Main stratOps.strat entry cond # ", stratOps.ifc2)
                    PrintEntryCond(RowOf(stratOps.stratDF, stratOps.sii))
                    plotOps.x1 = BarsWithValidCond(stratOps.sys.EntryBits)
                    plotOps.showMC = true
                    plotOps.replotMain = true
                    replot = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "mx"  # mark the exit cond in stratOps.strat on main plot
                if LoadStrats
                    println("Mark on Main stratOps.strat entry cond # ", stratOps.ifc3)
                    PrintExitCond(RowOf(stratOps.stratDF, stratOps.sii))
                    plotOps.x1 = BarsWithValidCond(stratOps.sys.ExitBits)
                    plotOps.showMC = true
                    replot = true
                    plotOps.replotMain = true
                else
                    println("No stratOps.strat file loaded")
                end
                break
            elseif tt == "LT" # print tech fields
                for j in eachindex(techFields)
                    println(j, " ", techFields[j])
                end
                break
            elseif tt == "LC" # print list of conds
                for j = 1:length(Conds)
                    println(j, " ", AtomsStringVec[j])
                end
                break
            elseif (occursin("_B", tt) || occursin("_F", tt) || occursin("_P", tt)) && tt in AtomsStringVec
                # input a Cond/Filter function name
                for j in eachindex(Conds)
                    if tt == AtomsStringVec[j]
                        plotOps.ifc = j
                        println("Found matching cond: ", plotOps.ifc, " ", Conds[j])
                        break
                    end
                end
                println("Plotting as indicator cond #", plotOps.ifc, " ", Conds[plotOps.ifc])
                plotOps.y1 = AtomValues(tech, Conds[plotOps.ifc], 1, length(tech.cl))
                if i == 1
                    plotOps.indLabel = tt
                else
                    plotOps.indLabel *= " & " * AtomsStringVec[plotOps.ifc]
                end
                plotOps.replotInd = true
                replot = true
            elseif !occursin("tech.", tt) && in(Symbol(tt), techFields)
                # this include things just like: CCR
                # input is simply a field in Technicals
                if i == 1
                    plotOps.indLabel = tt
                else
                    plotOps.indLabel *= " & " * tt
                end
                for j in eachindex(techFields)
                    if Symbol(tt) == techFields[j]
                        plotOps.fii = j
                        ExpUpdateTechElem(tech, j)
                        println("Found matching tech field: ", plotOps.fii, " ", techFields[plotOps.fii])
                        break
                    end
                end
                tt = "tech." * tt
                plotOps.y1 = include_string(IPlotM, tt)
                if plotOps.editMain
                    plotOps.replotMain = true
                else
                    plotOps.drawInd = true
                    plotOps.replotInd = true
                end
                replot = true
                println(plotOps.fii, " ", tt)
            elseif occursin("tech", tt) && (!occursin("[", tt) || (occursin("[", tt) && occursin("for", tt)))
                # this include things like: tech.CCR, or [tech.CCR[i] - tech.C5CR[i] for i=50:length(tech.cl)]
                # input has "tech", and is either like tech.cl or [tech.cl[i] for i=1:length(tech.cl)]
                if i == 1
                    plotOps.indLabel = tt
                else
                    plotOps.indLabel *= " & " * tt
                end
                ExpUpdateTechElems(tech, ExtractTechFieldsOffString(string(tt)))
                plotOps.y1 = map(Float64, include_string(IPlotM, tt))
                if length(plotOps.y1) < length(tech.cl)
                    println("Extra number of elements being added: ", length(tech.cl) - length(plotOps.y1))
                    plotOps.y1 = [zeros(Float64, length(tech.cl) - length(plotOps.y1)); plotOps.y1]
                end
                if plotOps.editMain
                    plotOps.replotMain = true
                else
                    plotOps.drawInd = true
                    plotOps.replotInd = true
                end
                replot = true
                println(tt)
            elseif occursin("tech.", tt) && occursin("[i", tt) && !occursin("for", tt)
                # this include things like: tech.CCR[i] - tech.CCR[i-1]
                # input has "tech" and something with "[i" but does not a for scheme
                if i == 1
                    plotOps.indLabel = tt
                else
                    plotOps.indLabel = plotOps.indLabel * " & " * tt
                end
                ExpUpdateTechElems(tech, ExtractTechFieldsOffString(string(tt)))
                tt = "[" * tt
                tt = tt * " for i=50:length(tech.cl)]"
                plotOps.y1 = [zeros(Float64, 49); map(Float64, include_string(IPlotM, tt))]
                println("Initial 49 elements were set to 0.")
                if plotOps.editMain
                    plotOps.replotMain = true
                else
                    plotOps.drawInd = true
                    plotOps.replotInd = true
                end
                replot = true
                println(tt)
            elseif tt == "D"  # Plotting difference of current indicator
                if length(plotOps.yIndS) == 1
                    plotOps.y1 = [0.0; [plotOps.yIndS[1][i] - plotOps.yIndS[1][i-1] for i = 2:length(plotOps.yIndS[1])]]
                    println("Plotting difference of current indicator")
                    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
                    push!(plotOps.yIndS, plotOps.y1)
                    if plotOps.showQT
                        ComputeQuantile()
                    end
                    plotOps.replotInd = true
                    replot = true
                else
                    println("there must be only one current indicator, ignored.")
                end
                break
            elseif tt == "DI"  # detrend current indicator
                if length(plotOps.yIndS) == 1
                    y1 = plotOps.yIndS[1]
                    ey1 = y1 .- sma(y1, 100)
                    println("Plotting detrend of current indicator")
                    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
                    push!(plotOps.yIndS, ey1)
                    if plotOps.showQT
                        ComputeQuantile()
                    end
                    plotOps.replotInd = true
                    replot = true
                else
                    println("there must be only one current indicator, ignored.")
                end
                break
            elseif tt == "DS"  # detrend CRet
                if LoadStrats
                    y1 = stratOps.pfCRets[1]
                    smay1, junk = forecast(y1, 40, 0)
                    ey1 = [abs(y1[i]) < 1. ? 0. : ((y1[i] - smay1[i])) for i in eachindex(y1)]
                    println("Plotting detrend of CRet")
                    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
                    push!(plotOps.yIndS, ey1)
                    if plotOps.showQT
                        ComputeQuantile()
                    end
                    plotOps.indLabel = "CRet detrended"
                    plotOps.replotInd = true
                    replot = true
                else
                    println("strats not loaded, ignored.")
                end
                break
            elseif tt == "MF"  # Plotting a formular of current indicator together
                if length(plotOps.yIndS) == 1
                    println("Input the formular")
                    tt = ""
                    while tt == ""
                        tt = readline(stdin)
                    end
                    println("Got: ", tt)
                    println("Input n for formular")
                    tn = ""
                    while tn == ""
                        tn = readline(stdin)
                    end
                    println("Got: ", tn)
                    plotOps.y1 = include_string(IPlotM, tt)(plotOps.yIndS[1], parse(Int, tn))
                    println("Plotting formula ", tt, " of current indicator")
                    push!(plotOps.yIndS, plotOps.y1)
                    if plotOps.showQT
                        ComputeQuantile()
                    end
                    plotOps.replotInd = true
                    replot = true
                else
                    println("there must be only one current indicator, ignored.")
                end
                break
            elseif tt == "q"
                closeall()
                # port=nothing
                # global tech=nothing
                GC.gc()
                return
            elseif tt == "?"
                PrintHelp()
                break
            elseif tt == "?P"
                PrintPlotHelp()
                break
            elseif tt == "?S"
                PrintStratHelp()
                break
            else
                print("Input not recoganized: ", tt)
                i -= 1
                break
            end

            if !plotOps.editMain
                if i == 1
                    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
                end
                push!(plotOps.yIndS, plotOps.y1)
                if i == 1 && plotOps.showQT
                    ComputeQuantile()
                end
            else
                if i == 1
                    plotOps.yIndM = Vector{Vector{Float64}}(undef, 0)
                end
                push!(plotOps.yIndM, plotOps.y1)
            end
        end
    end
end

end     #module