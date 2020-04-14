ax = gobjects(imgset.Count,1);
for ii = 1:imgset.Count
	ax(ii) = subplot(floor(sqrt(imgset.Count)),ceil(sqrt(imgset.Count)),ii);
	currName = imgset.ImageLocation{ii};
	imshow(imread(currName))
	[~,currName] = fileparts(currName);%Strip out extensions
	title([num2str(ii),') ' currName],...
		'interpreter','none','fontsize',7);
end
