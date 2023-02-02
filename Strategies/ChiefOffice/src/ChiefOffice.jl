__precompile__(true)

module ChiefOffice

export ChiefOfficer
export ResetChief
export ChiefSetMaxConcurs, ChiefOK2Trade, ChiefReportEntry, ChiefReportExit

mutable struct ChiefOfficer
    InitialEquity::Float64
    MaxConcurTrades::Int
    curPos::Int

    function ChiefOfficer(MaxConcurs::Int=1)
        this = new()
        this.InitialEquity = 1000000.
        this.curPos = Int(0)
        this.MaxConcurTrades = MaxConcurs
        println("ChiefOfficer allows a maximum of ", this.MaxConcurTrades, " concurrent trades")
        this
    end
end

function ResetChief(chief::ChiefOfficer)
    chief.curPos = Int(0)
    nothing
end

function ChiefSetMaxConcurs(chief::ChiefOfficer, maxConcurs::Int)
    chief.MaxConcurTrades = maxConcurs
    println("ChiefOfficer now allows a maximum of ", chief.MaxConcurTrades, " concurrent trades")
    nothing
end

function ChiefOK2Trade(chief::ChiefOfficer)
    chief.curPos < chief.MaxConcurTrades
end

function ChiefReportEntry(chief::ChiefOfficer)
    chief.curPos += 1
    nothing
end

function ChiefReportExit(chief::ChiefOfficer)
    chief.curPos -= 1
    nothing
end


end  # module