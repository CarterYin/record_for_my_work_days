
## DeepEyes 评测流程示例
```
root@39573a4695dd:/workspace# VLLM_USE_V1=0 vllm serve /data/models/Qwen2.5-7B-Instruct \
    --port 8000 \
    --trust-remote-code \
    --tensor-parallel-size 1 \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.9 \
    --enforce-eager \
    --served-model-name judge-72b > vllm_judge.log 2>&1 &
```

```
root@39573a4695dd:/workspace# # 启动 Judge，使用 2 张卡进行张量并行 (TP)
# 这样不仅快，而且显存分摊后不容易 OOM
VLLM_USE_V1=0 vllm serve /data/models/Qwen2.5-7B-Instruct \
    --port 8000 \
    --tensor-parallel-size 2 \
    --served-model-name judge-72b \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --max-model-len 8192 \
    --enforce-eager > vllm_judge.log 2>&1 &
```
```
root@39573a4695dd:/workspace# # 指定使用 1 号显卡 (CUDA_VISIBLE_DEVICES=1)
# 指定端口 8001 (--port 8001)
CUDA_VISIBLE_DEVICES=1 VLLM_USE_V1=0 vllm serve /data/models/Qwen2.5-7B-Instruct \
    --port 8001 \
    --tensor-parallel-size 1 \
    --served-model-name judge-72b \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --max-model-len 8192 \
    --enforce-eager > vllm_judge.log 2>&1 &
```
```
root@39573a4695dd:/workspace# python eval/eval_vstar.py \
    --model_name deepeyes-7b \
    --api_url http://localhost:8000/v1 \
    --vstar_bench_path /data/datasets/vstar \
    --save_path ./results \
    --eval_model_name deepeyes-7b \
    --num_workers 8
```
```
root@39573a4695dd:/workspace# python eval/judge_result.py \
    --model_name deepeyes-7b \
    --api_url http://localhost:8001/v1 \
    --vstar_bench_path /data/datasets/vstar \
    --save_path ./results \
    --eval_model_name judge-72b
```