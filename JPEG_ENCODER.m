

function [truerows,truecols,code_output] = JPEG_ENCODER (filename,quality)

%%**************************************************************************************%%
%%************************************JPEG ENCODER**************************************%%
%%*********JPEG标准编码器，输入灰度图像，通过量化、Huffman编码，输出二进制序列**********%%
%%**************************************************************************************%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%换图时注意修改以下语句%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imgint = imread(filename); %读图片矩阵
%imgint = rgb2gray(imgint);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



[row,col] = size(imgint); %图片矩阵的大小
rows = row / 8; %8个像素为一块
cols = col / 8;
truerows = rows*8;
truecols = cols*8;
lastcode = ''; %存储最终编码字符串

%quality 为量化因子，默认值为1。决定了截去的系数和压缩比，增加quality 的值，可增大压缩比，使压缩编码后的图像占用存储空间更小。
%quality = input('请输入量化参数（数值型，默认为1）= ');
if isempty(quality)
quality =1;
end
if quality <= 0
error('请输入大于0的数字！');
end

%编码每个块
block = []; %存放8*8块
FormerDC = 0; %前一块的直流系数，编码第一块的时候为0
for k = 1:rows
    for l = 1:cols
        block(1:8,1:8) = imgint((k-1)*8+1:k*8,(l-1)*8+1:l*8);
        dct = JPEGDCT(block); %dct变换
        q = JPEGQuantification(dct,quality); %量化
        zz = Zigzag(q); %zigzag
        strcode = JPEGEncode(zz,FormerDC); %编码
        lastcode = [lastcode,strcode];
        FormerDC = zz(1);
        k,l
    end
end
code_output = lastcode;


end

%%**************************************************************************************%%
%%DCT变换部分，输入8by8的数据块，先用两层循环生成系数矩阵，再通过二维DCT变换公式得到结果%%
%%**************************************************************************************%%
function X = JPEGDCT(block_8by8)
[rows,cols] = size(block_8by8);
c = [1/sqrt(2) 1 1 1 1 1 1 1];
for i = 1:rows
    for j = 1:cols
        A(i,j) = sqrt(2/rows) * c(i) * cos(((j- 1) + 0.5) * pi * (i-1) / rows);%生成DCT变换的系数矩阵
    end
end
X = A * block_8by8 * A';%二维DCT变换的简单形式算法
end

%%**************************************************************************************%%
%%量化部分，由于输入的是灰度图像，这里的量化矩阵采用的是标准的亮度量化矩阵，并通过quality进行调整%%
%%**************************************************************************************%%
function Q = JPEGQuantification( dct_result, quality )
%亮度量化矩阵
Quantize_matrix=[16 11 10 16 24 40 51 61
 
                 12 12 14 19 26 58 60 55
 
                 14 13 16 24 40 57 69 56
 
                 14 17 22 29 51 87 80 62
 
                 18 22 37 56 68 109 103 77
 
                 24 35 55 64 81 101 113 92
 
                 49 64 78 87 103 121 120 101
 
                 72 92 95 98 112 100 103 99]*quality;
Q=round(dct_result./Quantize_matrix);
end

%%**************************************************************************************%%
%%Zigzag扫描部分，把扫描的顺序存在ScanOrder数组当中*************************************%%
%%**************************************************************************************%%
function zigzaged = Zigzag( block )
ScanOrder=[1 9 2 3 10 17 25 18 ...
11 4 5 12 19 26 33 41 ...
34 27 20 13 6 7 14 21 ...
28 35 42 49 57 50 43 36 ...
29 22 15 8 16 23 30 37 ...
44 51 58 59 52 45 38 31 ...
24 32 39 46 53 60 61 54 ...
47 40 48 55 62 63 56 64];
block1=reshape(block,[1 64]);%按列取出排成一行
zigzaged=block1(ScanOrder);%重组顺序排列
end

%%**************************************************************************************%%
%%HUffman编码部分，分为DC系数的差分脉冲调制编码DPCM（Difference Pulse Code Modulation）*%%
%%以及AC系数的行程编码RLC（Run Length Coding）两个部分**********************************%%
%%**************************************************************************************%%
function code = JPEGEncode( Coefficient,FormerDC )
%加载事先准备好的标准编码表格
load ACpara.mat
if nargin == 1
    FormerDC = 0;
end

isDCNeg = 0; %DC系数是否为负
DCStr = '';  %直流系数字符串
DC = Coefficient(1) - FormerDC;    %与前一个DC系数差分

if DC < 0
    DC = -DC;
    isDCNeg = 1;
end

%计算差分后DC系数所在区间及前缀码
if DC == 0
    DCFormerStr = '00';
elseif DC <= 1
    DCFormerStr = '010';
elseif DC <= 3
    DCFormerStr = '011';
elseif DC <= 7
    DCFormerStr = '100';
elseif DC <= 15
    DCFormerStr = '101';
elseif DC <= 31
    DCFormerStr = '110';
elseif DC <= 63
    DCFormerStr = '1110';
elseif DC <= 127
    DCFormerStr = '11110';
elseif DC <= 255
    DCFormerStr = '111110';
elseif DC <= 511
    DCFormerStr = '1111110';
elseif DC <= 1023
    DCFormerStr = '11111110';
elseif DC <= 2047
    DCFormerStr = '111111110';
end

%计算差分后DC系数的二进制字符串，十进制转二进制的简单实现
DCSuf = '';
while DC > 0
    x = rem(DC,2);
    DC = floor(DC/2);
    if x ==0
        a = '0';
    else
        a = '1';
    end
    DCSuf = [DCSuf,a];
end
DCSuf = DCSuf(end:-1:1);  %余数从下往上读数
if isDCNeg == 1
    for k = 1 : length(DCSuf)
        if DCSuf(k) == '0'
            DCSuf(k) = '1';
        else
            DCSuf(k) = '0';%反码
        end
    end
end
DCStr = [DCFormerStr,DCSuf];

Coefficient(1) = 1;
NotZero = find (Coefficient ~= 0);%存非零元素的位置
num = size(NotZero,2);
ACStr = '';
for i = 1:num
    if NotZero(i) ~= 1%只有直流分量的情况
        %计算游程
        if i == 1
            RunLength = NotZero(i) - 2;
        elseif NotZero(i) > NotZero(i-1) - 1
            RunLength = NotZero(i) - NotZero(i-1) - 1;
        else
            RunLength = 0;
        end
        
        %计算尺寸
        ACCoe = Coefficient(NotZero(i));  %临时存放交流系数
        isACNeg = 0;    %交流系数是否为负
        if ACCoe < 0
            ACCoe = -ACCoe;
            isACNeg = 1;
        end
        if ACCoe <= 1
            SizeAC = 1;
        elseif ACCoe <=3
            SizeAC = 2;
        elseif ACCoe <=7
            SizeAC = 3;
        elseif ACCoe <=15
            SizeAC = 4;
        elseif ACCoe <=31
            SizeAC = 5;
        elseif ACCoe <=63
            SizeAC = 6;
        elseif ACCoe <=127
            SizeAC = 7;
        elseif ACCoe <=255
            SizeAC = 8;
        elseif ACCoe <=511
            SizeAC = 9;
        elseif ACCoe <=1023%确定交流系数幅度的长度
            SizeAC = 10;
        end
        ACFormerStr = '';
        while RunLength > 15%超过15个0时需要对每16个零单独编码
            RunLength = RunLength - 16;
            ACFormerStr = [ACFormerStr, AC{16,1}];
        end
        ACFormerStr = [ACFormerStr, AC{RunLength+1, SizeAC+1}];%找到矩阵中的AC编码
        ACSuf = '';
        while ACCoe > 0
            x = rem(ACCoe,2);
            ACCoe = floor(ACCoe/2);
            if x ==0
                a = '0';
            else
                a = '1';
            end
            ACSuf = [ACSuf,a];
        end
        ACSuf = ACSuf(end:-1:1);
        if isACNeg == 1
            for k = 1 : length(ACSuf)
                if ACSuf(k) == '0'
                    ACSuf(k) = '1';
                else
                    ACSuf(k) = '0';%跟DC一样，先转二进制码，如果小于0就取反码
                end
            end
        end
        ACStr = [ACStr, ACFormerStr,ACSuf];
    else
        continue;
    end
end

if NotZero(num) ~= 64
    ACLast = AC{1,1};
else 
    ACLast = '';
end
ACStr = [ACStr, ACLast];


    

code = [DCStr,ACStr];
end