module Contracts_CFG

using CSV, Tables

export Contract, datadir, contractsDict, GetContractCFG

mutable struct Contract
    InstrName::String
    ExchangeName::String
    ContractSize::Int
    margin::Float64
    Commission::Float64
    Slippage::Float64
    CommissionR::Float64
    SlippageR::Float64

    TradeCosts::Float64
    TradeCostsR::Float64
    MarginedContractSize::Float64

    datafile::String
    WalkForwardData::String
    FullWFData::String
    minData::String
    basedir::String
    fbasename::String

    function Contract()
        this = new()
        this
    end
end

const datadir="../../Data/"
const outpurdir = "../../Outputs/"

const contractsDict = Dict{String, Contract}()

function InitContractsCFG()
    df = CSV.File("Contracts_CFG/Contracts_CFG.csv") |> columntable
    for i=1:length(df.Name)
        tmp = Contract()
        tmp.InstrName = df[:Name][i]
        tmp.ExchangeName = df[:Exchange][i]
        tmp.ContractSize = df[:ContractSize][i]
        tmp.margin = df[:Margin][i]
        tmp.Commission = df[:Commission][i]
        tmp.Slippage = df[:Slippage][i]
        tmp.CommissionR = df[:CommissionR][i]
        tmp.SlippageR = df[:SlippageR][i]

        tmp.TradeCosts = 2. * tmp.ContractSize * tmp.Slippage + 2. * tmp.Commission
        tmp.TradeCostsR = 2. * tmp.ContractSize * tmp.SlippageR + 2. * tmp.CommissionR
        tmp.MarginedContractSize = tmp.margin * tmp.ContractSize

        tmp.datafile = datadir * tmp.InstrName * "/" * df[ :Data][i] * ".csv"
        tmp.WalkForwardData = datadir * tmp.InstrName * "/" * df[ :WFData][i] * ".csv"
        tmp.FullWFData = datadir * tmp.InstrName * "/" * df[ :FWFData][i] * ".csv"
        tmp.minData = datadir * tmp.InstrName * "/" * df[ :MinData][i] * ".csv"
        tmp.basedir = outpurdir * tmp.InstrName * "/"
        tmp.fbasename = outpurdir * tmp.InstrName * "/" * tmp.InstrName
        contractsDict[tmp.InstrName] = tmp
    end
    nothing
end

function GetContractCFG(InstrName::String)
    InitContractsCFG()
    get(contractsDict, InstrName, "")
end

end     #module