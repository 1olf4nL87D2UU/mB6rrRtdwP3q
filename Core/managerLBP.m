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
            
            
            %%  DA RIVEDERE TUTTI I COMMENTI NEL CICLO
            %   Ciclo che parte da radius+1, e incremento per volta arriva
            %   alla cordinata x massima
            for x = ((radius+1):xmax)
                
                %   Calcolo delle coordinate x nell'istogramma delle varie
                %   barre
                cx = floor((x-0.5) * invCellSize(2) - 0.5);
                x0 = cellSize(2) * (cx + 0.5);
                
                wx2 = ((x-0.5) - x0) * invCellSize(2);
                wx1 = 1 - wx2;
                
                cx = cx + 2; 
                
                %   Per ogni radius da radius+1 a xmax, calcola il vettore lbp e le barre dell'istogramma lbp scorrendo
                %   sulle ordinate 
                for y = ((radius+1):ymax)
                    
                    lbp = managerLBP.computeMultibyteLBP(I, x, y, numNeighbors, numBytes, offsets, weights);
                    
                    if ~upright
                        bin = managerLBP.getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                    else
                        bin = managerLBP.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                    end
                    
                    
                     %   Calcolo delle coordinate y nell'istogramma delle varie
                     %   barre
                    cy = floor((y-0.5) * invCellSize(1) - 0.5);
                    y0 = cellSize(1) * (cy + 0.5);
                    
                    wy2 = ((y-0.5) - y0) * invCellSize(1);
                    wy1 = 1 - wy2;
                    cy = cy + 2; % 1 - based
                    
                    %   Calcolo dei pesi per ciascuna barra dell'istogramma
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
        %   multi-byte) di tipo uint8 per ogni vicinato
           
            
            lbp = zeros(1,numBytes,'uint8');
            center = I(y,x);
            
            p2 = coder.internal.indexInt(numNeighbors);
            p1 = coder.internal.indexInt((8*numBytes)-7+1);
            for n = 1:numBytes % MSB [xxxx] LSB
                for p = p2:-1:p1 % reverse order b/c of bitshift to left
                    
                    
                    neighbor = managerLBP.bilinearInterp(I, x, y, p, offsets, weights);
                    
                    
                    lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                    lbp(n) = bitshift(uint8(lbp(n)),uint8(1));
                end
                
                % bit p1-1
                
                neighbor = managerLBP.bilinearInterp(I, x, y, p1-1, offsets, weights);
                
                
                lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                
                % next byte
                p2 = p1-2;
                p1 = p2-7+1;
            end
        end
        
        
        % -----------------------------------------------------------------
        % Return uniform rotated LBP code from plain LBP (stored in
        % multi-byte format).
        function [bin] = getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            
            bin = managerLBP.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
        end
        
        
        % -----------------------------------------------------------------
        % Return uniform LBP code from plain LBP (stored in multi-byte
        % format).
        function bin = getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            
            u = managerLBP.uniformLBP(lbp, numNeighbors);
            
            if u <= 2
                value = sum(scaling.*single(lbp));
                value = cast(value, 'uint32');
                
                numBits = managerLBP.getNumSetBits(value, numNeighbors);
                
                [~, numShifts] = managerLBP.rotateLBP(value, numNeighbors);
                
                if ~upright
                    % uniform + rotated
                    bin =  index(numBits+1) + 1; % +1 for 1-based
                else
                    % uniform
                    bin =  index(numBits+1) + numShifts + 1;
                end
            else
                bin = numBins;
            end
        end
        
        
        % -----------------------------------------------------------------
        function px = bilinearInterp(I, x, y, idx, offsets, weights)
       
            y = int32(y);
            x = int32(x);
            
            % neighbors of pixel,x
            % f(0,0) -- f(1,0)
            % |       x    |
            % f(0,1) -- f(1,1)
            f00 = single(I(y + offsets(2,1,idx), x + offsets(1,1,idx)));
            f10 = single(I(y + offsets(2,2,idx), x + offsets(1,2,idx)));
            f01 = single(I(y + offsets(2,3,idx), x + offsets(1,3,idx)));
            f11 = single(I(y + offsets(2,4,idx), x + offsets(1,4,idx)));
            
            a = f00;
            b = f10 - f00;
            c = f01 - f00;
            d = f00 - f10 - f01 + f11;
            
            xval = weights(1, idx);
            yval = weights(2, idx);
            xy   = weights(3, idx);
            
            px = a + b*xval + c*yval + d*xy;
            
        end
       
        
        % -----------------------------------------------------------------
        function u = uniformLBP(lbp, NumNeighbors)
            % Returns the number of transitions in a binary lbp code.
            % lbp may be stored in multi-byte format; elem 1 is MSB, end is LSB
            
            numBytes = int32(numel(lbp));
            
            % init
            n = int32(8) - int32((8*numBytes)) + int32(NumNeighbors); % position in the byte to start at
            % initialize with transition from MSB to LSB
            u = bitxor(bitget(lbp(1),n), bitget(lbp(end), 1));
            a = bitget(lbp(1), n);
            n = n - 1;
            
            for j = 1:numBytes  % MSB [xxxx] LSB
                while n
                    b = bitget(lbp(j), n);
                    u = u + bitxor(a,b);
                    a = b;
                    n = n - 1;
                end
                n = int32(8);
            end
        end
        
        
        % -----------------------------------------------------------------
        function n = getNumSetBits(value, NumNeighbors)
            n = uint32(0);
            for i = 1:NumNeighbors
                n = n + cast(bitget(value, i),'uint32');
            end
        end
        
        
        % -----------------------------------------------------------------
        function [rotated, count] = rotateLBP(lbp, NumNeighbors)
            % Return minimized lbp pattern computed by rotating the input
            % lbp code to the right until it is minimized. Also return the
            % number of shifts needed to reach minimum.
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
        % circular right shift: x >> K | x << (NumNeighbors-K)
        function out = rotr(in, K, NumNeighbors)
            
            
            a = bitshift(in, -K);
            b = bitshift(in, NumNeighbors - K);
            mask = cast(2^NumNeighbors-1, 'like', in); % required for partial bytes
            b = bitand(b, mask);            % mask out upper 8-NumNeighbors bits
            out = bitor(a,b);
        end
    end
end