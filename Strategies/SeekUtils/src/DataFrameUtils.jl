using DataFrames, CSV

function deleterow(df::DataFrame, row::Int)
    return df[[1:row-1, row+1:end], :]
end

function deleterows(df::DataFrame, rows::Vector{Int})
    return df[setdiff(1:end,rows), :]
end


function DropRowsByKeyVal(df::DataFrame, Key::Symbol, MinVal::Float64, Dir=1)
    rows=Vector{Int}(undef, 0)
    for ii=1:nrow(df)
        if Dir*(df[ii, Key]-MinVal)<0
            push!(rows, ii)
        end
    end
    return deleterows(df, rows)
end

function KeepRowsBetweenVals(df::DataFrame, Val::Symbol, MinVal::Float64, MaxVal::Float64)
    sort!(df, [(order(:Val, rev=true)),])
    rows=Vector{Int}(undef,0)
    for ii=1:nrow(df)
        if df[ii, Val]-MinVal<0. || df[ii, Val]-MaxVal>0.
            push!(rows, ii)
        end
    end
    return deleterows(df, rows)
end

function DFIntersect(df1::DataFrame, df2::DataFrame)
    A1 = Array{Array{String,1}}(0)
    for i=1:nrow(df1)
        println(df1[i, :Conds], " ", df1[i, :Seg], " ", df1[i, :Wrapper])
        A = Array{String}(0)
        push!(A, df1[i, :Conds])
        push!(A, df1[i, :Seg])
        push!(A, df1[i, :Wrapper])
        push!(A1, A)
    end

    A2 = Array{Array{String,1}}(0)
    for i=1:nrow(df2)
        A = Array{String}(0)
        push!(A, df2[i,:Conds])
        push!(A, df2[i,:Seg])
        push!(A, df2[i,:Wrapper])
        push!(A2, A)
    end

    A12 = intersect(A1, A2)
    dfo = DataFrame()
    for name in names(df1)
        dfo[name]=""
    end
    for i in eachindex(A12)
        push!(dfo, A12[i])
    end

    dfo
end

function SortFileByKey(fname::AbstractString, Key=:Quality)
    df = CSV.read(fname*".csv")
    sort!(df, (order(Key, rev=true)))
    ofname = fname * ".csv"
    writetable(ofname, df)
end

function DropRowsByKeyVal(fnames::Array{String,1}, Key::Symbol, MinVal::Float64, Dir=1)
    numFiles = length(fnames)
    for ii=1:numFiles
        fname = fnames[ii]*".csv"
        df = CSV.read(fnames[ii]*".csv")
        dfo = DropRowsByKeyVal(df, Key, MinVal, Dir)
        println("Orig rows: ", nrow(df), " new rows: ", nrow(dfo))
        writetable(fnames[ii]*string(Key)*".csv", dfo)
    end
    nothing
end

function CombineCSVFiles(fname1::AbstractString, fname2::AbstractString)
    df1 = CSV.read(fname1*".csv")
    df2 = CSV.read(fname2*".csv")

    dfn = vcat(df1, df2)

    ofname = fname1 * "C.csv"
    writetable(ofname, dfn)
end

# TODO not sure if these below are useful any more

function ChooseAroundKey(fname::AbstractString, Key::Symbol, Val::Float64)
    df = PrepDF(fname)

    df1 = KeepRowsBetweenVals(df, Key, Val*0.9, Val*1.1)
    df1[:Strats] = df1[:Strats] * string(Key)
    df1 = DelRedund(df1)
    ofname = fname * string(Key) * ".csv"
    writetable(ofname, df1)
end

function ChooseinKeyRange(fname::AbstractString, Key::Symbol, MinVal::Float64, MaxVal::Float64)
    df = PrepDF(fname)

    df1 = KeepRowsBetweenVals(df, Key, MinVal, MaxVal)
    df1[:Strats] = df1[:Strats] * string(Key)
    df1 = DelRedund(df1)
    ofname = fname * string(Key) * ".csv"
    writetable(ofname, df1)
end

function CountConditions(fname::AbstractString)
    df = CSV.read(fname*".csv")

    for Col in [:Cond; :Filter]
        sort!(df, (order(Col)))
        str=""
        num=0
        cret=0
        dfo = DataFrame()
        for ii=1:nrow(df)
            if df[ii, Col] != str
                if str != ""
                    cret=round(Int, cret/num)
                    dfo = vcat(dfo, DataFrame(Cond=str, Num=num, CRet=cret))
                end
                # println(str, ", ", num, ", ", cret)
                str = df[ii, Col]
                num=1
                cret=df[ii, :CRet]
            else
                num+=1
                cret=cret+df[ii, :CRet]
            end
        end
        sort!(dfo, (order(:Num, rev=true)))
        ofname=fname*"-"*string(Col)*"Count.csv"
        writetable(ofname, dfo)
    end
end

function DFIntersect(fname1::AbstractString, fname2::AbstractString)
    df1 = CSV.read(fname1*".csv")
    A1 = Array{Array{String,1}}(0)
    for i=1:nrow(df1)
        println(df1[i, :Conds], " ", df1[i, :Seg], " ", df1[i, :Wrapper])
        A = Array{String}(0)
        push!(A, df1[i, :Conds])
        push!(A, df1[i, :Seg])
        push!(A, df1[i, :Wrapper])
        push!(A1, A)
    end

    df2 = CSV.read(fname2*".csv")
    A2 = Array{Array{String,1}}(0)
    for i=1:nrow(df2)
        A = Array{String}(0)
        push!(A, df2[i,:Conds])
        push!(A, df2[i,:Seg])
        push!(A, df2[i,:Wrapper])
        push!(A2, A)
    end

    A12 = intersect(A1, A2)
    dfo = DataFrame()
    for name in names(df1)
        dfo[name]=""
    end
    for i in eachindex(A12)
        push!(dfo, A12[i])
    end
    ofname=fname1*"Joint.csv"
    writetable(ofname, dfo)
end

function DropResults2334(fname::AbstractString)
    colTypes = Dict(:Fseg=>String, :Seg=>String, :XFseg=>String, :xseg=>String)
    df = CSV.read(fname, DataFrame, types=colTypes, validate=false)
    rows = Vector{Int}(undef, 0)
    for ii in 1:nrow(df)
        if df[ii, :Seg] == "2:3" || df[ii, :Seg] == "3:4" || df[ii, :xseg] == "2:3" || df[ii, :xseg] == "3:4"
            # println(ii, " ", df[ii, :])
            push!(rows, ii)
        end
    end
    odf = deleterows(df, rows)
    ofname = fname[1:end-4] * "d.csv"
    CSV.write(ofname, odf)
end