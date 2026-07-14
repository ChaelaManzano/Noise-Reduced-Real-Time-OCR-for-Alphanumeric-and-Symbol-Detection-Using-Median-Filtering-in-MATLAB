clc;
clear;
close all;

% =========================
% 📂 LOAD IMAGE
% =========================
[file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp'}, 'Select Image for OCR');

if isequal(file,0)
    disp('No image selected.');
    return;
end

img = imread(fullfile(path, file));

% =========================
% 🧠 PREPROCESSING (ACCURACY BOOST)
% =========================
if size(img,3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end

gray = imadjust(gray);                          % contrast boost
gray = medfilt2(gray, [3 3]);                  % noise removal
gray = imsharpen(gray);                        % sharpen text

bw = imbinarize(gray, 'adaptive', ...
    'ForegroundPolarity','dark', ...
    'Sensitivity', 0.45);

% =========================
% 🔍 OCR PROCESS
% =========================
results = ocr(bw);

textOutput = strtrim(results.Text);

if isempty(textOutput)
    textOutput = "No text detected.";
end

% =========================
% 🖼 SHOW ORIGINAL IMAGE
% =========================
figure('Name','Original Image');
imshow(img);
title('Original Image');

% =========================
% 🧪 SHOW PROCESSED IMAGE
% =========================
figure('Name','Processed Image');
imshow(bw);
title('Preprocessed Image for OCR');

% =========================
% ✍️ FORMATTED TEXT OUTPUT
% =========================
figure('Name','OCR Text Result');
axis off;

lines = splitlines(textOutput);
y = 0.95;

for i = 1:length(lines)
    text(0.05, y, lines{i}, ...
        'FontSize', 12, ...
        'Interpreter', 'none');
    y = y - 0.05;
end

title('Extracted Text');

% =========================
% 📦 COMMAND WINDOW OUTPUT
% =========================
disp('================ OCR RESULT ================');
disp(textOutput);

% =========================
% 🟩 WORD BOUNDING BOX VISUALIZATION
% =========================
figure('Name','Detected Words');
imshow(img);
title('OCR Word Detection');
hold on;

if isfield(results, 'WordBoundingBoxes')
    boxes = results.WordBoundingBoxes;

    for i = 1:size(boxes,1)
        rectangle('Position', boxes(i,:), ...
            'EdgeColor','g', ...
            'LineWidth',1.5);
    end
else
    disp('WordBoundingBoxes not available in this MATLAB version.');
end

hold off;

% =========================
% 💾 SAVE TEXT TO FILE
% =========================
fileID = fopen('OCR_Output.txt','w');
fprintf(fileID, '%s', textOutput);
fclose(fileID);

disp('Saved: OCR_Output.txt');