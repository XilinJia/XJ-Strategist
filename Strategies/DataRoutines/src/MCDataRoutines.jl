
using CSV
using DataFrames
using Dates

# Steps to manage MC data
# 1) set trading sessions (night and day) of HOT data
# 2) download 1 minute data of HOT
# 3) export 1 minute data of HOT
# 4) run routine CheckMinuteCompleteness on the 1 minute data

    # **** day data not needed from MC
    # 5) when OK, download day data of HOT in MC
    # 6) export day data of HOT
    # 7) run routine RepairMCDay on the day data
    # 8) cut/paste new data into WF file
    # 9) run routine AdjustBackData on the WF data
    # ****

# 10) run AlignMinWithDay
# 11) import the aligned minute data into MC on a month contract
# 12) test trades on the month contract

function RepairMCDay(filename::AbstractString)
    df=CSV.read(filename*".csv")
    renameMCColumns(df)
    rows=Vector{Int}(undef,0)
    for i=1:nrow(df)-1
        if df[:Time][i] == "23:30:00"
            if df[:Time][i+1] == "15:00:00"
                df[:Open][i+1] = df[:Open][i]
                df[:High][i+1] = df[:High][i+1]>=df[:High][i] ? df[:High][i+1] : df[:High][i]
                df[:Low][i+1] = df[:Low][i+1]<=df[:Low][i] ? df[:Low][i+1] : df[:Low][i]
                push!(rows, i)
            else
                println("closing time is not 15:00 ", i, " ", df[:Time][i+1])
                break
            end
        end
    end
    println("deleting number of rows: ", length(rows))
    odf = deleterows(df, rows)
    delete!(odf, :Time)
    odf = [odf DataFrame(Interest=zeros(Int, nrow(odf)))]
    odf = [odf DataFrame(Contract=zeros(Int, nrow(odf)))]

    ofname = filename * ".Fix.csv"
    writetable(ofname, odf)
end

function deleterows(df::DataFrame, rows::Vector{Int})
     return df[setdiff(1:end,rows), :]
end

function renameMCColumns(df::DataFrame)
    if in(:_Date_, names(df))
        rename!(df, :_Date_, :Date)
    end
    if in(:_Time_, names(df))
        rename!(df, :_Time_, :Time)
    end
    if in(:_Open_, names(df))
        rename!(df, :_Open_, :Open)
    end
    if in(:_High_, names(df))
        rename!(df, :_High_, :High)
    end
    if in(:_Low_, names(df))
        rename!(df, :_Low_, :Low)
    end
    if in(:_Close_, names(df))
        rename!(df, :_Close_, :Close)
    end
    if in(:_Volume_, names(df))
        rename!(df, :_Volume_, :Volume)
    end
end

const MaxDailyBars=600
function CheckMinuteCompleteness(minfile::AbstractString)
    mdf = CSV.read(minfile*".csv")
    renameMCColumns(mdf)
    MinStartDate = Date(mdf[:Date][1], "yyyy/mm/dd")
    mi=1
    mCloseIndex=0
    PriorDate=" "
    while mi<nrow(mdf)
        if mdf[:Time][mi] != "09:01:00" && mdf[:Time][mi] != "21:01:00"
            println("Minute wrong start time ", mdf[:Date][mi], " ", mdf[:Time][mi])
        # else
        #     println(mdf[:Date][mi], " start time OK")
        end
        if mdf[:Time][mi] == "21:01:00"
            if mdf[:Date][mi] != PriorDate
                PriorDate = (mdf[:Date][mi])
            else
                println("date does not advance: ", PriorDate, " ", mdf[:Date][mi], " ", mdf[:Time][mi], " abort!")
                break
            end
        end
        MaxDayIndex=min(mi+MaxDailyBars, nrow(mdf))
        CurDate=""
        for i=mi:MaxDayIndex
            hour=parse(Int, mdf[:Time][i][1:2])
            if hour==9 && CurDate==""
                    CurDate=mdf[:Date][i]
            end
            if mdf[:Time][i] == "15:00:00" && mdf[:Date][i] == CurDate
                mCloseIndex=i
                if i-mi<200
                    println("insufficient minute data: ", mdf[:Date][i], " ", i-mi)
                end
                if mdf[:Time][i-4] != "14:56:00" || mdf[:Time][i-1] != "14:59:00"
                    println("ERROR***: incomplete closing data: ", mdf[:Date][i])
                end
                break
            elseif hour>15 && mdf[:Date][i] == CurDate
                println(i, " ERROR**: Minute closing time not found ", mdf[:Date][i], " ", mdf[:Time][i-1])
                mCloseIndex=i-1
                break
            elseif mdf[:Time][i] == "15:00:00" && mdf[:Date][i] != CurDate
                println(i, " ERROR***: Minute closing time not found ", mdf[:Date][i-1], " ", mdf[:Time][i])
                mCloseIndex=i-1
                break
            # elseif i>mi && mdf[:Date][i]!=mdf[:Date][i-1] && !occursin("23:30", mdf[:Time][i-1])
            #     mCloseIndex=i-1
            #     println(i, " Minute closing time not found ", mdf[:Date][i-1], " ", mdf[:Time][i-1])
            #     break
            elseif i==nrow(mdf)
                mCloseIndex=i
                break
            elseif i==MaxDayIndex
                println("*** MaxDayIndex reached", mdf[:Date][i])
            end
        end
        # println(mCloseIndex, " ", mi, " ", nrow(mdf), " ", mdf[:Date][mi], " ", mdf[:Time][mi])
        mi = mCloseIndex+1
    end
end

function AlignMinWithDay(dayfile::AbstractString, minfile::AbstractString)
    ddf = CSV.read(dayfile*".csv")
    mdf = CSV.read(minfile*".csv")
    renameMCColumns(mdf)
    MinStartDate = Date(mdf[:Date][1], "yyyy/mm/dd")
    DayStartIndex=0
    for i=1:nrow(ddf)
        if Date(ddf[:Date][i], "yyyy-mm-dd") == MinStartDate
            DayStartIndex=i
            break
        end
    end
    mi=1
    di=DayStartIndex
    while mi<nrow(mdf) && di<=nrow(ddf)
        if mdf[:Time][mi] != "09:01:00" && mdf[:Time][mi] != "21:01:00"
            println("Minute wrong start time, ignored ", mdf[:Date][mi], " ", mdf[:Time][mi])
        end
        mCloseIndex=0
        mClose=1
        for i=mi:min(mi+MaxDailyBars, nrow(mdf))
            if mdf[:Time][i] == "15:00:00"
                mCloseIndex=i
                mClose=mdf[:Close][i]
                if i-mi<200
                    println("incomplete minute data (ignored): ", mdf[:Date][i], " ", i-mi)
                end
                break
            end
        end
        if mCloseIndex==0
            println("Minute closing time not found, abort ", mdf[:Date][mi])
            break
        end
        ddate = Date(ddf[:Date][di], "yyyy-mm-dd")
        mdate = Date(mdf[:Date][mCloseIndex], "yyyy/mm/dd")
        if ddate != mdate
            if ddate<mdate
                println("Dates not matching, try adjusting", ddate, " ", mdate, " ", mCloseIndex)
                di+=1
                ddate = Date(ddf[:Date][di], "yyyy-mm-dd")
                if ddate != mdate
                    println("Dates not matching, abort ", ddate, " ", mdate, " ", mCloseIndex)
                    break
                end
            else
                println("Dates not matching, abort ", ddate, " ", mdate, " ", mCloseIndex)
                break
            end
        end
        dClose = ddf[:Close][di]
        ratio = dClose / mClose
        for i=mi:mCloseIndex
            mdf[:Open][i] = round(Int, (mdf[:Open][i] * ratio))
            mdf[:High][i] = round(Int, (mdf[:High][i] * ratio))
            mdf[:Low][i] = round(Int, (mdf[:Low][i] * ratio))
            mdf[:Close][i] = round(Int, (mdf[:Close][i] * ratio))
        end

        mi = mCloseIndex+1
        di += 1
    end

    ofname = minfile * ".Align.csv"
    writetable(ofname, mdf)
end

function AdjustBackData(filename::AbstractString, rolldatesfile="MCRollDates")
    df=CSV.read(filename*".csv")
    # rd=CSV.read(dirname(filename)*"/"*rolldatesfile*".csv")
    WorkDir=""
    if dirname(filename) != ""
        WorkDir=dirname(filename)*"/"
    end
    rd=CSV.read(WorkDir*rolldatesfile*".csv")

    for ri=1:nrow(rd)
        ratio = rd[:NewClose][ri] / rd[:OldClose][ri]
        rdt = Date(rd[:Date][ri])
        println("Roll Date: ", rdt, "\tRatio: ", ratio)
        numAdj=0
        for i=nrow(df):-1:1
            dt = Date(df[:Date][i], "yyyy/mm/dd")
            if dt <= rdt
                df[:Open][i] = round(Int, df[:Open][i] * ratio)
                df[:High][i] = round(Int, df[:High][i] * ratio)
                df[:Low][i] = round(Int, df[:Low][i] * ratio)
                df[:Close][i] = round(Int, df[:Close][i] * ratio)
                numAdj+=1
            end
        end
        println("Number of bars adjusted: ", numAdj)
    end

    ofname = filename * ".AdjM.csv"
    writetable(ofname, df)
end
