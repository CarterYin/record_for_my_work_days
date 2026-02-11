# DeepEyes Docker 镜像使用说明
## https://github.com/Visual-Agent/DeepEyes
## 关于迁移 Docker 镜像到远程服务器

由于服务器网络问题无法直接拉取镜像时，通常采用 **“本地拉取 -> 打包传输 -> 远程加载”** 的离线迁移方案。

以下是针对 Windows 本机到 Linux 远程服务器的具体操作步骤：

### 第一步：在 Windows 本机拉取镜像

请打开 Windows 的终端（PowerShell 或 CMD），运行以下命令拉取 DeepEyes 所需的官方镜像：

```powershell
docker pull whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0
```

### 第二步：在 Windows 本机打包镜像

将拉取下来的镜像保存为 `.tar` 文件。由于镜像较大（可能超过 10GB），建议找一个空间充足的磁盘目录操作。

```powershell
# 导出镜像（文件名定为 verl_docker.tar）
docker save -o verl_docker.tar whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0
```

### 第三步：上传文件到远程服务器

使用 `scp` 命令（Windows 10/11 自带）或使用 FTP 工具（如 FileZilla、WinSCP）将文件上传到服务器。

**使用 SCP 命令行示例（在 Windows 终端执行）：**

假设你的服务器 IP 是 `192.168.1.100`，用户名是 `yinchao`，目标路径是 yinchao：

```powershell
scp verl_docker.tar yinchao@iaaccn44:/home/yinchao/DeepEyes
```

### 第四步：在远程服务器加载镜像

登录到你的 Linux 服务器终端，执行加载命令：

```bash
# 加载镜像
docker load -i /home/yinchao/verl_docker.tar
```

### 第五步：验证并启动

加载完成后，验证镜像是否存在，并启动容器：

1.  **验证**：
    ```bash
    docker images | grep whatcanyousee
    ```

2.  **启动**（使用你之前的启动命令）：
    ```bash
    docker run --gpus all -it --shm-size=100g \
        -v /home/yinchao/DeepEyes:/workspace \
        whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0 \
        bash
    ```

### 💡 小贴士
*   **压缩建议**：生成的 `.tar` 文件非常大。如果你的上传带宽较小，可以在 Windows 上先用压缩软件（如 7-Zip）将其压缩为 `.tar.gz` 或 `.zip` 后再上传，然后在服务器解压后再 `docker load`。
*   **WSL 用户**：如果你是在 Windows 的 WSL2 (Ubuntu) 中操作，可以直接使用 `docker save ... | gzip > verl_docker.tar.gz` 一步到位进行压缩打包。


## 关于将 Docker 镜像移动到另一个盘运行

Docker 不支持单独把某一个**正在使用**的镜像移动到另一个盘运行。你只有两种选择：

### 方法一：导出为文件存到另一个盘（用于备份或传输）
如果你只是想把这个 75GB 的大家伙存到 D 盘（或 E 盘）去，不让它占 C 盘空间，但不需要直接运行它：

1.  **打开终端**（PowerShell 或 CMD）。
2.  **运行导出命令**（假设你要存到 `D:\DockerBackups`）：
    ```powershell
    docker save -o "D:\DockerBackups\verl_backup.tar" whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0
    ```
3.  **删除原镜像**（释放 C 盘空间）：
    ```powershell
    docker rmi whatcanyousee/verl:ngc-th2.6.0-cu124-vllm0.8.2-mcore0.11.0-te2.0
    ```
    *以后要用时，用 `docker load -i "D:\DockerBackups\verl_backup.tar"` 加载回来。*

---

### 方法二：把 Docker 整体迁移到另一个盘（推荐）
如果你是因为 C 盘满了，但还需要**运行**这个镜像，你需要把 Docker Desktop 的整个数据存储位置（WSL2 虚拟硬盘）迁移到 D 盘。

1.  **关闭 Docker Desktop**（右键任务栏图标 -> Quit Docker Desktop）。
2.  **关闭 WSL**：在 PowerShell 中运行 `wsl --shutdown`。
3.  **导出数据**（这会花点时间）：
    ```powershell
    wsl --export docker-desktop-data "D:\docker-desktop-data.tar"
    ```
4.  **注销旧数据**（这会清空 C 盘的 Docker 数据）：
    ```powershell
    wsl --unregister docker-desktop-data
    ```
5.  **导入到新位置**（假设你想存在 `D:\DockerData`）：
    ```powershell
    # 先创建目录
    New-Item -ItemType Directory -Path "D:\DockerData"
    # 导入数据
    wsl --import docker-desktop-data "D:\DockerData" "D:\docker-desktop-data.tar" --version 2
    ```
6.  **重启 Docker Desktop**。现在那个 75GB 的镜像就在 D 盘运行了。

## 关于将 Docker 镜像存放到另一个盘（如 E 盘）

在 Windows Docker Desktop 中，你不能直接把镜像保存为分散的文件到 `E:\dockerimages`，但你可以把**存放所有镜像的虚拟磁盘文件**移动到该目录。这样以后所有 `docker pull` 下来的内容都会占用 E 盘空间。

最简单的方法是直接在 Docker Desktop 设置里修改（推荐）：

### 方法一：使用 Docker Desktop 设置（最安全）

1.  在任务栏右下角找到 Docker 图标（鲸鱼），右键选择 **Settings**（设置）。
2.  进入 **Resources**（资源） > **Disk image location**（磁盘镜像位置）。
3.  点击 **Browse**（浏览），选择或新建你的文件夹 `E:\dockerimages`。
4.  点击 **Apply & Restart**。
    *   Docker 会自动把现有的数据（包括那个 75GB 的镜像）移动过去，以后拉取的新镜像也会自动存在这里。

---

### 方法二：使用命令行强制迁移（如果方法一不可用）

如果你的 Docker 版本较老没有上述选项，可以使用 WSL 命令手动迁移：

1.  **退出 Docker Desktop**（右键图标 -> Quit）。
2.  打开 PowerShell，停止所有 WSL 服务：
    ```powershell
    wsl --shutdown
    ```
3.  **导出**当前数据（作为备份和传输）：
    ```powershell
    # 这一步会花点时间，取决于你现在有多少镜像
    wsl --export docker-desktop-data "E:\docker-data-backup.tar"
    ```
4.  **注销**旧的存储位置（从 C 盘删除）：
    ```powershell
    wsl --unregister docker-desktop-data
    ```
5.  **导入**到新位置 `E:\dockerimages`：
    ```powershell
    # 确保文件夹存在
    mkdir "E:\dockerimages"
    # 导入数据
    wsl --import docker-desktop-data "E:\dockerimages" "E:\docker-data-backup.tar" --version 2
    ```
6.  重启 Docker Desktop。完成后可以删除 `E:\docker-data-backup.tar`。


## 常见问题解答
### 问题一：
#### 为什么我删除镜像后 ，在系统中查看C盘还是看到空间未变？

#### 使用傲梅分区助手直接查找C盘大文件，删除第一个dockerdata即可

### 问题二：
#### 我在用scp上传镜像文件时，提示找不到文件？
#### 这是因为你当前终端的工作目录不是镜像文件所在目录。请使用文件的完整路径，或者先切换到正确目录再执行scp命令。
```
(base) PS E:\dockerimages> scp verl_docker.tar yinchao@iaaccn44:/home/yinchao/DeepEyes                      
C:\Windows\System32\OpenSSH\scp.exe: stat local "verl_docker.tar": No such file or directory
(base) PS E:\dockerimages> scp E:\dockerimages\verl_backup.tar yinchao@iaaccn44:/home/yinchao/DeepEyes
yinchao@10.10.100.44's password: 
verl_backup.tar                                                             0%   55MB   2.2MB/s 3:16:04 ETA
```