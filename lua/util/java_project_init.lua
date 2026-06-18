local M = {}

local defaults = {
  group_id = "com.example",
  artifact_id = "demo",
  package_name = "com.example.demo",
  java_version = "21",
}

local build_tools = {
  {
    label = "Maven",
    value = "maven",
  },
  {
    label = "Gradle Kotlin DSL",
    value = "gradle-kotlin",
  },
  {
    label = "Gradle Groovy DSL",
    value = "gradle-groovy",
  },
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "JavaInitProject" })
end

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_path(path)
  if not path or path == "" then
    return nil
  end

  path = vim.fn.expand(path)
  return vim.fs.normalize(path)
end

local function is_valid_java_identifier(value)
  return value:match("^[A-Za-z_$][A-Za-z0-9_$]*$") ~= nil
end

local function is_valid_java_package(value)
  if value == "" then
    return false
  end

  for part in value:gmatch("[^.]+") do
    if not is_valid_java_identifier(part) then
      return false
    end
  end

  return value:match("%.%.") == nil and value:sub(1, 1) ~= "." and value:sub(-1) ~= "."
end

local function sanitize_artifact(value)
  value = trim(value)
  value = value:gsub("%s+", "-"):gsub("[^A-Za-z0-9_.-]", "-")
  value = value:gsub("^-+", ""):gsub("-+$", "")
  return value ~= "" and value or defaults.artifact_id
end

local function package_to_dir(package_name)
  return package_name:gsub("%.", "/")
end

local function path_join(...)
  return table.concat({ ... }, "/")
end

local function write_file(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

local function input(prompt, default, callback)
  vim.ui.input({ prompt = prompt, default = default }, function(value)
    value = trim(value)
    if value == "" then
      callback(nil)
      return
    end
    callback(value)
  end)
end

local function select_build_tool(callback)
  vim.ui.select(build_tools, {
    prompt = "Build tool",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    callback(choice and choice.value or nil)
  end)
end

local function empty_or_missing(path)
  if vim.fn.isdirectory(path) ~= 1 then
    return true
  end

  local handle = vim.uv.fs_scandir(path)
  if not handle then
    return true
  end

  return vim.uv.fs_scandir_next(handle) == nil
end

local function main_class_lines(package_name)
  return {
    "package " .. package_name .. ";",
    "",
    "public class Main {",
    "    public static void main(String[] args) {",
    '        System.out.println("Hello from Java");',
    "    }",
    "}",
  }
end

local function test_class_lines(package_name)
  return {
    "package " .. package_name .. ";",
    "",
    "import org.junit.jupiter.api.Test;",
    "",
    "import static org.junit.jupiter.api.Assertions.assertTrue;",
    "",
    "class MainTest {",
    "    @Test",
    "    void starts() {",
    "        assertTrue(true);",
    "    }",
    "}",
  }
end

local function pom_lines(opts)
  return {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<project xmlns="http://maven.apache.org/POM/4.0.0"',
    '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
    '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">',
    "    <modelVersion>4.0.0</modelVersion>",
    "",
    "    <groupId>" .. opts.group_id .. "</groupId>",
    "    <artifactId>" .. opts.artifact_id .. "</artifactId>",
    "    <version>0.1.0-SNAPSHOT</version>",
    "",
    "    <properties>",
    "        <maven.compiler.release>" .. opts.java_version .. "</maven.compiler.release>",
    "        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>",
    "        <junit.version>5.10.2</junit.version>",
    "    </properties>",
    "",
    "    <dependencies>",
    "        <dependency>",
    "            <groupId>org.junit.jupiter</groupId>",
    "            <artifactId>junit-jupiter</artifactId>",
    "            <version>${junit.version}</version>",
    "            <scope>test</scope>",
    "        </dependency>",
    "    </dependencies>",
    "",
    "    <build>",
    "        <plugins>",
    "            <plugin>",
    "                <groupId>org.apache.maven.plugins</groupId>",
    "                <artifactId>maven-surefire-plugin</artifactId>",
    "                <version>3.2.5</version>",
    "            </plugin>",
    "        </plugins>",
    "    </build>",
    "</project>",
  }
end

local function gradle_settings_lines(opts)
  return {
    'rootProject.name = "' .. opts.artifact_id .. '"',
  }
end

local function gradle_kotlin_lines(opts)
  return {
    "plugins {",
    "    java",
    "    application",
    "}",
    "",
    'group = "' .. opts.group_id .. '"',
    'version = "0.1.0-SNAPSHOT"',
    "",
    "repositories {",
    "    mavenCentral()",
    "}",
    "",
    "dependencies {",
    '    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")',
    "}",
    "",
    "java {",
    "    toolchain {",
    "        languageVersion = JavaLanguageVersion.of(" .. opts.java_version .. ")",
    "    }",
    "}",
    "",
    "application {",
    '    mainClass = "' .. opts.package_name .. '.Main"',
    "}",
    "",
    "tasks.test {",
    "    useJUnitPlatform()",
    "}",
  }
end

local function gradle_groovy_lines(opts)
  return {
    "plugins {",
    "    id 'java'",
    "    id 'application'",
    "}",
    "",
    "group = '" .. opts.group_id .. "'",
    "version = '0.1.0-SNAPSHOT'",
    "",
    "repositories {",
    "    mavenCentral()",
    "}",
    "",
    "dependencies {",
    "    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'",
    "}",
    "",
    "java {",
    "    toolchain {",
    "        languageVersion = JavaLanguageVersion.of(" .. opts.java_version .. ")",
    "    }",
    "}",
    "",
    "application {",
    "    mainClass = '" .. opts.package_name .. ".Main'",
    "}",
    "",
    "test {",
    "    useJUnitPlatform()",
    "}",
  }
end

local function write_project(opts)
  local source_dir = package_to_dir(opts.package_name)

  if opts.build_tool == "maven" then
    write_file(path_join(opts.root, "pom.xml"), pom_lines(opts))
  elseif opts.build_tool == "gradle-kotlin" then
    write_file(path_join(opts.root, "settings.gradle.kts"), gradle_settings_lines(opts))
    write_file(path_join(opts.root, "build.gradle.kts"), gradle_kotlin_lines(opts))
  else
    write_file(path_join(opts.root, "settings.gradle"), gradle_settings_lines(opts))
    write_file(path_join(opts.root, "build.gradle"), gradle_groovy_lines(opts))
  end

  write_file(path_join(opts.root, "src/main/java", source_dir, "Main.java"), main_class_lines(opts.package_name))
  write_file(path_join(opts.root, "src/test/java", source_dir, "MainTest.java"), test_class_lines(opts.package_name))
  write_file(path_join(opts.root, ".gitignore"), {
    "target/",
    "build/",
    ".gradle/",
    ".idea/",
    ".classpath",
    ".project",
    ".settings/",
    "*.class",
  })
end

local function open_project(opts)
  vim.cmd("cd " .. vim.fn.fnameescape(opts.root))
  vim.cmd("edit " .. vim.fn.fnameescape(path_join(opts.root, "src/main/java", package_to_dir(opts.package_name), "Main.java")))
  notify("Created " .. opts.build_tool .. " project at " .. opts.root)
end

local function confirm_non_empty(opts)
  if empty_or_missing(opts.root) then
    write_project(opts)
    open_project(opts)
    return
  end

  vim.ui.select({ "Cancel", "Create missing files anyway" }, {
    prompt = "Directory is not empty",
  }, function(choice)
    if choice ~= "Create missing files anyway" then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end

    write_project(opts)
    open_project(opts)
  end)
end

local function collect_package(opts)
  input("Package: ", opts.package_name, function(package_name)
    if not package_name then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end
    if not is_valid_java_package(package_name) then
      notify("Invalid Java package: " .. package_name, vim.log.levels.ERROR)
      return
    end

    opts.package_name = package_name
    confirm_non_empty(opts)
  end)
end

local function collect_group(opts)
  input("Group id: ", defaults.group_id, function(group_id)
    if not group_id then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end
    if not is_valid_java_package(group_id) then
      notify("Invalid group id: " .. group_id, vim.log.levels.ERROR)
      return
    end

    opts.group_id = group_id
    opts.package_name = group_id .. "." .. opts.artifact_id:gsub("[^A-Za-z0-9_$]", "")
    collect_package(opts)
  end)
end

local function collect_artifact(opts)
  input("Artifact id: ", defaults.artifact_id, function(artifact_id)
    if not artifact_id then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end

    opts.artifact_id = sanitize_artifact(artifact_id)
    collect_group(opts)
  end)
end

local function collect_root(opts)
  input("Project directory: ", opts.root, function(root)
    root = normalize_path(root)
    if not root then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end

    opts.root = root
    opts.artifact_id = sanitize_artifact(vim.fs.basename(root) or defaults.artifact_id)
    collect_artifact(opts)
  end)
end

function M.create(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})
  opts.root = normalize_path(opts.root)

  if opts.root and opts.build_tool and opts.group_id and opts.artifact_id and opts.package_name then
    confirm_non_empty(opts)
    return
  end

  select_build_tool(function(build_tool)
    if not build_tool then
      notify("Cancelled", vim.log.levels.WARN)
      return
    end

    opts.build_tool = build_tool
    opts.root = opts.root or normalize_path(vim.fn.getcwd() .. "/" .. defaults.artifact_id)
    collect_root(opts)
  end)
end

function M.register_commands()
  vim.api.nvim_create_user_command("JavaInitProject", function(args)
    M.create({
      root = args.args ~= "" and args.args or nil,
    })
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Create a small Maven/Gradle Java project",
  })
end

return M
