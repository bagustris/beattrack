function retval = map(x,ymin, ymax, xmin, xmax)
	if nargin <5 xmax = max(x); end
	if nargin <4 xmin = min(x); end
	if nargin <3 ymax = 1; end
	if nargin <2 ymin = -1; end
	retval = (ymax-ymin)*(x-xmin)/(xmax-xmin) + ymin;
