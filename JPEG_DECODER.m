

%%**************************************************************************************%%
%%************************************JPEG DECODER**************************************%%
%%************JPEG标准解码器，输入二进制和原图像的大小，输出图像的恢复结果**************%%
%%**************************************************************************************%%


%%**************************************************************************************%%
%%Huffman编码部分,同样，包括DC系数和AC系数的解码****************************************%%
%%**************************************************************************************%%

function imgint = JPEG_DECODER( code,width,height,quality)
load ACpara.mat

truerow = height/8; %8*8大小块
truecol = width/8;
isBlockStart = 1; %判断是否处于每一个块的开始
BlockPoint = 1; %当前处于块中的位置
BlockRow = 1; %计数解码了多少行个块
BlockCol = 1; %计数解码了多少列个块
intBlock = []; %解码后的1*64数组
DCFomer = 0; %保存前一块的DC分量
DCLen = 0; %直流分量尺寸
ACLen = 0; %当前交流分量尺寸
for k = 1 : 64
    intBlock(k) = 0; %全置零，更改非零值
end
i = 1; %计数处于整个字符串所在位置
j = 1; %计数码字偏移

while 1
    if isBlockStart == 1 %是块开头则计算DC分量，不是则计算AC分量
        i = i + DCLen + ACLen;
        if (i >= length(code))
            break;
        end
        ACLen = 0;
        j = 1;
        DCcode = '';
        dcint = []; %清零int型编码
        while 1 %不停寻找码字，直到码字出现，进行解码DC操作，并退出循环
            id = ismember(DC,code(i:i + j));%找前缀码
            [m,n] = find (id == 1); %寻找码字
            if isempty(m)
                j = j + 1;
            else
                DCPre = code(i:i + j); %前缀码
                DCLen = DClength(n); %尺寸，acpara里面的矩阵！
                if DCLen == 0
                    DCpara = 0;
                    break
                end
                DCcode(1,1:DCLen) = code(i + j + 1:i + j + DCLen); %尾码，取出尺寸长度的二进制码
                DCpara = 0; %存放算出的十六分量值
                for m = 1 : DCLen %转为int值
                    dcint(m) = str2num(DCcode(m));
                end
                if dcint(1) == 1 %判断正负
                    for m = 1:DCLen
                        DCpara = DCpara + dcint(m) * 2 ^ (DCLen - m);
                    end
                else
                    for m = 1:DCLen
                        if dcint(m) == 0
                            dcint(m) = 1;
                        else
                            dcint(m) = 0;
                        end
                        DCpara = DCpara + dcint(m) * 2 ^ (DCLen - m);
                    end
                    DCpara = -DCpara;
                end
                break
            end
        end
        isBlockStart = 0;
        BlockPoint = BlockPoint + 1;
        intBlock(1) = DCpara + DCFomer;%反差分
        DCFomer = intBlock(1);
        
    else
        i = i + j + DCLen + ACLen + 1;
        if (i >= length(code))
            break;
        end
        DCLen = 0;
        ACcode = '';
        acint = [];
        j = 1;
        while 1
            id = ismember(AC,code(i:i + j));
            [m,n] = find (id == 1);%成员在AC系数表中的位置
            if isempty(m)
                j = j + 1;%找不到肯定是因为不够长
            elseif m == 1 & n == 1 %为结束码
                BlockPoint = 64;
                ACLen = 4;
                ACpara = 0;
                runlength = 0;
                break
            elseif m == 16 & n == 1 %为超长码
                runlength = 15;
                ACpara = 0;
                ACLen = 0;
                break;
            else
                ACPre = code(i:i + j);
                runlength = m - 1;%行数-1标识了零的个数
                ACLen = AClength(n - 1);%列数-1标识了码值的幅度尺寸
                ACcode(1,1:ACLen) = code(i + j + 1:i + j + ACLen);%取出尺寸长度的二进制码
                ACpara = 0;
                for m = 1 : ACLen
                    acint(m) = str2num(ACcode(m));
                end
                if acint(1) == 1%有这么长的二进制码，那么它的第一位绝对不会是0！是0就说明它是负数
                    for m = 1:ACLen
                        ACpara = ACpara + acint(m) * 2 ^ (ACLen - m);
                    end
                else
                    for m = 1:ACLen
                        if acint(m) == 0
                            acint(m) = 1;
                        else
                            acint(m) = 0;
                        end
                        ACpara = ACpara + acint(m) * 2 ^ (ACLen - m);
                    end
                    ACpara = -ACpara;%解码过程
                end
                break
            end
        end
%         intBlock(BlockPoint : BlockPoint + runlength) = 0;最前面已经对全部64个元素置零
        intBlock(BlockPoint + runlength) = ACpara;%注意到blockpoint在直流处理完之后+1
        BlockPoint = BlockPoint + runlength;
        if BlockPoint == 64
            isBlockStart = 1;
            BlockPoint = 0;
            q = invZigzag(intBlock); %zigzag反变换
            dct = JPEGiQuantification(q,quality); %反量化
            blockint = JPEGiDCT(dct); %反DCT
            blockint = round(blockint); %取整
            imgint((BlockRow-1)*8+1:BlockRow*8,(BlockCol-1)*8+1:BlockCol*8) = blockint; %存储解码值
            if BlockCol == truecol
                BlockCol = 1;%返回第一列继续处理
                if BlockRow == truerow
                    break %直到行和列解码完跳出主循环
                end
                BlockRow = BlockRow + 1;%没处理完，但是列处理完了，就跳到下一行
            else
                BlockCol = BlockCol + 1;
            end
            intBlock(1:64) = 0;%重置
            BlockRow,BlockCol
        end 
        BlockPoint = BlockPoint + 1;%没结束就接着处理
    end
    if (i >= length(code))
        break;
    end
end

[width,height] = size(imgint);
for i = 1 : width
    for j = 1 : height
        if imgint(i,j) < 0
            imgint(i,j) = 0; %负值归零
        end
    end
end
imgint = uint8(imgint); %转成uint8才能显示出图像
end


%%**************************************************************************************%%
%%反量化部分****************************************************************************%%
%%**************************************************************************************%%
function Q = JPEGiQuantification( q,quality )
%亮度量化矩阵
Quantize_matrix=[16 11 10 16 24 40 51 61
 
                 12 12 14 19 26 58 60 55
 
                 14 13 16 24 40 57 69 56
 
                 14 17 22 29 51 87 80 62
 
                 18 22 37 56 68 109 103 77
 
                 24 35 55 64 81 101 113 92
 
                 49 64 78 87 103 121 120 101
 
                 72 92 95 98 112 100 103 99]*quality;
Q=q.*Quantize_matrix;%逆过程乘法
end


%%**************************************************************************************%%
%%DCT逆过程*****************************************************************************%%
%%**************************************************************************************%%
function x = JPEGiDCT(X)
[rows,cols] = size(X);
c = [1/sqrt(2) 1 1 1 1 1 1 1];

for i = 1:rows
    for j = 1:cols
        A(i,j) = sqrt(2/rows) * c(i) * cos(((j- 1) + 0.5) * pi * (i-1) / rows);
    end
end

x = A' * X * A;
end



%%**************************************************************************************%%
%%Zigzag反扫描部分，把扫描的顺序存在ScanOrder数组当中***********************************%%
%%**************************************************************************************%%
function block8by8 = invZigzag( ZZ )
block8by8 = zeros(8);
ScanOrder=[1 3 4 10 11 21 22 36 ...
2 5 9 12 20 23 35 37 ...
6 8 13 19 24 34 38 49 ...
7 14 18 25 33 39 48 50 ...
15 17 26 32 40 47 51 58 ...
16 27 31 41 46 52 57 59 ...
28 30 42 45 53 56 60 63 ...
29 43 44 54 55 61 62 64];

for i = 1:64
    block8by8(i) = ZZ(ScanOrder(i));%一列一列地存入block8by8当中去
end
end






















