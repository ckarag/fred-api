# fred-api
The function fred_api() allows users to conveniently download economic time series data from the FRED (Federal Reserve Economic Data) online database maintained by the Research Department at the Federal Reserve Bank of St. Louis. The data are accessed by connecting directly to the FRED data server (https://fred.stlouisfed.org).

The selected series are returned into a timetable. When multiple series are requested by the user, they are all merged together and returned into the same timetable. Merging returns the union (rather than the intersection) of the dates of the selected series. If a series is shorter than the rest of the requested series, the absent observations are set into missing (NaN). Similarly, series of different frequencies can also be requested in the same function call, and missing observations (that are due to the frequency mismatch) are treated in the same manner. The user can request the desired range of dates by setting the Name-Value pairs 'StartDate' and 'EndDate'. If no range is specified, the function retrieves all the observations available in FRED for the selected series. 

This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis.

[![View Interface to easily access FRED® data on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://uk.mathworks.com/matlabcentral/fileexchange/116955-interface-to-easily-access-fred-data)
