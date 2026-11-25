# 一个真实困难（30 秒口播稿）

## 困难：单文件 7.9 MB，手机 4G 首屏 38 秒

**怎么发现的**：`index.html` 7,912,407 B；12 张场景图全部 base64 内嵌，gzip 后仍有 5.9 MB。用 Chrome DevTools 限速 4G（1.6 Mbps / 150 ms）实测：

```
DOMContentLoaded  38.0 s
load              38.0 s
FCP                3.2 s（只有纸张底色）
```

**怎么查的**：先算体积（`du`/gzip 后大小），再用 Playwright + CDP `Network.emulateNetworkConditions` 复现，确认瓶颈是 HTML 本身而不是图片解码。

**怎么改的**：

1. 同一份模板新增 `python3 build.py --dist`：图片转 WebP 外链，HTML 只留 158 KB；
2. `_headers` 给 `assets/*` 加一年 immutable 缓存，场景图按需加载；
3. 单文件版保留，作为离线/双保险。

**结果**：

```
4G 限速 load：38.0 s → 1.45 s
HTML：162 KB → Brotli 61 KB
首屏资源：约 330 KB（背景 + 画轴 + 当前幕）
```

**顺带发现的第二个困难**：`walkthrough_test.js` 12 次跑挂 7 次——随机数没播种、第 7–9 日夜里不补精力。改成固定种子 + 补属性 + 失败非零退出后，三个种子稳定 54 条全绿。这个更"测试工程"，课堂时间够可以二选一讲。
