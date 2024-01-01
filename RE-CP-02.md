## 鲁班MOD思路及实现

### 思路

先明确我需要的是——在硬件不变的前提下，用上原汁原味的可持续升级的 OpenWrt。

其次是明确有什么，对原厂固件内的信息进行了梳理：

1. 分区及内容物如下

   | 闪存地址段          | 分区 Label | 有什么？有用吗？                                             |
   | ------------------- | ---------- | ------------------------------------------------------------ |
   | 0x0000000-0x0040000 | Bootloader | 没啥有用的                                                   |
   | 0x0040000-0x0050000 | Config     | 原厂的uboot-env，京东云的密钥啥的。没用                      |
   | 0x0050000-0x0090000 | Factory    | mtk EEPROM位于分区头部 ，设备 SN/MAC 位于分区尾部。中间一大片空白。很有用 |
   | 0x0090000-0x1000000 | firmware   | 原厂系统，里面带了个dts。                                    |

   可见原厂的分区分的十分的“大气”，数据也比较稀疏。**我们何不把有用的部分提取出来，把有限的空间尽可能留给系统**

2. 所以，我们需要的只有 Bootloader、EEPROM、MAC、OpenWrt。

### 实现

#### 第一步：Bootloader、EEPROM、MAC

截至目前（2023年12月31日），H大（hackpascal）尚未放出鲁班专用的 Breed，主要原因是大部分的 Breed 都不支持 XMC XM25QH128C 这款闪存。

参考 [鲁ban黑板可正常使用云一代breed启动openwrt的方法](https://www.right.com.cn/forum/thread-8285798-1-1.html) 以及 lyq1996 的折腾过程，可行的办法由如下三个：

1. 换breed能识别的16m spi闪存，用 breed-mt7621-jd-cloud-1.bin。
2. 用 lyq1996 适配的 u-boot。或者要到一份他提到的 H大 供它测试用的可识别 XM25QH128C 闪存的 Breed。
3. 其实 H大 在 v20220724 中，增加了部分 Breed 对 XM25QH128C 的支持。可以在这类 Breed 上进行“魔改”。

前面我也提到，要把“把有限的空间尽可能留给系统”，这意味着要对闪存的分区进行压减。这时候第三条路是不二的选择，能用上 Breed 丰富的功能的同时还能实现任意地址的固件引导。

那么现有的 mt7621 平台的 Breed 有：

```
- breed-mt7621-creativebox-v1.bin
- breed-mt7621-hiwifi-hc5961.bin
- breed-mt7621-hiwifi-hc5962.bin
- breed-mt7621-r6220.bin
- breed-mt7621-xiaomi-r3g.bin
- breed-mt7621-zte-e8820s.bin
```

其中只有 creativebox 这款是 SPI 闪存启动的，其余均为 NAND，其的描述“CreativeBox v1 专用，DDR3 内存适用，默认 512MB DDR AC 时序参数，波特率 115200，复位键 GPIO#18”。复位引脚与鲁班是一致的（可以跟随 lyq1996 的折腾日志获得原厂固件提取的 dts，里面会告诉你）。

于是基于这个 Breed 进行魔改，我记录的步骤如下（里面的地址接下来会解释）：

```
一、提取固件
使用设备：CH341a，跳线1-2（编程模式）
使用软件：NeoProgrammer
闪存型号：XMC XM25QH128C
接线方式：编程器接转换板，转换版接烧录夹SOP8，详下
	1. 烧录夹带红线的这边，夹闪存1号脚一侧（闪存上圆点标记1号脚）
	2. 烧录夹带突起这一侧，接转换版1-4号引脚一侧
	3. 转换版1号引脚，对照CH341a上丝印的图例中25XX这边的带白点的这个脚

（这步可以跳过）使用软件：BinarySplitter（二进制文件提取工具）
提取config分区：0x30000~0x40000
提取factory分区（EEPROM）：0x40000~0x50000

二、魔改Breed
使用软件：WinHex
1. 新建空白文件AX，大小192kb。按下“CTRL+L”，填充FF。
2. 放入Breed：打开“breed-mt7621-creativebox-v1.bin”全选复制。在0x0处按下“CTRL+B”写入到文件A头部。
3. 写入EEPROM：打开原厂固件“ALT+G”跳转到0x50000，在0x50000处按下“ALT+1”，在0x50E00处按下“ALT+2”，这部分是 factory 分区中的 EEPROM 的有效数据（大小=0xE00）其余都是0xFF的空值。在文件AX的0x20000处按下“CTRL+B”替换写入。
4. 写入SN/MAC：跳转到原厂固件0x8FF00，按下“ALT+1”，在0x8FFFF处按下“ALT+2”，这部分是factory 分区中包含SN/MAC的部分（大小=0xFF）。在AX的0x28000处按下“CTRL+B”替换写入。此时 WAN MAC 在 0x8FFF4，LAN MAC在 0x8FFFA。
5. 保存，获得初步魔改的Breed

三、写入固件
使用软件：NeoProgrammer、WinHex
1. 擦除IC
2. 写入魔改的Breed
3. 拔掉编程器，通电LAN口上机，在Breed中启用环境变量【Breed内部】，重启。
4. 在Breed中增加环境变量 autoboot.command=boot flash 0x30000
5. 下载编程器固件，使用Winhex截取前192kb部分（0x0000-0x30000）
6. 成功获得可引导固件，带EEPROM和MAC的 Breed。（大小 192KB）
```

对于这个“魔改”Breed，其数据结构如下

```
# 整合了 breed、EEPROM、SN/MAC 以及通过添加环境变量定义了固件启动位置

分段内容：
0x00000-0x20000 : "breed-mt7621-creativebox-v1"（约占103KB）
0x20000-0x20E00 : "Factory"(EEPROM)
0x28000-0x280F0 : "Factory"(SN/MAC)
0x2F000-0x30000 : "Breed-env"

BREED 限制环境变量起始地址必须高于 0x2f000
所以环境变量使用【Breed 内部】（0x2F000~0x30000）已是最优解
由此推导，系统(firware)起始点在此情况下可以是 0x30000，据此设置autoboot.command的值，指定从闪存0的0x30000位置启动
```

这个 Breed 对应分区表及内容物如下

| 闪存地址段          | 分区 Label | 内容                        |
| ------------------- | ---------- | --------------------------- |
| 0x0000000-0x0020000 | u-boot     | breed-mt7621-creativebox-v1 |
| 0x0020000-0x0030000 | Factory    | EEPROM、SN/MAC、Breed-env   |
| 0x0030000-0x1000000 | firmware   | OpenWrt                     |

此时有 16MiB-192KiB=16192KiB 的空间可以放系统。



#### 第二步：OpenWrt

OpenWrt 的 dts 是很重要的一环，这里我借鉴了以下几个

>[luban.patch](https://github.com/coolsnowwolf/lede/issues/10361)
>
>[ramips/mt7621: Add JDCloud Luban support](https://github.com/coolsnowwolf/lede/pull/10365/files#top)
>
>[lyq1996 的 openwrt for luban](https://github.com/lyq1996/openwrt/commits/v21.02.1-jdcloud-re-cp-02)

然后根据我设定的分区进行了一下优化，最终成品 [mt7621_jdcloud_re-cp-02-dts](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-mt7621_jdcloud_re-cp-02-dts)

然后对 OpenWrt 的两个文件进行一下 patch，[openwrt/target/linux/ramips/mt7621/base-files/etc/board.d/02_network](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-02_network-re-cp-02-patch) 用于网络初始化（MAC）、[openwrt/target/linux/ramips/image/mt7621.mk](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-mt7621-mk-re-cp-02-patch) 定义型号的信息。

mt7621.mk 里的 DEVICE_PACKAGES 解释如下

| DEVICE_PACKAGES      | What for                                                    |
| -------------------- | ----------------------------------------------------------- |
| kmod-mt7915e         | 鲁班的 WiFi 是 “MT7975DN + MT7905DAN”                       |
| kmod-mt7915-firmware | 根据了解到的资料已经别人的dts，对应 mt7915d方案，选这个没错 |
| kmod-sdhci-mt7620    | SD卡                                                        |

然后根据常规流程进行 OpenWrt 编译就可以了。



#### 第三步：组合编程器固件+刷入

初次加载固件需要通过 Breed 的编程器固件刷入

使用 Winhex，将魔改的 Breed 添加到编译获得的 OpenWrt sysupgrade.bin 前部，便获得了 firmware 位于 0x30000 的固件。

可以使用 Breed 中的编程器固件刷入（勾选自动重启、不保留 EEPROM 和 Bootloader）

上传刷入，进度条跑完后设备自动重启。稍等片刻，应该能看到鲁班的红灯开始闪烁，即进入了 OpenWrt 的初始化阶段。

至此事成，往后便可通过 OpenWrt 内的固件升级，使用 **相同分区** 的 OpenWrt 固件进行系统的更新了。