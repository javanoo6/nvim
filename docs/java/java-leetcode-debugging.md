# Java Debugging for LeetCode Files

Workflow note for standalone LeetCode-style Java files such as:

```text
/home/konkov/leetcode/202.happy-number.java
```

## Key Constraint

LeetCode files usually contain only a `Solution` class. They are not runnable
Java applications because they have no:

```java
public static void main(String[] args)
```

So `:JavaRunnerRunMain` and Java DAP launch discovery cannot run the original
file directly.

## Recommended Workflow

Create a small harness in the same directory:

```java
class Solution {
  public boolean isHappy(int n) {
    return false;
  }
}

public class HappyNumberDebug {
  public static void main(String[] args) {
    System.out.println(new Solution().isHappy(19));
  }
}
```

Then open the harness from the LeetCode directory:

```bash
cd /home/konkov/leetcode
nvim HappyNumberDebug.java
```

Use the normal Java/DAP workflow:

- verify `jdtls` with `:LspInfo`
- set breakpoints with `<leader>db`
- debug the main class with `<leader>jd`
- use `<leader>d*` keys for stepping, eval, UI, and termination

If needed, force Java DAP setup first:

```vim
:JavaDapConfig
```

## Runtime Note

If JDTLS or Java debugging fails under the shell default JDK, launch Neovim with
a known-good JDK:

```bash
JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 \
PATH=/usr/lib/jvm/java-1.17.0-openjdk-amd64/bin:$PATH \
nvim /home/konkov/leetcode/HappyNumberDebug.java
```

## Relevant Files

- [lua/plugins/nvim-java.lua](/home/konkov/.config/nvim/lua/plugins/nvim-java.lua:1)
- [lua/plugins/dap.lua](/home/konkov/.config/nvim/lua/plugins/dap.lua:1)
- [lua/util/java_debug.lua](/home/konkov/.config/nvim/lua/util/java_debug.lua:1)
