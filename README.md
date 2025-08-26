# RTX 3080 AI Docker 환경 설정 v4.2 (Git 문제 해결)

## 환경설정 예시와 항목별 상세 설명

### 사용자/그룹 설정
```ini
USER_NAME=helm                # 컨테이너 리눅스 사용자명 (호스트와 통일 권장)
GROUP_NAME=helm               # 그룹명
WANTED_UID=1024               # 파일 권한 일치 위해 UID/GID를 컨테이너/호스트와 통일(1000 이상)
WANTED_GID=1024
```
- 호스트 계정도 동일 UID/GID 권장. 변경 시 기존 소유 파일은 반드시 `chown -R [UID]:[GID]` 처리

### 기본 경로 구조
```ini
BASE_DIR=/home/helm/imagine/shared       # 데이터 공유 루트
COMMON_DIR=${BASE_DIR}/common
COMFY_BASEDIR=${BASE_DIR}/comfyui
MODELS_DIR=${COMMON_DIR}/models
OUTPUTS_DIR=${COMMON_DIR}/outputs
CACHE_DIR=${BASE_DIR}/cache
```
- 절대경로 사용 필수, 사전 생성 및 755 이상 권한으로 셋팅

### 컨테이너별 디렉터리
```ini
FORGE_BASEDIR=${BASE_DIR}/forge
SDW_BASEDIR=${BASE_DIR}/sdw
```
- 컨테이너별 독립 경로 지정, 충돌 예방

### 각 컨테이너 설정 및 포트
```ini
COMFYUI_CONTAINER=comfyui
COMFYUI_IMAGE=your/comfyui-nvidia-docker:latest
COMFY_HOST_PORT=8181
COMFY_CTR_PORT=8188
COMFY_CLI_ARGS="--listen ..."

FORGE_CONTAINER=forge
FORGE_IMAGE=your/stable-diffusion-webui-forge:latest
FORGE_HOST_PORT=8182
FORGE_CTR_PORT=7860
FORGE_ARGS="--listen ..."

SDW_CONTAINER=sdw
SDW_IMAGE=your/stable-diffusion-webui-docker:latest-cuda
SDW_HOST_PORT=8183
SDW_CTR_PORT=7860
SDW_ARGS="--listen ..."
```
- 포트 충돌 방지, 각 서비스별로 분리 지정

### RTX 3080 최적화 옵션
```ini
ENABLE_RTX3080_OPTIMIZATION=true
PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512,garbage_collection_threshold:0.6"
SHM_SIZE="4g"
```

### 버전 관리 예시
```ini
PYTORCH_VERSION="2.3.1+cu121"
TORCHVISION_VERSION="0.18.1+cu121"
TORCHAUDIO_VERSION="2.3.1+cu121"
XFORMERS_VERSION="0.0.26.post1"
```

### Git 및 네트워크 문제 대응
```ini
ENABLE_GIT_SAFE_MODE=true        # 파일권한/Clone 오류 자동복구
OFFLINE_MODE=false               # 네트워크 문제시만 true
SKIP_GIT_CLONE=false
PRE_PREPARE_ASSETS=true
GIT_CLONE_TIMEOUT=300
MAX_GIT_RETRY=3
```
- 다양한 실전 상황에 따른 안전장치 옵션입니다

### 배포/기타 옵션 요약
- DEPLOY_MODE: (basic/full/all) 환경에 맞게 선택
- LOG_LEVEL: 운영환경은 INFO 이상, DEBUG는 개발용만
- ALLOW_EXTERNAL_ACCESS=false: 외부 공개 필요 없으면 false 권장
- 기타: 모델 백업/복구·성능 튜닝 값 등 필요에 따라 추가

### 보안 및 운영 실전 Tip
- 모든 토큰·키·패스워드는 절대 저장소 커밋 불가, 반드시 .env 파일에서만 분리 보관(Git에는 .gitignore 적용)
- UID/GID 변경 시 기존 파일 소유권 항상 체크
- 컨테이너 외부 접근(포트 열기)은 최소화, 127.0.0.1 바인딩 권장
- root 권한 사용 지양, 소유자 권한과 그룹만 운영

---

# RTX 3080 AI Docker Setup
## 환경 변수 설정 가이드
### .env 파일 템플릿
프로젝트 루트 디렉토리에 `.env` 파일을 생성하고 다음 템플릿을 참조하여 설정하세요:
```bash
# ===== Docker & 컨테이너 설정 =====
# 컨테이너명 (영문, 숫자, 하이픈만 사용)
CONTAINER_NAME=rtx3080-ai-container
# 포트 설정 (외부:내부)
JUPYTER_PORT=8888
TENSORBOARD_PORT=6006
SSH_PORT=2222
# ===== 사용자 권한 설정 =====
# 현재 시스템의 UID/GID (보안 및 파일 권한을 위해 필수)
UID=1024
GID=1024
USER_NAME=aiuser
# ===== GPU 설정 =====
# NVIDIA GPU 디바이스 설정
GPU_DEVICE_ID=0
CUDA_VERSION=11.8
CUDNN_VERSION=8
# ===== 데이터 경로 설정 =====
# 호스트 시스템의 절대 경로로 설정
DATA_PATH=/home/YOUR_USERNAME/ai_data
MODELS_PATH=/home/YOUR_USERNAME/ai_models
NOTEBOOKS_PATH=/home/YOUR_USERNAME/notebooks
OUTPUT_PATH=/home/YOUR_USERNAME/ai_output
# ===== API 키 & 토큰 설정 =====
# 실제 사용시 각 서비스에서 발급받은 키로 교체
HUGGINGFACE_TOKEN=hf_XXXXXXXXXXXXXXXXXXXXXXXXX
OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
WANDB_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# ===== 네트워크 설정 =====
# Docker 네트워크 이름
NETWORK_NAME=ai-network
# ===== 로깅 설정 =====
# 로그 레벨 (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=INFO
LOG_PATH=/home/YOUR_USERNAME/logs
# ===== 메모리 & 성능 설정 =====
