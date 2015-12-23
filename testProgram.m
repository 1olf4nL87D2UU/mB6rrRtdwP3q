clc
clear
close all;

img=imread('M-011-03.bmp');
img2=imread('M-011-02.bmp');
img3=imread('M-012-02.bmp');

%Calcolo features vector
fV1 = faceRecognition (img);
fV2 = faceRecognition (img2);
fV3 = faceRecognition (img3);

showResults(fV1, fV2, true);
showResults(fV1, fV3, false);
showResults(fV2, fV3, false);
