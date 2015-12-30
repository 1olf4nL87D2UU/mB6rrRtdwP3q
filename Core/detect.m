function [yout,x,t] = detect(a,b,c,d,iu,t)
%STEP  Step response of dynamic systems.
%
%   [Y,T] = STEP(SYS) computes the step response Y of the dynamic system SYS. 
%   The time vector T is expressed in the time units of SYS and the time 
%   step and final time are chosen automatically. For multi-input systems,
%   independent step commands are applied to each input channel. If SYS has 
%   NY outputs and NU inputs, Y is an array of size [LENGTH(T) NY NU] where 
%   Y(:,:,j) contains the step response of the j-th input channel.
%
%   For state-space models, 
%      [Y,T,X] = STEP(SYS) 
%   also returns the state trajectory X, an array of size [LENGTH(T) NX NU] 
%   for a system with NX states and NU inputs.
%
%   For identified models (see IDLTI and IDNLMODEL),
%      [Y,T,X,YSD] = STEP(SYS) 
%   also computes the standard deviation YSD of the response Y (YSD is empty 
%   if SYS does not contain parameter covariance information).
%
%   [Y,...] = STEP(SYS,TFINAL) simulates the step response from t=0 to the 
%   final time t=TFINAL (expressed in the time units of SYS). For discrete-
%   time models with unspecified sample time, TFINAL is interpreted as  
%   the number of sampling periods.
%
%   [Y,...] = STEP(SYS,T) specifies the time vector T for simulation (in 
%   the time units of SYS). For discrete-time models, T should be of the  
%   form 0:Ts:Tf where Ts is the sample time. For continuous-time models, 
%   T should be of the form 0:dt:Tf where dt is the sampling period for the 
%   discrete approximation of SYS. 
%
%   [Y,...] = STEP(SYS,...,OPTIONS) specifies additional options such as the
%   step amplitude or input offset. Use stepDataOptions to create the option
%   set OPTIONS.
%
%   When called without output arguments, STEP(SYS,...) plots the step 
%   response of SYS and is equivalent to STEPPLOT(SYS,...). See STEPPLOT 
%   for additional graphical options for step response plots.
%
%   See also STEPPLOT, stepDataOptions, IMPULSE, INITIAL, LSIM, LTIVIEW, 
%   DYNAMICSYSTEM, IDLTI.

%       Extra notes on user-supplied T:  For continuous-time systems, the system is 
%       converted to discrete time with a sample time of dt=t(2)-t(1).  The time 
%       vector plotted is then t=t(1):dt:t(end).  

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%STEP   Step response of continuous-time linear systems.
%	STEP(A,B,C,D,IU)  plots the time response of the linear system:
%		.
%		x = Ax + Bu
%		y = Cx + Du
%	to a step applied to the input IU.  The time vector is auto-
%	matically determined.  STEP(A,B,C,D,IU,T) allows the specification
%	of a regularly spaced time vector T.
%
%	[Y,X] = STEP(A,B,C,D,IU,T) or [Y,X,T] = STEP(A,B,C,D,IU) returns
%	the output and state time response in the matrices Y and X 
%	respectively.  No plot is drawn on the screen.  The matrix Y has 
%	as many columns as there are outputs, and LENGTH(T) rows.  The 
%	matrix X has as many columns as there are states.  If the time 
%	vector is not specified, then the automatically determined time 
%	vector is returned in T.
%
%	[Y,X] = STEP(NUM,DEN,T) or [Y,X,T] = STEP(NUM,DEN) calculates the 
%	step response from the transfer function description 
%	G(s) = NUM(s)/DEN(s) where NUM and DEN contain the polynomial 
%	coefficients in descending powers of s.
%
%	See also: INITIAL, IMPULSE, LSIM and DSTEP.

%	J.N. Little 4-21-85
%	Revised A.C.W.Grace 9-7-89, 5-21-92
%	Revised A. Potvin 12-1-95
%   Copyright 1986-2011 The MathWorks, Inc.

ni = nargin;
no = nargout;
if ni==0,
   eval('exresp(''detect'')')
   return
end
narginchk(2,6)

% Determine which syntax is being used
switch ni
case 2
   if size(a,1)>1,
      % SIMO syntax
      a = num2cell(a,2);
      den = b;
      b = cell(size(a,1),1);
      b(:) = {den};
   end
   sys = tf(a,b);
   t = [];

case 3
   % Transfer function form with time vector
   if size(a,1)>1,
      % SIMO syntax
      a = num2cell(a,2);
      den = b;
      b = cell(size(a,1),1);
      b(:) = {den};
   end
   sys = tf(a,b);
   t = c;

case 4
   % State space system without iu or time vector
   sys = ss(a,b,c,d);
   t = [];

otherwise
   % State space system with iu 
   if min(size(iu))>1,
      error('IU must be a vector.');
   elseif isempty(iu),
      iu = 1:size(d,2);
   end
   sys = ss(a,b(:,iu),c,d(:,iu));
   if ni<6, 
      t = [];
   end
end

if no==1,
   yout = detect(sys,t);
   yout = yout(:,:);
elseif no>1,
   [yout,t,x] = detect(sys,t);
   yout = yout(:,:);
   x = x(:,:);
   t = t';
else
   detect(sys,t);
end


end
% end detect