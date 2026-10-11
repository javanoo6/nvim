# Java Debugging for LeetCode Files

LeetCode `Solution` files usually have no `public static void main(String[] args)`.
Create a harness in a normal Java project to run or debug them locally.

Use `<leader>ji` / `:JavaInitProject` to create a Maven or Gradle project, then
place the solution and harness in its source tree. Match the package to the
project's package and save the public class as `HappyNumberDebug.java`:

```java
package demo;

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

Open the harness, check `:JavaInfo`, set breakpoints with `<leader>db`, and
use `<leader>jd` inside the main class. `<leader>jr` runs it without debugging.
This follows the normal Maven/Gradle build and IntelliJ launch path; an isolated
LeetCode file alone does not provide that build context.

Use the [debugging guide](java-debugging.md) for stepping, evaluation, and output,
and [Java workflow](java-workflow.md) for project/JDK setup. LeetCode run/submit
keys remain available for the original problem file.
