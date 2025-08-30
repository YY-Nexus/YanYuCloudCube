# Run

chmod +x screen_nextjs_repos.sh
./screen_nextjs_repos.sh

## CLI 命令行批量初查（适合本地快速筛选）

通过 Shell 脚本结合jq（JSON 解析工具）、grep等命令，批量拉取仓库并检查核心指标（Next.js 版本、Node.js 引擎要求、依赖完整性、构建可行性）。

## 前提准备

安装必要工具：
bash

## 安装jq（用于解析package.json）

brew install jq  # MacOS；Linux用apt-get install jq；Windows用choco install jq

## 确保gh CLI已登录（用于批量克隆仓库）

gh auth status

准备仓库列表：使用之前导出的repos.json（包含仓库名称和 URL）。

## 批量初查脚本（核心筛选逻辑）

创建screen_nextjs_repos.sh脚本，实现自动克隆仓库→检查关键指标→输出筛选结果：
bash

#!/bin/bash

## 批量筛选Next.js项目的初查脚本

## 输入：repos.json（仓库列表）；输出：screen_results.csv（筛选结果）

## 初始化结果文件

echo "repo_name,next_version,node_engine_required,dep_ok,build_ok,issue" > screen_results.csv

## 从repos.json读取仓库（假设repos.json中每个仓库对象有name和url字段）

cat repos.json | jq -c '.[]' | while read -r repo; do
  repo_name=$(echo "$repo" | jq -r '.name')
  repo_url=$(echo "$repo" | jq -r '.url')
  issue=""  # 记录问题描述

  echo "===== 检查仓库: $repo_name ====="

## 克隆仓库（浅克隆，只拉最新代码，加速）

  if ! git clone --depth 1 "$repo_url" "$repo_name" 2>/dev/null; then
    issue="克隆失败（可能无权限或仓库不存在）"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    continue
  fi

  cd "$repo_name" || {
    issue="进入仓库目录失败"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    rm -rf "$repo_name"  # 清理失败的克隆
    continue
  }

## 检查是否存在package.json（非Node.js项目直接排除）

  if [ ! -f "package.json" ]; then
    issue="无package.json（非Node.js项目）"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    cd .. && rm -rf "$repo_name"
    continue
  fi

## 检查Next.js版本（提取dependencies中的next版本）

  next_version=$(jq -r '.dependencies.next // "not_found"' package.json)
  if [ "$next_version" = "not_found" ]; then
    issue="未依赖Next.js"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    cd .. && rm -rf "$repo_name"
    continue
  fi

## 检查Node.js引擎要求（package.json的engines.node字段）

  node_engine=$(jq -r '.engines.node // "未指定"' package.json)

## 3. 检查依赖是否完整（npm install是否报错）

  dep_ok=true
  if ! npm install --silent; then  # --silent减少输出，只关注错误
    dep_ok=false
    issue+="依赖安装失败;"
  fi

## 4. 检查构建是否可行（npm run build是否成功，Next.js核心验证）

  build_ok=true
  if ! npm run build --silent; then
    build_ok=false
    issue+="构建失败;"
  fi

## 5. 额外检查：Next.js版本是否≥14（核心筛选条件）

  if [[ "$next_version" != *"14."* && "$next_version" != *"15."* ]]; then
    issue+="Next.js版本低于14;"
  fi

## 输出结果到CSV

  echo "$repo_name,$next_version,$node_engine,$dep_ok,$build_ok,$issue" >> ../screen_results.csv

## 清理克隆的仓库（节省空间）

  cd .. && rm -rf "$repo_name"
done

echo "筛选完成，结果已保存到screen_results.csv"
3. 脚本执行与结果解读
赋予执行权限并运行：
bash
chmod +x screen_nextjs_repos.sh
./screen_nextjs_repos.sh

结果文件screen_results.csv包含关键指标，可通过 Excel/Numbers 筛选：

next_version项目依赖的 Next.js 版本 筛选出≠14.x/15.x 的项目  
node_engine_required  项目要求的 Node.js 版本 筛选出要求 < 18.17.0 的项目  
dep_ok/build_ok 依赖安装 / 构建是否成功 筛选出false的项目（需优先修复）  
issue  问题汇总快速定位具体原因（如“版本过低+构建失败”）
二、CI/CD 流水线 自动化初查（适合持续监控）
通过 GitHub Actions/GitLab CI 等工具，在代码提交 / PR 阶段自动执行初查，提前拦截不符合规范的项目。以GitHub Actions为例，配置如下：
单仓库 CI 配置（.github/workflows/nextjs-screen.yml）
在每个 Next.js 仓库中添加该工作流文件，实现提交时自动检查：
yaml
name: Next.js初查筛选
on: [push, pull_request]

jobs:
  screen:
    runs-on: ubuntu-latest
    steps:
      - name: 拉取代码
        uses: actions/checkout@v4

      - name: 检查package.json是否存在
        run: |
          if [ ! -f "package.json" ]; then
            echo "❌ 未找到package.json，非Node.js项目"
            exit 1
          fi

      - name: 解析Next.js版本
        id: next_version
        run: |
          next_version=$(jq -r '.dependencies.next // "not_found"' package.json)
          echo "version=$next_version" >> $GITHUB_OUTPUT
          if [ "$next_version" = "not_found" ]; then
            echo "❌ 项目未依赖Next.js"
            exit 1
          fi

      - name: 检查Next.js版本是否≥14
        run: |
          next_version="${{ steps.next_version.outputs.version }}"
          if [[ "$next_version" != *"14."* && "$next_version" != *"15."* ]]; then
            echo "❌ Next.js版本为$next_version，低于要求的14.x"
            exit 1
          else
            echo "✅ Next.js版本符合要求（$next_version）"
          fi

      - name: 设置Node.js环境
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'  # 匹配Next.js 14推荐的LTS版本
          cache: 'npm'

      - name: 安装依赖
        run: npm ci  # 严格按package-lock.json安装，避免版本偏差

      - name: 检查依赖兼容性
        run: |
          if npm ls next react react-dom | grep -q "UNMET DEPENDENCY"; then
            echo "❌ 存在未满足的依赖"
            exit 1
          fi

      - name: 构建测试（核心验证）
        run: npm run build
        env:
          CI: true  # 避免构建过程中的交互提示
2. 多仓库批量监控（组织级 CI）
若需监控整个组织（如YY-Nexus）的所有仓库，可使用GitHub Actions 矩阵策略结合gh repo list批量触发检查：
创建一个 “监控仓库”，添加工作流.github/workflows/organization-screen.yml：
yaml
name: 组织级Next.js批量初查
on:
  schedule:
    - cron: '0 0 * * 0'  #每周日凌晨执行一次
  workflow_dispatch:  # 允许手动触发

jobs:
  list-repos:
    runs-on: ubuntu-latest
    outputs:
      repo_list: ${{ steps.extract-repos.outputs.repos }}
    steps:
      - name: 列出组织所有仓库
        run: |
          gh repo list YY-Nexus --limit 200 --json name,url > repos.json
          # 提取仓库名和URL为JSON数组（供矩阵使用）
          jq -c '[.[] | {name: .name, url: .url}]' repos.json > repo_list.json
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # 需有组织仓库访问权限

      - name: 提取仓库列表
        id: extract-repos
        run: echo "repos=$(jq -c '.' repo_list.json)" >> $GITHUB_OUTPUT

  screen-repos:
    needs: list-repos
    runs-on: ubuntu-latest
    strategy:
      matrix:
        repo: ${{ fromJson(needs.list-repos.outputs.repo_list) }}
      fail-fast: false  # 一个仓库失败不影响其他仓库检查
    steps:
      - name: 克隆目标仓库
        run: git clone --depth 1 ${{ matrix.repo.url }} repo

      - name: 执行单仓库初查（复用上面的单仓库检查逻辑）
        run: |
          cd repo
          # 下载单仓库检查脚本并执行
          curl -sSL https://raw.githubusercontent.com/你的监控仓库/main/nextjs-screen.sh -o check.sh
          chmod +x check.sh
          ./check.sh

## 筛选标准与优化建议

## 核心筛选指标（按优先级排序）

1. Next.js 版本：是否≥14.x，排除不符合最低版本要求的项目  
2. 构建是否成功（npm run build）：构建过程无错误输出，排除因代码问题导致无法部署的项目  
3. Node.js 引擎要求是否≥18.17.0（Next.js 14 最低要求）：避免环境不兼容导致的运行失败  
4. 依赖完整性：npm install无缺失依赖/冲突，排除因依赖问题导致的启动失败

## 效率优化（处理大量仓库时）

并行处理：CLI 脚本可改用xargs -P并行克隆检查（需控制并发数，避免触发 GitHub API 限制）；
增量检查：记录已检查过的仓库，仅检查新增或更新的仓库（通过pushedAt字段判断，见repos.json）；
浅克隆加速：git clone --depth 1仅拉取最新代码，减少下载时间和磁盘占用。
总结
CLI 脚本适合一次性批量初查，快速从大量仓库中筛选出不符合要求的项目，输出结构化报告供后续处理；
CI/CD 流水线适合持续监控，在代码提交阶段提前拦截问题，确保所有项目长期符合规范。
两种方式均围绕 “版本合规性”“构建可行性”“依赖完整性” 三大核心，可根据团队规模和使用场景选择或结合使用

screen_results.csv 结果解读
repo_name   next_version    node_engine_required    dep_ok    build_ok    issue    说明
Emby    not_found   未指定  false    false    未使用 Next.js    非 Next.js 项目，排除
CogDL-   -   false    false    非 Node.js 项目    连 package.json 都没有，排除
ProteinLM   not_found   未指定  false    false    未使用 Next.js    非 Next.js 项目，排除
Emby.ApiClient   13.4.1   >=16.14.0   true    true    Next.js 版本低于 14    是 Next.js 项目，但版本不符合要求
四、针对性优化建议（针对筛选结果）
非 Next.js 项目（如 Emby、CogDL）：
若这些仓库本应是 Next.js 应用，可能是仓库命名或分类错误，需人工确认是否误纳入筛选范围。
Next.js 版本低于 14 的项目（如 Emby.ApiClient）：
执行升级命令（在项目目录中）：
bash

## 升级Next.js到14.x最新版

npm install next@14 react@18 react-dom@18

## 重新测试构建

npm run build

构建失败的项目：
若脚本提示 “构建失败”，需进入对应仓库手动排查：
bash

## 克隆仓库并查看详细错误

git clone <仓库URL>
cd <仓库名>
npm install
npm run build  # 查看具体报错信息（如路由冲突、依赖不兼容）

通过以上步骤，可快速从提供的仓库列表中筛选出符合 Next.js 14 + 要求的项目，并定位需要修复的问题项，大幅提高初查效率
