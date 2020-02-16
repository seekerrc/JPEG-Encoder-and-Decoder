

%%**************************************************************************************%%
%%************************************JPEG DECODER**************************************%%
%%************JPEG��׼����������������ƺ�ԭͼ��Ĵ�С�����ͼ��Ļָ����**************%%
%%**************************************************************************************%%


%%**************************************************************************************%%
%%Huffman���벿��,ͬ��������DCϵ����ACϵ���Ľ���****************************************%%
%%**************************************************************************************%%

function imgint = JPEG_DECODER( code,width,height,quality)
load ACpara.mat

truerow = height/8; %8*8��С��
truecol = width/8;
isBlockStart = 1; %�ж��Ƿ���ÿһ����Ŀ�ʼ
BlockPoint = 1; %��ǰ���ڿ��е�λ��
BlockRow = 1; %���������˶����и���
BlockCol = 1; %���������˶����и���
intBlock = []; %������1*64����
DCFomer = 0; %����ǰһ���DC����
DCLen = 0; %ֱ�������ߴ�
ACLen = 0; %��ǰ���������ߴ�
for k = 1 : 64
    intBlock(k) = 0; %ȫ���㣬���ķ���ֵ
end
i = 1; %�������������ַ�������λ��
j = 1; %��������ƫ��

while 1
    if isBlockStart == 1 %�ǿ鿪ͷ�����DC���������������AC����
        i = i + DCLen + ACLen;
        if (i >= length(code))
            break;
        end
        ACLen = 0;
        j = 1;
        DCcode = '';
        dcint = []; %����int�ͱ���
        while 1 %��ͣѰ�����֣�ֱ�����ֳ��֣����н���DC���������˳�ѭ��
            id = ismember(DC,code(i:i + j));%��ǰ׺��
            [m,n] = find (id == 1); %Ѱ������
            if isempty(m)
                j = j + 1;
            else
                DCPre = code(i:i + j); %ǰ׺��
                DCLen = DClength(n); %�ߴ磬acpara����ľ���
                if DCLen == 0
                    DCpara = 0;
                    break
                end
                DCcode(1,1:DCLen) = code(i + j + 1:i + j + DCLen); %β�룬ȡ���ߴ糤�ȵĶ�������
                DCpara = 0; %��������ʮ������ֵ
                for m = 1 : DCLen %תΪintֵ
                    dcint(m) = str2num(DCcode(m));
                end
                if dcint(1) == 1 %�ж�����
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
        intBlock(1) = DCpara + DCFomer;%�����
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
            [m,n] = find (id == 1);%��Ա��ACϵ�����е�λ��
            if isempty(m)
                j = j + 1;%�Ҳ����϶�����Ϊ������
            elseif m == 1 & n == 1 %Ϊ������
                BlockPoint = 64;
                ACLen = 4;
                ACpara = 0;
                runlength = 0;
                break
            elseif m == 16 & n == 1 %Ϊ������
                runlength = 15;
                ACpara = 0;
                ACLen = 0;
                break;
            else
                ACPre = code(i:i + j);
                runlength = m - 1;%����-1��ʶ����ĸ���
                ACLen = AClength(n - 1);%����-1��ʶ����ֵ�ķ��ȳߴ�
                ACcode(1,1:ACLen) = code(i + j + 1:i + j + ACLen);%ȡ���ߴ糤�ȵĶ�������
                ACpara = 0;
                for m = 1 : ACLen
                    acint(m) = str2num(ACcode(m));
                end
                if acint(1) == 1%����ô���Ķ������룬��ô���ĵ�һλ���Բ�����0����0��˵�����Ǹ���
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
                    ACpara = -ACpara;%�������
                end
                break
            end
        end
%         intBlock(BlockPoint : BlockPoint + runlength) = 0;��ǰ���Ѿ���ȫ��64��Ԫ������
        intBlock(BlockPoint + runlength) = ACpara;%ע�⵽blockpoint��ֱ��������֮��+1
        BlockPoint = BlockPoint + runlength;
        if BlockPoint == 64
            isBlockStart = 1;
            BlockPoint = 0;
            q = invZigzag(intBlock); %zigzag���任
            dct = JPEGiQuantification(q,quality); %������
            blockint = JPEGiDCT(dct); %��DCT
            blockint = round(blockint); %ȡ��
            imgint((BlockRow-1)*8+1:BlockRow*8,(BlockCol-1)*8+1:BlockCol*8) = blockint; %�洢����ֵ
            if BlockCol == truecol
                BlockCol = 1;%���ص�һ�м�������
                if BlockRow == truerow
                    break %ֱ���к��н�����������ѭ��
                end
                BlockRow = BlockRow + 1;%û�����꣬�����д������ˣ���������һ��
            else
                BlockCol = BlockCol + 1;
            end
            intBlock(1:64) = 0;%����
            BlockRow,BlockCol
        end 
        BlockPoint = BlockPoint + 1;%û�����ͽ��Ŵ���
    end
    if (i >= length(code))
        break;
    end
end

[width,height] = size(imgint);
for i = 1 : width
    for j = 1 : height
        if imgint(i,j) < 0
            imgint(i,j) = 0; %��ֵ����
        end
    end
end
imgint = uint8(imgint); %ת��uint8������ʾ��ͼ��
end


%%**************************************************************************************%%
%%����������****************************************************************************%%
%%**************************************************************************************%%
function Q = JPEGiQuantification( q,quality )
%������������
Quantize_matrix=[16 11 10 16 24 40 51 61
 
                 12 12 14 19 26 58 60 55
 
                 14 13 16 24 40 57 69 56
 
                 14 17 22 29 51 87 80 62
 
                 18 22 37 56 68 109 103 77
 
                 24 35 55 64 81 101 113 92
 
                 49 64 78 87 103 121 120 101
 
                 72 92 95 98 112 100 103 99]*quality;
Q=q.*Quantize_matrix;%����̳˷�
end


%%**************************************************************************************%%
%%DCT�����*****************************************************************************%%
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
%%Zigzag��ɨ�貿�֣���ɨ���˳�����ScanOrder���鵱��***********************************%%
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
    block8by8(i) = ZZ(ScanOrder(i));%һ��һ�еش���block8by8����ȥ
end
end






















