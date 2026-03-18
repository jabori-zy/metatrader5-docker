# MT5 Docker V1

在 Ubuntu EC2 上构建一个单用户、单容器的 MetaTrader 5 运行环境：

- Wine 进镜像
- KasmVNC 提供浏览器桌面
- Docker 固定使用 `winehq-stable 10.0.0.0~bookworm-1`
- 镜像构建期预下载 Wine Gecko / Wine Mono
- 镜像构建期预下载 MT5 和 Python 安装器
- 首次容器启动时自动安装 MT5
- 首次容器启动时自动安装 Windows Python 3.14
- 后续启动只复用已有前缀并启动 MT5

## 前提

- Ubuntu EC2
- `amd64/x86_64`
- 已安装 Docker Engine 和 Docker Compose Plugin
- 安全组允许访问 `3000/tcp`

## 快速开始

1. 复制环境变量文件：

```bash
cp .env.example .env
```

2. 构建镜像：

```bash
docker build --platform linux/amd64 -t metatrader5-docker:dev .
```

3. 启动容器：

```bash
docker compose up -d
```

4. 打开浏览器：

```text
http://<ec2-public-ip>:3000
```

使用 `.env` 中的 `CUSTOM_USER` 和 `PASSWORD` 登录。

## 运行行为

- 镜像构建阶段只安装 Wine 和运行依赖
- 镜像构建阶段固定安装 `winehq-stable 10.0.0.0~bookworm-1`
- 镜像构建阶段还会预下载：
  - `mt5setup.exe`
  - `python-3.14.0-amd64.exe`
  - Wine Gecko
  - Wine Mono
- 首次启动容器时，会在 `/config/.wine` 内初始化 Wine 前缀
- 首次启动容器时，会自动执行 `mt5setup.exe /auto`
- 完成 MT5 无人值守安装后，脚本才会继续安装 Windows Python 3.14
- 如果 `/config/.wine` 已存在，则会复用该前缀并跳过已完成的安装步骤
- 启动脚本会直接运行：

```text
wine "C:\Program Files\MetaTrader 5\terminal64.exe" /portable
```

如果设置了 `MT5_CMD_OPTIONS`，会追加到启动命令后面。

## 常用命令

查看日志：

```bash
docker compose logs -f
```

进入容器：

```bash
docker compose exec mt5 bash
```

检查 MT5 进程：

```bash
docker compose exec mt5 pgrep -fa terminal64.exe
```

检查 Windows Python：

```bash
docker compose exec mt5 bash -lc 'export WINEPREFIX=/config/.wine; wine python --version'
```

验证 MetaTrader5 包：

```bash
docker compose exec mt5 bash -lc 'export WINEPREFIX=/config/.wine; wine python -c "import MetaTrader5; print(MetaTrader5.__version__)"'
```

检查预下载资源：

```bash
docker compose exec mt5 bash -lc 'find /opt/installers /opt/wine-offline -maxdepth 3 -type f | sort'
```

## 仓库结构

```text
.
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── root/defaults/autostart
└── scripts
    ├── build
    │   ├── install-mt5.sh
    │   └── install-python.sh
    └── runtime
        ├── bootstrap-prefix.sh
        ├── healthcheck.sh
        └── start-mt5.sh
```

## 注意事项

- 该版本只解决“流程跑通”，不处理正式持久化和多用户调度
- KasmVNC 基础认证只适合开发/测试环境，不建议直接裸露到公网
- 首次启动主要耗时来自 Wine 前缀初始化和离线安装步骤
- 虽然镜像内已经预下载 `mt5setup.exe`，但它仍是官方引导安装器，安装阶段依然可能联网下载 MT5 主体
- 如果离线安装资源缺失，启动脚本会直接报错，不会静默回退到网络下载
