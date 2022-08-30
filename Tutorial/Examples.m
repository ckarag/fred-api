%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% fred_api() Examples %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-----------------------------%
% (A) Request a single series %
%-----------------------------%

%- Retrieve all the available dates
fred_code = 'CPIAUCSL';  %CPI Inflation (monthly)
[TT, Meta] = fred_api(fred_code);
[TT, Meta] = fred_api(fred_code, 'StartDate',NaT,'EndDate',NaT); %Equivalent to above
[TT, Meta] = fred_api(fred_code, 'StartDate',[],'EndDate',[]);   %Equivalent to above
[TT, Meta] = fred_api(fred_code, 'StartDate',[],'EndDate',datetime('now'));  %Equivalent to above

%Print the last 5 rows
TT(end-4:end, :)

%Print selected metadata
Meta(:, ["DateRange","Frequency","LastUpdated","Units","SeasonalAdjustment"])

%- Retrieve selected range (from startdate to enddate)
fred_code = 'CPIAUCSL';
startdate = datetime(2020,1,1);
enddate = datetime(2020,12,1);
[TT, Meta] = fred_api(fred_code, 'StartDate',startdate, 'EndDate',enddate);

%Print the entire table
TT(:,:) 

%Return the series as a numerical vector (instead of timetable)
TT{:,:}

%-----------------------------%
% (B) Request multiple series %
%-----------------------------%

%- Request SAME-FREQUENCY variables
fred_code = ["INDPRO","IPB50001N","UNRATE"]; %3 monthly series
[TT, Meta] = fred_api(fred_code, 'StartDate',datetime(2000,1,1), 'EndDate',datetime(2020,3,1));

%Print the last 5 rows
TT.Time.Format = 'dd-MMM-yyyy'; %Change the display format of dates
TT(end-4:end, :)

%Print selected metadata
Meta(:, ["Frequency","Units","SeasonalAdjustment"])

%Plot the series
p = stackedplot(TT,{["INDPRO" "IPB50001N"] "UNRATE"});
p.Title = 'Industrial Production & Unemployment';
p.DisplayLabels = {'IP','Unemp.'};
p.AxesProperties(1).LegendLabels = ["IP SA","IP NSA"];
p.AxesProperties(1).LegendLocation = 'SouthEast';

%- Request variables of DIFFERENT FREQUENCIES
fred_code = ["INDPRO","GDPC1"];  %1 monthly & 1 quarterly series
[TT, Meta] = fred_api(fred_code, 'StartDate',datetime(2000,1,1), 'EndDate',datetime(2022,6,1));

%Print the last 8 rows
TT(end-7:end, :)

%Print selected metadata
Meta(:, ["Frequency","Units","SeriesID"])

%Fill the quarterly series by repeating within-period values
TT(:,"GDPC1") = fillmissing(TT(:,"GDPC1"),'previous');

%Print the last 8 rows
TT(end-7:end, :)

%Plot the series in separate panels
p = stackedplot(TT);
p.Title = 'Industrial Production & Real GDP';
