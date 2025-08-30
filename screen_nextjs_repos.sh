#!/bin/bash
# 批量筛选Next.js项目的初查脚本
# 输入：repos.json（仓库列表）；输出：screen_results.csv（筛选结果）

# 初始化结果文件
echo "repo_name,next_version,node_engine_required,dep_ok,build_ok,issue" > screen_results.csv

# 从repos.json读取仓库（假设repos.json中每个仓库对象有name和url字段）
cat repos.json | jq -c '.[]' | while read -r repo; do
  repo_name=$(echo "$repo" | jq -r '.name')
  repo_url=$(echo "$repo" | jq -r '.url')
  issue=""  # 记录问题描述

  echo "===== 检查仓库: $repo_name ====="

  # 克隆仓库（浅克隆，只拉最新代码，加速）
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

  # 检查是否存在package.json（非Node.js项目直接排除）
  if [ ! -f "package.json" ]; then
    issue="无package.json（非Node.js项目）"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    cd .. && rm -rf "$repo_name"
    continue
  fi

  # 1. 检查Next.js版本（提取dependencies中的next版本）
  next_version=$(jq -r '.dependencies.next // "not_found"' package.json)
  if [ "$next_version" = "not_found" ]; then
    issue="未依赖Next.js"
    echo "$repo_name,,,false,false,$issue" >> screen_results.csv
    cd .. && rm -rf "$repo_name"
    continue
  fi

  # 2. 检查Node.js引擎要求（package.json的engines.node字段）
  node_engine=$(jq -r '.engines.node // "未指定"' package.json)

  # 3. 检查依赖是否完整（npm install是否报错）
  dep_ok=true
  if ! npm install --silent; then  # --silent减少输出，只关注错误
    dep_ok=false
    issue+="依赖安装失败;"
  fi

  # 4. 检查构建是否可行（npm run build是否成功，Next.js核心验证）
  build_ok=true
  if ! npm run build --silent; then
    build_ok=false
    issue+="构建失败;"
  fi

  # 5. 额外检查：Next.js版本是否≥14（核心筛选条件）
  if [[ "$next_version" != *"14."* && "$next_version" != *"15."* ]]; then
    issue+="Next.js版本低于14;"
  fi

  # 输出结果到CSV
  echo "$repo_name,$next_version,$node_engine,$dep_ok,$build_ok,$issue" >> ../screen_results.csv

  # 清理克隆的仓库（节省空间）
  cd .. && rm -rf "$repo_name"
done

echo "筛选完成，结果已保存到screen_results.csv"