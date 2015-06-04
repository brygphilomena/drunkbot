import json
import urllib.request
import time
import serial
from subprocess import *

global data,ser,base_url


def main_loop():
	global data,base_url
	#data retrieving
	while data==None:
		fetch_url(base_url+"waiting")
		time.sleep(2)
	#wait 10 seconds
	write_data("NewDrink")
	wait_answer()
	time.sleep(10)
	#dictate ingredients
	for i in data["ingredients"]:
		write_data("*-"+i+str(data["ingredients"][i]))
		wait_answer()
	#update db
	fetch_url(base_url+"completed")
	#reset position
	write_data("*-00")
	wait_answer()
	data=None
def fetch_url(url):
	global data
	try:
		page=urllib.request.urlopen(url)
		j=page.read().decode("utf-8")
		data=json.loads(j)
	except:
		data=None
def wait_answer(answer="1"):
	global ser
	v=None
	while not v==answer:
		v=ser.readline().decode("UTF-8").strip()
		time.sleep(0.2)
def write_data(data):
	global ser
	ser.write(bytes(data+'\n','UTF-8'))
def get_ip():
	myip = "ip addr show wlan0 | grep -m 1 inet | awk '{print $2}' | cut -d/ -f1"
	p = Popen(myip, shell = True, stdout = PIPE)
	output = p.communicate()[0]
	return output.decode("UTF-8").strip()

	

data=None
base_url="http://"+get_ip()+"/orders/"
ser=serial.Serial(port="/dev/ttyS0",baudrate=9600)
write_data("GoHome")
wait_answer()
while True:
	main_loop()
