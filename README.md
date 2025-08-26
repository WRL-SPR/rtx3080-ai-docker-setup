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
# 메모리 제한 (GB 단위)
MEMORY_LIMIT=16g
# CPU 코어 제한
CPU_LIMIT=8
# Shared memory 크기
SHM_SIZE=8g
```

### UID/GID 설정 방법

#### 1. 현재 사용자의 UID/GID 확인
```bash
# 현재 사용자 정보 확인
id
# 출력 예: uid=1000(username) gid=1000(username) groups=1000(username),4(adm),24(cdrom)...

# UID만 확인
id -u

# GID만 확인
id -g
```

#### 2. UID/GID 1024로 설정하는 방법
```bash
# 새 사용자 생성 (시스템 관리자 권한 필요)
sudo useradd -u 1024 -g 1024 -m -s /bin/bash aiuser

# 기존 사용자 UID/GID 변경 (주의: 데이터 손실 가능)
sudo usermod -u 1024 existing_username
sudo groupmod -g 1024 existing_groupname

# 파일 소유권 일괄 변경
sudo find /home/existing_username -user old_uid -exec chown 1024:1024 {} \;
```

#### 3. Docker 컨테이너에서 사용자 매핑
```bash
# docker-compose.yml에서 user 설정 예시
services:
  ai-container:
    user: "1024:1024"
    # 또는 환경변수 사용
    user: "${UID}:${GID}"
```

### 환경 변수 상세 설명

#### 🐳 Docker & 컨테이너 설정
- **CONTAINER_NAME**: 컨테이너 식별명 (영문, 숫자, 하이픈만 사용)
- **포트 설정**: 호스트:컨테이너 포트 매핑 (충돌 방지를 위해 8000번대 이상 권장)

#### 👤 사용자 권한 설정
- **UID/GID**: Linux 사용자/그룹 ID (1024 권장, root 권한 방지)
- **USER_NAME**: 컨테이너 내 사용자명 (영문 소문자, 언더스코어만 사용)

#### 🖥️ GPU 설정
- **GPU_DEVICE_ID**: 사용할 GPU 번호 (nvidia-smi로 확인)
- **CUDA_VERSION**: CUDA 버전 (11.8 또는 12.x 권장)
- **CUDNN_VERSION**: cuDNN 버전 (CUDA와 호환되는 버전)

#### 📁 데이터 경로 설정
- **절대 경로 사용 필수**: 상대 경로 사용 시 마운트 오류 발생
- **디렉토리 존재 확인**: Docker 실행 전 경로 생성 필요
- **권한 설정**: 777 권한은 보안상 위험, 755 권장

### 보안 및 권한 관련 주의사항

#### 🔒 보안 베스트 프랙티스

1. **API 키 보안**
   ```bash
   # .env 파일 권한 설정 (소유자만 읽기/쓰기)
   chmod 600 .env
   
   # Git에서 .env 파일 제외
   echo ".env" >> .gitignore
   ```

2. **Root 권한 방지**
   ```bash
   # ❌ 위험: root 사용자로 실행
   docker run --user root ...
   
   # ✅ 안전: 일반 사용자로 실행
   docker run --user 1024:1024 ...
   ```

3. **네트워크 보안**
   ```bash
   # 특정 인터페이스에만 바인딩
   ports:
     - "127.0.0.1:8888:8888"  # localhost만 접근 가능
   ```

#### 📋 권한 설정 체크리스트

- [ ] UID/GID가 1000 이상인지 확인 (시스템 사용자 충돌 방지)
- [ ] 데이터 디렉토리 권한이 올바른지 확인 (755 또는 775)
- [ ] .env 파일 권한이 600으로 설정되어 있는지 확인
- [ ] Docker 그룹에 사용자가 추가되어 있는지 확인
- [ ] SELinux/AppArmor 정책이 Docker 실행을 허용하는지 확인

#### 🐧 Linux 환경 권장 설정

1. **Docker 그룹 설정**
   ```bash
   # Docker 그룹에 사용자 추가
   sudo usermod -aG docker $USER
   
   # 로그아웃 후 재로그인 또는
   newgrp docker
   ```

2. **시스템 리소스 제한**
   ```bash
   # /etc/security/limits.conf에 추가
   username soft nofile 65536
   username hard nofile 65536
   username soft nproc 32768
   username hard nproc 32768
   ```

3. **방화벽 설정**
   ```bash
   # UFW 사용시 Docker 포트 허용
   sudo ufw allow from 127.0.0.1 to any port 8888
   sudo ufw allow from 192.168.0.0/16 to any port 8888
   ```

#### 🔧 자주 발생하는 문제 해결

1. **권한 거부 오류**
   ```bash
   # 원인: UID/GID 불일치
   # 해결: 파일 소유권 변경
   sudo chown -R 1024:1024 /path/to/data
   ```

2. **포트 충돌**
   ```bash
   # 사용 중인 포트 확인
   sudo netstat -tulpn | grep :8888
   
   # 프로세스 종료
   sudo kill -9 PID
   ```

3. **GPU 인식 실패**
   ```bash
   # NVIDIA Container Toolkit 설치 확인
   nvidia-container-cli --version
   
   # Docker에서 GPU 테스트
   docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
   ```

#### 💡 성능 최적화 팁

1. **메모리 설정**
   ```yaml
   # docker-compose.yml 메모리 제한
   mem_limit: 16g
   memswap_limit: 16g
   ```

2. **디스크 I/O 최적화**
   ```bash
   # SSD에 데이터 저장
   # tmpfs 사용으로 임시 파일 성능 향상
   tmpfs:
     - /tmp:size=2G
   ```

3. **CPU 친화성 설정**
   ```yaml
   cpuset: "0-7"  # CPU 코어 0-7 사용
   ```

---

## 환경 설정

### 필수 요구사항
- NVIDIA RTX 3080
- Docker
- NVIDIA Container Toolkit

### v4.2 주요 변경사항
- 환경설정 가이드 업데이트
- Git 저장소 설정 문제 해결
- Docker 컨테이너 최적화

### 설치 가이드
1. Docker 설치
2. NVIDIA Container Toolkit 설치
3. 저장소 클론
4. 컨테이너 빌드 및 실행

### Git 문제 해결
공통적인 Git 설정 문제들과 해결 방법을 포함하였습니다.

### 지원
문의사항이 있으시면 이슈를 생성해주세요.
