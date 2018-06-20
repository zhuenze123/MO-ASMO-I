%===============================================================================
% Multiobjective Adaptive Surrogate Modeling-based Optimization Code I
% Main author: Yong Hoon Lee (ylee196@illinois.edu, yonghoonlee@outlook.com)
% Link: https://github.com/yonghoonlee/MO-ASMO-I
%===============================================================================
% Plot Figure 06-07: Hypervolume metric and Hypervolume metric convergence
%===============================================================================
try figure(fg6); % Open figure window
catch, fg6 = figure('Color',[1 1 1]); end; fg6.Position = [460 540 560 220];
hold off;
try figure(fg7); % Open figure window
catch, fg7 = figure('Color',[1 1 1]); end; fg7.Position = [890 530 560 220];
hold off;
%-------------------------------------------------------------------------------
figure(fg6);
yyaxis left;
ph1 = plot([1:k]',R.data.c37_hypervolume(1:k), ...
    'ks-','MarkerFaceColor','k','LineWidth',2);
hold on;
ax = gca; ax.FontSize = prob.plotpareto.fontsize; ax.YColor = [0 0 0];
xlabel('iteration', 'FontSize', prob.plotpareto.fontsize);
ylabel('hypervolume size', 'FontSize', prob.plotpareto.fontsize);
%-------------------------------------------------------------------------------
yyaxis right;
ph2 = plot([1:k]',R.data.c38_hypervolumeRatio(1:k), ...
    'rd-','MarkerFaceColor','r','LineWidth',2);
hold on;
ax = gca; ax.FontSize = prob.plotpareto.fontsize; ax.YColor = [0 0 0];
xlabel('iteration', 'FontSize', prob.plotpareto.fontsize);
ylabel('hypervolume ratio', 'FontSize', prob.plotpareto.fontsize);
%-------------------------------------------------------------------------------
legend([ph1, ph2], ...
    {'HV size', 'HV ratio'}, ...
    'Location','northeast','Box','off','Color','none');
%-------------------------------------------------------------------------------
figure(fg7);
% Hypervolume
ph3data1 = R.data.c39_changeHypervolume(1:k);
ph3data2 = R.data.c40_changeHypervolumeRatio(1:k);
ph3 = semilogy(1:k,ph3data1,'ks-','LineWidth',2, ...
    'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerSize',9); hold on;
ph4 = semilogy(1:k,ph3data2,'rd-','LineWidth',2, ...
    'MarkerFaceColor','r','MarkerEdgeColor','none','MarkerSize',9); hold on;
%ph5 = semilogy([1:k]',(ph3data1+ph3data2)./2,'o-','LineWidth',2, ...
%    'Color',[0.2 0.7 0.2],'MarkerFaceColor',[0.2 0.7 0.2],...
%    'MarkerEdgeColor','none','MarkerSize',7); hold on;
% Eulerian distance
ph6 = semilogy(-k,mean(ph3data1),'bs:','LineWidth',2, ...
    'MarkerFaceColor','none','MarkerEdgeColor','b','MarkerSize',10); hold on;

errmax = max(cell2mat(R.data.c33_valErrorVec(1)));
erravg = R.data.c34_valErrorAvg(1);
errmin = min(cell2mat(R.data.c33_valErrorVec(1)));
semilogy([1-0.25;1+0.25],[errmax;errmax],'b-','LineWidth',1.5);
semilogy([1-0.25;1+0.25],[errmin;errmin],'b-','LineWidth',1.5);
semilogy([1-0.25;1-0.25],[errmin;errmax],'b-','LineWidth',1.5);
semilogy([1+0.25;1+0.25],[errmin;errmax],'b-','LineWidth',1.5);
semilogy([1-0.25;1+0.25],[erravg;erravg],'b-','LineWidth',2);
if k>1
    for idx = 2:k
        itr = [(idx-1), idx];
        errmax = [max(cell2mat(R.data.c33_valErrorVec(itr(1)))), ...
                  max(cell2mat(R.data.c33_valErrorVec(itr(2))))];
        erravg = [R.data.c34_valErrorAvg(itr(1)), ...
                  R.data.c34_valErrorAvg(itr(2))];
        errmin = [min(cell2mat(R.data.c33_valErrorVec(itr(1)))), ...
                  min(cell2mat(R.data.c33_valErrorVec(itr(2))))];
        semilogy([itr(2)-0.25;itr(2)+0.25],[errmax(2),errmax(2)],'b-','LineWidth',1.5);
        semilogy([itr(2)-0.25;itr(2)+0.25],[errmin(2),errmin(2)],'b-','LineWidth',1.5);
        semilogy([itr(2)-0.25;itr(2)-0.25],[errmin(2),errmax(2)],'b-','LineWidth',1.5);
        semilogy([itr(2)+0.25;itr(2)+0.25],[errmin(2),errmax(2)],'b-','LineWidth',1.5);
        semilogy([itr(2)-0.25;itr(2)+0.25],[erravg(2),erravg(2)],'b-','LineWidth',2);
        semilogy(itr,erravg,'b:','LineWidth',2);
    end
end
ax = gca; ax.FontSize = prob.plotpareto.fontsize; ax.XLim = [0 k+1];
xlabel('iteration','FontSize',prob.plotpareto.fontsize);
ylabel('normalized residual','FontSize',prob.plotpareto.fontsize);
%-------------------------------------------------------------------------------
%legend([ph6, ph3, ph4, ph5], ...
%    {'ED error', 'HV size', 'HV ratio', 'HV combined (avg.)'}, ...
%    'Location', 'southwest','Box','off','Color','none');
legend([ph6, ph3, ph4], ...
    {'ED error', 'HV size', 'HV ratio'}, ...
    'Location', 'southwest','Box','off','Color','none');
%-------------------------------------------------------------------------------
if (prob.control.plotexport)
    figure(fg6);
    eval(['export_fig ''', ...
        fullfile( ...
            prob.control.plotpath, [ ...
                prob.control.case, '_fig06_iter', num2str(k,'%04d')] ...
        ), ''' -pdf']);
    figure(fg7);
    eval(['export_fig ''', ...
        fullfile( ...
            prob.control.plotpath, [ ...
                prob.control.case, '_fig07_iter', num2str(k,'%04d')] ...
        ), ''' -pdf']);
end
%===============================================================================
