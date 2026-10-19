# CONFIG (autopilot 통합 정책)

사람이 정하는 파일이다. autopilot은 읽기만 하고 바꾸지 않는다.
이 레포는 CLAUDE.md의 git flow를 따른다 (feature/* → develop PR 머지, release/* → main, main → develop 역병합).

```
integration: pr
base_branch: develop
branch_prefix: feature/
merge: auto
release: auto
```
