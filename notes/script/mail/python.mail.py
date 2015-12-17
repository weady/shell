#!/usr/bin/python
#coding:utf-8
#
#	by wangdd 2015/12/4
#

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
user = "wangdd"
password = "Wangdong123"
host = "smtp.iPanel.cn"
port = 25
subject = 'Python Email Test'
sender = 'wangdd@iPanel.cn'
receivers = ['708964732@qq.com']
 
message = """From: From Person <wangdd@iPanel.cn>
To: To Person <708964732@qq.com>
Subject: SMTP e-mail test
 
This is a test e-mail message.
"""
def smp_mail(): 
    try:
       server = smtplib.SMTP() 
       server.connect(host,port)
       server.login(user,password)
       server.sendmail(sender, receivers, message)         
       server.quit()
       print "Successfully sent email"
    except Exception,e:
       print "Error: unable to send email"
#smp_mail()

#----------------------HTML-------------------------------------
msg = MIMEText('<pre><h1>你好</h1></pre>','html','utf-8')
msg['Subject'] = subject
msg['From'] = 'wangdd@iPanel.cn'
msg['To'] = '708964732@qq.com'
def html_mail():
    try:
       server = smtplib.SMTP()
       server.connect(host,port)
       server.login(user,password)
       server.sendmail(msg['From'], msg['To'], msg.as_string())
       server.quit()
       print "Successfully sent email"
    except Exception,e:
       print "Error: unable to send email"
       print e
#html_mail()
#------------------图片内嵌入邮件正文----------------------------------
msg = MIMEMultipart('related')
msg['Subject'] = subject
msg['From'] = 'wangdd@iPanel.cn'
msg['To'] = '708964732@qq.com'
msgText = MIMEText('<img alt="" src="cid:image1">','html','utf-8')
msg.attach(msgText)

fp = open('./1.jpg','r')
msgImage = MIMEImage(fp.read())
fp.close()

msgImage.add_header('Content-ID','image1')
msg.attach(msgImage)
def image_mail():
    try:
       server = smtplib.SMTP()
       server.connect(host,port)
       server.login(user,password)
       server.sendmail(msg['From'],msg['To'],msg.as_string())
       server.quit()
       print "Successfully sent email"
    except Exception,e:
       print e
image_mail()
