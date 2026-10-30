# 以 ios-alioth 为主的整合

主项目是 [MrMoxing/ios-alioth](https://github.com/MrMoxing/ios-alioth)，固定来源见 `integration/sources.json`。
启动仍使用本项目的 `boot-one.bat` / `boot-one.ps1`，镜像仍由原有 `ios165/fetch.sh`、`userland/build.sh` 和 `xnuloader/mkpayload.py` 生成。

## 合并边界

| 部分 | 采用方式 |
| --- | --- |
| 默认系统和内核 | 本项目 iOS 16.5 / XNU 8796.121.2 |
| 默认 UEFI、loader、载荷和触摸实现 | 保留本项目已有实现和已发布镜像 |
| UniXNU-alioth | `external/UniXNU-alioth` 固定提交的可选子模块 |
| 已有 Linux 环境、7-Zip、Git、编译工具 | 直接复用，避免重复安装 |
| 原手机备份和本机路径 | 只保存在本地，禁止加入源码提交 |

UniXNU-alioth 的目标是 iPadOS 17.7.11 / XNU 10063.141.1，使用不同 loader、驱动 ABI、信任缓存和磁盘布局。
因此它提供可追踪的板级资料和后续移植参考，默认启动不加载它的内核或镜像。不能把它的 boot.img、补丁或驱动归档直接塞进本项目。
参考分支仅将无法公开取得的 HID 子模块提交换为该项目自身目录和锁文件已列出的公开版本；该差异已记入其 `porting.toml`，不代表硬件验证。

按需取参考源码，普通使用者不需要执行：

```sh
git submodule update --init external/UniXNU-alioth
```

## 离线检查

Windows 下复用原启动脚本，只增加 `-CheckOnly`。它检查镜像、工具路径和现有 `SHA256SUMS.txt`，在任何固件下载或 ADB/Fastboot 调用前返回：

```powershell
.\boot-one.ps1 -CheckOnly
# 仅内核调试的准备状态：
.\boot-one.ps1 -CheckOnly -NoSystem
# 工具已在其他目录时：
.\boot-one.ps1 -CheckOnly -AdbPath 'D:\Android\Sdk\platform-tools\adb.exe' -FastbootPath 'D:\Android\Sdk\platform-tools\fastboot.exe'
```

完整启动缺少 `boot/system.apfs` 时，Windows 和 Bash 入口均直接报告缺项，不再静默降级到内核调试。仅调试内核时仍可显式使用 `-NoSystem` 或 `SYS=`。

## 复用原有镜像构建

`integration/prepare-build.sh` 只是将 README 5.2 的源树组装命令固化；不实现新的内核、APFS、固件下载或启动机制。
构建目录属于生成文件，请在 `src/` 修改源文件后重新组装，不要在生成目录维护独立改动。

```sh
bash integration/prepare-build.sh /path/to/generated-ios165
cd /path/to/generated-ios165
LOCAL_IPSW=/path/to/verified-iPhone10,3,iPhone10,6_16.5_20F66_Restore.ipsw bash ios165/fetch.sh
PREBUILT=1 REST=1 bash userland/build.sh
```

这里使用项目已有的预编译用户态程序，按原脚本生成 `userland/system.apfs`，复制到主项目 `boot/system.apfs` 后再做完整离线检查。
沿用上游已校验的 `boot/root.apfs` 和 `run-payload.bin`；不要把重建目录里不同参数产生的 root 镜像自动覆盖回去。

`firmware/`、`runs/`、`.build/`、`boot/system.apfs` 和 `integration/local.json` 均不入库。Apple IPSW 和生成的系统卷只作为本机构建输入和结果，不上传公开仓库。

## 验证边界

离线检查和成功生成镜像只证明本机文件及构建流程，不能替代本机启动、触摸、GPU 或网络验证。
临时启动沿用上游 RAM 加载方式，但 loader 返回时可能写 `logdump` 日志分区；不能将其描述为绝对不写任何分区。
本次整合不自动启动、刷写或擦除手机。

## 预编译模式修正

上游 `PREBUILT=1` 分支未提供 `drawable_test`，而复制列表仍无条件要求它。本分支按已有可选诊断程序的方式仅在该文件存在时复制；启动所需的 init、stage0、注入库和其他必需程序仍严格检查并直接复用原版。默认启动任务不调用该 GPU 诊断程序。
