

function [truerows,truecols,code_output] = JPEG_ENCODER (filename,quality)

%%**************************************************************************************%%
%%************************************JPEG ENCODER**************************************%%
%%*********JPEG��׼������������Ҷ�ͼ��ͨ��������Huffman���룬�������������**********%%
%%**************************************************************************************%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%��ͼʱע���޸��������%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imgint = imread(filename); %��ͼƬ����
%imgint = rgb2gray(imgint);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



[row,col] = size(imgint); %ͼƬ����Ĵ�С
rows = row / 8; %8������Ϊһ��
cols = col / 8;
truerows = rows*8;
truecols = cols*8;
lastcode = ''; %�洢���ձ����ַ���

%quality Ϊ�������ӣ�Ĭ��ֵΪ1�������˽�ȥ��ϵ����ѹ���ȣ�����quality ��ֵ��������ѹ���ȣ�ʹѹ��������ͼ��ռ�ô洢�ռ��С��
%quality = input('������������������ֵ�ͣ�Ĭ��Ϊ1��= ');
if isempty(quality)
quality =1;
end
if quality <= 0
error('���������0�����֣�');
end

%����ÿ����
block = []; %���8*8��
FormerDC = 0; %ǰһ���ֱ��ϵ���������һ���ʱ��Ϊ0
for k = 1:rows
    for l = 1:cols
        block(1:8,1:8) = imgint((k-1)*8+1:k*8,(l-1)*8+1:l*8);
        dct = JPEGDCT(block); %dct�任
        q = JPEGQuantification(dct,quality); %����
        zz = Zigzag(q); %zigzag
        strcode = JPEGEncode(zz,FormerDC); %����
        lastcode = [lastcode,strcode];
        FormerDC = zz(1);
        k,l
    end
end
code_output = lastcode;


end

%%**************************************************************************************%%
%%DCT�任���֣�����8by8�����ݿ飬��������ѭ������ϵ��������ͨ����άDCT�任��ʽ�õ����%%
%%**************************************************************************************%%
function X = JPEGDCT(block_8by8)
[rows,cols] = size(block_8by8);
c = [1/sqrt(2) 1 1 1 1 1 1 1];
for i = 1:rows
    for j = 1:cols
        A(i,j) = sqrt(2/rows) * c(i) * cos(((j- 1) + 0.5) * pi * (i-1) / rows);%����DCT�任��ϵ������
    end
end
X = A * block_8by8 * A';%��άDCT�任�ļ���ʽ�㷨
end

%%**************************************************************************************%%
%%�������֣�����������ǻҶ�ͼ�����������������õ��Ǳ�׼�������������󣬲�ͨ��quality���е���%%
%%**************************************************************************************%%
function Q = JPEGQuantification( dct_result, quality )
%������������
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
%%Zigzagɨ�貿�֣���ɨ���˳�����ScanOrder���鵱��*************************************%%
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
block1=reshape(block,[1 64]);%����ȡ���ų�һ��
zigzaged=block1(ScanOrder);%����˳������
end

%%**************************************************************************************%%
%%HUffman���벿�֣���ΪDCϵ���Ĳ��������Ʊ���DPCM��Difference Pulse Code Modulation��*%%
%%�Լ�ACϵ�����г̱���RLC��Run Length Coding����������**********************************%%
%%**************************************************************************************%%
function code = JPEGEncode( Coefficient,FormerDC )
%��������׼���õı�׼������
load ACpara.mat
if nargin == 1
    FormerDC = 0;
end

isDCNeg = 0; %DCϵ���Ƿ�Ϊ��
DCStr = '';  %ֱ��ϵ���ַ���
DC = Coefficient(1) - FormerDC;    %��ǰһ��DCϵ�����

if DC < 0
    DC = -DC;
    isDCNeg = 1;
end

%�����ֺ�DCϵ���������估ǰ׺��
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

%�����ֺ�DCϵ���Ķ������ַ�����ʮ����ת�����Ƶļ�ʵ��
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
DCSuf = DCSuf(end:-1:1);  %�����������϶���
if isDCNeg == 1
    for k = 1 : length(DCSuf)
        if DCSuf(k) == '0'
            DCSuf(k) = '1';
        else
            DCSuf(k) = '0';%����
        end
    end
end
DCStr = [DCFormerStr,DCSuf];

Coefficient(1) = 1;
NotZero = find (Coefficient ~= 0);%�����Ԫ�ص�λ��
num = size(NotZero,2);
ACStr = '';
for i = 1:num
    if NotZero(i) ~= 1%ֻ��ֱ�����������
        %�����γ�
        if i == 1
            RunLength = NotZero(i) - 2;
        elseif NotZero(i) > NotZero(i-1) - 1
            RunLength = NotZero(i) - NotZero(i-1) - 1;
        else
            RunLength = 0;
        end
        
        %����ߴ�
        ACCoe = Coefficient(NotZero(i));  %��ʱ��Ž���ϵ��
        isACNeg = 0;    %����ϵ���Ƿ�Ϊ��
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
        elseif ACCoe <=1023%ȷ������ϵ�����ȵĳ���
            SizeAC = 10;
        end
        ACFormerStr = '';
        while RunLength > 15%����15��0ʱ��Ҫ��ÿ16���㵥������
            RunLength = RunLength - 16;
            ACFormerStr = [ACFormerStr, AC{16,1}];
        end
        ACFormerStr = [ACFormerStr, AC{RunLength+1, SizeAC+1}];%�ҵ������е�AC����
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
                    ACSuf(k) = '0';%��DCһ������ת�������룬���С��0��ȡ����
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