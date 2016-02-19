#!/usr/bin/python
#coding: utf-8
#
#
#这个脚本实现Python脚本发送邮件
#
#	by wangdd 2015/12/4
#
import smtplib
import email.MIMEMultipart  
import email.MIMEText  
import email.MIMEBase 
import email.MIMEImage 
import os.path


user = "wangdd"
password = "Wangdong123"
host = "smtp.iPanel.cn"
port = 25
subject = "Python Email Test"
sender = "wangdd@iPanel.cn"
receivers = ["708964732@qq.com"]
 
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
msg = email.MIMEText.MIMEText('<pre><h1>你好</h1></pre>','html','utf-8')
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
msg = email.MIMEMultipart.MIMEMultipart('related')
msg['Subject'] = subject
msg['From'] = 'wangdd@iPanel.cn'
msg['To'] = '708964732@qq.com'
msgText = email.MIMEText.MIMEText('<img alt="" src="cid:image1">','html','utf-8')
msg.attach(msgText)

fp = open('./1.jpg','r')
msgImage = email.MIMEImage.MIMEImage(fp.read())
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
#image_mail()

#------------------发送带附件的----------------------------------

#***********************************************************************************
#可采用email模块发送电子邮件附件。发送一个未知MIME类型的文件附件其基本思路如下：

#1. 构造MIMEMultipart对象做为根容器
#2. 构造MIMEText对象做为邮件显示内容并附加到根容器
#3. 构造MIMEBase对象做为文件附件内容并附加到根容器
#　　a. 读入文件内容并格式化
#　　b. 设置附件头
#4. 设置根容器属性
#5. 得到格式化后的完整文本
#6. 用smtp发送邮件

#************************************************************************************
def send_attach():
    file_name = r"disk_status.pdf"#附件名
    From = "wangdd@iPanel.cn" 
    To = "708964732@qq.com"
    server = smtplib.SMTP(host)
    server.login(user,password) #仅smtp服务器需要验证时
    
    # 构造MIMEMultipart对象做为根容器
    main_msg = email.MIMEMultipart.MIMEMultipart()
    
    # 构造MIMEText对象做为邮件显示内容并附加到根容器
    text_msg = email.MIMEText.MIMEText("这个是发送附件的测试邮件!",_charset="utf-8")
    main_msg.attach(text_msg)
    
    # 构造MIMEBase对象做为文件附件内容并附加到根容器
    contype = 'application/octet-stream'
    maintype, subtype = contype.split('/', 1)
    
    ## 读入文件内容并格式化 [方式2]－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
    data = open(file_name, 'rb')
    file_msg = email.MIMEBase.MIMEBase(maintype, subtype)
    file_msg.set_payload(data.read())
    data.close( )
    email.Encoders.encode_base64(file_msg)#把附件编码
    #－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
    ## 设置附件头
    basename = os.path.basename(file_name)
    file_msg.add_header('Content-Disposition','attachment', filename = basename)#修改邮件头
    main_msg.attach(file_msg)
    
    # 设置根容器属性
    main_msg['From'] = From
    main_msg['To'] = To
    main_msg['Subject'] = "Attach Test "
    main_msg['Date'] = email.Utils.formatdate()
    
    # 得到格式化后的完整文本
    fullText = main_msg.as_string()
    
    # 用smtp发送邮件
    try:
        server.sendmail(From,To,fullText)
        print "Successfully sent email"
    finally:
        server.quit()

send_attach()
