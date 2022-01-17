%%% Extract ocean info from CTD and APB data around Antarctica

%%inputs:
%1) tab-delimited text files of iceberg melt data created by estimate_iceberg_melt_volume.m (*iceberg_meltinfo.txt)
%2) background image for Antarctic maps (Antarctic_RAMP_image_v2_1km.tif)
%3) ship-based conductivity, temperature, & depth mat-files (*CTD.mat) & autonomous pinneped data (*APB.mat): from Carlos Moffat
%4) RACMO data: RACMO2.3p2_XPEN055_T2m_daily_2011_2016.nc & RACMO2.3p2_ANT27_T2m_daily_2011_2016.nc

%%outputs:
%1) Antarctic-ocean-data.mat: CTD & APB structures contain compiled data in a standardized format
%2) Antarctic-icebergmelt-comparison.mat: melt structure w/ iceberg data & nearby CTD and/or APB data
%3) Antarctic-iceberg-oceandata-profiles.eps & .png: geographically-arranged subplots of ocean temp & iceberg depth timeseries
%4) Antarctic-iceberg-oceandata-map.eps & .png: map of study site mean iceberg melt rates & ocean temps
%5) *-iceberg-oceandata-scatterplot.eps & .png: site-specific & Antarctic-wide plots of ocean temp above freezing & iceberg melt rate

%%dependencies:
%1) wgs2ps.m
%2) cmocean.m


%%%

%% initiate
clearvars; close all;
addpath('/users/ellynenderlin/mfiles','/users/ellynenderlin/mfiles/general','/users/ellynenderlin/mfiles/general/cmocean');

%specify plot params
marker = ['d','d','d','d','d','d','d','s','s','s','s','s','s','s','s']; %set-up the different marker styles for E and W
plot_names = [{'i)'},{'j)'},{'k)'},{'l)'},{'m)'},{'n)'},{'o)'},{'h)'},{'g)'},{'f)'},{'e)'},{'d)'},{'c)'},{'b)'},{'a)'}]; %plot letters
plot_loc = [2,4,6,8,10,12,14,15,13,11,9,7,5,3,1];

%load the RAMP image to plot as background for a map
cd /Users/ellynenderlin/Research/miscellaneous/RAMP
[A,S] = geotiffread('Antarctic_RAMP_image_v2_1km.tif');
IM.x = S.XWorldLimits(1)+0.5*S.CellExtentInWorldX:S.CellExtentInWorldX:S.XWorldLimits(2)-0.5*S.CellExtentInWorldX;
IM.y = S.YWorldLimits(2)-0.5*S.CellExtentInWorldY:-S.CellExtentInWorldY:S.YWorldLimits(1)+0.5*S.CellExtentInWorldY;
IM.z=single(A);
clear A S;

%% compile CTD & APB data (only run once to create Antarctic-ocean-data.mat)

%navigate to the CTD and APB data
cd /users/ellynenderlin/Research/NSF_Antarctic-Icebergs/CTD_Antarctica/

%locate the data files
CTD_files = dir('*CTD.mat'); APB_files = dir('*APB.mat'); 

%set up days of year for leap and non-leap years for date conversions
modays = [31 28 31 30 31 30 31 31 30 31 30 31]; cumdays = [0 cumsum(modays(1:end-1))];
leap_modays = [31 29 31 30 31 30 31 31 30 31 30 31]; leap_cumdays = [0 cumsum(leap_modays(1:end-1))];

%load the CTD data
overviewfig = figure; set(overviewfig,'position',[50 50 1200 1200]);
cmap = colormap(jet(length(CTD_files)+length(APB_files)));
sub1 = subplot(1,2,1); sub2 = subplot(1,2,2);
set(sub2,'position',[0.7 0.11 0.25 0.85]); set(sub1,'position',[0.11 0.11 0.55 0.85]); 
subplot(sub1); imagesc(IM.x,IM.y,IM.z); colormap gray; hold on; axis xy equal
colormap(gray(10001));
for i = 1:length(CTD_files)
    load_file = ['load ',CTD_files(i).name]; eval(load_file); %info_sub describes variables
    
    %extract region name
    refs = strfind(CTD_files(i).name,'_');
    if length(refs) > 1
        region_name(i) = {CTD_files(i).name(refs(1)+1:refs(2)-1)};
    else
        region_name(i) = {CTD_files(i).name(1:refs(1)-1)};
    end
    CTD(i).name = string(region_name(i));
    
    if ~strcmp(CTD_files(i).name,'WesternPeninsula_CTD.mat')
        CTD(i).lat = latitude; %latitude (degrees N)
        CTD(i).lon = longitude; %longitude (degrees E)
        [CTD(i).x,CTD(i).y] = wgs2ps(CTD(i).lon,CTD(i).lat,'StandardParallel',-71,'StandardMeridian',0);
        CTD(i).depth = depth; %depth (m)
        CTD(i).time = date_datenum; %matlab dates
        [YYYY,MM,DD,~,~,~] = datevec(CTD(i).time); decidate = NaN(length(YYYY),1); 
        decidate(mod(YYYY,4)~=0) = YYYY(mod(YYYY,4)~=0) + ((cumdays(MM(mod(YYYY,4)~=0))'+DD(mod(YYYY,4)~=0))./sum(modays));
        decidate(mod(YYYY,4)==0) = YYYY(mod(YYYY,4)==0) + ((leap_cumdays(MM(mod(YYYY,4)==0))'+DD(mod(YYYY,4)==0))./sum(leap_modays));
        CTD(i).date = decidate; %decimal date
        clear YYYY MM DD hh mm ss decidate;
        CTD(i).P = []; %pressure (dbar)
        CTD(i).T = temperature; %in situ or conservative temp? (C)
        CTD(i).sal = salinity; %practical or absolute salinity?
    else %W Peninsula is a combination of different datasets (including CTD and APB)
        CTD(i).lat = lat_sub; %latitude (degrees N)
        CTD(i).lon = lon_sub+360; %longitude (degrees E)
        [CTD(i).x,CTD(i).y] = wgs2ps(CTD(i).lon,CTD(i).lat,'StandardParallel',-71,'StandardMeridian',0);
        CTD(i).depth = repmat(z_sub,1,length(time_sub)); %height (m)
        CTD(i).time = time_sub; %matlab dates
        [YYYY,MM,DD,~,~,~] = datevec(CTD(i).time); decidate = NaN(length(YYYY),1); 
        decidate(mod(YYYY,4)~=0) = YYYY(mod(YYYY,4)~=0) + ((cumdays(MM(mod(YYYY,4)~=0))+DD(mod(YYYY,4)~=0))./sum(modays));
        decidate(mod(YYYY,4)==0) = YYYY(mod(YYYY,4)==0) + ((leap_cumdays(MM(mod(YYYY,4)==0))+DD(mod(YYYY,4)==0))./sum(leap_modays));
        CTD(i).date = decidate; %decimal date
        clear YYYY MM DD hh mm ss decidate;
        CTD(i).P = p_sub; %pressure (dbar)
        CTD(i).T = temp_sub; %in situ or conservative temp? (C)
        CTD(i).sal = salt_sub; %practical or absolute salinity?
    end
    subplot(sub1);
    plot(CTD(i).x,CTD(i).y,'x','color',cmap(i,:)); hold on; drawnow;
    subplot(sub2);
    plot(CTD(i).T,CTD(i).depth,'x','color',cmap(i,:)); hold on; drawnow;
    pl(i) = plot(CTD(i).T(1),CTD(i).depth(1),'x','color',cmap(i,:)); hold on; drawnow;
    
    clearvars -except CTD* APB* cmap sub* pl region_name *days*;
end

%load the APB data
for i = 1:length(APB_files)
    load_file = ['load ',APB_files(i).name]; eval(load_file); %info_sub describes variables
    
    %extract region name
    refs = strfind(APB_files(i).name,'_');
    if length(refs) > 1
        region_name(i+length(CTD_files)) = {APB_files(i).name(refs(1)+1:refs(2)-1)};
    else
        region_name(i+length(CTD_files)) = {APB_files(i).name(1:refs(1)-1)};
    end
    APB(i).name = string(region_name(i+length(CTD_files)));
    
    APB(i).lat = latitude; %latitude (degrees N)
    APB(i).lon = longitude; %longitude (degrees E)
    [APB(i).x,APB(i).y] = wgs2ps(APB(i).lon,APB(i).lat,'StandardParallel',-71,'StandardMeridian',0);
    APB(i).depth = depth; %depth (m)
    APB(i).time = date_datenum; %matlab dates
    [YYYY,MM,DD,~,~,~] = datevec(APB(i).time); decidate = NaN(length(YYYY),1);
    decidate(mod(YYYY,4)~=0) = YYYY(mod(YYYY,4)~=0) + ((cumdays(MM(mod(YYYY,4)~=0))'+DD(mod(YYYY,4)~=0))./sum(modays));
    decidate(mod(YYYY,4)==0) = YYYY(mod(YYYY,4)==0) + ((leap_cumdays(MM(mod(YYYY,4)==0))'+DD(mod(YYYY,4)==0))./sum(leap_modays));
    APB(i).date = decidate; %decimal date
    clear YYYY MM DD hh mm ss decidate;
    APB(i).P = []; %pressure (dbar)
    APB(i).T = temperature; %in situ or conservative temp? (C)
    for j = 1:size(APB(i).T,2)
       if max(APB(i).T(:,j)) > 5;  APB(i).T(:,j) = NaN; end %remove strangely high temps when I assume the seals are beached
    end
    APB(i).sal = salinity; %practical or absolute salinity?
    subplot(sub1);
    plot(APB(i).x,APB(i).y,'x','color',cmap(i+length(CTD_files),:)); hold on; drawnow;
    subplot(sub2);
    plot(APB(i).T,APB(i).depth,'x','color',cmap(i+length(CTD_files),:)); hold on; drawnow;
    pl(i+length(CTD_files)) = plot(APB(i).T(1),APB(i).depth(1),'x','color',cmap(i+length(CTD_files),:)); hold on; drawnow;
    
    clearvars -except CTD* APB* cmap sub* pl region_name *days*;
end
subplot(sub2);
leg = legend(pl,region_name);
subplot(sub1);
set(gca,'xlim',[-28e5 28e5],'xtick',[-32e5:8e5:32e5],'xticklabel',[-3200:800:3200],...
    'ylim',[-24e5 24e5],'ytick',[-24e5:8e5:24e5],'yticklabel',[-2400:800:2400]); grid off;

% %plot time series of temperature profiles for each dataset
% for i = 1:length(CTD)
%     %identify unique years
%     yrs = unique(floor(CTD(i).date));
%     
%     %set up the figure
%     figure; yr_cmap = colormap(jet(length(yrs)));
%     for j = 1:length(CTD(i).date)
%        plot(CTD(i).T(:,j),CTD(i).depth(:,j),'-','color',yr_cmap(find(yrs==floor(CTD(i).date(j))),:)); hold on;
%     end
%     drawnow;
%     xlabel('Temperature (C)'); ylabel('Depth (m)'); title(region_name(i));
%     clear yrs yr_cmap;
% end
% for i = 1:length(APB)
%     %identify unique years
%     yrs = unique(floor(APB(i).date));
%     
%     %set up the figure
%     figure; yr_cmap = colormap(jet(length(yrs)));
%     for j = 1:length(APB(i).date)
%        plot(APB(i).T(:,j),APB(i).depth(:,j),'-','color',yr_cmap(find(yrs==floor(APB(i).date(j))),:)); hold on;
%     end
%     drawnow;
%     xlabel('Temperature (C)'); ylabel('Depth (m)'); title(region_name(i+length(CTD)));
%     clear yrs yr_cmap;
% end

%save the data
save('Antarctic-ocean-data.mat','CTD','APB','-v7.3');


%% organize ocean data & pair with remotely-sensed iceberg melt data (run once to create Antarctic-icebergmelt-comparison.mat)
% If you rerun this section, you will overwrite
% Antarctic-icebergmelt-comparison.mat... rerun if you want to change the
% size of the "buffer" search window for ocean data

%specify the buffer region to search for ocean data around the icebergs
buffer = 100000; %m

%load the compiled ocean data
cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/CTD_Antarctica; 
load Antarctic-ocean-data.mat;

%load RACMO air temps
cd /Users/ellynenderlin/Research/miscellaneous/RACMO2.3_Antarctica
AP_lat = ncread('RACMO2.3p2_XPEN055_T2m_daily_2011_2016.nc','lat');
AP_lon = ncread('RACMO2.3p2_XPEN055_T2m_daily_2011_2016.nc','lon');
AP_airtemp = ncread('RACMO2.3p2_XPEN055_T2m_daily_2011_2016.nc','t2m'); AP_airtemp(AP_airtemp==-9999)=NaN;
AIS_lat = ncread('RACMO2.3p2_ANT27_T2m_daily_2011_2016.nc','lat');
AIS_lon = ncread('RACMO2.3p2_ANT27_T2m_daily_2011_2016.nc','lon');
AIS_airtemp = ncread('RACMO2.3p2_ANT27_T2m_daily_2011_2016.nc','t2m'); AIS_airtemp(AIS_airtemp==-9999)=NaN;
RACMO_time = ncread('RACMO2.3p2_XPEN055_T2m_daily_2011_2016.nc','time');
RACMO_days = RACMO_time-RACMO_time(1); %days since 20110101
for i = 1:size(AP_lat,1); for j = 1:size(AP_lat,2); [AP_x(i,j),AP_y(i,j)] = wgs2ps(AP_lon(i,j),AP_lat(i,j),'StandardParallel',-71,'StandardMeridian',0); end; end
for i = 1:size(AIS_lat,1); for j = 1:size(AIS_lat,2); [AIS_x(i,j),AIS_y(i,j)] = wgs2ps(AIS_lon(i,j),AIS_lat(i,j),'StandardParallel',-71,'StandardMeridian',0); end; end


%go through the remotely-sensed iceberg melt data
cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
region = [{'Edgeworth'},{'Crane'},{'Ronne'},{'Filchner'},{'Amery'},{'Totten'},{'Mertz'},{'Thwaites'},{'Eltanin'},{'Seller'},{'Heim'},{'Widdowson'},{'Cadman'},{'Blanchard'},{'Leonardo'}];
leg_names = [{'Edgeworth'},{'Crane'},{'Ronne'},{'Filchner'},{'Amery'},{'Totten'},{'Mertz'},{'Thwaites'},{'Ferrigno'},{'Seller'},{'Heim'},{'Widdowson'},{'Cadman'},{'Blanchard'},{'Leonardo'}];
rho_sw = 1026; %sea water density in kg m^-3

%set up days of year for leap and non-leap years for date conversions
modays = [31 28 31 30 31 30 31 31 30 31 30 31]; cumdays = [0 cumsum(modays(1:end-1))];
leap_modays = [31 29 31 30 31 30 31 31 30 31 30 31]; leap_cumdays = [0 cumsum(leap_modays(1:end-1))];

%loop through folders and extract data
files = dir;
for i = 1:length(region) %loop through the regions
    %find the folder containing the data for the specified region
    for j = 1:length(files)
        if ~isempty(strfind(files(j).name,string(region(i)))) && isdir(files(j).name)
            regionref = j;
        end
    end
    
    % extract the data for the region
    cd_to_region = ['cd ',files(regionref).name]; eval(cd_to_region);
    melt(i).name = region(i); melt(i).dispname = leg_names(i);
    meltinfo = dir('*iceberg_meltinfo.txt');
    date_o = []; xcoord_o = []; ycoord_o = []; 
    date_f = []; xcoord_f = []; ycoord_f = [];
    rhoi_o = []; rhoi_f = [];
    flux = []; meltrate = []; meltrate_sigma = []; 
    keeld = []; keeld_sigma = []; 
    surf_area = []; surf_area_sigma = []; 
    sub_area = []; sub_area_sigma = []; 
    for k = 1:length(meltinfo)
        load_data = ['M=dlmread(''',meltinfo(k).name,''');']; eval(load_data);
        
        %pull variables
        xo = M(:,2); yo = M(:,3); zo = M(:,4); rhoo = M(:,5); %initial locations, median elev, density
        xf = M(:,7); yf = M(:,8); zf = M(:,9); rhof = M(:,10); %same as above but final
        dVdt = M(:,16); dVdt_uncert = M(:,17); %m^3/d

        %recalculate draft and Asub
        draft = (nanmean([rhoo rhof],2)./(repmat(rho_sw,length(nanmean([rhoo rhof],2)),1)-nanmean([rhoo rhof],2))).*nanmean([zo zf],2); %draft = M(:,18); 
        draft_uncert = M(:,19);
        Asurf = M(:,20); Asurf_uncert = M(:,21);
        lat_area = M(:,22) - Asurf; perim = lat_area./draft; clear lat_area; lat_area = perim.*draft; Asub = lat_area + Asurf; clear lat_area perim; %Asub = M(:,22); 
        Asub_uncert = M(:,23);
        rhoi_o = [rhoi_o; rhoo]; rhoi_f = [rhoi_f; rhof];
        surf_area = [surf_area; Asurf]; surf_area_sigma = [surf_area_sigma; Asurf_uncert]; 
        sub_area = [sub_area; Asub]; sub_area_sigma = [sub_area_sigma; Asub_uncert]; 
        meltrate = [meltrate; (dVdt./Asub)]; meltrate_sigma = [meltrate_sigma; abs(dVdt./Asub).*sqrt((dVdt_uncert./dVdt).^2 + (Asub_uncert./Asub).^2)]; 
        keeld = [keeld; draft]; keeld_sigma = [keeld_sigma; draft_uncert];
        
        %converting to decimal dates
        if mod(str2num(meltinfo(k).name(end-49:end-46)),4) ~=0
            decidate = str2num(meltinfo(k).name(end-49:end-46)) + ((cumdays(str2num(meltinfo(k).name(end-45:end-44)))+str2num(meltinfo(k).name(end-43:end-42)))./sum(modays));
        else
            decidate = str2num(meltinfo(k).name(end-49:end-46)) + ((leap_cumdays(str2num(meltinfo(k).name(end-45:end-44)))+str2num(meltinfo(k).name(end-43:end-42)))./sum(leap_modays));
        end
        date_o = [date_o; repmat(decidate,size(xo))]; xcoord_o = [xcoord_o; xo]; ycoord_o = [ycoord_o; yo]; clear decidate;
        if mod(str2num(meltinfo(k).name(end-34:end-31)),4) ~= 0
            decidate = str2num(meltinfo(k).name(end-34:end-31)) + ((cumdays(str2num(meltinfo(k).name(end-30:end-29)))+str2num(meltinfo(k).name(end-28:end-27)))./sum(modays));
        else
            decidate = str2num(meltinfo(k).name(end-34:end-31)) + ((leap_cumdays(str2num(meltinfo(k).name(end-30:end-29)))+str2num(meltinfo(k).name(end-28:end-27)))./sum(leap_modays));
        end
        date_f = [date_f; repmat(decidate,size(xf))]; xcoord_f = [xcoord_f; xf]; ycoord_f = [ycoord_f; yf]; clear decidate;
        
        clear xo yo zo rhoo xf yf zf rhof dVdt* draft* Asurf* Asub* M;
    end
    melt(i).to = date_o; melt(i).tf = date_f;
    melt(i).x = nanmean([xcoord_o xcoord_f],2); melt(i).y = nanmean([ycoord_o ycoord_f],2); 
    melt(i).rho = nanmean([rhoi_o rhoi_f],2); 
    melt(i).d = keeld; melt(i).d_uncert = keeld_sigma; 
    melt(i).m = meltrate; melt(i).m_uncert = meltrate_sigma; 
    melt(i).Asurf = surf_area; melt(i).Asurf_uncert = surf_area_sigma; 
    melt(i).Asub = sub_area; melt(i).Asub_uncert = sub_area_sigma; 
    avgx(i) = nanmean(melt(i).x); avgy(i) = nanmean(melt(i).y); 
    clear date_* *coord_* keeld meltrate *_uncert;
    cd .. %back out of the region directory
    
    %extract RACMO-estimated air temperatures from the nearest grid cell &
    %average over the full record to estimate iceberg temperature
    if i <= 2 || i >= 10
        lat_diff = abs(repmat(nanmean(melt(i).y),size(AP_y)) - AP_y);
        lon_diff = abs(repmat(nanmean(melt(i).x),size(AP_x)) - AP_x);
        diff_map = sqrt(lat_diff.^2+lon_diff.^2); diff_map(isnan(squeeze(nanmean(AP_airtemp(:,:,1,270:450),4)))) = NaN; %solve for the distance vector using the x&y distances
        RACMO_ref = find(diff_map==min(min(diff_map))); %find the minimum distance (reference for your grid cell is output)
        [RACMOy RACMOx] = ind2sub(size(squeeze(nanmean(AP_airtemp(:,:,1,270:450),4))),RACMO_ref); %convert cell reference to an x- and y-cell index
        melt(i).bergT = squeeze(nanmean(AP_airtemp(RACMOx,RACMOy,1,:),4))-273.15;
    else
        lat_diff = abs(repmat(nanmean(melt(i).y),size(AIS_y)) - AIS_y);
        lon_diff = abs(repmat(nanmean(melt(i).x),size(AIS_x)) - AIS_x);
        diff_map = sqrt(lat_diff.^2+lon_diff.^2); diff_map(isnan(squeeze(nanmean(AIS_airtemp(:,:,1,270:450),4)))) = NaN; %solve for the distance vector using the x&y distances
        RACMO_ref = find(diff_map==min(min(diff_map))); %find the minimum distance (reference for your grid cell is output)
        [RACMOy RACMOx] = ind2sub(size(squeeze(nanmean(AIS_airtemp(:,:,1,270:450),4))),RACMO_ref); %convert cell reference to an x- and y-cell index
        melt(i).bergT = squeeze(nanmean(AIS_airtemp(RACMOx,RACMOy,1,:),4))-273.15;
    end
    clear *diff* RACMO*;
    
    %crop the CTD and APB data to within the specified buffer distance of the icebergs
    xlimits = [min(melt(i).x)-buffer max(melt(i).x)+buffer]; ylimits = [min(melt(i).y)-buffer max(melt(i).y)+buffer];
    %CTD
    for j = 1:length(CTD)
        %find data
        oceanrefs = find(CTD(j).x>=min(xlimits) & CTD(j).x<=max(xlimits) & CTD(j).y>=min(ylimits) & CTD(j).y<=max(ylimits));
        if ~isempty(oceanrefs)
            melt(i).oceant = CTD(j).date(oceanrefs);
            melt(i).oceanx = CTD(j).x(oceanrefs); melt(i).oceany = CTD(j).y(oceanrefs);
            melt(i).oceand = CTD(j).depth(:,oceanrefs); melt(i).oceanT = CTD(j).T(:,oceanrefs); melt(i).oceanS = CTD(j).sal(:,oceanrefs);
            
            %if along peninsula, filter across the spine
            if avgx(i) < -1.8e6
                if avgx(i)>-2.45e6
                    melt(i).oceant(melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceand(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanT(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanS(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceany(melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanx(melt(i).oceanx<-2.45e6) = [];
                else
                    melt(i).oceant(melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceand(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanT(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanS(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceany(melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanx(melt(i).oceanx>-2.45e6) = [];
                end
            end
            
        end
        if ~isempty(oceanrefs)
            disp(['Number of ocean observations for ',char(region(i)),' = ',num2str(length(oceanrefs))]);
        end
        clear oceanrefs;
    end
    %APB
    for j = 1:length(APB)
        %find data
        oceanrefs = find(APB(j).x>=min(xlimits) & APB(j).x<=max(xlimits) & APB(j).y>=min(ylimits) & APB(j).y<=max(ylimits));
        if ~isempty(oceanrefs)
            melt(i).oceant = APB(j).date(oceanrefs);
            melt(i).oceanx = APB(j).x(oceanrefs); melt(i).oceany = APB(j).y(oceanrefs);
            melt(i).oceand = APB(j).depth(:,oceanrefs); melt(i).oceanT = APB(j).T(:,oceanrefs); melt(i).oceanS = APB(j).sal(:,oceanrefs);
            
            %if along peninsula, filter across the spine
            if avgx(i) < -1.8e6
                if avgx(i)>-2.45e6
                    melt(i).oceant(melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceand(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanT(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanS(:,melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceany(melt(i).oceanx<-2.45e6) = [];
                    melt(i).oceanx(melt(i).oceanx<-2.45e6) = [];
                else
                    melt(i).oceant(melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceand(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanT(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanS(:,melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceany(melt(i).oceanx>-2.45e6) = [];
                    melt(i).oceanx(melt(i).oceanx>-2.45e6) = [];
                end
            end
            
        end
        if ~isempty(oceanrefs)
            disp(['Number of ocean observations for ',char(region(i)),' = ',num2str(length(oceanrefs))]);
        end
        clear oceanrefs;
    end
    clear *limits;
    
end
save('Antarctic-icebergmelt-comparison.mat','melt','-v7.3');
clear CTD APB;
disp('Done compiling iceberg melt estimates, RACMO air temps (for iceberg temps), & ocean data');


%% create plots of ocean temperature data (creates Antarctic-iceberg-oceandata-profiles.eps)
close all; warning off;

cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
load Antarctic-icebergmelt-comparison.mat; 
% melt = rmfield(melt,{'oceand_prof','oceanTavg_prof','oceanTstd_prof','oceanSavg_prof','oceanSstd_prof'}); melt = rmfield(melt,'bergtemp');
cd /Users/ellynenderlin/Research/miscellaneous/RAMP
[A,S] = geotiffread('Antarctic_RAMP_image_v2_1km.tif');
IM.x = S.XWorldLimits(1)+0.5*S.CellExtentInWorldX:S.CellExtentInWorldX:S.XWorldLimits(2)-0.5*S.CellExtentInWorldX;
IM.y = S.YWorldLimits(2)-0.5*S.CellExtentInWorldY:-S.CellExtentInWorldY:S.YWorldLimits(1)+0.5*S.CellExtentInWorldY;
IM.z=single(A);
clear A S;


%set-up a standard depth profile
% Tm_mapplot = figure; set(gcf,'position',[450 50 800 800]);
figure; set(gcf,'position',[50 50 800 1000]);
region_cmap = [171,221,164; 43,131,186; 253,174,97; 215,25,28]./255;
depth_cmap = cmocean('deep',750); Temp_cmap = cmocean('thermal',600);
imagesc(IM.x,IM.y,IM.z); colormap gray; hold on; axis xy equal; colormap(gray(10001));
cmap_ref = [1 1 2 2 2 2 2 3 3 4 4 4 4 4 4];
z = [1:1:800]'; %set up a standard depth scale


%plot 'heat map' temperature profiles for each observation to explore
%temporal changes in ocean temperatures near these glaciers as well as 
%visualize the stratification of the water masses
% for i = 1:length(melt)
%     if ~isempty(melt(i).oceant)
%         disp(melt(i).name);
%         
%         %identify the unique dates for temperature observations
%         [unique_dates,unique_refs] = unique(melt(i).oceant);
%         for j = 1:length(unique_dates)
%             year_refs = find(melt(i).oceant == unique_dates(j));
%             melt(i).oceantavg(j) = unique_dates(j);
%             if length(year_refs) > 1
%                 melt(i).oceanxavg(:,j) = nanmean(melt(i).oceanx(year_refs)); melt(i).oceanyavg(:,j) = nanmean(melt(i).oceany(year_refs));
%                 melt(i).oceandavg_prof(:,j) = z; %nanmean(melt(i).oceand(:,year_refs),2);
%                 for k = 1:length(year_refs)
%                     if sum(~isnan(melt(i).oceand(:,year_refs(k))))>1 && sum(~isnan(melt(i).oceanT(:,year_refs(k))))>1
%                         Tprof(:,k) = interp1(melt(i).oceand(~isnan(melt(i).oceand(:,year_refs(k))) & ~isnan(melt(i).oceanT(:,year_refs(k))),year_refs(k)),melt(i).oceanT(~isnan(melt(i).oceand(:,year_refs(k))) & ~isnan(melt(i).oceanT(:,year_refs(k))),year_refs(k)),z,'linear');
%                         Sprof(:,k) = interp1(melt(i).oceand(~isnan(melt(i).oceand(:,year_refs(k))) & ~isnan(melt(i).oceanT(:,year_refs(k))),year_refs(k)),melt(i).oceanS(~isnan(melt(i).oceand(:,year_refs(k))) & ~isnan(melt(i).oceanT(:,year_refs(k))),year_refs(k)),z,'linear');
%                     else
%                         Tprof(:,k) = NaN(size(melt(i).oceandavg_prof(:,j))); Sprof(:,k) = NaN(size(melt(i).oceandavg_prof(:,j)));
%                     end
%                 end
%                 melt(i).oceanTavg_prof(:,j) = nanmean(Tprof,2); melt(i).oceanTstd_prof(:,j) = nanstd(Tprof,0,2);
%                 melt(i).oceanSavg_prof(:,j) = nanmean(Sprof,2); melt(i).oceanSstd_prof(:,j) = nanstd(Sprof,0,2);
%                 melt(i).oceanTfreeze_prof(:,j) = (((-5.73*10^-2).*melt(i).oceanSavg_prof(:,j)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceandavg_prof(:,j)));
%                 clear Tprof Sprof;
%             else
%                 melt(i).oceanxavg(:,j) = melt(i).oceanx(year_refs); melt(i).oceanyavg(:,j) = melt(i).oceany(year_refs);
%                 melt(i).oceandavg_prof(:,j) = z; %melt(i).oceand(:,year_refs);
%                 if sum(~isnan(melt(i).oceand(:,year_refs)))>1 && sum(~isnan(melt(i).oceanT(:,year_refs)))>1
%                     melt(i).oceanTavg_prof(:,j) = interp1(melt(i).oceand(~isnan(melt(i).oceand(:,year_refs)) & ~isnan(melt(i).oceanT(:,year_refs)),year_refs),melt(i).oceanT(~isnan(melt(i).oceand(:,year_refs)) & ~isnan(melt(i).oceanT(:,year_refs)),year_refs),z,'linear'); 
%                     melt(i).oceanSavg_prof(:,j) = interp1(melt(i).oceand(~isnan(melt(i).oceand(:,year_refs)) & ~isnan(melt(i).oceanT(:,year_refs)),year_refs),melt(i).oceanS(~isnan(melt(i).oceand(:,year_refs)) & ~isnan(melt(i).oceanT(:,year_refs)),year_refs),z,'linear'); 
%                 else
%                     melt(i).oceanTavg_prof(:,j) = NaN(size(melt(i).oceandavg_prof(:,j))); melt(i).oceanSavg_prof(:,j) = NaN(size(melt(i).oceandavg_prof(:,j)));
%                 end
%                 melt(i).oceanTstd_prof(:,j) = NaN(size(melt(i).oceandavg_prof(:,j))); melt(i).oceanSstd_prof(:,j) = NaN(size(melt(i).oceandavg_prof(:,j)));
%                 melt(i).oceanTfreeze_prof(:,j) = (((-5.73*10^-2).*melt(i).oceanSavg_prof(:,j)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceandavg_prof(:,j)));
%             end
%             
%             
% 
%             clear year_refs;
%         end
%         clear unique_*;
%         
%         %add date-averaged profiles to structure
%         cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
%         save('Antarctic-icebergmelt-comparison.mat','melt','-v7.3');
%     end
%     
% end


%plot the temperature profiles
for i = 1:length(melt)
    if ~isempty(melt(i).oceant)
        disp(melt(i).name);
        subpl = subplot(8,2,plot_loc(i));
%         figure;
        
        %plot profiles with colors to distinguish temps
        for j = 1:length(melt(i).oceantavg)
            for k = 6:10:size(melt(i).oceanTavg_prof(:,j),1)-5
                if ~isnan(nanmean(melt(i).oceanTavg_prof(k-5:k+5,j))) %&& ~isnan(melt(i).oceanTfreeze_prof(k,j))
                    plot(melt(i).oceantavg(j),nanmean(melt(i).oceandavg_prof(k-5:k+5,j)),'.','color',Temp_cmap(round((nanmean(melt(i).oceanTavg_prof(k-5:k+5,j))+3)*100),:)); hold on;
                end
            end
            
        end
        
        %plot the iceberg depths for each date
        plot(nanmean([melt(i).to melt(i).tf],2),melt(i).d,'.k'); hold on;
        errorbar(nanmean([melt(i).to melt(i).tf],2),melt(i).d,[],[],abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).to),abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).tf),'.k');
        
        %format plot
        set(gca,'ydir','reverse','xlim',[2012 2021],'ylim',[0 800],'ytick',[0:250:750],'fontsize',16);
        if plot_loc(i) == 15
            xlabel('Year','fontsize',16); ylabel('Depth (m b.s.l.)','fontsize',16);
        end
        text(min(get(gca,'xlim'))+0.025*(max(get(gca,'xlim'))-min(get(gca,'xlim'))),max(get(gca,'ylim'))-0.2*abs(max(get(gca,'ylim'))-min(get(gca,'ylim'))),[char(plot_names(i)),' ',char(melt(i).dispname)],'fontsize',16);
        drawnow;
%         title(melt(i).dispname,'fontsize',16);

    else
        subpl = subplot(8,2,plot_loc(i));
        %plot the iceberg depths for each date
        plot(nanmean([melt(i).to melt(i).tf],2),melt(i).d,'.k'); hold on;
        errorbar(nanmean([melt(i).to melt(i).tf],2),melt(i).d,[],[],abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).to),abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).tf),'.k');
        
        %format plot
        set(gca,'ydir','reverse','xlim',[2012 2021],'ylim',[0 800],'ytick',[0:250:750],'fontsize',16);
        text(min(get(gca,'xlim'))+0.025*(max(get(gca,'xlim'))-min(get(gca,'xlim'))),max(get(gca,'ylim'))-0.2*abs(max(get(gca,'ylim'))-min(get(gca,'ylim'))),[char(plot_names(i)),' ',char(melt(i).dispname)],'fontsize',16);
        drawnow;
        
    end
    
    %format axes
    pos = get(gca,'position'); set(gca,'position',[pos(1) pos(2) 1.05*pos(3) 1.15*pos(4)]);
    if plot_loc(i) == 14
        set(gca,'xlim',[2012 2021],'xtick',[2013:2:2021],'ylim',[0 800],'ytick',[0:250:750],'fontsize',16);
        xlabel('Year','fontsize',20); 
    elseif plot_loc(i) == 15
        set(gca,'xlim',[2012 2021],'xtick',[2013:2:2021],'ylim',[0 800],'ytick',[0:250:750],'fontsize',16);
        xlabel('Year','fontsize',20); ylbl = ylabel('Depth (m b.s.l.)','fontsize',20);
        set(ylbl,'position',[2010.75 -3000 -1]);
    else
        set(gca,'xlim',[2012 2021],'xtick',[2013:2:2021],'xticklabel',[],'ylim',[0 800],'ytick',[0:250:750],'fontsize',16);
    end
    
end
%add a colorbar
annotation('rectangle',[0.57 0.11 0.35 0.06],'facecolor','w','edgecolor','k');
for j = 1:length(Temp_cmap)
    annotation('line',[0.595+j/2000 0.595+j/2000],[0.145 0.165],'color',Temp_cmap(j,:));
end
annotation('textbox',[0.57 0.11 0.05 0.03],'string',['-3',char(176),'C'],'fontsize',16,'edgecolor','none');
annotation('textbox',[0.725 0.11 0.05 0.03],'string',['0',char(176),'C'],'fontsize',16,'edgecolor','none');
annotation('textbox',[0.875 0.11 0.05 0.03],'string',['3',char(176),'C'],'fontsize',16,'edgecolor','none');

%save
cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
saveas(gcf,'Antarctic-iceberg-oceandata-profiles.eps','epsc'); saveas(gcf,'Antarctic-iceberg-oceandata-profiles.png','png');
disp('iceberg and ocean temp depth profiles saved');

% %create a map that shows the average temperature for each profile down to
% %~100 m depth (Xs) and the median iceberg depth for all sites
% figure(Tm_mapplot);
% for i = 1:length(melt)
%     if ~isempty(melt(i).oceant)
%         for j = 1:length(melt(i).oceantavg)
%             hundred_ref = find(melt(i).oceandavg_prof(:,j)<=100,1,'last');
%             median_ref = find(melt(i).oceandavg_prof(:,j)<=nanmedian(melt(i).d),1,'last');
%             if ~isnan(nanmean(melt(i).oceanTavg_prof(1:hundred_ref,j)-melt(i).oceanTfreeze_prof(1:hundred_ref,j)))
%             plot(melt(i).oceanxavg(j),melt(i).oceanyavg(j),'x','color',Temp_cmap(round((nanmean(melt(i).oceanTavg_prof(1:hundred_ref,j)-melt(i).oceanTfreeze_prof(1:hundred_ref,j))+1)*100),:)); hold on;
%             end
%         end
%     end
%     plot(nanmean(melt(i).x),nanmean(melt(i).y),[marker(i),'k'],'markerfacecolor',depth_cmap(round(nanmean(melt(i).d)),:),'markersize',12); hold on;
% end
% %add labels to the location plot
% for i = 1:length(melt)
%     figure(Tm_mapplot); 
%     if strcmp(marker(i),'d')
%         text(nanmean(melt(i).x)+100000,nanmean(melt(i).y),char(plot_names(i)),'fontsize',16);
%     else
%         if strcmp(char(plot_names(i)),'f)')
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)-100000,char(plot_names(i)),'fontsize',16); 
%         elseif strcmp(char(plot_names(i)),'a)')
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)+100000,char(plot_names(i)),'fontsize',16); 
%         else
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y),char(plot_names(i)),'fontsize',16); 
%         end
%     end
% end
% %label
% set(gca,'xlim',[-28e5 28e5],'xtick',[-24e5:8e5:24e5],'xticklabel',[-2400:800:2400],...
%     'ylim',[-24e5 24e5],'ytick',[-24e5:8e5:24e5],'yticklabel',[-2400:800:2400],'fontsize',24); grid off;
% xlabel('Easting (km)','fontsize',24); ylabel('Northing (km)','fontsize',24);
% graticuleps(-50:-5:-90,-180:30:180);
% text(0,6.5e5,'85^oS','fontsize',16); text(0,12.0e5,'80^oS','fontsize',16); text(0,17.5e5,'75^oS','fontsize',16); text(0,23.0e5,'70^oS','fontsize',16);
% text(-16.5e5,25.25e5,'-30^oE','fontsize',16); text(12.5e5,25.25e5,'30^oE','fontsize',16); 
% colormap(gca,gray(100001));
% saveas(gcf,'Antarctic-iceberg-oceandata-map.eps','epsc'); saveas(gcf,'Antarctic-iceberg-oceandata-map.png','png');
% %now zoom in on the peninsula and save again
% set(gca,'xlim',[-28e5 -20e5],'xtick',[-28e5:2e5:-20e5],'xticklabel',[-2800:200:-2000],...
%     'ylim',[7.5e5 17.5e5],'ytick',[8e5:2e5:16e5],'yticklabel',[800:200:1600],'fontsize',24);
% graticuleps(-50:-2:-90,-180:10:180);
% saveas(gcf,'AntarcticPeninsula-iceberg-oceandata-map.eps','epsc'); saveas(gcf,'AntarcticPeninsula-iceberg-oceandata-map.png','png');

%% compare melt rates and ocean temps
close all;

%load the compiled iceberg & ocean data
cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
load Antarctic-icebergmelt-comparison.mat; 
cd /Users/ellynenderlin/Research/miscellaneous/RAMP
[A,S] = geotiffread('Antarctic_RAMP_image_v2_1km.tif');
IM.x = S.XWorldLimits(1)+0.5*S.CellExtentInWorldX:S.CellExtentInWorldX:S.XWorldLimits(2)-0.5*S.CellExtentInWorldX;
IM.y = S.YWorldLimits(2)-0.5*S.CellExtentInWorldY:-S.CellExtentInWorldY:S.YWorldLimits(1)+0.5*S.CellExtentInWorldY;
IM.z=single(A);
clear A S;
% marker = ['d','d','d','d','d','d','d','s','s','s','s','s','s','s','s']; %set-up the different marker styles for E and W
marker = ['s','s','s','s','s','s','s','s','s','s','s','s','s','s','s']; %set-up the different marker styles for E and W
plot_names = [{'i)'},{'j)'},{'k)'},{'l)'},{'m)'},{'n)'},{'o)'},{'h)'},{'g)'},{'f)'},{'e)'},{'d)'},{'c)'},{'b)'},{'a)'}]; %plot letters

%set-up a standard depth profile
% z = [0:10:200 220:20:400 450:50:700 800:100:1000];
Tm_scatterplot = figure; set(gcf,'position',[450 50 800 400]); %subA = subplot(1,2,1); subB = subplot(1,2,2);
region_cmap = [171,221,164; 43,131,186; 253,174,97; 215,25,28]./255;
depth_cmap = cmocean('deep',750); Temp_cmap = cmocean('thermal',600); im_cmap = colormap(gray(10001)); im_cmap(1,:) = [1 1 1];
Tm_mapplot = figure; set(gcf,'position',[450 50 800 800]);
imagesc(IM.x,IM.y,IM.z); hold on; axis xy equal; colormap(gca,im_cmap);
cmap_ref = [1 1 2 2 2 2 2 3 3 4 4 4 4 4 4];
tempref = [];
for i = 1:length(melt)
    if ~isempty(melt(i).oceant)
        
%         %if there are a lot of data, narrow the geographic window
%         if length(unique(melt(i).oceant)) > 200
%             buffer = 50000; 
%             xlimits = [min(melt(i).x)-buffer max(melt(i).x)+buffer]; ylimits = [min(melt(i).y)-buffer max(melt(i).y)+buffer];
%             oceanrefs = find(melt(i).oceanx>=min(xlimits) & melt(i).oceanx<=max(xlimits) & melt(i).oceany>=min(ylimits) & melt(i).oceany<=max(ylimits));
%             if ~isempty(oceanrefs)
%                 melt(i).oceant = melt(i).oceant(oceanrefs); melt(i).oceanx = melt(i).oceanx(oceanrefs); melt(i).oceany = melt(i).oceany(oceanrefs);
%                 melt(i).oceand = melt(i).oceand(:,oceanrefs); melt(i).oceanT = melt(i).oceanT(:,oceanrefs);
%             else
%                 buffer = 75000;
%                 xlimits = [min(melt(i).x)-buffer max(melt(i).x)+buffer]; ylimits = [min(melt(i).y)-buffer max(melt(i).y)+buffer];
%                 oceanrefs = find(melt(i).oceanx>=min(xlimits) & melt(i).oceanx<=max(xlimits) & melt(i).oceany>=min(ylimits) & melt(i).oceany<=max(ylimits));
%                 melt(i).oceant = melt(i).oceant(oceanrefs); melt(i).oceanx = melt(i).oceanx(oceanrefs); melt(i).oceany = melt(i).oceany(oceanrefs);
%                 melt(i).oceand = melt(i).oceand(:,oceanrefs); melt(i).oceanT = melt(i).oceanT(:,oceanrefs);
%             end
%         end
        
%         %filter-out ocean data that are off the continental shelf
%         for j = 1:size(melt(i).oceand,2)
%             if max(melt(i).oceand(~isnan(melt(i).oceanT(:,j)),j)) > 1500
%                 melt(i).oceant(j) = NaN;
%             end
%         end
%         melt(i).oceanx(isnan(melt(i).oceant)) = [];
%         melt(i).oceany(isnan(melt(i).oceant)) = [];
%         melt(i).oceanT(:,isnan(melt(i).oceant)) = [];
%         melt(i).oceand(:,isnan(melt(i).oceant)) = [];
%         melt(i).oceant(isnan(melt(i).oceant)) = [];
        
        %loop through remotely-sensed data and extract ocean temperature
        %information for each iceberg
        for j = 1:length(melt(i).to)
            %identify the time span of remotely-sensed iceberg melt rate estimates
            %(bi-annual=2, annual=1, or seasonal=0)
            if melt(i).tf(j)-melt(i).to(j) >= 2
                timespan = 2;
            elseif melt(i).tf(j)-melt(i).to(j) >= 1
                timespan = 1;
            else
                timespan = 0;
            end
            
            %if seasonal, find ocean data from approximately the same season
            %minrefs are the data from the closest date (there may be multiple profiles) & oceantemps and oceansals are the corresponding profiles
            if timespan == 0
                deciseas = nanmean([melt(i).to(j) melt(i).tf(j)]-floor(melt(i).to(j)),2); if deciseas > 1; deciseas = deciseas - floor(deciseas); end
                
                [mindiff,minref] = min(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas));
                if melt(i).oceant(minref)-floor(melt(i).oceant(minref)) >= melt(i).to(j)-floor(melt(i).to(j)) && melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).to(j)) %if to and tf are in the same year & minref is in between, find all between
                    minrefs = find(melt(i).oceant-floor(melt(i).oceant(minref)) >= melt(i).to(j)-floor(melt(i).to(j)) & melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).to(j)));
                elseif melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).to(j)-floor(melt(i).to(j)) && melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).tf(j)) %if tf is in a different year than to & minref is in between, find all between
                    minrefs = find(melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).to(j)-floor(melt(i).to(j)) & melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).tf(j)));
                else 
                    if mindiff < 0.5 %if there are no data that fall within the seasonal range of to and tf, find data within +/-3 months of the central day of year
                        minrefs = find(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas) <= 4/12);
                    else
                        minrefs = find(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas) <= mindiff + 1/12);
%                         if ~isempty(find(melt(i).oceant-floor(melt(i).oceant) >= nanmean(melt(i).to(j)-floor(melt(i).to(j)),2)-0.25))
%                             minrefs = find(melt(i).oceant-floor(melt(i).oceant) >= nanmean(melt(i).to(j)-floor(melt(i).to(j)),2)-0.25);
%                         else
%                             minrefs = find(melt(i).oceant-floor(melt(i).oceant) <= nanmean(melt(i).tf(j)-floor(melt(i).tf(j)),2)+0.25);
%                         end
                    end
                end
                melt(i).oceanm_tdiff(j,:) = [nanmean([melt(i).to(j) melt(i).tf(j)])-min(melt(i).oceant(minrefs)) max(melt(i).oceant(minrefs))-nanmean([melt(i).to(j) melt(i).tf(j)])];
                oceantemps = melt(i).oceanT(:,minrefs); oceansals = melt(i).oceanS(:,minrefs); oceandepths = melt(i).oceand(:,minrefs);
                clear minref deciseas mindiff;
            else
                %if annual or bi-annual, find the closest year of ocean data
                [~,minref] = min(abs(melt(i).oceant-nanmean([melt(i).to(j) melt(i).tf(j)])));
                if melt(i).oceant(minref)-nanmean([melt(i).to(j) melt(i).tf(j)]) > 0
                    minrefs = find(melt(i).oceant>=melt(i).oceant(minref) & melt(i).oceant<=melt(i).oceant(minref)+timespan);
                else
                    minrefs = find(melt(i).oceant<=melt(i).oceant(minref) & melt(i).oceant>=melt(i).oceant(minref)-timespan);
                end
                %calculate the time difference between remotely-sensed and in situ observations
                if min(melt(i).oceant(minrefs)) > melt(i).tf(j)
                    melt(i).oceanm_tdiff(j,:) = [min(melt(i).oceant(minrefs))-nanmean([melt(i).to(j) melt(i).tf(j)]) max(melt(i).oceant(minrefs))-nanmean([melt(i).to(j) melt(i).tf(j)])];
                elseif max(melt(i).oceant(minrefs)) < melt(i).to(j)
                    melt(i).oceanm_tdiff(j,:) = [nanmean([melt(i).to(j) melt(i).tf(j)])-min(melt(i).oceant(minrefs)) nanmean([melt(i).to(j) melt(i).tf(j)])-max(melt(i).oceant(minrefs))];
                else
                    melt(i).oceanm_tdiff(j,:) = [nanmean([melt(i).to(j) melt(i).tf(j)])-min(melt(i).oceant(minrefs)) max(melt(i).oceant(minrefs))-nanmean([melt(i).to(j) melt(i).tf(j)])];
                end
                oceantemps = melt(i).oceanT(:,minrefs); oceansals = melt(i).oceanS(:,minrefs); oceandepths = melt(i).oceand(:,minrefs);
                clear minref;
            end
%             minref = find(melt(i).oceand(:,minrefs)<=melt(i).d(j),1,'last');
            
%             %average to standard depth profile
%             melt(i).oceand_prof = z;
%             melt(i).oceanTavg_prof(j,1) = nanmean(oceantemps(melt(i).oceand(:,minrefs)<((z(1)+z(2))/2))); melt(i).oceanTstd_prof(j,1) = nanstd(oceantemps(melt(i).oceand(:,minrefs)<((z(1)+z(2))/2)));
%             melt(i).oceanSavg_prof(j,1) = nanmean(oceansals(melt(i).oceand(:,minrefs)<((z(1)+z(2))/2))); melt(i).oceanSstd_prof(j,1) = nanstd(oceansals(melt(i).oceand(:,minrefs)<((z(1)+z(2))/2)));
%             for k = 2:length(z)-1
%                 melt(i).oceanTavg_prof(j,k) = nanmean(oceantemps(melt(i).oceand(:,minrefs)>=z(k)-((z(k)-z(k-1))/2) & melt(i).oceand(:,minrefs)<=z(k)+((z(k+1)-z(k))/2)));
%                 melt(i).oceanTstd_prof(j,k) = nanstd(oceantemps(melt(i).oceand(:,minrefs)>=z(k)-((z(k)-z(k-1))/2) & melt(i).oceand(:,minrefs)<=z(k)+((z(k+1)-z(k))/2)));
%                 
%                 melt(i).oceanSavg_prof(j,k) = nanmean(oceansals(melt(i).oceand(:,minrefs)>=z(k)-((z(k)-z(k-1))/2) & melt(i).oceand(:,minrefs)<=z(k)+((z(k+1)-z(k))/2)));
%                 melt(i).oceanSstd_prof(j,k) = nanstd(oceansals(melt(i).oceand(:,minrefs)>=z(k)-((z(k)-z(k-1))/2) & melt(i).oceand(:,minrefs)<=z(k)+((z(k+1)-z(k))/2)));
%             end
%             melt(i).oceanTavg_prof(j,length(z)) = nanmean(oceantemps(melt(i).oceand(:,minrefs)>=z(end)-((z(end)-z(end-1))/2) & melt(i).oceand(:,minrefs)<=z(end)+((z(end)-z(end-1))/2)));
%             melt(i).oceanTstd_prof(j,length(z)) = nanstd(oceantemps(melt(i).oceand(:,minrefs)>=z(end)-((z(end)-z(end-1))/2) & melt(i).oceand(:,minrefs)<=z(end)+((z(end)-z(end-1))/2)));
%             melt(i).oceanSavg_prof(j,length(z)) = nanmean(oceansals(melt(i).oceand(:,minrefs)>=z(end)-((z(end)-z(end-1))/2) & melt(i).oceand(:,minrefs)<=z(end)+((z(end)-z(end-1))/2)));
%             melt(i).oceanSstd_prof(j,length(z)) = nanstd(oceansals(melt(i).oceand(:,minrefs)>=z(end)-((z(end)-z(end-1))/2) & melt(i).oceand(:,minrefs)<=z(end)+((z(end)-z(end-1))/2)));
            
            %extract temperature metrics over the iceberg draft
            for k = 1:length(minrefs)
                if ~isempty(find(melt(i).oceand(:,minrefs(k))<=melt(i).d(j),1,'last'))
                    bottomrefs(k) = find(melt(i).oceand(:,minrefs(k))<=melt(i).d(j),1,'last');
                    bottomT(k) = melt(i).oceanT(bottomrefs(k),minrefs(k)); bottomS(k) = melt(i).oceanS(bottomrefs(k),minrefs(k));
                else
                    bottomrefs(k) = NaN; bottomT(k) = NaN; bottomS(k) = NaN;
                end
            end
            %extract the average, standard deviation, max, & bottom temp
            %and salinity from the profiles for the closest data
            melt(i).oceanTavg(j,1) = nanmean(oceantemps(melt(i).oceand(:,minrefs)<=melt(i).d(j))); melt(i).oceanTstd(j,1) = nanstd(oceantemps(melt(i).oceand(:,minrefs)<=melt(i).d(j)));
            melt(i).oceanTmax(j,1) = max(oceantemps(melt(i).oceand(:,minrefs)<=melt(i).d(j))); melt(i).oceanTbottom(j,1) = nanmean(bottomT);
            melt(i).oceanSavg(j,1) = nanmean(oceansals(melt(i).oceand(:,minrefs)<=melt(i).d(j))); melt(i).oceanSstd(j,1) = nanstd(oceansals(melt(i).oceand(:,minrefs)<=melt(i).d(j)));
            melt(i).oceanSmax(j,1) = max(oceansals(melt(i).oceand(:,minrefs)<=melt(i).d(j))); melt(i).oceanSbottom(j,1) = nanmean(bottomS);
            clear bottom*;
            
            %calculate the temperature with respect to the freezing
            %temperature of sea water (Tfp = -5.73*10^-2 (C/psu)*salinity + 8.32*10^-2 (C) - 7.61*10^-4 (C/dbar)*pressure)
            %pressure is approximately equivalent to depth
            melt(i).oceanTfp(j,1) = nanmean(((-5.73*10^-2).*oceansals(melt(i).oceand(:,minrefs)<=melt(i).d(j))) + (8.32*10^-2) - ((7.61*10^-4).*oceandepths(melt(i).oceand(:,minrefs)<=melt(i).d(j))));
            
            %plot temperature above freezing vs melt rate
            figure(Tm_scatterplot); 
            plot(melt(i).oceanTavg(j)-melt(i).oceanTfp(j,1),365*melt(i).m(j),[marker(i),'k'],'markerfacecolor',depth_cmap(round(melt(i).d(j)),:),'markersize',12); hold on; 
             
            
%             %plot average near-surface temperature above freezing
%             figure(Tm_mapplot); 
%             for k = 1:length(minrefs)
%                 temp(k) = nanmean(oceantemps(melt(i).oceand(:,minrefs(k))<200,k));
%                 freeze_temp(k) = nanmean(((-5.73*10^-2).*oceansals(melt(i).oceand(:,minrefs(k))<200,k)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceand(melt(i).oceand(:,minrefs(k))<200,minrefs(k))));
%                 if ~isnan(temp(k)) && ~isnan(freeze_temp(k))
%                     tempref = [tempref; round((temp(k)-freeze_temp(k)+0.5)*200)];
%                     plot(melt(i).oceanx(minrefs(k)),melt(i).oceany(minrefs(k)),'x','color',Temp_cmap(round((temp(k)-freeze_temp(k)+0.5)*200),:),'markersize',12); hold on;
%                 end
%             end
            clear minrefs oceantemps timespan;
        end
        drawnow;
        
        %plot the temp vs meltrate
        figure; plot(melt(i).oceanTavg-melt(i).oceanTfp,100*melt(i).m,'x','color',region_cmap(cmap_ref(i),:),'markersize',12); hold on; 
        set(gca,'fontsize',16); grid on; 
        xlabel(['Thermal forcing (',char(176),'C above freezing)'],'fontsize',16); ylabel('Melt rate (cm/d)','fontsize',16); 
        title(melt(i).dispname); drawnow;
        [f,gof] = fit(melt(i).oceanTavg-melt(i).oceanTfp,melt(i).m,'poly1'); disp(['Trendline r^2 = ',num2str(gof.rsquare)]);
        if gof.rsquare > 0.5
            saveas(gcf,[char(melt(i).name),'-iceberg-oceandata-scatterplot.eps'],'epsc'); saveas(gcf,[char(melt(i).name),'-iceberg-oceandata-scatterplot.png'],'png');
        end
    end
    
    %add glacier locations to map
    figure(Tm_mapplot); 
    for k = 1:size(melt(i).oceanTavg_prof,2)
        temp(k) = nanmean(melt(i).oceanTavg_prof(1:find(melt(i).oceandavg_prof(:,k)<=nanmean(melt(i).d),1,'last'),k));
        freeze_temp(k) = ((-5.73*10^-2).*nanmean(melt(i).oceanSavg_prof(1:find(melt(i).oceandavg_prof(:,k)<=nanmean(melt(i).d),1,'last'),k))) + (8.32*10^-2) - ((7.61*10^-4).*nanmean(melt(i).oceandavg_prof(1:find(melt(i).oceandavg_prof(:,k)<=nanmean(melt(i).d),1,'last'),k)));
        if ~isnan(temp(k)) && ~isnan(freeze_temp(k))
            tempref = [tempref; round((temp(k)-freeze_temp(k)+0.5)*150)];
            plot(melt(i).oceanxavg(k),melt(i).oceanyavg(k),'x','color',Temp_cmap(round((temp(k)-freeze_temp(k)+0.5)*150),:),'markersize',8); hold on;
        end
    end
    plot(nanmean(melt(i).x),nanmean(melt(i).y),[marker(i),'k'],'markerfacecolor',depth_cmap(round(nanmean(melt(i).d)),:),'markersize',12); hold on;
    
end
%add labels to the location plot
for i = 1:length(melt)
    figure(Tm_mapplot); 
    if strcmp(marker(i),'d')
        text(nanmean(melt(i).x)+100000,nanmean(melt(i).y),char(plot_names(i)),'fontsize',16);
    else
        if strcmp(char(plot_names(i)),'f)')
            text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)-100000,char(plot_names(i)),'fontsize',16); 
        elseif strcmp(char(plot_names(i)),'a)')
            text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)+100000,char(plot_names(i)),'fontsize',16); 
        elseif strcmp(char(plot_names(i)),'b)') || strcmp(char(plot_names(i)),'c)') || strcmp(char(plot_names(i)),'e)')
            text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)-100000,char(plot_names(i)),'fontsize',16); 
        else
            text(nanmean(melt(i).x)+100000,nanmean(melt(i).y),char(plot_names(i)),'fontsize',16);
        end
    end
end
figure(Tm_scatterplot);  
set(gca,'fontsize',20); grid on;
for k = 1:length(depth_cmap)
    plot([0.1 0.25],[47.5-(k/100) 47.5-(k/100)],'-','color',depth_cmap(k,:)); hold on;
end
text(0.275,47,'0 m','fontsize',16); text(0.275,45,'200 m','fontsize',16); text(0.275,39.5,'750 m','fontsize',16);
% scatterleg = legend(scp,'W. Peninsula','WAIS','EAIS','E. Peninsula'); set(scatterleg,'fontsize',16);
xlabel(['Thermal forcing (',char(176),'C above freezing)'],'fontsize',20); ylabel('Melt rate (m/yr)','fontsize',20);
cd /Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt
saveas(gcf,'Antarctic-iceberg-meltrate-temp-depth-scatterplots.eps','epsc'); saveas(gcf,'Antarctic-iceberg-meltrate-temp-depth-scatterplots.png','png');
figure(Tm_mapplot);
set(gca,'xlim',[-28e5 28e5],'xtick',[-32e5:8e5:32e5],'xticklabel',[-3200:800:3200],...
    'ylim',[-24e5 24e5],'ytick',[-24e5:8e5:24e5],'yticklabel',[-2400:800:2400],'fontsize',20); grid off;
%add color legends
for k = 1:length(depth_cmap)
    plot([-26e5 -24e5],[-16e5-k*1000 -16e5-k*1000],'-','color',depth_cmap(k,:)); hold on;
end
text(-23.25e5,-15.75e5,'0 m','fontsize',16); text(-23.25e5,-17.75e5,'200 m','fontsize',16); text(-23.25e5,-23.25e5,'750 m','fontsize',16);
for k = 1:length(Temp_cmap)
    plot([-17e5 -15e5],[-17.5e5-k*1000 -17.5e5-k*1000],'-','color',Temp_cmap(k,:)); hold on;
end
text(-14.25e5,-18.25e5,['-2',char(176),'C'],'fontsize',16); text(-14.25e5,-20.25e5,['0',char(176),'C'],'fontsize',16); text(-14.25e5,-22.25e5,['2',char(176),'C'],'fontsize',16);
xlabel('Easting (km)','fontsize',20); ylabel('Northing (km)','fontsize',20);
graticuleps(-50:-5:-90,-180:30:180);
text(0,6.5e5,'85^oS','fontsize',16); text(0,12.0e5,'80^oS','fontsize',16); text(0,17.5e5,'75^oS','fontsize',16); text(0,23.0e5,'70^oS','fontsize',16);
text(-16.5e5,25.25e5,'-30^oE','fontsize',16); text(12.5e5,25.25e5,'30^oE','fontsize',16); 
colormap(gca,im_cmap);
xlims = get(gca,'xlim'); ylims = get(gca,'ylim');
saveas(gcf,'Antarctic-iceberg-oceandata-map.eps','epsc'); saveas(gcf,'Antarctic-iceberg-oceandata-map.png','png');

%resave the data structure
% save('Antarctic-icebergmelt-comparison.mat','melt','-v7.3');


% %make maps showing the average temperature in the upper 200m & the maximum
% %temperature
% Temp_mapplot = figure; set(gcf,'position',[450 50 800 800]); Temp_cmap = colormap(hot(100));
% imagesc(IM.x,IM.y,IM.z); colormap gray; hold on; axis xy equal; colormap(gray(10001));
% cmap_ref = [1 1 2 2 2 2 2 3 3 4 4 4 4 4 4];
% for i = 1:length(melt)
%     if ~isempty(melt(i).oceant)
%         if size(melt(i).oceanx,1) > 1
%             for j = 1:size(melt(i).oceanx,1)
%                 temp(j,1) = nanmean(melt(i).oceanT(melt(i).oceand(:,j)<200,j));
%                 freeze_temp(j,1) = nanmean(((-5.73*10^-2).*melt(i).oceanS(melt(i).oceand(:,j)<200,j)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceand(melt(i).oceand(:,j)<200,j)));
%                 if ~isnan(freeze_temp(j,1)) && ~isnan(temp(j,1))
%                     plot(melt(i).oceanx(j),melt(i).oceany(j),'ok','markerfacecolor',Temp_cmap(round((temp(j,1)-freeze_temp(j,1)+0.5)*30),:)); hold on;
%                 end
%             end
%         else
%             for j = 1:size(melt(i).oceanx,2)
%                 temp(j,1) = nanmean(melt(i).oceanT(melt(i).oceand(:,j)<200,j));
%                 freeze_temp(j,1) = nanmean(((-5.73*10^-2).*melt(i).oceanS(melt(i).oceand(:,j)<200,j)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceand(melt(i).oceand(:,j)<200,j)));
%                 if ~isnan(freeze_temp(j,1)) && ~isnan(temp(j,1))
%                     plot(melt(i).oceanx(j),melt(i).oceany(j),'ok','markerfacecolor',Temp_cmap(round((temp(j,1)-freeze_temp(j,1)+0.5)*25),:)); hold on;
%                 end
%             end
%         end
%         drawnow;
%     end
% end

