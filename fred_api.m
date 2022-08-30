function [TT, Meta] = fred_api(fred_seriescode, varargin)

%fred_api() allows users to conveniently download economic time series data  
%from the FRED (Federal Reserve Economic Data) online database maintained  
%by the Research Department at the Federal Reserve Bank of St. Louis. 
%The data are accessed by connecting directly to the FRED data server 
%(https://fred.stlouisfed.org).
%
%The selected series are returned into a timetable. When multiple series 
%are requested by the user, they are all merged together and returned into 
%the same timetable. Merging returns the union (rather than the 
%intersection) of the dates of the selected series. If a series is shorter
%than the rest of the requested series, the absent observations are set
%into missing (NaN). Similarily, series of different frequencies can also
%be requested in the same function call, and missing observations (that are 
%due to the frequency mismatch) are treated in the same manner. The user 
%can request the desired range of dates by setting the Name-Value pairs 
%'StartDate' and 'EndDate'. If no range is specified, the function 
%retrieves all the observations available in FRED for the selected series. 
%
%INPUTS:
%- 'fred_seriescode': The FRED mnemonic(s) of the requested series.
%- 'StartDate': Specifies the series starting date. If the input is 
%               omitted, the function returns the earliest starting date 
%               available in FRED. The input should be specified as a 
%               datetime e.g. datetime(2021,3,31) for 31st March 2021.
%- 'EndDate':   Specifies the series ending date. If the input is omitted,
%               the function returns the latest ending date available in 
%               FRED. The input should be specified as a 
%               datetime
%
%OUTPUTS:
%- 'TT':   A timetable of size T-by-N containing the timeseries, where N is 
%          the number of the specified FRED series in 'fred_seriescode'. 
%          The dates in the resulted timetable are in DD/MM/YYYY format.
%- 'Meta': A N-by-10 sized table containing metadata information for the 
%          N requested variables. Specifically, the following information 
%          is retruned in the table: 
%           DateRange, Frequency, LastUpdated, Notes, Release, 
%           SeasonalAdjustment, SeriesID, Source, Title, Units. 
%
%Examples:
%A) Request a single time series
%fred_seriescode = 'CPIAUCSL';  %CPI Inflation (monthly)
%fred_seriescode = 'GDPC1';     %US Real GDP (quarterly)
%
%[TT, Meta] = fred_api(fred_seriescode)
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',NaT,'EndDate',NaT) %Equivalent to above
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',[],'EndDate',[]) %Equivalent to above
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',datetime(2000,1,1), 'EndDate',datetime(2005,1,1))
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',datetime(2000,1,1), 'EndDate',datetime('today'))
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',datetime(2000,1,1))
%[TT, Meta] = fred_api(fred_seriescode, 'EndDate',datetime(2005,1,1))
%
%B) Request multiple time series
%fred_seriescode = ["INDPRO","IPB50001N","UNRATE"] %3 monthly series
%fred_seriescode = ["INDPRO","GDPC1"]              %1 monthly & 1 quarterly series
%
%[TT, Meta] = fred_api(fred_seriescode)
%[TT, Meta] = fred_api(fred_seriescode, 'StartDate',datetime(2000,1,1), 'EndDate',datetime(2020,3,1))


po = inputParser;
addRequired(po,'fred_seriescode',@(z) isstring(z) || ischar(z))
addParameter(po,'StartDate',NaT,@(z) isnumeric(z) || isdatetime(z) || isempty(z)) 
addParameter(po,'EndDate',datetime('today'),@(z) isnumeric(z) || isdatetime(z) || isempty(z)) 

parse(po,fred_seriescode,varargin{:});
startdate = po.Results.StartDate;
enddate = po.Results.EndDate;

fred_seriescode = convertCharsToStrings(fred_seriescode);

Nj = length(fred_seriescode);
if Nj > 1
    TT = timetable();
    TT.Time.Format = 'dd/MM/yyyy'; %Set datetime format of final timetable
    Meta = table();
    release = struct('firstdate',NaT(1,Nj), 'lastdate',NaT(1,Nj), 'lastupdate',NaT(1,Nj), 'l8ncy',nan(1,Nj));
    for j=1:Nj
        [tmpTT, tmpMeta, tmprelease] = fred_api(fred_seriescode(j), 'StartDate',startdate,'EndDate',enddate);
        TT = synchronize(TT, tmpTT, 'union', 'fillwithmissing');
        Meta = [Meta; tmpMeta];
        release.firstdate(j) = tmprelease.firstdate;
        release.lastdate(j) = tmprelease.lastdate;
        release.lastupdate(j) = tmprelease.lastupdate;
        release.l8ncy(j) = tmprelease.l8ncy;
    end
    
else %Nj == 1
    
    if isempty(startdate) || ismissing(startdate)
        startdate='-inf';
    end
    if isempty(enddate) || ismissing(enddate)
        enddate=datetime('now');
    end
    
    c = fred('https://fred.stlouisfed.org/'); %Connect to the FRED data server
    c.DataReturnFormat = 'table'; 
    c.DatetimeType = 'datetime';
    
    try
        dow = fetch(c,fred_seriescode);
    catch
        warning(['Requested security (' char(fred_seriescode) ') is invalid. fetch() returned nothing.']);
        TT = table();
        Meta = table();
        if nargout > 2
            release = struct([]);
        end
        close(c)
        return
    end
    TTrng = timerange(startdate,enddate,'closed');
    
    vars = setdiff(dow.Properties.VariableNames, 'Data');
    Meta = dow(:,vars);
    Meta = convertvars(Meta, @isdatetime, @(t) datetime(t, 'Format', 'dd/MM/yyyy'));
    Meta = convertvars(Meta, @iscellstr, @string);
    Meta{:,vars} = strip(Meta{:,vars});
        
    close(c) %Close the FRED connection
        
    dow.Data{:} = convertvars(dow.Data{:}, @isdatetime, @(t) datetime(t, 'Format', 'dd/MM/yyyy'));
    TT = array2timetable(dow.Data{:}{:,2}, 'RowTimes', dow.Data{:}{:,1});
    TT.Properties.VariableNames = {char(fred_seriescode)};
    TT = TT(TTrng,:);
    clear c dow 
end
end