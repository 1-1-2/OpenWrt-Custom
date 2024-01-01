# 自用编译库

## 设备型号

| [Model](https://openwrt.org/toh) | SoC               | CPU MHz | Flash MB | RAM MB | WLAN Hardware                         | WLAN2.4  | WLAN5.0 | 100M ports | Gbit ports | Modem | USB    |
| :------------------------------- | :---------------- | :------ | :------- | :----- | :------------------------------------ | :------- | :------ | :--------- | :--------- | :---- | :----- |
| HC5661                           | MediaTek MT7620A  | 580     | 16       | 128    | MediaTek MT7620A                      | b/g/n    | -       | 5          | -          | -     | -      |
| Newifi D2 (Newifi3)              | MediaTek MT7621AT | 880     | 32       | 512    | MediaTek MT7603EN, MediaTek MT7612EN  | b/g/n    | ac/n    | -          | 5          | -     | 1x 3.0 |
| RE-SP-01B                        | MediaTek MT7621AT | 880     | 32       | 512    | MediaTek MT7603, MediaTek MT7615      | b/g/n    | ac/n    | -          | 3          | -     | 1x 2.0 |
| RE-CP-02                         | MediaTek MT7621AT | 880     | 16       | 512    | MediaTek MT7975DN, MediaTek MT7905DAN | ax/b/g/n | ac/ax/n | -          | 4          | -     | -      |



## 适配系统

| Model               | [Lean's LEDE](https://github.com/coolsnowwolf/lede) | [OpenWrt](https://github.com/openwrt/openwrt) |
| ------------------- | --------------------------------------------------- | --------------------------------------------- |
| HC5661              | ✅                                                   |                                               |
| Newifi D2 (Newifi3) | ✅                                                   | ✅                                             |
| RE-SP-01B           | ✅                                                   | ✅                                             |
| RE-CP-02            |                                                     | ✅([引导说明](RE-CP-02.md))                    |

暂无更多适配计划

——如果能帮到你，那是我的荣幸——



#### 致谢

云编译模板源自 [P3TERX 的 Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) Ver.[97697df](https://github.com/P3TERX/Actions-OpenWrt/tree/97697df385dc2036681aafed73afd2cd903632f1)

> Actions-OpenWrt - A template for building OpenWrt with GitHub Actions
>
> [English](https://github.com/P3TERX/Actions-OpenWrt/blob/main/README.md) | [中文](https://p3terx.com/archives/build-openwrt-with-github-actions.html)
>
> [![LICENSE](https://img.shields.io/github/license/mashape/apistatus.svg?style=flat-square&label=LICENSE)](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE) ![GitHub Stars](https://img.shields.io/github/stars/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Stars&logo=github) ![GitHub Forks](https://img.shields.io/github/forks/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Forks&logo=github)

