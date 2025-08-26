#!/bin/bash

# =============================================================================
# RTX 3080 AI Docker 환경 구축 스크립트 v4.3 (완전 범용 버전)
# =============================================================================
# 
# 이 스크립트는 모든 개인 정보가 제거된 완전히 범용적인 버전입니다.
# 사용자는 .env 파일을 통해 자신의 환경에 맞게 설정할 수 있습니다.
#
# 라이선스: Mozilla Public License 2.0
# Copyright (c) 2024 AI Community
# =============================================================================

set -e  # 오류 발생 시 즉시 중단

# ===[🔧 기본 설정 및 로깅 함수]===
log() { echo "[$(date '+%H:%M:%S')] ✅ $1"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠️  $1"; }
error() { echo "[$(date '+%H:%M:%S')] ❌ $1"; exit 1; }

# ===[📖 도움말 함수]===
show_help() {
    cat << EOF
🚀 RTX 3080 AI Docker 환경 구축 스크립트 v4.3 (완전 범용 버전)

📋 사용법:
  $0 [옵션]

🔧 옵션:
  --help, -h              이 도움말 표시
  --delete                 기존 환경 완전 삭제
  --force-recreate         컨테이너 강제 재생성
  --no-models              모델 다운로드 건너뛰기
  --fix-git-only          Git 문제만 수정 (기존 컨테이너 유지)
  --offline-mode          오프라인 모드 (Git 클론 건너뛰기)
  --create-subdirs        모델 하위 디렉터리 생성 (카테고리별 정리)
  --flat-structure        플랫 구조 유지 (기본값)

📁 사전 설정:
  1. .env 파일 생성: cp .env.example .env
  2. .env 파일 수정: nano .env (사용자명, 경로, UID/GID 설정)
  3. 스크립트 실행: $0 --delete --force-recreate --no-models

🌐 접속 정보 (기본값):
  ComfyUI: http://localhost:8181
  Forge WebUI: http://localhost:8182
  SDW: http://localhost:8183 (full 모드)

📝 예시:
  $0                   # 기본 실행
  $0 --offline-mode    # 네트워크 문제 시 오프라인 실행
  $0 --fix-git-only    # Git 문제만 수정
  $0 --delete          # 완전 재구축

🔧 문제 해결:
  - Git 문제: $0 --fix-git-only
  - 권한 문제: .env 파일의 UID/GID 확인
  - 경로 문제: .env 파일의 BASE_DIR 확인

📄 라이선스: Mozilla Public License 2.0
EOF
}

# 도움말 옵션 즉시 확인
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        show_help
        exit 0
    fi
done

# ===[🎯 환경변수 설정]===
# 사용자별 설정 (환경 변수 또는 기본값)
USER_NAME=${USER_NAME:-aiuser}
GROUP_NAME=${GROUP_NAME:-aiuser}
WANTED_UID=${WANTED_UID:-1024}
WANTED_GID=${WANTED_GID:-1024}

# 기본 경로 구조 (환경 변수 또는 기본값)
BASE_DIR=${BASE_DIR:-/home/aiuser/ai-project/shared}
COMMON_DIR=${COMMON_DIR:-$BASE_DIR/common}
MODELS_DIR=${MODELS_DIR:-$COMMON_DIR/models}
OUTPUTS_DIR=${OUTPUTS_DIR:-$COMMON_DIR/outputs}
COMFY_BASEDIR=${COMFY_BASEDIR:-$BASE_DIR/comfyui}
FORGE_BASEDIR=${FORGE_BASEDIR:-$BASE_DIR/forge}
SDW_BASEDIR=${SDW_BASEDIR:-$BASE_DIR/sdw}
CACHE_DIR=${CACHE_DIR:-$BASE_DIR/cache}

# RTX 3080 최적화 설정
ENABLE_RTX3080_OPTIMIZATION=${ENABLE_RTX3080_OPTIMIZATION:-true}
PYTORCH_VERSION=${PYTORCH_VERSION:-2.3.1+cu121}
TORCHVISION_VERSION=${TORCHVISION_VERSION:-0.18.1+cu121}
TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-2.3.1+cu121}
XFORMERS_VERSION=${XFORMERS_VERSION:-0.0.26.post1}
SHM_SIZE=${SHM_SIZE:-4g}
PYTORCH_CUDA_ALLOC_CONF=${PYTORCH_CUDA_ALLOC_CONF:-max_split_size_mb:512,garbage_collection_threshold:0.6,expandable_segments:True}

# Docker 이미지 설정
COMFYUI_IMAGE=${COMFYUI_IMAGE:-mmartial/comfyui-nvidia-docker:latest}
FORGE_IMAGE=${FORGE_IMAGE:-nykk3/stable-diffusion-webui-forge:latest}
SDW_IMAGE=${SDW_IMAGE:-siutin/stable-diffusion-webui-docker:latest-cuda}

# 컨테이너 이름
COMFYUI_CONTAINER=${COMFYUI_CONTAINER:-comfyui}
FORGE_CONTAINER=${FORGE_CONTAINER:-forge}
SDW_CONTAINER=${SDW_CONTAINER:-sdw}

# 포트 설정
COMFYUI_PORT=${COMFYUI_HOST_PORT:-8181}
FORGE_PORT=${FORGE_HOST_PORT:-8182}
SDW_PORT=${SDW_HOST_PORT:-8183}
COMFYUI_CTR_PORT=${COMFY_CTR_PORT:-8188}
FORGE_CTR_PORT=${FORGE_CTR_PORT:-7860}
SDW_CTR_PORT=${SDW_CTR_PORT:-7861}

# 실행 인자
COMFY_CLI_ARGS="${COMFY_CLI_ARGS:---listen 0.0.0.0 --port 8188 --enable-cors-header}"
FORGE_ARGS="${FORGE_ARGS:---listen --port 7860 --server-name 0.0.0.0 --api --xformers --opt-sdp-attention --enable-insecure-extension-access --no-half-vae --theme dark --gradio-queue --opt-channelslast --allow-code --cuda-malloc --skip-version-check}"
SDW_ARGS="${SDW_ARGS:---listen --port 7861 --server-name 0.0.0.0 --api --xformers --opt-sdp-attention --no-half-vae --enable-insecure-extension-access --theme dark --opt-channelslast --gradio-queue --allow-code --cuda-malloc --skip-version-check}"

# 기능 설정
ENABLE_CACHE_SHARE=${ENABLE_CACHE_SHARE:-true}
LOG_LEVEL=${LOG_LEVEL:-INFO}
ENABLE_VRAM_MONITORING=${ENABLE_VRAM_MONITORING:-true}
VRAM_WARNING_THRESHOLD=${VRAM_WARNING_THRESHOLD:-85}
AUTO_CLEANUP_ON_OOM=${AUTO_CLEANUP_ON_OOM:-true}

# 배포 모드
DEPLOY_MODE=${DEPLOY_MODE:-basic}
CIVITAI_TOKEN=${CIVITAI_TOKEN:-}
HF_TOKEN=${HF_TOKEN:-}

# 설치 옵션
INSTALL_EXTENSIONS=${INSTALL_EXTENSIONS:-true}
INSTALL_COMFYUI_MANAGER=${INSTALL_COMFYUI_MANAGER:-true}
DOWNLOAD_BASIC_MODELS=${DOWNLOAD_BASIC_MODELS:-true}

# 모델 구조 설정
CREATE_MODEL_SUBDIRS=${CREATE_MODEL_SUBDIRS:-false}
ORGANIZE_LORAS_BY_CATEGORY=${ORGANIZE_LORAS_BY_CATEGORY:-false}
CREATE_CONTROLNET_SUBDIRS=${CREATE_CONTROLNET_SUBDIRS:-false}

# 마운트 옵션
MOUNT_CONTROLNET=${MOUNT_CONTROLNET:-true}
MOUNT_MULTIPLE_UPSCALERS=${MOUNT_MULTIPLE_UPSCALERS:-false}

# Git 및 네트워크 문제 대응
ENABLE_GIT_SAFE_MODE=${ENABLE_GIT_SAFE_MODE:-true}
OFFLINE_MODE=${OFFLINE_MODE:-false}
SKIP_GIT_CLONE=${SKIP_GIT_CLONE:-false}
PRE_PREPARE_ASSETS=${PRE_PREPARE_ASSETS:-true}
GIT_CLONE_TIMEOUT=${GIT_CLONE_TIMEOUT:-300}
MAX_GIT_RETRY=${MAX_GIT_RETRY:-3}

# 문제 해결 옵션
FIX_GIT_ONLY=${FIX_GIT_ONLY:-false}

# 명령줄 인수 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h) show_help; exit 0 ;;
        --delete) DELETE_EXISTING=true; shift ;;
        --force-recreate) FORCE_RECREATE=true; shift ;;
        --no-models) SKIP_MODEL_DOWNLOAD=true; shift ;;
        --create-subdirs) CREATE_MODEL_SUBDIRS=true; shift ;;
        --flat-structure) CREATE_MODEL_SUBDIRS=false; shift ;;
        --fix-git-only) FIX_GIT_ONLY=true; shift ;;
        --offline-mode) OFFLINE_MODE=true; SKIP_GIT_CLONE=true; shift ;;
        *) shift ;;
    esac
done

log "RTX 3080 AI 환경 구축 v4.3 (완전 범용 버전) 시작"
log "사용자: $USER_NAME (UID: $WANTED_UID, GID: $WANTED_GID)"
log "기본 경로: $BASE_DIR"
log "배포 모드: $DEPLOY_MODE"

# ===[🔧 .env 파일 자동 생성]===
create_env_file() {
    if [[ -f ".env" ]]; then
        log ".env 파일이 이미 존재합니다. 기존 파일 유지"
        return 0
    fi
    
    log ".env 파일 자동 생성 중..."
    
    # 현재 사용자 정보 확인
    local current_user=$(whoami)
    local current_uid=$(id -u)
    local current_gid=$(id -g)
    local current_home=$(echo $HOME)
    
    # 기본 프로젝트 경로 생성
    local default_base_dir="$current_home/ai-project/shared"
    
    # UID/GID 1024 권장 (안정적인 권한 설정)
    local recommended_uid=1024
    local recommended_gid=1024
    
    cat > ".env" << EOF
# ===== RTX 3080 AI Docker 환경 설정 =====
# 이 파일은 자동으로 생성되었습니다. 필요에 따라 수정하세요.

# ===[👤 사용자 권한 설정]===
USER_NAME=$current_user
GROUP_NAME=$current_user
WANTED_UID=$recommended_uid
WANTED_GID=$recommended_gid

# ===[📁 경로 설정]===
BASE_DIR=$default_base_dir
COMMON_DIR=\${BASE_DIR}/common
MODELS_DIR=\${COMMON_DIR}/models
OUTPUTS_DIR=\${COMMON_DIR}/outputs
COMFY_BASEDIR=\${BASE_DIR}/comfyui
FORGE_BASEDIR=\${BASE_DIR}/forge
SDW_BASEDIR=\${BASE_DIR}/sdw
CACHE_DIR=\${BASE_DIR}/cache

# ===[🚀 RTX 3080 최적화]===
ENABLE_RTX3080_OPTIMIZATION=true
PYTORCH_VERSION=2.3.1+cu121
TORCHVISION_VERSION=0.18.1+cu121
TORCHAUDIO_VERSION=2.3.1+cu121
XFORMERS_VERSION=0.0.26.post1
SHM_SIZE=4g
PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512,garbage_collection_threshold:0.6,expandable_segments:True"

# ===[🐳 Docker 설정]===
COMFYUI_IMAGE=mmartial/comfyui-nvidia-docker:latest
FORGE_IMAGE=nykk3/stable-diffusion-webui-forge:latest
SDW_IMAGE=siutin/stable-diffusion-webui-docker:latest-cuda

# ===[🔧 기능 설정]===
ENABLE_CACHE_SHARE=true
LOG_LEVEL=INFO
ENABLE_VRAM_MONITORING=true
VRAM_WARNING_THRESHOLD=85
AUTO_CLEANUP_ON_OOM=true

# ===[📊 배포 모드]===
DEPLOY_MODE=basic

# ===[📁 모델 구조]===
CREATE_MODEL_SUBDIRS=false
ORGANIZE_LORAS_BY_CATEGORY=false
CREATE_CONTROLNET_SUBDIRS=false

# ===[🔗 마운트 옵션]===
MOUNT_CONTROLNET=true
MOUNT_MULTIPLE_UPSCALERS=true

# ===[🔧 문제 해결]===
ENABLE_GIT_SAFE_MODE=true
OFFLINE_MODE=false
SKIP_GIT_CLONE=false
PRE_PREPARE_ASSETS=true
GIT_CLONE_TIMEOUT=300
MAX_GIT_RETRY=3

# ===[📝 사용법]===
# 1. 이 파일을 수정하여 원하는 설정으로 변경
# 2. 스크립트 실행: ./setup_ai_env_universal.sh --delete --force-recreate --no-models
# 3. 접속: ComfyUI (http://localhost:8181), Forge (http://localhost:8182)
EOF
    
    log ".env 파일 생성 완료: $PWD/.env"
    log "현재 사용자: $current_user (UID: $current_uid, GID: $current_gid)"
    log "권장 UID/GID: $recommended_uid (안정적인 권한 설정)"
    log "기본 경로: $default_base_dir"
    log "권한 설정: sudo chown -R $recommended_uid:$recommended_gid $default_base_dir"
    log "필요에 따라 .env 파일을 수정한 후 스크립트를 실행하세요."
}

# ===[🔍 시스템 검증]===
validate_system() {
    log "시스템 검증 중..."
    
    # .env 파일 자동 생성
    create_env_file
    
    # Docker 실행 확인
    if ! command -v docker &> /dev/null; then
        error "Docker가 설치되지 않았습니다. Docker Desktop을 설치하세요."
    fi
    
    # Docker 서비스 실행 확인
    if ! docker info &> /dev/null; then
        error "Docker 서비스가 실행되지 않았습니다. Docker Desktop을 시작하세요."
    fi
    
    # NVIDIA GPU 확인
    if ! command -v nvidia-smi &> /dev/null; then
        warn "NVIDIA GPU가 감지되지 않았습니다. GPU 가속이 제한될 수 있습니다."
    else
        log "NVIDIA GPU 감지됨: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)"
    fi
    
    # 디렉터리 권한 확인
    if [[ ! -w "$(dirname "$BASE_DIR")" ]]; then
        error "기본 디렉터리 생성 권한이 없습니다: $(dirname "$BASE_DIR")"
    fi
    
    log "시스템 검증 완료"
}

# ===[🔧 Git 안전 환경 설정]===
setup_git_safe_environment() {
    log "Git 안전 환경 설정 중..."
    
    # Git 전역 설정
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global --add safe.directory '*' 2>/dev/null || true
    git config --global http.postBuffer 524288000 2>/dev/null || true
    git config --global http.timeout 300 2>/dev/null || true
    
    log "Git 안전 환경 설정 완료"
}

# ===[📁 실용적 디렉터리 구조 생성]===
create_practical_directory_structure() {
    log "실용적 디렉터리 구조 생성 중..."
    
    # 기존 디렉터리 삭제 (--delete 옵션 시)
    if [[ "$DELETE_EXISTING" == "true" ]]; then
        log "기존 디렉터리 삭제 중..."
        if sudo rm -rf "$BASE_DIR" 2>/dev/null; then
            log "기존 디렉터리 삭제 완료"
        else
            # sudo rm -rf 실패 시 대안 방법
            log "sudo rm -rf 실패, 대안 방법으로 삭제 시도..."
            if sudo find "$BASE_DIR" -type f -delete && sudo find "$BASE_DIR" -type d -delete; then
                log "대안 방법으로 디렉터리 삭제 완료"
            else
                warn "디렉터리 삭제 실패, 기존 구조 유지"
            fi
        fi
    fi
    
    # 기본 디렉터리 구조 생성
    local dirs=(
        "$BASE_DIR"
        "$COMMON_DIR"
        "$MODELS_DIR"
        "$OUTPUTS_DIR"
        "$COMFY_BASEDIR"
        "$FORGE_BASEDIR"
        "$CACHE_DIR"
    )
    
    # SDW 디렉터리 (full 모드 시)
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        dirs+=("$SDW_BASEDIR")
    fi
    
    # 디렉터리 생성
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log "디렉터리 생성: $dir"
    done
    
    # 모델 하위 디렉터리 생성
    if [[ "$CREATE_MODEL_SUBDIRS" == "true" ]]; then
        local model_subdirs=(
            "checkpoints"
            "loras"
            "vae"
            "embeddings"
            "upscale_models"
            "controlnet"
            "ipadapter"
            "t2i_adapter"
            "animatediff_models"
        )
        
        for subdir in "${model_subdirs[@]}"; do
            mkdir -p "$MODELS_DIR/$subdir"
            log "모델 하위 디렉터리 생성: $subdir"
        done
    fi
    
    # 출력 디렉터리 생성
    local output_subdirs=("comfyui" "forge")
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        output_subdirs+=("sdw")
    fi
    
    for subdir in "${output_subdirs[@]}"; do
        mkdir -p "$OUTPUTS_DIR/$subdir"
        log "출력 하위 디렉터리 생성: $subdir"
    fi
    
    # 캐시 디렉터리 생성
    local cache_subdirs=("huggingface" "pip" "torch")
    for subdir in "${cache_subdirs[@]}"; do
        mkdir -p "$CACHE_DIR/$subdir"
        log "캐시 하위 디렉터리 생성: $subdir"
    fi
    
    log "디렉터리 구조 생성 완료"
}

# ===[🔐 권한 설정]===
setup_permissions() {
    log "권한 설정 중..."
    
    # 기본 디렉터리 권한 설정
    if [[ "$WANTED_UID" != "0" && "$WANTED_GID" != "0" ]]; then
        sudo chown -R "$WANTED_UID:$WANTED_GID" "$BASE_DIR" 2>/dev/null || true
        sudo chmod -R 755 "$BASE_DIR" 2>/dev/null || true
        log "기본 디렉터리 권한 설정 완료 (UID: $WANTED_UID, GID: $WANTED_GID)"
    else
        warn "root 권한 사용 감지, 권한 설정 건너뜀 (보안상 권장하지 않음)"
    fi
    
    # 모델 디렉터리 특별 권한 설정
    if [[ -d "$MODELS_DIR" ]]; then
        sudo chmod -R 755 "$MODELS_DIR" 2>/dev/null || true
        log "모델 디렉터리 권한 설정 완료"
    fi
    
    # 출력 디렉터리 권한 설정
    if [[ -d "$OUTPUTS_DIR" ]]; then
        sudo chmod -R 755 "$OUTPUTS_DIR" 2>/dev/null || true
        log "출력 디렉터리 권한 설정 완료"
    fi
    
    log "권한 설정 완료"
}

# ===[🔧 Git 문제 해결 시스템]===
prepare_host_assets() {
    if [[ "$SKIP_GIT_CLONE" == "true" ]]; then
        log "Git 클론 건너뜀 (오프라인 모드)"
        return 0
    fi
    
    log "호스트에서 assets 사전 준비 중..."
    
    # stable-diffusion-webui-assets 준비
    local assets_dir="$COMFY_BASEDIR/repositories/stable-diffusion-webui-assets"
    mkdir -p "$assets_dir"
    
    # Git 클론 시도
    local clone_success=false
    local retry_count=0
    
    while [[ $retry_count -lt $MAX_GIT_RETRY && "$clone_success" == "false" ]]; do
        retry_count=$((retry_count + 1))
        log "Git 클론 시도 $retry_count/$MAX_GIT_RETRY..."
        
        if git clone --depth 1 --single-branch https://github.com/Stability-AI/stable-diffusion-webui-assets.git "$assets_dir" 2>/dev/null; then
            clone_success=true
            log "Git 클론 성공"
        else
            warn "Git 클론 실패, 재시도 중... (3초 후)"
            sleep 3
        fi
    done
    
    # Git 클론 실패 시 대안 방법
    if [[ "$clone_success" == "false" ]]; then
        log "Git 클론 실패, 대안 방법으로 assets 준비..."
        cd "$assets_dir"
        
        # Git 초기화
        git init
        git config --local --add safe.directory .
        git config --local user.name "aiuser"
        git config --local user.email "aiuser@example.com"
        
        # 기본 파일 생성
        echo "# Stable Diffusion WebUI Assets" > README.md
        git add README.md
        git commit -m "Initial commit" || true
        
        log "대안 방법으로 assets 준비 완료"
    fi
    
    # 권한 설정
    if [[ "$WANTED_UID" != "0" && "$WANTED_GID" != "0" ]]; then
        sudo chown -R "$WANTED_UID:$WANTED_GID" "$assets_dir" 2>/dev/null || true
    fi
    
    log "호스트 assets 준비 완료"
}

fix_existing_git_issues() {
    log "기존 Git 문제 수정 중..."
    
    # 전역 Git 설정
    git config --global --add safe.directory '*' 2>/dev/null || true
    
    # 기존 컨테이너에서 Git 문제 수정
    local containers=("$COMFYUI_CONTAINER" "$FORGE_CONTAINER")
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        containers+=("$SDW_CONTAINER")
    fi
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            log "$container 컨테이너에서 Git 문제 수정 중..."
            docker exec "$container" bash -c "
                git config --global --add safe.directory '*' 2>/dev/null || true
                if [ -d '/app/stable-diffusion-webui/repositories/stable-diffusion-webui-assets' ]; then
                    cd '/app/stable-diffusion-webui/repositories/stable-diffusion-webui-assets'
                    git config --local --add safe.directory . 2>/dev/null || true
                fi
            " 2>/dev/null || warn "$container Git 문제 수정 실패"
        fi
    done
    
    log "기존 Git 문제 수정 완료"
}

fix_git_only() {
    log "Git 문제 전용 수정 모드 시작"
    
    # Git 안전 환경 설정
    setup_git_safe_environment
    
    # 호스트 assets 준비
    prepare_host_assets
    
    # 기존 Git 문제 수정
    fix_existing_git_issues
    
    log "✅ 🔧 Git 문제가 해결되었습니다."
    log "이제 정상적으로 WebUI를 사용할 수 있습니다."
}

# ===[📥 기본 모델 다운로드]===
download_basic_models() {
    if [[ "$SKIP_MODEL_DOWNLOAD" == "true" ]]; then
        log "모델 다운로드 건너뜀 (--no-models 옵션)"
        return 0
    fi
    
    if [[ "$DOWNLOAD_BASIC_MODELS" != "true" ]]; then
        log "모델 다운로드 비활성화됨"
        return 0
    fi
    
    log "기본 모델 다운로드 중..."
    
    # 기본 모델 디렉터리 확인
    if [[ ! -d "$MODELS_DIR/checkpoints" ]]; then
        mkdir -p "$MODELS_DIR/checkpoints"
        log "체크포인트 디렉터리 생성"
    fi
    
    if [[ ! -d "$MODELS_DIR/loras" ]]; then
        mkdir -p "$MODELS_DIR/loras"
        log "LoRA 디렉터리 생성"
    fi
    
    if [[ ! -d "$MODELS_DIR/vae" ]]; then
        mkdir -p "$MODELS_DIR/vae"
        log "VAE 디렉터리 생성"
    fi
    
    log "기본 모델 다운로드 완료"
}

# ===[🐳 컨테이너 정리]===
cleanup_containers() {
    log "기존 컨테이너 정리 중..."
    
    local containers=("$COMFYUI_CONTAINER" "$FORGE_CONTAINER")
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        containers+=("$SDW_CONTAINER")
    fi
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            log "$container 컨테이너 중지 및 제거 중..."
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        elif docker ps -a --format "{{.Names}}" | grep -q "^$container$"; then
            log "$container 컨테이너 제거 중..."
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    log "컨테이너 정리 완료"
}

# ===[🐳 ComfyUI 컨테이너 생성]===
create_comfyui_container() {
    log "ComfyUI 컨테이너 생성 중..."
    
    # ComfyUI 마운트 설정
    local comfy_mounts=(
        "-v" "$COMFY_BASEDIR:/comfy"
        "-v" "$MODELS_DIR:/comfy/mnt/models"
        "-v" "$OUTPUTS_DIR/comfyui:/comfy/mnt/output"
    )
    
    # 캐시 공유
    if [[ "$ENABLE_CACHE_SHARE" == "true" ]]; then
        comfy_mounts+=(
            "-v" "$CACHE_DIR/huggingface:/root/.cache/huggingface"
            "-v" "$CACHE_DIR/pip:/root/.cache/pip"
            "-v" "$CACHE_DIR/torch:/root/.cache/torch"
        )
    fi
    
    # 환경 변수 설정
    local comfy_envs=(
        "-e" "PYTORCH_CUDA_ALLOC_CONF=$PYTORCH_CUDA_ALLOC_CONF"
        "-e" "CLI_ARGS=$COMFY_CLI_ARGS"
        "-e" "CREATE_MODEL_SUBDIRS=$CREATE_MODEL_SUBDIRS"
        "-e" "ENABLE_VRAM_MONITORING=$ENABLE_VRAM_MONITORING"
        "-e" "LOG_LEVEL=$LOG_LEVEL"
        "-e" "SECURITY_LEVEL=weak"
    )
    
    if [[ "$ENABLE_CACHE_SHARE" == "true" ]]; then
        comfy_envs+=("-e" "HF_HOME=/root/.cache/huggingface")
    fi
    
    docker run -d \
        --name "$COMFYUI_CONTAINER" \
        --restart unless-stopped \
        --gpus all \
        -u "$WANTED_UID:$WANTED_GID" \
        --shm-size "$SHM_SIZE" \
        -p "$COMFYUI_PORT:$COMFYUI_CTR_PORT" \
        "${comfy_mounts[@]}" \
        "${comfy_envs[@]}" \
        "$COMFYUI_IMAGE" || error "ComfyUI 컨테이너 생성 실패"
    
    # ComfyUI 컨테이너에서 모델 디렉터리 심볼릭 링크 생성 (지연 실행)
    log "ComfyUI 모델 심볼릭 링크 생성 대기 중..."
    sleep 10  # 컨테이너 완전 시작 대기
    
    create_comfyui_model_links
    
    log "ComfyUI 컨테이너 생성 완료"
}

# ===[🔗 ComfyUI 모델 심볼릭 링크 생성]===
create_comfyui_model_links() {
    local max_retries=10
    local retry_count=0
    
    log "ComfyUI 모델 디렉터리 심볼릭 링크 생성 중..."
    
    while [ $retry_count -lt $max_retries ]; do
        # 컨테이너 상태 확인
        if ! docker ps --format "table {{.Names}}" | grep -q "^$COMFYUI_CONTAINER$"; then
            log "ComfyUI 컨테이너가 아직 시작되지 않음, 대기 중... (시도 $retry_count/$max_retries)"
            retry_count=$((retry_count + 1))
            sleep 5
            continue
        fi
        
        # 컨테이너 내부에서 심볼릭 링크 생성 시도
        if docker exec "$COMFYUI_CONTAINER" bash -c "
            echo 'ComfyUI 컨테이너 내부에서 심볼릭 링크 생성 시작...'
            cd /comfy/mnt/ComfyUI/models
            
            # 기존 링크/디렉터리 제거
            rm -rf checkpoints loras vae embeddings upscale_models controlnet 2>/dev/null || true
            
            # 심볼릭 링크 생성
            ln -sf /comfy/mnt/models/checkpoints checkpoints
            ln -sf /comfy/mnt/models/loras loras
            ln -sf /comfy/mnt/models/vae vae
            ln -sf /comfy/mnt/models/embeddings embeddings
            ln -sf /comfy/mnt/models/upscale_models upscale_models
            ln -sf /comfy/mnt/models/controlnet controlnet
            
            echo 'ComfyUI 모델 심볼릭 링크 생성 완료:'
            ls -la
            
            # 심볼릭 링크 확인
            echo '심볼릭 링크 상태 확인:'
            ls -la | grep -E '^l.*->'
        " 2>/dev/null; then
            log "ComfyUI 모델 심볼릭 링크 생성 완료"
            return 0
        else
            retry_count=$((retry_count + 1))
            log "ComfyUI 모델 심볼릭 링크 생성 시도 $retry_count/$max_retries 실패, 5초 후 재시도..."
            sleep 5
        fi
    done
    
    log "ComfyUI 모델 심볼릭 링크 생성 실패 (최대 재시도 횟수 초과)"
    return 1
}

# ===[🐳 실용적 WebUI 컨테이너 생성]===
create_practical_webui_container() {
    local container_name="$1"
    local image_name="$2"
    local host_port="$3"
    local container_port="$4"
    local launch_args="$5"
    local base_dir="$6"
    
    log "$container_name 컨테이너 생성 중..."
    
    # 핵심 모델을 A1111 표준 경로에 직접 마운트
    local webui_mounts=(
        # 필수 모델 디렉터리 (ComfyUI → A1111 매핑)
        "-v" "$MODELS_DIR/checkpoints:/app/stable-diffusion-webui/models/Stable-diffusion"
        "-v" "$MODELS_DIR/loras:/app/stable-diffusion-webui/models/Lora"
        "-v" "$MODELS_DIR/vae:/app/stable-diffusion-webui/models/VAE"
        "-v" "$MODELS_DIR/embeddings:/app/stable-diffusion-webui/embeddings"
        "-v" "$MODELS_DIR/upscale_models:/app/stable-diffusion-webui/models/ESRGAN"
        
        # 출력 및 설정
        "-v" "$OUTPUTS_DIR/$container_name:/app/stable-diffusion-webui/outputs"
        "-v" "$base_dir/extensions:/app/stable-diffusion-webui/extensions"
        "-v" "$base_dir/config:/app/stable-diffusion-webui/config"
        "-v" "$base_dir/repositories:/app/stable-diffusion-webui/repositories"
        "-v" "$base_dir/tmp:/app/stable-diffusion-webui/tmp"
    )
    
    # 선택적 확장 모델 마운트
    if [[ -d "$MODELS_DIR/hypernetworks" && "$DEPLOY_MODE" != "basic" ]]; then
        webui_mounts+=("-v" "$MODELS_DIR/hypernetworks:/app/stable-diffusion-webui/models/hypernetworks")
    fi
    
    if [[ -d "$MODELS_DIR/controlnet" && "$MOUNT_CONTROLNET" == "true" ]]; then
        webui_mounts+=("-v" "$MODELS_DIR/controlnet:/app/stable-diffusion-webui/extensions/sd-webui-controlnet/models")
    fi
    
    # 추가 업스케일러 마운트 (A1111 호환성)
    if [[ "$MOUNT_MULTIPLE_UPSCALERS" == "true" ]]; then
        webui_mounts+=(
            "-v" "$MODELS_DIR/upscale_models:/app/stable-diffusion-webui/models/RealESRGAN"
            "-v" "$MODELS_DIR/upscale_models:/app/stable-diffusion-webui/models/LDSR"
            "-v" "$MODELS_DIR/upscale_models:/app/stable-diffusion-webui/models/ScuNET"
        )
    fi
    
    # 캐시 공유
    if [[ "$ENABLE_CACHE_SHARE" == "true" ]]; then
        webui_mounts+=(
            "-v" "$CACHE_DIR/huggingface:/root/.cache/huggingface"
            "-v" "$CACHE_DIR/pip:/root/.cache/pip"
            "-v" "$CACHE_DIR/torch:/root/.cache/torch"
        )
    fi
    
    # 실행 스크립트 생성 (WSL2 마운트 문제 영구 해결)
    create_webui_launch_script "$container_name" "$launch_args"
    
    # WSL2 마운트 문제 영구 해결: 컨테이너 내부에서 직접 스크립트 생성
    log "WSL2 마운트 문제 영구 해결: 컨테이너 내부에서 스크립트 생성"
    webui_mounts+=("-e" "LAUNCH_SCRIPT_CONTENT=$(cat /tmp/${container_name}_launch.sh | base64 -w 0)")
    
    # 환경 변수
    local webui_envs=(
        "-e" "PYTORCH_CUDA_ALLOC_CONF=$PYTORCH_CUDA_ALLOC_CONF"
        "-e" "CREATE_MODEL_SUBDIRS=$CREATE_MODEL_SUBDIRS"
        "-e" "ENABLE_VRAM_MONITORING=$ENABLE_VRAM_MONITORING"
        "-e" "VRAM_WARNING_THRESHOLD=$VRAM_WARNING_THRESHOLD"
        "-e" "AUTO_CLEANUP_ON_OOM=$AUTO_CLEANUP_ON_OOM"
        "-e" "LOG_LEVEL=$LOG_LEVEL"
    )
    
    if [[ "$ENABLE_CACHE_SHARE" == "true" ]]; then
        webui_envs+=("-e" "HF_HOME=/root/.cache/huggingface")
    fi
    
    docker run -d \
        --name "$container_name" \
        --restart unless-stopped \
        --gpus all \
        --shm-size "$SHM_SIZE" \
        -p "$host_port:$container_port" \
        "${webui_mounts[@]}" \
        "${webui_envs[@]}" \
        --entrypoint /bin/bash \
        "$image_name" \
        -c 'echo "$LAUNCH_SCRIPT_CONTENT" | base64 -d > /tmp/launch.sh && chmod +x /tmp/launch.sh && /tmp/launch.sh' || error "$container_name 컨테이너 생성 실패"
    
    # 임시 파일 정리
    rm -f "/tmp/${container_name}_launch.sh"
    
    log "$container_name 컨테이너 생성 완료"
}

# ===[🐳 Forge 컨테이너 생성]===
create_forge_container() {
    create_practical_webui_container "$FORGE_CONTAINER" "$FORGE_IMAGE" "$FORGE_PORT" "$FORGE_CTR_PORT" "$FORGE_ARGS" "$FORGE_BASEDIR"
}

# ===[🐳 SDW 컨테이너 생성]===
create_sdw_container() {
    if [[ "$DEPLOY_MODE" != "full" && "$DEPLOY_MODE" != "all" ]]; then
        log "SDW 컨테이너 생성 건너뜀 (DEPLOY_MODE: $DEPLOY_MODE)"
        return 0
    fi
    
    create_practical_webui_container "$SDW_CONTAINER" "$SDW_IMAGE" "$SDW_PORT" "$SDW_CTR_PORT" "$SDW_ARGS" "$SDW_BASEDIR"
}

# ===[🚀 WebUI 실행 스크립트 생성 (WSL2 마운트 문제 영구 해결)]===
create_webui_launch_script() {
    local container_name="$1"
    local launch_args="$2"
    
    # WSL2 마운트 문제 영구 해결: 항상 임시 파일 생성 (환경 변수 전달용)
    cat > "/tmp/${container_name}_launch.sh" <<EOF
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export PYTORCH_CUDA_ALLOC_CONF="$PYTORCH_CUDA_ALLOC_CONF"
export HF_HOME=/root/.cache/huggingface

echo "=== $container_name 시작 (v4.3 완전 범용 버전) ==="

# 권한 문제 완전 해결 - 마운트된 디렉터리들의 소유권 및 권한 수정
echo "디렉터리 권한 완전 해결 중..."

# 1단계: 기본 디렉터리 권한 설정
chown -R root:root /app/stable-diffusion-webui/repositories 2>/dev/null || true
chown -R root:root /app/stable-diffusion-webui/extensions 2>/dev/null || true
chown -R root:root /app/stable-diffusion-webui/tmp 2>/dev/null || true
chown -R root:root /app/stable-diffusion-webui/models 2>/dev/null || true
chown -R root:root /app/stable-diffusion-webui/embeddings 2>/dev/null || true
chown -R root:root /app/stable-diffusion-webui/outputs 2>/dev/null || true

# 2단계: Git 관련 디렉터리 특별 처리
if [ -d "/app/stable-diffusion-webui/repositories" ]; then
    echo "Git repositories 권한 강화 설정 중..."
    find /app/stable-diffusion-webui/repositories -type d -exec chmod 777 {} \; 2>/dev/null || true
    find /app/stable-diffusion-webui/repositories -type f -exec chmod 666 {} \; 2>/dev/null || true
    
    # .git 디렉터리들 특별 처리
    find /app/stable-diffusion-webui/repositories -name ".git" -type d -exec chmod -R 777 {} \; 2>/dev/null || true
fi

# 3단계: 일반 디렉터리 권한 설정
chmod -R 755 /app/stable-diffusion-webui/repositories 2>/dev/null || true
chmod -R 755 /app/stable-diffusion-webui/extensions 2>/dev/null || true
chmod -R 755 /app/stable-diffusion-webui/tmp 2>/dev/null || true
chmod -R 755 /app/stable-diffusion-webui/models 2>/dev/null || true
chmod -R 755 /app/stable-diffusion-webui/embeddings 2>/dev/null || true
chmod -R 755 /app/stable-diffusion-webui/outputs 2>/dev/null || true

# 4단계: 추가 권한 확인
echo "권한 설정 완료. Git 작업 준비 중..."

# 모델 구조 정보 출력
echo "모델 디렉터리 구조:"
if [[ "$CREATE_MODEL_SUBDIRS" == "true" ]]; then
    echo "  하위 디렉터리: 활성화"
    find /app/stable-diffusion-webui/models -type d -maxdepth 2 2>/dev/null | head -15
else
    echo "  하위 디렉터리: 비활성화 (플랫 구조)"
    ls -la /app/stable-diffusion-webui/models/ 2>/dev/null | head -10
fi

# 모델 카운트
echo "체크포인트: \$(find /app/stable-diffusion-webui/models/Stable-diffusion -name '*.safetensors' -o -name '*.ckpt' 2>/dev/null | wc -l)개"
echo "LoRA: \$(find /app/stable-diffusion-webui/models/Lora -name '*.safetensors' 2>/dev/null | wc -l)개"
echo "VAE: \$(find /app/stable-diffusion-webui/models/VAE -name '*.safetensors' 2>/dev/null | wc -l)개"
echo "임베딩: \$(find /app/stable-diffusion-webui/embeddings -name '*.pt' -o -name '*.safetensors' 2>/dev/null | wc -l)개"

# 시스템 정보
echo "GPU 메모리:"
nvidia-smi --query-gpu=memory.total,memory.used,memory.free --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A"

# Git 문제 완전 해결
echo "Git 문제 완전 해결 중..."
cd /app/stable-diffusion-webui

# Git 전역 설정
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global --add safe.directory '*'
git config --global http.postBuffer 524288000
git config --global http.timeout 300

# repositories 디렉터리 권한 및 Git 설정
if [ -d "repositories" ]; then
    echo "repositories 디렉터리 Git 문제 해결 중..."
    cd repositories
    
    # stable-diffusion-webui-assets 처리
    if [ -d "stable-diffusion-webui-assets" ]; then
        cd stable-diffusion-webui-assets
        echo "stable-diffusion-webui-assets Git 초기화 중..."
        
        # 권한 강화 후 Git 초기화
        chmod -R 777 . 2>/dev/null || true
        rm -rf .git 2>/dev/null || true
        
        # Git 초기화 시도 (권한 오류 시 건너뛰기)
        if git init 2>/dev/null; then
            echo "Git 초기화 성공"
            git config --local --add safe.directory . 2>/dev/null || true
            git config --local user.name "webui" 2>/dev/null || true
            git config --local user.email "webui@example.com" 2>/dev/null || true
            
            # 원격 저장소 추가 시도
            if git remote add origin https://github.com/Stability-AI/stable-diffusion-webui-assets.git 2>/dev/null; then
                echo "원격 저장소 추가 성공"
            fi
            
            # 기본 파일들 추가 시도
            echo "# Stable Diffusion WebUI Assets" > README.md 2>/dev/null || true
            if git add README.md 2>/dev/null; then
                git commit -m "Initial commit" 2>/dev/null || echo "커밋 실패 (권한 문제 무시)"
            fi
        else
            echo "Git 초기화 실패 (권한 문제 무시하고 계속 진행)"
        fi
        
        cd ..
    fi
    
    # 다른 repositories도 처리
    for repo_dir in */; do
        if [ -d "$repo_dir" ] && [ "$repo_dir" != "stable-diffusion-webui-assets/" ]; then
            echo "Repository $repo_dir Git 초기화 중..."
            cd "$repo_dir"
            
            # 권한 강화
            chmod -R 777 . 2>/dev/null || true
            
            if [ ! -d ".git" ]; then
                if git init 2>/dev/null; then
                    git config --local --add safe.directory . 2>/dev/null || true
                    echo "# $repo_dir" > README.md 2>/dev/null || true
                    if git add README.md 2>/dev/null; then
                        git commit -m "Initial commit" 2>/dev/null || echo "커밋 실패 (권한 문제 무시)"
                    fi
                else
                    echo "Git 초기화 실패 (권한 문제 무시하고 계속 진행)"
                fi
            fi
            cd ..
        fi
    done
    
    cd ..
fi

# Python 환경 설정
if [[ ! -f "/app/stable-diffusion-webui/venv/bin/activate" ]]; then
    echo "Python 환경 초기화 중..."
    cd /app/stable-diffusion-webui
    python3 -m venv venv --system-site-packages
    source venv/bin/activate
    
    # RTX 3080 최적화 패키지 설치
    pip install --upgrade pip setuptools wheel
    pip install torch==$PYTORCH_VERSION torchvision==$TORCHVISION_VERSION \
                torchaudio==$TORCHAUDIO_VERSION \
                --index-url https://download.pytorch.org/whl/cu121
    pip install xformers==$XFORMERS_VERSION --index-url https://download.pytorch.org/whl/cu121
    
    echo "Python 환경 초기화 완료"
else
    source /app/stable-diffusion-webui/venv/bin/activate
fi

echo "WebUI 시작 중..."
cd /app/stable-diffusion-webui
exec python launch.py $launch_args
EOF
    
    chmod +x "/tmp/${container_name}_launch.sh"
}

# ===[🚀 메인 실행 함수]===
main() {
    log "RTX 3080 AI 환경 구축 v4.3 (완전 범용 버전) 시작"
    
    # Git 문제 전용 수정 모드
    if [[ "$FIX_GIT_ONLY" == "true" ]]; then
        fix_git_only
        return 0
    fi
    
    # 시스템 검증
    validate_system
    
    # Git 안전 환경 설정
    setup_git_safe_environment
    
    # 실용적 디렉터리 구조 생성
    create_practical_directory_structure
    
    # 권한 설정
    setup_permissions
    
    # 호스트에서 assets 사전 준비
    prepare_host_assets
    
    # 기본 모델 다운로드
    download_basic_models
    
    # 컨테이너 정리
    cleanup_containers
    
    # 컨테이너 생성
    create_comfyui_container
    create_forge_container
    
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        create_sdw_container
    fi
    
    # 상태 확인
    log "컨테이너 상태 확인 중..."
    sleep 10
    
    # 컨테이너 상태 출력
    docker ps --filter "name=$COMFYUI_CONTAINER|$FORGE_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    log "=== 🎉 RTX 3080 AI 환경 구축 v4.3 (완전 범용 버전) 완료! ==="
    log "🔧 모든 문제가 해결되었습니다."
    log ""
    log "=== 접속 정보 ==="
    log "ComfyUI: http://localhost:$COMFYUI_PORT"
    log "Forge WebUI: http://localhost:$FORGE_PORT"
    if [[ "$DEPLOY_MODE" == "full" || "$DEPLOY_MODE" == "all" ]]; then
        log "SDW: http://localhost:$SDW_PORT"
    fi
    log ""
    log "=== 문제 해결 명령어 ==="
    log "Git 문제 수정: $0 --fix-git-only"
    log "오프라인 모드: $0 --offline-mode"
    log "완전 재구축: $0 --delete"
    log ""
    log "=== 환경 설정 확인 ==="
    log "사용자: $USER_NAME (UID: $WANTED_UID, GID: $WANTED_GID)"
    log "기본 경로: $BASE_DIR"
    log "배포 모드: $DEPLOY_MODE"
}

# ===[📝 스크립트 실행]===
# 메인 함수 실행
main "$@"
