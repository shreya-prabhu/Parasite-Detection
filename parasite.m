%%
clear; close all;clc; 

%% Loading and Displaying Images:

babesiosisDir = fullfile(pwd,'.\babesiosis');
imgset=imageSet(babesiosisDir);
methods(imgset);


togglefig('Babesiosis Images');

%Create graphic objects array
ax=gobjects(imgset.Count,1);
for ii=1:imgset.Count
    
    %Appending each image to object array
    %Create a display of all images in a grid format
    
    ax(ii)= subplot(floor(sqrt(imgset.Count)),ceil(sqrt(imgset.Count)),ii);
       [~,currName]=fileparts(imgset.ImageLocation{ii});
       imshow(read(imgset,ii))
       title([num2str(ii),')' currName],'interpreter','none','fontsize',7)
end

%% selection of target:

togglefig('Babesiosis Images')
targetImgNum=1;
[~,Imname]=fileparts(imgset.ImageLocation{targetImgNum});

%Marking target with red border
set(ax,'xcolor','r','ycolor','r','xtick',[],'ytick',[],'linewidth',2,'visible','off')
set(ax(targetImgNum),'visible','on');

targetimage=read(imgset,targetImgNum);
togglefig('Target image');
imshow(targetimage);
title(Imname,'interpreter','None','fontsize',12);
imtool(targetimage)
%% Morphological Segmentation - Here we demonstrate with with target image

%Segmentation- creating a binary mask that is 'true' in region of interest (marking out the cells)
grayscale = rgb2gray(targetimage);
%Using image segmenter app
cellMask = segmentImage(targetimage);

% Remove objects containing fewer than ‘n’ pixels thereby 'cleaning' the image
cellMask = bwareaopen(cellMask,100);
%togglefig('Cell Mask',true); imshow(cellMask);

%% Try detecting edges
%Finds edges by looking for zero-crossings after filtering img with a Laplacian of Gaussian (LoG) filter
%with a threshold of 0.001
edges = edge(rgb2gray(targetimage),'LOG',0.001);
edges = bwareaopen(edges,60,8);
% togglefig('Edge Mask')
% Display target image vs edges
% subplot(1,2,1) ; imshow(targetimage)
% subplot(1,2,2) ; imshow(edges)


%% Improve the edge mask

morphed1 = imclose(edges, strel('Disk',3,4));
morphed1 = bwmorph(morphed1, 'skeleton', Inf);
morphed1 = bwmorph(morphed1, 'spur', Inf);
morphed1 = bwpropfilt(morphed1,'Perimeter',[80 Inf]);
togglefig('Edge Mask',true)
imshow(morphed1);
imshow(cellMask & ~morphed1);

%% Combine the edges (logically) with the segmented regions
togglefig('Final Cell Mask on Target')
tmp = cellMask & ~edges;
tmp = bwareaopen(tmp,100);
imshow(tmp);


%% Applying Segmentation Mask on all Images


for ii = 1:imgset.Count
	mask = refinedMask(getimage(ax(ii)));
end


%% Watershed Segmentation 


%segmenting the cells
segment_img=segmentImage(targetimage);
% togglefig('cell mask');
% imshow(segment_img);


%watershed algorithm to remove noise
grayscale = rgb2gray(targetimage);
wsimg = watershed(grayscale);

% togglefig('Exploration')
grayscale = imhmin(grayscale,13);
wsimg = watershed(grayscale);
% title('Watershed','fontsize',14);


%improving our cell mask
togglefig("Watershed Cell Mask",true);
cellMask=segmentImage(targetimage);
cellMask=bwareaopen(cellMask,30);
wsEdges= wsimg==0;
wsEdges=bwareaopen(wsEdges,200,8);

cellMask(wsEdges)=0;
imshow(cellMask);


for ii = 1:imgset.Count
    tmpMask = refinedMask2(imgset,ii)
end



%% Circle Detection

detectCircles = @(x) imfindcircles(x,[23 35], ...
	'Sensitivity',0.89, ...
	'EdgeThreshold',0.04, ...
	'Method','TwoStage', ...
	'ObjectPolarity','Dark');
[centers, radii, metric] = detectCircles(grayscale);
togglefig('Circle Detection on Target Image',true)
imshow(targetimage)


%viscircles draws circle with given centre and radius
viscircles(centers,radii,'edgecolor','b')
title(sprintf('%i Cells Detected',numel(radii)),'fontsize',14);

%Applying function on all images
% togglefig('Circle Detection Function on Images')
for ii = 1:imgset.Count
	[centers,radii] = detectCircles(rgb2gray(read(imgset,ii)));
	delete(findall(ax(ii),'type','line'))
	viscircles(ax(ii),centers,radii,'edgecolor','b')
	drawnow
end

%% Trying to bring all images to same greyscale threshold
%For example, the first and last images are quite different 
%in terms of lighting and clarity

% Based on pixel values noted using image toolbox, we consider an
% "infection threshold" of 135

togglefig('Exploration',1);
infectionThreshold = 135;
infection = grayscale <= infectionThreshold;
subplot(1,2,1)
imshow(targetimage)
subplot(1,2,2)
tmpImg = read(imgset,8);
imshow(tmpImg)
infection = rgb2gray(tmpImg) <= infectionThreshold;



%% So which cells, and what fraction of cells, are infected?
[centers,radii] = detectCircles(grayscale);
isInfected = false(numel(radii),1);
nCells = numel(isInfected);

% Creating a mesh:
x = 1:size(grayscale,2);
y = 1:size(grayscale,1);
[xx,yy] = meshgrid(x,y);


togglefig('Grayscale',true);
imshow(grayscale)

%Initialize a mask

infectionMask = false(size(grayscale));

for ii = 1:numel(radii)
    
    %hypotenuse <= radius
	mask = hypot(xx - centers(ii,1), yy - centers(ii,2)) <= radii(ii);
	currentCellImage = grayscale;
	currentCellImage(~mask) = 0;
    
    %All values within the threshold
	infection = currentCellImage > 0 & currentCellImage < infectionThreshold;
	
    %Update the mask- those pixels where parasite is present
	infectionMask = infectionMask | infection;
    isInfected(ii) = any(infection(:));
    

end


title(sprintf('%i of %i (%0.1f%%) Infected',sum(isInfected),numel(isInfected),100*sum(isInfected)/numel(isInfected)),'fontsize',14,'color','r');

%% For full dataset
togglefig('Detecting Infection',true)
refreshImages1;
drawnow

for x = 1:imgset.Count
    %Calling the function
    [percentInfected,centers,radx,isInfected,infectionMask] = ...
    testForInfection(getimage(ax(x)),targetimage,infectionThreshold,detectCircles);

    %Title of each image
    title(ax(x),['Percentage Infection: ', num2str(percentInfected,2),' (' num2str(sum(isInfected)),' of ' num2str(numel(isInfected)) ')']);

    %Construct circles around all cells
    viscircles(ax(x),centers,radx,'edgecolor','b')



    drawnow
end



