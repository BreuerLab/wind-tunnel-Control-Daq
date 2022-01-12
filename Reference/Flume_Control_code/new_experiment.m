function path = new_experiment(varargin)
% Autmatically generates new experiment folder given experiment name. If no
% argument is given, reuses last used experiment name.  Number of foils
% input optional (uses last known configuration) -Miller
global fname Number_of_foils exp_name

switch nargin
    case 0
        experiment_name = exp_name;
        Number_of_foil = Number_of_foils;
    case 1 
        Number_of_foil = Number_of_foils;
        exp_name = varargin{1};
    case 2
        Number_of_foils = varargin{2};
        exp_name = varargin{1};        
end
    

fname = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\',num2str(Number_of_foils),'foil\',exp_name];
Date  = date;
Time = clock;
fname = [fname,'_',Date,'_',num2str(Time(4)),'_',num2str(Time(5)),'_',num2str(round(Time(6)))];
path = fname;
mkdir(fname)
mkdir([fname,'\code'])
mkdir([fname,'\data'])
mkdir([fname,'\analysis'])

copyfile('C:\Users\ControlSystem\Documents\vertfoil\Control_code\', [fname,'\code'])

end
