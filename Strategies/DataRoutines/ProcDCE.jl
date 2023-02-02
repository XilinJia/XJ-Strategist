
using XLSX
using DataFrames
using CSV
using Dates

using DataRoutines

colNamesCh = ["合约", "日期", "前收盘价", "前结算价", "开盘价", "最高价", "最低价", "收盘价", "结算价", "涨跌1", "涨跌2", "成交量", "成交额", "成交金额", "持仓量"]
colNamesEn = ["Contract", "Date", "pClose", "pSettle", "Open", "High", "Low", "Close", "Settle", "UpDown1", "UpDown2", "Volume", "Amount", "Amount", "OpenInterest"]

DataDir = "../Data/P/DCE"
files = readdir(DataDir)
StartDate="2012-08-01"
EndDate="2018-01-20"

function changeColumnNames(df) 
    ns = names(df)
    for n in ns
        for i in eachindex(colNamesCh)
            if (n == colNamesCh[i])
                rename!(df, Symbol(colNamesCh[i]) => Symbol(colNamesEn[i]))
                break
            end
        end
    end
end

df159 = DataFrame()

for yf in files
    if !contains(yf, "xlsx") || yf[end-4:end] != ".xlsx" 
        continue 
    end
    println(yf)

    y = yf[1:5]
    xlsx = XLSX.readxlsx(DataDir * "/" * y * ".xlsx")
    s = xlsx[y]
    df = XLSX.eachtablerow(s) |> DataFrames.DataFrame

    changeColumnNames(df)
    df = df[!, [x for x in unique(colNamesEn)]]
    df.Date = Dates.Date.(string.(df.Date), "yyyymmdd")
    df[!, :Open] = convert.(Float64, df[:, :Open])
    df[!, :High] = convert.(Float64, df[:, :High])
    df[!, :Low] = convert.(Float64, df[:, :Low])
    df[!, :Close] = convert.(Float64, df[:, :Close])

    df = DropDatesOutside(df, StartDate, EndDate)
    df = DropNAValues(df)

    println(names(df))

    df1 = filter(row -> row.Contract[end-1:end] == "01", df)
    df5 = filter(row -> row.Contract[end-1:end] == "05", df)
    df9 = filter(row -> row.Contract[end-1:end] == "09", df)

    # global df159 = vcat(df159, df1, df5, df9)

    if nrow(df159) == 0
        global df159 = vcat(df1, df5, df9)
    else
        global df159 = vcat(df159, df1, df5, df9)
    end
end

transform!(df159, names(df159) .=> ByRow(identity), renamecols=false)

dfStitch, dfRoll = stitchDF(df159, :OpenInterest)
ofname = DataDir * "/Stitched.csv"
CSV.write(ofname, dfStitch)

ofname = DataDir * "/Roll.csv"
CSV.write(ofname, dfRoll)

adjustDF(dfStitch, dfRoll, "M")
ofname = DataDir * "/StitchedAdjM" * ".csv"
println("Stitch final output file is: ", ofname)
CSV.write(ofname, dfStitch)
