# 图标与资源自动化处理脚本文档

本项目采用 **"Build-Time Asset Generation"** 策略来处理图标资源。为了兼顾 **微信小程序兼容性**（不支持 `<svg>` 标签，不建议打包大体积 `.ttf`）与 **开发体验**（直接使用 Material Symbols 名称），我们设计了一套自动化脚本流，在构建阶段将用到的图标自动转换为高清 PNG。

## 📂 脚本清单

| 脚本文件 | 作用 | 依赖环境 |
| :--- | :--- | :--- |
| `download_font.js` | 下载最新的 Google Material Symbols 字体文件 (.ttf) 及 Codepoints 映射表。 | Node.js |
| `generate_real_icons.ps1` | 1. 扫描 `/sheji` 目录下的 HTML 文件，提取所有使用的图标名称。<br>2. 读取 Codepoints 映射 Unicode。<br>3. 调用 Windows System.Drawing 库，使用下载的 .ttf 字体将图标渲染为 PNG。<br>4. 自动生成 Tabbar 的 Active/Inactive 双态图标。 | PowerShell (Windows) |
| `fetch_images.js` | 扫描 HTML 中的演示图片链接，自动下载并保存为本地文件。 | Node.js |

## 🚀 使用指南

### 1. 预备工作
确保本地已安装 Node.js，并且操作系统为 Windows（支持 PowerShell）。

### 2. 下载字体源
首次运行或需要更新图标库时执行：
```bash
node scripts/download_font.js
```
此命令会将字体下载至 `static/fonts/MaterialSymbolsOutlined.ttf`。

### 3. 生成 PNG 图标 (增量模式)
当设计稿 HTML 发生变化，或需要新增图标时执行：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_real_icons.ps1
```
脚本会自动：
- 扫描项目中的图标引用。
- **仅生成尚未存在的图标** (增量更新)，已存在的文件会自动跳过。
- 若需强制重新生成所有图标（例如修改了颜色），请先删除 `static/icons/` 目录下的对应文件，或手动修改脚本逻辑。

### 4. 引用方式
在 Vue 组件中，直接引用生成的 PNG 路径即可：
```html
<!-- 原设计稿: <span class="material-symbols-outlined">search</span> -->
<!-- 转换后 -->
<image src="/static/icons/search.png" class="icon-sm" />
```

## ⚙️ 自定义配置

若需修改生成图标的颜色或尺寸，请编辑 `scripts/generate_real_icons.ps1`：

```powershell
# 调整默认颜色 (第 80 行左右)
Generate-Icon -IconName $icon -ColorHex "#333333" ...

# 调整 Tabbar 颜色 (第 85 行左右)
Generate-Icon -IconName "spa" -ColorHex "#E29578" ... # 激活态颜色
```

## ⚠️ 注意事项
- **系统依赖**：渲染脚本依赖 .NET Framework 的 `System.Drawing` 类库，仅适用于 Windows 环境。Mac/Linux 用户需使用基于 ImageMagick 或 Cairo 的替代脚本（暂未提供）。
- **字体版本**：`download_font.js` 下载的是 Variable Font 版本，脚本中已固定 Font Family 名称。
