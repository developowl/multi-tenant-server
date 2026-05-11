# %%%%%%%%%%%%%%%%%%%%%%%%%%
# 현재 사용하지 않는 정의 파일입니다.
# %%%%%%%%%%%%%%%%%%%%%%%%%%

#!/bin/bash

# 관리자 설정 변수
NAMESPACE="****"
SSH_NODEPORT=****
PASSWORD="****"
HOSTNAME="****"

echo "관리자 전용 서버 생성 중: $NAMESPACE"

# 1. 네임스페이스 생성
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. 리소스 적용
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: admin-pvc
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
  name: admin-server
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin-server
  template:
    metadata:
      labels:
        app: admin-server
    spec:
      hostname: "$HOSTNAME"
      containers:
      - name: ssh-server
        image: ubuntu:22.04
        command: ["/bin/bash", "-c"]
        ports:
        - containerPort: ****
        - containerPort: $WEB_NODEPORT
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
            cpu: "500m" # 최소 0.5 core 보장
            memory: "2Gi" # 최소 2GB 보장
          limits:
            cpu: "2" # 최대 2 cores (권장 사양)
            memory: "4Gi" # 최대 4GB (권장 사양)
        volumeMounts:
        - name: admin-storage
          mountPath: /home/tenant-user
          subPath: admin-home-data
      volumes:
      - name: admin-storage
        persistentVolumeClaim:
          claimName: admin-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: admin-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  selector:
    app: admin-server
  ports:
  - name: ssh-access
    port: ****
    targetPort: ****
    nodePort: $SSH_NODEPORT
#  - name: web
#    port: ****
#    targetPort: ****
#    nodePort: $WEB_NODEPORT
EOF
