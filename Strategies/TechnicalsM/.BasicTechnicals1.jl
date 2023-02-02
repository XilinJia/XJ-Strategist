mutable struct Technicals
    baseT::BaseTech

    cllen::Int
    tStart::Int
    tEnd::Int

    op::Vector{Float64}
    hi::Vector{Float64}
    lo::Vector{Float64}
    cl::Vector{Float64}

    mid::Vector{Float64}

    vol::Vector{Float64}

    Fields2Expand::Array{String,1}

    function Technicals(datafile::String, fieldsNeeded::Array{String,1}=String[])
        this = new()
        this.baseT = BaseTech(datafile)

        this.op = this.baseT.op
        this.hi = this.baseT.hi
        this.lo = this.baseT.lo
        this.cl = this.baseT.cl

        this.mid = 0.5 * (this.hi .+ this.lo)

        this.vol = this.baseT.vol

        this.cllen = length(this.cl)
        this.tStart = OneMonth
        this.tEnd = this.cllen
    
        this.Fields2Expand = fieldsNeeded

        InitializeTechnicals(this)
        if length(this.Fields2Expand)>0
            ExpUpdateTechnicals(this)
        end

        this
    end

    function Technicals()
        this = new()
        this.cllen = 0
        InitializeTechnicals(this)
        this
    end
end
