import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")
if os.name == "nt":
    BASH = str(Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Git" / "bin" / "bash.exe")

AZ = """#!/usr/bin/env bash
echo "az $*" >> "$TRACE"
case "$1 $2" in
  "account show")
    if [[ "$*" == *"--query id"* ]]; then echo "${ACCOUNT:-fixture-sub}"
    else echo '{"name":"fixture","state":"Enabled"}'; fi ;;
  "aks show")
    if [[ "$*" == *nodeResourceGroup* ]]; then echo fixture-node
    else echo fixture.aks.local; fi ;;
  "feature show") echo Registered ;;
  "group exists") echo false ;;
  "provider register"|"feature register") test "${SETUP_FAIL:-0}" = 0 ;;
  *) echo fixture ;;
esac
"""
KUBE = """#!/usr/bin/env bash
echo "kubectl $*" >> "$TRACE"
echo "kubeconfig=$KUBECONFIG" >> "$TRACE"
case "$1 $2" in
  "version --client") echo fixture ;;
  "config view") echo "${SERVER:-https://fixture.aks.local:443}" ;;
  "get namespace")
    [ "${NAMESPACE_ERROR:-0}" = 0 ] || { echo "namespace lookup denied" >&2; exit 9; }
    [ "${EXISTING:-0}" = 0 ] || echo namespace/lab ;;
  "create namespace"|"auth can-i") exit 0 ;;
  "get nodes")
    if [[ "$*" == *"-o json"* ]]; then
      echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"'"${NODE_READY:-True}"'"}]}}]}'
    else echo "fixture user"; fi ;;
  "get node") echo "${POOL:-user}" ;;
  "apply -f") cat >/dev/null ;;
  "delete pod") touch "$RESTARTED" ;;
  "-n lab")
    case "$3" in
      wait|rollout)
        [ "${WAIT_FAIL:-0}" = 0 ] || { echo "readiness timeout" >&2; exit 8; } ;;
      logs)
        printf ' successful_checks\\n-------------------\\n %s\\n(1 row)\\n' "${SQL_COUNT:-1}" ;;
      get)
        case "$4" in
          gateway) echo "${GATEWAY:-fixture.gateway.local}" ;;
          pod) echo '{"metadata":{"labels":{"app":"lab-web"}},"spec":{"nodeName":"fixture-user"},"status":{"conditions":[{"type":"Ready","status":"'"${POD_READY:-True}"'"}]}}' ;;
        esac ;;
    esac ;;
  *) echo "unexpected kubectl command" >&2; exit 14 ;;
esac
"""
CURL = """#!/usr/bin/env bash
echo "curl $*" >> "$TRACE"
[ "${CURL_FAIL:-0}" = 0 ] || { echo "fixture network error" >&2; exit 7; }
case "${!#}" in
  *api.ipify.org) echo 203.0.113.7 ;;
  */data/products.txt) printf '%s\\n' 'Dune Light DL-12 · KRW 250000' ;;
  */pod-name.txt)
    if [ -f "$RESTARTED" ]; then echo lab-web-new
    else echo lab-web-old; fi ;;
  */pod-namespace.txt) echo "${RESPONSE_NS:-lab}" ;;
  *) echo "Contoso Shop" ;;
esac
"""


class WorkshopTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="workshop-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        shutil.copytree(ROOT / "scripts", self.root / "scripts")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name, body in {"az": AZ, "kubectl": KUBE, "curl": CURL,
                           "kubelogin": "#!/usr/bin/env bash\necho fixture\n"}.items():
            self.write(self.bin / name, body)
        jq = shutil.which("jq") or shutil.which("jq.exe")
        if not jq:
            self.fail("jq is required for the existing workshop scripts and their tests")
        self.jq_directory = str(Path(jq).parent)
        self.write(self.root / "scripts" / "prepare-aks-access.sh", """#!/usr/bin/env bash
set -euo pipefail
test "$1" = --approved
echo "approved-access" >> "$TRACE"
mkdir -p .azure
touch .azure/workshop.kubeconfig
""")
        self.write(self.root / "scripts" / "render-workload.sh", """#!/usr/bin/env bash
echo "render" >> "$TRACE"
test "${RENDER_FAIL:-0}" = 0 || { echo "renderer failed" >&2; exit 7; }
echo "kind: List"
""")
        self.write(self.root / ".env", """SUBSCRIPTION_ID=fixture-sub
WORKSHOP_ID=sample
RESOURCE_GROUP=rg-aks-lab-sample
REGION=koreacentral
AKS_NAME=aks-lab-sample
NAMESPACE=lab
NODE_RESOURCE_GROUP=
EGRESS_IP_CIDR=203.0.113.7/32
""")
        (self.root / ".azure").mkdir()
        (self.root / ".azure" / "workshop.kubeconfig").touch()
        for skill in ["azure-quotas", "azure-kubernetes", "azure-enterprise-infra-planner",
                      "azure-resource-lookup", "azure-diagnostics", "azure-resource-visualizer"]:
            path = self.root / ".github" / "skills" / skill / "SKILL.md"
            path.parent.mkdir(parents=True)
            self.write(path, "fixture")
        self.trace_file = self.root / "trace"
        self.env = os.environ.copy()
        self.env.update(TRACE=str(self.trace_file), RESTARTED=str(self.root / "restarted"),
                        MSYS_NO_PATHCONV="1", KUBECONFIG="unrelated-external-context")
        self.env["PATH"] = self.jq_directory + os.pathsep + self.env["PATH"]

    @staticmethod
    def write(path, content):
        path.write_text(content, encoding="utf-8", newline="\n")
        path.chmod(0o755)

    def run_action(self, *args, **env):
        invocation_env = {**self.env, **env}
        return subprocess.run(
            [BASH, "-c", 'export PATH="$PWD/bin:$PATH"; bash scripts/workshop.sh "$@"',
             "test", *args], cwd=self.root, env=invocation_env, capture_output=True,
            text=True, encoding="utf-8", timeout=30)

    def trace(self):
        return self.trace_file.read_text(encoding="utf-8") if self.trace_file.exists() else ""

    def test_mutations_require_exact_approval_flag(self):
        for action in ["setup", "connect", "apply", "restart"]:
            with self.subTest(action=action):
                result = self.run_action(action)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("approval required", result.stderr)
                self.assertEqual(self.trace(), "")

    def test_invalid_arguments_do_not_query_or_write(self):
        for args in [(), ("destroy",), ("verify", "--approved"),
                     ("connect", "--approved", "extra")]:
            with self.subTest(args=args):
                self.assertNotEqual(self.run_action(*args).returncode, 0)
                self.assertEqual(self.trace(), "")

    def test_subscription_mismatch_blocks_all_actions(self):
        for action in ["check", "setup", "connect", "apply", "verify", "restart"]:
            args = (action,) if action in ["check", "verify"] else (action, "--approved")
            with self.subTest(action=action):
                result = self.run_action(*args, ACCOUNT="different-sub")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("differs from .env", result.stderr)
                self.assertNotIn("kubectl", self.trace())
                self.assertNotIn("register", self.trace())

    def test_check_uses_real_helpers_without_azure_changes(self):
        result = self.run_action("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("register", self.trace())
        self.assertNotIn("approved-access", self.trace())
        self.assertIn("no Azure changes", result.stdout)

    def test_check_missing_skill_stops_before_initialization(self):
        (self.root / ".github" / "skills" / "azure-quotas" / "SKILL.md").unlink()
        before = (self.root / ".env").read_bytes()
        result = self.run_action("check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing required Skill", result.stderr)
        self.assertEqual(before, (self.root / ".env").read_bytes())

    def test_check_does_not_accept_stale_egress_after_lookup_failure(self):
        result = self.run_action("check", CURL_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("environment checked", result.stdout)
        self.assertNotIn("group exists", self.trace())

    def test_setup_registers_only_confirmed_subscription(self):
        result = self.run_action("setup", "--approved")
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = [line for line in self.trace().splitlines() if "register" in line]
        self.assertEqual(len(lines), 10)
        self.assertTrue(all("--subscription fixture-sub" in line for line in lines))
        self.assertNotIn("kubectl", self.trace())

    def test_setup_failure_is_not_success(self):
        result = self.run_action("setup", "--approved", SETUP_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Features Registered", result.stdout)

    def test_wrong_namespace_blocks_kubernetes(self):
        text = (self.root / ".env").read_text().replace("NAMESPACE=lab", "NAMESPACE=production")
        self.write(self.root / ".env", text)
        result = self.run_action("apply", "--approved")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("kubectl", self.trace())

    def test_missing_or_wrong_kubeconfig_blocks_apply(self):
        path = self.root / ".azure" / "workshop.kubeconfig"
        path.unlink()
        self.assertNotEqual(self.run_action("apply", "--approved").returncode, 0)
        self.assertNotIn("render", self.trace())
        path.touch()
        result = self.run_action("apply", "--approved", SERVER="https://other.aks.local:443")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not target", result.stderr)
        self.assertNotIn("render", self.trace())

    def test_connect_reuses_helper_and_existing_namespace(self):
        result = self.run_action("connect", "--approved", EXISTING="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("approved-access", self.trace())
        self.assertNotIn("create namespace", self.trace())
        self.assertIn("NODE_RESOURCE_GROUP=fixture-node", (self.root / ".env").read_text())
        self.assertNotIn("unrelated-external-context", self.trace())

    def test_connect_creates_only_absent_namespace(self):
        result = self.run_action("connect", "--approved")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("create namespace lab", self.trace())

    def test_namespace_lookup_error_stops_creation(self):
        result = self.run_action("connect", "--approved", NAMESPACE_ERROR="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("create namespace", self.trace())

    def test_nonready_nodes_are_rejected(self):
        result = self.run_action("connect", "--approved", NODE_READY="False")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Not all AKS Nodes are Ready", result.stderr)

    def test_renderer_failure_propagates_before_verification(self):
        result = self.run_action("apply", "--approved", RENDER_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("renderer failed", result.stderr)
        self.assertNotIn("rollout status", self.trace())

    def test_readiness_timeout_stops_http(self):
        result = self.run_action("verify", WAIT_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("curl", self.trace())

    def test_verify_checks_http_sql_pod_and_pool_without_writes(self):
        result = self.run_action("verify")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Verified HTTP, SQL, response Pod and User Pool", result.stdout)
        for mutation in ["apply -f", "delete pod", "create namespace", "approved-access"]:
            self.assertNotIn(mutation, self.trace())
        self.assertIn('--for=jsonpath={.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}=True',
                      self.trace())

    def test_sql_zero_rejected_and_restart_does_not_delete(self):
        for action in ["verify", "restart"]:
            args = (action,) if action == "verify" else (action, "--approved")
            result = self.run_action(*args, SQL_COUNT="0")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("no positive successful_checks", result.stderr)
            self.assertNotIn("delete pod", self.trace())

    def test_response_namespace_pod_and_pool_failures(self):
        for env in [{"RESPONSE_NS": "other"}, {"POD_READY": "False"}, {"POOL": "system"}]:
            with self.subTest(env=env):
                result = self.run_action("verify", **env)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Verified HTTP, SQL, response Pod", result.stdout)

    def test_apply_runs_existing_renderer_and_complete_verification(self):
        result = self.run_action("apply", "--approved")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("render", self.trace())
        self.assertIn("apply -f -", self.trace())
        self.assertIn("Verified HTTP, SQL", result.stdout)

    def test_restart_compares_real_response_identity_and_reuses_verify(self):
        result = self.run_action("restart", "--approved")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.trace().count("delete pod -n lab"), 1)
        self.assertIn("same URL, new Pod, exact SQL product", result.stdout)

    def test_complete_agent_command_sequence_and_evidence_recording(self):
        results = []
        for args in [("check",), ("setup", "--approved"), ("connect", "--approved"),
                     ("apply", "--approved"), ("verify",), ("restart", "--approved"), ("verify",)]:
            with self.subTest(action=args[0]):
                result = self.run_action(*args)
                self.assertEqual(result.returncode, 0, result.stderr)
                results.append(result.stdout)
        body = "\n".join(results)
        recorded = subprocess.run(
            [BASH, "scripts/add-report.sh", "workload", "Fixture E2E", "offline mock tools"],
            cwd=self.root, env=self.env, input=body, capture_output=True,
            text=True, encoding="utf-8", timeout=15)
        self.assertEqual(recorded.returncode, 0, recorded.stderr)
        report = (self.root / "infra-report.md").read_text(encoding="utf-8")
        self.assertIn("successful_checks", report)
        self.assertIn("same URL, new Pod, exact SQL product", report)
        self.assertEqual(self.trace().count("delete pod -n lab"), 1)


class DocumentTests(unittest.TestCase):
    def test_terminal_budget_and_links(self):
        paths = [ROOT / "README.md", *sorted((ROOT / "docs" / "labs").glob("*.md"))]
        blocks = []
        for path in paths:
            text = path.read_text(encoding="utf-8")
            blocks.extend(re.findall(r"```bash\n(.*?)\n```", text, re.S))
            for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", text):
                if re.match(r"^(https?://|#|mailto:)", target):
                    continue
                self.assertTrue((path.parent / unquote(target.split("#")[0])).exists(),
                                f"{path.name}: {target}")
            for target in re.findall(r'<img[^>]+src="([^"]+)"', text):
                self.assertTrue((path.parent / target).exists(), f"{path.name}: {target}")
            for block in re.findall(r"```text\n(.*?)\n```", text, re.S):
                if " Skill" in block:
                    self.assertTrue(block.strip().endswith(
                        "이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘"), path.name)
            if path.parent.name == "labs":
                for match in re.finditer(r"```(bash|text)\n", text):
                    preceding = text[:match.start()].rstrip().splitlines()[-1]
                    self.assertIn("터미널에서 실행" if match[1] == "bash" else
                                  "Copilot 채팅에 붙여넣기", preceding)
                self.assertLessEqual(text.count("> [!WARNING]"), 1)
        self.assertEqual(blocks, ["az login --use-device-code"])

    def test_script_syntax(self):
        for path in [*sorted((ROOT / "scripts").glob("*.sh")), ROOT / ".devcontainer" / "post-create.sh"]:
            result = subprocess.run([BASH, "-n", str(path)], capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_labs_keep_approvals_and_recovery_read_only(self):
        docs = sorted((ROOT / "docs" / "labs").glob("*.md"))
        self.assertEqual(len(docs), 8)
        for i, path in enumerate(docs, 1):
            text = path.read_text(encoding="utf-8")
            self.assertIn(f"**Lab {i} / 8**", text)
            for section in ["왜 필요한가요?", "시작 전에", "Step 1.", "완료 체크리스트", "문제가 생겼다면"]:
                self.assertIn(section, text)
            self.assertEqual(text.count("<details>"), text.count("</details>"))
            if i < 8:
                self.assertIn(docs[i].name, text.split("## 다음 Lab", 1)[1])
        lab6 = docs[5].read_text(encoding="utf-8")
        lab7 = docs[6].read_text(encoding="utf-8")
        lab8 = docs[7].read_text(encoding="utf-8")
        self.assertIn("승인 전에는 적용하지 마", lab6)
        self.assertIn("승인 전에는 Pod를 삭제하지 마", lab6)
        self.assertIn("scripts/workshop.sh verify", lab7)
        self.assertIn("Manifest 적용이나 Pod 삭제·재생성은 반복하지 마", lab7)
        self.assertIn("실제 삭제 작업은 명시적 승인 전에는 수행하지 마", lab8)

    def test_beginner_reading_budget(self):
        main_prompts = 0
        for path in sorted((ROOT / "docs" / "labs").glob("*.md")):
            text = path.read_text(encoding="utf-8")
            main = re.sub(r"<details>.*?</details>", "", text, flags=re.S)
            with self.subTest(document=path.name):
                self.assertLessEqual(len(main.splitlines()), 90)
                self.assertLessEqual(len(text.splitlines()), 125)
                count = len(re.findall(r"```text\n", main))
                self.assertLessEqual(count, 2)
                main_prompts += count
                why = text.split("## 왜 필요한가요?", 1)[1].split("## 시작 전에", 1)[0]
                explanation = [line for line in why.splitlines() if line.strip()]
                self.assertGreaterEqual(len(explanation), 2)
                self.assertLessEqual(len(explanation), 3)
                self.assertTrue(all(len(line) <= 100 for line in explanation))
                prerequisites = text.split("## 시작 전에", 1)[1].split("## Step 1.", 1)[0]
                self.assertEqual(len([line for line in prerequisites.splitlines() if line.strip()]), 1)
        self.assertEqual(main_prompts, 9)

    def test_steps_explain_the_action_before_execution(self):
        for path in sorted((ROOT / "docs" / "labs").glob("*.md")):
            main = re.sub(r"<details>.*?</details>", "", path.read_text(encoding="utf-8"), flags=re.S)
            steps = re.findall(r"^## Step (\d+)\.[^\n]*\n(.*?)(?=^## |\Z)", main, re.M | re.S)
            for number, body in steps:
                with self.subTest(document=path.name, step=number):
                    intro = body.split("> ", 1)[0]
                    self.assertTrue(any(line.strip() for line in intro.splitlines()))


if __name__ == "__main__":
    unittest.main()
