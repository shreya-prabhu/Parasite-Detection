function [pctInfection,centers,radii,isInfected,infectionMask] = testForInfection(testImage,targetImage,infectionThreshold,detectCircles)

if ischar(testImage)
	testImage = imread(testImage);
end
matchedImage = imhistmatch(testImage,targetImage);
[centers, radii, metric] = detectCircles(matchedImage);
infectionMask = false(size(matchedImage(:,:,1)));

%% So which cells are infected?
isInfected = false(numel(radii),1);
x = 1:size(testImage,2);
y = 1:size(testImage,1);
[xx,yy] = meshgrid(x,y);

for ii = 1:numel(radii)
	diameter = radii(ii)*2;
	currentCellImage = rgb2gray(matchedImage);
	mask = hypot(xx - centers(ii,1), yy - centers(ii,2)) <= radii(ii);
	currentCellImage(~mask) = 0;
	infection = currentCellImage > 0 & currentCellImage < infectionThreshold;
	isInfected(ii) = any(infection(:));
	infectionMask = infectionMask | infection;
end
pctInfection = sum(isInfected)/numel(radii);