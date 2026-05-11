# %%%%%%%%%%%%%%%%%%%%%%%%%%
# 현재 사용하지 않는 정의 파일입니다.
# %%%%%%%%%%%%%%%%%%%%%%%%%%

#!/bin/bash

for i in {5..10}; do
  NAMESPACE="****"
  SSH_NODEPORT=$((****)) # 기존 SSH 포트 유지
  WEB_NODEPORT=$((****)) # 웹 서비스 포트
  WEB_EXTERNAL_PORT=$((****)) # 실제 외부 포트
  PASSWORD="****" 

  echo "계정 생성 중: $NAMESPACE (Port: $SSH_NODEPORT / WEB: $WEB_NODEPORT  / PW: $PASSWORD)..."

  # 1. 네임스페이스 생성
  kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  # 2. 통합 리소스 적용 (PVC + Deployment + Service)
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tenant-basic-pvc
  namespace: $NAMESPACE
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: "local-path"
  resources:
    requests:
      storage: 8Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-basic-server
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: basic-server
  template:
    metadata:
      labels:
        app: basic-server
    spec:
      hostname: "tenant-basic-$i"
      containers:
      - name: ssh-server
        image: lscr.io/linuxserver/openssh-server:latest
        ports:
        - containerPort: ****
        - containerPort: $WEB_EXTERNAL_PORT
        env:
        - name: PUID
          value: "1000"
        - name: PGID
          value: "1000"
        - name: TZ
          value: "Asia/Seoul"
        - name: USER_NAME
          value: "tenant-user"
        - name: USER_PASSWORD
          value: "$PASSWORD"
        - name: PASSWORD_ACCESS
          value: "true"
        - name: SUDO_ACCESS
          value: "true"
        resources:
          requests:
            cpu: "100m"
            memory: "512Mi"
          limits:
            cpu: "1"
            memory: "1Gi"
        volumeMounts:
        - name: tenant-storage
          mountPath: /config
          subPath: system-config
        - name: tenant-storage
          mountPath: /home/tenant-user
          subPath: tenant-home-data
      volumes:
      - name: tenant-storage
        persistentVolumeClaim:
          claimName: tenant-basic-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: tenant-basic-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  selector:
    app: basic-server
  ports:
  - name: ssh-access
    port: ****
    targetPort: ****
    nodePort: $SSH_NODEPORT
  - name: web
    port: $WEB_EXTERNAL_PORT
    targetPort: $WEB_EXTERNAL_PORT
    nodePort: $WEB_NODEPORT
EOF
done
