%TRINTERP Interpolate homogeneous transformations
%
% T = TRINTERP(T0, T1, S) is a homogeneous transform interpolation 
% between T0 when S=0 to T1 when S=1.  Rotation is interpolated using 
% quaternion spherical linear interpolation.  If S is an N-vector then
% T is a 4x4xN matrix where the transform T(:,:,i) corresponds to S(i).
%
% T = TRINTERP(T, S) is a transform that varies from the identity matrix when
% S=0 to T when R=1. If S is an N-vector then T is a 4x4xN matrix where 
% the transform T(:,:,i) corresponds to S(i).
%
% See also CTRAJ, QUATERNION.


% Copyright (C) 1993-2011, by Peter I. Corke
%
% This file is part of The Robotics Toolbox for Matlab (RTB).
% 
% RTB is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% RTB is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Leser General Public License
% along with RTB.  If not, see <http://www.gnu.org/licenses/>.

function T = trinterp(A, B, C)

    if nargin == 3
        %	TR = TRINTERP(T0, T1, r)
        T0 = A; T1 = B; r = C;

        if length(r) > 1
            T = [];
            for rr=r(:)'
                TT = trinterp(T0, T1, rr);
                T = cat(3, T, TT);
            end
            return;
        end

        q0 = Quaternion(T0);
        q1 = Quaternion(T1);

        p0 = transl(T0);
        p1 = transl(T1);

        qr = q0.interp(q1, r);
        pr = p0*(1-r) + r*p1;
    elseif nargin == 2
    %	TR = TRINTERP(T, r)
        T0 = A; r = B;

        if length(r) > 1
            T = [];
            for rr=r(:)'
                TT = trinterp(T0, rr);
                T = cat(3, T, TT);
            end
            return;
        end

        q0 = Quaternion(T0);
        p0 = transl(T0);

        qr = q0.scale(r);
        pr = r*p0;
    else
        error('must be 2 or 3 arguments');
    end
    T = rt2tr(qr.R, pr);
        
