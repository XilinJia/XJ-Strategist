
using CSV
using DataFrames

# include("QuandlPkg.jl")

# include("Contracts_CFG1.jl")
datadir="../../Data/"

MonthCodes = ["F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z"]
# Exchanges: SHFE, DCE, ZCE

function AddContractCol(df::DataFrame, code::AbstractString)
    NameCol = Array{String}(undef, nrow(df))
    [NameCol[j]=code[end-4:end] for j=1:nrow(df)]
    df[:Contract] = NameCol
end

function GetDataOfContract(df::DataFrame, Exchange="DCE", Instrument="P", month="F", year=2016)
    code= Exchange * "/" * Instrument * month * string(year)
    println("getting ", code)
    data = quandl(code)
    println(data)
    df1 = DataFrame()
    df1.Date = data[2]
    for i=2:length(data[3])
        df1[Symbol(data[3][i])] = data[1][:,i-1]
    end

    if df1 != Union{}
        println("got ", code)
        AddContractCol(df1, code)
        if nrow(df)==0
            df = df1
        else
            df = vcat(df, df1)
        end
    else
        println("*** ", code, " does not exist")
    end
    df
end

function GetData(Exchange::String, Instrument::String, ContractStart="2018-09", ContractEnd="2019-09", Months=[1,5,9])
    quandl_auth("")
    sleep(5)
    Contracts = Array{DataFrame}(undef, 12)
    for j=1:12
        Contracts[j] = DataFrame()
    end

    StartYear = parse(Int, ContractStart[1:4])
    StartMonth = parse(Int, ContractStart[6:7])
    EndYear = parse(Int, ContractEnd[1:4])
    EndMonth = parse(Int, ContractEnd[6:7])

    for year=StartYear:EndYear
        for j in Months
            if year==StartYear && j<StartMonth
                continue
            end
            if year==EndYear && j>EndMonth
                break
            end
            Contracts[j] = GetDataOfContract(Contracts[j], Exchange, Instrument, MonthCodes[j], year)
        end
    end

    for j in 1:12
        if nrow(Contracts[j])>2
            ofname = datadir * Instrument * "/Quandl/Contract" * string(j) * ".csv"
            append=false
            if stat(ofname).size > 100
                append=true
            end
            if haskey(Contracts[j], Symbol("Open Interest"))
                rename!(Contracts[j], Symbol("Open Interest") => :Open_Interest)
            elseif haskey(Contracts[j], Symbol("O.I."))
                rename!(Contracts[j], Symbol("O.I.") => :Open_Interest)
            end
            CSV.write(ofname, Contracts[j], append=append)
        end
    end
    nothing
end

# The SHFE data has a lot of NA numbers, this function can not fully repair it yet
function RepairQuandlData(Instr="")
    if Instr==""
        DataDir = pwd() * "/"
    else
        DataDir = "../../Data/" * Instr * "/Quandl/"
    end
    println("Repair files in directory: ", DataDir)

    filenames = readdir(DataDir)
    nfiles = length(filenames)

    df = DataFrame()

    for i=1:nfiles
        fname = filenames[i]
        if fname[max(1,end-3):end] == ".csv"
            df = CSV.read(DataDir * fname)
            unique!(df)
            if haskey(df, :O_I_)    # SHFE data: merge Prev_Day_Open_Interest into O_I_
                rows=Vector{Int}(0)
                for i=1:nrow(df)
                    if isna(df[:Prev_Day_Open_Interest][i])
                        df[:Prev_Day_Open_Interest][i] = 0
                    end
                    if isna(df[:O_I_][i])
                        df[:O_I_][i] = 0
                    end
                    if isna(df[:Volume][i])
                        df[:Volume][i] = 0
                    end
                    if df[:Prev_Day_Open_Interest][i] > df[:O_I_][i]
                        df[:O_I_][i] = df[:Prev_Day_Open_Interest][i]
                    end
                    if df[:O_I_][i]<1000 &&
                        (isna(df[:Open][i]) || isna(df[:High][i]) || isna(df[:Low][i]) || isna(df[:Close][i]))
                        push!(rows, i)
                    end
                end
                odf = deleterows(df, rows)
            end
            ofname = fname[1:end-4] * "o" *".csv"
            writetable(DataDir * ofname, odf)
        end
    end
    nothing
end
