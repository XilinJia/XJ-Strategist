
# What it is

Stitcher is a utility writen in Julia for constructing continuous contract data needed for analysing trading instruments of either financial or commodity futures.  The continuous contract can be used for devising or backtesting of trading strategies.  Stitcher takes historical data of individual contracts in CSV format, selects the trading data of the contract of most interests on any given trading day, thus forming a new linage of trading history, then back-adjust prices to eliminate prices gaps on changes of actual contracts, outputs the data in the same CSV format.

# How it works

The historical data of individual contracts can be provided in separate files or a lumpsum file.  The names of the files should contain "Contract" and end with ".csv".

The files need to have at least these columns:

"Date","Open","High","Low","Close","Open_Interest","Contract"

They can have other columns, and the extra columns will just pass through without touch.

"Date" should be String in the format of "yyyy-mm-dd", like "2010-03-24".

"Open","High","Low","Close" should be floating point numbers

The column of "Contract" notes the name of the contract, for instance, "F2015", "K2015" etc.  The actual name given is not of a concern to Stitcher as long as they are consistent duing one batch of processing.

So on any given trading day, there are various contracts being traded.  Stitcher selects the contract with the highest "Open_Interest" on that day.  If the name of the column "Open_Interest" is not such, you can specify it with argument as "openInterest = :Interest" (if your column is denominated as "Interest").  Anyhow, the openInterest column should be floating point numbers.

Function Stitch takes the following arguments, with defaults specified:

Instr="".  By default, Stitch uses the current directory as the working directory for inputs and outputs.  If you specify Instr="Gold", then it uses the subdirectory of "Data/Gold" as the working directory.

StartDate="2010-01-01" and EndDate="2050-12-31" are to specify the date range of the output file.  Dates outside of this range in the input files are dropped.

AdjMethod="M" specifies the method to back adjust price data due to gaps.  The default uses multiplication (or division) method.  If you specify otherwise, it will use addition (or subtraction) method (note: this can generate negative prices which can be not proper for trading analysis).

Finally, openInterest::Symbol=:Open_Interest has been addressed above.

On outputs, there are three files:

Stitched.csv is the stitched data but not back adjusted.

Roll.csv contains only the dates with contract changes.

StitchedAdjM.csv (or StitchedAdjA.csv) is the final stitched and adjusted data.

# How to use it

Stitcher is compatible with Julia 1.7.2.

As prerequisites, it requires three Julia packages: Dates, CSV, DataFrames

Test data are provided under Data subdirectory.

To run the test, do:

$ julia

julia> using DataRoutines

julia> cd("Data")

julia> Stitch()

# License

Stitcher is provided under MIT License: https://opensource.org/licenses/MIT

# No warrantee and No Guarrantee

The author hereby provides no warrantee of the utility and no guarantee for trading success.