
function ResetTradesManager(TMan::TradesManager)
    fill!(TMan.curPositions, 0.)
    TMan.trades = Array{OneTrade}(undef, 0)
    i = Int(1)
    while i <= TMan.MaxRepeatingTrades
        TMan.positions[i].lots = 0
        i += Int(1)
    end
    nothing
end

function SetInitialEquity(sys::StratSys, equity::Float64)
    sys.TMan.InitialEquity = equity
    sys.TMan.AvailEquity = sys.TMan.InitialEquity
nothing
end

function SetMaxRepeatingTrades(TMan::TradesManager, maxTrades::Int)
    TMan.MaxRepeatingTrades = maxTrades
    TMan.positions=Array{OneTrade}(undef, TMan.MaxRepeatingTrades)
    for i = 1 : TMan.MaxRepeatingTrades
        TMan.positions[i] = OneTrade()
    end
    nothing
end

function SetUseEquityPC(sys::StratSys, UseEquityPC::Float64)
    sys.TMan.UseEquityPC = min(1., UseEquityPC)
    nothing
end

function GetTradeSlot(sys::StratSys)
    if ChiefOK2Trade(sys.PortChief)
        for i = 1 : sys.TMan.MaxRepeatingTrades
            if sys.TMan.positions[i].lots == Int(0)
                return i
            end
        end
    end
    Int(0)
end

function IsEmptySlot(TMan::TradesManager, i::Int)
    TMan.positions[i].lots == Int(0)
end

function RecordMaxTrades(sys::StratSys)
    data = sys.tradeData
    if data.maxOverLapTrades < sys.TMan.curPositions[data.i]
        data.maxOverLapTrades = sys.TMan.curPositions[data.i]
    end
    nothing
end

function GetFixEquity(sys::StratSys)
    sys.TMan.AvailEquity = sys.TMan.InitialEquity * sys.TMan.UseEquityPC
    nothing
end

function GetCumEquity(sys::StratSys)
    data = sys.tradeData
    sys.TMan.AvailEquity = (sys.TMan.InitialEquity + data.CRet[data.i-1])  * sys.TMan.UseEquityPC
    nothing
end

GetEquity(sys::StratSys) = GetFixEquity(sys)
# GetEquity(sys::StratSys) = GetCumEquity(sys)

function CalcLotsMulti(sys::StratSys, EntryPrice::Float64)
    round(Int, fld(sys.TMan.AvailEquity, (sys.contract.MarginedContractSize * EntryPrice)))
end

function CalcLotsSingle(sys::StratSys, EntryPrice::Float64)
    Int(1)
end

CalcLots(sys::StratSys, EntryPrice::Float64) = CalcLotsMulti(sys, EntryPrice)
# CalcLots(sys::StratSys, EntryPrice::Float64) = CalcLotsSingle(sys, EntryPrice)

function RatioTradeCosts(sys::StratSys, price::Float64)
    sys.contract.TradeCostsR * price
end

function DirectTradeCosts(sys::StratSys, price::Float64=1.)
    sys.contract.TradeCosts
end

TradeCosts(sys::StratSys, price::Float64) = RatioTradeCosts(sys, price)
# TradeCosts(sys::StratSys, price::Float64) = DirectTradeCosts(sys, price)

function RequestEntry(sys::StratSys, EntryPrice::Float64)
    iTrade = GetTradeSlot(sys)
    if iTrade>0
        GetEquity(sys)
        data = sys.tradeData
        sys.TMan.positions[iTrade].entryPrice = EntryPrice
        sys.TMan.positions[iTrade].entryDay = sys.tradeData.i
        sys.TMan.positions[iTrade].lots = CalcLots(sys, EntryPrice)
        sys.TMan.positions[iTrade].tradeMultiply = 1. * sys.TMan.positions[iTrade].lots * sys.LS * sys.contract.ContractSize
        sys.TMan.positions[iTrade].costMultiply = sys.TMan.positions[iTrade].lots * TradeCosts(sys, EntryPrice)
        sys.TMan.curPositions[data.i] += Int(1)
        ChiefReportEntry(sys.PortChief)
        RecordMaxTrades(sys)

        if sys.PrintTrades
            println(sys.tradeOfd, data.i, " ", sys.tech.baseT.dt[data.i],
                " +Enter Trade #", iTrade, " at price: ", (EntryPrice),
                " Lots: ",  sys.TMan.positions[iTrade].lots, " LS: ", sys.LS,
                " Costs: ", round(0.5*sys.TMan.positions[iTrade].costMultiply))
            flush(sys.tradeOfd)
        end
    end
    iTrade
end

function ReportExit(sys::StratSys, jTrade::Int, ExitPrice::Float64, tradeProfit::Float64)
    data = sys.tradeData
    if sys.PrintTrades
        println(sys.tradeOfd, data.i, " ", sys.tech.baseT.dt[data.i],
            " -Exit Trade #", jTrade, " at price: ", (ExitPrice),
            " Lots: ",  sys.TMan.positions[jTrade].lots,
            " Costs: ", round(0.5*sys.TMan.positions[jTrade].costMultiply),
            " with Profit: ", round(tradeProfit))
        flush(sys.tradeOfd)
    end
    if sys.SaveTrades
        trade = OneTrade()
        trade.entryPrice = sys.TMan.positions[jTrade].entryPrice
        trade.entryDay = sys.TMan.positions[jTrade].entryDay
        trade.lots = sys.LS * sys.TMan.positions[jTrade].lots
        trade.exitPrice = ExitPrice
        trade.exitDay = data.i
        push!(sys.TMan.trades, trade)
    end

    RecordMaxTrades(sys)

    sys.TMan.curPositions[data.i] -= 1
    sys.TMan.positions[jTrade].entryDay = Int(0)
    sys.TMan.positions[jTrade].lots = Int(0)

    ChiefReportExit(sys.PortChief)
    nothing
end

function DailyReport(sys::StratSys)
    RecordMaxTrades(sys)
    data = sys.tradeData
    if sys.PrintTrades
        if abs(data.CRet[data.i]) > 0.1
            println(sys.tradeOfd, data.i, " ", sys.tech.baseT.dt[data.i],
                " EndOfDay price: ", sys.tech.cl[data.i],
                " CRet (average): ", round(data.CRet[data.i]))
            flush(sys.tradeOfd)
        end
    end
    
    if data.i<data.tEnd
        sys.TMan.curPositions[data.i+1] = sys.TMan.curPositions[data.i]
    end
    nothing
end
