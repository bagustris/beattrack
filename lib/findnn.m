function retval = findnn(ammo, target, nfind)
	retval = zeros(size(target));
	nn_ammo = length(ammo);
	if nargin < 3 nfind = 1; end
	for ii = 1 : nn_ammo
		for jj = 1 : nfind
			[~,idx] = min(abs(target - ammo(ii)));
			retval(idx) = 1;
			target(idx) = NaN;
		end
	end
	retval = find (retval);
