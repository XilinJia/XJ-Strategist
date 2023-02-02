
module MoleWrappers

using StratSysM

export SchemeRunnerS, SchemeRunnerMNoOpt, MoleculeWrap, MoleculeWrapN

function SchemeRunnerS(csign::Int, sys::StratSys,
            ShortScheme::TS, BuyScheme::TB, ls::Int, TradeType::Int) where TS <: Function where TB <: Function
    if ls<=0
        ShortScheme(csign, sys, 0.)
        # sys.dataO = deepcopy(sys.tradeData)
    end
    if ls>=0
        BuyScheme(csign, sys, 0.)
        # sys.dataO = deepcopy(sys.tradeData)
    end
    nothing
end

function SchemeRunnerMNoOpt(csign::Int, sys::StratSys,
                ShortScheme::TS, BuyScheme::TB,
                SSchemeRange::Vector{Float64}, BSchemeRange::Vector{Float64},
                ls::Int, TradeType::Int) where TS <: Function where TB <: Function
    if ls<=0
        xRat=SSchemeRange[1]+2. *(SSchemeRange[end]-SSchemeRange[1])/3
        # xRat=SSchemeRange[end]
        ShortScheme(csign, sys, xRat)
    end
    if ls>=0
        xRat=BSchemeRange[1]+2. *(BSchemeRange[end]-BSchemeRange[1])/3
        # xRat=BSchemeRange[end]
        BuyScheme(csign, sys, xRat)
    end
    nothing
end

function MoleculeWrap(csign::Int, ls::Int, sys::StratSys, MoleculeTrade::T, xRat::Float64, 
        TradeType::Int) where T <: Function
    ResetStratSys(sys, ls, csign, xRat, TradeType)
    for i = sys.sStart:sys.sEnd-TradeType # *** "-TradeType" is a temp solution
        MoleculeTrade(i, sys, xRat)
    end
    PreserveCRet(sys)
    if TradeType==TradeTypeNext
        RightShiftArrays!(sys.tradeData)
    end
    nothing
end

function MoleculeWrapN(csign::Int, ls::Int, sys::StratSys, MoleculeTrade::T, xRat::Float64) where T <: Function
    ResetStratSys(sys, ls, csign, xRat, TradeTypeMulti)
    for i = sys.sStart:sys.sEnd
        @inbounds MoleculeTrade(i, sys, xRat)
    end
    PreserveCRet(sys)
    nothing
end

end