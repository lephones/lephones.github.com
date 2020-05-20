title: python+selenium为你自动挂海淀驾校法陪课
date: 2020-05-18 20:25:12
category: python

tag: [python,selenium]
---

# 前言

在北京摇号摇了18次了，下次开始就是四倍概率。然后，中签还是遥遥无期，隔壁坐的同事摇了两年就摇到了，万分羡慕。有时候晚上想去溜达一下，要去找gofun共享汽车还要走1公里多，还车还要走1公里。于是就有了想买一辆摩托车的想法。

要买车，肯定得有驾照，挑选完以后，报了海淀驾校，小区门口就有驾校的班车，关键是便宜，只要1000块。在我家那18线城市的小地方也得800多。于是报名，开始上法陪课。但法陪课每一章节必须自已手动点开始，很是麻烦，于是就想写个程序代替自己手点。

<!-- more -->

## 手机端
法陪课可以在网页上上，也可以在APP上上，没自动播放，估计也是想让你好好学习，怕你偷懒吧。

因为我是做安卓的，起先打算拿在手机上搞，发现手机上是个自定义控件，基本不能用辅助功能（类似微信抢红包插件的技术）下手。唯一可用的就是

```
adb -s device_name shell input tap x y
```

然后多久发一次命令又是个问题，于是就打算从网页上下手。

## 网页端
网页上看，播放视频是一个flash，想用javascript也就没办法搞了，只得用selenium。

准备工作：

- Python：不解释
- selenium: pip3 install selenium安装
- Firefox：浏览器，本来我使用的是chrome，发现chrome对flash做了个优化，切后台后，flash不自动加载，换火狐就没问题了。
- geckodriver:火狐浏览器的驱动，供selenium调用

# 放代码

```
from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.support.wait import WebDriverWait
import re
import time

def findTime(dr):
    timeText = driver.find_element_by_class_name('playing').text
    p1 = re.compile(r'[(](.*?)[)]', re.S)
    timeList = re.findall(p1, timeText)
    if len(timeList) == 0:
        return 0
    else:
        timearr = timeList[0].split(':')
        return int(timearr[1]) * 60 + int(timearr[2])

#flash的事件不能通过element触发 
def click_locxy(dr, x, y, left_click=True):
    '''
    dr:浏览器
    x:页面x坐标
    y:页面y坐标
    left_click:True为鼠标左键点击，否则为右键点击
    '''
    if left_click:
        ActionChains(dr).move_by_offset(x, y).click().perform()
    else:
        ActionChains(dr).move_by_offset(x, y).context_click().perform()
    ActionChains(dr).move_by_offset(-x, -y).perform()  # 将鼠标位置恢复到移动前


opts = FirefoxOptions()
#opts.add_argument("--headless")
option_profile = webdriver.FirefoxProfile()
option_profile.set_preference("plugin.state.flash",2)

path = "/Users/lefo/Documents/dev/chrome/geckodriver"# 注意这个路径需要时可执行路径（chmod 777 dir or 755 dir）
driver = webdriver.Firefox(executable_path=path,options=opts)
driver.get('http://www.xuechebu.com/sign.html')
def playing():
    playing = WebDriverWait(driver,60,1).until(lambda x:x.find_element_by_class_name('playing')) #等一分钟，直到获取到正在播放的控件
    text = playing.text
    print(text)
    time.sleep(3) #等三秒，有时候文字可能加载慢
    nextTime = findTime(dr=driver) #文字中提取括号内的时间
    playing.click() #这里貌似无所谓，不点击也可以
    print(str(nextTime))  #下一次执行的时间
    time.sleep(10) #这个10s主要是为了flash允许有时间点
    click_locxy(driver,750,540,left_click=True) #根据坐标点上去
    time.sleep(nextTime + 5)  #这个5s和上面10s同样的道理
count = 0
while(count <= 99):  #99这个数值具体自己设
    playing()
    count = count +1

driver.quit()

```

# 说明

首先，获取正在播放的超链接，上面文字的格式：第x章节(00:02:30)表示2分30秒长，计算成秒，然后间隔这个时间值再去下一个循环。因为播放完成后会自动跳到下一个章节，只是不会开始播放而已，所以，我们要做的就是，间隔一段时间，点一下播放。

试过传入启动flash插件的参数，最后也失败了，所以启动后需要在一分钟内登录，然后去 附加组件 - 插件 将flash插件启用。再将页面上的flash点个允许。点完允许后，10s内会触发一次播放点击。如果你觉得1分钟的登录时间不够，那就改一下上面的时间，或者，加上登录的逻辑（其实我是有登录的，发文章的时候，删掉了）

如果你是其它挂课的网页，道理也是相同的，如果用JS可以实现还是用js吧。因为这个网页有flash的特殊性，才用的selenium，我对python和selenium都不熟，里面的函数几乎一个都不知道，只能边学边搜边写。