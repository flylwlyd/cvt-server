# CVT Server 部署指南（解决手机端「网络请求失败」）

## 问题原因

APK 在手机上**直连** `fred.stlouisfed.org`（FRED 美国经济数据）等境外源，
国内网络经常无法访问，因此前端独立引擎拉数失败 → 提示网络请求失败。

**解法**：把 Express server 部署到一台手机能访问的服务器上（境外 VPS 或国内云主机均可，
服务器自己能访问 FRED 即可），server 在服务端代理拉取并计算，手机只访问你的服务器。
**部署后无需重新打包 APK**：打开 App → 设置 → 后端地址，填入部署地址即可。

部署前自测：用手机浏览器打开下面两个地址，能下载/显示 CSV 说明手机直连不行（或反过来验证）：
- `https://fred.stlouisfed.org/graph/fredgraph.csv?id=VIXCLS&cosd=2026-06-01`
- `https://quotes.sina.cn` （新浪接口国内一般可达）

---

## 方式 A：Render.com 云部署（最简单，约 5 分钟）

1. 把本 server 目录推到一个 GitHub 仓库（只需 `server/` 目录内容在仓库根，含 Dockerfile 可选）。
2. 登录 [render.com](https://render.com) → **New → Web Service** → 连接该仓库。
3. 配置：
   - **Runtime**: Node
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `node dist/index.js`
   - **Health Check Path**: `/api/v1/health`
4. Deploy。完成后得到地址：`https://你的服务名.onrender.com`
5. 验证：浏览器打开 `https://你的服务名.onrender.com/api/v1/health` → 应显示 `{"status":"ok"}`
6. App 设置页填入该地址（不带末尾 `/`）。

> 免费档 15 分钟无访问会休眠，首次打开慢 30-60 秒；付费 $7/月 常驻。
> 仓库里已带 `render.yaml`，用 Blueprint 方式可一键按配置创建。

## 方式 B：Docker 部署（任何 VPS / 群晖 / 家里 NAS）

```bash
cd server
docker build -t cvt-server .
docker run -d -p 8080:8080 --restart always --name cvt-server cvt-server
curl http://服务器IP:8080/api/v1/health   # 应返回 {"status":"ok"}
```

## 方式 C：国内云主机直接跑（腾讯云/阿里云轻量，需要 Node 18+）

```bash
# 在 server 目录
npm install && npm run build
# 用 pm2 常驻
npm i -g pm2
PORT=8080 pm2 start dist/index.js --name cvt-server
pm2 save && pm2 startup     # 开机自启
```
记得在云主机安全组放行 8080 端口。国内主机访问 FRED 通常也需要在主机上配置代理出境，
**所以国内主机一般不如境外 VPS 直接可用**，选境外机房（香港/美国/新加坡）更省事。

## 方式 D：临时方案——家里电脑跑 server（手机同 WiFi）

```bash
cd server
npm install && npm run build
PORT=9091 node dist/index.js
```
电脑 `ipconfig` 查局域网 IP（如 `192.168.1.100`），App 设置页填 `http://192.168.1.100:9091`。
仅限同一 WiFi 下使用，电脑关机即失效——只适合调试。

---

## 部署后如何让 App 使用

**方式 1（推荐，无需重打包）**：App → 设置 → 后端地址，填入，例如
`https://cvt-server.onrender.com`（不要带末尾斜杠、不要带 `/api`）。

**方式 2（打包内置）**：以后重打包时在 `client/.env` 里填：
```
EXPO_PUBLIC_BACKEND_BASE_URL=https://cvt-server.onrender.com
```

## 验证清单

- [ ] `curl https://你的地址/api/v1/health` 返回 `{"status":"ok"}`
- [ ] `curl "https://你的地址/api/v1/cvt/panel?mode=normal"` 返回 `{"ok":true,"data":{...cvt...}}`
- [ ] App 设置页填入地址 → 返回首页下拉/等待 → 看板出现数值
- [ ] 历史页曲线正常加载（首次可能要 10-30 秒，之后有缓存）
