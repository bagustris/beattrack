function [mainscore, backupscores]= beatEvaluator(detections,annotations)

%  function [mainscore, backupscores]= beatEvaluator(detections,annotations)
%   
%  Description:
%  Calculate the continuity based accuracy values as used in (Hainsworth, 2004) and (Klapuri et al, 2006)
%   
%  Inputs: 
%  detections - sequence of estimated beat times (in seconds)
%  annotations - sequence of ground truth beat annotations (in seconds)
%   
%  Ouputs: 
%  mainscore - continuity not required at allowed metrical levels (amlT)
%  backupscores - the remaining continuity conditions, to be used for
%  tiebreaking (amlc, cmlt, cmlc). 
%
%  References:
%
%  S. Hainsworth, "Techniques for the automated analysis of musical audio,"
%  Ph.D. dissertation, Department of Engineering, Cambridge University,
%  2004.
%
%  A. P. Klapuri, A. Eronen, and J. Astola, "Analysis of the meter of
%  acoustic musical signals," IEEE Transactions on Audio, Speech and
%  Language Processing, vol. 14, no. 1, pp. 342-355, 2006.
%
%  M. E. P. Davies, N. Degara and M. D. Plumbley. "Evaluation Methods for
%  Musical Audio Beat Tracking Algorithms," Technical Report C4DM-TR-09-06,
%  Queen Mary University of London, Centre for Digital Music, 8 October
%  2009.
%
%  S. Boeck, F. Korzeniowski, J. Schluter, F. Krebs, G. Widmer "madmom: a
%  new Python Audio and Music Signal Processing Library,"
%  https://arxiv.org/pdf/1605.07008.pdf
%
%
%  This provides near identical output to Sebastian Boeck's madmom evaluation 
%  code in python: (expect that this implementation allows a 5s start up
%  period): https://github.com/CPJKU/madmom
%
%
%  (c) 2016 Matthew Davies, INESC TEC

% set up the parameters
% start up period
minBeatTime = 5;
% size of tolerance window for beat phase in continuity based evaluation
phase_tolerance = 0.175;
% size of tolerance window for beat period in continuity based evaluation
tempo_tolerance = 0.175;

% run the evaluation code
[cmlC,cmlT,amlC,amlT] = continuity(detections,annotations,tempo_tolerance,phase_tolerance,minBeatTime);

% use amlT as the overall score
mainscore = amlT;
backupscores = [amlC, cmlT, cmlC]; % in case of an amlT tie, we can use these as tie-breakers in this order.

function [cmlC,cmlT,amlC,amlT] = continuity(detections,annotations,tempo_tolerance,phase_tolerance,minBeatTime)

% put the beats and annotations into column vectors
annotations = annotations(:);
detections = detections(:);

% remove beats and annotations that are before minBeatTime
annotations(annotations<minBeatTime) = [];
detections(detections<minBeatTime) = [];

% now do some checks
if (and(isempty(detections),isempty(annotations)))
    cmlC = 1;
    cmlT = 1;
    amlC = 1;
    amlT = 1;
    return
end
if (or(isempty(detections),isempty(annotations)))
    cmlC = 0;
    cmlT = 0;
    amlC = 0;
    amlT = 0;
    return
end

if (length(annotations)<2)
    cmlC = [];
    cmlT = [];
    amlC = [];
    amlT = [];
    disp('At least two annotations (after the minBeatTime) are needed for continuity scores');
    return
end

if (length(detections)<2)
    cmlC = [];
    cmlT = [];
    amlC = [];
    amlT = [];
    disp('At least two detections (after the minBeatTime) are needed for continuity scores');
    return
end

if (or(tempo_tolerance<0,phase_tolerance<0))
    cmlC = [];
    cmlT = [];
    amlC = [];
    amlT = [];
    disp('Tempo and Phase tolerances must be greater than 0');
    return
end


% put the beats and annotations into column vectors and make sure they're
% in ascending order
annotations = sort(annotations(:));
detections = sort(detections(:));

% remove beats and annotations that are within the first 5 seconds
annotations(annotations<minBeatTime) = [];
detections(detections<minBeatTime) = [];

% interpolate annotations
doubleAnnotations = interp1(1:length(annotations),annotations,1:0.5:length(annotations),'linear');

% make different variants of annotations
% normal annotations
variations{1} = annotations;
% off-beats
variations{2} = doubleAnnotations(2:2:end);
% double tempo
variations{3} = doubleAnnotations;
% half tempo odd-beats (i.e. 1,3,1,3)
variations{4} = annotations(1:2:end);
% half tempo even-beat (i.e. 2,4,2,4)
variations{5} = annotations(2:2:end);

numVariations = size(variations,2);

% pre-allocate array to store intermediate scores of different variations
cmlCVec = zeros(1,numVariations);
cmlTVec = zeros(1,numVariations);

% loop analysis over number of variants on annotations
for j=1:numVariations,
    [cmlCVec(j),cmlTVec(j)] = ContinuityEval(detections,variations{j},tempo_tolerance,phase_tolerance);
end


% assign the accuracy scores
cmlC = cmlCVec(1);
cmlT = cmlTVec(1);
amlC = max(cmlCVec);
amlT = max(cmlTVec);

function [contAcc, totAcc] = ContinuityEval(detections,annotations,tempo_tolerance,phase_tolerance)
% sub-function for calculating continuity-based accuracy

if (length(annotations)<2)
    contAcc = 0;
    totAcc = 0;
    disp('At least two annotations are required to create an interval');
    return
end

if (length(detections)<2)
    contAcc = 0;
    totAcc = 0;
    disp('At least two detections are required to create an interval');
    return
end

% phase condition
correct_phase = zeros(1,max(length(annotations),length(detections)));
% tempo condition
correct_tempo = zeros(1,max(length(annotations),length(detections)));

for i=1:length(detections)
    
    % find the closest annotation and the signed offset
    [~,closest] = min(abs(annotations-detections(i)));
    signed_offset = detections(i)-annotations(closest);
    
    % first deal with the phase condition
    tolerance_window = zeros(1,2); % clear each time.
    if (closest==1) % first annotation, so use the forward interval
        annotation_interval = annotations(closest+1)-annotations(closest);
        tolerance_window(1) = -phase_tolerance*(annotation_interval);
        tolerance_window(2) = phase_tolerance*(annotation_interval);
    else % use backward interval
        annotation_interval = annotations(closest)-annotations(closest-1);
        tolerance_window(1) = -phase_tolerance*(annotation_interval);
        tolerance_window(2) = phase_tolerance*(annotation_interval);
    end
    
    % if the signed_offset is within the tolerance window range, then
    % the phase is ok.
    correct_phase(i) = and(signed_offset>=tolerance_window(1), signed_offset<=tolerance_window(2));
    
    % now look at the tempo condition
    % calculate the detection interval back to the previous detection
    % (if we can)
    if (i==1) % first detection, so use the interval ahead
        detection_interval = detections(i+1)-detections(i);
    else % we can always look backwards, which is where we should look for the period interval
        detection_interval = detections(i)-detections(i-1);
    end
    
    % find out if the relative intervals of detections to annotations are less than the tolerance
    correct_tempo(i) = ((abs(1-(detection_interval/annotation_interval))) <= (tempo_tolerance));
    
end

% now want to take the logical AND between correct_phase and correct_tempo
correct_beats = correct_phase & correct_tempo;

% we'll look for the longest continuously correct segment
% to do so, we'll add zeros on the front and end in case the sequence is
% all ones
correct_beats = [0 correct_beats(:)' 0];
% now find the boundaries
[~,d2,~] = find(correct_beats==0);
correct_beats = correct_beats(2:end-1);

% in best case, d2 = 1 & length(checkbeats)
contAcc = (max(diff(d2))-1)/length(correct_beats);
totAcc = sum(correct_beats)/length(correct_beats);

