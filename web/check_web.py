#!/usr/bin/python
#coding:utf-8
#
#利用pycurl 模块对web服务器站点服务质量的探测
#	by wangdd 2016/03/09

import pycurl
import os,sys
import time

def check_web():
	url = sys.argv[1]
	c = pycurl.Curl()
	c.setopt(pycurl.URL,url)	#定义请求的常量
	c.setopt(pycurl.CONNECTTIMEOUT, 5)	#请求连接的等待时间
	c.setopt(pycurl.TIMEOUT, 5)	#请求超时时间
	c.setopt(pycurl.NOPROGRESS,1)	#屏蔽下载进度条
	c.setopt(pycurl.FORBID_REUSE, 1)	#完成交互断开,不重用
	c.setopt(pycurl.MAXREDIRS, 1)	#http 重定向的最大数 1
	c.setopt(pycurl.DNS_CACHE_TIMEOUT, 30)	#DNS信息保存30s

	file = open(os.path.dirname(os.path.realpath(__file__))+"\content.txt",'wb')	#创建一个文件存放页面
	c.setopt(pycurl.WRITEHEADER, file)	#页面头部信息
	c.setopt(pycurl.WRITEDATA, file)	#页面内容
	try:
		c.perform() #提交请求
	except Exception, e:
		print str(e)
		file.close()
		c.close()
		sys.exit()
	namelookup_time = c.getinfo(c.NAMELOOKUP_TIME)	#获取DNS解析时间
	connect_time = c.getinfo(c.CONNECT_TIME)	#获取建立连接时间
	pretransfer_time = c.getinfo(c.PRETRANSFER_TIME)	#获取从建立连接到准备传输所消耗的时间
	starttransfer_time = c.getinfo(c.STARTTRANSFER_TIME)	#获取从建立连接到传输开始消耗的时间
	total_time = c.getinfo(c.TOTAL_TIME)	#传输的总时间
	http_code	=c.getinfo(c.HTTP_CODE)
	size_download = c.getinfo(c.SIZE_DOWNLOAD)	#获取下载数据包大小
	header_size = c.getinfo(c.HEADER_SIZE)	#获取http头部大小
	speed_download = c.getinfo(c.SPEED_DOWNLOAD)	#获取平均下载速度


	print "HTTP 状态码: %s" % (http_code)
	print "DNS 解析时间: %.2f ms" % (namelookup_time*1000)
	print "建立连接时间: %.2f ms" % (connect_time*1000)
	print "准备传输时间: %.2f ms" % (pretransfer_time*1000)
	print "传输开始时间: %.2f ms" % (starttransfer_time*1000)
	print "传输结束时间: %.2f ms" % (total_time*1000)
	print "下载数据包大小: %d bytes/s" % (size_download)
	print "HTTP 头部大小: %d bytes" % (header_size)
	print "平均下载速度: %d bytes/s" % (speed_download)
	file.close()
	c.close()
	
check_web()
