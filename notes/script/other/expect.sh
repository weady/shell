#!/bin/expect
# expect 实现自动登陆服务器，实现自动化管理
#set user [lindex $argv 0] //外部传进的第一个参数,第二个参数为1,依次类推
set host "127.0.0.1"
set passwd "wangdong"
spawn ssh wangdong@$host
expect {
	"yes/no" { send "yes\r"; exp_continue}
	"password:" {send "$passwd\r" }
}
#interact
expect "]*"
send "touch /tmp/expect.txt\r"
expect "]*"
send "echo 11111 > /tmp/expect.txt\r"
expect "]*"
send "exit\r"
#同步文件,最后要加eof 表示结束符
#spawn rsync -av source desc_dir
#....
#expect eof
