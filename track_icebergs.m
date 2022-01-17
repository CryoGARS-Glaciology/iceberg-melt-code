function [PSx_early,PSy_early,PSx_late,PSy_late] = track_icebergs(DEM1,DEM2,IM1,IM2,dir_output)
% Function to identify the identifiable icebergs in both DEMs and save the 
% coordinates as .txt files.
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
%
% OUTPUTS:  PSx_early       x coordinates (Antarctic Polar Stereo) of
%                           icebergs in the earlier DEM
%           PSy_early       y coordinates (Antarctic Polar Stereo) of
%                           icebergs in the earlier DEM
%           PSx_late        x coordinates (Antarctic Polar Stereo) of
%                           icebergs in the later DEM
%           PSy_late        y coordinates (Antarctic Polar Stereo) of
%                           icebergs in the later DEM

%navigate to the date-specific directory
cd_to_datefolder = ['cd ',dir_output,'/',DEM1.time,'-',DEM2.time,'/']; eval(cd_to_datefolder);

%plot co-registered DEMs
DEM1.z_elpsd_adjust(DEM1.z_elpsd_adjust<0) = 0; DEM2.z_elpsd_adjust(DEM2.z_elpsd_adjust<0) = 0; %remove elevations less than zero for plotting purposes
figure1 = figure; set(figure1,'position',[0 600 900 600]);
imagesc(DEM1.x,DEM1.y,DEM1.z_elpsd_adjust); axis xy equal; set(gca,'clim',[min(DEM1.z_elpsd_adjust(~isnan(DEM1.z_elpsd_adjust))) min(DEM1.z_elpsd_adjust(~isnan(DEM1.z_elpsd_adjust)))+40]); colormap(gca,'jet'); colorbar; grid on;
set(gca,'xtick',[min(DEM1.x):round(range(DEM1.x)/10000)*1000:max(DEM1.x)],'xticklabel',[min(DEM1.x)/1000:round(range(DEM1.x)/10000):max(DEM1.x)/1000],...
    'ytick',[min(DEM1.y):round(range(DEM1.y)/10000)*1000:max(DEM1.y)],'yticklabel',[min(DEM1.y)/1000:round(range(DEM1.y)/10000):max(DEM1.y)/1000]);
figure2 = figure; set(figure2,'position',[975 600 900 600]);
imagesc(DEM2.x,DEM2.y,DEM2.z_elpsd_adjust); axis xy equal; set(gca,'clim',[min(DEM2.z_elpsd_adjust(~isnan(DEM2.z_elpsd_adjust))) min(DEM2.z_elpsd_adjust(~isnan(DEM2.z_elpsd_adjust)))+40]); colormap(gca,'jet'); colorbar; grid on;
set(gca,'xtick',[min(DEM2.x):round(range(DEM2.x)/10000)*1000:max(DEM2.x)],'xticklabel',[min(DEM2.x)/1000:round(range(DEM2.x)/10000):max(DEM2.x)/1000],...
    'ytick',[min(DEM2.y):round(range(DEM2.y)/10000)*1000:max(DEM2.y)],'yticklabel',[min(DEM2.y)/1000:round(range(DEM2.y)/10000):max(DEM2.y)/1000]);

%plot images
figure3 = figure; set(figure3,'position',[0 0 900 600]); ax3=gca;
imagesc(IM1.x,IM1.y,IM1.z); axis xy equal; colormap(gca,'gray'); grid on; set(gca,'clim',[0 200]); hold on;
set(gca,'xtick',[min(DEM1.x):round(range(DEM1.x)/10000)*1000:max(DEM1.x)],'xticklabel',[min(DEM1.x)/1000:round(range(DEM1.x)/10000):max(DEM1.x)/1000],...
    'ytick',[min(DEM1.y):round(range(DEM1.y)/10000)*1000:max(DEM1.y)],'yticklabel',[min(DEM1.y)/1000:round(range(DEM1.y)/10000):max(DEM1.y)/1000]);

figure4 = figure; set(figure4,'position',[975 0 900 600]); ax4=gca;
imagesc(IM2.x,IM2.y,IM2.z); axis xy equal; colormap(gca,'gray'); grid on; set(gca,'clim',[0 200]); hold on;
set(gca,'xtick',[min(DEM2.x):round(range(DEM2.x)/10000)*1000:max(DEM2.x)],'xticklabel',[min(DEM2.x)/1000:round(range(DEM2.x)/10000):max(DEM2.x)/1000],...
    'ytick',[min(DEM2.y):round(range(DEM2.y)/10000)*1000:max(DEM2.y)],'yticklabel',[min(DEM2.y)/1000:round(range(DEM2.y)/10000):max(DEM2.y)/1000]);


% pick iceberg coordinates
disp('Click on each iceberg you can visually ID on both DEMs. Max is 30!');
disp('earlier DEM');
% col = spring(30); % color scheme for plotting
more=1; % select more icebergs when more=1
i=0; % index for storing coordinates
axes(ax3); % bring figure 3 axes to front
while more==1
    axes(ax3);
    i=i+1;
    [PSx_early(i),PSy_early(i)] = ginput(1);
    plot(gca,PSx_early(i),PSy_early(i),'.','markersize',10,'color','y');
    
    str = input('Do you see more icebergs (y/n)?','s');
    if strcmp(str,'n')
        more=more+1;
    end 
end
%add number labels
axes(ax3);
for i = 1:length(PSx_early)
   text(PSx_early(i)+300,PSy_early(i),num2str(i),'color','y','fontsize',18); hold on;
end
disp('later DEM: Now, click on the same icebergs in the other image');
disp('   You can click until the same number of icebergs have been selected');
figure(figure4);
for j=1:i
    axes(ax4); % bring figure 4 axes to front
    [PSx_late(j),PSy_late(j)] = ginput(1);
    plot(PSx_late(j),PSy_late(j),'.','markersize',10,'color','y');
    drawnow
end

% sort by x coordinates then y-coordinates
early_coords = [PSx_early',PSy_early']; %early_coords = sortrows(early_coords,[1 2]);
PSx_early = early_coords(:,1); PSy_early = early_coords(:,2);
late_coords = [PSx_late',PSy_late']; %late_coords = sortrows(late_coords,[1 2]);
PSx_late = late_coords(:,1); PSy_late = late_coords(:,2);

%save iceberg coordinates
% if ~exist([dir_output,'iceberg_data/'], 'dir')
%    mkdir([dir_output,'iceberg_data/'])
% end
for j = 1:length(PSx_early)
    if size(num2str(j),2) == 1
        iceberg_no = [num2str(0),num2str(j)];
    else
        iceberg_no = num2str(j);
    end
    coords = [PSy_early(j)  PSx_early(j) PSy_late(j) PSx_late(j)];
    coords_table = array2table(coords,...
        'VariableNames',{'DEM1: Y (m)','DEM1: X (m)','DEM2: X (m)','DEM2: Y (m)'});
    writetable(coords_table,[dir_output,'/',DEM1.time,'-',DEM2.time,'/','iceberg',iceberg_no,'_PScoords.txt']);
    clear coords;
end
disp('iceberg coordinates saved');

% close all; drawnow;
clear Y Z I1 I2;

disp('Advance to the next step');
disp('------------------------');