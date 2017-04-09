function rd_demoImageSequenceRivalry

% Demo for Image Sequence Rivalry experiment. Purpose is to teach
% subjects the key mappings. Subjects have unlimited time to correctly
% identify each image.
%
% Subjects perform an image identification task on each image.
%
% Rachel Denison
% February 2013

location = input('location (laptop, testingRoom): ','s');

global pixelsPerDegree;
global spaceBetweenMultiplier;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up paths. Depends on testing location.
% data path
dataDirectoryPath = 'data/';
% displayParams file path
targetDisplayPath = 'displays/';
% image path
imageDirectoryPath = 'images/';
% image file names lists path
typeListDirectoryPath = 'image_type_lists/';

% displayParams file
targetDisplayName = 'Minor_582J_rivalry'; % 60 Hz frame rate

typeFile = 'TYPES_20110325_6Cat.mat'; % 4 hand-picked image sets

% set keypad device numbers
devNums.Keypad = -1;

% 12 images
responseKeys = {'a','z','s','x','d','c','h','n','j','m','k','<'}; % these are our default keys
responseNames = {'young man','old man','black girl','white woman',...
    'tiger','monkey','kiwi','cherries','escalator','museum',...
    'field','palm trees'};

% run parameters
nImageBs = 4;
nRepsB = 2; % determines the number of trials % 18 for actual expt

imageTypeNames = {'b','a1','a2','a3','c1','c2','c3','c4','d','z1','z2','z3'}';
lowerbounds = [(0:100:800) (1100:100:1300)]';
upperbounds = lowerbounds + 101;

% Sound for starting trials
v = 1:2000;
soundvector = 0.25 * sin(2*pi*v/30); %a nice beep at 2kH samp freq

% Response error sound
v = 1:1000;
errorsound = 0.25 * sin(10*pi*v/30);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spaceBetweenMultiplier = 3;

Screen('Preference', 'VisualDebuglevel', 3); % replaces startup screen with black display
screenNumber = max(Screen('Screens'));

window = Screen('OpenWindow', screenNumber);
black = BlackIndex(window);  % Retrieves the CLUT color code for black.
white = WhiteIndex(window);  % Retrieves the CLUT color code for white.
gray = (black + white) / 2;  % Computes the CLUT color code for gray.

Screen('TextSize', window, 60);

switch location
    case 'testingRoom'
        targetDisplay = loadDisplayParams_OSX('path',targetDisplayPath,'displayName',targetDisplayName,'cmapDepth',8);
        pixelsPerDegree = angle2pix(targetDisplay, 1); % number of pixels in one degree of visual angle
        Screen('LoadNormalizedGammaTable', targetDisplay.screenNumber, targetDisplay.gammaTable);
    otherwise
        fprintf('\nNot setting pixels per degree or loading gamma table.\n\n')
end

fprintf('Welcome to the Image Sequence Rivalry DEMO\n\n');
fprintf('Be sure to turn manually turn off console monitor before testing!\n\n')

KbName('UnifyKeyNames');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keyboard mapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for key = 1:length(responseKeys)
    responseKeyCode (1:256) = 0;
    responseKeyCode (KbName (responseKeys(key))) = 1; % creates the keyCode vector
    
    response = 1;
    while ~isempty (response)
        fprintf('The key assigned for %s is: %s \n', responseNames{key}, KbName(responseKeyCode));
        response = input ('Hit "enter" to keep this value or a new key to change it.\n','s');
        if ~isempty(response) && str2num(response)<10 % make sure response key is on the key pad
            responseKey = response;
            responseKeyCode (1:256) = 0;
            responseKeyCode (KbName (responseKey)) = 1; % creates the keyCode vector
        end
    end
    
    responseKeyNumbers(:,key) = find(responseKeyCode);
end

fprintf('Key numbers: %d %d %d %d %d %d %d %d %d %d %d %d\n\n', responseKeyNumbers)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect subject and session info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subjectNumber = str2double(input('\nPlease input the subject number: ','s'));
runNumber = str2double(input('\nPlease input the run number: ','s'));
subjectID = sprintf('s%02d_run%02d', subjectNumber, runNumber);
timeStamp = datestr(now);

% Show the gray background, return timestamp of flip in 'vbl'
Screen('FillRect',window, gray);
vbl = Screen('Flip', window);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load image file lists by type (TYPES). types are b, a1, a3, etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load TYPES
typeListFileName = [typeListDirectoryPath typeFile];
load(typeListFileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Store experiment parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
expt.timeStamp = timeStamp;
expt.subject = subjectNumber;
expt.run = runNumber;
expt.nImageBs = nImageBs;
expt.nRepsB = nRepsB;

expt.imageTypeNames = imageTypeNames;
expt.lowerbounds = lowerbounds;
expt.upperbounds = upperbounds;
expt.responseNames = responseNames;
expt.responseKeyNumbers = responseKeyNumbers;

stim.TYPES = TYPES;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start the experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataFileName = [dataDirectoryPath subjectID '_DemoImageSequenceRivalry_', datestr(now,'ddmmmyyyy')];

DrawFormattedText(window, 'Preparing stimuli ...', 0, 'center', [255 255 255]);
Screen('Flip', window);
tic

% make image sequence for this block
imageSequence = rd_makeDemoImageSequence(nImageBs, nRepsB);

% get image labels for this image sequence
imageSequenceImageNames = getImageLabels(imageSequence, TYPES, getImageKey);

clear imageTextures imagetexs

% build image texture sequence
for trial = 1:length(imageSequence)
    
    image = imageSequence(trial);
    imageType = imageTypeNames{(image > lowerbounds) & (image < upperbounds)};
    imageNumber = rem(image, 100);
    imageFileName = TYPES.(imageType).imageFiles(imageNumber).name;
    
    imageFilePathLeft = [imageDirectoryPath imageFileName];
    imageFilePathRight = imageFilePathLeft; % same image on both sides
    
    [imageTexture imagetex] = rd_makeRivalryImageTextureRGB(window, imageFilePathLeft, imageFilePathRight);
    
    imageTextures{trial} = imageTexture; % a stack of image matrices (eg. imagesc(imageTexture))
    imagetexs(trial,1) = imagetex; % a list of texture pointers to said image matrices
    
end

% present alignment targets and wait for a keypress
toc
presentAlignmentTargets(window, devNums);

% make a beep to say we're ready
sound (soundvector, 8000);


datestr(now)

% present image sequence for this block
[responseArray.keyTimes responseArray.keyEvents responseArray.responseAcc stim.timing] = ...
    rd_presentRivalryTrainingImageSequenceDemo(window, imagetexs, ...
    imageSequenceImageNames, ...
    responseNames, responseKeyNumbers, devNums, errorsound);


stim.sequence = imageSequence;
stim.imageNames = imageSequenceImageNames;

% save data
save(dataFileName, 'subjectID', 'timeStamp', 'responseArray', 'stim', 'expt');

%%%%%%%%%%%%%
% Clean up
%%%%%%%%%%%%%
Screen('CloseAll');
ShowCursor;


