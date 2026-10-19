# CONFIG (autopilot 통합 정책)

사람이 정하는 파일이다. autopilot은 읽기만 하고 바꾸지 않는다. 이 파일이 없으면 아래 기본값으로 동작한다.
값을 바꾸면 결과가 레포 밖(원격 브랜치, PR, 릴리스)으로 나가므로 의도를 확인하고 바꿀 것.

```
integration: local      # local | branch | pr
base_branch: auto       # 작업 브랜치의 출발점이자 PR 대상. auto = develop이 있으면 develop, 없으면 원격 기본 브랜치
branch_prefix: auto     # 작업 브랜치 접두어. auto = 레포 관례(CONTRIBUTING 등)에 있으면 그것, 없으면 autopilot/
merge: off              # pr 모드에서: off = PR만 만든다 | auto = 검증 통과 시 직접 머지
release: off            # off | auto = 레포에 문서화된 릴리스 절차가 있을 때 그대로 수행
```

- `local`: 현재 브랜치에 커밋만 한다. push하지 않는다 (기본, 가장 안전)
- `branch`: 작업마다 `<prefix><작업ID>-<slug>` 브랜치를 만들어 커밋하고 push한다. PR은 만들지 않는다
- `pr`: `branch`에 더해 base_branch로 PR을 만든다. `merge: auto`면 검증 통과 후 머지까지 한다
