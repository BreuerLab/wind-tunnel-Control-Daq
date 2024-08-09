
% Create a UI figure
fig = uifigure('Name', 'Dual Slider Example', 'Position', [100, 100, 600, 150]);

% Create the minimum slider
minSlider = uislider(fig, 'Position', [150, 80, 300, 3], 'Limits', [0 100], ...
                     'Value', 20, 'ValueChangingFcn', @(sld, event) minSliderChanged(sld, event));

% Create the maximum slider
maxSlider = uislider(fig, 'Position', [150, 50, 300, 3], 'Limits', [0 100], ...
                     'Value', 80, 'ValueChangingFcn', @(sld, event) maxSliderChanged(sld, event));

% Store references to the sliders
minSlider.UserData.maxSlider = maxSlider;
maxSlider.UserData.minSlider = minSlider;

% Display the selected range
lbl = uilabel(fig, 'Position', [470, 65, 120, 30], 'Text', 'Range: 20 - 80');
minSlider.UserData.lbl = lbl;
maxSlider.UserData.lbl = lbl;

function minSliderChanged(sld, event)
    % Get the other slider
    maxSlider = sld.UserData.maxSlider;
    
    % Ensure the min slider does not cross the max slider
    if event.Value >= maxSlider.Value
        sld.Value = maxSlider.Value - 1;
    else
        sld.Value = event.Value;
    end
    
    % Update the display
    updateLabel(sld, sld.Value, maxSlider.Value);
end

function maxSliderChanged(sld, event)
    % Get the other slider
    minSlider = sld.UserData.minSlider;
    
    % Ensure the max slider does not cross the min slider
    if event.Value <= minSlider.Value
        sld.Value = minSlider.Value + 1;
    else
        sld.Value = event.Value;
    end
    
    % Update the display
    updateLabel(sld, minSlider.Value, sld.Value);
end

function updateLabel(sld, minVal, maxVal)
    % Update the label to display the selected range
    lbl = sld.UserData.lbl;
    lbl.Text = sprintf('Range: %d - %d', round(minVal), round(maxVal));
end