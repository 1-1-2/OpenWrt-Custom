# 鲁班MOD思路及实现

😀🌼能找到本库，我对你的细心，有十足的信心！

⚠⚠嘿，这是一条温馨的重要提示：本方案的闪存分区与大多数方案并**不兼容**，大概率**不支持**与其它分区的 OP **混刷**。希望您理解本文的目标和手段后，再进行具体操作。

## 基本思路

先明确我需要的是——在硬件不变的前提下，用上原汁原味的可持续升级的 OpenWrt。

其次是明确有什么，对原厂固件内的信息进行了梳理：

1. 分区及内容物如下

   | 闪存地址段          | 分区 Label | 有什么？有用吗？                                             |
   | ------------------- | ---------- | ------------------------------------------------------------ |
   | 0x0000000-0x0040000 | Bootloader | 难以挪用的官方 u-boot，没啥有用的。                          |
   | 0x0040000-0x0050000 | Config     | 原厂的 uboot-env，包含京东云的密钥啥的。都用 OpenWrt 了，没啥用了 |
   | 0x0050000-0x0090000 | Factory    | 分区头部是 mtk EEPROM，分区尾部是设备 SN/MAC。中间是一大片的空白0xFF。信息很有用 |
   | 0x0090000-0x1000000 | firmware   | 原厂系统，里面带了个dts可以反编译作为参照。                  |

   可见原厂的分区分的十分的“大气”，数据也比较稀疏。**我们何不把有用的部分提取出来，把有限的空间尽可能留给系统**

2. 组成一个可用的完整固件，我们需要的只有 Bootloader、EEPROM、MAC、OpenWrt。EEPROM、MAC 来自原厂固件（所以请务必设法获得原厂的编程器固件），余下的 Bootloader、OpenWrt 本文来带你们解决。

## 我的实现

### 第一步：融合Bootloader+EEPROM+MAC

#### breed版本的选取

截至目前（2023年12月31日），大部分的 Breed 都不支持 XMC XM25QH128C 这款闪存，[H大(hackpascal)](https://blog.hackpascal.net/) 亦未放出鲁班专用的 Breed。

参考过《[鲁ban黑板可正常使用云一代breed启动openwrt的方法](https://www.right.com.cn/forum/thread-8285798-1-1.html)》一文以及 lyq1996 的折腾过程，相对可行的办法有如下三个：

1. 换 breed 能识别的 SPI 闪存，用 breed-mt7621-jd-cloud-1.bin，但这不符合**不硬改**的初衷。
2. 用 lyq1996 适配的 u-boot。或者要到一份他提到的 H大 供它测试用的可识别 XM25QH128C 闪存的 Breed。
3. 其实 H大 在 v20220724 中，增加了部分 Breed 对 XM25QH128C 的支持。可以在这类 Breed 上进行“魔改”。

在鲁班上，16M的闪存可谓是寸金寸土，breed 不但空间占用比 u-boot 小得多，还支持更丰富的自定义设置项目。前面我也提到，要把“把有限的空间尽可能留给系统”，原厂的分区过于“大làng气fèi”，必须对其进行压减。这时候第三条路是不二的选择，能用上 Breed 丰富的功能的同时还能实现任意地址的固件引导。

那么现有的 mt7621 平台的 Breed 有：

```
- breed-mt7621-creativebox-v1.bin
- breed-mt7621-hiwifi-hc5961.bin
- breed-mt7621-hiwifi-hc5962.bin
- breed-mt7621-r6220.bin
- breed-mt7621-xiaomi-r3g.bin
- breed-mt7621-zte-e8820s.bin
```

其中只有 creativebox 这款是 SPI 闪存启动的，其余均为 NAND，这款 breed 描述为“CreativeBox v1 专用，DDR3 内存适用，默认 512MB DDR AC 时序参数，波特率 115200，复位键 GPIO#18”，可知其复位引脚与鲁班一致（关于这点，可以跟随 lyq1996 的折腾日志获得原厂固件提取的 dts，里面会告诉你）。

#### 内嵌数据到Bootloader

基于上述选取得 Breed 进行魔改，实现 Bootloader 分区内嵌 EEPROM+MAC

我记录的步骤如下（各步骤涉及的闪存地址后续会解释）：

```
一、提取固件
使用设备：CH341a，跳线1-2（编程模式）
使用软件：NeoProgrammer
闪存型号：XMC XM25QH128C
接线方式：编程器接转换板，转换版接烧录夹SOP8，详下
	1. 烧录夹带红线的这边，夹闪存1号脚一侧（闪存上圆点标记1号脚）
	2. 烧录夹带突起这一侧，接转换版1-4号引脚一侧
	3. 转换版1号引脚，对照CH341a上丝印的图例中25XX这边的带白点的这个脚

原厂固件要素表：
0x50000~0x50DFF	EEPROM(3584 bytes)
0x8FF00~0x8FFFF	SN/MAC(256 bytes)

二、魔改Breed
使用软件：WinHex
1. 新建空白文件AX，大小192kb。按下“CTRL+L”，填充FF。
2. 放入Breed：打开“breed-mt7621-creativebox-v1.bin”全选复制。在0x0处按下“CTRL+B”写入到文件A头部。
3. 写入EEPROM：
	原理：原厂固件的 0x50000~0x50DFF 部分（隶属 factory 分区）为 EEPROM 的有效数据（大小=0xE00=3584bytes=3.5KB），分区余下部分是空值 0xFF。
	操作：原厂固件，“ALT+G”跳转0x50000，“ALT+1”标记选区头，跳转0x50DFF，“ALT+2”标记选区尾，“CTRL+C”复制。转到文件AX，“ALT+G”跳转 0x20000，“CTRL+B”覆写。
4. 写入SN/MAC：
	原理：原厂固件的 0x8FF00~0x8FFFF 部分（隶属 factory 分区）记录了 SN/MAC 数据（大小=0x100=256bytes=0.25KB）。WAN MAC 在 0x8FFF4，LAN MAC 在 0x8FFFA。
	操作：原厂固件，“ALT+G”跳转0x8FF00，“ALT+1”标记选区头，跳转0x8FFFF，“ALT+2”标记选区尾，“CTRL+C”复制。转到文件AX，“ALT+G”跳转 0x28000，“CTRL+B”覆写。此时 WAN MAC 在 0x280F4~0x280F9，LAN MAC 在 0x280FA~0x280FF，格式为 raw hex
5. 保存，获得初步魔改的Breed

三、写入固件
使用软件：NeoProgrammer、WinHex
1. NeoProgrammer 擦除IC，写入魔改的Breed。
2. 拔掉编程器，上电，LAN口上机打开192.168.1.1，进入Breed设置。
3. 启用Breed环境变量，选择【Breed内部】，默认存储在0x2F000~0x30000段，确认，重启。
4. 增加Breed环境变量 字段 autoboot.command，值 boot flash 0x30000，实现自定义引导。
5. Breed备份编程器固件，此时将 sysupgrade 固件“CTRL+B”覆写至地址 0x30000，便可完成固件拼接，通过breed写回设备。
6. 若使用Winhex截取前192kb部分（0x0000-0x30000）即为特定于本设备（包含 EEPROM 和 MAC 属性）、引导地址0x30000的 Breed（大小 192KB）

四、测试：
拔掉编程器
上电亮红灯，192.168.1.1进入BREED
刷入固件
DONE

⚠注意：openwrt中，mtd设备的分区布局可能由dts定义。要实现“充分利用闪存空间”的目标，在编译时需要按照本次魔改的各个地址修正dts！
```

至此，这个基于 Breed “魔改” 的 Bootloader 的数据结构如下

```
# 整合了 breed、EEPROM、SN/MAC 以及通过添加环境变量定义了固件启动位置
0x00000-0x20000 : "breed-mt7621-creativebox-v1"（约占103KB）
0x20000-0x20E00 : "Factory"(EEPROM)
0x28000-0x280F0 : "Factory"(SN/MAC)
0x2F000-0x30000 : "Breed-env"

# 一些说明
BREED 限制环境变量起始地址必须高于 0x2f000
所以环境变量使用【Breed 内部】（0x2F000~0x30000）已是最优解
由此推导，系统分区(firmware)地址头在此情况下是 0x30000
在该分区下，通过设置autoboot.command的值，可实现从闪存0的0x30000位置引导系统启动
```

换句话说，魔改获得的 Bootloader 对应地址段及内容物如下

| 闪存地址段          | 分区 Label | 内容                                               |
| ------------------- | ---------- | -------------------------------------------------- |
| 0x0000000-0x0020000 | u-boot     | breed-mt7621-creativebox-v1(patched for re-cp-02b) |
| 0x0020000-0x0030000 | Factory    | EEPROM、SN/MAC、Breed-env                          |
| 0x0030000-0x1000000 | firmware   | OpenWrt                                            |

**此时有 16MiB-192KiB=16192KiB 的空间可以放系统**，基本实现了闪存的最大化利用。



### 第二步：适配OpenWrt

*这一步的基础是 OpenWrt 对 mt7621 的支持已经十分成熟了，略加适配即可。*主要涉及三个文件：

| 文件路径                                                     | 用途                            |
| ------------------------------------------------------------ | ------------------------------- |
| openwrt/target/linux/ramips/dts/mt7621_jdcloud_re-cp-02.dts  | 设备树文件                      |
| openwrt/target/linux/ramips/mt7621/base-files/etc/board.d/02_network | 定义设备的接口 MAC 的初始化逻辑 |
| openwrt/target/linux/ramips/image/mt7621.mk                  | 定义设备的型号信息              |


OpenWrt 的 dts 是很重要的一环，这里我在以下文件的基础上修改，适配了我前文提到的分区

>[luban.patch](https://github.com/coolsnowwolf/lede/issues/10361)
>
>[ramips/mt7621: Add JDCloud Luban support](https://github.com/coolsnowwolf/lede/pull/10365/files#top)
>
>[lyq1996 的 openwrt for luban](https://github.com/lyq1996/openwrt/commits/v21.02.1-jdcloud-re-cp-02)

获得成品 DTS 文件 [mt7621_jdcloud_re-cp-02-dts](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-mt7621_jdcloud_re-cp-02-dts)



~~上游未添加鲁班的设备信息~~ OpenWrt 上游已[增加对鲁班的支持(since 2024-05-11)](https://github.com/openwrt/openwrt/commit/985af21123a02ff764156aafff2be4e9cc6e640e)，**但分区与本文不一致**。因此，需要对 OpenWrt 的两个文件进行一下 patch：

1. [02_network.patch](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-02_network-re-cp-02-patch) for openwrt/target/linux/ramips/mt7621/base-files/etc/board.d/02_network
2. [mt7621.mk.patch](https://gist.github.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476#file-mt7621-mk-re-cp-02-patch) for openwrt/target/linux/ramips/image/mt7621.mk

对 mt7621.mk 里的 DEVICE_PACKAGES 解释如下

| DEVICE_PACKAGES      | What for                                                     |
| -------------------- | ------------------------------------------------------------ |
| kmod-mt7915e         | 鲁班的 WiFi 是 “MT7975DN + MT7905DAN”，是 kmod-mt7915-firmware 的依赖，可以省略不写 |
| kmod-mt7915-firmware | 根据了解到的资料以及别人的dts，对应 mt7915d 方案，选这个没错 |
| kmod-sdhci-mt7620    | SD卡                                                         |

给源码库补上 dts 并打上补丁，然后按常规流程进行 OpenWrt 编译就可以获得系统固件了。



### 第三步：组合编程器固件+刷入

1. 组合编程器固件：使用 Winhex，将魔改的 Breed 添加到编译获得的 OpenWrt sysupgrade.bin 前部，便获得了 firmware 位于 0x30000 的固件。

2. 刷入：初次使用本方案固件，推荐使用编程器
   1. ***备份*** 并**清空闪存后**刷入空白的`breed-mt7621-creativebox-v1.bin`
   2. 在 Breed 中使用编程器固件刷入完整的组合编程器固件。勾选自动重启、不保留 EEPROM 和 Bootloader，上传刷入，进度条跑完后设备自动重启。
3. 稍等片刻，应该能看到鲁班的红灯开始闪烁，即进入了 OpenWrt 的初始化阶段。

至此事成，往后便可通过 OpenWrt 内的固件升级，使用 **相同分区** 的 OpenWrt 固件进行系统的更新啦！