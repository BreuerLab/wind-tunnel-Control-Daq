function dictate(text)
    NET.addAssembly('System.Speech');
    obj = System.Speech.Synthesis.SpeechSynthesizer;

    % % Check which voices are available
    % voices = obj.GetInstalledVoices;
    % for i = 1 : voices.Count
    %     voice = Item(voices,i-1);
    %     voice.VoiceInfo.Name
    % end

    obj.SelectVoice('Microsoft David Desktop')
    obj.Volume = 100;  % Set the volume level (0-100)
    obj.Rate = 0;      % Set the speaking rate (-10 to 10)
    obj.Speak(text);
end