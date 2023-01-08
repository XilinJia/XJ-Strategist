
function ReAssembleConds()
    println("Input patterns to include")
    pats=Vector{String}(undef, 0)
    tt=""
    while (tt=readline(stdin)) != "."
        push!(pats, tt)
        println("Input more, '.' to quit")
    end
    println("Paterns to include: ", pats)
    println("Input patterns to must include")
    patsM=Vector{String}(undef, 0)
    while (tt=readline(stdin)) != "."
        push!(patsM, tt)
        println("Input more, '.' to quit")
    end
    println("Paterns to must include: ", patsM)
    println("Input patterns to exclude")
    expats=Vector{String}(undef, 0)
    while (tt=readline(stdin)) != "."
        push!(expats, tt)
        println("Input more, '.' to quit")
    end
    println("Paterns to exclude: ", expats)
    Conds = IncExcPattern(pats, patsM, expats)
    println("New conds set: ", Conds)
    println("Total number of conds: ", length(Conds))
    plotOps.ifc = 1
    Conds
end

function PlotMains()
    if plotOps.xEnd-plotOps.xStart < 600
        yohlc = @view plotOps.techOHLC[plotOps.xStart:plotOps.xEnd]
        plotOps.Pcl = ohlc(plotOps.xStart:plotOps.xEnd, yohlc, xlims=(plotOps.xStart, plotOps.xEnd), 
            ylims=(minimum(tech.lo[plotOps.xStart:plotOps.xEnd]), maximum(tech.hi[plotOps.xStart:plotOps.xEnd])), 
            legend=:none)
   else
        yc = @view tech.cl[plotOps.xStart:plotOps.xEnd]
        plotOps.Pcl = plot(plotOps.xStart:plotOps.xEnd, yc,
            xlims=(plotOps.xStart, plotOps.xEnd), 
            ylims=(minimum(tech.lo[plotOps.xStart:plotOps.xEnd]), maximum(tech.hi[plotOps.xStart:plotOps.xEnd])), 
            legend=:none)
    end
    yMain=Vector{Vector{Float64}}(undef, 0)
    for i=1:length(plotOps.yIndM)
        push!(yMain, @view plotOps.yIndM[i][plotOps.xStart:plotOps.xEnd])
    end
    if length(yMain) > 0
        plot!(plotOps.xStart:plotOps.xEnd, yMain, xlims=(plotOps.xStart,plotOps.xEnd), legend=:none)
    end
    if plotOps.showMC && length(plotOps.x1)>1
        PlotMC(plotOps.x1, plotOps.xStart, plotOps.xEnd)                    
    end
    plotOps.replotMain=false
    nothing
end

function DDDeTrend()
    y0 = [tech.mid[i]-tech.fe20mid[i] for i=1:length(tech.cl)]
    ey0 = ema(y0, 20)
    y01 = [(y0[i]-ey0[i]) for i=1:length(tech.cl)]
    ey01 = ema(y01, 10)
    plotOps.y1 = [(y01[i]-ey01[i])/tech.fe2trD[i] for i=1:length(tech.cl)]
    println("Plotting double detrended data")
    plotOps.yIndS=Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, plotOps.y1)
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.indLabel="mid-fe20mid-ema20-ema10"
    plotOps.replotInd=true
    nothing
end

function DDeTrend()
    y0 = [tech.mid[i]-tech.fe20mid[i] for i=1:length(tech.cl)]
    ey0 = ema(y0, 20)
    plotOps.y1 = [(y0[i]-ey0[i])/tech.fe2trD[i] for i=1:length(tech.cl)]
    println("Plotting double detrended data")
    plotOps.yIndS=Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, plotOps.y1)
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.indLabel="mid-fe20mid-ema20"
    plotOps.replotInd=true
    nothing
end

function DeTrend()
    # plotOps.y1 = [(tech.mid[i]-tech.fe20mid[i])/tech.fe2trD[i] for i=1:length(tech.cl)]
    plotOps.y1 = tech.fmidv4DT
    println("Plotting detrended data")
    # ey1 = ema(sma(plotOps.y1,3), 20)
    ey1 = vema(plotOps.y1, 20)
    plotOps.yIndS=Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, plotOps.y1)
    push!(plotOps.yIndS, ey1)
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.indLabel="mid-fe20mid"
    plotOps.replotInd=true
    nothing
end

function PrepareTech()
    ExpUpdateTechElems(tech, ["fe20mid", "fe10MMR"])
    push!(plotOps.yIndM, tech.fe20mid)
    push!(plotOps.yIndS, tech.fe10MMR)
    plotOps.indLabel = "fe10MM"
    if plotOps.showQT
        ComputeQuantile()
    end
    nothing
end

function PrepareOnTech(ETech::Bool)
    plotOps.techOHLC = OHLC[(tech.op[i], tech.hi[i], tech.lo[i], tech.cl[i]) for i=1:tech.tEnd]
    plotOps.xStart = 1
    plotOps.xEnd=length(tech.cl)
    ExpUpdateTechElem(tech, :fe2trD)
    plotOps.yIndM=Vector{Vector{Float64}}(undef, 0)
    plotOps.yIndS=Vector{Vector{Float64}}(undef, 0)
    if ETech
        PrepareTech()
    end
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function PlotCond(ifc::Int)
    plotOps.ifc = ifc
    plotOps.ifc = max(plotOps.ifc, 1)
    plotOps.ifc = min(plotOps.ifc, length(Conds))
    println("conds/filters #: ", plotOps.ifc, " ", Conds[plotOps.ifc])
    plotOps.indLabel = string(nameof(Conds[plotOps.ifc]))
    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, AtomValues(tech, Conds[plotOps.ifc], 1, length(tech.cl)))
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.replotInd=true
    nothing
end

function PlotRetOnInd(ret::Vector{Float64})
    plotOps.indLabel = ""
    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, ret)
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.replotInd=true
    nothing
end

function PlotCondV()
    fields = ExtractTechFields(Conds[plotOps.ifc], tech)
    if length(fields) > 0
        plotOps.indLabel = ""
        plotOps.Vector = Vector{Vector{Float64}}(undef, 0)
        for field in fields
            println("Cond: ",  Conds[plotOps.ifc], " contains: ", field)
            plotOps.indLabel *= (" " * field)
            y1 = include_string(IPlotM, "tech." * field)
            push!(plotOps.yIndS, y1)
        end
        if plotOps.showQT
            ComputeQuantile()
        end
        plotOps.replotInd=true
    else
        println("Cond: ",  Conds[plotOps.ifc], " contains no tech field, ignored")
    end
    nothing
end

function PlotTechField(fii::Int)
    plotOps.fii = fii
    plotOps.fii = max(plotOps.fii, 1)
    plotOps.fii = max(plotOps.fii, 1)
    println("Tech field index set to: ", plotOps.fii, " ", techFields[plotOps.fii])
    plotOps.indLabel = string(techFields[plotOps.fii])
    plotOps.yIndS = Vector{Vector{Float64}}(undef, 0)
    push!(plotOps.yIndS, getTechField(tech, techFields[plotOps.fii]))
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.replotInd = true
    nothing
end

function ZoomIn()
    xRange=plotOps.xEnd-plotOps.xStart
    plotOps.xStart = min(plotOps.xStart+fld(xRange,8),length(tech.cl)-50)
    plotOps.xEnd = max(plotOps.xEnd-fld(xRange,8),plotOps.xStart+20)
    println("XView set to: ", plotOps.xStart, " ", plotOps.xEnd)
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function ZoomOut()
    xRange=plotOps.xEnd-plotOps.xStart
    plotOps.xStart = max(plotOps.xStart-fld(xRange,8),1)
    plotOps.xEnd = min(plotOps.xEnd+fld(xRange,8),length(tech.cl))
    println("XView set to: ", plotOps.xStart, " ", plotOps.xEnd)
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function LeftShift()
    xRange=plotOps.xEnd-plotOps.xStart
    plotOps.xStart = min(plotOps.xStart+xRange,length(tech.cl)-xRange)
    plotOps.xEnd = min(plotOps.xEnd+xRange,length(tech.cl))
    println("Performing left shift: ", plotOps.xStart, " ", plotOps.xEnd)
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function RightShift()
    xRange=plotOps.xEnd-plotOps.xStart
    plotOps.xStart = max(plotOps.xStart-xRange,1)
    plotOps.xEnd = max(plotOps.xEnd-xRange,xRange)
    println("Performing right shift: ", plotOps.xStart, " ", plotOps.xEnd)
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function SetXRange()
    println("Input the x rangeD")
    tt=""
    while tt==""
        tt=readline(stdin)
    end
    tts=split(tt)
    plotOps.xStart = min(parse(Int, tts[1]), length(tech.cl)-50)
    plotOps.xEnd = min(parse(Int, tts[2]), length(tech.cl))
    println("XView set to: ", plotOps.xStart, " ", plotOps.xEnd)
    plotOps.replotInd=true
    plotOps.replotMain=true
    nothing
end

function PlotLayout(drawCRet::Bool)
    if plotOps.drawInd && drawCRet
        plot(plotOps.Pcl, plotOps.PI, plotOps.PS, layout=grid(3,1, heights=[0.4,0.2,0.4]), size=(1200,800))
    end
    if !plotOps.drawInd && drawCRet
        plot(plotOps.Pcl, plotOps.PS, layout=(2,1), size=(1200,600))
    end
    if plotOps.drawInd && !drawCRet
        plot(plotOps.Pcl, plotOps.PI, layout=grid(2,1, heights=[0.6,0.4]), size=(1200,600))
    end
    if !plotOps.drawInd && !drawCRet
        plot(plotOps.Pcl, size=(1200,600))
    end
    nothing
end

function ToggleQuantile()
    plotOps.showQT = !plotOps.showQT
    if plotOps.showQT
        ComputeQuantile()
    end
    plotOps.replotInd=true
    nothing
end

function PlotInds()
    if plotOps.drawInd
        plotOps.editMain=false
        numInds = length(plotOps.yIndS)
        if plotOps.replotInd && numInds>0
            println("Plotting Inds total #: ", numInds)
            ySub=Vector{Vector{Float64}}(undef, 0)
            xStep = 1
            for i=1:numInds
                push!(ySub, @view plotOps.yIndS[i][plotOps.xStart:xStep:plotOps.xEnd])
            end
            plotOps.PI = plot(plotOps.xStart:xStep:plotOps.xEnd, ySub, seriestype=:scatter, 
                xlabel=plotOps.indLabel, markersize=2.0, xlims=(plotOps.xStart,plotOps.xEnd), legend=:none)
            if plotOps.showQT
                PlotQuantile()
            end
        end
        plotOps.replotInd=false
    end
    nothing
end

function ChangeDataFile(idata::Int, dataFiles::Vector{String}, contract::Contract)
    println("instrDatadir: ", instrDatadir, "\n",
        "current instrument: ", contract.InstrName, "\n",
        "current data file: ", dataFiles[idata])
    println("Input the new filename")
    tt=""
    while tt==""
        tt=readline(stdin)
    end
    WFDataFile = instrDatadir * tt * ".csv"
    println("new WF file: ", WFDataFile)
    if stat(WFDataFile).size < 300
        println("** Wrong file name. Ignored!")
        WFDataFile = instrDatadir * dataFiles[idata]
    end
    for i=1:length(dataFiles)
        if occursin(tt, dataFiles[i])
            idata=i
            break
        end
    end
    idata, WFDataFile
end

function SelectDataFile(idata::Int, dataFiles::Vector{String}, contract::Contract)
    println("Current file: ", dataFiles[idata], " at index: ", idata)
    WFDataFile = ""
    while true
        println("Input 'd' or 'u' to move down or up the list")
        tt=""
        while tt==""
            tt=readline(stdin)
        end
        while true
            if tt=="d"
                idata+=1
            elseif tt=="u"
                idata-=1
            end
            if idata>length(dataFiles) || idata<1
                println("Reached the end of file list. Input again")
                break
            end
            if !occursin(".csv", dataFiles[idata])
                continue
            end
            println("Data file selected: ", dataFiles[idata])
            break
        end
        println("Input 'y' to confirm selection")
        tt=""
        while tt==""
            tt=readline(stdin)
        end
        if tt=="c"
            println("Selection cancelled")
            for i=1:length(dataFiles)
                if occursin(dataFiles[i], contract.WalkForwardData)
                    idata=i
                    break
                end
            end
            println("Continue using data file: ", contract.WalkForwardData, " ", idata)
            break
        elseif tt!="y"
            continue
        end
        WFDataFile = instrDatadir * dataFiles[idata]
        if stat(WFDataFile).size < 300
            println("Wrong file name. Ignored!")
            continue
        end
        println("new WF file: ", WFDataFile)
        break
    end
    idata, WFDataFile
end

function PlotQuantile()
    x = [plotOps.xStart, plotOps.xEnd]
    vvb = [plotOps.indQ[1], plotOps.indQ[1]]
    vb = [plotOps.indQ[2], plotOps.indQ[2]]
    vm = [plotOps.indQ[3], plotOps.indQ[3]]
    vt = [plotOps.indQ[4], plotOps.indQ[4]]
    vvt = [plotOps.indQ[5], plotOps.indQ[5]]
    plot!(x, vvb, w=2, color=:green)
    plot!(x, vb, w=2, color=:cyan)
    plot!(x, vm, w=2, color=:red)
    plot!(x, vt, w=2, color=:cyan)
    plot!(x, vvt, w=2, color=:green)
    nothing
end

function ComputeQuantile()
    println("recomputing quantiles")
    plotOps.indQ[1] = quantile(plotOps.yIndS[1], 0.05)
    plotOps.indQ[2] = quantile(plotOps.yIndS[1], 0.25)
    plotOps.indQ[3] = quantile(plotOps.yIndS[1], 0.5)
    plotOps.indQ[4] = quantile(plotOps.yIndS[1], 0.75)
    plotOps.indQ[5] = quantile(plotOps.yIndS[1], 0.95)
    nothing
end

function PlotMC(x1::Vector{Int}, xStart::Int, xEnd::Int)
    xMainS=Vector{Int}(undef, 0)
    yMainS=Vector{Float64}(undef, 0)
    for i=1:length(x1)
        if x1[i]>=xStart && x1[i]<=xEnd
            push!(xMainS, x1[i]-xStart+1)
            push!(yMainS, tech.cl[x1[i]])
        end
    end
    plot!(xMainS, yMainS, seriestype=:scatter, markersize=3, color=:darkgreen, xlims=(1,xEnd-xStart), legend=:none)
    nothing
end

function ToggleScatter()
    plotOps.scatterPlot = !plotOps.scatterPlot
    println("plotOps.scatterPlot: ", plotOps.scatterPlot)
    if plotOps.scatterPlot
        setScatterParams()
    else
        plotOps.replotMain=true
    end
    nothing
end

function setScatterParams()
    plotOps.replotMain=false
    plotOps.drawInd=false
    stratOps.replotCRet=false
    plotOps.replotInd=true
end

