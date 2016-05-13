#!/usr/bin/env python
# -*- coding: utf-8 -*-
import MySQLdb
import _mysql
import re
import time
import sys
import getpass
from decimal import Decimal

port=3306
dbname="zabbix"
times=2
slow=60
version=Decimal("5.5")

class tools(object):
	@staticmethod
	def println(header="",all="",current="",mark=""):
		print header.ljust(42)+": "+all.ljust(30)+" "+current.ljust(30)+" "+mark
	@staticmethod
	def dRatio(param1,param2):
		p1=param1
		p2=param2
		re=""
		if(p1==0):
			if(p2==0):
				re="0:0"
			else:
				re="0:1"
		else:
			if(p2==0):
				re="1:0"
			else:
				if(p1==p2):
					re="1:1"
				elif(p1>p2):
					re= tools.dFormat(Decimal(p1)/Decimal(p2))+":1"
				else:
					re="1:"+tools.dFormat(Decimal(p2)/Decimal(p1))
		return re+" "+tools.remarks([p1, p2])
	@staticmethod
	def remarks(params):
		#print params
		arr=[]
		for param in params:
			arr.append(tools.dFormat(param))
		return "("+"/".join(arr)+")"
	@staticmethod
	def dFormat(val):
		k=1024
		m=k*k
		g=k*m
		t=k*g
		p=k*t
		dp=0
		dm=""
		if(val!=0):
			if(val>p):
				dp=p
				dm="P"
			elif(val>t):
				dp=t
				dm="T"
			elif(val>g):
				dp=g
				dm="G"
			elif(val>m):
				dp=m
				dm="M"
			elif(val>k):
				dp=k
				dm="k"
			else:
				dp=1
			return "%2.2f" % (Decimal(val)/Decimal(dp)) +dm
		else:
			return "%2.2f" % 0

class mysqlvariables(object):
	def __init__(self,variables):
		self.variables=variables
		
	def param(self,param1):
		if(self.variables.has_key(param1)):
			return long(self.variables[param1])
		else:
			if(param1=='table_open_cache'):
				return long(self.variables['table_cache'])
			else:
				return 0L
	def dFormat(self,param1):
		return tools.dFormat(self.param(param1))
	def strFormat(self,param1):
		if(self.variables.has_key(param1)):
			return self.variables[param1]
		else:
			if(param1=='character_set_server'):
				return 'null'
			elif(param1=='table_open_cache'):
				return self.variables['table_cache']
			else:
				return 'null'

class mysqlstatuscomputer(object):
	def __init__(self,statuslist):
		self.statuslist=statuslist
		self.length=len(statuslist)
		self.second=self.seconds()
	
	def getval(self,param):
		if(type(param)==type("")):
			return self.param(param)
		elif(type(param)==type([])):
			return self.arange(param)
		else:
			return param
	
	def param(self,param1):
		if(self.length>1):
			if(self.statuslist[0].has_key(param1)):
				return long(self.statuslist[1][param1])-long(self.statuslist[0][param1])
			else:
				if(param1=='Innodb_buffer_pool_read_ahead' and version>5):
					return (long(self.statuslist[1]['Innodb_buffer_pool_read_ahead_rnd'])+long(self.statuslist[1]['Innodb_buffer_pool_read_ahead_seq']))-(long(self.statuslist[0]['Innodb_buffer_pool_read_ahead_rnd'])+long(self.statuslist[0]['Innodb_buffer_pool_read_ahead_seq']))
				elif(param1=='Uptime_since_flush_status'):
					return long(self.statuslist[1]['Uptime'])-long(self.statuslist[0]['Uptime'])
				else:
					return 0L
		else:
			if(self.statuslist[0].has_key(param1)):
				return long(self.statuslist[0][param1])
			else:
				if(param1=='Innodb_buffer_pool_read_ahead' and version>5):
					return long(self.statuslist[0]['Innodb_buffer_pool_read_ahead_rnd'])+long(self.statuslist[0]['Innodb_buffer_pool_read_ahead_seq'])
				elif(param1=='Uptime_since_flush_status'):
					return long(self.statuslist[0]['Uptime'])
				else:
					return 0L  

	def seconds(self):
		return self.param('Uptime_since_flush_status')
	'''
	param1+param2+....params
	'''
	def arange(self,params):
		re=0
		for param in params:
			re+=self.getval(param)
		return re
	'''
	param1+param2
	'''
	def add(self,param1,param2):
		return self.getval(param1)+self.getval(param2)
	'''
	param1-param2
	'''    
	def sub(self,param1,param2):
		return self.getval(param1)-self.getval(param2)
	'''
	param1*param2
	'''
	def ext(self,param1,param2):
		return self.getval(param1)*self.getval(param2)
	'''
	param1/param2
	'''    
	def per(self,param1,param2):
		a=self.getval(param1)
		b=self.getval(param2)
		if(b!=0):
			return Decimal(a)/Decimal(b)
		else:
			return Decimal(0)
	
	'''
	param/seconds
	'''
	def ps(self,param):
		val=self.getval(param)
		
		if(self.second>0):
			return Decimal(val)/Decimal(self.second)
		else:
			return Decimal(0)
	'''
	format param to P T G M K
	'''
	def format(self,param):
		val=self.getval(param)
		return tools.dFormat(val)
	
	def strFormat(self,param):
		return self.statuslist[0][param]
	
	'''
	param1:param2 (param1/param2)
	'''
	def ratioF(self,param1,param2):
		p1=self.getval(param1)
		p2=self.getval(param2)
		return tools.dRatio(p1, p2)
	'''
	param1/param2 % (param1/param2)
	'''
	def perF(self,param1,param2):
		return self.format(self.per(param1, param2)*100) + "% "+self.remark(param1, param2)
	'''
	1-(param1/param2) % (param1/param2)
	'''
	def dperF(self,param1,param2):
		return self.format((Decimal(1)-self.per(param1, param2))*100) + "% "+self.remark(param1, param2)
	'''
	param1/(param1+param2) % (param1/param2)
	'''
	def aperF(self,param1,param2):
		return self.format(self.per(param1,self.add(param1, param2))*100) + "% "+self.remark(param1, param2)
	'''
	param/seconds % (param/seconds)
	'''
	def psF(self,param):
		return self.format(self.ps(param))+"/s "+self.remark(param, self.second)
	
	'''
	(param1/param2)
	'''
	def remark(self,param1,param2):
		params=[]
		params.append(param1)
		params.append(param2)
		return self.remarks(params)
	'''
	(param1/param2/.../params)
	'''
	def remarks(self,params):
		#print params
		arr=[]
		for param in params:
			arr.append(self.format(self.getval(param)))
		return "("+"/".join(arr)+")"
		
class mysqlstatusmonitor(object):
	def __init__(self,conn):
		self.inx=times
		self.conn=conn
		self.statusList=[]
		self.statustmpList=[]
		self.totalstatus={}
		self.totaltmpstatus=()
		self.getstatus()
	
	def getstatus(self):
		statustmp=()
		mysqlstatus={}
		sql="show /*!41000 GLOBAL */ status"
		cursor=self.conn.cursor()
		for i in range(self.inx):
			cursor.execute(sql)
			statustmp=cursor.fetchall()
			mysqlstatus={}
			for row in statustmp:
				mysqlstatus.setdefault(row[0],row[1])
			self.statustmpList.append(statustmp)
			self.statusList.append(mysqlstatus)
			if(i<(self.inx-1)):
				time.sleep(slow)
			else:
				self.totalstatus=mysqlstatus
				self.totaltmpstatus=statustmp
				
	def getstatusList(self):
		return self.statusList
	
	def getstatustmpList(self):
		return self.statustmpList
	
	def gettotalstatus(self):
		return self.totalstatus
	
	def gettotaltmpstatus(self):
		return self.totaltmpstatus
	
class mysqlpulse(object):
	def __init__(self,conn,monitor):
		self.conn=conn
		self.version=version
		cursor=conn.cursor()
		sql="select current_user();"
		cursor.execute(sql)
		self.currentuser=cursor.fetchall()
		sql="show /*!41000 GLOBAL */ variables;"
		cursor.execute(sql)
		self.variablestmp=cursor.fetchall()
		self.variables={}
		for row in self.variablestmp:
			self.variables.setdefault(row[0],row[1])
		#
		self.statusList=monitor.getstatusList()
		self.statustmpList=monitor.getstatustmpList()
		self.statustmp=monitor.gettotaltmpstatus()
		self.mysqlstatus=monitor.gettotalstatus()
		
		self.totalcomputer=mysqlstatuscomputer([self.mysqlstatus])
		self.computer=mysqlstatuscomputer(self.statusList)
		self.mysqlvariables=mysqlvariables(self.variables)
		# 
		#sql="SHOW /*!41000 ENGINE */ INNODB STATUS;"
		#cursor.execute(sql)
		#self.innodbstatus=cursor.fetchall()
		
		#ver=""
		#match=re.compile(r'^([\d]+\.[\d]+)').match(set[0][0])
		#if match:
		#    ver=match.group(1)
			
		#del set
		sql="show databases"
		cursor.execute(sql)
		self.tables=[]
		self.databases=cursor.fetchall()
		for tmpdatabase in self.databases:
			if(str(tmpdatabase[0])!="information_schema" and str(tmpdatabase[0])!="mysql" and str(tmpdatabase[0])!="performance_schema"):
				sql="show table status from `"+str(tmpdatabase[0])+"`"
				cursor.execute(sql)
				tmptables=cursor.fetchall()
				for tmptable in tmptables:
					tableinfo=[]
					tableinfo.append(tmpdatabase[0])
					tableinfoindex=len(tmptable)
					for idx in range(tableinfoindex):
						tableinfo.append(tmptable[idx])
					self.tables.append(tableinfo)
					
		
		#
		sql="SHOW PROCESSLIST;"
		cursor.execute(sql)
		self.processlist=cursor.fetchall()
			
	def abs(self,left,right):
		return cmp(left[8],right[8])
	
	
	def desc(self,left,right):
		return cmp(right[8],left[8])
	
	def printstatus(self):
		print "============MySQL status============"
		print "get status times="+str(len(self.statustmpList))
		for row in self.statustmp:
			print row[0]+"\t:"+row[1]
	
	
	def printinnodbstatus(self):
		print self.innodbstatus[0][2]
		
	def printtablestatus(self):
		print "------------------------------------"
		print "table status"
		print "------------------------------------"
		print "db\t\tName\t\tEngine\t\tVersion\t\tRow_format\t\tRows\t\tAvg_row_length\t\tData_length\t\tMax_data_length\t\tIndex_lengtht\t\tData_free\t\tAuto_increment\t\tCreate_time\t\tUpdate_time\t\tCheck_time\t\tCollation\t\tChecksum\t\tCreate_options\t\tComment"
		self.tables.sort(cmp=self.desc)
		for row in self.tables:
			tableinfolen=len(row)
			tableinfo=""
			for idx in range(tableinfolen):
				tableinfo+=str(row[idx])+"\t\t"
			print tableinfo
	
	def printprocesslist(self):
		print "============processlist============="
		print "processlist rowcount ="+str(len(self.processlist))+"\nstatus time>0 threads list:"
		print "Id\tUser\t\tHost\t\t\tdb\t\tCommand\t\tTime\t\tState\tInfo\t"
		threadscount=0
		for row in self.processlist:
			if(str(row[4])!="Sleep" and long(row[5])>1):
				print str(row[0])+"\t"+str(row[1])+"\t\t"+str(row[2])+"\t"+str(row[3])+"\t\t"+str(row[4])+"\t\t"+str(row[5])+"\t\t"+str(row[6])+"\t"+str(row[7])
				threadscount+=1
				
		print "status time>0 threads count="+str(threadscount)
	
	
	def printmysqlinfo(self):
		print "=============MySQL info============="
		print "Connection id        : "+str(self.conn.thread_id())
		print "Current database     : "+dbname
		print "Current user         : "+str(self.currentuser[0][0])
		print "SSL                  : "+self.mysqlvariables.strFormat('have_openssl')
		#print "Current pager        : "
		#print "Using outfile        : "
		#print "Using delimiter      : "
		self.version=Decimal(self.mysqlvariables.strFormat('version')[0:3])
		print "MySQL VERSION        : "+self.mysqlvariables.strFormat('version')+" "+self.mysqlvariables.strFormat('version_comment')
		print "MySQL client info    : "+_mysql.get_client_info()
		print "Protocol version     : "+str(self.conn.get_proto_info())
		print "Connection           : "+self.conn.get_host_info()
		print "Server characterset  : "+self.mysqlvariables.strFormat('character_set_server')
		print "Db     characterset  : "+self.mysqlvariables.strFormat('character_set_database')
		print "Client characterset  : "+self.mysqlvariables.strFormat('character_set_client')
		print "Conn.  characterset  : "+self.mysqlvariables.strFormat('character_set_connection')
		print "collation_connection : "+self.mysqlvariables.strFormat('collation_connection')
		print "collation_database   : "+self.mysqlvariables.strFormat('collation_database')
		print "collation_server     : "+self.mysqlvariables.strFormat('collation_server')
		print "Uptime               : "+self.mysqlstatus['Uptime']+"s"
		
	def printQcachestatus(self):
		if(self.mysqlvariables.strFormat("have_query_cache")=="YES" and self.mysqlvariables.strFormat("query_cache_type")!="OFF" and self.mysqlvariables.param("query_cache_size")>0):
			print "------------------------------------"
			print "Qcache Status"
			print "------------------------------------"
			tools.println("Qcache queries hits ratio(hits/reads)",self.totalcomputer.perF("Qcache_hits", ["Com_select", "Qcache_hits"]),self.computer.perF("Qcache_hits", ["Com_select", "Qcache_hits"]),"Higher than 30.00")
			tools.println("Qcache hits inserts ratio(hits/inserts)",self.totalcomputer.perF("Qcache_hits", "Qcache_inserts"),self.computer.perF("Qcache_hits", "Qcache_inserts"),"Higher than 300.00")
			tools.println("Qcache memory used ratio(free/total)",self.totalcomputer.dperF("Qcache_free_memory",self.mysqlvariables.param("query_cache_size")))
			tools.println("Qcache prune ratio(prunes/inserts)",self.totalcomputer.perF("Qcache_lowmem_prunes", "Qcache_inserts"),self.computer.perF("Qcache_lowmem_prunes", "Qcache_inserts"))
			tools.println("Qcache block Fragmnt ratio(free/total)",self.totalcomputer.perF("Qcache_free_blocks", "Qcache_total_blocks"))
	
	def printUptimesinceflushstatus(self):
		print "-----------------------------------------------------------------------------------------------------------------------------"
		print "Reads/Writes status                            total                        current                        proposal          "
		print "-----------------------------------------------------------------------------------------------------------------------------"
		tools.println("Reads:Writes ratio(Reads/Writes)",self.totalcomputer.ratioF(["Com_select", "Qcache_hits"], ["Com_insert","Com_insert_select","Com_update","Com_update_multi","Com_delete","Com_delete_multi","Com_replace","Com_replace_select"]),self.computer.ratioF(["Com_select", "Qcache_hits"], ["Com_insert","Com_insert_select","Com_update","Com_update_multi","Com_delete","Com_delete_multi","Com_replace","Com_replace_select"]))
		tools.println("QPS(Questions/Uptime)",self.totalcomputer.psF("Questions"),self.computer.psF("Questions"))
		tools.println("TPS(Questions/Uptime)",self.totalcomputer.psF(["Com_commit","Com_rollback"]),self.computer.psF(["Com_commit","Com_rollback"]))
		tools.println("Table locks waited ratio(waited/immediate)",self.totalcomputer.ratioF("Table_locks_waited","Table_locks_immediate"),self.computer.ratioF("Table_locks_waited","Table_locks_immediate"),"0:1")
		tools.println("select per second(select/Uptime)",self.totalcomputer.psF(["Com_select","Qcache_hits"]),self.computer.psF(["Com_select","Qcache_hits"]))
		tools.println("insert per second(insert/Uptime)",self.totalcomputer.psF(["Com_insert","Com_insert_select"]),self.computer.psF(["Com_insert","Com_insert_select"]))
		tools.println("update per second(update/Uptime)",self.totalcomputer.psF(["Com_update","Com_update_multi"]),self.computer.psF(["Com_update","Com_update_multi"]))
		tools.println("delete per second(delete/Uptime)",self.totalcomputer.psF(["Com_delete","Com_delete_multi"]),self.computer.psF(["Com_delete","Com_delete_multi"]))
		tools.println("replace per second(replace/Uptime)",self.totalcomputer.psF(["Com_replace","Com_replace_select"]),self.computer.psF(["Com_replace","Com_replace_select"])) 
		tools.println("Bytes sent per second(sent/Uptime)",self.totalcomputer.psF("Bytes_sent"),self.computer.psF("Bytes_sent"))
		tools.println("Bytes received per second(re/Uptime)",self.totalcomputer.psF("Bytes_received"),self.computer.psF("Bytes_received"))
		print "------------------------------------"
		print "Slow and Sort queries status"
		print "------------------------------------"
		tools.println("Slow queries Ratio(Slow/Questions)",self.totalcomputer.perF("Slow_queries", "Questions"),self.computer.perF("Slow_queries", "Questions"),"Lower than 0")
		tools.println("Slow queries PS(Slow/Uptime)",self.totalcomputer.psF("Slow_queries"),self.computer.psF("Slow_queries"),"Lower than 0")
		tools.println("Full join PS(full/Uptime)",self.totalcomputer.psF("Select_full_join"),self.computer.psF("Select_full_join"),"Lower than 0")
		tools.println("Sort merge passes PS(merge/Uptime)",self.totalcomputer.psF("Sort_merge_passes"),self.computer.psF("Sort_merge_passes"),"Lower than 0")
		tools.println("Sort range PS(range/Uptime)",self.totalcomputer.psF("Sort_range"),self.computer.psF("Sort_range"),"Lower than 0")
		tools.println("Sort rows PS(rows/Uptime)",self.totalcomputer.psF("Sort_rows"),self.computer.psF("Sort_rows"),"Lower than 0")
		tools.println("Sort scan PS(scan/Uptime)",self.totalcomputer.psF("Sort_scan"),self.computer.psF("Sort_scan"),"Lower than 0")
		print "------------------------------------"
		print "connections status"
		print "------------------------------------"
		tools.println("Thread cache hits(created/Total)",self.totalcomputer.dperF("Threads_created", "Connections"),self.computer.dperF("Threads_created", "Connections"),"Higher than 0")
		tools.println("Connections used ratio(Max used/Max)",self.totalcomputer.perF("Max_used_connections",self.mysqlvariables.param("max_connections")),self.computer.perF("Max_used_connections",self.mysqlvariables.param("max_connections")),"Lower than 90")
		tools.println("Aborted connects ratio(Aborted/Max)",self.totalcomputer.perF(["Aborted_clients","Aborted_connects"],self.mysqlvariables.param("max_connections")),self.computer.perF(["Aborted_clients","Aborted_connects"],self.mysqlvariables.param("max_connections")),"Lower than 0")
		tools.println("Threads running",self.totalcomputer.format("Threads_running"))
		print "------------------------------------"
		print "temp table and Open tables/files status"
		print "------------------------------------"
		tools.println("Temp tables to Disk ratio(disk/tmp)",self.totalcomputer.perF("Created_tmp_disk_tables", "Created_tmp_tables"),self.computer.perF("Created_tmp_disk_tables", "Created_tmp_tables"),"Lower than 0")
		tools.println("Open tables/table open cache/Opened tables",self.totalcomputer.remarks(["Open_tables",self.mysqlvariables.param("table_open_cache"),"Opened_tables"]),self.computer.remarks(["Open_tables",self.mysqlvariables.param("table_open_cache"),"Opened_tables"]),"1:1:1")
		tools.println("Opened files PS(Opened/Uptime)",self.totalcomputer.psF("Opened_files"),self.computer.psF("Opened_files"),"Lower than 0")
	
	def printInnoDBStatus(self):
		print "------------------------------------"
		print "InnoDB Status"
		print "------------------------------------"
		tools.println( "Innodb buffer read hits(Disk/total)",self.totalcomputer.dperF(["Innodb_buffer_pool_reads","Innodb_buffer_pool_read_ahead"], "Innodb_buffer_pool_read_requests"),self.computer.dperF(["Innodb_buffer_pool_reads","Innodb_buffer_pool_read_ahead"], "Innodb_buffer_pool_read_requests"),"Higher than 99.99")
		tools.println( "Innodb dblwr pages written:dblwr writes",self.totalcomputer.ratioF("Innodb_dblwr_pages_written", "Innodb_dblwr_writes"),"","Lower than 64:1")
		tools.println( "Innodb buffer pages used ratio(free/total)",self.totalcomputer.dperF("Innodb_buffer_pool_pages_free", "Innodb_buffer_pool_pages_total"),"","Lower than 99.99")
		tools.println( "Innodb buffer pages dirty ratio(dirty)",self.totalcomputer.perF("Innodb_buffer_pool_pages_dirty", "Innodb_buffer_pool_pages_total"))
		tools.println( "Innodb buffer pages flushed PS(flushed)",self.totalcomputer.psF("Innodb_buffer_pool_pages_flushed"),self.computer.psF("Innodb_buffer_pool_pages_flushed"))
		tools.println( "Innodb buffer pool pages misc",self.totalcomputer.format("Innodb_buffer_pool_pages_misc"))
		
		tools.println( "Innodb row lock waits PS(waits/Uptime)",self.totalcomputer.psF("Innodb_row_lock_current_waits"),self.computer.psF("Innodb_row_lock_current_waits"))
		tools.println( "Innodb row lock current waits",self.totalcomputer.format("Innodb_row_lock_current_waits"),self.computer.format("Innodb_row_lock_current_waits"))
		tools.println( "Innodb row lock time avg",self.totalcomputer.format("Innodb_row_lock_time_avg"),self.computer.format("Innodb_row_lock_time_avg"))
		tools.println( "Innodb row lock time max",self.totalcomputer.format("Innodb_row_lock_time_max"),self.computer.format("Innodb_row_lock_time_max"))
		tools.println( "Innodb row lock time total",self.totalcomputer.format("Innodb_row_lock_time"),self.computer.format("Innodb_row_lock_time"))
		
		tools.println( "Innodb rows read PS(read/Uptime)",self.totalcomputer.psF("Innodb_rows_read"),self.computer.psF("Innodb_rows_read"))
		tools.println( "Innodb rows inserted PS(inserted/Uptime)",self.totalcomputer.psF("Innodb_rows_inserted"),self.computer.psF("Innodb_rows_inserted"))
		tools.println( "Innodb rows updated PS(updated/Uptime)",self.totalcomputer.psF("Innodb_rows_updated"),self.computer.psF("Innodb_rows_updated"))
		
		tools.println( "Innodb data reads PS(reads/Uptime)",self.totalcomputer.psF("Innodb_data_reads"),self.computer.psF("Innodb_data_reads"))
		tools.println( "Innodb data writes PS(writes/Uptime)",self.totalcomputer.psF("Innodb_data_writes"),self.computer.psF("Innodb_data_writes"))
		tools.println( "Innodb data fsyncs PS(fsyncs/Uptime)",self.totalcomputer.psF("Innodb_data_fsyncs"),self.computer.psF("Innodb_data_fsyncs"))
		
		tools.println( "Innodb data pending reads PS(reads/Uptime)",self.totalcomputer.psF("Innodb_data_pending_reads"),self.computer.psF("Innodb_data_pending_reads"))
		tools.println( "Innodb data pending writes PS(write/Uptime)",self.totalcomputer.psF("Innodb_data_pending_writes"),self.computer.psF("Innodb_data_pending_writes"))
		tools.println( "Innodb data pending fsyncs PS(fsync/Uptime)",self.totalcomputer.psF("Innodb_data_pending_fsyncs"),self.computer.psF("Innodb_data_pending_fsyncs"))
		
	def printkeystatus(self):
		print "------------------------------------"
		print "key buffer Status"
		print "------------------------------------"
		tools.println( "key buffer used ratio(used/size)",self.totalcomputer.perF(self.totalcomputer.ext("Key_blocks_used",self.mysqlvariables.param("key_cache_block_size")), self.mysqlvariables.param("key_buffer_size")),"","Lower than 99.99")
		tools.println( "key buffer read hit ratio(reads/request)",self.totalcomputer.dperF("Key_reads", "Key_read_requests"),self.computer.dperF("Key_reads", "Key_read_requests"),"Higher than 99.99")
		tools.println( "key buffer write hit ratio(writes/request)",self.totalcomputer.dperF("Key_writes", "Key_write_requests"),self.computer.dperF("Key_writes", "Key_write_requests"),"Higher than 99.99")
	
	def printslavestatus(self):
		print "------------------------------------"
		print "Slave Status"
		print "------------------------------------"
		tools.println( "Slave running status",self.totalcomputer.strFormat("Slave_running"),self.computer.strFormat("Slave_running"))
		tools.println( "Slave open temp tables",self.totalcomputer.format("Slave_open_temp_tables"),self.computer.format("Slave_open_temp_tables"))
		tools.println( "Slave transactions PS(transactions/Uptime)",self.totalcomputer.psF("Slave_retried_transactions"),self.computer.psF("Slave_retried_transactions"))
		tools.println( "Slave received PS(heartbeats/Uptime)",self.totalcomputer.psF("Slave_received_heartbeats"),self.computer.psF("Slave_received_heartbeats"))
	
	def printflushstatus(self):
		print "=========MySQL status pulse========="
		self.printUptimesinceflushstatus()
		if(self.version> Decimal("5")):
			self.printInnoDBStatus()
		self.printkeystatus()
		self.printQcachestatus()
		self.printslavestatus()
		#self.printtablestatus()

class mysqlmonitor(object):
	def __init__(self,dbs):
		self.conn=MySQLdb.connect(host=dbs['host'],port=dbs['port'],user=dbs['user'],passwd=dbs['passwd'],db=dbs['db'])
		self.monitor=mysqlstatusmonitor(self.conn)
		self.pulse=mysqlpulse(self.conn,self.monitor)
		
	def du(self):
		self.pulse.printmysqlinfo()
		self.pulse.printprocesslist()
		self.pulse.printflushstatus()
		#printstatus(statustmp, statustmpList)
		#printinnodbstatus(innodbstatus)
	
	def __del__( self ):
		self.conn.close()

if __name__ == '__main__':
	host = raw_input("Host[localhost]:")
	if not host.strip():host = "localhost"
	user = raw_input("User[root]:")
	if not user.strip():user = "root"
	pwd = getpass.getpass("Password %s@%s:" % (user,host))
	dbname = raw_input("database[mysql]:")
	if not dbname.strip():dbname = "mysql"       
	dbs={'host':host,'port':port,'user':user,'passwd':pwd,'db':dbname}
	monitor=mysqlmonitor(dbs)
	monitor.du()

