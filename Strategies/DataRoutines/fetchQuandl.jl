
using DataFrames
using CSV

include("DataRoutines.jl")
# using DataRoutines


GetData("DCE", "P", "2015-01", "2022-09", [1,5,9])
GC.gc()
# GetData("DCE", "Y", "2019-05", "2019-09", [1,5,9])
# GC.gc()

# GetData("ZCE", "SR", "2015-01", "2019-09", [1,5,9])
# GC.gc()
# GetData("ZCE", "TA", "2010-01", "2019-09", [1,5,9])
# GC.gc()
# GetData("ZCE", "CF", "2018-09", "2019-09", [1,5,9])
# GC.gc()
#
# GetData("SHFE", "AG", "2019-01", "2019-09", [1,2,3,4,5,6,7,8])
# GC.gc()
# GetData("SHFE", "ZN", "2018-09", "2019-09", [1,2,3,4,5,6,7,8])
# GC.gc()
