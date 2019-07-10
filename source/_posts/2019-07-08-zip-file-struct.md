title: 从zip结构看APK采集时优化
date: 2019-07-08 17:44:20
category: android开发

tag: [android]
---

# 现有采集

都知道APK就是一个zip包，目前，收集别人家的APK信息，原理都一样，一般都是先将APK文件下载，再提取AndroidManifest.xml，通过`AXmlPrint2.jar`打开，得到反编译后的xml，解析xml得到包信息。

那么，一个游戏好几个GB，真正用到的却只有几KB信息。如果能跳过内容，结合断点下载，直接下载到AndroidManifest.xml，那就能省很多流量了。

<!-- more -->

# 分析ZIP

图文并茂的文章：https://blog.csdn.net/hp910315/article/details/77717746

表格介绍的文章：https://blog.csdn.net/a200710716/article/details/51644421

上面这两篇文章很详细的介绍了zip文件的结构，我再简单提一下，zip是先保存的文件，最后又将文件信息做了个目录放在最后。如下：

**\[文件实体头+文件数据+数据描述符][..重复..]+核心目录+目录结束标识**

核心目录是关键内容，结构为重复n个\[文件头]，也就是，所有在zip中重复的文件，都有会在核心目录区保存一些关键信息(文件信息，不含文件内容)。其中，包含了每个文件在zip中起始偏移、压缩后的大小，所以，只要我们拿到核心目录的内容，就可以定位到AndroidManifest.xml的位置。

附上两张图：
![manifest文件实体头](/image/20190708/zip-header.jpg)

![manifest核心目录](/image/20190708/zip-dir.jpg)

# 关键头

核心目录中，每个文件头的标记位开始都是4个字节`0x02014b50`，在文件中，高位是在后面存放的，所以，要找的4个字节是0x50，0x4b，0x01，0x02。找到以后，根据对应的偏移，来找到文件名、文件名长度、压缩后大小以及在文件中的位置。

我只列举一下用到的位置

| offset | 大小(字节)    | 代表意义       |
| ------ | ------------- | -------------- |
| 0      | 4             | 0x02014b50     |
| 20     | 4             | 压缩后文件大小 |
| 28     | 2             | 文件名长度(n)  |
| 42     | 4             | 文件保存的位置 |
| 46     | 文件名长度(n) | 文件名         |

找到文件保存的位置和大小后，直接读取成字节数组，然后使用`ZipInputStream`解压。

# 文件

文件分为：文件头、文件数据、数据描述符

文件头后面，就是文件内容了，但是，这些我们都不用关注，我们只需要拿到最开始0x04034b50所在的位置就行。因为ZipInputStream调用getNextEntry可以直接读取。

实际中发现文件头中很多信息都没有，比如文件大小。另外，扩展内容一般情况也是空的，所以基本上文件名后面就是文件内容。

| offset | 大小   | 意义          |
| ------ | ------ | ------------- |
| 0      | 4      | 0x04034b50    |
| 26     | 2      | 文件名长度n   |
| 28     | 2      | 扩展内容长度m |
| 30     | n      | 文件名        |
| 30+n   | m      | 扩展内容      |
| 30+n+m | 不固定 | 文件内容      |

# 思路

1. 找到核心目录开头
2. 找出AndroidManifest.xml文件信息
3. 找到在文件中对应的偏移
4. 解压出AndroidManifest.xml
5. 使用AXmlPrint2.jar转换xml

比较难的是确认核心目录开头，我们可以先获取后1MB的内容，然后读取，如果没有匹配上manifest，则再向前取1MB的内容，再进行一次匹配。使用断点下载时同理。

# 代码

附上代码：这个代码是一边学习一边随手尝试写的，查找目录偏移，读取文件等有很多偷懒的写法，请自行优化。代码只是提供思路以及验证可行性，请不要在正式环境中使用。

另外注意，read()过后，计算下一个offset的时候，要去掉本身的大小的。比如：得到压缩后文件大小，再去获取文件名长度时，是20偏移 + 4字节再到28偏移，所以是skipBytes(4)。

```
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.RandomAccessFile;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class ManifestGetter{

    public static final int DEFAULT_SIZE = 1024 * 1024 *2;
    public static void main(String... args) {

        byte[] signature = new byte[]{0x50,0x4b,0x01,0x02};
    
        String filename = "./test.apk";
        File file = new File( filename);

        try {
            RandomAccessFile accessFile = new RandomAccessFile(file,"r");
            RandomAccessFile accessFile2 = new RandomAccessFile(file,"r");
            long offset = file.length() - DEFAULT_SIZE;
            
            accessFile.seek(offset);
            
            byte[] buffer = new byte[1024];
            int len = 0;
            while((len = accessFile.read(buffer) )> 0){
            
                int index = 0;
                for (; index < len; index++) {
                    
                    boolean flag = true;

                    for (byte signatureB : signature) {

                        byte b = 0;
                        if (index < buffer.length - 4){
                            b = buffer[index++];
                        }else{
                            b = (byte)accessFile.read();
                        }
                        if (signatureB != b){
                            flag = false;
                            break;
                        }
                    }
										//匹配到了0x02014b50标记
                    if (flag){

                        long subOffset = 0;
                        if (index < buffer.length - 4){
                           subOffset = accessFile.getFilePointer() - buffer.length + index -4;
                        }else{
                            subOffset = accessFile.getFilePointer();
                        }
                        
                        //0x04034B50
                        System.out.println("中心目录文件开始-----------" + subOffset);
                        System.out.println("offset =" + subOffset);
												//压缩后文件大小 4字节
                        accessFile2.seek(subOffset + 20);
                        int fileSize = 0;
                        for (int i =0; i < 4; i++) {
                            fileSize += (accessFile2.read()<< (8 *i));
                        }    
                        
                        accessFile2.skipBytes(4);
												//文件名大小 2字节
                        int size_byte1 = accessFile2.read();
                        int size_byte2 = accessFile2.read();

                        int name_size = (size_byte2 << 8 ) + size_byte1;
                        System.out.println("name size = " + name_size);
                        accessFile2.skipBytes(12);

                        long fileOffset = 0;

                        for (int i =0; i < 4; i++) {
                            fileOffset += (accessFile2.read()<< (8 *i));
                        }

                        byte[] nameBuf = new byte[name_size];
                        accessFile2.read(nameBuf);
                        String nameString = new String(nameBuf);

                        System.out.println(nameString + " offset = "+ Long.toHexString(fileOffset));

                        if (nameString.contains("AndroidManifest.xml")){
                           
                            // file header
                            accessFile2.seek(fileOffset);

                            FileOutputStream out = new FileOutputStream("./dest.xml");
                            // 文件里还有一个小文件头，这里加了1024字节，实际情况很小
                            byte[] buf = new byte[fileSize + 1024];
                            accessFile2.read(buf);
                            ByteArrayInputStream bInputStream = new ByteArrayInputStream(buf);
                            ZipInputStream zin = new ZipInputStream(bInputStream);

                            ZipEntry zipEntry = zin.getNextEntry();

                            System.out.println(zipEntry.getName() + "文件信息在目录里，这里的size = " + zipEntry.getSize());
                            
                            byte[] readBuf = new byte[fileSize + 1024];

                            int readLength = 0;
                            while ((readLength = zin.read(readBuf)) > 0) {
                                byte[] bytes = new byte[readLength];
                                System.arraycopy(readBuf, 0, bytes, 0, readLength);
                                out.write(bytes);
                                
                            }

                            accessFile.close();
                            accessFile2.close();
                            out.close();
                            return;

                        }
                        System.out.println(nameString);
                    

                    }                   
                }
            
                offset += len;

            }
            accessFile.close();
            accessFile2.close();
        } catch (Exception e) {
            e.printStackTrace();
        }  
    }
}

```