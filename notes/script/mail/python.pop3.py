#!/usr/bin/python
#coding: utf-8
from poplib import POP3

	"""
	p = POP3('XXXX') #实例化
	p.user('username') #登陆的账号
	p.pass_('passwd') #登陆的密码
	p.stat() #返回邮件的状态，一个2元组(消息数量,消息的总大小)
	p.list([msgnum]) #从服务器返回以三元组表示的整个消息列表(rsp,msg_list,rsp_siz) 分别为服务器的响应、消息列表、返回消息的大小
	p.retr(msgnum) #从服务器得到消息msgnum,并设置其‘已读’。
			   #返回一个长度为3的元组(rsp,msglines,msgsiz) rsp,msglines,msgsize = p.retr(1111)
	p.dele(msgnum) #删除消息
	"""


#smtp发送邮件,pop3获取邮件
def mailtest():
	from smtplib import SMTP
	from poplib import POP3
	from time import sleep

	smtpsvr = 'xxxxx'
	pop3svr = 'xxxxx'

	user = 'test@163.com'
	body = '''\
	From: %(who)s
	To: %(who)s
	Subject: TEST msg
	HELLO World!
	''' % ('who':user)

	sendsvr = SMTP(smtpsvr)
	errs = sendsvr.sendmail(user,[user],origMsg)
	sendsvr.quit()

	assert len(errs) == 0,errs
	sleep(10)

	recvsvr = POP3(pop3svr)
	recvsvr.user('xxx')
	recvsvr.pass_('xxxx')
	rsp,msg,siz = recvsvr.retr(recvsvr.stat()[0]) #登录成功后通过stat()方法得到可用消息列表,通过[0]获取第一条消息

	sep = msg.index('')
	recvbody = msg[sep+1:]

	assert origbody == recvbody

#IMAP4 互联网邮件访问协议，该模块定义了三个类 IMAP4 IMAP4_SSL IMAP4_stream
	"""
	使用方式和POP3类似，对应的模块是imaplib
	常用方法:
	close()
	fetch()
	login(user,passwd)
	logout() #从服务器注销
	noop() #ping服务器
	search()
	select()
	
	s = IMAP4('xxxxx')
	s.login('user','passwd')
	rsp,msgs = s.select('INBOX',True)
	rsp,data = s.fetch(msgs[0],'RFC822')

	for i in data[0][1].splitlines()[:5]:
		print i
		
	"""














