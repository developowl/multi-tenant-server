#!/bin/bash
# %%%%%%%%%%%%%%%%%%%%%%%%%%
# 현재 사용하지 않는 정의 파일입니다.
# %%%%%%%%%%%%%%%%%%%%%%%%%%

for i in {1..10}; do
  echo "삭제 중: tenant-basic-$i..."
  kubectl delete namespace tenant-basic-$i --ignore-not-found=true
done
echo "모든 테넌트 삭제 완료."

