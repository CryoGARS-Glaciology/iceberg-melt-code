function [DEM1,DEM2] = estimate_iceberg_meltrates(DEM1,DEM2,IM1,IM2,dir_output,dir_code,region_abbrev,region_name,option_no)
% Function to estimate iceberg freshwater fluxes and melt rates
% Ellyn Enderlin and Rainey Aberle, Fall 2021
%
% INPUTS:   DEM1            structure variable containing earlier DEM info
%           DEM2            structure variable containing later DEM info
%           IM1             structure variable containing earlier
%                               orthoimage info
%           IM2             structure variable containing later orthoimage
%                               info
%           dir_output      directory where all output files will be placed
%           dir_code        directory to the Iceberg-melt-rate code folder
%                               (including the name of the folder)
%           region_abbrev   region abbreviation used in image files
%           option_no         select which step to execute (1 or 2):
%                           (1) Estimate elevation change for each iceberg
%                           (2) Update individual icebergs and/or remove 
%                               icebergs with anomalous melt rate estimates
%
% OUTPUTS:  DEM1            structure variable containing earlier DEM info
%                               with any new fields
%           DEM2            structure variable containing later DEM info
%                               with any new fields
% 
% Calls the following external functions: 
%   - extract_Antarctic_iceberg_elev_change.m
%   - convert_Antarctic_iceberg_elev_change_to_meltrates.m


% ----------STEP 1: Calculate Elevation Change----------
disp('Extract iceberg elevation change');
dir_iceberg = [dir_output,'/',DEM1.time,'-',DEM2.time,'/'];
cd(dir_iceberg);
icebergs = dir([dir_iceberg,'iceberg*coords.txt']);
iceberg_dz = dir([dir_iceberg,'iceberg*dz.mat']);

%select the iceberg number for which to start the elevation change estimates
if ~isempty(iceberg_dz)
    disp(['Already calculated elevation change for ',num2str(length(iceberg_dz)),' of ',num2str(length(icebergs)),' icebergs']);
    prompt = 'Do you want/need to calculate elevation changes for more icebergs (y/n)?';
    str = input(prompt,'s');
    if strmatch(str,'y')==1
        %specify the iceberg numbers to loop through
        disp('Specify range of iceberg numbers as "iceberg_refs = X:Y; dbcont" in the command window (w/o quotes) then hit enter to loop');
        disp('   Ex of loop: iceberg_refs = 4:size(icebergs,1); dbcont');
        disp('   Ex of select numbers: iceberg_refs = [5,15,16]; dbcont');
        keyboard
        
        %loop
        for j = iceberg_refs %size(icebergs,1) %default to loop through all icebergs is j = 1:size(icebergs,1)
            iceberg_no = icebergs(j).name(8:9);
            [IB,dz] = extract_Antarctic_iceberg_elev_change(DEM1,DEM2,IM1,IM2,iceberg_no,dir_output,dir_code,region_abbrev);
            clear IB dz;
        end
    else
        disp('Moving on to melt rate estimation...');
    end
else
    for j = 1:size(icebergs,1) %size(icebergs,1) %default to loop through all icebergs is j = 1:size(icebergs,1)
        %for j = berg_refs
        %for j = 1:3 %example: pull elevation change info for icebers 01-03
        %for j = 5:11 %example: pull elevation change info for icebergs 05-11
        %for j = [4 11] %example: re-calculate elevation changes for two icebergs with non sequential numbers (4 and 11 in this case)
        iceberg_no = icebergs(j).name(8:9);
        
        [IB,dz] = extract_Antarctic_iceberg_elev_change(DEM1,DEM2,IM1,IM2,iceberg_no,dir_output,dir_code,region_abbrev);
        clear IB dz;
    end
end
close all;


% ----------STEP 2: Estimate Melt Rates----------
if option_no==1 %calculate melt rates for all icebergs

    % Calculate meltwater fluxes, melt rates, and uncertainties
    disp('Convert elevation change to meltwater fluxes & melt rates');
    cd(dir_iceberg);
    berg_numbers = dir([dir_iceberg,'iceberg*dz.mat']);
    dir_bedrock = [dir_output,'/DEM_offset_data/'];
    
    % calculate iceberg meltrate from elevation change:
    if exist([region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt.mat']) == 2 %does the meltrate file already exist?
        prompt = 'Do you want/need to redo the conversion to melt rates (y/n)?';
        str = input(prompt,'s');
        if strmatch(str,'y')==1
            SL = convert_Antarctic_iceberg_elev_change_to_meltrates(DEM1,DEM2,IM1,IM2,berg_numbers,region_name,region_abbrev,dir_output,dir_code,dir_iceberg,dir_bedrock);
        else
            disp('reloading meltrate data...');
            load([region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt.mat']);
        end
    else
        SL = convert_Antarctic_iceberg_elev_change_to_meltrates(DEM1,DEM2,IM1,IM2,berg_numbers,region_name,region_abbrev,dir_output,dir_code,dir_iceberg,dir_bedrock);
    end
    
    %save as a table in a text file
    clear dt xo yo zo po Vo xf yf zf pf Vf coreg_z* dz* dVdt* draft* Asurf* Asub*;
    for i = 1:length(SL)
        berg_nostring(i,:) = SL(i).name(end-1:end);
        dt(i) = sum(SL(i).days);
        xo(i) = nanmean(SL(i).initial.x); yo(i) = nanmean(SL(i).initial.y); zo(i) = SL(i).initial.z_median; Vo(i) = SL(i).initial.V;
        xf(i) = nanmean(SL(i).final.x); yf(i) = nanmean(SL(i).final.y); zf(i) = SL(i).final.z_median; Vf(i) = SL(i).final.V;
        po(i)=SL(i).initial.density; pf(i) = SL(i).final.density;
        coreg_zo(i) = SL(i).initial.coreg_z; coreg_zf(i) = SL(i).final.coreg_z;
        dz(i) = SL(i).mean.dz; dz_sigma(i) = SL(i).uncert.dz;
        dVdt(i) = SL(i).mean.dVdt; dVdt_uncert(i) = max(SL(i).uncert.dVdt);
        draft(i) = SL(i).mean.draft; draft_uncert(i) = SL(i).change.draft;
        Asurf(i) = SL(i).mean.SA; Asurf_uncert(i) = SL(i).change.SA;
        Asub(i) = SL(i).mean.TA; Asub_uncert(i) = SL(i).change.TA;
    end
    bad_refs = find(draft<0); %remove data with negative thicknesses (unrealistic = error-prone)
    dt(bad_refs) = []; 
    xo(bad_refs) = []; yo(bad_refs) = [];  zo(bad_refs) = []; Vo(bad_refs) = []; po(bad_refs) = []; coreg_zo(bad_refs) = []; 
    xf(bad_refs) = []; yf(bad_refs) = [];  zf(bad_refs) = []; Vf(bad_refs) = []; pf(bad_refs) = []; coreg_zf(bad_refs) = []; 
    dz(bad_refs) = []; dz_sigma(bad_refs) = []; dVdt(bad_refs) = []; dVdt_uncert(bad_refs) = []; 
    draft(bad_refs) = []; draft_uncert(bad_refs) = []; Asurf(bad_refs) = []; Asurf_uncert(bad_refs) = []; Asub(bad_refs) = []; Asub_uncert(bad_refs) = []; 
    clear bad_refs; 
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...         'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...         'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...         'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...         'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...         'SubmergedArea_mean (m^3)','SubmergedArea_range (m^3)'};
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    T=table(dt',xo',yo',zo',po',Vo',xf',yf',zf',pf',Vf',coreg_zo',coreg_zf',dz',dz_sigma',dVdt',dVdt_uncert',draft',draft_uncert',Asurf',Asurf_uncert',Asub',Asub_uncert'); T.Properties.VariableNames = column_names;
    writetable(T,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_meltinfo.csv']);
    
    %plot to figure-out which icebergs need to be re-run
    dVdt = []; Asub = []; rho = []; H = []; m = []; coreg_zo = []; coreg_zf = []; berg_ref =[];
    for i = 1:length(SL)
        if SL(i).mean.dVdt > 0 && ~isempty(SL(i).mean.TA)
            dVdt = [dVdt SL(i).mean.dVdt];
            Asub = [Asub SL(i).mean.TA];
            rho = [rho (SL(i).initial.density+SL(i).final.density)/2];
            H = [H SL(i).mean.H];
            m = [m SL(i).mean.dHdt];
            coreg_zo = [coreg_zo SL(i).initial.coreg_z]; coreg_zf = [coreg_zf SL(i).final.coreg_z];
            berg_ref = [berg_ref; SL(i).name(end-1:end)];
        end
    end
    figure; set(gcf,'position',[100 500 1500 600]);
    subplot(1,3,1);
    plot(Asub,dVdt,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Submerged area (m^2)','fontsize',20); ylabel('Meltwater flux (m^3/d)','fontsize',20);
    for i = 1:length(m)
        text(double(Asub(i))-0.03e5,double(dVdt(i)),berg_ref(i,:))
    end
    grid on;
    subplot(1,3,2);
    plot(H,m,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Average iceberg thickness (m)','fontsize',20); ylabel('Melt rate (m/d)','fontsize',20);
    for i = 1:length(m)
        text(double(H(i))-2,double(m(i)),berg_ref(i,:))
    end
    grid on;
    subplot(1,3,3);
    plot(coreg_zo-coreg_zf,dVdt,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('\Delta sea-level adjustment (m)','fontsize',20); ylabel('Meltwater flux (m^3/d)','fontsize',20);
    for i = 1:length(m)
        text(double(coreg_zo(i)-coreg_zf(i)),double(dVdt(i)),berg_ref(i,:))
    end
    grid on;
    saveas(gcf,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt_scatterplots.eps'],'epsc');
    
    %automatically "fix" melt rate estimates with bad local sea level adjustments
    disp('Automatically adjusting fluxes & melt rates for icebergs with clearly bad sea level estimates');
    median_sldz = nanmedian(coreg_zo-coreg_zf); median_slzo = nanmedian(coreg_zo); median_slzf = nanmedian(coreg_zf);
    rho_sw = 1026;  %kg m^-3
    for i = 1:length(coreg_zo)
        if (coreg_zo(i)-coreg_zf(i)) > (median_sldz + 1) || (coreg_zo(i)-coreg_zf(i)) < (median_sldz - 1)
            %find the SL index
            SLref = strmatch(berg_ref(i,:),berg_nostring);
            
            %adjust the volume change estimate so that it is calculated
            %assuming the median sea level correction is accurate locally
            rho_f = rho(i);
            dZ_mean = (rho_sw/(rho_sw-rho_f))*(SL(SLref).mean.dz-((coreg_zo(i)-coreg_zf(i))-median_sldz));
            dV_mean = SL(SLref).mean.SA*(dZ_mean+SL(SLref).SMB+SL(SLref).creep_dz);
            
            %convert volume change to flux & melt rate
            to = SL(SLref).initial.time; tf = SL(SLref).final.time;
            if mod(str2num(to(1:4)),4)==0; doyso=366; modayso = [31 29 31 30 31 30 31 31 30 31 30 31]; else doyso=365; modayso = [31 28 31 30 31 30 31 31 30 31 30 31]; end
            if mod(str2num(tf(1:4)),4)==0; doysf=366; modaysf = [31 29 31 30 31 30 31 31 30 31 30 31]; else doysf=365; modaysf = [31 28 31 30 31 30 31 31 30 31 30 31]; end
            doyo = sum(modayso(1:str2num(to(5:6))))-31+str2num(to(7:8)); doyf = sum(modaysf(1:str2num(tf(5:6))))-31+str2num(tf(7:8));
            if str2num(tf(1:4)) == str2num(to(1:4))
                ddays = doyf-doyo+1;
            elseif str2num(tf(1:4)) - str2num(to(1:4)) == 1
                ddays = doyf + (doyso-doyo)+1;
            else
                years = str2num(to(1:4)):1:str2num(tf(1:4));
                for k = 1:length(years)
                    if mod(years(k),4)==0
                        doys(k)=366;
                    else
                        doys(k) = 365;
                    end
                end
                ddays = doyf + sum(doys(2:end-1)) + (doyso-doyo)+1;
            end
            hrs_o = ((str2num(to(13:14))/(60*60*24))+(str2num(to(11:12))/(60*24))+(str2num(to(9:10))/24));
            hrs_f = ((str2num(tf(13:14))/(60*60*24))+(str2num(tf(11:12))/(60*24))+(str2num(tf(9:10))/24));
            dhrs = hrs_f - hrs_o;
            dt = ddays + dhrs;
            dVdt_mean = dV_mean/dt;
            dHdt_mean = dVdt_mean/SL(i).mean.TA;
            
            %replace in structure
            SL(SLref).mean.dVdt = dVdt_mean; SL(SLref).mean.dHdt = dHdt_mean;
            SL(SLref).initial.coreg_z = median_slzo; SL(SLref).final.coreg_z = median_slzf;
        end
    end
    
    %replot
    dVdt = []; Asub = []; H = []; m = []; coreg_zo = []; coreg_zf = []; berg_ref =[];
    for i = 1:length(SL)
        if SL(i).mean.dVdt > 0 && ~isempty(SL(i).mean.TA)
            dVdt = [dVdt SL(i).mean.dVdt];
            Asub = [Asub SL(i).mean.TA];
            H = [H SL(i).mean.H];
            m = [m SL(i).mean.dHdt];
            coreg_zo = [coreg_zo SL(i).initial.coreg_z]; coreg_zf = [coreg_zf SL(i).final.coreg_z];
            berg_ref = [berg_ref; SL(i).name(end-1:end)];
        end
    end
    figure; set(gcf,'position',[100 100 1200 600]);
    subplot(1,2,1);
    plot(Asub,dVdt,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Submerged area (m^2)','fontsize',20); ylabel('Meltwater flux (m^3/d)','fontsize',20);
    for i = 1:length(m)
        text(double(Asub(i))-0.03e5,double(dVdt(i)),berg_ref(i,:))
    end
    grid on;
    subplot(1,2,2);
    plot(H,m,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Average iceberg thickness (m)','fontsize',20); ylabel('Melt rate (m/d)','fontsize',20);
    for i = 1:length(m)
        text(double(H(i))-2,double(m(i)),berg_ref(i,:))
    end
    grid on;
    disp('Iceberg meltwater flux should increase linearly with submerged area');
    disp('Iceberg melt rates should increase with thickness');
    saveas(gcf,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt_scatterplots-adjusted.eps'],'epsc');
    
    %resave as a table in a text file
    cd(dir_iceberg);
    clear dt xo yo zo po Vo xf yf zf pf Vf coreg_z* dz* dVdt* draft* Asurf* Asub*;
    append_ref = 1;
    for i = 1:length(SL)
        if SL(i).mean.dVdt > 0 && ~isempty(SL(i).mean.TA)
            dt(append_ref) = sum(SL(i).days);
            xo(append_ref) = nanmean(SL(i).initial.x); yo(append_ref) = nanmean(SL(i).initial.y); zo(append_ref) = SL(i).initial.z_median; Vo(append_ref) = SL(i).initial.V;
            xf(append_ref) = nanmean(SL(i).final.x); yf(append_ref) = nanmean(SL(i).final.y); zf(append_ref) = SL(i).final.z_median; Vf(append_ref) = SL(i).final.V;
            po(append_ref)=SL(i).initial.density; pf(append_ref) = SL(i).final.density;
            coreg_zo(append_ref) = SL(i).initial.coreg_z; coreg_zf(append_ref) = SL(i).final.coreg_z;
            dz(append_ref) = SL(i).mean.dz; dz_sigma(append_ref) = SL(i).uncert.dz;
            dVdt(append_ref) = SL(i).mean.dVdt; dVdt_uncert(append_ref) = max(SL(i).uncert.dVdt);
            draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft;
            Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA;
            Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA;
            append_ref = append_ref+1;
        else
%             SLref = strmatch(berg_ref(i,:),berg_nostring);
            disp(['Skipping over data for ',num2str(berg_ref(i,:))]);
        end
    end
    bad_refs = find(draft<0); %remove data with negative thicknesses (unrealistic = error-prone)
    dt(bad_refs) = []; 
    xo(bad_refs) = []; yo(bad_refs) = [];  zo(bad_refs) = []; Vo(bad_refs) = []; po(bad_refs) = []; coreg_zo(bad_refs) = []; 
    xf(bad_refs) = []; yf(bad_refs) = [];  zf(bad_refs) = []; Vf(bad_refs) = []; pf(bad_refs) = []; coreg_zf(bad_refs) = []; 
    dz(bad_refs) = []; dz_sigma(bad_refs) = []; dVdt(bad_refs) = []; dVdt_uncert(bad_refs) = []; 
    draft(bad_refs) = []; draft_uncert(bad_refs) = []; Asurf(bad_refs) = []; Asurf_uncert(bad_refs) = []; Asub(bad_refs) = []; Asub_uncert(bad_refs) = []; 
    clear bad_refs; 
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...         'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...         'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...         'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...         'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...         'SubmergedArea_mean (m^3)','SubmergedArea_range (m^3)'};
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    T=table(dt',xo',yo',zo',po',Vo',xf',yf',zf',pf',Vf',coreg_zo',coreg_zf',dz',dz_sigma',dVdt',dVdt_uncert',draft',draft_uncert',Asurf',Asurf_uncert',Asub',Asub_uncert'); T.Properties.VariableNames = column_names;
    writetable(T,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_meltinfo.csv']);
    
    %call-out the clearly bad icebergs
    for i = 1:length(SL)
        if SL(i).mean.dVdt < 0
            disp(['Recalculate elevation change for iceberg #',num2str(berg_ref(i,:))]);
        end
    end
    
    %resave to the mat-file
    disp('Saving melt rates');
    save([dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt.mat'],'SL','-v7.3');
    
    disp(' ');
    disp('Save the figures');
    disp('Define a variable, berg_refs, that lists the #s of the icebergs that have bad melt rate estimates');
    disp('   "berg_refs = [#s in here];"');
    disp('Run option 2 in the last section of the wrapper:');
    disp('   a) When prompted, specify the icebergs to rerun using iceberg_refs = X:Y; dbcont');
    disp('   b) Update and/or remove icebergs as necessary');
    clear SL;
    
elseif option_no==2 %recalculate melt rates for select icebergs
    disp('Recalculate melt rates for select icebergs then remove icebergs that still have bad results');
    dir_iceberg = [dir_output,'/',DEM1.time,'-',DEM2.time,'/'];
    berg_numbers = dir([dir_iceberg,'iceberg*dz.mat']);
    dir_bedrock = [dir_output,'DEM_offset_data/'];
    
    %update and/or remove select icebergs
    if exist('iceberg_refs') ~= 1
        disp('Specify the bergs that need updating as "iceberg_refs = []; dbcont"');
        keyboard
    end
    [SL] = update_or_remove_Antarctic_iceberg_meltrates(root_dir,glacier_dir,dir_iceberg,DEM1_time,DEM1_name,DEM2_time,DEM2_name,region_name,region_abbrev,berg_refs,iceberg_refs);
    
    %plot
    dVdt = []; Asub = []; H = []; m = []; coreg_zo = []; coreg_zf = []; berg_ref =[];
    for i = 1:length(SL)
        if SL(i).mean.dVdt > 0 && ~isempty(SL(i).mean.TA)
            dVdt = [dVdt SL(i).mean.dVdt];
            Asub = [Asub SL(i).mean.TA];
            H = [H SL(i).mean.H];
            m = [m SL(i).mean.dHdt];
            coreg_zo = [coreg_zo SL(i).initial.coreg_z]; coreg_zf = [coreg_zf SL(i).final.coreg_z];
            berg_ref = [berg_ref; SL(i).name(end-1:end)];
        end
    end
    figure; set(gcf,'position',[100 100 1200 600]);
    subplot(1,2,1);
    plot(Asub,dVdt,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Submerged area (m^2)','fontsize',20); ylabel('Meltwater flux (m^3/d)','fontsize',20);
    for i = 1:length(m)
        text(double(Asub(i))-0.03e5,double(dVdt(i)),berg_ref(i,:))
    end
    grid on;
    subplot(1,2,2);
    plot(H,m,'ok','markersize',24,'markerfacecolor','w'); hold on;
    set(gca,'fontsize',20); xlabel('Average iceberg thickness (m)','fontsize',20); ylabel('Melt rate (m/d)','fontsize',20);
    for i = 1:length(m)
        text(double(H(i))-2,double(m(i)),berg_ref(i,:))
    end
    grid on;
    saveas(gcf,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_melt_scatterplots-adjusted.eps'],'epsc');
    
    %resave as a table in a text file
    cd(dir_iceberg);
    clear dt xo yo zo po Vo xf yf zf pf Vf coreg_z* dz* dVdt* draft* Asurf* Asub*;
    append_ref = 1;
    for i = 1:length(SL)
        if SL(i).mean.dVdt > 0 && ~isempty(SL(i).mean.TA)
            dt(append_ref) = sum(SL(i).days);
            xo(append_ref) = nanmean(SL(i).initial.x); yo(append_ref) = nanmean(SL(i).initial.y); zo(append_ref) = SL(i).initial.z_median; Vo(append_ref) = SL(i).initial.V;
            xf(append_ref) = nanmean(SL(i).final.x); yf(append_ref) = nanmean(SL(i).final.y); zf(append_ref) = SL(i).final.z_median; Vf(append_ref) = SL(i).final.V;
            po(append_ref)=SL(i).initial.density; pf(append_ref) = SL(i).final.density;
            coreg_zo(append_ref) = SL(i).initial.coreg_z; coreg_zf(append_ref) = SL(i).final.coreg_z;
            dz(append_ref) = SL(i).mean.dz; dz_sigma(append_ref) = SL(i).uncert.dz;
            dVdt(append_ref) = SL(i).mean.dVdt; dVdt_uncert(append_ref) = max(SL(i).uncert.dVdt);
            draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft;
            Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA;
            Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA;
            append_ref = append_ref+1;
        else
%             SLref = strmatch(berg_ref(i,:),berg_nostring);
            disp(['Skipping over data for ',num2str(berg_ref(i,:))]);
        end
    end
    bad_refs = find(draft<0); %remove data with negative thicknesses (unrealistic = error-prone)
    dt(bad_refs) = []; 
    xo(bad_refs) = []; yo(bad_refs) = [];  zo(bad_refs) = []; Vo(bad_refs) = []; po(bad_refs) = []; coreg_zo(bad_refs) = []; 
    xf(bad_refs) = []; yf(bad_refs) = [];  zf(bad_refs) = []; Vf(bad_refs) = []; pf(bad_refs) = []; coreg_zf(bad_refs) = []; 
    dz(bad_refs) = []; dz_sigma(bad_refs) = []; dVdt(bad_refs) = []; dVdt_uncert(bad_refs) = []; 
    draft(bad_refs) = []; draft_uncert(bad_refs) = []; Asurf(bad_refs) = []; Asurf_uncert(bad_refs) = []; Asub(bad_refs) = []; Asub_uncert(bad_refs) = []; 
    clear bad_refs; 
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...         'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...         'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...         'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...         'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...         'SubmergedArea_mean (m^3)','SubmergedArea_range (m^3)'};
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    T=table(dt',xo',yo',zo',po',Vo',xf',yf',zf',pf',Vf',coreg_zo',coreg_zf',dz',dz_sigma',dVdt',dVdt_uncert',draft',draft_uncert',Asurf',Asurf_uncert',Asub',Asub_uncert'); T.Properties.VariableNames = column_names;
    writetable(T,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.time,'-',DEM2.time,'_iceberg_meltinfo.csv']);
    disp('Text file written');
    
end



end 