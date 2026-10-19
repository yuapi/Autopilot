# 릴리스 절차

`scripts/release.sh` 는 **사람이** `main` 브랜치에서 실행한다. 에이전트는 실행하지 않는다.

## 브랜치 흐름 (git flow)

```
feature/<topic> ──PR──▶ develop ──▶ release/<ver> ──▶ main (+ tag v<ver>)
                                         └────────────▶ develop (역병합)
```

## 순서

1. `feature/*` 에서 변경 → `bash scripts/bump.sh <kind> "<요약>"`
2. `bash scripts/validate.sh` → PASS
3. commit → push → PR → `develop` 병합
4. 릴리스 준비: `git checkout -b release/<ver> develop` (필요하면 여기서 마지막 수정·validate)
5. `main` 에 병합: `git checkout main && git merge --no-ff release/<ver> && git push origin main`
6. `develop` 에 역병합: `git checkout develop && git merge --no-ff release/<ver> && git push origin develop`
7. 레포가 **public** 인지 확인 (마켓플레이스 설치·Release 다운로드가 외부에서 되는지)
8. `main` 에서 `bash scripts/release.sh`

`release.sh` 가 하는 일:
1. `main` 브랜치인지 확인
2. `validate.sh` 실행
3. 작업 트리가 깨끗한지 확인
4. 태그 `v<ver>` 가 아직 없는지 확인
5. `dist/autopilot-<ver>.skill` 생성
6. `git tag -a v<ver>` → `git push origin v<ver>`
7. `gh` 가 있으면 CHANGELOG의 해당 섹션을 노트로 `gh release create` + `.skill` 첨부

## gh 가 없을 때

`release.sh` 는 태그 push 까지 하고 안내를 출력한다. 수동으로:

1. GitHub 레포 → **Releases** → **Draft a new release**
2. 태그: `v<ver>` (이미 push 됨)
3. 제목: `autopilot <ver>`
4. 본문: `CHANGELOG.md` 의 `## <ver>` 섹션 내용
5. `dist/autopilot-<ver>.skill` 첨부 → **Publish release**

## .skill 파일 구조

zip 파일이며, 최상위에 `autopilot/` 폴더 하나가 있다.

```
autopilot-<ver>.skill
└── autopilot/
    ├── SKILL.md
    ├── assets/  (ROADMAP.md, BACKLOG.md, LOG.md, feature-template.md, autopilot-stop.sh)
    └── scripts/ (autopilot.sh)
```

`plugins/autopilot/skills/` 에서 `zip -r ... autopilot` 으로 만든다. CHANGELOG는 레포 루트에 있어 포함되지 않는다.
`unzip -l dist/autopilot-<ver>.skill` 로 최상위가 `autopilot/` 인지 확인할 수 있다.

## 잘못 릴리스했을 때

태그를 지우거나 다시 쓰지 않는다. PATCH를 올려 새 릴리스를 낸다.
