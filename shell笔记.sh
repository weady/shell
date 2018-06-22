正则表达式：
常用的正则表达式grep sed awk 
linux的正则表达式和命令行中其他的命令使用统配符有区别
linux 正则表达式一般以行为单位
alias grep='grep --color=auto'
注意字符集，LC_ALL=C
基础正则表达式：
1) ^word 表示搜索以word开头的内容
2）word$ 表示搜索以word结尾的内容
3)^$表示空行
4). 代表且只能代表任意一个字符 
5)\ 转义字符
6)* 重复0个或多个前面的一个字符，不代表所有(此时*不是统配符)
7).* 匹配所有的字符 ^.* 任意多个字符开头
8)[abc] 匹配字符集合内任意一个字符[a-z]
9)[^abc] 表示取反，表示不包含a或b或c的内容
10){n,m}表示重复n到m次，前一个字符
    {n,} 至少n次，多了不限
    {n} n次
    {,m} 至多m次，少了不限
   注:grep 要对{}进行转义\{\}，egrep 不需要转义了
   egrep ==grep -E
grep 命令：
-v 排除匹配的内容
-E 支持扩展的正则表达式
-i 忽略大小写
-o 输出匹配的字符
--color=auto 匹配的内容显示颜色
-n 显示行号
sed:
s 替换
g全局替换
-i 修改文件
-n 取消默认输出
p 打印内容
过滤IP地址和广播地址：
ifconfig eth0 | sed -n 's/^.*dr:\(.*\) B.*t:\(.*\)  Ma.*$/\1\2/gp'
ifconfig eth0 | grep 'inet addr' | awk -F '[: ]+' '{print $4}'
ifconfig eth0 |sed -n '2p'|awk -F '[: ]+' '{print $4}'
ifconfig eth0 | awk -F '[: ]+' 'NR==2 {print $4}'    //NR表示第几行
扩展正则表达式：egrep/grep -E
1) + 重复一个或一个以上前面
2) ? 重复0个或一个0前面的字符
3) | 用或的方式查找多个符合的字符串
4)()找出'用户组'字符
awk
NR 行号
NF 当前记录域或列的个数
$NF 代表最后一列

[root@Linux shell]# stat /etc/passwd
  File: `/etc/passwd'
  Size: 1517            Blocks: 8          IO Block: 4096   regular file
Device: 801h/2049d      Inode: 533456      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2015-05-30 01:19:01.814999984 +0800
Modify: 2015-05-17 18:30:55.233764056 +0800
Change: 2015-05-17 18:30:55.235763056 +0800
通配符：
 * 任意字符串
? 任意单个字符
{c1,c2} 同c1或者c2匹配，c1,c2也可以是统配符 {[0-9]*,[abcd]}
PS1
PS2
PS3 select发出的提示符
PS4 shell调试提示符+
1.关闭不必要的服务
ntsysv chkconfig
必须开启的服务有：	crond/messagebus/network/iptables/sshd/syslog/sysstat/snmpd
关闭不必要的服务脚本：
for i in `chkconfig --list |awk '/3:on/ {print $1}'|grep -v "crond\|	messagebus\|sshd\|iptables\|network\|syslog\|snmpd\|sysstat"`; 
do  chkconfig --level 345 ${i} off; 
done
开启需要的服务脚本：
for i in "crond" "messagebus" "iptables" "network" "snmpd" "sshd" 	"syslog" "sysstat";
do  chkconfig --level 345 ${i} on; 
done
3.检查服务的基本配置
dmidecode | grep "Product" | head -n 1  检查服务器型号
cat /proc/cpuinfo | grep name | cut -f2 -d: |uniq -c 检查CUP信号
free -m | grep Mem | awk '{print $2}'
ifconfig | grep "inet addr" | awk -F: '{print $2}'| awk '{print $1}'
4.系统优化修改/etc/sysctl.conf文件，sysctl -p 是修改生效；
关闭不必要的服务使用ntsysv;查看自启动服务chkconfig;
5.修改系统的文件句柄数/etc/security/limits.conf   确认句柄允许数据ulimit -n
6.修改sshd监听端口，并禁止密码验证登录配置文件/etc/ssh/sshd_config
7.账号安全，清除除root用户之外的其他用户的登录权限
     #!/bin/bash
    for k in `cat /etc/passwd | grep -i "\/bin\/bash" | grep -v "root" | cut -d: -f1`;
    do
    usermod -s /sbin/nologin ${k};
    done
    更改root用户密码：
    echo "xxxxxxxx" >/root/tmp.txt   “xxxxxxxx”为设定的密码
    passwd root --stdin </root/tmp.txt ；rm –f /root/tmp.txt
8.查看系统的基本信息脚本
    #!/bin/bash
    dmidecode | grep "Product" | head -n 1
    cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
    free -m | grep Mem | awk '{print $2}'
    ifconfig | grep "inet addr" | awk -F: '{print $2}'| awk '{print $1}'
    route -n 
    cat /etc/issue | head -n 1
    uname -a
    df -h | awk '{print $1,$2}'
9.加载ext4模块
    modprobe ext4
    lsmod | grep ext4
    yum -y install e4fsprogs
10.统计登陆用户数
uptime | cut -d',' -f 2 | sed 's/^[[:space:]]*//g'
who | wc -l 
11.添加用户脚本
#!/bin/bash
id $1 >/dev/null 2>&1
if [ $? -eq 0 ];then
        echo "$1 is exsit!"
else
        useradd $1
        echo "123456" | passwd --stdin "$1" >/dev/null 2>&1
        if [ $? -eq 0 ];then
                echo "$1 create seccuss!"
        fi
fi
12.Shell 脚本中有个变量叫IFS(Internal Field Seprator) ，内部域分隔符,当 shell 处理"命令替换"和"参数替换"时，shell 根据 IFS 的值，默认是 space, tab, newline 来拆解读入的变量，然后对特殊字符进行处理，最后重新组合赋值给该变量
实际应用
#!/bin/bash
OLD_IFS=$IFS #保存原始值
IFS="" #改变IFS的值
...
...
IFS=$OLD_IFS #还原IFS的原始值

正在运行的内核和系统信息
# uname -a # 获取内核版本（和BSD版本）
# lsb_release -a # 显示任何 LSB 发行版版本信息
# cat /etc/SuSE-release # 获取 SuSE 版本
# uptime # 显示系统开机运行到现在经过的时间
# hostname # 显示系统主机名
# hostname -i # 显示主机的 IP 地址
# man hier # 描述文件系统目录结构
# last reboot # 显示系统最后重启的历史记录
硬件信息
内核检测到的硬件信息
# dmesg # 检测到的硬件和启动的消息
# lsdev # 关于已安装硬件的信息
# dd if=/dev/mem bs=1k skip=768 count=256 2>/dev/null | strings -n 8 # 读取 BIOS 信息
Linux
# cat /proc/cpuinfo                  # CPU 讯息
# cat /proc/meminfo                  # 内存信息
# grep MemTotal /proc/meminfo        # 显示物理内存大小
# watch -n1 'cat /proc/interrupts'   # 监控内核处理的所有中断
# free -m                            # 显示已用和空闲的内存信息 (-m 为 MB)
# cat /proc/devices                  # 显示当前核心配置的设备
# lspci -tv                          # 显示 PCI 设备
# lsusb -tv                          # 显示 USB 设备
# lshal                              # 显示所有设备属性列表
# dmidecode                          # 显示从 BIOS 中获取的硬件信息
显示状态信息
以下的命令有助于找出正在系统中运行着的程序。
# top                                # 显示和更新使用 cpu 最多的进程
# mpstat 1                           # 显示进程相关的信息
# vmstat 2                           # 显示虚拟内存的状态信息
# iostat 2                           # 显示 I/O 状态信息(2 秒 间隙)
# tail -n 500 /var/log/messages      # 显示最新500条内核/系统日志的信息
# tail /var/log/warn                 # 显示系统警告信息(看syslog.conf) 
用户
# id                                 # 显示当前用户和用户组的 ID
# last                               # 列出目前与过去登入系统的用户相关信息
# who                                # 显示目前登入系统的用户信息
# groupadd admin                     # 建立新组"admin"和添加新用户 colin 并加入 admin 用户组(Linux/Solaris)
# useradd -c "Colin Barschel" -g admin -m colin
# userdel colin                      # 删除用户 colin(Linux/Solaris)
# adduser joe                        # FreeBSD 添加用户 joe(交互式)
# rmuser joe                         # FreeBSD 删除用户 joe(交互式)
# pw groupadd admin                  # 在 FreeBSD 上使用 pw
# pw groupmod admin -m newmember     # 添加新用户到一个组
# pw useradd colin -c "Colin Barschel" -g admin -m -s /bin/tcsh 
# pw userdel colin; pw groupdel admin 
加密过的密码存储在 /etc/shadow (Linux and Solaris) 
使用 nologin 来临时阻止所有用户登录(root除外)。用户登录时将会显示 nologin 中的信息。
# echo "Sorry no login now" > /etc/nologin       # (Linux) 
限制
某些应用程序需要设置可打开最大文件和 socket 数量(像代理服务器，数据库)。 默认限制通常很低。
Linux
每 shell/脚本
shell 的限制是受 ulimit 支配的。使用 ulimit -a 可查看其状态信息。 举个例子，改变可打开最大文件数从 1024 到 10240，可以这么做：
# ulimit -n 10240                    # 这只在shell中有用 
ulimit 命令可以使用在脚本中来更改对此脚本的限制。
每 用户/进程
登录用户和应用程序的限制可以在 /etc/security/limits.conf 中配置。举个例子：
# cat /etc/security/limits.conf
*   hard    nproc   250              # 限制所有用户进程数
asterisk hard nofile 409600          # 限制应用程序可打开最大文件数 
系统级
用sysctl来设置内核限制。要使其永久，可以在 /etc/sysctl.conf 中进行配置。
# sysctl -a                          # 显示所有系统限制
# sysctl fs.file-max                 # 显示系统最大文件打开数
# sysctl fs.file-max=102400          # 更改系统最大文件打开数
# cat /etc/sysctl.conf
fs.file-max=102400                   # 在 sysctl.conf 中的永久项
# cat /proc/sys/fs/file-nr           # 在使用的文件句柄数
运行级别
Linux
一旦内核加载完成，内核会启动 init 进程，然后运行 rc 脚本，之后运行所有属于其运行级别的命令脚本。这些脚本都储存在 /etc/rc.d/rcN.d 中(N代表运行级别)，并且都建立着到 /etc/init.d 子目录中命令脚本程序的符号链接。
默认运行级别配置在 /etc/inittab 中。它通常为 3 或 5：
# grep default: /etc/inittab                                         
id:3:initdefault: 
可以使用 init 来改变当前运行级别。举个例子：
# init 5                             # 进入运行级别 5
运行级别列表如下：
    - 0       系统停止
    - 1       进入单用户模式(也可以是 S)
    - 2       没有 NFS 特性的多用户模式
    - 3       完全多用户模式(正常操作模式)
    - 4       未使用
    - 5       类似于级别3，但提供 XWindow 系统登录环境
    - 6       重新启动系统
使用 chkconfig 工具控制程序在一个运行级别启动和停止。
# chkconfig --list                   # 列出所有 init 脚本
# chkconfig --list sshd              # 查看 sshd 在各个运行级别中的启动配置
# chkconfig sshd --level 35 on       # 对 sshd 在级别 3 和 5 下创建启动项
# chkconfig sshd off                 # 在所有的运行级别下禁用 sshd
重设 root 密码
Linux 方法 1
在引导加载器(lilo 或 grub)中，键入如下启选项：
init=/bin/sh
内核会挂载 root 分区，进程 init 会启动 bourne shell 而不是 rc，然后是运行级别。使用命令 passwd 设置密码然后重启。别忘了需要在单用户模式下做这些动作。
如果重启后 root 分区被挂载为只读，重新挂在它为读写：
# mount -o remount,rw /
# passwd                             # 或者删除 root 密码 (/etc/shadow)
# sync; mount -o remount,ro /        # sync 在重新挂在为只读之前 sync 一下
# reboot 

内核模块
Linux
# lsmod                              # 列出所有已载入内核的模块
# modprobe isdn                      # 载入 isdn 模块
编译内核
Linux
# cd /usr/src/linux
# make mrproper                      # 清除所有东西，包括配置文件
# make oldconfig                     # 从当前内核配置文件的基础上创建一个新的配置文件
# make menuconfig                    # 或者 xconfig (Qt) 或者 gconfig (GTK)
# make                               # 创建一个已压缩的内核映像文件
# make modules                       # 编译模块
# make modules_install               # 安装模块
# make install                       # 安装内核
# reboot 

要重建完全的操作系统：
# make buildworld                    # 构建完全的系统，但不是内核
# make buildkernel                   # 使用 KERNCONF 配置文件编译内核
# make installkernel
# reboot
# mergemaster -p                     # 建立临时根环境并比对系统配置文件
# make installworld
# mergemaster                        # 升级所有配置和其他文件
# reboot 
对于源的一些小改动，有时候简单的命令就足够了：
# make kernel world                  # 编译并安装内核和系统
# mergemaster
# reboot 
进程
列表 | 优先级 | 后台/前台 | Top | Kill
进程列表
PID是每个进程唯一号码。使用 ps 获取所有正在运行的进程列表。
# ps -auxefw                         # 所有正在运行进程的详尽列表
然而，更典型的用法是使用管道或者 pgrep:
# ps axww | grep cron
586  ??  Is     0:01.48 /usr/sbin/cron -s
# ps aux | grep 'ss[h]'              # Find all ssh pids without the grep pid
# pgrep -l sshd                      # 查找所有进程名中有sshd的进程ID
# echo $$                            # The PID of your shell
# fuser -va 22/tcp                   # 列出使用端口22的进程
# fuser -va /home                    # 列出访问 /home 分区的进程
# strace df                          # 跟踪系统调用和信号
# truss df                           # 同上(FreeBSD/Solaris/类Unix)
# history | tail -50                 # 显示最后50个使用过的命令 
优先级
用 renice 更改正在运行进程的优先级。负值是更高的优先级，最小为-20，其正值与 "nice" 值的意义相同。
# renice -5 586                      # 更强的优先级
586: old priority 0, new priority -5 
使用 nice 命令启动一个已定义优先级的进程。 正值为低优先级，负值为高优先级。确定你知道 /usr/bin/nice 或者使用 shell 内置命令(# which nice)。
# nice -n -5 top                     # 更高优先级(/usr/bin/nice)
# nice -n 5 top                      # 更低优先级(/usr/bin/nice)
# nice +5 top                        # tcsh 内置 nice 命令(同上) 
nice 可以影响 CPU 的调度，另一个实用命令 ionice 可以调度磁盘 IO。This is very useful for intensive IO application which can bring a machine to its knees while still in a lower priority. 此命令仅可在 Linux (AFAIK) 上使用。你可以选择一个类型(idle - best effort - real time)，它的 man 页很短并有很好的解释。
# ionice c3 -p123                    # 给 pid 123 设置为 idle 类型
# ionice -c2 -n0 firefox             # 用 best effort 类型运行 firefox 并且设为高优先级
# ionice -c3 -p$$                    # 将当前的进程(shell)的磁盘 IO 调度设置为 idle 类型 
例中最后一条命令对于编译(或调试)一个大型项目会非常有用。每一个运行于此 shell 的命令都会有一个较低的优先级，但并不妨碍这个系统。$$ 是你 shell 的 pid (试试 echo $$)。
前台/后台
当一个进程在 shell 中已运行，可以使用 [Ctrl]-[Z] (^Z), bg 和 fg 来 调入调出前后台。举个例子：启动 2 个进程，调入后台。使用 jobs 列出后台列表，然后再调入一个进程到前台。
# ping cb.vu > ping.log
^Z                                   # ping 使用 [Ctrl]-[Z] 来暂停(停止) 
# bg                                 # 调入后台继续运行
# jobs -l                            # 后台进程列表
[1]  - 36232 Running                       ping cb.vu > ping.log
[2]  + 36233 Suspended (tty output)        top
# fg %2                              # 让进程 2 返回到前台运行


read 可以一次读取所有的值到多个变量，一$IFS里的字符为分隔输入行里的数据
当使用read -r 参数时，read不会将结尾的反斜线视为特殊字符

重定向：file > results 2>errors         //把标准错误输出信息放到erros文件里
        file > results 2> /dev/null     //丢弃标准错误输出的信息
        file > results 2>&1            //标准输出和标准错误输出信息都放到results文件里

在shell脚本里，对于临时性文件一般是通过$$进程号进行命令文件

查找文件可以是locate，find
locate是将文件系统的所有文件名压缩成数据库，以迅速找到匹配shell通配符的文件
寻找命令存储位置  type
/dev/random 和/dev/urandom 特殊字符，产生大量随机数
/dev/random 会一直封锁，直到填入的随机数够用
/dev/urandom 不会封锁，速度快
系统在正常关机下，进程的删除是以由大到小的进程ID依此执行，直到剩下init为止
当程序不正常终止时，可能会在文件系统离留下残余数据。这些数据本应删除，除了浪费空间外，还可能导致程序下次无法执行
只列出目录：
ls -ld */
ls -la | grep '^d'
$# 是传给脚本的参数个数
$0 是脚本本身的名字
$1 是传递给该shell脚本的第一个参数
$2 是传递给该shell脚本的第二个参数
$@ – 以 $IFS 为分隔符列出所有传递到脚本中的参数
$* 是以一个单字符串显示所有向脚本传递的参数，与位置变量不同，参数可超过9个
$$ 是脚本运行的当前进程ID号
$? 是显示最后命令的退出状态，0表示没有错误，其他表示有错误
basename $0 只返回脚本名
$*变量会将所有的参数当成单个参数，而$@变量会单独处理每个参数。

inode 表格大小为文件系统安装时就已固定，所以文件系统即使仍有空间置放文件数据，也可能出现已满的状态
linux查看已挂载分区的当前挂载参数： cat /proc/mounts    参数详细
fstab中，分区挂载的defaults：rw,suid,dev,exec,auto,nouser,async       
suid,允许suid命令生效   exec允许执行二进制文件  auto 可以用-a参数mount
nouser 禁止非root用户mount async I/O请求异步
atime:文件访问时间
mtime:文件内容修改时间
ctime:文件更改状态时间
写入文件，一定会改变mtime,ctime
chmod,chown等会改变ctime，不会改变mtime
文件夹的mtime,ctime,atime
文件夹中，有文件的新建和删除会改变mtime
文件夹中的文件ctime改变，文件夹的ctime就一起改变
文件夹下的文件列表或文件被访问，文件夹的atime就会改变
MBR主引导记录，位于硬盘的0道0面1扇区，大小512字节，MBR引导程序占446个字节
随后的64个是硬盘分区表，最后两个为分区结束标志
dd if=/dev/sda of=mbr bs=512 count=1
xxd mbr //xxd 是linux下的一个十六进制输出命令 yum install vim-common
pv 物理卷
pvscan 扫描pv
lvscan 扫描lv
重新调整分区大小以后，需要再次格式化。如果没有格式化，或者格式化的文件系统类型不对，swapon就会报错：Invalid argument
mkswap /dev/xxxx
swapon /dev/xxxx
swapoff /dev/xxx
linux 限制用户资源_限制单个制定用户或用户组资源的方法
vi /etc/security/limits.conf
每一行的用户限制格式为:<domain> <type> <item> <value>
1.domain 可以是一个用户名,一个以@开拓的用户组名，* 代表所有
2.type 可以是soft 和hard 
3.item 限制项
- core - limits the core file size (KB)
- data - max data size (KB)
- fsize - maximum filesize (KB)
- memlock - max locked-in-memory address space (KB)
- nofile - max number of open files
- rss - max resident set size (KB)
- stack - max stack size (KB)
- cpu - max CPU time (MIN)
- nproc - max number of processes
- as - address space limit
- maxlogins - max number of logins for this user
- maxsyslogins - max number of logins on the system
- priority - the priority to run user process with
- locks - max number of file locks the user can hold
- sigpending - max number of pending signals
- msgqueue - max memory used by POSIX message queues (bytes)
- nice - max nice priority allowed to raise to
- rtprio - max realtime priority
4.value 限制值 任意整数，或 unlimited
eg： shellcn soft    nofile    100
linux系统中，每当进程打开一个文件时，系统就为其分配一个唯一的整形文件描述符，用来标示这个文件
系统默认的最大文件描述符限制为1024    ulimit -a
web服务器等，可以通过在/etc/rc.d/rc.local文件中用 ulimit -Hsn 65536进行修改文件的描述符数
curl命令是linux shell下用来获取网页内容的常用命令,curl默认有个比较讨厌的功能，就是常常自动显示出统计信息
curl -s http://www.shellcn.net|grep abc   //-s 静默模式
用ls 按照mtime,ctime,atime对文件进行排序，分别对应tl,ctl,utl
man 命令数组说明：
1.通用命令(General Commands)
2.系统调用指令(System Calls)
4.特殊文件(Special Files)
5.文件格式(File Formats)
6.游戏(Games)
7.宏和协议(Macros and Conventions)
8.系统维护命令(Maintenence Commands)
linux中的资源限制分为软限制和硬限制，ulimit 硬限制一旦设置就不能增加，软限制能够最多增加到硬限制的值。
ls -l 七个字段的说明：
权限,硬链接数或目录的子目录数，所有者，所属用户组,文件大小byte，mtime（修改时间，最后一次写文件内容时间）,文件名
扩展正则表达式与基础正则表达式的唯一区别在于：? + () {} 这几个字符 ，扩展正则表达式与基础正则表达式的区别，就是它们加不加转义符号，代表的意思刚好相反。
=~符号在shell条件判断中，用来表示是否匹配。=~右边是正则表达式，=~左边是被匹配的字符串
str=www.shellcn.net
if [[ "$str"  =~ shellcn.net$ ]]
then
echo matched
fi
=~右侧的正则表达式不能被引号括起来，否则将不会得到正确结果。
请牢记=~的使用格式。任何格式的错误都会导致匹配功能的失效。
=~是shell中的匹配符号，=~左侧的变量最好加引号，右侧的为正则表达式，正则表达式上不能加引号，加了引号正则就没用了，当字符串处理了
匹配空行，shell脚本实现：    [[ str1 =~ str1 ]] 这个就是正则匹配啊，str1 和普通的字符串一样，不使用//来表示正则
cat 1.txt |while read line
do if [[ "$line" =~ ^$ ]]
then echo 空行
fi
done
[ ] 实际上是bash 中 test 命令的简写。即所有的 [ expr ] 等于 test expr
[[ expr ]] 是bash中真正的条件判断语句
在 [[ 中使用 && 和 || 
[ 中使用 -a 和 -o 表示逻辑与和逻辑或。
[[ 中可以使用通配符
arch=i486 
[[ $arch = i*86 ]] && echo "arch is x86!" 
[[ 中匹配字符串或通配符，不需要引号
用grep -c来统计匹配到的字符的行数 
1. [[ `grep -c "test" test` -eq 0 ]] && echo "OK"  

 2.   $coun=`grep -c "test" test`
        if [ $coun -eq 0 ];then
            echo "OK"
        fi
命令1和2是等价的
-gt,-lt是算数比较操作
> < == 是字符比较操作
== 用于字符串比较
=    用于字符串赋值
-eq 等于,如:if [ "$a" -eq "$b" ]  
-ne 不等于,如:if [ "$a" -ne "$b" ]  
-gt 大于,如:if [ "$a" -gt "$b" ]  
-ge 大于等于,如:if [ "$a" -ge "$b" ]  
-lt 小于,如:if [ "$a" -lt "$b" ]  
-le 小于等于,如:if [ "$a" -le "$b" ]  
<   小于(需要双括号),如:(("$a" < "$b"))  
<=  小于等于(需要双括号),如:(("$a" <= "$b"))  
>   大于(需要双括号),如:(("$a" > "$b"))  
>=  大于等于(需要双括号),如:(("$a" >= "$b")) 
f1 -nt f2                   文件f1是否比f2新
f1 -ot f2                   文件f1是否比f2旧
f1 -ef f2                   文件f1和f2是否硬连接到同一个文件
在使用数值比较的时候，用(())，减少出错
"["：    逻辑与："-a"；逻辑或："-o"；
"[["：    逻辑与："&&"；逻辑或："||"
$ [[ 99+1 -eq 100 ]]&&echo true||echo false
true
$ [ $((99+1)) -eq 100 ]&&echo true||echo false
true
linux系统中，通配符一般只应用于文件名的匹配 ? * [a-z] [0-9] [!a]
ls *.txt #匹配txt结尾的文件
ls [0-9]*.txt #匹配0-9开头的,.txt结尾的文件
ls [!1].txt #匹配不是1开头的只有一位字符的txt文件，如a.txt 3.txt
ls -a| awk '$1~/^\./ {print $1}'
~：正则表达式的匹配运算符
echo 默认会自动换行的
[root@shellcn.net ~#] echo -e "linux\c";echo shell
linuxshell
\c 反斜杠转义后的意思为：不产生额外的输出，即不产生额外的换行符
while read line
do
    echo $line
done < filename
cat >1.txt <<EOF   #将分界符EOF之间的文本输入到1.txt
A
B
C
EOF
head -n -1 shellcn.txt    //-number 可以直接实现打印 除最后指定行数 的所有行
tail -n +8 test.txt     //    从第八行开始
xargs是一条Unix和类Unix操作系统的常用命令。它的作用是将参数列表转换成小块分段传递给其他命令，以避免参数列表过长的问题
//变量的变量引用
#!/bin/bash
a0="abc";
j=0
b="a"$j;
此时$b=a0;
如何利用b取a0的值？
echo ${!b}
until循环执行命令至到条件为true时停止执行，until循环与while循环相反。一般while循环优于until循环，但较少使用
until 测试条件; do 
语句1 语句2 ... 
done
while循环用于不断执行的一系统命令，也可以从文件中读取数据，大多数用于测试条件，while循环语法格式：
while 测试条件; do 
语句1 语句2 ... 
done
case … esac是一种多分枝选择结构，case语句匹配一个值或一个模式，如果匹配成功，执行相匹配的命令
每一个模式必须以括号结果，值可以为变量或常数。匹配发现取值符合某一模式后，其间所有命令开始执行直至遇见;;。“;;”号意思是跳到整个case语句的最后。取值将检测匹配的每一个模式，一旦模式匹配，则执行匹配模式相应的命令后不再继续其他模式，如果无一匹配模式，使用星号“*”捕获该值，再执行后面的命令

case 值 in
value1)
             语句1 
             ...
             ;; 
value2) 
            语句1 
            ... 
            ;; 
value3) 
            语句1 
            ...
            ;;
 *) 
            语句1 
            ... 
            ;; 
esac 
短路运算符操作；只要前半段已经可以决定最终结果，后半段就不会再执行运算
cmd1 && cmd2
        1.若cmd1执行完毕且正确执行($?=0),则开始执行cmd2
        2.若cmd1执行完毕但为错误($?！=0),则不执行cmd2
cmd1 || cmd2   
        1.若cmd1执行完毕且正确执行($?=0),则不执行cmd2
        2.若cmd1执行完毕但为错误($?！=0),则执行cmd2
字符测试语句：
>：大于 <：小于 如：if [ "$A \< "$B" ]注：在[]中"<"需要用"\"转义 ==：等于 如：if [ "$A" == "$B" ] =~：判断左加字符串是否能够被右边的模式匹配，大部分用用[[]]中。 [[ $A =~ $B ]] -z：为空则为真，不为空则为假 -n：为空则为假，不为空则为真
这个计算需要用的生成数字序列：seq [起始数字] [步长] 结束数字：如：seq 1 2 100：
odd=$[$odd+$I]    //数字
-s file    检测文件是否为空（文件大小是否大于0），不为空返回 true
-e file    检测文件（包括目录）是否存在，如果是，则返回 true
s_base_time=`ssh $ip "stat $path/homed_base/bin |tee | grep Modify | awk -F. '{print $'1'}'"`      //特殊
ssh $ip "stat $path/homed_base/bin |tee | grep Modify | awk -F. '{print \$1}'" //不赋值给变量
遍历目录
#!/bin/sh    
list_alldir(){    
    for file2 in `ls -A $1`    
    do    
        if [ -d "$1/$file2" ];then    
            echo "$1/$file2"    
          list_alldir "$1/$file2"    
         fi     
    done    
 }    
  list_alldir ./test 
shell脚本 --if(数字条件，文件，字符串) 常用
[-a file] 如果file存在则为真
[-b file] 如果file存在且是一个块特殊文件则为真
[-c file] 如果file存在且是一个字特殊文件则为真
[-d file] 如果file文件存在且是一个目录则为真
-d前的!是逻辑非
例如：
if [ ! -d $lcd_path/$par_date ]
表示后面的那个目录不存在，则执行后面的then操作
[-e file] 如果file文件存在则为真
[-f file] 如果file存在且是一个普通文件则为真
[-g file] 如果file存在且已经设置了SGID则为真（SUID 是 Set User ID, SGID 是 Set Group ID的意思）
[-h file] 如果file存在且是一个符号连接则为真
[-k file] 如果file存在且已经设置粘制位则为真
当一个目录被设置为"粘制位"(用chmod a+t),则该目录下的文件只能由
一、超级管理员删除
二、该目录的所有者删除
三、该文件的所有者删除
也就是说,即便该目录是任何人都可以写,但也只有文件的属主才可以删除文件。
具体例子如下：
#ls -dl /tmp
drwxrwxrwt 4 root    root  .........
注意other位置的t，这便是粘连位。
[-p file] 如果file存在且是一个名字管道（F如果O）则为真
管道是linux里面进程间通信的一种方式，其他的还有像信号（signal）、信号量、消息队列、共享内存、套接字（socket）等。  
[-r file] 如果file存在且是可读的则为真
[-s file] 如果file存在且大小不为0则为真
[-t FD] 如果文件描述符FD打开且指向一个终端则为真
[-u file] 如果file存在且设置了SUID（set userID）则为真
[-w file] 如果file存在且是可写的则为真
[-x file] 如果file存在且是可执行的则为真
[-O file] 如果file存在且属有效用户ID则为真
[-G file] 如果file存在且属有效用户组则为真
[-L file] 如果file存在且是一个符号连接则为真
[-N file] 如果file存在and has been mod如果ied since it was last read则为真
[-S file] 如果file存在且是一个套接字则为真
[file1 –nt file2] 如果file1 has been changed more recently than file2或者file1 exists and file2 does not则为真
[file1 –ot file2] 如果file1比file2要老，或者file2存在且file1不存在则为真
[file1 –ef file2] 如果file1和file2指向相同的设备和节点号则为真
[-o optionname] 如果shell选项“optionname”开启则为真
[-z string] “string”的长度为零则为真
[-n string] or [string] “string”的长度为非零non-zero则为真
[sting1==string2] 如果2个字符串相同。“=”may be used instead of “==”for strict posix compliance则为真
[string1!=string2] 如果字符串不相等则为真
[string1<string2] 如果“string1”sorts before“string2”lexicographically in the current locale则为真
[arg1 OP arg2] “OP”is one of –eq,-ne,-lt,-le,-gt or –ge.These arithmetic binary oprators return true if “arg1”is equal to,not equal to,less than,less than or equal to,greater than,or greater than or equal to“agr2”,respectively.“arg1”and “agr2”are integers. 
整数比较：
-eq
-ne
-gt
-ge
-lt
-le
字符串比较：
==     //等于
=    //等于
！=    //不等于
-z    //字符串长度为0
-n    //字符串长度不为0
文件比较:
-e    //文件存在
-f    //普通文件
-s    //文件长度不为0
-d    //被测对象是目录
-b    //被测对象是块设备
-c    //被测对象是字符设备
-L    //被测文件是符号连接
-S    //被测文件是一个socket
-r    //文件具有读权限
-w    //写权限
-x    //执行权限
-o    //文件的所有者
-G    //文件的组
-N    //从文件最后被阅读到现在，是否被修改
f1 -nt f2    //文件f1是否比f2新
f1 -ot  f2    //文件f1是否比f2旧
如何避免shell脚本被同时运行多次
#!/bin/bash
LOCK_NAME="/tmp/my.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null;
then
trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT
### 开始正常流程
### 正常流程结束
### Removing lock
rm -f $LOCK_NAME
trap - INT TERM EXIT
else
echo "Failed to acquire lockfile: $LOCK_NAME."
echo "Held by $(cat $LOCK_NAME)"
exit 1
fi
echo "Done."
 
set -o noclobber 的意思：
If set, bash does not overwrite an existing file with the >, >&, and <> redirection operators.
 
这样就能保证my.lock只能被一个进程创建出来。比touch靠谱多了。
trap 可以捕获各种信号，然后做出处理：
INT 用来处理 ctrl+c取消脚本执行的情况。
TERM 用来处理 kill -TERM pid 的情况。
`cat /etc/passwd`     $(cat /etc/passwd)    反引号和$()作用一样
read
read命令接收标准输入（键盘）的输入，或其他文件描述符的输入（后面在说）。得到输入后，read命令将数据放入一个标准变量中。下面是 read命令
#!/bin/bash
echo -n "Enter your name:"   //参数-n的作用是不换行，echo默认是换行
read  name                   //从键盘输入
echo "hello $name,welcome to my program"     //显示信息
exit 0                       //退出shell程序。
由于read命令提供了-p参数，允许在read命令行中直接指定一个提示。
read -p "Enter your name:" name  等价于  echo -n "Enter your name:" read name 
在上面read后面的变量只有name一个，也可以有多个，这时如果输入多个数据，则第一个数据给第一个变量，第二个数据给第二个变量，如果输入数 据个数过多，则最后所有的值都给第一个变量。如果太少输入不会结束。
在read命令行中也可以不指定变量.如果不指定变量，那么read命令会将接收到的数据放置在环境变量REPLY中。
使用read命令存在着潜在危险。脚本很可能会停下来一直等待用户的输入。如果无论是否输入数据脚本都必须继续执行，那么可以使用-t选项指定一个 计时器。
-t选项指定read命令等待输入的秒数。当计时满时，read命令返回一个非零退出状态
if read -t 5 -p "please enter your name:" name
除了输入时间计时，还可以设置read命令计数输入的字符。当输入的字符数目达到预定数目时，自动退出，并将输入的数据赋值给变量。
read -n1 -p "Do you want to continue [Y/N]?" answer
-s选项能够使read命令中输入的数据不显示在监视器上（实际上，数据是显示的，只是 read命令将文本颜色设置成与背景相同的颜色）
每次调用read命令都会读取文件中的"一行"文本。当文件没有可读的行时，read命令将以非零状态退出。
读取文件的关键是如何将文本中的数据传送给read命令。
最常用的方法是对文件使用cat命令并通过管道将结果直接传送给包含read命令的 while命令
#!/bin/bash
count=1    //赋值语句，不加空格
cat test | while read line        //cat 命令的输出作为read命令的输入,read读到的值放在line中
do
   echo "Line $count:$line"
   count=$[ $count + 1 ]          //注意中括号中的空格。
done
echo "finish"
exit 0
eval命令将会首先扫描命令行进行所有的置换，然后再执行该命令。该命令适用于那些一次扫描无法实现其功能的变量。该命令对变量进行两次扫描。这些需要进行两次扫描的变量有时被称为复杂变量。不过这些变量本身并不复杂
eval命令也可以用于回显简单变量，不一定是复杂变量。

 eval temp="$""$srv"_ips
 list=`echo $temp | sed 's/ /\n/g' | sort -u`
首先我们首先创建一个名为test的小文件，在这个小文件中含有一些文本。接着，将cat test赋给变量myfile，现在我们e c h o该变量，看看是否能够执行上述命令。
[neau@mail ~]$ vi test
[neau@mail ~]$ cat test
Hello World!!!
I am a chinese Boy!
将cat testf赋给变量myfile
[neau@mail ~]$ myfile="cat test"
如果我们e c h o该变量，我们将无法列出t e s t 文件中的内容。
[neau@mail ~]$ echo $myfile
cat test
让我们来试一下e v a l命令，记住e v a l命令将会对该变量进行两次扫瞄。
[neau@mail ~]$ eval $myfile
Hello World!!!
I am a chinese Boy!
从上面的结果可以看出，使用e v a l命令不但可以置换该变量，还能够执行相应的命令。第
一次扫描进行了变量置换，第二次扫描执行了该字符串中 所包含的命令cat test
netstat -n
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 123.123.123.123:80      234.234.234.234:12345   TIME_WAIT
netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,"\t",state[key]}'
/^tcp/
滤出tcp开头的记录，屏蔽udp, socket等无关记录。
state[]相当于定义了一个名叫state的数组
NF
表示记录的字段数，如上所示的记录，NF等于6
$NF
表示某个字段的值，如上所示的记录，$NF也就是$6，表示第6个字段的值，也就是TIME_WAIT
state[$NF]表示数组元素的值，如上所示的记录，就是state[TIME_WAIT]状态的连接数
++state[$NF]表示把某个数加一，如上所示的记录，就是把state[TIME_WAIT]状态的连接数加一
END
表示在最后阶段要执行的命令
for(key in state)
遍历数组
print key,"\t",state[key]打印数组的键和值，中间用\t制表符分割，美化一下。
sed && awk
使用sed在一个文件的制定位置插入另一个文件的内容-r命令
在一个文件的指定位置，如匹配到一个单词的行的下一行插入另一个文件的全部内容，可以使用sed的r命令
sed '/test/r file' data    //在data文件中查找test字符，并在该行后插入file文件的全部内容
echo "1 2 3 4" | sed 's/ /\n/g'
eval temp="$""$srv"_ips
list=`echo $temp | sed 's/ /\n/g' | sort -u`
cat a.txt | sed 's/[a-z]*/\U&/g'|sed 's/[A-Z]*/\L&/g'    //以单词为单位，大小写转换，U L是把所有单词都大小写，u,l是每个单词的首字母，&代表前面匹配到的
cat a.txt | sed 's/[a-z]/\U&/g'|sed 's/[A-Z]/\L&/g'  //不带* 是针对所有字母，以字母为单位进行匹配
sed 's/^[a-z]/\u&/g' wangdong.sh    //每行的首个字母大写
awk 中END是最后才执行的
cat grade.txt | awk '{sum=$2+$3+$4+$5+$6} {print $1,sum/5}' 
    执行过程是，每读取一行数据，进行计算一次，然后打印出来
cat grade.txt | awk '{sum=$2+$3+$4+$5+$6} END{print $1,sum/5}'
    执行过程是，数据会逐行被处理，但是只打印出最后一行
cat grade.txt | awk '{ sum=$2+$3+$4+$5+$6} {print $1,sum/5} END{print NR,"records"}'
cat grade.txt | awk 'BEGIN{print "name","avg"} {sum=$2+$3+$4+$5+$6} {print $1,sum/5} END{print NR,"records"}'
    BEGIN用在报表的开头打印，仅执行一次
    END最后执行的，仅执行一次
awk 中 print输出指定内容后换行，printf只输出指定内容后不换行
awk默认是以行为单位处理文本的，对1.txt中的每一行都执行后面 "{ }" 中的语句。
awk中的两个术语：
记录（默认就是文本的每一行）
字段 （默认就是每个记录中由空格或TAB分隔的字符串）
$0就表示一个记录，$1表示记录中的第一个字段

短程序通常直接在命令行上提供，比较长的程序通常委托-f选项指定
RS ORS FS OFS的区别

RS和ORS是定义行的,RS是awk读取文件时的行分隔符，ORS则是awk输出时的行结束符。
默认，RS的值是\n
[root@slave30(130) /homed/ilogslave/config]# echo '1a2b3c' | awk '{print $1}'
1a2b3c
[root@slave30(130) /data1/wangdong]# echo '1ab2bc3cd4de5' | awk 'BEGIN{RS="[a-z]+"}{print $1,RS,RT}'
1 [a-z]+ ab
2 [a-z]+ bc
3 [a-z]+ cd
4 [a-z]+ de
5 [a-z]+ 

更简单的讲，就是awk在输出时，会在每行记录后面增加一个ORS变量所设定的值。
ORS的值只能设定为字符串，默认情况下，ORS的值是\n 
seq 5 | awk '{print $0}'
1
2
3
4
5
seq 5 | awk 'BEGIN{ORS="a"}{print $0}'
1a2a3a4a5a

FS和OFS是awk对列的操作
FS 的使用和 -F 一样
当我们想以固定的长度来分隔列的时候，可以使用 FIELDWIDTHS 来代替 FS
FS是awk读入记录时的列分隔符，OFS则是awk输出时的列分隔符
[root@master(47.141) /homed]# echo '1 2' | awk -v OFS="------------" '{print $1,$2}'
1------------2
-v -OFS 和print 结合使用，和printf无法结合使用，OFS 主要是对awk中的print处理的数据进行格式处理
awk中的“真”与“假”。
以下3种情况是“假”，其他情况都为“真”
1) 数字 0
2) 空字符串
3) 未定义的值 

NR表示从awk开始执行后，按照记录分隔符读取的数据次数，默认的记录分隔符为换行符，因此默认的就是读取的数据行数，NR可以理解为Number of Record的缩写
在awk处理多个输入文件的时候，在处理完第一个文件后，NR并不会从1开始，而是继续累加，因此就出现了FNR，每当处理一个新文件的时候，FNR就从1开始计数，FNR可以理解为File Number of Record。
NF表示目前的记录被分割的字段的数目，NF可以理解为Number of Field。
awk '{print NR,$0}' /etc/passwd    //打印出内容，并加上行号
awk -F':' 'NR>3&&NR<6 {print NR,$0}' /etc/passwd
awk -F':' -v OFS='--------------' 'NR<3 {print $1,$2}' /etc/passwd
awk '{print FILENAME,"NR="NR,"FNR="FNR,"$"NF"="$NF}' /etc/passwd
next 和getline
[root@slave30(130)]# echo "1 2 3 4 " | awk '{print $1;next;print $2}'    //next后的语句不被执行
1
[root@slave30(130)]# echo "1 2 3 4 " | awk '{print $1;getline;print $2}'    //getline后面的语句是在下一条数据执行的
1
2
next只是完成当前记录的处理，继续处理下一条记录（上面的代码里print $2根本执行不到）
getline是读取下一条记录以后继续执行后面的print $2
awk '{if(NR==1){next} print $1,$2}' data //awk的next忽略掉第一行即可。
与next相似，getline也是读取下一行数据。但是与next不同的是，next读取下一行之后，把控制权交给了awk脚本的顶部。但是getline却没有改变脚本的控制，读取下一行之后，继续运行当前的awk脚本。getline执行之后，会覆盖$0的内容。
除了读取本文间的 下一行，getline还能够读取其他文件
awk 'NF=5 ~ /test/ {print $1","$6}'    //将第五个字段的值与正则表达式"test" 比较
NF ==5 && NR>1 //表示字段的数量必须等于5并且记录的编号大于1
awk 中!a[$0]++    和!a[$1...]++     !优先级高于++ 
!a[$0]++ 去除一行中重复的记录
!a[$1]++可以根据记录中某个域删除这个域相同的记录，也可以根据这个域相同，执行另外一些相应的操作
awk '{++a[$1]} END{for(i in a)print i "\t" a[i] }' access_log
统计（按域统计）文件中某个域出现的次数，有时候可能根据日志中的IP地址来统计某个IP访问网站的次数
cat /usr/local/apache/conf/httpd.conf | awk '/^$/{++x} END{print x}'    /统计出空行的数量
awk有三种循环:while循环；for循环；special for循环
C语言while for 循环：
for和while的比较
其实这两个可以互相代替的，比如说
for (int i = 0; i<10; i++)
{...//插入语句 }
用while来写就是
int i = 0;
while (i<10)
 {
...//插入语句
i++;
}
1、从上可以看出for循环比较简洁，会比while更常用些,循环次数已知的情况下，尤其是用使用指针的时候，很方便的。
2、但是如果想做无限循环，while更方便点，比如说
int i = 1;
while (i == 1){ ... }
while与do while比较
do..while，和while差不多，但是do...while在任何情况下都会先执行命令一次，即使i不符合设定条件,
do{
…
}
while (i<10);
没有特殊要求的时候二者选一即可，但是通常我们会选择while循环。
$ awk '{ i = 1; while ( i <= NF ) { print NF,$i; i++}}' test
$ awk '{for (i = 1; i<NF; i++) print NF,$i}' test 作用同上
变量的初始值为1，若i小于可等于NF(记录中域的个数),则执行打印语句，且i增加1。直到i的值大于NF.
breadkcontinue语句。break用于在满足条件的情况下跳出循环；continue用于在满足条件的情况下忽略后面的语句，直接返回循环的顶端。如：
{for ( x=3; x<=NF; x++) if ($x<0 ){print "Bottomed out!"; break   }}
{for ( x=3; x<=NF; x++) if ($x==0){print "Get next item"; continue}}      
next语句从输入文件中读取一行，然后从头开始执行awk脚本。如：
{if ($1 ~/test/){next}    else {print}}    
exit语句用于结束awk程序，但不会略过END块。退出状态为0代表成功，非零值表示出错
 cat grade.txt | awk '{sum=0;for(i=2;i<=NF;i++) sum=sum+$i}{print sum/5}'    
cat grade.txt | awk -v OFS="---" '{sum=0;for(i=2;i<=NF;i++) sum=sum+$i}{print $1,sum/5}'
当应用多个输入文件时，变量FNR被用来表示与当前输入文件相关的当前记录的代码
格式化打印
printf( "%d\t%s\n",$5,$9)
%-20s //左对齐，20个字符的宽度
printf("|%10s|\n","hello")
if (x) print //如果x是零，print语句将不执行
if ( x ~ /test/ ) print x //模式匹配
if ( expression) {
    statement1
     statement2        
}
awk提供的条件操作符： expr ? action1:action2
grade = (avg >=65) ? "pass":"false"
awk中的循环可以使用while...do 或for语句
i=1
while (i<=4) {
    print $i
    ++i
}
BEGIN {
            do{
                    ++x
                     print x
                }while (x<=4)
        }
do循环，循环体至少执行一次
for 循环
for (i=1;i<=100;i++) {print $1}
awk中控制循环的其他语句，break continue，next exit
break 是终止循环体，continue是终止当前循环，并从循环的顶部开始一个新的循环
next和exit 的使用
next语句能够导致读入下一个输入行，并返回到脚本的底部
exit语句使主输入循环退出并将控制移到END规则，如果没有定义END规则或在END中应用ext语句，则终止脚本
awk '{exit 5}' //退出状态码是 5
%(取余) 
你记住前面的数比后面的数小 那么 余数就是 前面的数；当整除的时候结果是0
像 5%10 还是5 1%2 还是1
/ (取商)
5/10 商为0
next的经典例子，遇到next就不再执行后面的语句，然后从头开始执行
text.txt 内容是：
a
b
c
d
e
[chengmo@centos5 shell]$ awk 'NR%2==1{next}{print NR,$0;}' text.txt    
2 b
4 d
当记录行号除以2余 1，就跳过当前行。下面的print NR,$0也不会执行。 下一行开始，程序又开始判断NR%2 值。这个时候记录行号是：2 ，就会执行下面语句块：'print NR,$0'
awk数组中的所有数字小标都是字符类型
item in array //关键字in 用在表达式中时测试一个下标是否是数组的成员
如果array[item]存在，返回1，否则返回0
if ( a in array)  //此时的a代表的是array中数组的下标，不是数组中的值，和shell编程中的for ip in ips 性质不一样
    print "true"
awk '{a[$1]+=$2} END {for(key in a) print key,"\t"a[key]}'
awk的数组，一种关联数组（Associative Arrays）
下标可以是数字和字符串。因无需对数组名和元素提前声明，也无需指定元素个数 ，所以awk的数组使用非常灵活
遍历数组：
{ for (item in array)  print array[item]} # 输出的顺序是随机的
{for(i=1;i<=len;i++)  print array[i]} # Len 是数组的长度
delete array                     #删除整个数组
delete array[item]           # 删除某个数组元素（item）
awk中的asort函数可以实现对数组的值进行排序，不过排序之后的数组下标改为从1到数组的长度
-v var=val 把val值赋值给var（变量通信的好方法啊～～今天才知道这个选项，想想之前写的代码，抓狂啊～～）如果有多个变量要赋值，那么就写多个-v，每个变量赋值对应一个-v
e.g. 要打印文件a的第num行到num+num1行之间的行， awk -v num=$num -v num1=$num1 'NR==num,NR==num+num1{print}' a
-f progfile：允许awk调用并执行progfile程序文件，当然progfile必须是一个符合awk语法的程序文件
awk内置变量：
ARGC    命令行参数的个数
ARGV：命令行参数数组
ARGIND 当前被处理文件的ARGV标志符
e.g 有两个文件a 和b
awk '{if(ARGIND==1){print "处理a文件"} if(ARGIND==2){print "处理b文件"}}' a b
文件处理的顺序是先扫描完a文件，再扫描b文件
NR 已经读出的记录数
FNR   当前文件的记录数
上面的例子也可以写成这样：
awk 'NR==FNR{print "处理文件a"} NR > FNR{print "处理文件b"}' a b
输入文件a和b，由于先扫描a，所以扫描a的时候必然有NR==FNR，然后扫描b的时候，FNR从1开始计数，而NR则接着a的行数继续计数，所以NR > FNR
e.g 要显示文件的第10行至第15行
awk 'NR==10,NR==15{print}' a
FS 输入字段分隔符（缺省为:space:），相当于-F选项
awk -F ':' '{print}' a    和   awk 'BEGIN{FS=":"}{print}' a 是一样的
OFS输出字段分隔符（缺省为:space:）
awk -F ':' 'BEGIN{OFS=";"}{print $1,$2,$3}' b
如果cat b为
1:2:3
4:5:6
那么把OFS设置成";"后就会输出
1;2;3
4;5;6
（小注释：awk把分割后的第1、2、3个字段用$1,$2,$3...表示，$0表示整个记录（一般就是一整行））
NF：当前记录中的字段个数
awk -F ':' '{print NF}' b的输出为
3
3
表明b的每一行用分隔符":"分割后都3个字段
可以用NF来控制输出符合要求的字段数的行，这样可以处理掉一些异常的行
awk -F ':' '{if (NF == 3)print}' b
RS：输入记录分隔符，缺省为"\n"
缺省情况下，awk把一行看作一个记录；如果设置了RS，那么awk按照RS来分割记录
例如，如果文件c，cat c为
hello world; I want to go swimming tomorrow;hiahia
运行 awk 'BEGIN{ RS = ";" } {print}' c 的结果为
hello world
I want to go swimming tomorrow
hiahia
ORS：输出记录分隔符，缺省为换行符，控制每个print语句后的输出符号 
awk 'BEGIN{ FS = "\n"; RS = ""; ORS = ";"} {print NF}' d 输出
2;3;1
文件e是由小写的字母组成，cat e 输出为 
a
b
z
...
如果要统计不同的字母出现的个数，那么可以使用数组来实现
awk '{arr[$0]++} END{ for (key in arr) print key, "-->",arr[key] }' e
使用for( key in arr)来遍历数组的时候，输出的次序是不可预测的，这一点跟python的字典遍历是一致的。
在gawk中，可以使用asort内置函数实现数组的排序，其他的awk版本中还没有发现有类似的排序函数。一个折中的办法是先awk完再用管道传给sort来排序。sort使用-k选项可以控制使用指定列排序。
awk的多维数组：
awk的多维数组在本质上是一维数组，更确切一点，awk在存储上并不支持多维数组。awk提供了逻辑上模拟二维数组的访问方式。例如，array[2,4] = 1这样的访问是允许的。awk使用一个特殊的字符串SUBSEP (\034)作为分割字段，在上面的例子中，关联数组array存储的键值实际上是2\0344。
类似一维数组的成员测试，多维数组可以使用 if ( (i,j) in array)这样的语法，但是下标必须放置在圆括号中。
类似一维数组的循环访问，多维数组使用 for ( item in array )这样的语法遍历数组。与一维数组不同的是，多维数组必须使用split()函数来访问单独的下标分量。split ( item, subscr, SUBSEP)
awk读取shell中的变量
可以使用-v选项实现功能
b=1
cat f
     apple
awk -v var=$b '{print var, $var}' f
1 apple
除了使用-v选项外，还可以使用"'$variable'"的方式从shell往awk传递变量(注意：这里是单引号)
$awk '{print $b, '$b'}' f
apple 1
至于有没有办法把awk中的变量传给shell呢，这个问题我是这样理解的。shell调用awk实际上是fork一个子进程出来，而子进程是无法向父进程传递变量的，除非用重定向（包括管道）
$a=$(awk '{print $b, '$b'}' f)
$echo $a
apple 1
getline
getline为awk所提供的输入指令.
其语法如下 :
语法
由何处读取数据
数据读入后置于
getline var < file
所指定的 file
变量 var(var省略时,表示置于$0)
getline var
pipe 变量
变量 var(var省略时,表示置于$0)
$awk 'BEGIN{ date" "| getline d; close("date");print d}' f
Sun Nov 9 20:55:12 CST 2008
$awk 'BEGIN{getline name < "/dev/tty"} '
$awk 'BEGIN{while(getline < "/etc/passwd" > 0) { lc++ }; print lc }' f
只要getline的返回值大于0，即读入一行，循环就会继续。
getline如果如成功读取，返回1，否则返回-1，如果遇到EOF，则返回0。getline在读取的同时会设置NF,NR,FNR等内置变量
如果getline后没有变量，则默认置于$0
$awk 'BEGIN{ while(("ls" | getline) > 0) print}' f
输出重定向
awk的输出重定向类似于shell的重定向。重定向的目标文件名必须用双引号引用起来。
$awk '$4 >=70 {print $1,$2 > "destfile" }' filename
$awk '$4 >=70 {print $1,$2 >> "destfile" }' filename
awk中调用shell命令：
1)使用管道
awk中的管道概念和shell的管道类似，都是使用"|"符号，在上面getline中{"date" | getline d;}就是使用了管道。如果在awk程序中打开了管道，必须先关闭该管道才能打开另一个管道。也就是说一次只能打开一个管道。shell命令必须被双引号引用起来。“如果打算再次在awk程序中使用某个文件或管道进行读写，则可能要先关闭程序，因为其中的管道会保持打开状态直至脚本运行结束。注意，管道一旦被打开，就会保持打开状态直至awk退出。因此END块中的语句也会收到管道的影响。（可以在END的第一行关闭管道）”
awk中使用管道有两种语法，分别是：
awk output | shell input
shell output | awk input
对于awk output | shell input来说，shell接收awk的输出，并进行处理。需要注意的是，awk的output是先缓存在pipe中，等输出完毕后再调用shell命令处理，shell命令只处理一次，而且处理的时机是“awk程序结束时，或者管道关闭时（需要显式的关闭管道）”
$awk '/west/{count++} {printf "%s %s\t\t%-15s\n", $3,$4,$1 | "sort +1"} END{close "sort +1"; printf "The number of sales pers in the western"; printf "region is " count "." }' datafile
printf函数用于将输出格式化并发送给管道。所有输出集齐后，被一同发送给sort命令。必须用与打开时完全相同的命令来关闭管道(sort +1)，否则END块中的语句将与前面的输出一起被排序。此处的sort命令只执行一次。
在shell output | awk input中awk的input只能是getline函数。shell执行的结果缓存于pipe中，再传送给awk处理，如果有多行数据，awk的getline命令可能调用多次。
$awk 'BEGIN{ while(("ls" | getline d) > 0) print d}' f
2)使用system命令
$awk 'BEGIN{system("echo abc")}'
需要注意的是system中应该使用shell命令的对应字符串。awk直接把system中的内容传递给shell，作为shell的命令行。
3)system命令中使用awk的变量
空格是awk中的字符串连接符，如果system中需要使用awk中的变量可以使用空格分隔，或者说除了awk的变量外其他一律用""引用起来。
$awk 'BEGIN{a = 12; system("echo " a) }'
1.除去重复项
awk '{!a[$0]++} END{for(key in a) print key}' grade.txt //去除重复行,!优先级高于++，先判断后自加
awk '!($0 in a){a[$0];print}' file(s) //去除重复行
2.计算总数
awk  '{name[$0]+=$1};END{for(i in name) print  i, name[i]}'
3.排序
awk '{a[$0]++}END{l=asorti(a);for(i=1;i<=l;i++)print a[i]}'
awk '{a[$0]=$0} #建立数组a，下标为$0，赋值也为$0
END{
len=asort(a)      #利用asort函数对数组a的值排序，同时获得数组长度len
for(i=1;i<=len;i++) print i "\t"a[i]  #打印
}'
4.有序输出，采用（index in array）的方式打印数组值的顺序是随机的，如果要按原序输出
awk '{a[$1]=$2; c[j++]=$1} END{ for(m=0;m<j;m++)print c[m],a[c[m]] }'
5.把下列数据处理为slave4 XXXX xxxxx类型
slave4  crond
slave4  ilogslave
slave7  QuorumPeerMain
slave7  httpd
awk '{a[$1]=a[$1]" " $2}END{for(key in a) print key,a[key]}' b.txt
awk 对文件处理
1.多行合并：
文件：text.txt 格式：
web01[192.168.2.100]
httpd            ok
tomcat               ok
sendmail               ok
web02[192.168.2.101]
httpd            ok
postfix               ok
web03[192.168.2.102]
mysqld            ok
httpd               ok
需要通过awk将输出格式变成：
web01[192.168.2.100]:   httpd            ok
web01[192.168.2.100]:   tomcat               ok
web01[192.168.2.100]:   sendmail               ok
web02[192.168.2.101]:   httpd            ok
web02[192.168.2.101]:   postfix               ok
web03[192.168.2.102]:   mysqld            ok
web03[192.168.2.102]:   httpd               ok
分析：
分析发现需要将包含有“web”行进行跳过，然后需要将内容与下面行合并为一行。
[chengmo@centos5 shell]$ awk '/^web/{T=$0;next;}{print T":\t"$0;}' test.txt
web01[192.168.2.100]:   httpd            ok
web01[192.168.2.100]:   tomcat               ok
web01[192.168.2.100]:   sendmail               ok
web02[192.168.2.101]:   httpd            ok
web02[192.168.2.101]:   postfix               ok
web03[192.168.2.102]:   mysqld            ok
web03[192.168.2.102]:   httpd               ok
ARGIND  命令行中文件序号
ARGC    命令行参数的个数
ARGV    命令行参数数组
列出b文件中完全不包含a文件的行：awk 'ARGIND==1 {a[$0]} ARGIND>1&&!($0 in a) {print $0}' a b
ARGIND==1{a[$0]}
#ARGIND==1 判断是否正在处理第一个文件，本例为文件a
# {a[$0]} 初始化（或叫做定义）a[$0]
ARGIND>1&&!($0 in a){print $0}
#ARGIND>1 判断是否在处理第二个或第n个文件，本例只有一个文件b
#并且判断a[$0]是否未定义，然后打印$0
2.用某一文件的一个域替换另一个文件中的的特定域？
文件passwd:  
s2002408030068:x:527:527::/home/dz02/s2002408030068:/bin/pw  
s2002408032819:x:528:528::/home/dz02/s2002408032819:/bin/pw  
s2002408032823:x:529:529::/home/dz02/s2002408032823:/bin/pw
文件shadow:  
s2002408030068:$1$d8NwFclG$v4ZTacfR2nsbC8BnVd3dn1:12676:0:99999:7:::  
s2002408032819:$1$UAvNbHza$481Arvk1FmixCP6ZBDWHh0:12676:0:99999:7:::  
s2002408032823:$1$U2eJ3oO1$bG.eKO8Zupe0TnyFhWX9Y.:12676:0:99999:7:::  
用shadow文件中的密文部分替换passwd中的"x",生一个新passwd文件,如下所示
s2002408030068:$1$d8NwFclG$v4ZTacfR2nsbC8BnVd3dn1:527:527::/home/dz02/s2002408030068:/bin/pw  
s2002408032819:$1$UAvNbHza$481Arvk1FmixCP6ZBDWHh0:528:528::/home/dz02/s2002408032819:/bin/pw  
s2002408032823:$1$U2eJ3oO1$bG.eKO8Zupe0TnyFhWX9Y.:529:529::/home/dz02/s2002408032823:/bin/pw  
awk 'BEGIN{OFS=FS=":"} NR==FNR{a[$1]=$2}NR>FNR{$2=a[$1];print $0 >"result.txt"}' shadow passwd
NR==FNR,第一个文件shadow，以$1为下标，将$2的值赋给数组a
NR>FNR，第二个文件passwd，将文件shadow$2的值赋值给文件passwd
3.比较 file1的1-4字符 和 file2的2-5 字符，如果相同，将file2 的第二列 与 file1 合并 file3  
cat file1:  
0011AAA 200.00 20050321  
0012BBB 300.00 20050621  
0013DDD 400.00 20050622  
0014FFF 500.00 20050401  
cat file2:  
I0011  11111  
I0012  22222  
I0014  55555  
I0013  66666  
结果：  
0011AAA 200.00 20050321 11111  
0012BBB 300.00 20050621 22222  
0013DDD 400.00 20050622 66666  
0014FFF 500.00 20050401 55555  
awk 'NR==FNR{a[substr($1,2,5)]=$2}NR>FNR&&a[substr($1,1,4)]{print $0, a[substr($1,1,4)]}' file2.txt file1.txt >file3
3.如果文件a中包含文件b，则将文件b的记录打印出来
文件a:  
10/05766798607,11/20050325191329,29/0.1,14/05766798607  
10/05767158557,11/20050325191329,29/0.08,14/05767158557  

文件b:  
05766798607  
05766798608  
05766798609  
通过文件a和文件b对比,导出这样的文件出来.  
10/05766798607,11/20050325191329,29/0.1,14/05766798607

awk -F'[/,]' 'ARGIND==1{a[$0]}ARGIND>1{($2 in a);print $0}' b a 
awk -F'[/,]' 'NR==FNR{a[$0]}NR>FNR{($2 in a);print $0}' b a
4.a中第二列在b中可能有可能没有，需要把有的匹配起来生成新的一列：要包含a和b的第一列。没有匹配的按照b原来的格式进行输出。
文件a
1000 北京市 地级 北京市 北京市  
1100 天津市 地级 天津市 天津市  
1210 石家庄市 地级 石家庄市 河北省  
1210 晋州市 县级 石家庄市 河北省  
1243 滦县 县级 唐山市 河北省  
1244 滦南县 县级 唐山市 河北省  

b文件：  
110000,北京市  
120000,天津市  
130000,河北省  
130131,平山县  
130132,元氏县  

awk 'BEGIN{FS="[ |,]";OFS=","}NR<=FNR{a[$2]=$1}NR>FNR{print $1,$2,a[$2]}' a b
5.file1的第一列与file2的第3列相同,
file1的第二列与file2的第4列的3-5位相同,
file1的第三列与file2的最后一列相同,
# cat file1
AAA  001  1000.00  
BBB  001  2000.00  
DDD  002  4000.00  
EEE  002  5000.00  
FFF  003  6000.00
# cat file2
01 1111  AAA  WW001  $$$$  1000.00  
02 2222  BBB  GG001  %%%%  2000.00  
03 3333  CCC  JJ001  ****  3000.00  
04 4444  DDD  FF002  &&&&  4000.00  
05 5555  EEE  RR002  @@@@  5000.00  
06 666   FFF  UU003  JJJJ  6000.00  
07 777   III  II005  PPPP  7000.00  
08 8888  TTT  TT008  TTTT  8000.00

# awk 'NR<=FNR{a[$1]=$1"x"$2"x"$3} NR>FNR{b=substr($4,3);c=$3"x"b"x"$6;if(c==a[$3]) print}' file1 file2  

01 1111  AAA  WW001  $$$$  1000.00

02 2222  BBB  GG001  %%%%  2000.00

04 4444  DDD  FF002  &&&&  4000.00

05 5555  EEE  RR002  @@@@  5000.00

06 666   FFF  UU003  JJJJ  6000.00
awk 'NR<=FNR{a[$1]=$1"x"$2"x"$3} NR>FNR{b=substr($4,3);c=$3"x"b"x"$6;if(c==a[$3]) print}' file1 file2
6.两个文件中对应的字段进行相加以后的数字。
file1文件内容
   1    0.5  100   10  15    36.5   
file2文件
    50   10    9     1     5  
将两个文件合成一个文件如：
   51     10.5    109  13.2   16      41.5  
awk '{for (i=1;i<=NF;i++) a=$i;getline <"file2";for (i=1;i<NF;i++) printf $i+a" ";printf $NF+a[NF] "\n"}' file1
awk 内置函数
getline next split() system()
blength[([s])]          计算字符串长度(byte为单位)
length[([s])]           计算字符串长度(character为单位)，length(s) 返回字符串的长度
rand()              生成随机数
         srand([expr])           设置rand() seed
    int(x)              字符串转换为整型
         substr(s, m [, n])      取子字符串
         index(s, t)         在字符串s中定位t字符串首次出现的位置；若原字符串中含有欲找寻的子字符串，则返回该子字符串在原字符串中第一次出现的位置，如果没有出现该子字符串则返回0
         match(s, ere)           在字符串s中匹配正则ere，match修改RSTART、RLENGTH变量。
         split(s, a[, fs])       将字符串分割到数组中
split( 原字符串，数组名称，分隔字符) //awk将根据指定的分隔字符(field separator)来分隔原字符串，将原字符串分割成一个个的域(field)，并以指定的数组保存各个域的值
         sub(ere, repl [, in])   字符串替换;sub( 比对用的正则表达式，新字符串，原字符串)
         gsub                同上;这个函数与sub()一样，是进行字符串取代的函数。不同点是gsub()会取代所有合条件的子字符串，而sub函数只会取代同一行中第一个符合条件的字符串，gsub()会返回被取代的子字符串个数
         sprintf(fmt, expr, ...) 拼字符串
         system(cmd)         在shell中执行cmd;该函数执行给出的command并返回它的状态。执行命令的状态通常表示成功或失败。0表示命令执行成功，非零表示某些类型的错误。在awk脚本中这个命令的输出结果是不可用的，使用command|getline可以将命令的输出读取到脚本中
         toupper(s)          字符串转换为大写
         tolower(s)          字符串转换为小写
next 处理单个文件，调用next后之后的命令就不再执行，此行文本的处理处理到此结束，开始读取下一行记录并操作
getline 在处理单个文件时，getline却没有改变脚本的控制，读取下一行之后，继续运行当前的awk脚本。getline执行之后，会覆盖$0的内容
awk 'BEGIN{ "date" | getline d;print d}'    //awk内部读取shell命令shell命令必须用双引号
awk 'BEGIN{while("ls"|getline)print}'     //读取shell命令
awk -v file=$file 'BEGIN{getline < file;print $1}'     //从shell向awk传参，最好使用-v 参数
自定义函数：
function my_plus(a, b)
{
        return a + b;
}
BEGIN {
        printf("%d\n", my_plus(123, 321));
}
AWK脚本文件开头需要注明调用方式，典型写法为：
         #!/bin/awk -f
    注意-f后面有空格
awk 'gsub(/\$/,"");gsub(/,/,""); cost+=$4;
END {print "The total is $" cost>"filename"}' file gsub函数用空串替换$和,再将结果输出到filename中。
1 2 3 $1,200.00
1 2 3 $2,300.00
1 2 3 $4,000.00
awk 'BEGIN{system("printf \"Input your name:\"");getline d;print d}'    //awk中可以使用system()执行shell中的cmd，但是需要注意的是转义字符
awk -v nam=$name 'BEGIN{print nam}'
在屏幕上打印”What is your name?",并等待用户应答。当一行输入完毕后，getline函数从终端接收该行输入，并把它储存在自定义变量name中
awk 'BEGIN{printf "What is your name?"; getline name < "/dev/tty";print name}'
awk 'BEGIN {for (i = 1; i <= 7; i++) print rand()}'     //随即数获取
expand file //expand 会将tab 改成space
在文件的第一行前插入一行
#awk 'BEGIN {print "new line"} {print $0}' file >file1
在文件末尾添加一行
#awk 'END {print "THE END"} {print $0}' file >file1
awk中执行shell命令要用双引号，最后要使用close进行关闭;close使用的时机是：在第二次写入前，应该关闭前一次写入时打开的文件，close的时候一定于上次打开文件是的打开方式相同。在ENG语句中
    system 指令   
该指令用来执行Shell上的command。
    比如：
    path=/etc/local/apache2
    system( “rm -rf” path)
  awk程序中常使用数组(Array)来存储大量数据，delete 指令可以用来释放数组所占用的内存空间。
    比如：for( any in X_arr )     delete X_arr[any] ，需要注意的是：delete 指令一次只能释放数组中的一个元素
awk程序中常以/…/括住Regexp，以区別于一般字符串
echo 1 > /proc/sys/vm/drop_caches //手动清理内存
eval command-line
其中command－line是在终端上键入的一条普通命令行。然而当在它前面放上eval时，其结果是shell在执行命令行之前扫描它两次。如：
pipe="|"
eval ls $pipe wc -l
shell第1次扫描命令行时，它替换出pipe的值｜，接着eval使它再次扫描命令行，这时shell把｜作为管道符号了
脚本中如果要支持chkconfig,则需要在#!/bin/bash 下一行加入 #chkconfig:   - 85 15
使用perf top查看性能情况
top  查看某个进程的PID
pstack PID  //查看线程数
jstack PID //查看线程的状态
blkid   //查看磁盘uuid
ls -l /dev/disk/by-uuid //
$row=mysql_fetch_arry($result) 生成的是一维数组，通过如下方式转换为多位数组
while($row=mysql_fetch_array($result)) {
        $data[] = $row;
$data[0][user-id]    //$data[0]  代表第一行数据
$data[0][num]
linux系统优化,清除缓存
运行sync将dirty的内容写回硬盘
sync  
通过修改proc系统的drop_caches清理free的cache
echo 3 > /proc/sys/vm/drop_caches
drop_caches的详细文档如下：
Writing to this will cause the kernel to drop clean caches, dentries and inodes from memory, causing that memory to become free.
To free pagecache:
* echo 1 > /proc/sys/vm/drop_caches
To free dentries and inodes:
* echo 2 > /proc/sys/vm/drop_caches
To free pagecache, dentries and inodes:
* echo 3 > /proc/sys/vm/drop_caches
As this is a non-destructive operation, and dirty objects are notfreeable, the user should run "sync" first in order to make sure allcached objects are freed.
shell脚本中追加多行到文件中
 cat <<EOF >> /home/oracle/.bash_profile  
PATH=\$PATH:\$HOME/bin  
export ORACLE_BASE=/u01/app/oracle  
export ORACLE_HOME=\$ORACLE_BASE/10.2.0/db_1  
export ORACLE_SID=yqpt
export PATH=\$PATH:\$ORACLE_HOME/bin  
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
EOF
root_path=`dirname $0`    //脚本所在的目录
echo要变换颜色的时候，要使用参数-e
格式: echo -e "\033[字背景颜色;字体颜色m字符串\033[0m"
vim -r t.swp  //恢复文件保存的文件
java -version 是非标准输出，所有 java -version | tee -a test ，test文件里面没有内容
可以通过java -version 2> test 这样test文件里面就有内容了
$0：是脚本本身的名字；
$#：是传给脚本的参数个数；
$@：是传给脚本的所有参数的列表，即被扩展为"$1" "$2" "$3"等；
$*：是以一个单字符串显示所有向脚本传递的参数，与位置变量不同，参数可超过9个，即被扩展成"$1c$2c$3"，其中c是IFS的第一个字符；
$$：是脚本运行的当前进程ID号；
$?：是显示最后命令的退出状态，0表示没有错误，其他表示有错误；
time命令常用于测量一个命令或者脚本的运行时间
type -a time 发现time有两种命令模式
# type -a time
time is a shell keyword    //系统内置命令，平时常用的是time test.sh 是内部命令
time is /usr/bin/time    //外部命令，外部命令显示的更详细
time命令的输出信息是打印在标准错误输出上的
time命令本身的输出并不会被重定向的，解决办法：
1.{ time command-line; } 2>file //注意空格
2.(time command-line) 2>file 这里time紧贴着小括号
将首字母大写
sed
sed 's/^\w\|\s\w/\U&/g'
注释：\w 相当于 [a-zA-Z0-9] ,\s 表示 任何空白字符（包括空格，制表等）。\U将后面的字符转换成大写，&指前面匹配的内容，上面sed的作用是将行首字母或者是后面每个单词的首字母转换成大写
awk
awk '{for(i=1;i<=NF;i++) {printf "%s%s ", toupper(substr($i,1,1)),substr($i,2)};printf ORS}' file
注释：substr($i,1,1)截取$i的第一字符中的第一个字母 substr($i,2)截取$i的从第二个字母到后面的内容
另外，\U \u可以转换首字母大写，\L和\l 就能转换收字母小写了
同样，\U..\E 或者 \L .. \E 可以转换匹配到的字符串全大写或小写了
shell中的数组
数组的定义arr=("test" "www.baidu.com" "shelltest")
数组的使用 len=${#arr[@]} 返回的是数组元素的个数
echo ${arr[0]}    使用数组中的第一个元素
str="燕睿涛 lulu yrt yanruitao" 字符串数组
for var in ${str[@]} //直接把字符串转化为数组，然后使用
arr=($str)  #这一步将字符串转化为了数组
if((6 <8)); then echo "yes 燕睿涛"; 
if [ 2 -gt 1 ]; then echo "iforever 燕睿涛";
双小括号[(())]里面是可以直接使用大于小于号进行比较(>、<、<=、>=)，而且不需要“坑爹”的空格，用于数学计算
单中括号([])里面比较必须使用-gt、-lt、-ne、-eq这些运算符，而且必须要有严格的空格要求
双中括号([[]])里面比较可以使用>、<、-gt、-lt......这两种格式，但是还是必须要有严格的空格要求，而且双中括号中的>、<对类似于字符串的比较，所以在使用的时候需要注意
#括号中and的使用
if [[ -n "$ret" && $ret -gt 123 ]]... #[[]]双中括号中只能使用&&，不能使用-a
if [ -n "$ret" -a $ret -gt 123 ]...  #[]单中括号中只能使用-a，不能使用&&
if(($ret)) && (($ret >123 ))...  #(())双小括号使用&& 
数学运算用法 $((1+2))
函数中使用local 定义局部变量
获取文件名basename,获取目录dirname
[root@slave30(130) /data1/wangdong/shell]# name=`basename /data1/wangdong/shell/lock.sh`
[root@slave30(130) /data1/wangdong/shell]# echo $name
lock.sh
[root@slave30(130) /data1/wangdong/shell]# name=`dirname /data1/wangdong/shell/lock.sh`    
[root@slave30(130) /data1/wangdong/shell]# echo $name
/data1/wangdong/shell
反斜线 \  在交互模式下的escape 字元，有几个作用；放在指令前，有取消 aliases的作用；放在特殊符号前，则该特殊符号的作用消失；放在指令的最末端，表示指令连接下一行
算数运算expr 1+2 
seq 1 3 10  '从1开始，到10 间隔为3 结果是：1 4 7 10   
说明：默认间隔是“空格” 如果想换成其它的可以带参数：-s   
[chengmo@centos5 ~]$seq -s'#' 1 3 10
[chengmo@centos5 ~]$ seq -s '#' 30 | sed -e 's/[0-9]*//g'
#############################
echo ${#a[@]}    //得到数组长度
unset a[1]    //删除数组的第二个元素
数组分片:
[chengmo@centos5 ~]$ a=(1 2 3 4 5)
[chengmo@centos5 ~]$ echo ${a[@]:0:3}
1 2 3
[chengmo@centos5 ~]$ echo ${a[@]:1:4}
2 3 4 5
直接通过 ${数组名[@或*]:起始位置:长度} 切片原先数组，返回是字符串，中间用“空格”分开，因此如果加上”()”，将得到切片数组
数组替换:
[chengmo@centos5 ~]$ a=(1 2 3 4 5)  
[chengmo@centos5 ~]$ echo ${a[@]/3/100}
1 2 100 4 5
[chengmo@centos5 ~]$ echo ${a[@]}
1 2 3 4 5
[chengmo@centos5 ~]$ a=(${a[@]/3/100})
[chengmo@centos5 ~]$ echo ${a[@]}  
1 2 100 4 5
${数组名[@或*]/查找字符/替换字符} 该操作不会改变原先数组内容，如果需要修改，可以看上面例子，重新定义数据。
read -p "请输入一个数字:" num
if [[ $num =~ ^[0-9]*$ ]];then
        echo $num
else
        echo "输入的不是数字"
fi
#!/bin/bash
exec >/tmp/log 2>&1 //把以下脚本的执行过程输入到log文件中 
ls ...
cd ...
.......
自动登陆脚本
#!/bin/expect
set host "127.0.0.1"
set passwd "wangdong"
spawn ssh wangdong@$host
expect {
    "yes/no" { send "yes\r"; exp_continue}
    "password:" {send "$passwd\r" }
}
interact
select
#!/bin/bash
echo "Please choose a number,1:run w;2:run top;3:run free;4:quit"
echo
PS3="你必须输入1-4之间的数字:"    //修改提示符
select command in w top free quit
do
    case $command in
    w)
        w
        ;;
    top)
        top
        ;;
    free)    
        free
        ;;
    quit)
        exit
        ;;
    *)
        echo "Please input a number:(1-4)!"
        ;;
    esac
done
conntiue    结束本次循环
break    结束整个循环
exit    推出脚本
shell计算/比较（整数 浮点数 字符串）expr bc echo let (())
expr（对字符串和整数做些运算）
规则：
用空格隔开每个项。
用 \（反斜杠） 放在 shell 特定的字符前面。（* | & （ ） >  >=   <   <=  ）
对包含空格和其他特殊字符的字符串要用引号括起来。
整数前面可以放一个一元连字符。在内部，整数被当作 32 位，双互补数
1.计算字符串的长度，我们可以用awk中的length(s)进行计算。我们也可以用echo中的echo ${#string}进行计算，当然也可以expr中的expr length $string 求出字符串的长度
2.index $string substring索引命令功能在字符串$string上找出substring中任一字符第一次出现的位置，若找不到则expr index返回0或1。
3.match $string substring命令在string字符串中匹配substring字符串，然后返回匹配到的substring字符串的长度，若找不到则返回0
4.在shell中可以用{string:position}和{string:position:length}进行对string字符串中字符的抽取。第一种是从position位置开始抽取直到字符串结束，第二种是从position位置开始抽取长度为length的子串。而用expr中的expr substr $string $position $length同样能实现上述功能
[root@localhost shell]# string="hello,everyone my name is xiaoming"
[root@localhost shell]# echo ${string:10}
yone my name is xiaoming
[root@localhost shell]# echo ${string:10:5}
yone
[root@localhost shell]# echo ${string:10:10}
yone my na
[root@localhost shell]# expr substr "$string" 10 5
ryone
注意：echo ${string:10:5}和 expr substr "$string" 10 5的区别在于${string:10:5}以0开始标号而expr substr "$string" 10 5以1开始标号
5.删除字符串和抽取字符串相似${string#substring}为删除string开头处与substring匹配的最短字符子串，而${string##substring}为删除string开头处与substring匹配的最长字符子串
[root@localhost shell]# string="20091111 readnow please"
[root@localhost shell]# echo ${string#2*1}
111 readnow please
[root@localhost shell]# string="20091111 readnow please"
[root@localhost shell]# echo ${string##2*1}
readnow please
第一个为删除2和1之间最短匹配，第二个为删除2和1之间的最长匹配。
6.替换子串${string/substring/replacement}表示仅替换一次substring相配字符，而${string//substring/replacement}表示为替换所有的substring相配的子串
let 整数计算
let i++;
i=$(expr $i + 1)
i=$(echo $i+1|bc)
i=$(echo "$i 1" | awk '{printf $1+$2;}')
let,expr,bc都可以用来求模，运算符都是%，而let和bc可以用来求幂，运算符不一样，前者是**，后者是^
浮点运算 bc awk
echo "scale=4;124142/12412424" | bc
shell中浮点数的比较使用bc awk
if [ `echo "0.5 > 0.3" | bc` -eq 1 ]; then echo "ok"; else echo "not ok"; fi; 
x=3.1; y=3.2; echo "$x $y" | awk '{if ($1 > $2) print $1; else print $2}'
shell脚本中可以使用#!/bin/bash/expect -f 实现SSH的账户密码的登录
declare -i var1   # var1是一个整数
var1=2367
echo "var1 declared as $var1"
var1=var1+1       # 整数声明后，不需要使用'let'.
在脚本中没有带任何参数的declare -f 会列出所有在此脚本前面已定义的函数出来
declare -a test    //定义数组
declare -r test    //定义一个只读变量
 If  [  $ANS  ]    等价于  if [ -n $ANS ] 
blkid 查看磁盘的UUID 等基本信息，blkid -U UUID //知道了UUID查看磁盘的盘符
[root@master(35.100) ~]# blkid -U 35df6a77-82c6-4e87-bf96-0f7a5271aa26
/dev/sdb1
temp='/dev/sdh1: UUID="737e6007-8cd7-4278-9595-e607bb62f2cc" SEC_TYPE="ext2" TYPE="ext3" LABEL="/d8"'
panfu=${temp/:*/}
echo $panfu --->/dev/sdh1
test=${tmp/:*/}    //主要功能是截取字段
A=(a b c def)
${A[@]} 或 ${A[*]} 可得到 a b c def (全部组数)
${A[0]} 可得到 a (第一个组数)，${A[1]} 则为第二个组数...
${#A[@]} 或 ${#A[*]} 可得到 4 (全部组数数量)
${#A[0]} 可得到 1 (即第一个组数(a)的长度)，${#A[3]} 可得到 3 (第四个组数(def)的长度)
e2label UUID=5a2a02b9-41e7-4f11-8da2-eebb77365dc4    //通过UUID获取当前的标签
uuid=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`    //获取UUID
经典的正则
一、校验数字的表达式
数字：^[0-9]*$
n位的数字：^\d{n}$
至少n位的数字：^\d{n,}$
m-n位的数字：^\d{m,n}$
零和非零开头的数字：^(0|[1-9][0-9]*)$
非零开头的最多带两位小数的数字：^([1-9][0-9]*)+(.[0-9]{1,2})?$
带1-2位小数的正数或负数：^(\-)?\d+(\.\d{1,2})?$
正数、负数、和小数：^(\-|\+)?\d+(\.\d+)?$
有两位小数的正实数：^[0-9]+(.[0-9]{2})?$
有1~3位小数的正实数：^[0-9]+(.[0-9]{1,3})?$
非零的正整数：^[1-9]\d*$ 或 ^([1-9][0-9]*){1,3}$ 或 ^\+?[1-9][0-9]*$
非零的负整数：^\-[1-9][]0-9″*$ 或 ^-[1-9]\d*$
非负整数：^\d+$ 或 ^[1-9]\d*|0$
非正整数：^-[1-9]\d*|0$ 或 ^((-\d+)|(0+))$
非负浮点数：^\d+(\.\d+)?$ 或 ^[1-9]\d*\.\d*|0\.\d*[1-9]\d*|0?\.0+|0$
非正浮点数：^((-\d+(\.\d+)?)|(0+(\.0+)?))$ 或 ^(-([1-9]\d*\.\d*|0\.\d*[1-9]\d*))|0?\.0+|0$
正浮点数：^[1-9]\d*\.\d*|0\.\d*[1-9]\d*$ 或 ^(([0-9]+\.[0-9]*[1-9][0-9]*)|([0-9]*[1-9][0-9]*\.[0-9]+)|([0-9]*[1-9][0-9]*))$
负浮点数：^-([1-9]\d*\.\d*|0\.\d*[1-9]\d*)$ 或 ^(-(([0-9]+\.[0-9]*[1-9][0-9]*)|([0-9]*[1-9][0-9]*\.[0-9]+)|([0-9]*[1-9][0-9]*)))$
浮点数：^(-?\d+)(\.\d+)?$ 或 ^-?([1-9]\d*\.\d*|0\.\d*[1-9]\d*|0?\.0+|0)$
二、校验字符的表达式
汉字：^[\u4e00-\u9fa5]{0,}$
英文和数字：^[A-Za-z0-9]+$ 或 ^[A-Za-z0-9]{4,40}$
长度为3-20的所有字符：^.{3,20}$
由26个英文字母组成的字符串：^[A-Za-z]+$
由26个大写英文字母组成的字符串：^[A-Z]+$
由26个小写英文字母组成的字符串：^[a-z]+$
由数字和26个英文字母组成的字符串：^[A-Za-z0-9]+$
由数字、26个英文字母或者下划线组成的字符串：^\w+$ 或 ^\w{3,20}$
中文、英文、数字包括下划线：^[\u4E00-\u9FA5A-Za-z0-9_]+$
中文、英文、数字但不包括下划线等符号：^[\u4E00-\u9FA5A-Za-z0-9]+$ 或 ^[\u4E00-\u9FA5A-Za-z0-9]{2,20}$
可以输入含有^%&’,;=?$\”等字符：[^%&',;=?$\x22]+
禁止输入含有~的字符：[^~\x22]+
三、特殊需求表达式
Email地址：^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$
域名：[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(/.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+/.?
InternetURL：[a-zA-z]+://[^\s]* 或 ^http://([\w-]+\.)+[\w-]+(/[\w-./?%&=]*)?$
手机号码：^(13[0-9]|14[5|7]|15[0|1|2|3|5|6|7|8|9]|18[0|1|2|3|5|6|7|8|9])\d{8}$
电话号码(“XXX-XXXXXXX”、”XXXX-XXXXXXXX”、”XXX-XXXXXXX”、”XXX-XXXXXXXX”、”XXXXXXX”和”XXXXXXXX)：^($$\d{3,4}-)|\d{3.4}-)?\d{7,8}$
国内电话号码(0511-4405222、021-87888822)：\d{3}-\d{8}|\d{4}-\d{7}
身份证号(15位、18位数字)：^\d{15}|\d{18}$
短身份证号码(数字、字母x结尾)：^([0-9]){7,18}(x|X)?$ 或 ^\d{8,18}|[0-9x]{8,18}|[0-9X]{8,18}?$
帐号是否合法(字母开头，允许5-16字节，允许字母数字下划线)：^[a-zA-Z][a-zA-Z0-9_]{4,15}$
密码(以字母开头，长度在6~18之间，只能包含字母、数字和下划线)：^[a-zA-Z]\w{5,17}$
强密码(必须包含大小写字母和数字的组合，不能使用特殊字符，长度在8-10之间)：^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,10}$
日期格式：^\d{4}-\d{1,2}-\d{1,2}
一年的12个月(01～09和1～12)：^(0?[1-9]|1[0-2])$
一个月的31天(01～09和1～31)：^((0?[1-9])|((1|2)[0-9])|30|31)$
钱的输入格式：
有四种钱的表示形式我们可以接受:”10000.00″ 和 “10,000.00″, 和没有 “分” 的 “10000″ 和 “10,000″：^[1-9][0-9]*$
这表示任意一个不以0开头的数字，但是，这也意味着一个字符”0″不通过，所以我们采用下面的形式：^(0|[1-9][0-9]*)$
一个0或者一个不以0开头的数字.我们还可以允许开头有一个负号：^(0|-?[1-9][0-9]*)$
这表示一个0或者一个可能为负的开头不为0的数字.让用户以0开头好了.把负号的也去掉，因为钱总不能是负的吧.下面我们要加的是说明可能的小数部分：^[0-9]+(.[0-9]+)?$
必须说明的是，小数点后面至少应该有1位数，所以”10.”是不通过的，但是 “10″ 和 “10.2″ 是通过的：^[0-9]+(.[0-9]{2})?$
这样我们规定小数点后面必须有两位，如果你认为太苛刻了，可以这样：^[0-9]+(.[0-9]{1,2})?$
这样就允许用户只写一位小数。下面我们该考虑数字中的逗号了，我们可以这样：^[0-9]{1,3}(,[0-9]{3})*(.[0-9]{1,2})?$
1到3个数字，后面跟着任意个 逗号+3个数字，逗号成为可选，而不是必须：^([0-9]+|[0-9]{1,3}(,[0-9]{3})*)(.[0-9]{1,2})?$
备注：这就是最终结果了，别忘了”+”可以用”*”替代。如果你觉得空字符串也可以接受的话(奇怪，为什么?)最后，别忘了在用函数时去掉去掉那个反斜杠，一般的错误都在这里
xml文件：^([a-zA-Z]+-?)+[a-zA-Z0-9]+\\.[x|X][m|M][l|L]$
中文字符的正则表达式：[\u4e00-\u9fa5]
双字节字符：[^\x00-\xff] (包括汉字在内，可以用来计算字符串的长度(一个双字节字符长度计2，ASCII字符计1))
空白行的正则表达式：\n\s*\r (可以用来删除空白行)
HTML标记的正则表达式：<(\S*?)[^>]*>.*?</\1>|<.*? /> (网上流传的版本太糟糕，上面这个也仅仅能部分，对于复杂的嵌套标记依旧无能为力)
首尾空白字符的正则表达式：^\s*|\s*$或(^\s*)|(\s*$) (可以用来删除行首行尾的空白字符(包括空格、制表符、换页符等等)，非常有用的表达式)
腾讯QQ号：[1-9][0-9]{4,} (腾讯QQ号从10000开始)
中国邮政编码：[1-9]\d{5}(?!\d) (中国邮政编码为6位数字)
IP地址：\d+\.\d+\.\d+\.\d+ (提取IP地址时有用)
IP地址：((?:(?:25[0-5]|2[0-4]\\d|[01]?\\d?\\d)\\.){3}(?:25[0-5]|2[0-4]\\d|[01]?\\d?\\d)) 
awk -vFS='\n' -vORS=',' '$1=$1' urfile 
sed编辑器逐行处理文件，并将输出结果打印到屏幕上。sed命令将当前处理的行读入模式空间（pattern space）进行处理，sed在该行上执行完所有命令后就将处理好的行打印到屏幕上（除非之前的命令删除了该行），sed处理完一行就将其从模式空间中删除，然后将下一行读入模式空间，进行处理、显示。处理完文件的最后一行，sed便结束运行。sed在临时缓冲区（模式空间）对文件进行处理，所以不会修改原文件，除非显示指明-i选项。
与模式空间和暂存空间（hold space）相关的命令：
n 输出模式空间行，读取下一行替换当前模式空间的行，执行下一条处理命令而非第一条命令。
N 读入下一行，追加到模式空间行后面，此时模式空间有两行。
h 把模式空间里的行拷贝到暂存空间。
H 把模式空间里的行追加到暂存空间。
g 用暂存空间的内容替换模式空间的行。
G 把暂存空间的内容追加到模式空间的行后。
x 将暂存空间的内容于模式空间里的当前行互换。
！ 对所选行以外的所有行应用命令。
注意：暂存空间里默认存储一个空行。
在每行后面加一空行：
sed 'G' datafile
shell中进制转换
shell可以在不调用第3方命令，表示不同进制数据。这里总结以下表示方法。shell 脚本默认数值是由10 进制数处理,除非这个数字某种特殊的标记法或前缀开头. 才可以表示其它进制类型数值。如：以 0 开头就是 8 进制.以0x 开头就是16 进制数.使用 BASE#NUMBER 这种形式可以表示其它进制.BASE值：2-64
二进制转十进制
[chengmo@centos5 ~]$ ((num=2#11111111));
[chengmo@centos5 ~]$ echo $num;
十进制转为其它进制
这里使用到：bc外部命令完成。bc命令格式转换为：echo "obase=进制;值"|bc
[chengmo@centos5 ~]$ echo "obase=8;01234567"|bc
shell，内置各种进制表示方法非常简单。记得base#number 即可。这里记得赋值时候用(())符号。不能直接用=号了。=号没有值类型。默认将后面变成字符串了。如：
    [chengmo@centos5 ~]$ num=0123;
    [chengmo@centos5 ~]$ echo $num;
    0123
    0开头已经失去了意义了。
    可以通过定义符：let达到(()) 运算效果。
    [chengmo@centos5 ~]$ let num=0123;
    [chengmo@centos5 ~]$ echo $num;  
    83
SHELL中位操作运算符与大多数语言中相同
左移运算符：<<       v<<num：v的二进制左移num位；      例 ：let :"var =1<<2 " 1左移两位二进制100 十进制4
右移运算符：>>      v>>num：v右移num位                        例：let "var=3>>1"   3(0011)右移1位二进制 001十进制1
按位与      ：&        v1&v2 :v1 ,v2按位与                            例：let "var=5&4"   5和4进行按位与结果4
按位或      ：|        v1|v2： v1，v2 按位或                          例： let "var=5|4"  结果4      
按位非    ：~           ~v：                                                    例： let "var=~8"   var 为-9
按位异或  ：^        v1^v2:                                                   例：let "var=4^5"   var为1
m_time=`date +%s`    //当前时间戳
tmp=${#m_time} //得到字符串的长度
res=`expr substr "$m_time" 1 7`    //截取前7位
#/bin/bash
set -e  #set -e 表示 一旦脚本出错就报错并停止执行余下命令
set -o xtrace #跟踪脚本的执行过程，有利于调试
........
set +o xtrace

1.删除所有的空格
sed s/[[:space:]]//g
2.行首空格
sed 's/^[ \t]*//g'
3.行末空格
sed 's/[ \t]*$//g
ssh黄金参数:
ssh -o ConnectTimeout=2 -o ConnectionAttempts=5 -o PasswordAuthentication=no -o StrictHostKeyChecking=no $ip -p$port "command"
1 ConnectTimeout=2                    连接时超时时间，2秒
2 ConnectionAttempts=5                连接失败后重试次数，5次
3 PasswordAuthentication=no           是否使用密码认证，（在遇到没做信任关系时非常有用，不然会卡在那里）
4 StrictHostKeyChecking=no            第一次登陆服务器时自动拉取key文件，（跟上面一样，并且在第一次ssh登陆时，自动应答yes）
PS1 默认交互式提示符 # $
PS2 交互式提示符
PS3 shell脚本中select关键字提示符
PS4 脚本在set -x 调试模式时输出的前导提示符
PROMPT_COMMAND 利用这个可以记录用户的操作记录
cat /pro/uptime 查询系统的运行时间
第一列输出的是，系统启动到现在的时间（以秒为单位），这里简记为num1；
第二列输出的是，系统空闲的时间（以秒为单位）,这里简记为num2
系统的空闲率(%) = num2/(num1*N) 其中N是SMP系统中的CPU个数
who -b 最后一次系统启动时间
who -r 系统当前运行时间
last reboot 
rsync -az -e 'ssh -p 10006' test.log 127.0.0.1:/tmp  ssh  非标准端口同步文件
自定义 shell函数和函数库
为了在执行你自己的脚本时不必输入脚本所在位置的完整或绝对路径，脚本必须被存储在 $PATH 环境变量所定义的路径里的其中一个
1.建立一个bin 目录，存放脚本同时需要引入到$PATH中
2.建立一个lib 目录，存放函数库 mkdir -p /xx/lib/sh 目录下存放一个libmyfunction 库函数
	libmyfunction.sh 定义各种工作使用到的函数
3.在脚本中引用函数库
	要使用某个 lib 目录下的函数，首先你需要按照下面的形式 将包含该函数的函数库导入到需要执行的 shell 脚
	source /path/lib/sh/libmyfunction
	在编写的脚本中就可以使用libmyfunction.sh中的函数了
环境变量用大写字母命名，而自定义变量用小写
用 readonly 来声明静态变量
用 $(command)  来做代换
字符串比较时用 = 而不是 ==
# 若命令失败让脚本退出 
set -o errexit  
# 若未设置的变量被使用让脚本退出 
set -o nounset 
awk 'NR==FNR{a[$2]=$1}NR>FNR{print $0, a[$3]}'
格式化2T以上的大磁盘用操作:
1.用parted 进行分区 parted -l 查看分区情况
2.进行分区 mkfs.ext4 -T largefile -n /dev/sdb2  -T largefile 制定了inodes的大小(4M) 默认为256个字节 -n 用于测试使用不进行真正格式化
 