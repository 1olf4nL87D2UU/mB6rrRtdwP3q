classdef managerLBP
    
    methods(Static)
           
        function [lbpHist] = LBPFeaturesExtractor(I, numNeighbors, radius, interpolation, uniform, upright, cellSize, normalization)
        %% Estrazione di un Logical Binary Pattern(LBP) uniforme da un immagine in scala di grigio e restituisce un vettore 1xN di features
        %  Uniforme:   ogni pattern binary locale ha al massimo 2 transizioni 1-a-0 o 0-a-1 
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
        %                   riconoscimento diminuisce 
        %
        %  Radius           La dimensione del raggio della circonferenza
        %                   che identifica i neighbors di un pixel. Aumentando il valore
        %                   vengono catturati dettagli su una superficie maggiore per ogni
        %                   pixel.
        %
        %  Upright          Valore logico che indica se è necessario
        %                   codificare informazioni relative all'invarianza alla rotazione o
        %                   meno
        %
        %  Interpolation    Specifica il metodo di interpolazione usato per
        %                   calcolare i pixel neighbors. 'Linear' o
        %                   'Nearest' . 
        %                   SI POTREBBE ELIMINARE e usare sempre Linear
        %                  
        %  CellSize         Vettore di due elementi che definisce la
        %                   dimensione delle celle in cui viene divisa l'immagine. Su
        %                   ciascuna cella viene calcolato LBP per poi riportare ciascun
        %                   risultato a un vettore di features globale. Abbiamo riscontrato
        %                   buoni risultati dividendo l'immagine in 16 parti.
        %
        %  Normalization   Tipo di Normalizzazione da utilizzare sugli
        %                  histogrammi LBP. 'L2' o 'None'
        %                  SI POTREBBE ELIMINARE e usare sempre L2

            I = im2uint8(I);
            
            [x, y] = managerLBP.generateNeighborLocations(numNeighbors, radius);
            
            if strncmpi(interpolation, 'l', 1)
                [offsets, weights] = managerLBP.createBilinearOffsets(x, y, numNeighbors);
            else
                [offsets, weights] =  managerLBP.createNearestOffsets(x, y);
            end
            
            
            if ~uniform && upright
                numBins = uint32(2^numNeighbors);
            else
                
                % on-the-fly LBP computations
                if uniform && ~upright
                    % uniform and rotated
                    numBins = uint32(numNeighbors + 2);
                    index   = uint32(0:numNeighbors);
                else
                    numBins = uint32(numNeighbors*(numNeighbors-1) + 3);
                    index   = uint32([0 1:numNeighbors:(numNeighbors*(numNeighbors-1)+1)]);
                end
            end
            
            [M, N] = size(I);
            
            lbpHist = managerLBP.initializeHist(cellSize, numBins, M, N);
            
            [xmax, ymax] = managerLBP.computeRange(cellSize, radius, M, N);
            
            invCellSize = 1./cellSize;
            
            numBytes = ceil(numNeighbors/8);
            
            % Scaling to convert N bytes to a float. MSB is at elem 1, LSB
            % is at end.
            scaling  = 2.^((8*numBytes-8):-8:0); % to store multi-byte LBP
            
            % start at Radius+1 to process full Radius+1-by-Radius+1 block
            for x = ((radius+1):xmax)
                
                cx = floor((x-0.5) * invCellSize(2) - 0.5);
                x0 = cellSize(2) * (cx + 0.5);
                
                wx2 = ((x-0.5) - x0) * invCellSize(2);
                wx1 = 1 - wx2;
                
                cx = cx + 2; % 1-based
                
                for y = ((radius+1):ymax)
                    
                    lbp = managerLBP.computeMultibyteLBP(I, x, y, numNeighbors, interpolation, numBytes, offsets, weights);
                    
                    if ~uniform && upright
                        bin =  managerLBP.getLBPCodePlain(lbp, scaling);
                        
                    else
                        % on-the-fly LBP computations
                        if uniform && ~upright
                            % uniform and rotated
                            bin = managerLBP.getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                        else
                            bin = managerLBP.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                        end
                    end
                    
                    % spatial weights for cell bins
                    cy = floor((y-0.5) * invCellSize(1) - 0.5);
                    y0 = cellSize(1) * (cy + 0.5);
                    
                    wy2 = ((y-0.5) - y0) * invCellSize(1);
                    wy1 = 1 - wy2;
                    cy = cy + 2; % 1 - based
                    
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
            
            % remove border cells
            lbpHist = lbpHist(:, 2:end-1, 2:end-1);
            
            % normalize
            if strcmpi(normalization, 'l2')
                lbpHist = bsxfun(@rdivide, lbpHist, sqrt(sum(lbpHist.^2)) + eps('single'));
            end
            
            % output features as 1-by-N
            lbpHist = reshape(lbpHist, 1, []);
        end
        
        % -----------------------------------------------------------------
        function [x, y] = generateNeighborLocations(numNeighbors, radius)
            % generate locations for circular symmetric neighbors
            theta = single((360/numNeighbors) * (0:numNeighbors-1));
            
            x =  radius * cosd(theta);
            y = -radius * sind(theta);
        end
        
        
        function [offsets, weights] = createBilinearOffsets(x, y, numNeighbors)
            
            % Pre-compute offsets to neighbors of pixel,px
            % f(0,0) -- f(1,0)
            % |      px    |
            % f(0,1) -- f(1,1)
            floorX = floor(x);
            floorY = floor(y);
            ceilX  = ceil(x);
            ceilY  = ceil(y);
            
            offsets = ...
                [floorX; floorY   % f(0,0)
                ceilX ; floorY    % f(1,0)
                floorX; ceilY     % f(0,1)
                ceilX ; ceilY];   % f(1,1)
            
            % Pre-compute interp weights, dx, dy, dx*dy for bilinear interp
            %
            %  dx and dy are distances from f(0,0) to the pixel, px, to be
            %  interpolated.
            %
            %  f(0,0)---->
            %         dx  |
            %             | dy
            %             v
            %            px
            %
            weights      = coder.nullcopy(zeros(3, numNeighbors, 'single'));
            weights(1,:) = x - offsets(1,:);               % x
            weights(2,:) = y - offsets(2,:);               % y
            weights(3,:) = weights(1,:) .* weights(2,:);   % xy
            
            % 2-by-4-by-N storage to simplify indexing during interp.
            offsets = reshape(offsets, 2, 4, []);
            
            offsets = int32(offsets);
            
        end
        
        function [offsets, weights] = createNearestOffsets(x, y)
            offsets = int32(round([x;y]));
            weights = zeros(1,1,'single');
        end
        
        function h = initializeHist(cellSize, numBins, M, N)
            numCells = floor([M N]./cellSize);
            h = zeros([numBins numCells+2],'single');  % +2 for cells bins at edges, these are remove later
        end
        
        function [xmax, ymax] = computeRange(cellSize, radius, M, N)
            
            ymax = floor(M/cellSize(1)) * cellSize(1);
            xmax = floor(N/cellSize(2)) * cellSize(2);
            
            % range up to last pixel in cell or that fits in image
            ymax = min(ymax, M-radius);
            xmax = min(xmax, N-radius);
        end
        
        % -----------------------------------------------------------------
        % Returns a multi-byte LBP code stored in stored as multiple uint8
        % values. lbp(1) is the MSB, lbp(end) is the LSB.
        % -----------------------------------------------------------------
        function lbp = computeMultibyteLBP(I, x, y, numNeighbors, interpolation, numBytes, offsets, weights)
            
            coder.inline('always');
            
            lbp = zeros(1,numBytes,'uint8');
            center = I(y,x);
            
            p2 = coder.internal.indexInt(numNeighbors);
            p1 = coder.internal.indexInt((8*numBytes)-7+1);
            for n = coder.unroll(1:numBytes) % MSB [xxxx] LSB
                for p = p2:-1:p1 % reverse order b/c of bitshift to left
                    
                    if strcmpi(interpolation, 'linear')
                        neighbor = managerLBP.bilinearInterp(I, x, y, p, offsets, weights);
                    else
                        neighbor = managerLBP.nearestInterp(I, x, y, p, offsets);
                    end
                    
                    lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                    lbp(n) = bitshift(uint8(lbp(n)),uint8(1));
                end
                
                % bit p1-1
                if strcmpi(interpolation, 'linear')
                    neighbor = managerLBP.bilinearInterp(I, x, y, p1-1, offsets, weights);
                else
                    neighbor = managerLBP.nearestInterp(I, x, y, p1-1, offsets);
                end
                
                lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                
                % next byte
                p2 = p1-2;
                p1 = p2-7+1;
            end
        end
        % -----------------------------------------------------------------
        % Return plain LBP code and bin for histogram.
        function [bin] = getLBPCodePlain(lbp, scaling)
            lbp = sum(scaling.*single(lbp));
            bin = single(lbp)+1;
        end
        
        % -----------------------------------------------------------------
        % Return uniform rotated LBP code from plain LBP (stored in
        % multi-byte format).
        function [bin] = getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            coder.inline('always');
            bin = managerLBP.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
        end
        
        % -----------------------------------------------------------------
        % Return uniform LBP code from plain LBP (stored in multi-byte
        % format).
        function bin = getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            coder.inline('always');
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
            coder.inline('always')
            
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
        function px = nearestInterp(I, x, y, idx, offsets)
            coder.inline('always')
            y = int32(y);
            x = int32(x);
            px = single(I(y + offsets(2, idx), x + offsets(1, idx)));
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
            coder.inline('always');
            
            a = bitshift(in, -K);
            b = bitshift(in, NumNeighbors - K);
            mask = cast(2^NumNeighbors-1, 'like', in); % required for partial bytes
            b = bitand(b, mask);            % mask out upper 8-NumNeighbors bits
            out = bitor(a,b);
        end
    end
end