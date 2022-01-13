function [eqty, sharpe, dd, ret] = iqtest(P, signals, intiDeposit)
    %      __  __
    %   __/  \/ /_  iQuantTrader platform
    %  / / / /  _/  (c) 2009-2013, JWizards
    %  \/\__ \__\   http://www.appliedalpha.com/
    %       \/
    %
	% [eqty, sharpe, dd, ret] = iqtest(P, signals, initialDeposit) process trading signals
    %
    % Inputs:
    %    P  - matrix of prices, first column is time, rest are prices for every stock.
    %    signals - matrix of signals, first column is time, rest are positions for every stock. 
    %         If position is NaN the signal is skipped.
    %    initialDeposit - initial dollar deposit.
    %
    % Outputs:
    %    eqty - equity curve
    %    sharpe - Annualized Sharpe index
    %    dd - maximal drawdown in percents
    %    ret - returns at every time when profit is realized
    %
    
    if size(P, 2) < 2, error('Price matrix must contain at least 2 colums (Time and Price)'); end
    if size(signals, 2) < 2, error('Signal''s matrix must contain at least 2 colums (Time and signal)'); end
    if size(signals, 2) > size(P, 2), error('Wrong price matrix num colums'); end
    
    nInstrs = size(signals,2) - 1;
    poses = Position.empty(nInstrs, 0);
    for i = 1 : nInstrs, poses(i) = Position; end
  
    % Main cycle
    ret = [signals(1, 1) 0 zeros(1, size(P, 2)-1)]; % execution prices are at the end
    for i = 1 : size(signals, 1)
        ti = signals(i, 1);
               
        if ischar(ti), ti = datenum(ti); end
        
        prices = P(P(:,1)==ti, 2:end);
        if isempty(prices), error(['Can''t find prices for signal at ' datestr(ti)]); end
        
        pnl = 0;
        for j = 1 : nInstrs
            signal = signals(i, j+1);
            if ~isnan(signal) % skip NaN signals
                pnl = pnl + poses(j).changePosition(prices(j), signal);
            end
        end
        
        if pnl ~= 0
            ret =[ret; [ti pnl prices];]; % attach prices
        end

    end
    
    % finally close opened positions ???
    prices = P(end, 2:end);
    pnl = 0;
    for j = 1 : nInstrs
        pnl = pnl + poses(j).changePosition(prices(j), 0);
    end
    if pnl ~= 0,
        ret =[ret; [P(end, 1) pnl prices];];
    end
    
    % statistic
    eqty = intiDeposit + cumsum(ret(:,2));
    rets = eqty(2:end)./eqty(1:end-1) - 1; % - 0.04/252;
    sharpe = sqrt(252)*mean(rets)/std(rets);
    dd = maxdd(eqty);
end
