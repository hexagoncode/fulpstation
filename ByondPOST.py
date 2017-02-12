#!python

import requests
import yaml
import sys

def send_post_request(url, payload, auth):
    headers = {}
    headers['Authorization'] = auth
    headers['Content-Type'] = 'application/json'
    data = yaml.safe_load(payload)
    r = requests.post(url, json=data, headers=headers)
    #print r.status_code
    #print r.json()
    #print data
    #print type(data)
    #print headers
    return

#pp = '{ \'content\' : \'This is a stupid test by Tomar\'}'
#auth = 'Bot MjgwMDgxNjc1MjMxMjk3NTM3.C4EOPg.qmwfJRRTljyczOOXeGO_AmAatJ4'
#ct = 'application/json'


#send_post_request('https://discordapp.com/api/channels/280102859113103362/messages',pp,auth,ct)
args = sys.argv
aurl = args[1]
app = '{ \'content\' : \'' + args[2] + '\'}'
aauth = args[3]

#print(aurl + ' | ' + app  + ' | ' + aauth + ' | ' + act)

send_post_request(aurl,app,aauth)
