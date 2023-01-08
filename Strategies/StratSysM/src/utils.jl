
function PrintTrades(sys::StratSys, fileExt::String="", initText::String="")
    sys.PrintTrades = true
    if sys.PrintTrades
        filename = sys.contract.fbasename * "Trades" * fileExt * ".txt"
        if stat(filename).size > 150
            fnamebak = sys.contract.fbasename * "Trades" * fileExt * "-" * string(now()) * ".txt"
            println("moving existing record file to: ", fnamebak)
            mv(filename, fnamebak)
        end
        println("Printing trades to file: ", filename)
        sys.tradeOfd = open(filename, "w")
        println(sys.tradeOfd, initText)
        println(sys.tradeOfd, "Starting date: ", sys.tech.baseT.dt[1], "\n")
    end
    nothing
end

function EndPrintTrades(sys::StratSys)
    sys.PrintTrades = false
    close(sys.tradeOfd)
    nothing
end

function StartSaveTrades(sys::StratSys)
    sys.SaveTrades = true
    nothing
end

function EndSaveTrades(sys::StratSys)
    sys.SaveTrades = false
end

function BarsWithWinningTrades(sys::StratSys)
    bars = Vector{Int}(undef,0)
    for i=1:length(sys.TMan.trades)
        trade = sys.TMan.trades[i]
        profit = trade.lots * (trade.exitPrice - trade.entryPrice)
        if profit>0.
            append!(bars, [trade.entryDay:trade.exitDay;])
        end
    end
    bars
end

function BarsWithLosingTrades(sys::StratSys)
    bars = Vector{Int}(undef,0)
    for i=1:length(sys.TMan.trades)
        trade = sys.TMan.trades[i]
        profit = trade.lots * (trade.exitPrice - trade.entryPrice)
        if profit<0.
            append!(bars, [trade.entryDay:trade.exitDay;])
        end
    end
    bars
end

function CreateConsArray(sys::StratSys)
    zeros(Int, length(sys.EntryBits))
end

function Nonzeros(A::Vector{Float64})
    filter(x -> abs(x)>0.1, A)
end
