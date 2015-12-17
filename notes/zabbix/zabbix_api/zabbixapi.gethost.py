#!/usr/bin/python
#coding=utf-8
import json
import urllib2
# based url and required header
url = "http://192.168.36.108/zabbix/api_jsonrpc.php"
header = {"Content-Type": "application/json"}
#host.get
data_host = json.dumps(
{
    "jsonrpc":"2.0",
    "method":"host.get",
    "params":{
        "output":["hostid","name"],
        "filter":{"host":""}
    },
    "auth":"158861dbe5996b6e3a8536acd502146b", # the auth id is what auth script returns, remeber it is string
    "id":1
})
# create request object
request = urllib2.Request(url,data_host)
for key in header:
    request.add_header(key,header[key])
# get host list
result = urllib2.urlopen(request)
response = json.loads(result.read())
#print "Result:", response
#print response['result']
for name in response['result']:
	print "hostid:",name['hostid'] +"\t" "hostname:",name['name']
result.close()
