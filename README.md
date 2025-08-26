# 🚀 RTX 3080 AI Docker 환경 구축 스크립트 v4.3

> **완벽한 문제 해결과 실용적 모델 공유를 위한 AI 환경 구축 도구**

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-76B900?style=for-the-badge&logo=nvidia&logoColor=white)](https://www.nvidia.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](LICENSE)

## 📋 목차

- [✨ 주요 기능](#-주요-기능)
- [🔧 해결된 문제들](#-해결된-문제들)
- [🚀 빠른 시작](#-빠른-시작)
- [📁 프로젝트 구조](#-프로젝트-구조)
- [⚙️ 환경 설정](#️-환경-설정)
- [📖 사용법](#-사용법)
- [🔍 문제 해결](#-문제-해결)
- [📝 변경 이력](#-변경-이력)
- [🤝 기여하기](#-기여하기)
- [📄 라이선스](#-라이선스)

## ✨ 주요 기능

### 🎯 **완벽한 문제 해결**
- ✅ **Git 문제**: `fatal: not a git repository`, `dubious ownership` 완전 해결
- ✅ **권한 문제**: `Permission denied`, `could not lock config file` 완전 해결
- ✅ **WSL2 마운트 문제**: `error mounting` 영구 해결
- ✅ **확장 설치 후 재시작 마운트 문제**: 완벽 해결

### 🐳 **Docker 컨테이너 관리**
- **ComfyUI**: 최신 ComfyUI Docker 이미지 지원
- **Forge WebUI**: 안정적인 Forge 기반 Stable Diffusion WebUI
- **SDW**: 기본 Stable Diffusion WebUI (full 모드)
- **모델 공유**: 모든 컨테이너 간 실시간 모델 공유

### 🚀 **RTX 3080 최적화**
- **PyTorch 2.3.1+cu121**: 최신 CUDA 12.1 지원
- **xFormers 0.0.26.post1**: 메모리 효율성 극대화
- **CUDA 할당 최적화**: `max_split_size_mb:512` 설정
- **VRAM 모니터링**: 실시간 GPU 메모리 상태 확인

### 🔗 **실용적 모델 공유**
- **통합 모델 디렉터리**: ComfyUI와 WebUI 간 자동 동기화
- **심볼릭 링크**: 컨테이너 내부 자동 생성
- **캐시 공유**: HuggingFace, PyTorch 캐시 공유
- **권한 관리**: 자동 권한 설정 및 복구

## 🔧 해결된 문제들

| 문제 유형 | 해결 방법 | 상태 |
|-----------|-----------|------|
| **Git 저장소 오류** | `git config --global --add safe.directory *` + 자동 초기화 | ✅ 완료 |
| **권한 거부 오류** | 4단계 권한 설정 시스템 + 재시도 로직 | ✅ 완료 |
| **WSL2 마운트 오류** | 환경 변수 기반 스크립트 전달 + 컨테이너 내부 생성 | ✅ 완료 |
| **모델 공유 문제** | 자동 심볼릭 링크 생성 + 실시간 동기화 | ✅ 완료 |
| **확장 설치 후 재시작** | 마운트 포인트 자동 복구 + 권한 재설정 | ✅ 완료 |

## 🚀 빠른 시작

### 📋 **사전 요구사항**

```bash
# Ubuntu 20.04+ / WSL2
# Docker Desktop 4.0+
# NVIDIA GPU + CUDA 12.1 지원 드라이버
# 최소 16GB RAM, 50GB 여유 공간
```

### ⚡ **1분 설치**

```bash
# 저장소 클론
git clone https://github.com/yourusername/rtx3080-ai-docker.git
cd rtx3080-ai-docker

# 실행 권한 부여
chmod +x setup_ai_env_full.sh

# 기본 환경 구축
./setup_ai_env_full.sh --delete --force-recreate --no-models
```

**🔧 개인 설정 (필수):**
```bash
# 1. .env 파일 생성 및 수정
cp .env.example .env
nano .env  # 또는 선호하는 에디터

# 2. 다음 항목들을 실제 값으로 수정:
# - USER_NAME: 실제 호스트 사용자명
# - WANTED_UID: 실제 호스트 UID (id -u 명령어로 확인)
# - WANTED_GID: 실제 호스트 GID (id -g 명령어로 확인)
# - BASE_DIR: 실제 프로젝트 경로
```

### 🌐 **접속 정보**

```
ComfyUI: http://localhost:8181
Forge WebUI: http://localhost:8182
SDW: http://localhost:8183 (full 모드)
```

## 📁 프로젝트 구조

```
rtx3080-ai-docker/
├── 📄 setup_ai_env_full.sh          # 메인 스크립트 (v4.3)
├── 📄 .env.example                  # 환경 변수 템플릿
├── 📄 README.md                     # 이 파일
├── 📁 shared/                       # 데이터 공유 디렉터리
│   ├── 📁 models/                   # AI 모델 (공유)
│   ├── 📁 outputs/                  # 생성된 결과물
│   └── 📁 cache/                    # 캐시 공유
├── 📁 comfyui/                      # ComfyUI 전용 데이터
├── 📁 forge/                        # Forge WebUI 전용 데이터
└── 📁 sdw/                          # SDW 전용 데이터
```

## ⚙️ 환경 설정

### 🔧 **기본 환경 변수**

```bash
# ===[👤 사용자 권한 설정]===
USER_NAME=aiuser              # 컨테이너 사용자명 (호스트와 동일하게 설정)
WANTED_UID=1000              # UID (1000 이상 권장, 호스트 UID와 일치)
WANTED_GID=1000              # GID (호스트 GID와 일치)

# ===[📁 경로 설정]===
BASE_DIR=/home/aiuser/ai-project/shared    # 프로젝트 루트 디렉터리
MODELS_DIR=${BASE_DIR}/common/models       # AI 모델 저장소
OUTPUTS_DIR=${BASE_DIR}/common/outputs     # 생성된 결과물 저장소

# ===[🐳 Docker 설정]===
COMFYUI_IMAGE=mmartial/comfyui-nvidia-docker:latest
FORGE_IMAGE=nykk3/stable-diffusion-webui-forge:latest
SDW_IMAGE=siutin/stable-diffusion-webui-docker:latest-cuda
```

**📝 사용자별 설정 가이드:**
```bash
# 1단계: 호스트 사용자 정보 확인
id -u    # UID 확인
id -g    # GID 확인
whoami   # 사용자명 확인

# 2단계: .env 파일에서 경로 수정
# BASE_DIR을 실제 프로젝트 경로로 변경
# 예: /home/yourname/my-ai-project/shared

# 3단계: 디렉터리 생성
mkdir -p /home/yourname/my-ai-project/shared/{common/{models,outputs},cache,comfyui,forge,sdw}
```

### 🚀 **RTX 3080 최적화 설정**

```bash
# ===[🎯 RTX 3080 최적화]===
ENABLE_RTX3080_OPTIMIZATION=true
PYTORCH_VERSION=2.3.1+cu121
XFORMERS_VERSION=0.0.26.post1
PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512,garbage_collection_threshold:0.6,expandable_segments:True"
SHM_SIZE=4g
```

### 🔒 **보안 설정**

```bash
# ===[🔒 보안 설정]===
ALLOW_EXTERNAL_ACCESS=false    # 외부 접근 제한
LOG_LEVEL=INFO                 # 로그 레벨
ENABLE_VRAM_MONITORING=true    # VRAM 모니터링
```

## 📖 사용법

### 🎯 **기본 실행**

```bash
# 완전한 AI 환경 구축
./setup_ai_env_full.sh --delete --force-recreate --no-models

# Git 문제만 수정 (기존 컨테이너 유지)
./setup_ai_env_full.sh --fix-git-only

# 오프라인 모드 (Git 클론 건너뛰기)
./setup_ai_env_full.sh --offline-mode
```

### 🔧 **고급 옵션**

```bash
# 모델 하위 디렉터리 생성 (카테고리별 정리)
./setup_ai_env_full.sh --create-subdirs

# 플랫 구조 유지 (기본값)
./setup_ai_env_full.sh --flat-structure

# 완전 재구축
./setup_ai_env_full.sh --delete
```

### 📊 **상태 확인**

```bash
# 컨테이너 상태 확인
docker ps --filter "name=comfyui|forge|sdw"

# 로그 확인
docker logs comfyui
docker logs forge
docker logs sdw
```

## 🔍 문제 해결

### ❌ **일반적인 문제들**

#### **1. Git 저장소 오류**
```bash
# 자동 해결 (권장)
./setup_ai_env_full.sh --fix-git-only

# 수동 해결
docker exec comfyui git config --global --add safe.directory '*'
```

#### **2. 권한 문제**
```bash
# 호스트에서 권한 수정 (실제 경로로 변경)
sudo chown -R 1000:1000 /home/aiuser/ai-project/shared
sudo chmod -R 755 /home/aiuser/ai-project/shared
```

#### **3. WSL2 마운트 문제**
```bash
# 자동 해결됨 (v4.3에서 영구 해결)
# 추가 설정 불필요
```

#### **4. 모델 공유 문제**
```bash
# ComfyUI 컨테이너에서 수동 생성
docker exec comfyui bash -c "
cd /comfy/mnt/ComfyUI/models
ln -sf /comfy/mnt/models/checkpoints checkpoints
ln -sf /comfy/mnt/models/loras loras
ln -sf /comfy/mnt/models/vae vae
"
```

### 📋 **문제 해결 체크리스트**

- [ ] Docker Desktop이 실행 중인가?
- [ ] NVIDIA 드라이버가 최신인가?
- [ ] 호스트 디렉터리 권한이 올바른가?
- [ ] 포트가 다른 서비스와 충돌하지 않는가?
- [ ] 충분한 디스크 공간이 있는가?

## 📝 변경 이력

### **v4.3 (2024-08-26) - 문제 해결 강화**
- ✅ **Git 문제 완전 해결**: `safe.directory` 설정 + 자동 초기화
- ✅ **권한 문제 완전 해결**: 4단계 권한 설정 시스템
- ✅ **WSL2 마운트 문제 영구 해결**: 환경 변수 기반 스크립트 전달
- ✅ **ComfyUI 모델 심볼릭 링크**: 자동 생성 + 재시도 로직
- ✅ **확장 설치 후 재시작 문제**: 마운트 포인트 자동 복구

### **v4.2 (2024-08-26) - Git 문제 해결**
- 🔧 Git 저장소 오류 자동 복구
- 🔧 권한 문제 해결 시스템
- 🔧 네트워크 연결 문제 대응

### **v4.1 (2024-08-26) - 기본 기능**
- 🐳 Docker 컨테이너 자동 생성
- 🔗 모델 공유 시스템
- 🚀 RTX 3080 최적화

### **v4.0 (2024-08-26) - 초기 버전**
- 📁 기본 디렉터리 구조
- 🐳 Docker 이미지 설정
- ⚙️ 환경 변수 기본값

## 🤝 기여하기

### 🔧 **개발 환경 설정**

```bash
# 개발 환경 클론
git clone https://github.com/yourusername/rtx3080-ai-docker.git
cd rtx3080-ai-docker

# 테스트 실행
./setup_ai_env_full.sh --delete --force-recreate --no-models
```

### 📝 **기여 가이드라인**

1. **Fork** 저장소
2. **Feature branch** 생성 (`git checkout -b feature/amazing-feature`)
3. **Commit** 변경사항 (`git commit -m 'Add amazing feature'`)
4. **Push** 브랜치 (`git push origin feature/amazing-feature`)
5. **Pull Request** 생성

### 🐛 **버그 리포트**

- [Issues](https://github.com/yourusername/rtx3080-ai-docker/issues) 페이지에서 버그 리포트
- 상세한 오류 메시지와 재현 단계 포함
- 시스템 정보 (OS, Docker 버전, GPU 모델 등) 제공

## 📄 라이선스

이 프로젝트는 [Mozilla Public License 2.0](LICENSE) 하에 배포됩니다.

**MPL 2.0의 주요 특징:**
- ✅ **소스 코드 공개**: 수정된 소스 코드는 반드시 공개
- ✅ **파일별 라이선스**: 수정된 파일만 MPL 2.0 적용
- ✅ **상업적 사용**: 자유로운 상업적 사용 가능
- ✅ **특허 보호**: 특허 소송으로부터 보호
- ✅ **호환성**: GPL, LGPL 등과 호환

**간단한 요약:**
- 이 스크립트를 수정하여 배포할 때는 **수정된 파일을 공개**해야 합니다
- **새로운 파일**은 자유롭게 라이선스 선택 가능
- **상업적 사용**도 자유롭게 가능합니다

**전체 라이선스 텍스트는 [LICENSE](LICENSE) 파일을 참조하세요.**

## 🙏 감사의 말

- **ComfyUI** 팀: 혁신적인 AI 워크플로우 도구
- **Forge** 팀: 안정적인 Stable Diffusion WebUI
- **Docker** 팀: 컨테이너 기술
- **NVIDIA** 팀: GPU 가속 기술
- **PyTorch** 팀: 딥러닝 프레임워크

---

**⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!**

**🚀 RTX 3080으로 AI의 미래를 만들어가세요!**
