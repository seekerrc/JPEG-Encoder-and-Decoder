
%%**************************************************************************************%%
%%***********************************�ӳ������*****************************************%%
%%**************************************************************************************%%

tic   %����ѹ��ʱ��


%%*********************************�������ļ���ȡ***************************************%%
fid1=fopen('bitstream.txt','rt');
code_input=fscanf(fid1,'%s');
fclose(fid1);
JPEG_DECODER;%����code_input

%%**************************************************************************************%%
%%************************************ͼ����ʾ******************************************%%
%%**************************************************************************************%%
imshow(img)
title('�ָ�ͼ��')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%��ͼʱע���޸��������%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imwrite(img,'processed.jpg');

disp('������תͼ����ʱ��')
toc   %����ʱ��