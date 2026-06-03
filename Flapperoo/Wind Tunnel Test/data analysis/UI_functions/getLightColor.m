function lighter_color = getLightColor(original_color)
        original_color = hex2rgb(original_color);
                
        % Amount to lighten (0 = no change, 1 = completely white)
        fade_amount = 0.7;  % Adjust this value to control how light you want the color
        
        % White color in RGB
        white = [1, 1, 1];
        
        % Linearly interpolate between the original color and white
        lighter_color = (1 - fade_amount) * original_color + fade_amount * white;
    end