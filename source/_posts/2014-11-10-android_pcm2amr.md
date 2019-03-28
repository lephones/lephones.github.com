title: android pcm转amr格式
date: 2014-11-10 14:23:46
tags: [android,amr]
category: android开发
---
## 引言
项目中需要将科大讯飞生成的录音传递到服务器上，因为amr格式的文件大小最小，而讯飞生成的文件是pcm格式的，所以需要将pcm转换成amr格式。在网上找了半天资料，发现android系统的源码中包含有一个`android.media.AmrInputStream`类，其内部分装了将pcm转换为amr的方法。

## 用法
首先将`AmrInputStream`复制到工程下，注意包名也不要改动，因为该类调用的是libmedia.so的native方法。

只要将原来的pcm文件用`AmrInputStream`read后生成的字节写入新文件就成了amr格式的了。

起初我就是这样试的，结果生成的文件一直不能播放，我以为是采样率的问题，后来试了几个参数都不行。

各种google，百度，终于找到了原因，原来这个只能转内容，而amr文件还需要一个`文件头`。其文件头为六个字节,分别是`0x23` `0x21` `0x41` `0x4D` `0x52` `0x0A`，下面是我写的一个工具类

<!-- more -->

```
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import android.media.AmrInputStream;

public class Pcm2Amr {
	
	public static void pcm2Amr(String pcmPath , String amrPath) {
		try {
			FileInputStream fis = new FileInputStream(pcmPath);
			AmrInputStream ais = new AmrInputStream(fis);
			OutputStream out = new FileOutputStream(amrPath);
			byte[] buf = new byte[4096];
			int len = -1;
			/*
			 * 下面的amr的文件头
			 * 缺少这几个字节是不行的
			 */
	        out.write(0x23);
	        out.write(0x21);
	        out.write(0x41);
	        out.write(0x4D);
	        out.write(0x52);
	        out.write(0x0A);   
			while((len = ais.read(buf)) >0){
				out.write(buf,0,len);
			}
			out.close();
			ais.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}		
	}
}

```