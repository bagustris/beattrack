function retval = mapstdev(x)
	ystd = 1;
	ymean = 0;
	xmean = mean(x);
	xstd = std(x);
	retval =  (x-xmean)*(ystd/xstd) + ymean;;
