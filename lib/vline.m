function retval = vline(x,line_color)
	if nargin < 2 line_color = 'g'; end
	retval = 0;
	hold on
	for ii = 1 : length(x)
		if ii == 1
			retval = plot([x(ii),x(ii)],get(gca,'ylim'),line_color);
		else
			plot([x(ii),x(ii)],get(gca,'ylim'),line_color);
		end
	end
	hold off
