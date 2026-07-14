function LiveOCR_FINAL_withMedianFilter()
% GUI
fig = figure('Name','Live OCR','NumberTitle','off','Position',[50,50,1200,700],...
    'CloseRequestFcn',@onClose,'Color',[0.13 0.13 0.13]);
ax = axes('Parent',fig,'Position',[0.01,0.12,0.45,0.85],'Color','k'); axis(ax,'off');
title(ax,'Live Feed','Color',[0.8 0.8 0.8],'FontSize',10);

resultPanel = uipanel('Parent',fig,'Title','Detected Text','FontSize',11,'FontWeight','bold',...
    'Position',[0.48,0.12,0.27,0.85],'BackgroundColor',[0.10 0.10 0.10],'ForegroundColor',[0.9 0.9 0.9]);
resultText = uicontrol('Parent',resultPanel,'Style','edit','Max',20,'Min',1,'HorizontalAlignment','left',...
    'FontSize',12,'FontName','Courier New','BackgroundColor',[0.06 0.06 0.06],'ForegroundColor',[0.2 1 0.4],...
    'Units','normalized','Position',[0.02,0.02,0.96,0.96],'String','Point camera at text...');

confLabel = uicontrol('Parent',fig,'Style','text','String','Confidence: --','FontSize',10,...
    'ForegroundColor',[0.8 0.8 0.8],'BackgroundColor',[0.13 0.13 0.13],'HorizontalAlignment','left',...
    'Units','normalized','Position',[0.14,0.04,0.20,0.06]);
uicontrol('Parent',fig,'Style','text','String','● LIVE','FontSize',10,'FontWeight','bold',...
    'ForegroundColor',[0.2 0.9 0.3],'BackgroundColor',[0.13 0.13 0.13],'HorizontalAlignment','left',...
    'Units','normalized','Position',[0.01,0.04,0.12,0.06]);

uicontrol('Parent',fig,'Style','pushbutton','String','Save Result','FontSize',10,'FontWeight','bold',...
    'BackgroundColor',[0.15 0.55 0.95],'ForegroundColor','white','Units','normalized','Position',[0.48,0.03,0.13,0.07],...
    'Callback',@onSave);
uicontrol('Parent',fig,'Style','pushbutton','String','Reset Result','FontSize',10,'FontWeight','bold',...
    'BackgroundColor',[0.85 0.35 0.35],'ForegroundColor','white','Units','normalized','Position',[0.63,0.03,0.13,0.07],...
    'Callback',@onReset);

% State
cams = webcamlist; if isempty(cams), errordlg('No webcam detected!'); return; end
state.running = true; state.lastFrame = []; state.cam = webcam(cams{1}); state.frameCount = 0; guidata(fig,state);

% Loop
imH = []; processEvery = 15;
while ishandle(fig)
    state = guidata(fig); if ~state.running, break; end
    try frame = snapshot(state.cam); catch, pause(0.1); continue; end
    state.lastFrame = frame; state.frameCount = state.frameCount + 1;
    if isempty(imH) || ~isvalid(imH), imH = imshow(frame,'Parent',ax); else, set(imH,'CData',frame); end
    if mod(state.frameCount,processEvery)==0
        [detectedText,conf] = runOCR(frame,false);
        if ~isempty(detectedText), set(resultText,'String',detectedText); end
        updateConf(confLabel,conf);
    end
    guidata(fig,state); drawnow limitrate;
end

% Callbacks
    function onSave(~,~)
        choice = questdlg('Save Options','Save Result','Save Text','Save Window Image','Cancel','Save Text');
        switch choice
            case 'Save Text'
                txt = get(resultText,'String'); [file,path] = uiputfile('DetectedText.txt','Save OCR Text');
                if ischar(file), fid = fopen(fullfile(path,file),'w'); fprintf(fid,'%s\n',txt); fclose(fid); end
            case 'Save Window Image'
                frame = getframe(fig); [file,path] = uiputfile('OCR_Window.png','Save Window Image');
                if ischar(file), imwrite(frame.cdata,fullfile(path,file)); end
        end
    end
    function onReset(~,~)
        set(resultText,'String','Point camera at text...'); set(confLabel,'String','Confidence: --','ForegroundColor',[0.6 0.6 0.6]);
    end
    function onClose(~,~)
        s = guidata(fig); s.running = false; guidata(fig,s);
        try delete(s.cam); clear s.cam; end; delete(fig);
    end
end

% OCR Worker
function [detectedText,conf] = runOCR(frame,highQuality)
detectedText = ''; conf = 0; gray = rgb2gray(frame);
gray = medfilt2(gray,[3 3]);  
if highQuality, gray = imresize(gray,3.0,'bicubic'); gray = adapthisteq(gray);
else, gray = imresize(gray,1.5,'bilinear'); end
charSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,;:!?@#$%^&*()-_=+[]{}|\/''"`~';
results = ocr(gray,'CharacterSet',charSet);
if isfield(results,'TextLines') && ~isempty(results.TextLines)
    detectedText = strjoin({results.TextLines.Text},newline);
else, detectedText = strtrim(results.Text); end
if ~isempty(results.CharacterConfidences)
    validConf = results.CharacterConfidences(~isnan(results.CharacterConfidences));
    if ~isempty(validConf), conf = mean(validConf)*100; end
end
end

% Confidence Update
function updateConf(confLabel,conf)
if conf<=0, set(confLabel,'String','Confidence: --','ForegroundColor',[0.6 0.6 0.6]); return; end
confStr = sprintf('Confidence: %.1f%%',conf);
if conf>=75, color=[0.3 1 0.4]; elseif conf>=50, color=[1 0.8 0.2]; else, color=[1 0.35 0.35]; end
set(confLabel,'String',confStr,'ForegroundColor',color);
end
