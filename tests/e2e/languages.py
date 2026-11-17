"""Optional language integration scenarios; installed tools are prerequisites."""

import json
import os
import sys
import subprocess


async def _require(audit, executable):
    if not await audit.lua(f"vim.fn.executable({json.dumps(executable)}) == 1"):
        raise RuntimeError(f"Language scenario requires {executable} on Neovim's PATH")


async def python_lsp_format(audit):
    await _require(audit, "pyright-langserver")
    project = audit.project
    (project / "pyproject.toml").write_text('[tool.pyright]\ntypeCheckingMode = "standard"\n', encoding="utf-8")
    (project / "main.py").write_text('def add(a:int,b:int):\n return a+b\n\nanswer: int = "wrong"\n', encoding="utf-8")
    await audit.reset("main.py")
    await audit.wait_for('vim.tbl_contains(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0})), "pyright")', timeout=30)
    await audit.wait_for('#vim.diagnostic.get(0, {severity=vim.diagnostic.severity.ERROR}) > 0', timeout=30)
    await audit.keys(" cf")
    await audit.wait_for('vim.api.nvim_buf_get_lines(0,0,1,false)[1] == "def add(a: int, b: int):"', timeout=30)
    return {"lsp": "pyright", "diagnostic": "type error", "format": "Python"}


async def python_tests(audit):
    python = os.environ.get("NVIM_E2E_PYTHON", sys.executable)
    try:
        probe = subprocess.run([python, "-c", "import pytest, sys; assert sys.prefix != sys.base_prefix"], capture_output=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError(f"Python scenario requires a virtualenv interpreter with pytest: {python}") from exc
    if probe.returncode:
        raise RuntimeError("Python scenario requires pytest in a virtualenv; set NVIM_E2E_PYTHON to its interpreter")
    (audit.project / "pyproject.toml").write_text('[tool.pytest.ini_options]\ntestpaths = ["tests"]\n', encoding="utf-8")
    (audit.project / "tests").mkdir(exist_ok=True)
    (audit.project / "tests/test_calc.py").write_text(
            'def test_pass():\n    assert 1 + 1 == 2\n\ndef test_fail():\n    assert 1 + 1 == 3\n', encoding="utf-8"
    )
    await audit.reset("tests/test_calc.py")
    await audit.cmd('lua require("venv-selector").activate_from_path(' + json.dumps(python) + ', "venv")')
    await audit.wait_for('require("venv-selector").python() == ' + json.dumps(python), timeout=15)
    await audit.keys(" tt")
    counts = await audit.wait_for(
            '(function() local ok,n=pcall(require,"neotest"); if not ok then return false end; '
            'for _,id in ipairs(n.state.adapter_ids()) do if id:find("neotest%-python") then '
            'local s=n.state.status_counts(id); if s and s.total==2 and s.running==0 and s.passed==1 and s.failed==1 then return s end end end return false end)()',
            timeout=90, interval=1
    )
    return {"interpreter": python, "test_counts": counts}


async def go_lsp_format_tests(audit):
    for executable in ("go", "gopls", "gotestsum"):
        await _require(audit, executable)
    project = audit.project
    (project / "go.mod").write_text("module example.com/e2e\n\ngo 1.24\n", encoding="utf-8")
    (project / "calc.go").write_text('package audit\n\nfunc Add(a int,b int) int {return a+b}\nvar Broken int = "wrong"\n', encoding="utf-8")
    (project / "calc_test.go").write_text(
            'package audit\nimport "testing"\nfunc TestPass(t *testing.T) { if Add(1,1)!=2 {t.Fatal("wrong")} }\n'
            'func TestFail(t *testing.T) { if Add(1,1)!=3 {t.Fatal("expected failure")} }\n', encoding="utf-8"
    )
    await audit.reset("calc.go")
    await audit.wait_for('vim.tbl_contains(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0})), "gopls")', timeout=30)
    await audit.wait_for('#vim.diagnostic.get(0, {severity=vim.diagnostic.severity.ERROR}) > 0', timeout=30)
    await audit.keys(" cf")
    await audit.wait_for('vim.api.nvim_buf_get_lines(0,2,3,false)[1] == "func Add(a int, b int) int { return a + b }"', timeout=30)
    await audit.cmd('lua vim.api.nvim_buf_set_lines(0,-2,-1,false,{})')
    await audit.cmd('write')
    await audit.reset("calc_test.go")
    await audit.keys(" ее")  # Russian physical equivalent of <leader>tt.
    counts = await audit.wait_for(
            '(function() local ok,n=pcall(require,"neotest"); if not ok then return false end; '
            'for _,id in ipairs(n.state.adapter_ids()) do if id:find("neotest%-golang") then '
            'local s=n.state.status_counts(id); if s and s.total==2 and s.running==0 and s.passed==1 and s.failed==1 then return s end end end return false end)()',
            timeout=120,
            interval=1,
    )
    return {"lsp": "gopls", "diagnostic": "type error", "format": "Go", "test_counts": counts, "layout": "Russian"}


async def java_lsp_tests(audit):
    for executable in ("java", "mvn"):
        await _require(audit, executable)
    if not list((audit.base / "data/nvim/neotest-java").glob("*.jar")):
        raise RuntimeError("Java scenario requires an installed neotest-java JUnit Console jar")
    project = audit.project
    (project / ".mvn").mkdir(exist_ok=True)
    (project / ".mvn/maven.config").write_text("--offline\n", encoding="utf-8")
    (project / "src/main/java/example").mkdir(parents=True, exist_ok=True)
    (project / "src/test/java/example").mkdir(parents=True, exist_ok=True)
    (project / "pom.xml").write_text(
            '<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion>'
            '<groupId>example</groupId><artifactId>audit</artifactId><version>1.0</version>'
            '<properties><maven.compiler.release>21</maven.compiler.release></properties><dependencies>'
            '<dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId>'
            '<version>5.10.2</version><scope>test</scope></dependency></dependencies><build><plugins>'
            '<plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId>'
            '<version>3.2.5</version></plugin></plugins></build></project>', encoding="utf-8"
    )
    (project / "src/main/java/example/Calc.java").write_text(
            'package example;\npublic class Calc { public static int add(int a,int b){return a+b;} }\n', encoding="utf-8"
    )
    (project / "src/test/java/example/CalcTest.java").write_text(
            'package example;\nimport org.junit.jupiter.api.Test;\nimport static org.junit.jupiter.api.Assertions.*;\n'
            'class CalcTest {\n @Test void pass(){assertEquals(2,Calc.add(1,1));}\n'
            ' @Test void fail(){assertEquals(3,Calc.add(1,1));}\n}\n', encoding="utf-8"
    )
    result = subprocess.run(["mvn", "-o", "test-compile"], cwd=project, capture_output=True, text=True, timeout=90)
    if result.returncode:
        raise RuntimeError("Java scenario needs cached Maven dependencies and build plugins: " + result.stdout[-1500:])
    await audit.reset("src/test/java/example/CalcTest.java")
    await audit.wait_for('vim.tbl_contains(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0})), "intellij")', timeout=120, interval=1)
    await audit.wait_for('(function() for _,n in ipairs(_G.audit_notifications or {}) do if n.msg:find("indexing complete",1,true) then return true end end return false end)()', timeout=120, interval=1)
    await audit.keys(" tt")
    counts = await audit.wait_for(
            '(function() local ok,n=pcall(require,"neotest"); if not ok then return false end; '
            'for _,id in ipairs(n.state.adapter_ids()) do if id:find("neotest%-intellij%-java") then '
            'local s=n.state.status_counts(id); if s and s.total==2 and s.running==0 and s.passed==1 and s.failed==1 then return s end end end return false end)()',
            timeout=120, interval=1
    )
    return {"lsp": "intellij", "test_counts": counts}


async def go_debug(audit):
    for executable in ("go", "dlv"):
        await _require(audit, executable)
    (audit.project / "go.mod").write_text("module example.com/debug\n\ngo 1.24\n", encoding="utf-8")
    (audit.project / "calc_test.go").write_text(
            'package audit\n\nimport "testing"\n\nfunc TestCalculation(t *testing.T) {\n'
            '    number := 41\n    result := number + 1\n    if result != 42 {\n'
            '        t.Fatal(result)\n    }\n}\n', encoding="utf-8"
    )
    await audit.reset("calc_test.go")
    source = await audit.lua("vim.api.nvim_get_current_buf()")
    await audit.cmd("lua vim.api.nvim_win_set_cursor(0,{8,0})")
    await audit.keys(" db")
    assert await audit.lua(
            '(function() for _,points in pairs(require("dap.breakpoints").get()) do '
            'for _,point in ipairs(points) do if point.buf==' + str(source) + ' and point.line==8 then return true end end end return false end)()'
    ), "Go breakpoint was not set"
    await audit.cmd("lua vim.api.nvim_win_set_cursor(0,{5,0})")
    await audit.keys(" dgt")
    await audit.wait_for(
            '(function() local s=require("dap").session(); return s and s.stopped_thread_id and s.current_frame and s.current_frame.line==8 or false end)()',
            timeout=120, interval=1
    )
    await audit.wait_for(
            '(function() local f={} for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do f[vim.bo[vim.api.nvim_win_get_buf(w)].filetype]=true end '
            'return f.dapui_scopes and f.dapui_stacks and f.dapui_watches or false end)()', timeout=20
    )
    await audit.cmd(
            'lua local s=require("dap").session(); s:request("scopes",{frameId=s.current_frame.id},'
            'function(err,r) _G.audit_go_scopes={error=err,result=r} end)'
    )
    await audit.wait_for('_G.audit_go_scopes ~= nil', timeout=20)
    await audit.cmd(
            'lua local s=require("dap").session(); local r=_G.audit_go_scopes.result; '
            'local scope=r and r.scopes[1]; assert(scope,"Go DAP returned no local scope"); '
            's:request("variables",{variablesReference=scope.variablesReference},'
            'function(err,v) _G.audit_go_variables={error=err,result=v} end)'
    )
    await audit.wait_for('_G.audit_go_variables ~= nil', timeout=20)
    values = await audit.lua(
            '(function() local out={} local r=_G.audit_go_variables.result; '
            'for _,v in ipairs(r and r.variables or {}) do out[v.name]=v.value end return out end)()'
    )
    assert values.get("number") == "41" and values.get("result") == "42", f"Unexpected Go locals: {values}"
    await audit.wait_for(
            '(function() local seen={} for _,m in ipairs(vim.api.nvim_buf_get_extmarks(' + str(source) + ',-1,0,-1,{details=true})) do '
                                                                                                         'for _,chunk in ipairs(m[4].virt_text or {}) do if chunk[2]=="NvimDapVirtualText" then seen[chunk[1]]=true end end end '
                                                                                                         'return seen["41"] and seen["42"] or false end)()', timeout=20
    )
    await audit.cmd('lua require("dap").continue()')
    await audit.wait_for('require("dap").session()==nil', timeout=30)
    await audit.wait_for(
            '(function() for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
            'if vim.bo[vim.api.nvim_win_get_buf(w)].filetype:match("^dapui_") then return false end end return true end)()', timeout=20
    )
    return {"breakpoint_line": 8, "locals": {"number": values["number"], "result": values["result"]}, "ui_closed": True}


CASES = {"python_lsp_format": python_lsp_format, "python_tests": python_tests, "go_lsp_format_tests": go_lsp_format_tests, "java_lsp_tests": java_lsp_tests, "go_debug": go_debug}
