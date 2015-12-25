function []= showResults(fV1, fV2, samePerson)
%% Visualizzazione dati di confronto tra due vettori di feature fV1 e fV2
%  Il parametro bool samePerson ha la funzione di guidare la stampa dei
%  risultati: se samePerson vale true allora fV1 e fV2 sono vettori
%  estratti da immagini relative allo stesso individuo, altrimenti
%  appartengono a individui diversi

distancesfV1_fV2= getDistances(fV1, fV2);

if samePerson
    s='(   Same Person  )';
else
    s='(Different Person)';
end

fprintf('Photo1 vs Photo2 %s--Euclidean= %.6f  CityBlock= %.6f  Squared Error Mean= %.6f \n\n', s, distancesfV1_fV2.Euclidean, distancesfV1_fV2.CityBlock, distancesfV1_fV2.SquaredErrorMean);


figure
bar([(fV1-fV2).^2]', 1, 'hist')
ylim([0 0.1])
title('Squared error of LBP Histograms')
xlabel('LBP Histogram Bins')

legend(strcat('Photo1 vs Photo2 ', s))




