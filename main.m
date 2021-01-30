clear
clc
% рабочая директория
D  = cat(2, pwd, '\data');
S = dir(fullfile(D, '*.jpg'));
S = rmfield(S,{'date','bytes','isdir','datenum','bytes'}) ;
%% Определение частиц
for i = 1:2%size(S)
    % считывание и кроп изображение с запасом
    I = imread(fullfile(D, S(i).name));
    I = I(601:2300, 901:3000);
    % бинаризация изображения, по которому ищем окружности
    Gr = imbinarize(I,0.7);
    %uiwait
    Gr = ~Gr;
    %imshow(Gr)
    % определение области окуляра    
    I(I<20) = 0;
    C1 = imbinarize(I);
    C2 = imfill(C1,[1,1]);
    C2 = C2-C1;
    %imshow(C2)
    E = 255 * uint8(edge(C2,'canny',0.5));
    %imshow(E)
    [~, L] = bwboundaries(E);
    param = regionprops(L, 'Centroid', 'EquivDiameter', 'Area',...
        'Circularity', 'BoundingBox');
    [~,index] = sortrows([param.Area].'); 
    param = param(index(end:-1:1));
    S(i).optic = param(1);
    % преобразование Хафа для окружностей
    [c,r] = imfindcircles(Gr,[15 200]);
    %clear Gr
    for q = 1:size(r)
        S(i).part(q).c = c(q,:);
        S(i).part(q).r = r(q);
    end
    % сортировка частиц по размеру
    [~,index] = sortrows([S(i).part.r].'); 
    S(i).part = S(i).part(index(end:-1:1));    
    for k = 1:size(S(i).part,2)
        S(i).part(k).check = true;
    end
    % условие нахождения частицы в окуляре (граница кадра)
    for k = 1:size(S(i).part,2)
        if param(1).EquivDiameter > 700
            a = sqrt((param(1).Centroid(1) - S(i).part(k).c(1))^2 +...
                (param(1).Centroid(2) - S(i).part(k).c(2))^2);
            if (param(1).EquivDiameter/2) < a + (S(i).part(k).r)
                S(i).part(k).check = false;
            end
        end
    end    
    % наложение частиц друг на друга
    for k = 1:(size(S(i).part,2)-1)     
        for l = (k+1):size(S(i).part,2)
            if (S(i).part(k).r+S(i).part(l).r)^2 > ...
                   (S(i).part(k).c(1)-S(i).part(l).c(1))^2 +...
                   (S(i).part(k).c(2)-S(i).part(l).c(2))^2
                S(i).part(l).check = false;
            end
        end
    end
    disp(i/size(S,1)*100)
end
clear i k l q C1 C2 param j Gr I a index E L c r
%% Вывод результатов
for i = 1:2%size(S)
    qqq = -1;
    while qqq ~= 0
        % изображения с окружностями
        figure('Name',S(i).name)
        I = imread(fullfile(D, S(i).name));
        I = I(601:2300, 901:3000);
        imshow(I)
        hold on
        %viscircles([300,300], 100);
        viscircles([S(i).optic.Centroid(1),S(i).optic.Centroid(2)],...
            S(i).optic.EquivDiameter/2,'EdgeColor','g');
        for q = 1:size(S(i).part,2)
            if S(i).part(q).check == true
                color = 'r'; % red = true
            else
                color = 'b'; % blue = false
            end
            viscircles([S(i).part(q).c(1),S(i).part(q).c(2)],...
                S(i).part(q).r,'EdgeColor',color);
    %         text(S(i).part(q).c(1), S(i).part(q).c(2),...
    %              {"d="+round(2*S(i).part(q).r,0)+"px"},...
    %              'Color',color, 'FontSize', 14, 'EdgeColor', 'none',...
    %              'BackgroundColor','w','FontName','consolas')
             plot(S(i).part(q).c(1),S(i).part(q).c(2), 'black+',...
                 'MarkerSize', 10, 'LineWidth', 1);
            text(S(i).part(q).c(1), S(i).part(q).c(2),...clc
                {"#"+q,"d = "+(1/0.575)*2*S(i).part(q).r+" \mu"+"m"},...
                'Color',color, 'FontSize', 10, 'EdgeColor', 'none',...
                'BackgroundColor','w','FontName','consolas')
            text(100, 100,...
                {"#"+i},...
                'Color','black', 'FontSize', 14, 'EdgeColor', 'none',...
                'BackgroundColor','w','FontName','consolas')
        end    
        %uiwait
        qqq = input('qqq = ')
        if qqq ~= 0
            S(i).part(qqq).check = ~S(i).part(qqq).check;
        end
        close('all')
    end
end
clear i q color I ans qqq
%% Построение гистограммы по размерам частиц
for i = 1:size(S)
    for j = 1:size(S(i).part, 2)
        A(i,j) = S(i).part(j).r*1000/575*2;
        if S(i).part(j).check == 0
            A(i,j) = 0;
        end
    end
end
clear i j
A (A == 0) = NaN;
A = reshape(A, [numel(A),1])
histogram(A, 'NumBins', 50)
hold on
