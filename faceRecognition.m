clc
clear
img=imread('M-001-01.bmp');
img2=imread('M-001-02.bmp');
img3=imread('M-002-01.bmp');

% Viola-Jones [Per ora lo saltiamo finchè non chiediamo al tutor, è un passaggio inutile date le immagini di input]
%  detector = vision.CascadeObjectDetector('ClassificationModel', 'FrontalFaceLBP') ;
%  
%  bboxes = step(detector,img);
%  
%  IFaces = insertObjectAnnotation(img, 'rectangle', bboxes, 'Face');
%  figure, imshow(IFaces), title('Detected faces');

%Metodo che chiama efficientLBP che probabilmente non ci servirà
%lbpCall();

%Funzione presente in matlab 2015, ci basta prendere il codice, capirlo e
%commentarlo e abbiamo finito
features1 = extractLBPFeatures(img); 
features2 = extractLBPFeatures(img2); 
features3 = extractLBPFeatures(img3); 

%giusto per provare la distanza, distanza per stesso individuo
norm(features1-features2)

%giusto per provare la distanza, distanza per individui diversi
norm(features1-features3)