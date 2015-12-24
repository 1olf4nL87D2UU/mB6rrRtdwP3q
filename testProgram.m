% Questo Programma di Test utilizza le funzioni faceRecognition e
% showResults per comparare volti contenuti in un database di test di
% immagini  

clc;
clear;
close all;

I1=imread('M-011-03.bmp');
I2=imread('M-011-02.bmp');
I3=imread('M-012-02.bmp');
I4=imread('Test_Viola-Jones.jpg');

%Calcolo Features Vector
fV1 = faceRecognition (I1);
fV2 = faceRecognition (I2);
fV3 = faceRecognition (I3);
%Test che la detection lavori correttamente per immagini diverse da quelle
%del database di test fornito
fV4 = faceRecognition (I4);

%Visualizzazione distanze e grafico dell'errore quadratico 
showResults(fV1, fV2, true);
showResults(fV1, fV3, false);
showResults(fV2, fV3, false);
%Come ci si aspetta la distanza tra un'immagine del database di test e una
%ottenuta in altra maniera è grande a causa delle condizioni differenti di
%cattura
showResults(fV1, fV4, false);
