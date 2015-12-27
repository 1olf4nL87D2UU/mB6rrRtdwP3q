classdef managerLBP
    
    methods(Static)
        
        function [lbpHist] = LBPFeaturesExtractor(I, numNeighbors, radius, upright, cellSize)
            %% Estrazione di un Logical Binary Pattern(LBP) uniforme da un immagine in scala di grigio e restituzione di un vettore 1xN di features
            %  Uniforme:   ogni pattern binario locale ha al massimo 2 transizioni 1-a-0 o 0-a-1
            %
            %  L'algoritmo prevede l'utilizzo di interpolazione bilineare e di
            %  normalizzazione degli istrogrammi LBP
            %
            %  Parametri:
            %
            %  NumNeighbors     Numero di Pixel da considerare neighbors per
            %                   calcolare LBP localmente per ogni pixel. L'insieme dei neighbors
            %                   è selezionato in maniera circolare e simmetrica intorno al
            %                   pixel. Aumentare il numero di neighbors aggiunge dettaglio al
            %                   vettore di features, rendendolo più grande e più preciso.
            %                   Tuttavia utilizzando l'algoritmo per la Face Recognition è
            %                   preferibile non aumentare oltre 8 questo parametro, in quanto le
            %                   dimensioni del vettore crescono di molto e l'efficacia del
            %                   riconoscimento diminuisce.
            %
            %  Radius           La dimensione del raggio della circonferenza
            %                   che identifica i neighbors di un pixel. Aumentando il valore
            %                   vengono catturati dettagli su una superficie maggiore per ogni
            %                   pixel.
            %
            %  Upright          Valore logico che indica se è necessario
            %                   codificare informazioni relative all'invarianza alla rotazione o
            %                   meno. Per le immagini del Database di Test
            %                   questa caratteristica non è fondamentale,
            %                   ma in presenza di volti inclinati permette
            %                   risultati migliori
            %
            %  CellSize         Vettore di due elementi che definisce la
            %                   dimensione delle celle in cui viene divisa l'immagine. Su
            %                   ciascuna cella viene calcolato LBP per poi riportare ciascun
            %                   risultato a un vettore di features globale. Abbiamo riscontrato
            %                   buoni risultati dividendo l'immagine in 16 parti.
                   
            I = im2uint8(I);
            
            %   La chiamata a generateNeighborLocations genera due vettori x
            %   e y, ognuno contenent 8 elementi, rappresentanti le cordinate
            %   dei vicini di un pixel rispetto a quel pixel
            %   [Maggiori dettagli nei commenti della funzione]
            [x, y] = managerLBP.generateNeighborLocations(numNeighbors, radius);
                       
            %   La chiamata calcola gli offset e i pesi per
            %   l'interpolazione bilineare dei vicini di P
            %   [Maggiori dettagli nei commenti della funzione]   
            [offsets, weights] = managerLBP.createBilinearOffsets(x, y, numNeighbors);           
  
            if  ~upright
                %   Nel caso l'immagine non sia upright, vuol dire che ci
                %   possono essere degli elementi ruotati nell'immagine
                numBins = uint32(numNeighbors + 2);
                index   = uint32(0:numNeighbors);
            else
                %   Viceversa, l'immagine non presenta elementi ruotati
                numBins = uint32(numNeighbors*(numNeighbors-1) + 3);
                index   = uint32([0 1:numNeighbors:(numNeighbors*(numNeighbors-1)+1)]);
            end
                     
            [M, N] = size(I);
            
            %   Inizializza un Istogramma per le caratteristiche LBP che
            %   abbia numBins barre e dimensione basata sul numero di
            %   celle (calcolato tramite dimensione immagine e dimensione celle)
            lbpHist = managerLBP.initializeHist(cellSize, numBins, M, N);
            
            %   Calcolo delle massime cordinate tenendo conto della
            %   divisione in celle
            [xmax, ymax] = managerLBP.computeRange(cellSize, radius, M, N);
            
            invCellSize = 1./cellSize;
            
            %   Calcolo per eccesso del numero di byte necessari a salvare
            %   le caratteristiche di un "vicinato"
            %   Se il numero di vicini è 8, numBytes=1
            numBytes = ceil(numNeighbors/8);
            
            %   Fattore di scaling per convertire N byte in un float (Necessario per salvare LBP multy-byte)
            %   Se il numero di vicini è 8, scaling=1
            scaling  = 2.^((8*numBytes-8):-8:0);
            
            
            %   Ciclo sulle ascisse per valori da radius+1 a xmax.
            %   Nota: LBP calcolato solo sui pixel con distanza dal bordo
            %   maggiore di "radius"
            for x = ((radius+1):xmax)
                
                %   Calcolo dell'indice x della cella (relativo alla
                %   griglia)
                cx = floor((x-0.5) * invCellSize(2) - 0.5);
                
                % Calcolo dell'ordinata dell'origine della cella
                x0 = cellSize(2) * (cx + 0.5);
                
                % Calcolo dei pesi spaziali relativi alla ascissa del
                % pixel nella cella
                wx2 = ((x-0.5) - x0) * invCellSize(2);
                wx1 = 1 - wx2;
                
                cx = cx + 2; % indice x della cella aggiornato per le celle aggiunte sui bordi
                
                %   Ciclo sulle ordinate per valori da radius+1 a ymax.
                %   Nota: LBP calcolato solo sui pixel con distanza dal bordo
                %   maggiore di "radius" 
                for y = ((radius+1):ymax)
                    
                    %   Associa un valore decimale al vicinato corrente (ad esempio un intero tra 0-255 se numNeighbors=8)
                    lbp = managerLBP.computeMultibyteLBP(I, x, y, numNeighbors, numBytes, offsets, weights);
                    
                    %   Sulla base del valore decimale lbp precedentemente
                    %   calcolato, viene calcolato un nuovo valore che sia
                    %   uniforme: ogni pattern binario locale ha al massimo 2 transizioni 1-a-0 o 0-a-1
                    bin = managerLBP.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);  
                                  
                    %   Calcolo dell'indice y della cella (relativo alla
                    %   griglia)
                    cy = floor((y-0.5) * invCellSize(1) - 0.5);                    
                
                    % Calcolo dell'ordinata dell'origine della cella
                    y0 = cellSize(1) * (cy + 0.5);                    
                
                    % Calcolo dei pesi spaziali relativi alla ordinata del
                    % pixel nella cella
                    wy2 = ((y-0.5) - y0) * invCellSize(1);
                    wy1 = 1 - wy2;
                    
                    cy = cy + 2; % indice y della cella aggiornato per le celle aggiunte sui bordi
                    
                    % Calcolo dei pesi per ciascuna barra dell'istogramma
                    wx1y1 = wx1 * wy1;
                    wx2y2 = wx2 * wy2;
                    wx1y2 = wx1 * wy2;
                    wx2y1 = wx2 * wy1;
                    
                    lbpHist(bin, cy      , cx)     = lbpHist(bin, cy     , cx)     + wx1y1;
                    lbpHist(bin, cy + 1  , cx)     = lbpHist(bin, cy + 1 , cx)     + wx1y2;
                    lbpHist(bin, cy      , cx + 1) = lbpHist(bin, cy     , cx + 1) + wx2y1;
                    lbpHist(bin, cy + 1  , cx + 1) = lbpHist(bin, cy + 1 , cx + 1) + wx2y2;
                    
                end
            end
            
            % Rimozione delle celle aggiunte ai bordi
            lbpHist = lbpHist(:, 2:end-1, 2:end-1);
            
 
            lbpHist = bsxfun(@rdivide, lbpHist, sqrt(sum(lbpHist.^2)) + eps('single'));
            
            
            % Rimodella l'istogramma in un vettore di caratteristiche
            % 1x[ColonneNecessarie]
            lbpHist = reshape(lbpHist, 1, []);
        end
        
         
        % -----------------------------------------------------------------
        function [x, y] = generateNeighborLocations(numNeighbors, radius)
            %  La funzione genera due vettori x e y (8 elementi ciascuno)
            %  che rappresentano le coordinate rispetto a ciascun pixel dei suoi vicini
            %
            %  numNeighbors: Numero di vicini da considerar
            %  radius:       Dimensione del raggio della circonferenza
            %                sulla quale ricercare i vicini
            
            %  Calcolo dell'angolo (in gradi) in cui trovare ciascun vicino
            %  [esempio: a 45° dal pixel]
            theta = single((360/numNeighbors) * (0:numNeighbors-1));
            
            %  Calcolo del raggio per il coseno o il seno degli angoli theta
            %  Nel caso il raggio sia 1, x e y rappresentano esattamente il
            %  seno e il coseno relativi alal posizione in gradi di ogni
            %  vicino rispetto al pixel centrale
            x =  radius * cosd(theta);
            y = -radius * sind(theta);
        end
        
        
        % -----------------------------------------------------------------
        function [offsets, weights] = createBilinearOffsets(x, y, numNeighbors)
            %   La funzione genera due matrici rappresentanti gli offset e
            %   i pesi dei pixel per l'interpolazione bilineare
            
            %   La fuzione floor arrotonda x all'intero più vicino (per difetto)
            floorX = floor(x);
            floorY = floor(y);
            
            %   La funzione ceil arrotonda x all'intero più vicino (per eccesso)
            ceilX  = ceil(x);
            ceilY  = ceil(y);
            
            %   Si calcolano ora gli offsets dei vicini di P
            %   (esempio caso 4 vicini):
            %   f(0,0)    f(1,0)
            %          P
            %   f(0,1)    f(1,1)
            offsets =    [floorX; floorY    % f(0,0)
                ceilX ; floorY    % f(1,0)
                floorX; ceilY     % f(0,1)
                ceilX ; ceilY];   % f(1,1)
            
            %   Vengono ora calcolati i pesi Dx, Dy e Dx*Dy per
            %   l'interpolazione bilineare
            %   Dx e Dy sono le distanze fra P e f(0,0)
            %
            %  f(0,0)----
            %         Dx  |
            %             | Dy
            %
            %             P
            
            %   Inizializza weights a una matrice 3x8 vuota
            weights      = coder.nullcopy(zeros(3, numNeighbors, 'single'));
            
            weights(1,:) = x - offsets(1,:);               % Calcolo Dx
            weights(2,:) = y - offsets(2,:);               % Calcolo Dy
            weights(3,:) = weights(1,:) .* weights(2,:);   % Calcolo Dx*Dy
            
            %   Rimodella la matrice degli offset affinchè sia della forma
            %   2x4xnumNeighbors
            offsets = reshape(offsets, 2, 4, []);
            
            offsets = int32(offsets);        
        end
        
        
        % -----------------------------------------------------------------
        function h = initializeHist(cellSize, numBins, M, N)
            %   Calcola il numero di celle in base alla dimensione
            %   dell'immagine e della dimensione delle celle fornita in
            %   input
            numCells = floor([M N]./cellSize);
            
            %   Inizializza a zero un istogramma di dimensione basata sul
            %   numero di barre e il numero di celle (2 in più per i contorni)
            h = zeros([numBins numCells+2],'single'); 
        end
        
        
         % -----------------------------------------------------------------
        function [xmax, ymax] = computeRange(cellSize, radius, M, N)
        %   La funzione calcola le cordinate massime per il pixel più
        %   "esterno" tenendo conto della divisione in celle
            
            ymax = floor(M/cellSize(1)) * cellSize(1);
            xmax = floor(N/cellSize(2)) * cellSize(2);
                 
            ymax = min(ymax, M-radius);
            xmax = min(xmax, N-radius);
        end
         
    
        % -----------------------------------------------------------------
        function lbp = computeMultibyteLBP(I, x, y, numNeighbors, numBytes, offsets, weights)
        %   La funzione calcola un descrittore LBP (quando necessario
        %   multi-byte, se numNeighbors>8) di tipo uint8 per ogni vicinato.
        %   Più semplicemente, a ogni vicinato, viene associato un valore
        %   intero. Nel caso di numNeighbors=8, viene associato un intero
        %   tra 0 e 255
           
            %Inizializza lbp con 0 codificati in uint8
            lbp = zeros(1,numBytes,'uint8');
            
            %Identifica il centro della porzione di immagine corrente
            center = I(y,x);
            
            p2 = coder.internal.indexInt(numNeighbors);
            p1 = coder.internal.indexInt((8*numBytes)-7+1);
            
            %Per ogni byte del vettore caratteristiche della zona corrente
            for n = 1:numBytes 
                %Per ogni bit del vettore, a partire dal più significativo,
                %del byte corrente
                for p = p2:-1:p1
                    
                    %   Valore interpolato del pixel corrente
                    neighbor = managerLBP.bilinearInterp(I, x, y, p, offsets, weights);
                    
                    %   Xor bit a bit il valore corrente del vettore
                    %   caratteristiche e il valore del confronto tra il
                    %   pixel interpolato e il centro del suo neighbor
                    lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                    lbp(n) = bitshift(uint8(lbp(n)),uint8(1));
                end
                
                %   Infine calcolo del valore complessivo del vettore
                %   caratteristiche per questa byte di questa zona
                neighbor = managerLBP.bilinearInterp(I, x, y, p1-1, offsets, weights);      
                lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                
                % Passaggio al byte successivo se presente
                p2 = p1-2;
                p1 = p2-7+1;
            end
        end
        
        
        % -----------------------------------------------------------------
        function bin = getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
        %   Calcola un pattern binario uniforme (ha al massimo 2 transizioni 1-a-0 o 0-a-1)
        %   a partire dal valore lbp locale
            
            %   Calcola il numero di transizioni in lbp
            u = managerLBP.uniformLBP(lbp, numNeighbors);
            
            %   Se è già uniforme 
            if u <= 2
                value = sum(scaling.*single(lbp));
                value = cast(value, 'uint32');
                
                %   Numero di bit restanti nel lbp corrente
                numBits = managerLBP.getNumSetBits(value, numNeighbors);
                
                %   Restituisce un pattern lbp minimizzato calcolato ruotando
                %   il codice lbp di input verso la destra finchè non è minimo.
                [~, numShifts] = managerLBP.rotateLBP(value, numNeighbors);
                
                if ~upright
                %   Se l'immagine è ruotata, non si può utilizzare il
                %   valore numShifts perchè non si può minimizzare lbp per
                %   tener conto della rotazione
                    bin =  index(numBits+1) + 1;
                else
                %   Se invece l'immagine non è ruotata, è possibile
                %   minimizzarlo 
                    bin =  index(numBits+1) + numShifts + 1;
                end
            else
            %   Se non è uniforme (u>2) si prende come bin il valore
            %   numBins
                bin = numBins;
            end
        end
        
        
        % -----------------------------------------------------------------
        function px = bilinearInterp(I, x, y, idx, offsets, weights)
            %   L’algoritmo di interpolazione bilineare considera 
            %   quattro pixel limitrofi presi da una matrice 3×3 dove il punto centrale è quello da interpolare.
            y = int32(y);
            x = int32(x);
            
            % 	Calcolo dei neighbors del punto P di cordinate x,y
            %   f(0,0)    f(1,0)
            %          P    
            %   f(0,1)    f(1,1)
            f00 = single(I(y + offsets(2,1,idx), x + offsets(1,1,idx)));
            f10 = single(I(y + offsets(2,2,idx), x + offsets(1,2,idx)));
            f01 = single(I(y + offsets(2,3,idx), x + offsets(1,3,idx)));
            f11 = single(I(y + offsets(2,4,idx), x + offsets(1,4,idx)));
            
            
            %   Calcolo dei fattori e pesi per l'interpolazione
            a = f00;
            b = f10 - f00;
            c = f01 - f00;
            d = f00 - f10 - f01 + f11;
            
            xval = weights(1, idx);
            yval = weights(2, idx);
            xy   = weights(3, idx);
            
            %   Valore pixel interpolato
            px = a + b*xval + c*yval + d*xy;
            
        end
       
        
        % -----------------------------------------------------------------
        function u = uniformLBP(lbp, NumNeighbors)
            %   Restituisce il numero di transizioni nel codice lbp binario
            %   tenendo conto che questo potrebbe occupare più di un byte
            
            numBytes = int32(numel(lbp));
            
            %   Posizione da cui iniziare nel byte
            n = int32(8) - int32((8*numBytes)) + int32(NumNeighbors);
            
            u = bitxor(bitget(lbp(1),n), bitget(lbp(end), 1));
            a = bitget(lbp(1), n);
            n = n - 1;
            
            %Per ogni byte
            for j = 1:numBytes  
                %Per ogni bit nel byte
                while n
                    b = bitget(lbp(j), n);
                    
                    %Conteggio transizioni
                    u = u + bitxor(a,b);
                    a = b;
                    n = n - 1;
                end
                n = int32(8);
            end
        end
        
        
        % -----------------------------------------------------------------
        function n = getNumSetBits(value, NumNeighbors)
        %   Calcola il numero di bit
            n = uint32(0);
            for i = 1:NumNeighbors
                n = n + cast(bitget(value, i),'uint32');
            end
        end
        
        
        % -----------------------------------------------------------------
        function [rotated, count] = rotateLBP(lbp, NumNeighbors)
        %   Restituisce un pattern lbp minimizzato calcolato ruotando
        %   il codice lbp di input verso la destra finchè non è minimo.
        %   Restituisce anche il conteggio di shift eseguiti per
        %   raggiungere il minimo
            rotated = lbp;
            count = uint32(0);
            for k = 1:uint32(NumNeighbors)
                lbp  = managerLBP.rotr(lbp, 1, NumNeighbors);
                if lbp < rotated
                    rotated = lbp;
                    count  = k;
                end
            end
        end
        
        
        % -----------------------------------------------------------------
        function out = rotr(in, K, NumNeighbors)
        %   Effettua uno shift circolare a destra 
         
            a = bitshift(in, -K);
            b = bitshift(in, NumNeighbors - K);
            mask = cast(2^NumNeighbors-1, 'like', in); % Effettua il cast di 2^NumNeighbors-1 a un tipo di dato compatibile con in (nel caso di byte parziali)
            b = bitand(b, mask);                       % Maschera gli 8 bit più significativi di b
            out = bitor(a,b);
        end
    end
end