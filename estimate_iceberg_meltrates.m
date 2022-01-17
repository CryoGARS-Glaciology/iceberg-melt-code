function [DEM1,DEM2] = estimate_iceberg_meltrates(DEM1,DEM2,IM1,IM2,dir_output,dir_code,region_abbrev,region_name,step_no)
% Function to estimate iceberg freshwater fluxes and melt rates
% Ellyn Enderlin & Mariama Dryak
% Slightly reformatted by Rainey Aberle, Fall 2021
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
%           step_no         select which step to execute (1 or 2):
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

% ----------STEP 1----------

% Estimate elevation change for each iceberg
if step_no==1
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
            disp('   Ex: iceberg_refs = 4:size(icebergs,1); dbcont');
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
        
    % ----------STEP 2----------
    % Calculate meltwater fluxes, melt rates, and uncertainties
    
    disp('Convert elevation change to meltwater fluxes & melt rates');
    cd(dir_iceberg);
    berg_numbers = dir([dir_iceberg,'iceberg*dz.mat']);
    dir_bedrock = [dir_output,'/DEM_offset_data/'];
    
    %if calculating volume fluxes for all icebergs:
    %[SL] = convert_Antarctic_iceberg_fluxes_to_meltrates(region_name,root_dir,glacier_dir,iceberg_dir,bedrock_dir,berg_numbers,DEM1_time,DEM1_name,DEM2_time,DEM2_name,region_abbrev);
    %clear SL;
    %load_meltrates = ['load ',region_abbrev,'_iceberg_melt.mat']; eval(load_meltrates);
    
    % calculate iceberg meltrate from elevation change:
    SL = convert_Antarctic_iceberg_elev_change_to_meltrates(DEM1,DEM2,IM1,IM2,berg_numbers,region_name,region_abbrev,dir_output,dir_code,dir_iceberg,dir_bedrock);
    
    %save as a table in a text file
    clear dt xo yo zo po Vo xf yf zf pf Vf coreg_z* dz* dVdt* draft* Asurf* Asub*;
    for i = 1:length(SL)
        dt(i) = sum(SL(i).days);
        xo(i) = nanmean(SL(i).initial.x); yo(i) = nanmean(SL(i).initial.y); zo(i) = SL(i).initial.z_median; Vo(i) = SL(i).initial.V;
        xf(i) = nanmean(SL(i).final.x); yf(i) = nanmean(SL(i).final.y); zf(i) = SL(i).final.z_median; Vf(i) = SL(i).final.V;
        po(i)=SL(i).initial.density; pf(i) = SL(i).final.density;
        coreg_zo(i) = SL(i).initial.coreg_z; coreg_zf(i) = SL(i).final.coreg_z;
        dz(i) = SL(i).mean.dz; dz_sigma(i) = SL(i).uncert.dz;
        dVdt(i) = SL(i).mean.dVdt; dVdt_uncert(i) = max(SL(i).uncert.dVdt);
        %     draft(i) = SL(i).mean.draft; draft_uncert(i) = SL(i).change.draft/2;
        %     Asurf(i) = SL(i).mean.SA; Asurf_uncert(i) = SL(i).change.SA/2;
        %     Asub(i) = SL(i).mean.TA; Asub_uncert(i) = SL(i).change.TA/2;
        draft(i) = SL(i).mean.draft; draft_uncert(i) = SL(i).change.draft;
        Asurf(i) = SL(i).mean.SA; Asurf_uncert(i) = SL(i).change.SA;
        Asub(i) = SL(i).mean.TA; Asub_uncert(i) = SL(i).change.TA;
    end
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...         'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...         'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...         'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...         'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...         'SubmergedArea_mean (m^3)','SubmergedArea_range (m^3)'};
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    column_vals = [dt' xo' yo' zo' po' Vo' xf' yf' zf' pf' Vf' coreg_zo' coreg_zf' dz' dz_sigma' dVdt' dVdt_uncert' draft' draft_uncert' Asurf' Asurf_uncert' Asub' Asub_uncert'];
    bad_refs = find(column_vals(:,18)<0); column_vals(bad_refs,:) = []; clear bad_refs; %remove data with negative thicknesses (unrealistic = error-prone)
    % dlmwrite([region_abbrev,'_',DEM1_time(1:8),'-',DEM2_time(1:8),'_iceberg_meltinfo.txt'],column_vals,'delimiter','\t');
    T=table(column_vals); T.Properties.VariableNames = column_names;
    writetable(T,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.date,'-',DEM2.date,'_iceberg_meltinfo.csv']);
    
    %plot to figure-out which icebergs need to be re-run
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
    
    %automatically "fix" melt rate estimates with bad local sea level adjustments
    disp('Automatically adjusting fluxes & melt rates for icebergs with clearly bad sea level estimates');
    median_sldz = nanmedian(coreg_zo-coreg_zf); median_slzo = nanmedian(coreg_zo); median_slzf = nanmedian(coreg_zf);
    rho_i = 900; rho_i_err = 20; %kg m^-3
    rho_sw = 1026;  rho_sw_err = 2; %kg m^-3
    for i = 1:length(coreg_zo)
        if (coreg_zo(i)-coreg_zf(i)) > (median_sldz + 1) || (coreg_zo(i)-coreg_zf(i)) < (median_sldz - 1)
            %adjust the volume change estimate so that it is calculated
            %assuming the median sea level correction is accurate locally
            rho_f = (po(i)+pf(i))/2;
            dZ_mean = (rho_sw/(rho_sw-rho_f))*(SL(i).mean.dz-((coreg_zo(i)-coreg_zf(i))-median_sldz));
            dV_mean = SL(i).mean.SA*(dZ_mean+SL(i).SMB+SL(i).creep_dz);
            
            %convert volume change to flux & melt rate
            to = SL(i).initial.time; tf = SL(i).final.time;
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
            SL(i).mean.dVdt = dVdt_mean; SL(i).mean.dHdt = dHdt_mean;
            SL(i).initial.coreg_z = median_slzo; SL(i).final.coreg_z = median_slzf;
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
            %         draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft/2;
            %         Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA/2;
            %         Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA/2;
            draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft;
            Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA;
            Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA;
            append_ref = append_ref+1;
        else
            disp(['Skipping over data for ',num2str(i)]);
        end
    end
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...       
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    column_vals = [dt' xo' yo' zo' po' Vo' xf' yf' zf' pf' Vf' coreg_zo' coreg_zf' dz' dz_sigma' dVdt' dVdt_uncert' draft' draft_uncert' Asurf' Asurf_uncert' Asub' Asub_uncert'];
    bad_refs = find(column_vals(:,18)<0); column_vals(bad_refs,:) = []; clear bad_refs; %remove data with negative thicknesses (unrealistic = error-prone)
    % dlmwrite([region_abbrev,'_',DEM1_time(1:8),'-',DEM2_time(1:8),'_iceberg_meltinfo.txt'],column_vals,'delimiter','\t');
    T=table(column_vals); T.Properties.VariableNames = column_names;
    writetable(T,[dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_',DEM1.date,'-',DEM2.date,'_iceberg_meltinfo.csv']);
    
    %call-out the clearly bad icebergs
    for i = 1:length(SL)
        if SL(i).mean.dVdt < 0
            disp(['Recalculate elevation change for iceberg #',num2str(i)]);
        end
    end
    
    %resave to the mat-file
    disp('Saving melt rates');
    save([dir_output,'/',DEM1.time,'-',DEM2.time,'/',region_abbrev,'_iceberg_melt.mat'],'SL','-v7.3');
    
    disp(' ');
    disp('Save the figures');
    disp('Define a variable, berg_refs, that lists the #s of the icebergs that have bad melt rate estimates');
    disp('   "berg_refs = [#s in here];"');
    disp('Repeat STEP 1 for icebergs with negative melt rates (listed above) & outliers in plots by doing the following:');
    disp('   a) Insert a blank line above line 41 ("for j =1:size(icebergs,1);") in STEP 1 above');
    disp('   b) Insert a percent sign before "for j =1:size(icebergs,1);"');
    disp('   c) In the blank line, add "for j = berg_refs" so that only the icebergs you IDed will be redone when you run this section');
    disp('   d) Now run the STEP 1 section');
    clear SL;
    
end

% ----------ALTERNATE STEP 2----------
% Update individual icebergs and/or remove icebergs with anomalous melt rate estimates

if step_no==2
    disp('Recalculate melt rates for select icebergs then remove icebergs that still have bad results');
    dir_iceberg = [dir_output,'/',DEM1.time,'-',DEM2.time,'/'];
    berg_numbers = dir([dir_iceberg,'iceberg*dz.mat']);
    dir_bedrock = [dir_output,'DEM_offset_data/'];
    
    disp('If you already know some icebergs are bad, specify them now as "bad_bergs = []; dbcont"');
    keyboard
    [SL] = update_or_remove_Antarctic_iceberg_meltrates(root_dir,glacier_dir,dir_iceberg,dir_bedrock,berg_numbers,DEM1_time,DEM1_name,DEM2_time,DEM2_name,region_name,region_abbrev,berg_refs,bad_bergs);
    
    %resave to tab-delimited text file
    disp('Saving final results to a tab-delimited text file');
    cd_to_iceberg_data = ['cd ',dir_iceberg]; eval(cd_to_iceberg_data);
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
            %         draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft/2;
            %         Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA/2;
            %         Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA/2;
            draft(append_ref) = SL(i).mean.draft; draft_uncert(append_ref) = SL(i).change.draft;
            Asurf(append_ref) = SL(i).mean.SA; Asurf_uncert(append_ref) = SL(i).change.SA;
            Asub(append_ref) = SL(i).mean.TA; Asub_uncert(append_ref) = SL(i).change.TA;
            append_ref = append_ref+1;
        else
            disp(['Skipping over data for ',num2str(i)]);
        end
    end
    column_names = {'TimeSeparation (days)' 'X_i (m)' 'Y_i (m)' 'MedianZ_i (m)'...         'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...         'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...         'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...         'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...         'SubmergedArea_mean (m^3)','SubmergedArea_range (m^3)'};
        'Density_i (kg/m^3)' 'Volume_i (m^3)' 'X_f (m)' 'Y_f (m)' 'MedianZ_f (m)'...
        'Density_f (kg/m^3)' 'Volume_f (m^3)' 'VerticalAdjustment_i (m)' 'VerticalAdjustment_f (m)'...
        'MeanElevationChange (m)' 'StdevElevationChange (m)' 'VolumeChangeRate (m^3/d)' 'VolumeChangeRate_uncert (m^3/d)'...
        'MedianDraft_mean (m)' 'MedianDraft_range (m)' 'SurfaceArea_mean (m^2)' 'SurfaceArea_range (m^2)'...
        'SubmergedArea_mean (m^3)','SubmergedArea_uncert (m^3)'};
    column_vals = [dt' xo' yo' zo' po' Vo' xf' yf' zf' pf' Vf' coreg_zo' coreg_zf' dz' dz_sigma' dVdt' dVdt_uncert' draft' draft_uncert' Asurf' Asurf_uncert' Asub' Asub_uncert'];
    bad_refs = find(column_vals(:,18)<0); column_vals(bad_refs,:) = []; clear bad_refs; %remove data with negative thicknesses (unrealistic = error-prone)
    % dlmwrite([region_abbrev,'_',DEM1_time(1:8),'-',DEM2_time(1:8),'_iceberg_meltinfo.txt'],column_vals,'delimiter','\t');
    T=table(column_vals); T.Properties.VariableNames = column_names;
    writetable(T,[region_abbrev,'_',DEM1_time(1:8),'-',DEM2_time(1:8),'_iceberg_meltinfo.csv']);
    disp('Text file written');
    
end



end 