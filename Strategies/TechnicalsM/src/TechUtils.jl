
struct FieldNShift
    field::Symbol
    ns::Int
end

function EvaluateTechByCorrs(; Instr="P")
    contract = GetContractCFG(Instr)
    tech = Technicals(contract.datafile)
    fields = fieldnames(tech)

    # start the scheme at tech.rangeD
    corArray=Vector{Float64}(0)
    fieldsNShifts=Array{FieldNShift}(0)
    cCount=1
    TargetField = tech.C5CR
    for ii=5:length(fields)-2
        sField = getfield(tech, fields[ii])
        TheSeries = sField
        for ns=5:6
            corArray = mcorkendall(TheSeries, TargetField, 20, ns)
            meanCorr = mean(corArray)
            iCoCount = 0
            aveCor = 0.
            for i in eachindex(corArray)
                if abs(corArray[i])>0.4
                    iCoCount+=1
                    aveCor += abs(corArray[i])
                    # println(ii, " ", fields[ii], " ", ns, " ", i, " ", round(corArray[i],4), " ", round(meanCorr,3))
                end
            end
            if iCoCount>1
                aveCor = aveCor/iCoCount
            end
            if iCoCount>0.3*length(corArray)
                println("Good: ", fields[ii], " ", ns, " ", iCoCount, " ", round(aveCor,4))
            else
                # println("Not good: ", fields[ii], " ", ns, " ", iCoCount)
            end
            fullCorr = corkendallShifted(getfield(tech, fields[ii]), TargetField, ns)
        end
    end
end


function EvaluateTechCrossCorrs(; Instr="P")
    contract = GetContractCFG(Instr)
    tech = Technicals(contract.datafile)
    fields = fieldnames(tech)

    # start the scheme at tech.rangeD
    cCount=1
    for ii=10:length(fields)-2
        if !contains(string(fields[ii]), "R")
            continue
        end
        for jj=ii+1:length(fields)-2
            if !contains(string(fields[jj]), "R")
                continue
            end
            fullCorr = corShifted(getfield(tech, fields[ii]), getfield(tech, fields[jj]), 0)
            if abs(fullCorr)>0.98
                println(cCount, " ", ii, " ", fields[ii], " ", fields[jj], " ", round(fullCorr,3))
                # println(round(corArray,2))
                cCount+=1
            end
        end
    end
end

function VisualTechCorrelations(; Instr="P")
    contract = GetContractCFG(Instr)
    tech = Technicals(contract.datafile)
    fields = fieldnames(tech)

    # start the scheme at tech.rangeD
    ii=10
    corArray=Vector{Float64}(0)
    ns=2
    recalc=true
    PlotField=false
    PlotCL=false
    while true
        if recalc
            println(ii, " ", fields[ii], " ", ns)
            scatter(tech.L3HR3[1+ns:end], getfield(tech, fields[ii])[1:end-ns])
            gui()
            recalc=false
        end

        ch=' '
        while (ch=read(stdin, Char)) == '\n' end
        if ch=='e'
            ii -= 1
            ii = max(ii, 10)
            recalc=true
        elseif ch=='d'
            ii += 1
            ii = min(ii, length(fields))
            recalc=true
        elseif ch=='n'
            println("Input the number")
            tt=""
            while tt==""
                tt=readline(stdin)
            end
            println(tt)
            ii = parse(Int, tt[1:end])
            recalc=true
        elseif ch=='a'
            ns -= 1
            ns = max(ns, 0)
            recalc=true
        elseif ch=='z'
            ns += 1
            ns = min(ns, 10)
            recalc=true
        elseif ch=='g'
            PlotCL = !PlotCL
            if PlotCL
                plot(tech.cl, w=2, leg=false, margin=[5mm 0mm])
                gui()
            else
                recalc=true
            end
        elseif ch=='G'
            PlotField = !PlotField
            if PlotField
                println("PlotField: ", fields[ii])
                plot(getfield(tech, fields[ii]), w=2, leg=false, margin=[5mm 0mm])
                gui()
            else
                recalc=true
            end
        elseif ch=='q'
            break
        end
    end
end

function VisualTechCrossCorrs(; Instr="P")
    contract = GetContractCFG(Instr)
    tech = Technicals(contract.datafile)
    fields = fieldnames(tech)

    # start the scheme at tech.rangeD
    ii=10
    jj=10
    corArray=Vector{Float64}(0)
    ns=0
    recalc=true
    PlotField=false
    PlotCL=false
    while true
        if recalc
            println(ii, " ", jj, " ", fields[ii], " ", fields[jj], " ",ns)
            scatter(getfield(tech, fields[ii])[1+ns:end], getfield(tech, fields[jj])[1:end-ns])
            gui()
            recalc=false
        end

        ch=' '
        while (ch=read(stdin, Char)) == '\n' end
        if ch=='w'
            ii -= 1
            ii = max(ii, 24)
            recalc=true
        elseif ch=='s'
            ii += 1
            ii = min(ii, length(fields))
            recalc=true
        elseif ch=='e'
            jj -= 1
            jj = max(jj, 24)
            recalc=true
        elseif ch=='d'
            jj += 1
            jj = min(jj, length(fields))
            recalc=true
        elseif ch=='n'
            println("Input the number")
            tt=""
            while tt==""
                tt=readline(stdin)
            end
            println(tt)
            ii = parse(Int, tt[1:end])
            recalc=true
        elseif ch=='m'
            println("Input the number")
            tt="\n"
            while tt=="\n"
                tt=readline(stdin)
            end
            println(tt)
            jj = parse(Int, tt[1:end])
            recalc=true
        elseif ch=='a'
            ns -= 1
            ns = max(ns, 0)
            recalc=true
        elseif ch=='z'
            ns += 1
            ns = min(ns, 10)
            recalc=true
        elseif ch=='g'
            PlotCL = !PlotCL
            if PlotCL
                plot(tech.cl, w=2, leg=false, margin=[5mm 0mm])
                gui()
            else
                recalc=true
            end
        elseif ch=='G'
            PlotField = !PlotField
            if PlotField
                println("PlotField: ", fields[ii])
                plot(getfield(tech, fields[ii]), w=2, leg=false, margin=[5mm 0mm])
                gui()
            else
                recalc=true
            end
        elseif ch=='q'
            break
        end
    end
end
