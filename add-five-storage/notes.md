# AddFiveStorage 学习笔记

## 范围与验证状态

本笔记整理继承（inheritance）、函数重写（override），以及 `virtual`、`override` 和 `super` 的作用。
## 目录

1. [导入与继承](#1-导入与继承)
2. [允许重写与声明重写](#2-允许重写与声明重写)
3. [通过 super 调用父级实现](#3-通过-super-调用父级实现)
4. [常见错误](#4-常见错误)
5. [待核实事项](#5-待核实事项)

## 1. 导入与继承

### 1.1 import 不等于继承

导入语句让当前源文件能够使用目标文件中的符号：

```solidity
import {SimpleStorage} from "./SimpleStorage.sol";
```

这个路径以两个文件位于同一目录为前提。

仅写 `import` 不会建立继承关系：

```solidity
contract AddFiveStorage {}
```

上述声明没有指定父合约。

继承需要使用 `is`：

```solidity
contract AddFiveStorage is SimpleStorage {
    // ...
}
```

这里：

- `SimpleStorage` 是父合约或基类（base contract）。
- `AddFiveStorage` 是派生合约（derived contract）。

### 1.2 当前仓库中的导入路径

当前仓库按合约分目录保存：

```text
simple-storage/
├── SimpleStorage.sol
└── notes.md

add-five-storage/
├── AddFiveStorage.sol
└── notes.md
```

因此，从 `add-five-storage/AddFiveStorage.sol` 引用上述父合约文件时，路径应对应为：

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

`../` 表示返回上一级目录。

这是根据当前目录结构给出的路径调整，尚未提供编译验证。实际使用前仍需确认文件名、大小写和目标符号。

## 2. 允许重写与声明重写

重写是派生合约为继承来的函数提供自己的实现。

材料讨论的是普通合约中已实现函数的重写：

| 关键词 | 使用位置 | 作用 |
|---|---|---|
| `virtual` | 父级函数 | 允许派生合约重写 |
| `override` | 派生合约函数 | 声明正在重写继承的函数 |
| `super` | 派生合约内部 | 访问继承链中的父级实现 |

父级函数片段：

```solidity
function store(uint256 _NewNumber) public virtual {
    // Existing implementation
}
```

注释是占位说明，不包含实际保存逻辑。

派生合约中的重写片段：

```solidity
function store(uint256 _NewNumber) public override {
    // Replacement implementation
}
```

这些片段分别属于父合约和派生合约，不能放在同一个合约中当作完整实现。

## 3. 通过 super 调用父级实现

### 3.1 加 5 后交给父级处理

假设继承关系已经正确声明，父级 `store` 是兼容的 `public virtual` 函数：

```solidity
function store(uint256 _NewNumber) public override {
    super.store(_NewNumber + 5);
}
```

执行过程：

1. 接收 `_NewNumber`。
2. 将它加上 `5`。
3. 把结果传给父级 `store` 实现。

例如传入 `10`，传给父级的参数就是 `15`。

是否以及如何保存该值，仍取决于父级 `store` 的实现。材料没有提供这一示例的实际运行结果。

### 3.2 空函数体不会自动保存参数

```solidity
function store(uint256 _NewNumber) public override {}
```

这个函数接收参数，但函数体没有保存数字的逻辑，也没有调用父级实现。

参数不会因为名为 `_NewNumber` 就自动写入状态。重写函数也不会自动执行被替换的父级函数体。

## 4. 常见错误

### 4.1 函数缺少可见性

**错误片段：**

```solidity
function store(uint256 _NewNumber) {}
```

**实际诊断：**

```text
SyntaxError: No visibility specified. Did you intend to add "public"?
```

**原因：** 没有声明函数可见性（visibility）。

**本次讨论中的修正方向：**

```solidity
function store(uint256 _NewNumber) public {}
```

这一步只处理可见性问题。在重写场景中，还需要满足重写要求。

### 4.2 重写函数缺少 override

**实际诊断：**

```text
TypeError: Overriding function is missing "override" specifier.
```

**原因：** 编译器识别到函数正在重写继承来的函数，但没有 `override`。

**讨论中的修正：**

```solidity
function store(uint256 _NewNumber) public override {}
```

还需要核对：

- 是否正确声明继承关系。
- 父级已实现函数是否标记为 `virtual`。
- 函数签名和可见性是否兼容。

补齐关键词不会让空函数体自动保存数据。

### 4.3 以为导入就完成了继承

**错误理解：** 写了 `import`，`AddFiveStorage` 就自动继承 `SimpleStorage`。

**原因：** 混淆了符号导入与继承声明。

**修正：** 导入正确符号后，还需在合约声明中使用：

```solidity
contract AddFiveStorage is SimpleStorage {
    // ...
}
```

### 4.4 导入符号拼写错误

**错误：**

```solidity
import {SimmpleStorage} from "./SimpleStorage.sol";
```

**原因：** 如果目标合约名是 `SimpleStorage`，`SimmpleStorage` 就是不同标识符。

**修正：** 将导入符号改为 `SimpleStorage`，同时独立核对实际路径。

### 4.5 文件依赖解析失败

材料中出现过：

```text
Dependency resolution failed: File not found: SimpleStorage.sol
Could not resolve package version for "SimpleStorage.sol". Package may not exist or version could not be determined.
```

**已确认：** 工具无法找到或解析导入目标。

**待核实：** 当时究竟是文件名、大小写、目录、路径还是编辑环境导致，材料没有最终结论。

**排查：**

1. 核对目标文件名与扩展名。
2. 核对文件位置。
3. 核对相对路径及大小写。
4. 重新编译并阅读完整诊断。

不能仅因诊断出现 `package`，就认定需要安装名为 `SimpleStorage.sol` 的软件包。

### 4.6 将红线位置直接当作错误原因

许可证注释推荐格式：

```solidity
// SPDX-License-Identifier: MIT
```

注释不作为程序语句执行，但工具能够读取其中的特定信息。

材料曾记录 `MIT` 附近标红，后来提供的实际诊断是文件依赖解析失败。

**修正思路：** 优先阅读诊断内容，不仅根据红线位置判断原因。没有证据证明许可证注释少一个空格就是当时标红的原因。
