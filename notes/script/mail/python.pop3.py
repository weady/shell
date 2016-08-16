#!/usr/bin/python
#coding: utf-8
from poplib import POP3

p = POP3('XXXX') #实例化
p.user('username') #登陆的账号
p.pass_('passwd') #登陆的密码
p.stat() #返回邮件的状态，一个2元组(消息数量,消息的总大小)
p.list([msgnum]) #从服务器返回以三元组表示的整个消息列表(rsp,msg_list,rsp_siz) 分别为服务器的响应、消息列表、返回消息的大小
p.retr(msgnum) #从服务器得到消息msgnum,并设置其‘已读’。
			   #返回一个长度为3的元组(rsp,msglines,msgsiz) rsp,msglines,msgsize = p.retr(1111)


