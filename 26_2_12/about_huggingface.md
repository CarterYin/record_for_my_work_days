#  关于huggingface和docker容器中模型文件路径问题的解决方案
### 1. 强制卸载旧版本 (可能需要运行两次)

为了确保干净，我们先卸载它。

```bash
pip uninstall huggingface_hub -y
pip uninstall huggingface_hub -y
```
*(如果第一次卸载后，再次运行卸载仍提示有残留，请继续卸载直到提示 "Skipping huggingface_hub as it is not installed".)*

### 2. 重新安装最新版

```bash
pip install huggingface_hub==0.28.1
```
*(这里指定一个较新的版本号，确保它不会去安装旧缓存里的包)*

### 3. 再次验证

```bash
python -c "import huggingface_hub; print(huggingface_hub.__version__)"
```
如果输出 `0.28.1` (或类似的高版本)，则升级成功。



GitHub Copilot: 报错 `PermissionError: [Errno 13] Permission denied: '/data/models'` 表明您的用户（yinchao）没有权限在根目录下的 data 文件夹写入数据。

请将下载路径修改为您有权限的目录（例如您的主目录 `~/models`），或者使用 `sudo` 创建目录并赋予权限。

### 方法一：下载到主目录（推荐）

将路径改为 `~/models/...`，系统会自动在您的用户目录下创建文件夹。

**下载 DeepEyes-7B:**
```bash
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download ChenShawn/DeepEyes-7B \
    --local-dir ~/models/DeepEyes-7B \
    --resume-download
```

**下载 Qwen2.5-72B-Instruct:**
```bash
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download Qwen/Qwen2.5-72B-Instruct \
    --local-dir ~/models/Qwen2.5-72B-Instruct \
    --resume-download
```
**下载 Qwen2.5-7B-Instruct（当显存不够时）:**
```bash
HF_ENDPOINT=https://hf-mirror.com python -m huggingface_hub.cli.hf download Qwen/Qwen2.5-7B-Instruct \
    --local-dir ~/models/Qwen2.5-7B-Instruct
    --resume-download
```

*(注意：之后运行评估脚本时，请记得将路径参数也对应改为 `~/models/DeepEyes-7B` 和 `~/models/Qwen2.5-72B-Instruct`)*

---


### 第二步：准备 V* 数据集 (Dataset Preparation)

脚本需要读取本地的 V* Benchmark 数据。

1.  **下载数据**：
    您需要从 HuggingFace 下载 `Visual-Agent/V-Star` 数据集（或从 GitHub 仓库获取）。
    ```bash
    # 创建数据存放目录
    mkdir -p ~/data/vstar
    
    # 下载 V-Star 数据集 (包含 direct_attributes 和 relative_position)
```bash
HF_ENDPOINT=https://hf-mirror.com python -m huggingface_hub.cli.hf download craigwu/vstar_bench \
    --repo-type dataset \
    --local-dir ~/data/vstar \
```


### 第三步：第一阶段 - 待测模型推理 (DeepEyes Inference)

我们需要先启动 DeepEyes-7B 的推理服务，然后运行评估脚本来生成答案。

1.  **启动 vLLM 服务 (终端 A)**：
    ```bash
    # 显存要求：约 16GB VRAM
    vllm serve ~/models/DeepEyes-7B \
        --port 8000 \
        --trust-remote-code \
        --tensor-parallel-size 1 \
        --max-model-len 8192 \
        --served-model-name deepeyes-7b
    ```
    *等待出现 `Application startup complete` 字样。*

2.  **运行推理脚本 (终端 B)**：
    ```bash
    conda activate deepeyes
    cd ~/DeepEyes
    
    # 运行 V* 评估
python eval/eval_vstar.py \
    --model_name deepeyes-7b \
    --api_url http://localhost:8000/v1 \
    --vstar_bench_path /data/datasets/vstar \
    --save_path ./results \
    --eval_model_name deepeyes-7b \
    --num_workers 8
    ```
    *运行完成后，结果会保存在 `./results/deepeyes-7b/` 目录下。*

### 第四步：第二阶段 - 裁判打分 (LLM-as-a-Judge)

现在关闭 DeepEyes 服务，启动强大的 Qwen2.5-72B 来作为裁判给结果打分。

1.  **启动裁判 vLLM 服务 (终端 A)**：
    *先按 `Ctrl+C` 停止之前的服务，然后运行：*
    ```bash
    # 显存要求：需要 4张 A100/A800 (或使用量化版本)
    # 如果显存不足，尝试添加 --quantization awq (需下载量化版模型)
    vllm serve ~/models/Qwen2.5-72B-Instruct \
        --port 8000 \
        --trust-remote-code \
        --tensor-parallel-size 4 \
        --served-model-name judge-72b
    ```

2.  **运行打分脚本 (终端 B)**：    
    ```bash
    python eval/judge_result.py \
        --model_name deepeyes-7b \
        --api_url http://localhost:8000/v1 \
        --vstar_bench_path /data/datasets/vstar \
        --save_path ./results \
        --eval_model_name judge-72b
    ```

### 第五步：查看结果
打分完成后，最终的准确率统计将会在终端输出，同时在 `./results/deepeyes-7b/` 目录下生成打分后的详细 JSONL 文件。


User: hf download ChenShawn/DeepEyes-Datasets-47k --repo-type=dataset如何使用这个来下载到对应目录

GitHub Copilot: 您想使用 `huggingface-cli` 命令行工具将数据集下载到指定目录，请使用以下命令：

```bash
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download ChenShawn/DeepEyes-Datasets-47k \
    --repo-type dataset \
    --local-dir ~/data/DeepEyes-Datasets-47k \
    --resume-download
```

**命令详解：**
*   `HF_ENDPOINT=https://hf-mirror.com`: 使用国内镜像加速下载。
*   `ChenShawn/DeepEyes-Datasets-47k`: 模型/数据集 ID。
*   `--repo-type dataset`: 指定下载的是数据集（默认是模型）。
*   `--local-dir ~/data/DeepEyes-Datasets-47k`: 指定您希望保存到的本地路径。
*   `--resume-download`: 开启断点续传（非常建议加上）。


我已经拉取了镜像文件，并启动了容器，请问接下来如何做eval

GitHub Copilot: 正在优化工具选择...您现在已经在 Docker 容器内部（`root@22d606d31a3e`），但是 `vllm` 报错找不到模型文件 `/data/models/DeepEyes-7B`。这是因为 Docker 容器是一个隔离的环境，它默认看不到宿主机（您之前的 Ubuntu 环境）里的文件，除非您通过 `-v` 参数挂载进去。

您之前的启动命令是：
```bash
docker run ... -v /home/yinchao/DeepEyes:/workspace ...
```
这只把代码目录挂载到了容器的 `/workspace`，但**模型文件**还在宿主机的 `~/models` (即 models) 下，容器里并没有。

---

### 第一步：确保模型文件在容器内可见

**方案 A：重启容器并挂载模型目录（推荐）**

请先退出当前容器（输入 `exit`），然后使用新的命令启动，增加一个挂载点把模型目录映射进去：

```bash
docker run --gpus all -it --shm-size=100g \
    -v /home/yinchao/DeepEyes:/workspace \
    -v /home/yinchao/models:/data/models \
    -v /home/yinchao/data:/data/datasets \
    whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0 \
    bash
```

*解释：*
*   `-v /home/yinchao/models:/data/models`: 把宿主机的 `~/models` 目录挂载到容器内的 models。
*   `-v /home/yinchao/data:/data/datasets`: 把宿主机的 `~/data` (存放 V* 数据集的) 挂载到容器内的 `/data/datasets`。

---

### 第二步：在容器内安装 DeepEyes 依赖

进入容器后，首先需要安装 DeepEyes 项目的依赖。

```bash
# 1. 进入工作目录
cd /workspace

# 2. 安装项目本身
pip install -e .

# 3. 安装评估所需的额外包 (虽然镜像里有 vllm，但 deepeyes 可能有一些特定的脚本依赖)
bash scripts/install_deepeyes.sh
```

---

### 第三步：启动 DeepEyes-7B 推理服务 (Inference)

现在模型路径 `/data/models/DeepEyes-7B` 在容器里应该是可见的了。

```bash
# 在后台启动 vllm，或者开启一个新的终端窗口 (docker exec -it <container_id> bash)
# 这里演示后台启动 (加上 &) 并将日志输出到 log.txt
VLLM_USE_V1=0 vllm serve /data/models/DeepEyes-7B \
    --port 8000 \
    --trust-remote-code \
    --tensor-parallel-size 1 \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.9 \
    --enforce-eager \
    --served-model-name deepeyes-7b > vllm_inference.log 2>&1 &
    #注：根据您的 GPU 显存情况，调整 `--tensor-parallel-size` 和 `--gpu-memory-utilization` 参数。
```

*检查服务是否启动：*
```bash
tail -f vllm_inference.log
# 等待出现 "Application startup complete"
```
彻底清理旧进程：

```bash    
pkill -9 -f vllm
sleep 3
```
---

### 第四步：运行评估脚本

确认 vLLM 启动成功后，运行评估。注意您的 V* 数据集现在挂载在 `/data/datasets/vstar`（假设您宿主机下载到了 `~/data/vstar`）。

```bash
python eval/eval_vstar.py \
    --model_name deepeyes-7b \
    --api_url http://localhost:8000/v1 \
    --vstar_bench_path /data/datasets/vstar \
    --save_path ./results \
    --eval_model_name deepeyes-7b \
    --num_workers 8
```

---

### 第五步：裁判打分 (Judge)

评估跑完后，杀掉之前的 vLLM 进程，换裁判模型启动。

1.  **停止旧服务**:
    ```bash
    pkill vllm
    ```

2.  **启动裁判模型**:
    ```bash
    vllm serve /data/models/Qwen2.5-72B-Instruct \
        --port 8000 \
        --trust-remote-code \
        --tensor-parallel-size 4 \
        --served-model-name judge-72b > vllm_judge.log 2>&1 &
    ```
    *(注：如果是单卡 A100 可能跑不动 72B，根据您的硬件情况调整 `tensor-parallel-size`)*

3.  **运行打分**:
    ```bash
    python eval/judge_result.py \
        --model_name deepeyes-7b \
        --api_url http://localhost:8000/v1 \
        --vstar_bench_path /data/datasets/vstar \
        --save_path ./results \
        --eval_model_name judge-72b
    ```