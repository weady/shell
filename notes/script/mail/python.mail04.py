#!/usr/bin/env python
#coding:utf8
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email import encoders
import sys
import os
from datetime import *

def send_mail(to_list, cc_list, sub):
        me = mail_user 
        msg = MIMEMultipart()
        msg['Subject'] = sub
        msg['From'] = me
        msg['To'] = ",".join(to_list)
	msg['Cc'] = ",".join(cc_list)
	
	reciver = to_list + cc_list 

	#创造数据
	data={}
	with open(r'/app/scripts/epsp_report/epsp_report.log') as filename:
		info = filename.readlines()
    		data['MobileList']= info[0].split()
    		data['Auto_identify_numt']= info[1].split()
    		data['SF']= info[2].split()
    		data['ZTO']= info[3].split()
    		data['YD']= info[4].split()
    		data['STO']= info[5].split()
    		data['Summary']= info[6].split()


        #构造html
        d = datetime.now()
        yesteday = (d - timedelta(1)).strftime('%Y-%m-%d')

#构造html
        html = """\
<html>
<body>
<style type="text/css" media="screen"> 
table { 
border-collapse:collapse; 
border:solid #999;
border-width:1px 0 0 1px;
} 
table caption {font-size:14px;font-weight:bolder;} 
table th,table td {border:solid #999;border-width:0 1px 1px 0;padding:2px;} 
tfoot td {text-align:center;} 

</style>
<br>
<span>自动获取股东手机号:</span>
<table width="1500px" border="1" cellpadding="0">
  <tr>
    <td rowspan="2" style="text-align: center;">日期</td>
    <td colspan="3" style="text-align: center;">顺丰</td>
    <td colspan="3" style="text-align: center;">中通</td>
    <td colspan="3" style="text-align: center;">韵达</td>
    <td colspan="3" style="text-align: center;">申通</td>
    <td colspan="3" style="text-align: center;">合计</td>
  </tr>
  <tr>
    <td>请求次数</td>
    <td>成功获取次数</td>
    <td>获取成功率</td>
    <td>请求次数</td>
    <td>成功获取次数</td>
    <td>获取成功率</td>
    <td>请求次数</td>
    <td>成功获取次数</td>
    <td>获取成功率</td>
    <td>请求次数</td>
    <td>成功获取次数</td>
    <td>获取成功率</td>
    <td>请求次数</td>
    <td>成功获取次数</td>
    <td>获取成功率</td>
  </tr>
  <tr>
    <td style="text-align: center;">"""+yesteday+"""</td>
    <td>"""+data['SF'][1]+"""</td>
    <td>"""+data['SF'][2]+"""</td>
    <td>"""+data['SF'][3]+"""</td>
    <td>"""+data['ZTO'][1]+"""</td>
    <td>"""+data['ZTO'][2]+"""</td>
    <td>"""+data['ZTO'][3]+"""</td>
    <td>"""+data['YD'][1]+"""</td>
    <td>"""+data['YD'][2]+"""</td>
    <td>"""+data['YD'][3]+"""</td>
    <td>"""+data['STO'][1]+"""</td>
    <td>"""+data['STO'][2]+"""</td>
    <td>"""+data['STO'][3]+"""</td>
    <td>"""+data['Summary'][1]+"""</td>
    <td>"""+data['Summary'][2]+"""</td>
    <td>"""+data['Summary'][3]+"""</td>
  </tr>
</table>

<br>
<span>手机号码后四位带出数量:</span>
<table width="400px" border="1" cellpadding="0">
  <tr>
    <td style="text-align: center;">日期</td>
    <td style="text-align: center;">请求次数</td>
    <td style="text-align: center;">带出手机号次数</td>
    <td style="text-align: center;">带出率</td>
  </tr>
  <tr>
    <td style="text-align: center;">"""+yesteday +"""</td>
    <td style="text-align: center;">"""+data['MobileList'][1]+"""</td>
    <td style="text-align: center;">"""+data['MobileList'][2]+"""</td>
    <td style="text-align: center;">"""+data['MobileList'][3]+"""</td>
  </tr>
</table>

<br>
<span>自动识别快递公司:</span>
<table width="400px" border="1" cellpadding="0">
  <tr>
    <td style="text-align: center;">日期</td>
    <td style="text-align: center;">请求次数</td>
  </tr>
  <tr>
    <td style="text-align: center;">"""+yesteday+"""</td>
    <td style="text-align: center;">"""+data['Auto_identify_numt'][1]+"""</td>
  </tr>
</table>
</body>
</html>
        """
        context = MIMEText(html,_subtype='html',_charset='utf-8')  #解决乱码
        msg.attach(context) 
        try:
                send_smtp = smtplib.SMTP()
                send_smtp.connect(mail_host)
                send_smtp.login(mail_user, mail_pass)
                send_smtp.sendmail(me, reciver, msg.as_string())
                send_smtp.close()
                return True
        except Exception, e:
                print str(e)[1]
                return False
if __name__ == '__main__':
    # 设置服务器名称、用户名、密码以及邮件后缀
    mail_host = 'xxxxx'
    mail_user = 'xxxx'
    mail_pass = 'xxxx'   
    mailto_list = [] #邮件接收人
    cc_list = [] #邮件抄送人

    sub= "共配调用股东方接口与手机号后四位自动带出数据统计" #邮件主题

    if send_mail(mailto_list, cc_list, sub):
            print "Send mail succed!"
    else:
            print "Send mail failed!"
