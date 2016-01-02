%%Gruppo 03 - Corso di Biometria e Sicurezza 2015 - Progetto FaceRecognition

% Questo Programma di Test utilizza le funzioni faceRecognition e
% showResults per comparare volti. La comparazione è possibile sia su volti
% presenti nel Database di Test che su Immagini qualsiasi contenenti volti.
% Nel primo caso la fase di Detection-Ridimensionamento non è eseguita in 
% quanto le immagini rappresentano già dei primi piani ravvicinati (ed 
% effettuando una detection si è riscontrato un calo del 
% potere discriminante dell'algoritmo). Nel secondo caso, invece, le
% immagini non contengono solo un volto, e perciò il passo di Detection è
% eseguito. L'unica limitazione in tal caso risiede nel fatto che l'immagine deve 
% contenere un solo invidivuo/volto, in quanto le specifiche fornite per il
% programma prevedono che sia processato un viso per volta.
% Per i dettagli visionare i file del Programma.

clc;
clear;
close all;

I1=imread('M-011-01.bmp');
I2=imread('M-011-02.bmp');
I3=imread('M-012-02.bmp');
I4=imread('Test_Viola-Jones.jpg');

%Calcolo Features Vector
fV1 = faceRecognition (I1);
fV2 = faceRecognition (I2);
fV3 = faceRecognition (I3);
%Test per verificare che la Detection lavori correttamente per immagini diverse da quelle
%del database di test fornito (Detection e Ridimensionamento)
fV4 = faceRecognition (I4);

%Visualizzazione distanze e grafico dell'errore quadratico 
showResults(fV1, fV2, true);
showResults(fV1, fV3, false);
showResults(fV2, fV3, false);
%Come ci si aspetta la distanza tra un'immagine del database di test e una
%ottenuta in altra maniera è grande a causa delle condizioni differenti di
%cattura
showResults(fV1, fV4, false);
