#import "@preview/typslides:1.3.2": *

// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)

// The front slide is the first slide of your presentation
#front-slide(
  title: "DeepEyes Eval 流程介绍",
  subtitle: [基于强化学习 (RL) 的多模态代理项目],
  authors: "尹超",
  info: [#link("https://github.com/Visual-Agent/DeepEyes")],
)

// Custom outline
#table-of-contents()

// Title slides create new sections
#title-slide[
  DeepEyes 项目介绍
]

// A simple slide
#slide[
  DeepEyes 构建在#stress[VeRL] (Volcano Engine Reinforcement Learning) 框架之上。

  - *核心目标*: 训练多模态代理（Agent），使其能够在推理链中直接整合视觉信息。
  - *能力*: 主动调用 `image_zoom_in_tool` 查看细节，无需依赖冷启动或监督微调。

  #framed(title: "核心机制")[
    **端到端强化学习 (End-to-End RL)**: 利用结果奖励信号引导模型涌现出视觉搜索、比较等能力。
    激励模型 #stress["通过图像思考" (Thinking with Images)]。
  ]
]

// // Slide with columns for code structure
// #slide(title: "代码结构")[
//   #cols(columns: (1fr, 3fr), gutter: 1em)[
//     - *`verl/`*
//     - *`examples/`*
//     - *`results/`*
//     - *`scripts/`*
//   ][
//     #grayed[核心框架代码，含数据集处理 (`utils/dataset`)、模型 (`models`)、训练器等。]
//     #grayed[训练脚本 (`agent/`) 和数据预处理示例 (`data_preprocess/`)。]
//     #grayed[存放评估结果和推理输出。]
//     #grayed[安装和辅助脚本。]
//   ]
// ]

// Title slide for Evaluation Process
#title-slide[
  评估流程介绍 (Evaluation)
]

// Overview & Environment
#slide(title: "评估概览与环境准备")[
  DeepEyes 评估采用 #stress[两步法 (Two-step Approach)]:
  1.  **推理 (Inference)**: 模型生成回答 (含 Thinking & Tool Call)。
  2.  **打分 (Scoring)**: 使用 LLM-as-a-judge (通常为 Qwen-2.5-72B)。

  #framed(title: "环境准备")[
    先拉取官方docker image后，进入workspace，再确保下载了相关模型和数据集（例如推理模型下载命令如下）:
    ```bash
    HF_ENDPOINT=https://hf-mirror.com huggingface-cli download ChenShawn/DeepEyes-7B \
    --local-dir ~/models/DeepEyes-7B \
    --resume-download
    ```
  ]
]

// Model Deployment
#slide(title: "模型部署 (Model Deployment)")[
  评估脚本通过 OpenAI-compatible API (vLLM) 通信。需启动 **两个** 服务：

  #text(size: 16pt)[
  **1. Target Model (被评估模型)**
  ```bash
  vllm serve /path/to/DeepEyes-7B-v1 \
      --port 8000 \
      --trust-remote-code \
      --gpu-memory-utilization 0.9
  ```

  **2. Judge Model (打分模型)**
  ```bash
  vllm serve /path/to/Qwen-2.5-72B-Instruct \
      --port 18901 \
      --served-model-name "judge" \
      --tensor-parallel-size 4
  ```
  ]
]

// V* Benchmark Evaluation - Step 1
#slide(title: "V* 评估 - Step 1: 推理 (Inference)")[
  #cols(columns: (1.6fr, 1fr), gutter: 1em)[
    #text(size: 18pt)[
    ```bash
    python eval/eval_vstar.py \
      --model_name "DeepEyes-7B-v1" \
      --api_key "EMPTY" \
      --api_url "http://localhost:8000/v1" \
      --vstar_bench_path "/path/to/vstar" \
      --save_path "./results" \
      --eval_model_name "default" \
      --num_workers 8
    ```
    ]
  ][
    #text(size: 18pt)[
    **参数解释**:
    - `model_name`: 输出文件夹名，用于区分实验。
    - `api_key`: 鉴权密钥，本地一般用 "EMPTY"。
    - `api_url`: **被评测模型** API 地址。
    - `vstar_bench_path`: V\* 数据集本地路径。
    - `save_path`: 结果保存根目录。
    - `eval_model_name`: 请求体中的 model 字段。
    - `num_workers`: 并发推理线程数。
    ]
  ]
]

// V* Benchmark Evaluation - Step 2
#slide(title: "V* 评估 - Step 2: 打分 (Scoring)")[
  #cols(columns: (1.6fr, 1fr), gutter: 1em)[
    #text(size: 18pt)[
    ```bash
    python eval/judge_result.py \
      --model_name "DeepEyes-7B-v1" \
      --api_key "EMPTY" \
      --api_url "http://localhost:18901/v1" \
      --save_path "./results" \
      --eval_model_name "judge" \
      --num_workers 8
    ```
    ]
  ][
    #text(size: 18pt)[
    **参数解释**:
    - `model_name`: **须与Step 1一致**，定位中间结果。
    - `api_key`: 鉴权密钥。
    - `api_url`: **打分模型 (Judge)** API 地址。
    - `save_path`: 结果读取目录。
    - `eval_model_name`: Judge 模型在 vLLM 的服务名。
    - `num_workers`: 并发打分线程数。
    ]
  ]
]

// HRBench Evaluation
// #slide(title: "HRBench 评估 (同理)")[
//   使用 HRBench 专用脚本，流程与 V\* 相同。

//   #cols(columns: (1fr, 1fr), gutter: 1em)[
//     **Step 1: 推理**
//     #text(size: 12pt)[
//     ```bash
//     python eval/eval_hrbench.py \
//       --model_name "DeepEyes-7B-v1" \
//       --api_url "http://localhost:8000/v1" \
//       --hrbench_path "/path/to/hrbench" \
//       --save_path "./results" \
//       --num_workers 8
//     ```
//     ]
//   ][
//     **Step 2: 打分**
//     #text(size: 12pt)[
//     ```bash
//     python eval/judge_result_hrbench.py \
//       --model_name "DeepEyes-7B-v1" \
//       --api_url "http://localhost:18901/v1" \
//       --save_path "./results" \
//       --eval_model_name "judge"
//     ```
//     ]
//   ]
// ]

// Output Interpretation
#slide(title: "结果解读 (Output Interpretation)")[
  - *中间结果*: `save_path/model_name/result_*.jsonl`
    - 包含: Prompts, Raw Model Outputs, Parsed Answers.

  - *最终分数*: `save_path/model_name/final_acc.json`
    - 生成于打分步骤之后。
    - 包含: 各类别准确率及总体准确率。

  #framed[
    **Usage Tip**:
    确保 `save_path` 和 `model_name` 在两步中完全一致，否则打分脚本无法找到推理结果。
  ]
]

// Title slide for Data Structure
#title-slide[
  数据结构分析
]

// Slide for Input Data Structure
#slide(title: "输入数据结构 (Input Data)", outlined: true)[
  训练数据通常为 *Parquet* 格式，每条数据代表一个训练样本。

  - `data_source`: 数据来源标识 (e.g., `"rag_v2-train"`).
  - `prompt`: 对话历史 (Role: `system`, `user`).
  - #stress[`env_name`]: *关键字段*。指定工具环境 (e.g., `"visual_toolbox_v2"`).
  - `reward_model`: 奖励计算配置 (e.g., `ground_truth`).
  - `images`: 图像数据（路径或二进制）。

  #framed(back-color: white)[
    参考: #link("verl/workers/agent/envs/visual_agent/generate_trainset.py")
  ]
]

// Input Data Example
#slide(title: "输入数据示例 (Input JSON)")[
  #text(size: 19pt)[
  ```json
  {
    "data_source": "deepeyes-train",
    "prompt": [
      { "role": "system", "content": "You are a helpful assistant..." },
      { "role": "user", "content": "What is the color of the flower?..." }
    ],
    "env_name": "visual_toolbox_v2",
    "ability": "qa",
    "reward_model": {
      "style": "rule",
      "ground_truth": "The color is white."
    },
    "extra_info": { "id": "sa_4988", "answer": "The color is white." }
  }
  ```
  ]
]


// Slide for Output Data Structure
#slide(title: "输出数据结构 (Output Data)",outlined: true)[
  结果保存为 **JSONL** 文件，每行一个 JSON 对象。

  #cols(columns: (1fr, 1fr), gutter: 1em)[
    - `image`: 输入图像文件名
    - `question`: 输入问题
    - `answer`: 标准答案 (Ground Truth)
    - `status`: 执行状态
  ][
    - #stress[`pred_ans`]: 模型预测并提取的简短答案
    - #stress[`pred_output`]: 完整的对话交互记录
      - 包含 *思维链* `<think>`
      - 包含 *工具调用* `<tool_call>`
  ]

  #v(1em)
  #grayed[参考: `results/deepeyes-7b/result_direct_attributes_deepeyes-7b.jsonl`]
]

// Output Data Example
#slide(title: "输出数据示例 (Output JSON)")[
  #text(size: 19pt)[
  ```json
  {
    "image": "sa_4988.jpg",
    "question": "What is the color of the flower?",
    "answer": "The color of the flower is white.",
    "pred_ans": "white",
    "pred_output": [
      {
        "role": "assistant",
        "content": "<think>\nI need to check the details of the flower center.\n</think>\n<tool_call>\n{\"name\": \"image_zoom_in_tool\", \"arguments\": {...}}\n</tool_call>\n<answer>The color of the flower is white.</answer>"
      }
    ],
    "status": "success"
  }
  ```
  ]
]

// // Focus slide for Output
// #focus-slide[
//   数据示例
// ]



