# 🚀 ARMv7生产环境部署指南

## 📦 镜像信息
- **镜像地址**: `helloworld-lin/sgcc_electricity:armv7-latest`
- **支持架构**: linux/arm/v7
- **适用设备**: 树莓派2B/3B/3B+、其他ARMv7设备

## 🔧 部署方式

### 方式1：Docker Run（简单）

```bash
docker run -d \
  --name sgcc_electricity \
  --network host \
  --restart unless-stopped \
  -v $(pwd)/data:/data \
  -e PHONE_NUMBER='13800138000' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://homeassistant.local:8123/' \
  -e HASS_TOKEN='your_hass_token' \
  -e JOB_START_TIME='07:00' \
  -e LOG_LEVEL='INFO' \
  helloworld-lin/sgcc_electricity:armv7-latest
```

### 方式2：Docker Compose（推荐）

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  sgcc_electricity:
    image: helloworld-lin/sgcc_electricity:armv7-latest
    container_name: sgcc_electricity
    network_mode: host
    restart: unless-stopped
    
    environment:
      - PHONE_NUMBER=13800138000
      - PASSWORD=your_password
      - HASS_URL=http://homeassistant.local:8123/
      - HASS_TOKEN=your_hass_token
      - JOB_START_TIME=07:00
      - LOG_LEVEL=INFO
      - RETRY_TIMES_LIMIT=5
      - DATA_RETENTION_DAYS=7
    
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    
    healthcheck:
      test: ["CMD", "python3", "-c", "from ncc_matcher import NCCMatcher; print('OK')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

启动服务：
```bash
docker-compose up -d
```

## 📋 环境变量配置

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| `PHONE_NUMBER` | ✅ | - | 国网账号手机号 |
| `PASSWORD` | ✅ | - | 国网账号密码 |
| `HASS_URL` | ✅ | - | Home Assistant地址 |
| `HASS_TOKEN` | ✅ | - | HA长期访问令牌 |
| `JOB_START_TIME` | ❌ | 07:00 | 任务执行时间 |
| `LOG_LEVEL` | ❌ | INFO | 日志级别 |
| `RETRY_TIMES_LIMIT` | ❌ | 5 | 最大重试次数 |
| `DATA_RETENTION_DAYS` | ❌ | 7 | 数据保留天数 |

## 🔍 监控和维护

### 查看日志
```bash
docker logs -f sgcc_electricity
```

### 检查状态
```bash
docker ps | grep sgcc_electricity
docker stats sgcc_electricity
```

### 更新镜像
```bash
docker pull helloworld-lin/sgcc_electricity:armv7-latest
docker-compose down
docker-compose up -d
```

### 备份数据
```bash
# 备份数据目录
tar -czf sgcc_backup_$(date +%Y%m%d).tar.gz ./data

# 备份配置
cp docker-compose.yml docker-compose.yml.backup
```

## 🛠️ 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   # 检查日志
   docker logs sgcc_electricity
   
   # 检查配置
   docker inspect sgcc_electricity
   ```

2. **网络连接问题**
   ```bash
   # 测试Home Assistant连接
   curl -H "Authorization: Bearer YOUR_TOKEN" http://your_ha_ip:8123/api/
   ```

3. **权限问题**
   ```bash
   # 确保数据目录权限
   sudo chown -R 1000:1000 ./data
   ```

## 📊 性能优化

### ARMv7设备优化建议

1. **内存限制**：
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M
       reservations:
         memory: 256M
   ```

2. **CPU限制**：
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1.0'
       reservations:
         cpus: '0.5'
   ```

3. **存储优化**：
   - 使用SSD存储提高I/O性能
   - 定期清理日志文件
   - 设置合适的数据保留期

## 🎉 部署完成

部署成功后，你将拥有：
- ✅ 自动化的国网电费数据采集
- ✅ 与Home Assistant的无缝集成
- ✅ 可靠的ARMv7架构支持
- ✅ 容器化的易维护部署

---
构建时间: $(date)
镜像版本: armv7-latest
