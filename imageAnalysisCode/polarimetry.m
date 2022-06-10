%% Polarimetry
% This code requires you have DCRAW application by Dave Coffin:
%       https://www.dechifro.org/dcraw/
% This code follows the workflow outlined at 
% https://www.rcsumner.net/raw_guide/RAWguide.pdf

%%
clear

image_path  = fullfile(pwd,'images');
dcraw_path  = '.\imageAnalysisCode';
d           = dir(fullfile(image_path,'*.cr2'));

angles  = [0 45 90 135];
[~,ind] = sort(angles);

% get black, saturation, and white balance multipliers from each image
for i = 1:length(ind)
    [~,image_name,raw_ext] = fileparts(d(ind(i)).name);
    [black(i,1), saturation(i,1), wb_multipliers(i,:)] = reading_raw(image_path,image_name,raw_ext,dcraw_path);
end
max_black       = min(black);
max_saturation  = max(saturation);
max_wb          = max(wb_multipliers);

for i = 1:length(ind)

    [~,image_name,raw_ext] = fileparts(d(ind(i)).name);
    im = fullfile([image_path],[image_name,'.tiff']);
    raw = double(imread(im));
    
    % Linearise the image and normalise to [0,1] range using the black and
    % saturation values from the first informational run of dcraw
    lin_bayer = (raw-max_black)/(max_saturation-max_black);
    lin_bayer = max(0,min(lin_bayer,1));

    Pol(:,:,i) = lin_bayer(2:2:end,1:2:end);  

end

for i = 1:length(ind)

    figure(100)
    spr = ceil(sqrt(length(ind))); % subplot rows
    spc = floor(sqrt(length(ind))); % subplot columns
    subplot(spr,spc,i)
    imagesc(Pol(:,:,i))
    title([num2str(angles(ind(i)))])
    colbar_max = median(Pol(:,:,:),'all')+0.5*std(Pol(:,:,:),0,'all');
    caxis([0 colbar_max])
    c = colorbar;
    c.Label.String = ('Intensity');
    c.Location = ('southoutside');
    colormap gray
%     axis equal

end

%% calculate stokes parameters
    
tmp1    = Pol(:,:,angles(ind)==45) + Pol(:,:,angles(ind)==135);
tmp2    = Pol(:,:,angles(ind)==0) + Pol(:,:,angles(ind)==90);
S0      = max(tmp1,tmp2);

S0_max  = max(S0,[],'all');
S0      = S0./S0_max;

S1 = Pol(:,:,angles(ind)==0) - Pol(:,:,angles(ind)==90);
S1 = S1./S0_max;
S2 = Pol(:,:,angles(ind)==45) - Pol(:,:,angles(ind)==135);
S2 = S2./S0_max;

AoP     = 0.5*atan2d(S2,S1);
AoP     = mod(AoP,180);
DoLP    = sqrt((S1.^2) + (S2.^2)) ./ S0;


%% plot images
close all
    
% 1. relative intensity
    sp(1) = figure(1); hold on
    img = S0./max(S0(:));
    imagesc(img)
    set(gca,'XTickLabel','','YTickLabel','')
    c = colorbar;
    c.Label.String = ('Relative Intensity');
    c.Location = ('southoutside');
    caxis([0 1])
    title('Intensity')
    axis equal
    set(gca,'YDir','reverse')
    set(gca,'Visible', 'off')

%  2. DoLP
    sp(2) = figure(2); hold on
    img = DoLP;
    imagesc(img)
    set(gca,'XTickLabel','','YTickLabel','')
    c = colorbar;
    c.Label.String = ('DoLP');
    c.Location = ('southoutside');
    caxis([0 1]);
    title('DoLP')
    axis equal
    set(gca,'YDir','reverse')
    set(gca,'Visible', 'off')

% 3. AoP
    sp(3) = figure(3); hold on
    img = AoP;
    imagesc(img)
    set(gca,'XTickLabel','','YTickLabel','')
    c = colorbar;
    c.Label.String = ('AoP');
    c.Location = ('southoutside');
    c.Ticks = [0:45:180];
    colormap(sp(3),'hsv');
    caxis([0 180])
    title('AoP')
    axis equal
    set(gca,'YDir','reverse')
    set(gca,'Visible', 'off')

% 4. convolve DoLP with AoP
    sp(4) = figure(4); hold on
    img = AoP;
    rectangle('position',[0 0 size(img,2) size(img,1)],'FaceColor','k','EdgeColor','none')
    img_alpha = DoLP;
    img_alpha(img_alpha > 1) = 1;
    imagesc(img,'AlphaData',img_alpha)
    set(gca,'XTickLabel','','YTickLabel','')
    c = colorbar;
    c.Label.String = ('AoP');
    c.Location = ('southoutside');
    c.Ticks = [0:45:180];
    colormap(sp(4),'hsv');
    caxis([0 180])
    set(gca,'Color','k')
    axis equal
    set(gca,'YDir','reverse')
    set(gca,'Visible', 'off')


    %% save figure
    timestamp = datestr(now,'yymmdd_HHMM');
    save_path = fullfile(pwd,'polFigures',timestamp);
    mkdir(save_path)
    
    fig                 = figure(1);
    set(fig,'color',[1 1 1])
    set(fig, 'InvertHardCopy', 'off');
    A4_dims_x           = [21];
    fig.PaperUnits      = 'centimeters';
    fig.PaperPosition   = [0 0 A4_dims_x/2 A4_dims_x/2];
    figname             = ['1. Relative intensity'];
    filename            = fullfile(save_path,figname);
    saveas(fig,[filename,'.svg'])
    print(fig,[filename,'.png'], '-dpng','-r300')         

    fig                 = figure(2);
    set(fig,'color',[1 1 1])
    set(fig, 'InvertHardCopy', 'off'); 
    A4_dims_x           = [21];
    fig.PaperUnits      = 'centimeters';
    fig.PaperPosition   = [0 0 A4_dims_x/2 A4_dims_x/2];
    figname             = ['2. DoLP'];
    filename            = fullfile(save_path,figname);
    saveas(fig,[filename,'.svg'])
    print(fig,[filename,'.png'], '-dpng','-r300')         

    fig                 = figure(3);
    set(fig,'color',[1 1 1])
    set(fig, 'InvertHardCopy', 'off'); 
    A4_dims_x           = [21];
    fig.PaperUnits      = 'centimeters';
    fig.PaperPosition   = [0 0 A4_dims_x/2 A4_dims_x/2];
    figname             = ['3. AoP'];
    filename            = fullfile(save_path,figname);
    saveas(fig,[filename,'.svg'])
    print(fig,[filename,'.png'], '-dpng','-r300')         

    fig                 = figure(4);
    set(fig,'color',[1 1 1])
    set(fig, 'InvertHardCopy', 'off');
    A4_dims_x           = [21];
    fig.PaperUnits      = 'centimeters';
    fig.PaperPosition   = [0 0 A4_dims_x/2 A4_dims_x/2];
    figname             = ['4. weighted AoP'];
    filename            = fullfile(save_path,figname);
    saveas(fig,[filename,'.svg'])
    print(fig,[filename,'.png'], '-dpng','-r300')

