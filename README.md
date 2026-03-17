# MT5 Docker V1

在 Ubuntu EC2 上构建一个单用户、单容器的 MetaTrader 5 运行环境：

- Wine 进镜像
- KasmVNC 提供浏览器桌面
- MT5 在构建期无人值守安装
- Windows Python 3.14 在构建期静默安装
- 运行期只负责初始化可写前缀并启动 MT5

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

- 构建期会在模板 Wine 前缀里自动安装 MT5 和 Windows Python 3.14
- 首次启动容器时，会把镜像内模板复制到 `/config/.wine`
- 如果 `/config/.wine` 已存在，则跳过复制
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
- 构建依赖外网下载官方安装器，若下载失败，`docker build` 会直接失败
