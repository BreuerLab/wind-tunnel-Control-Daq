clear
close all
% The point of this file is to look at what the typical values are for R
% (wing flapping lever arm) and theta_m (wingbeat amplitude) for a variety
% of birds, so we can use our simplified model to assess whether wingbeat
% frequency or wind speed changes will affect pitch stiffness more.

% Of course, this assumes that bird flight will perform similarly to this
% robot which uses rectangular rigid wings with a single DoF with a symmetric motion.
% Also assumes COM is located at LE

% Calculation of mins and max unrealistic since min of some variables can
% only occur when other variables have certain values, not a true min. For
% example min(amp) occurs at min(speed), but freq is high at min(speed) and
% span is highest at min(speed)

names = [];
scaleFactorsMin = [];
scaleFactorsMax = [];
scaleFactorsMean = [];
genFactorsMin = [];
genFactorsMax = [];
genFactorsMean = [];
St_min = [];
St_max = [];
St_mean = [];
coeff = [];

% Ducci 2021
% Parameters for Ibis
% Got variation of speed from Portugal Nature paper supplementary info
n = "Ibis"
span = 1.35; % wingspan, meters
R = span/2;
amp = deg2rad(42); % wingbeat amplitude
R*amp
freq = 4; % wingbeat frequency, Hz
speed = [13 18]; % m/s, from equilibrium flight condition

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);
[fl_min, fl_max, fl_mean] = getFlappingContrib(Stm, StM, Ste);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

% amp = linspace(0,pi/2,10);
% St = linspace(St_min,St_max,20);
l = R;
expr = besselj(0,amp) / (((2*(pi^2))/3) * ((l^2 - 3*l*R + 3*R^2)/(R^2))...
                        * (besselj(1,amp)/amp));
coeff = [coeff mean(expr,"all")];
% y = St.^2 ./ (St.^2 + expr);
% 
% figure
% plot(St, y)

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% https://journals.biologists.com/jeb/article/204/15/2741/32794/Flight-kinematics-of-the-barn-swallow-Hirundo
% Parameter for Swallow
n = "Swallow"
span = [0.32, 0.26]; % wingspan at midstroke at 4 m/s and 14 m/s, meters
R = span/2;
amp = deg2rad([70, 120] / 2);
R.*amp
freq = [7, 9];
speed = [4, 14];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% https://journals.biologists.com/jeb/article/198/6/1259/6940/Neuromuscular-Control-and-Kinematics-of
% Parameters for Starling
n = "Starling"
span = 0.35; % wingspan at midstroke at 4 m/s, meters
R = span/2;
amp = deg2rad([95, 105]/2); % wingbeat amplitude
R*amp
freq = [13 16];
speed = [8 18];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% https://journals.biologists.com/jeb/article/211/5/717/18121/Vortex-wake-and-flight-kinematics-of-a-swift-in
% Parameters for Swift
n = "Swift"
span = 0.38; % wingspan at midstroke at 4 m/s, meters
R = span/2;
amp = deg2rad([110 115] / 2); % wingbeat amplitude
R.*amp
freq = [8.2 9];
speed = [8 9.2];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% https://journals.biologists.com/jeb/article/49/3/527/21322/Power-Requirements-for-Horizontal-Flight-in-the
% Parameters for Pigeon, ignoring hovering case
n = "Pigeon"
span = 0.6; % wingspan at midstroke at 4 m/s, meters
R = span/2;
amp = deg2rad([160 200] / 2); % wingbeat amplitude
R.*amp
freq = [5.2 6.3];
speed = [8 18];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% https://royalsocietypublishing.org/doi/epdf/10.1098/rstb.2015.0385
% In both cases amplitude is highly speed dependent and wingpsan as defined
% by span ratio. Values estimated from table 2
% Bats: M. velifer
n = "M. velifer"
R = 0.127; % max half wingspan
amp = deg2rad([63 87] / 2); % wingbeat amplitude at flight speeds between 5.5 and 7
R.*amp
freq = [8.6 9.6];
speed = [4 8];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% Bat: T. brasiliensis
n = "T. brasiliensis"
R = 0.142; % wingspan in meters
amp = deg2rad([64 82] / 2); % wingbeat amplitude at flight speeds between 5.5 and 7
R.*amp
freq = [8.5 10.8];
speed = [4 8];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% House martin
% https://royalsocietypublishing.org/doi/epdf/10.1098/rsif.2007.0215
n = "House martin";
amp = 0.038*[2.5 2.7]; % multiplied by chord length
R = 1; % just a constant since R already included in amp
freq = [8 12];
speed = [4 10];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% Geese
% https://www.cambridge.org/core/journals/aeronautical-journal/article/experimental-and-numerical-study-of-the-flight-of-geese/0C23EA6C2A179DB709E8A1AEA8C7B26A
n = "Barnacle Geese";
amp = [0.36 0.58] / 2; % in meters
R = 1; % just a constant since R already included in amp
freq = [4.7 5.4];
speed = [14 18];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

% Brooke bat depilation paper not going to work since they give amplitude
% of wrist motion rather than amplitude of wingtip motion

% -------------------------------------------------------------------

% Cybird P1
% "Experimental study on the flight dynamics of a bioinspired ornithopter:
% Free flight testing and wind tunnel testing"
n = "Cybird P1"
span = 0.74;
R = span/2;
amp = deg2rad(55 / 2); % wingbeat amplitude, really from -15 to 30 deg, but how would I treat that
R*amp
freq = [5 11];
speed = [7.25 10];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff

% More or less the same as the Cybird P2
% from "Flight Dynamics of a Flapping-Wing Air Vehicle"
% in that paper they just say wingbeat amplitude 55 in paper
% -------------------------------------------------------------------

% MetaBird
n = "MetaBird"
span = 0.33;
R = span/2;
amp = deg2rad(25); % wingbeat amplitude, roughly +41 to -9 from high speed video at a slight angle
R*amp
freq = [5 11];
speed = [3 6];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% -------------------------------------------------------------------

n = "Flapperoo"
R = 0.313;
amp = deg2rad(30); % wingbeat amplitude
R*amp
freq = [2, 5];
speed = [3, 6];

[sm, sM, se] = getScaleFactors(R, amp);
[gm, gM, ge] = getGenFactors(R, amp, freq, speed);
[Stm, StM, Ste] = getSt(R, amp, freq, speed);

[names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste);

R = R(:);
l = R;
expr = besselj(0,amp) ./ (((2*(pi^2))/3) .* ((l.^2 - 3*l.*R + 3*R.^2)./(R.^2))...
                        .* (besselj(1,amp)./amp));
coeff = [coeff mean(expr,"all")];

clearvars -except names scaleFactorsMin scaleFactorsMax scaleFactorsMean...
    genFactorsMin genFactorsMax genFactorsMean St_min St_max St_mean coeff
% ------------------------------------------------

fin = [names; St_min; St_max; St_mean];

% ------------------------------------------------
function factor = calcFactor(R, amp)
    factor = 4.25*(2*R*amp)^2;
end

function [names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin,...
          genFactorsMax, genFactorsMean, St_min, St_max, St_mean] = ...
    addToLists(names, scaleFactorsMin, scaleFactorsMax, scaleFactorsMean, genFactorsMin, genFactorsMax, genFactorsMean,...
               St_min, St_max, St_mean, n, sm, sM, se, gm, gM, ge, Stm, StM, Ste)
    names = [names n];
    scaleFactorsMin = [scaleFactorsMin sm];
    scaleFactorsMax = [scaleFactorsMax sM];
    scaleFactorsMean = [scaleFactorsMean se];
    genFactorsMin = [genFactorsMin gm];
    genFactorsMax = [genFactorsMax gM];
    genFactorsMean = [genFactorsMean ge];
    St_min = [St_min Stm];
    St_max = [St_max StM];
    St_mean = [St_mean Ste];
end

function [sm, sM, se] = getScaleFactors(R, amp)
    % Old method, before 02/15/2026
    % sm = calcFactor(min(R), min(amp));
    % sM = calcFactor(max(R), max(amp));
    % se = calcFactor(mean(R), mean(amp));

    [Rg, Ag] = ndgrid(R, amp);
    scale = 4.25*(2*Rg.*Ag).^2;
    se = mean(scale,"all");
    sM = max(scale, [], "all");
    sm = min(scale, [], "all");
end

function [gm, gM, ge] = getGenFactors(R, amp, freq, speed)
    [sm, sM, se] = getScaleFactors(R, amp);

    % gm = sm*(min(freq) / max(speed))^2;
    % gM = sM*(max(freq) / min(speed))^2;
    % ge = se*(mean(freq) / mean(speed))^2;

    gm = ((sm*(min(freq))^2) / (sm*(min(freq))^2 + (max(speed))^2)) * 100;
    gM = ((sM*(max(freq))^2) / (sM*(max(freq))^2 + (min(speed))^2)) * 100;
    ge = ((se*(mean(freq))^2) / (se*(mean(freq))^2 + (mean(speed))^2)) * 100;
end

function [St_min, St_max, St_mean] = getSt(R, amp, freq, speed)
    [Rg, Ag, Fg, Sg] = ndgrid(R, amp, freq, speed);
    St = (2 .* Rg .* Ag .* Fg) ./ Sg;
    St_mean = mean(St,"all");
    St_max = max(St, [], "all");
    St_min = min(St, [], "all");
end

function [fl_min, fl_max, fl_mean] = getFlappingContrib(St_min, St_max, St_mean)
    St = [St_min, St_max, St_mean];
    fl = (St.^2) ./ (St.^2 + (1/4.25)) * 100; % expressed as percent
    fl_mean = mean(fl);
    fl_max = max(fl);
    fl_min = min(fl);
end