if (wrapper.isFeatureSupportedBoardTemperature(spectrometerIndex) == 1)
% Board temperature feature is supported by this spectrometer
boardTemperature =wrapper.getFeatureControllerBoardTemperature(spectrometerIndex);
temperatureCelsius = boardTemperature.getBoardTemperatureCelsius();
disp(sprintf('Spectrometer Board Temperature = %1.2f °C',temperatureCelsius))
else
    disp('board temperature feature not supported')
end