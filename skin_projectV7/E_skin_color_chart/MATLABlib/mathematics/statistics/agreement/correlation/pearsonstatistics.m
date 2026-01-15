function statistics=pearsonstatistics(x,y)
%calculate pearsonstatistics:
%standard deviation of X, standard deviation of Y,
%mean of X, mean of Y and Pearson correlation
%output:
%    statistics=[pop_sd_x,pop_sd_y,mean_x,mean_y,correlation]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sum_sq_x = 0;
 sum_sq_y = 0;
 sum_coproduct = 0;
 N=length(x);
 mean_x = sum(x)/N;
 mean_y = sum(y)/N;
 for i =2: 1 : N
     sweep = (i - 1.0) / i;
     delta_x = x(i) - mean_x;
     delta_y = y(i) - mean_y;
     sum_sq_x =sum_sq_x + delta_x * delta_x * sweep;
     sum_sq_y = sum_sq_y + delta_y * delta_y * sweep;
     sum_coproduct = sum_coproduct+ delta_x * delta_y * sweep;
     mean_x = mean_x + delta_x / i;
     mean_y = mean_y + delta_y / i ;
 end
 pop_sd_x = sqrt( sum_sq_x / N );
 pop_sd_y = sqrt( sum_sq_y / N );
 cov_x_y = sum_coproduct / N;
 correlation = cov_x_y / (pop_sd_x * pop_sd_y);
 anglecorr=atan(correlation);
statistics=[pop_sd_x,pop_sd_y,mean_x,mean_y,correlation]
end