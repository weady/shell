ʵ�ִ��̵��Զ����غͼ��
eg�����ĸ����̣�����һ����ϵͳ�̣���������Ϊҵ���̣�����ҵ�񶼷�һ����
/dev/sda1	/boot
/dev/sda2	/
....
/dev/sdb1	/data1
/dev/sdc1	/data2
/dev/sdd1	/data3

��Ҫʵ��ҵ���̵��Զ����غͼ�����
���̼��ű��ķ���:
���̵ļ��ű���ÿһ��������һ��,�����������£�
1.ͨ��/usr/local/homed/maintain/m_start.sh Ϊ�����
2.m_start.sh����/usr/local/homed/maintain/checkdiskmount/m_checkdisk.sh
3.m_checkdisk.sh���� m_build_raid.sh m_builddisk.sh m_reallycheck.sh
    m_build_raid.sh    ����raid �������ڼ��
    m_builddisk.sh    ͨ��blkid��ȡ����Դ��Ȼ��������disk_config.txt�ļ������ļ�����Ҫ���ļ���������м�ⶼ�������ļ�
    eg��    5a2a02b9-41e7-4f11-8da2-eebb77365dc4,/dev/sda1,/data1,/d1,ext3
    һ������ֶ�
    1.ͨ��tmp �ļ����˳�UUID ��һ���ֶ�    ����blkid,���ֵ��Ψһ��
    2.ͨ��tmp�ļ����˳�/dev/sda1(���̷�)    �ڶ����ֶ� ����blkid�������fdisk /dev/sdx ���з���ʱȷ����
    3.�������ֶ���ͨ��df -l �����ϲ���3�еĴ��̷���ȡ   �������ֶ�����df -l��df -l ������mount
    4.���ĸ��ֶ����ڵ������ֶεĻ����Ͻ����޸Ļ�ȡ��    label
    5.������ֶ���ͨ��tmp�ļ�ֱ�ӻ�ȡ�� ����blkid    type
    m_reallycheck.sh ��Ҫ�����Ǽ��ϵͳ�Ĵ����Ƿ�������������disk_config.txt�ļ�
    m_reallycheck.sh�ű��ж����˶��ֺ���