function fig = togglefig(name, clearfig)
% FIG = TOGGLEFIG(NAME, CLEARFIG)
% Finds and activates, or creates, figure with user-specified name.
%
% INPUTS:
%    NAME: A string. If no name is provided, creates figure named
%    "untitledn" (where n is incremented to result in a unique name).

if ~nargin
    tmp = get(findall(0,'type','figure'),'name');
    if isempty(tmp)
        tmp = 0;
    elseif ischar(tmp) %one match
        tmp = 1;
    else %should be a cell array of matches
        tmp = sum(cell2mat(regexp(tmp,'untitled')));
    end
    name = ['untitled',num2str(tmp+1)];
    clearfig = 0;
elseif nargin == 1
    clearfig = 0;
end

fig = findall(0,'type','figure','name',name);
if isempty(fig)
    fig = figure('numbertitle','off','name',name);shg;
    %tofront(name);
else
    %figure(fig);
    set(0,'currentfigure',fig)
end
drawnow;%This is necessary in R14b+ because graphics changes no longer ensure that events are complete before the figure is called
%shg;
figure(fig)
if clearfig
    clf
end
% If no output was requested, none should be generated
if ~nargout
    clear fig
end


end
