# 공개 전 점검 체크리스트

레포를 public으로 전환하거나 릴리스하기 전에 확인한다.

## 점검 항목

- [ ] 플레이스홀더(`<GITHUB_ID>`, `<NAME>`)가 실제 값으로 교체되었다 (`validate.sh`가 WARN으로 알려준다)
- [ ] 아래 금지어가 레포 어디에도 없다 (`validate.sh`가 grep 한다)
- [ ] `git log -p` 전체에도 금지어·내부 경로·개인 정보가 없다 (히스토리는 `validate.sh`가 보지 않는다)
- [ ] 비밀값·토큰·키가 없다 (`.env`, 자격 증명 파일, 하드코딩된 키)
- [ ] 스킬 본문이 특정 조직 전용 도구·MCP를 필수로 요구하지 않는다 (예시로만 언급)
- [ ] LICENSE, SECURITY.md, CONTRIBUTING.md, README(영/한)가 최신 상태다
- [ ] `bash scripts/validate.sh` 가 통과한다

## 금지어 목록

`scripts/validate.sh` 는 아래 코드 블록의 각 줄을 대소문자 무시 확장 정규식(`grep -iE`)으로 레포 전체에서 찾는다.
빈 줄과 `#`으로 시작하는 줄, `<여기에 추가>` 줄은 무시한다. 하나라도 걸리면 FAIL.

분류: 회사명 · 프로젝트명 · 내부 호스트 · 개인 경로 패턴

<!-- FORBIDDEN-PATTERNS:BEGIN -->
```
# 회사명
<여기에 추가>
# 프로젝트명
<여기에 추가>
# 내부 호스트 (예: \.corp\.example\.com)
<여기에 추가>
# 개인 경로 패턴 (예: /Users/[a-z]+/)
<여기에 추가>
```
<!-- FORBIDDEN-PATTERNS:END -->

금지어를 추가할 때 이 문서 자체는 grep 대상에서 제외되므로 안전하다.
