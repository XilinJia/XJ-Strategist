__precompile__(true)

module TechnicalsM

using CSV, Tables
using Dates

export Technicals, RequireExpFields, ExpUpdateTechnicals
export ExpUpdateTechElem, ExpUpdateTechElems, getTechField
export ExtractTechFieldsOffString
export sma, ema, cmo, vema, kama, TSI, pdi, ndi, adx
export truerange, atr, NBarHigh, NBarLow, NBarHighLow, NBarHighLowDistance, mstd, mstdd
export zigzag, linear_regression, advance_regres, forecast, NBarRetR, mquantile, flipflop, flipflopPC
export mskew, mcor, mcorkendall, mautocor
export corShifted, corkendallShifted

export CZFields

const OneMonth=20
const TwoWeek=10
const WLookback=5

struct BaseTech
    dt::Array{DateTime,1}
    op::Vector{Float64}
    hi::Vector{Float64}
    lo::Vector{Float64}
    cl::Vector{Float64}

    vol::Vector{Float64}

    function BaseTech(datafile::String)
        df = CSV.File(datafile) |> columntable
        if haskey(df, :Time)
            # println(df[:Date], df[:Time])
            # dts = convert(String, (df[:Date] * "T" .* df[:Time]))
            dts = df[:Date] .* "T" .* df[:Time]
            # println(dts)
            dt = DateTime.(dts, "yyyy/mm/ddTHH:MM:SS")
            # dt = convert(Array{DateTime}, dts)
        else
            dt = map(DateTime, df.Date)
        end
        op = map(Float64, df.Open)
        hi = map(Float64, df.High)
        lo = map(Float64, df.Low)
        cl = map(Float64, df.Close)
        vol = map(Float64, df.Volume)

        new(dt, op, hi, lo, cl, vol)
    end

    function BaseTech()
        dt = Array{DateTime}(undef, 0)
        op = Vector{Float64}(undef, 0)
        hi = Vector{Float64}(undef, 0)
        lo = Vector{Float64}(undef, 0)
        cl = Vector{Float64}(undef, 0)
        vol = Vector{Float64}(undef, 0)
        new(dt, op, hi, lo, cl, vol)
    end
end

mutable struct FlipFlopData
    normal::Bool
    h::Float64
    l::Float64
    E::Vector{Float64}
end

include("_AutoTechnicals.jl")
include("_AutoDerivedTechs.jl")

include("TechIndicators.jl")

function ExpandTech(tech::Technicals, ds::String,
            op::Float64, hi::Float64, lo::Float64, cl::Float64, vol::Float64)
    basetech = tech.BaseT

    push!(basetech.op, op)
    push!(basetech.hi, hi)
    push!(basetech.lo, lo)
    push!(basetech.cl, cl)
    push!(basetech.vol, vol)
    if occursin("/", ds)
        dt = DateTime(ds, "yyyy/mm/dd")
    else
        # assuming date string contains "-", then just using it
        dt = DateTime(ds)
    end
    push!(basetech.dt, dt)

    push!(tech.op, op)
    push!(tech.hi, hi)
    push!(tech.lo, lo)
    push!(tech.cl, cl)
    push!(tech.vol, vol)

    ExpUpdateTechnicals(tech)

    nothing
end

function FeedTechElement(tech::Technicals, ds::String,
            op::Float64, hi::Float64, lo::Float64, cl::Float64, vol::Float64)
    basetech = tech.BaseT

    basetech.op[tech.cllen] = op
    basetech.hi[tech.cllen] = hi
    basetech.lo[tech.cllen] = lo
    basetech.cl[tech.cllen] = cl
    basetech.vol[tech.cllen] = vol
    if occursin("/", ds)
        dt = DateTime(ds, "yyyy/mm/dd")
    else
        # assuming date string contains "-", then just using it
        dt = DateTime(ds)
    end
    basetech.dt[tech.cllen] = dt

    tech.op[tech.cllen] = op
    tech.hi[tech.cllen] = hi
    tech.lo[tech.cllen] = lo
    tech.cl[tech.cllen] = cl
    tech.vol[tech.cllen] = vol

    ExpUpdateTechnicals(tech)

    nothing
end

function InitializeTechnicals(tech::Technicals)
    fields = fieldnames(typeof(tech))
    indexOfVol=10000
    for i in eachindex(fields)
        if String(fields[i])=="vol"
            indexOfVol=i
        end
        # initialize all after the field vol
        if i>indexOfVol
            if fieldtype(Technicals, fields[i]) == Vector{Float64}
                setfield!(tech, fields[i], Vector{Float64}(undef, 0))
            end
            if fieldtype(Technicals, fields[i]) == Vector{Int}
                setfield!(tech, fields[i], Vector{Int}(undef, 0))
            end
        end
    end
    nothing
end

function DelTechElement(tech::Technicals)
    fields = fieldnames(typeof(tech))
    # start the scheme at tech.mid
    for i=7:length(fields)
        pop!(getfield(tech, fields[i]))
    end
    nothing
end

function ExtractTechFieldsOffString(tt::String)
    # the string contains "tech." and comes with either '\n' or " " as separators
    tts = ""
    if occursin('\n', tt)
        tts = split(tt, '\n')
    else
        tts = split(tt, " ")
    end
    fieldNames = Array{String,1}(undef, 0)
    for ts in tts
        if occursin("tech.", ts) && !occursin("cl", ts)
            aIndex = findfirst(".", ts)[1]+1
            if occursin("[", ts[aIndex:end])
                eIndex = findnext("[", ts, aIndex)[1]-1
            elseif occursin(",", ts[aIndex:end])
                eIndex = findnext(",", ts, aIndex)[1]-1
            else
                eIndex = 1000
            end
            push!(fieldNames, ts[aIndex:min(end, eIndex)])
        end
    end
    fieldNames
end

function Check2FillTechField(tech::Technicals, fieldFunc::T, fieldName::String) where T <: Function
    techCode = map(string, code_lowered(fieldFunc)[1].code)
    for i in eachindex(techCode)
        stLine = techCode[i]
        if occursin("_2", stLine) && occursin(":", stLine)
            colonIndex = findfirst(":", stLine)[1]
            parenIndex = findnext(")", stLine, colonIndex)[1]
            techFieldName = stLine[colonIndex+1 : parenIndex-1]
            if techFieldName == fieldName
                continue
            end
            ExpUpdateTechElem(tech, Symbol(techFieldName))
        end
    end
    nothing
end

function RequireExpFields(tech::Technicals, fieldsNeeded::Array{String,1})
    tech.Fields2Expand = fieldsNeeded
    nothing
end

function ExpUpdateTechnicals(tech::Technicals)
    lenNew = length(tech.cl)

    fields = fieldnames(typeof(tech))
    println("total number of fields in Technicals: ", length(fields))

    indexOfVol=10000
    indexofFields2Expand=10000
    for i in eachindex(fields)
        sfield = String(fields[i])
        if sfield=="vol"
            indexOfVol=i
        end
        if sfield=="Fields2Expand"
            indexofFields2Expand=i
        end
        if i>indexOfVol && ((sfield in tech.Fields2Expand) ||
                (sfield[1]!='f' && sfield[1]!='a'))
            if fieldtype(Technicals, fields[i]) == Vector{Float64}
                field = getfield(tech, fields[i])
                lenOld = length(field)
                append!(field, zeros(lenNew-lenOld))
                if i<indexofFields2Expand
                    fieldFunc = getfield(TechnicalsM, Symbol("AU_T_" * string(fields[i])))
                    Check2FillTechField(tech, fieldFunc, string(fields[i]))
                    for ii=lenOld+1:lenNew
                        field[ii] = fieldFunc(tech, ii)
                    end
                end
            end
        end
    end
    nothing
end

function ExpUpdateTechElem(tech::Technicals, i::Int)
    fields = fieldnames(typeof(tech))
    field = getfield(tech, fields[i])
    if length(field)<tech.cllen
        lenOld = length(field)
        lenNew = tech.cllen
        if fieldtype(Technicals, fields[i]) == Vector{Float64}
            append!(field, zeros(lenNew-lenOld))
            fieldFunc = getfield(TechnicalsM, Symbol("AU_T_" * string(fields[i])))
            Check2FillTechField(tech, fieldFunc, string(fields[i]))
            for ii=lenOld+1:lenNew
                field[ii] = fieldFunc(tech, ii)
            end
        end
    end
    nothing
end

function ExpUpdateTechElem(tech::Technicals, fieldSymbol::Symbol)
    if fieldtype(Technicals, fieldSymbol) == Vector{Float64}
        field::Vector{Float64} = getfield(tech, fieldSymbol)
        if length(field)<tech.cllen
            lenOld = length(field)
            lenNew = tech.cllen
            append!(field, zeros(lenNew-lenOld))
            fieldFunc = getfield(TechnicalsM, Symbol("AU_T_" * string(fieldSymbol)))
            Check2FillTechField(tech, fieldFunc, string(fieldSymbol))
            for ii=lenOld+1:lenNew
                field[ii] = fieldFunc(tech, ii)
            end
        end
    end
    nothing
end

function ExpUpdateTechElems(tech::Technicals, FieldsNeeded::Array{String,1})
    fields = fieldnames(typeof(tech))
    for fieldname in FieldsNeeded
        field = getfield(tech, Symbol(fieldname))
        if length(field)<tech.cllen
            lenOld = length(field)
            lenNew = tech.cllen
            if fieldtype(Technicals, Symbol(fieldname)) == Vector{Float64}
                append!(field, zeros(lenNew-lenOld))
                fieldFunc = getfield(TechnicalsM, Symbol("AU_T_" * fieldname))
                Check2FillTechField(tech, fieldFunc, fieldname)
                for ii=lenOld+1:lenNew
                    field[ii] = fieldFunc(tech, ii)
                end
            end
        end
    end
    nothing
end

function getTechField(tech::Technicals, fieldSymbol::Symbol)
    ExpUpdateTechElem(tech, fieldSymbol)
    getfield(tech, fieldSymbol)
end

end     # module