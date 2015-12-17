#!/usr/bin/python
#coding:utf-8
import MySQLdb
#连接数据库
db = MySQLdb.connect("192.168.36.130","root","123456","zabbix")
#cursor()方法获取操作游标
cursor = db.cursor()
#执行sql语句
cursor.execute("select version()")
#使用fetchone()方法获取一条数据
data = cursor.fetchone()
print "Database version is %s" % data
#--------------数据库建表---------------------------------------
cursor.execute("drop table if exists wangdong")
sql = """create table wangdong (
	id int,
	name varchar(10))"""
cursor.execute(sql)
#--------------数据库插入操作-----------------------------------
sql = """insert into wangdong 
	values (1,"wangdong")"""
try:
	#执行sql语句
	cursor.execute(sql)
	#提交到数据库执行
	db.commit()
except:
	#rollback 以防有错误
	db.rollback()
db.close()
