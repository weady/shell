实现磁盘的自动挂载和检查
eg：有四个磁盘，其中一个是系统盘，另外三个为业务盘，三个业务都分一个区
/dev/sda1	/boot
/dev/sda2	/
....
/dev/sdb1	/data1
/dev/sdc1	/data2
/dev/sdd1	/data3

主要实现业务盘的自动挂载和检查机制
磁盘监测脚本的分析:
磁盘的监测脚本是每一分钟运行一次,具体流程如下：
1.通过/usr/local/homed/maintain/m_start.sh 为主入口
2.m_start.sh调用/usr/local/homed/maintain/checkdiskmount/m_checkdisk.sh
3.m_checkdisk.sh调用 m_build_raid.sh m_builddisk.sh m_reallycheck.sh
    m_build_raid.sh    建立raid 磁盘用于监测
    m_builddisk.sh    通过blkid获取数据源，然后处理生成disk_config.txt文件，该文件是重要的文件后面的所有监测都依赖该文件
    eg：    5a2a02b9-41e7-4f11-8da2-eebb77365dc4,/dev/sda1,/data1,/d1,ext3
    一共五个字段
    1.通过tmp 文件过滤出UUID 第一个字段    依赖blkid,这个值是唯一的
    2.通过tmp文件过滤出/dev/sda1(磁盘符)    第二个字段 依赖blkid，这个是fdisk /dev/sdx 进行分区时确定的
    3.第三个字段是通过df -l 命令结合步骤3中的磁盘符获取   第三个字段依赖df -l，df -l 依赖于mount
    4.第四个字段是在第三个字段的基础上进行修改获取的    label
    5.第五个字段是通过tmp文件直接获取的 依赖blkid    type
    m_reallycheck.sh 主要功能是监测系统的磁盘是否正常，依赖于disk_config.txt文件
    m_reallycheck.sh脚本中定义了多种函数