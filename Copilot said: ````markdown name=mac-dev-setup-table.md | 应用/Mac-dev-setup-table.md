# GITHUB

常用的开发、拉取、维护等场景下，涉及软件、变量名、设定命令、自定义方式及用途的表格，适用于 Mac 开发环境

| 应用/工具        | 变量名示例           | 设定命令/自定义方式                                 | 用途说明                              |
|------------------|----------------------|----------------------------------------------------|---------------------------------------|
| Git              | GIT_REPO_URL         | `git clone $GIT_REPO_URL`                          | 克隆远程仓库，代码版本管理            |
|                  | GIT_BRANCH           | `git checkout $GIT_BRANCH`                         | 切换分支                              |
| Docker           | DOCKER_IMAGE         | `docker pull $DOCKER_IMAGE`                        | 拉取镜像，容器化部署                   |
|                  | DOCKER_CONTAINER     | `docker run --name $DOCKER_CONTAINER $DOCKER_IMAGE`| 启动容器                               |
| Homebrew         | 无                   | `brew install 包名`                                | Mac 包管理，安装开发软件               |
| Node.js/npm      | NODE_ENV             | `export NODE_ENV=production`                       | 设置环境变量，前端/后端开发            |
|                  | NPM_TOKEN            | `export NPM_TOKEN=xxx`                             | 设置私有包访问令牌                     |
| Python/virtualenv| VIRTUAL_ENV          | `source venv/bin/activate`                         | 激活虚拟环境，依赖隔离                 |
|                  | PYTHONPATH           | `export PYTHONPATH=路径`                           | 设置 Python 模块查找路径               |
| VS Code          | 无                   | `code .`                                           | 打开当前目录为项目                     |
|                  | EDITOR_THEME         | 编辑器设置中自定义                                 | 个性化编辑器外观                       |
| GitHub CLI       | GH_TOKEN             | `export GH_TOKEN=xxx`                              | 命令行操作 GitHub，自动化脚本          |
|                  | 无                   | `gh repo clone owner/repo`                         | 使用 GitHub CLI 克隆仓库               |
| Jenkins          | BUILD_NUMBER         | 环境变量自动注入                                   | 持续集成标识                           |
|                  | 无                   | 配置 Webhook，自动触发构建                         | 自动化部署                             |
| Nginx            | NGINX_PORT           | 配置文件中设置 `listen $NGINX_PORT;`               | Web 服务端口                           |
| MySQL/PostgreSQL | DB_HOST, DB_USER     | `export DB_HOST=localhost`                         | 数据库连接配置                         |
|                  | DB_PASSWORD          | `export DB_PASSWORD=xxx`                           | 数据库密码环境变量                     |
| Redis            | REDIS_HOST           | `export REDIS_HOST=localhost`                      | 缓存服务主机配置                       |
| Kubernetes       | KUBE_CONFIG          | `export KUBE_CONFIG=~/.kube/config`                | K8s 集群连接配置                       |
|                  | NAMESPACE            | `kubectl config set-context --namespace=xx`        | 设置命名空间                           |
| Terraform        | TF_VAR_REGION        | `export TF_VAR_REGION=us-east-1`                   | 云资源区域变量                         |
| Ansible          | ANSIBLE_HOSTS        | `export ANSIBLE_HOSTS=hosts.ini`                   | 自动化运维主机列表                     |
| SSH              | SSH_KEY_PATH         | `ssh -i $SSH_KEY_PATH user@host`                   | 指定密钥远程登录                       |
| 环境变量管理     | .env 文件            | `.env` 文件定义所有变量，如 `DB_HOST=localhost`    | 统一管理项目环境变量                   |
| 系统代理         | http_proxy           | `export http_proxy=http://127.0.0.1:1087`          | 设定系统/开发工具网络代理              |
| Gitee/GitLab     | 无                   | 官方命令行或 GUI 工具                              | 国内/企业代码托管                      |
| MinIO/S3         | S3_BUCKET            | `export S3_BUCKET=xxx`                             | 对象存储桶配置                         |
| RabbitMQ/Kafka   | RABBITMQ_HOST        | `export RABBITMQ_HOST=localhost`                   | 消息队列主机                           |
| Prometheus/Grafana| GRAFANA_API_KEY     | `export GRAFANA_API_KEY=xxx`                       | 监控/可视化平台 API 令牌               |

补充说明：

表中变量名一般用于 .env 或 shell 环境变量设置，命令可直接在 macOS 终端输入。
具体软件配置请参考官方文档，变量名可根据实际项目自定义。
如需更详细某一工具的变量和命令，可指定工具进一步展开。
如需 Excel/Numbers 表格，也可复制内容粘贴至表格应用
