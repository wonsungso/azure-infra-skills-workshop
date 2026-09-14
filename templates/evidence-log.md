# 검증 증거 로그

실제 출력에 token이나 kubeconfig 내용을 넣지 않습니다. subscription·tenant ID와 IP는 가려서 적습니다. 오류는 요약만 남기고 원본 로그 위치를 연결합니다.

[`log-evidence.sh`](../scripts/log-evidence.sh)를 쓰면 시각·도구·명령·결과가 아래 표에 자동으로 추가됩니다. `대상`과 `승인/담당자`는 판단이 필요하므로 사람이 채웁니다.

```bash
bash scripts/log-evidence.sh "Lab 01 Step 4" "az CLI" -- az account show --query name -o tsv
```

| 시각 | 단계 | Skill 또는 도구 | 대상 | 수행 작업 | 실제 결과 | 상태 | 승인/담당자 |
| --- | --- | --- | --- | --- | --- | --- | --- |
