# 릴리스 절차

릴리스는 Claude가 `CLAUDE.md`의 판단 기준에 따라 직접 수행한다. 사람이 해도 절차는 같다.

## 브랜치 흐름 (git flow)

```
feature/<topic> ──PR──▶ develop ──▶ release/<ver> ──PR──▶ main (+ tag v<ver>)
                                                        └──PR──▶ develop (main 역병합)
```

## 순서

1. feature PR들이 `develop`에 머지되며 `CHANGELOG.md`의 `## Unreleased`에 항목이 쌓인다.
2. `git checkout -b release/<ver> origin/develop`
3. `bash scripts/bump.sh <major|minor|patch>`: `## Unreleased`가 `## <ver> — <날짜>`가 되고 SKILL.md·plugin.json 버전이 갱신된다.
4. `bash scripts/validate.sh` → PASS → 커밋 `chore(release): <ver>` → push
5. PR `release/<ver>` → `main` 생성·머지 (merge commit)
6. PR `main` → `develop` 생성·머지 (역병합. `develop`은 PR head로 쓰지 않는다: 자동 삭제 대상이 되므로)
7. `main`을 받은 뒤 `bash scripts/release.sh`

`release.sh`가 하는 일:
1. `main` 브랜치인지 확인
2. `validate.sh` 실행
3. 작업 트리가 깨끗한지 확인
4. 태그 `v<ver>`가 아직 없는지 확인
5. 커밋된 내용으로 `dist/autopilot-<ver>.skill` 생성 (`git archive`)
6. `git tag -a v<ver>` → `git push origin v<ver>`. 실패하면 로컬 태그를 지우고, `gh`에 이 레포 쓰기 권한이 있으면 `gh release create --target <커밋>`으로 GitHub에서 태그와 Release를 함께 만든다. 그것도 안 되면 종료
7. `gh`가 있으면 CHANGELOG의 해당 섹션을 노트로 `gh release create` + `.skill` 첨부

## 밀린 태그 한 번에 만들기

태그 push도 `gh`도 쓸 수 없는 환경에서 릴리스하면 `main`에는 버전이 들어갔지만 태그가 없는 상태가 된다. Claude Code 클라우드 세션이 그렇다: git 태그 push는 403, Release API는 "not permitted for this session type"으로 정책상 막혀 있다. 태그를 push할 수 있거나 쓰기 권한이 있는 `gh`가 있는 곳에서:

```bash
git checkout main && git pull
bash scripts/release.sh --catch-up
```

CHANGELOG의 모든 버전에 대해, 태그가 없으면 `main`의 first-parent 기록에서 plugin.json이 그 버전이 된 첫 커밋을 찾아 태그를 달고 push하고 Release를 만든다. 패키지는 그 커밋의 내용으로 만든다.

## gh가 없을 때

`release.sh`는 태그 push까지 하고 안내를 출력한다. 수동으로:

1. GitHub 레포 → **Releases** → **Draft a new release**
2. 태그: `v<ver>` (이미 push 됨)
3. 제목: `autopilot <ver>`
4. 본문: `CHANGELOG.md`의 `## <ver>` 섹션 내용
5. `dist/autopilot-<ver>.skill` 첨부 → **Publish release**

## .skill 파일 구조

zip 파일이며, 최상위에 `autopilot/` 폴더 하나가 있다.

```
autopilot-<ver>.skill
└── autopilot/
    ├── SKILL.md
    ├── assets/
    └── scripts/
```

`unzip -l dist/autopilot-<ver>.skill`로 최상위가 `autopilot/`인지 확인할 수 있다.

## 잘못 릴리스했을 때

태그를 지우거나 다시 쓰지 않는다. PATCH를 올려 새 릴리스를 낸다.
