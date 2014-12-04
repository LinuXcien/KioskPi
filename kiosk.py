#!/usr/bin/env python3
import sys
import os
import subprocess
from datetime import date
from datetime import time
from datetime import datetime

ip_addresses = subprocess.getoutput("/sbin/ifconfig | grep -i \"inet\" | grep -iv \"inet6\" | " +
                         "awk {'print $2'} | sed -ne 's/addr\:/ /p'")


#cgitb.enable()

print("Content-type: text/html\r\n\r\n")
print("<!doctype html><html>")
f = open('includes/header.html', 'r')
print(f.read())
today = date.today()
t = datetime.time(datetime.now())
print('<div id="sidebar">')
print("Today is ", today, '<br />')
print(" ", t)
print("</p>")
print("<hr>")
print('</div>')
print('<div id="page">')
f = open('includes/scraped_included.html', 'r')
print(f.read())
print("<hr>")
print("</div>")
print('<div id="ipAddress">')
print("<b>" , ip_addresses , "</b>")
print("</div>")
f = open('includes/footer.html', 'r')
print(f.read())