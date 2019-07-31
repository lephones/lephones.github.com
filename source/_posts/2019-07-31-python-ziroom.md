title: python入门：使用python刷自如的房子
date: 2019-07-31 16:43:48
category: android开发

tag: [python]
---

# 错过房子

自如在北京租房行业上占据着龙头地位，它们的房租也是一年比一年高，特别是新签约的房子，价格很是离谱。但偶尔也会有一两个换租的房子，性价比超级高。如果有自己比较中意的小区，想监控里面的房子，我就有一次看中一个房子，看到的时候，就已经晚了，等想签的时候，被别人抢先了。这个脚本，可以在某小区有新房源的时候，第一时间通知自己。

<!-- more -->

# 环境

1. python 2.x 语言及运行环境
2. tesseract ocr 这是google的一款图片识别文字的软件，需要安装库，自行搜索python+tesseract
3. 支持smtp协议的邮箱，建议新注册一个。
4. 绑定微信的QQ的邮箱。

安装python和tesseract就不讲了，主要说一下tesseract。其实没有这个也不重要，主要是自如的房子，价格是一张图片。然后用坐标截取相应的数字生成价格图，比如坐标是[8,9,2,1]，那价格就是1345元。其实只要发送房子id就行，去官网看一下，价格就有了。

![](/image/20190731/price.png)

使用邮箱，主要是为了方便微信接收，微信可以绑定QQ邮箱。只要给QQ发送邮件，微信就可以收到信息。

# 流程

1. 发送请求，搜索关键字 http://m.ziroom.com/v7/room/list.json?city_code=110000&type=11&keywords=   后面跟上要搜索的关键字。type=11是一居室,具体参数，可以通过[http://m.ziroom.com](http://m.ziroom.com/)，上面选择搜索信息后，可以查看到具体的type。
2. 拿到列表，解析房源信息。
3. 拿到房子价格图片，识别出内容，根据坐标拼出房价及单元（日租和月租）
4. 检查数据库中是否保存过该房源（已经发送过）
5. 分页会再请求下一页。



# 代码

代码用定时任务跑在了我的服务器上，每隔一段时间跑一下。

写python比较少，再加上后来改代码时，直接用ssh连接的服务器用vi改的，导致代码写的比较乱。

我把信息保存到了ziroom.db里，是sqlite格式。价格为了不每次都请求，也缓存到了image文件夹下。

```
# -*- coding: utf-8 -*-
import sqlite3
import urllib
import urllib2
import os
import re
import sys
import json
import smtplib
import pytesseract
import time
from email.mime.text import MIMEText
from email.header import Header
from PIL import Image

# 第三方 SMTP 服务
mail_host=""  #设置服务器
mail_user=""    #用户名
mail_pass=""   #口令 
sender = ""		#发送邮箱 一般等同于用户名
receivers = ['2323354557@qq.com']  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱

BaseURL = 'http://m.ziroom.com/v7/room/list.json?city_code=110000&type=11&keywords='  
#keywords = '%E9%BE%99%E5%8D%8E%E5%9B%AD'
keywords = ['华清嘉园' , '展春园']
cur_page = 1
room_string = ''

def sendEmail(content,keyword):
	message = MIMEText(content, 'plain', 'utf-8')
	message['From'] = '自如<'+sender+'>'
	message['To'] =  'lefo<2323354557@qq.com>'
	
	subject = '有'+ keyword +'的新房子了'
	message['Subject'] = Header(subject, 'utf-8')
	
	
	try:
		smtpObj = smtplib.SMTP() 
		smtpObj.connect(mail_host, 25)    # 25 为 SMTP 端口号
		smtpObj.login(mail_user,mail_pass)  
		smtpObj.sendmail(sender, receivers, message.as_string())
		print("邮件发送成功")
	except smtplib.SMTPException as e:
		print(e);


def getJson(URL,page,keyword):

	
	global cur_page
	global room_string

	send_headers = {
    'Host':'m.ziroom.com',
    'User-Agent':'Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1',
    'Accept':'application/json;version=6',
	}
  
	
	url = URL +'&page=' + page;
	req = urllib2.Request(url,headers=send_headers)

	content = urllib2.urlopen(req).read().decode('utf-8')
	data = json.loads(content)
	rooms = data['data']['rooms'];
	print(URL)
	print(content)
	
	for room in rooms:
		tags =''
		for tag in room['tags']:
			tags +=(' ' + (tag['title']))
		#print (room['id'] + room['face'] + ' ' + room['name'] + tags + room['price'])
		cursor = c.execute("SELECT * from ROOM WHERE ZID=" + room['id'])
		result = cursor.fetchall()
		
		if len(result) <= 0:
			pricedata = room['price']
			priceurl = 'http:' + pricedata[0]
			print(priceurl)
			path = "image/" + os.path.basename(pricedata[0])
			if not os.path.exists(path):
				res = urllib.urlopen(priceurl).read()
				f = open(path,"wb")
				f.write(res)
				f.close()
			img = Image.open(path)
			print(path)
			imgprice = pytesseract.image_to_string(img,lang='eng',config='-psm 7')
			print(imgprice)
			price = ''
			unit = room['price_unit']
			if len(imgprice)>0:
				for index in pricedata[1]:
					price =price + imgprice[index]
			roomInfo = room['id'] + ' ' +  room['name'] + ' ' + price + unit
			 

			room_string = room_string + roomInfo + '\n'
			sql = 'INSERT INTO ROOM (ZID,HID,TITLE) VALUES ("' + room['id'] +'","'  + room['house_id']+'","' + room['name'] +'")'
			c.execute(sql )
			conn.commit()
	
	if len(rooms) > 0:
		cur_page += 1
		getJson(BaseURL + urllib.quote(keyword),str(cur_page),keyword)
	else:
		if len(room_string) > 0:
			print('send email \n' + room_string)
			sendEmail(room_string,keyword)
			room_string = ''
			
		
conn = sqlite3.connect('ziroom.db')		
c = conn.cursor()
c.execute('''CREATE TABLE IF NOT EXISTS ROOM
       (ID INTEGER PRIMARY KEY AUTOINCREMENT     NOT NULL,
	   ZID           TEXT     NOT NULL,
       HID           TEXT     NOT NULL,
       TITLE        CHAR(50));''')

for keyword in keywords:
	cur_page = 1
	keywordsquote = urllib.quote(keyword)
	getJson(BaseURL + keywordsquote,str(cur_page),keyword)


```

# 自行优化

说一下优化的事，自如的房子有各种状态，参数名叫status，后续，可以把代码加一个状态的判断。比如status == 'dzz'是待租中，还有退租配置中，最关键的是，有一个释放倒计时的状态。这样可以实现某个房子的要释放时，提前通知自己。