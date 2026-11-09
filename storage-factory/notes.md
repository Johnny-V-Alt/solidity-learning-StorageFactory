# StorageFactory 学习笔记

## 范围与验证状态

本笔记整理合约创建、动态数组、合约引用、跨合约调用和返回值，以及相关错误。
## 目录

1. [创建合约与保存引用](#1-创建合约与保存引用)
2. [动态数组](#2-动态数组)
3. [从数组选择已有合约](#3-从数组选择已有合约)
4. [跨合约写入](#4-跨合约写入)
5. [读取与返回值](#5-读取与返回值)
6. [导入与文件路径](#6-导入与文件路径)
7. [常见错误与排查](#7-常见错误与排查)
8. [待核实事项](#8-待核实事项)

## 1. 创建合约与保存引用

### 1.1 声明不等于部署

状态变量声明：

```solidity
SimpleStorage public mystorage;
```

它声明一个保存合约引用（contract reference）的变量，没有创建新合约。尚未赋值时，对应零地址。

函数体内的部署语句：

```solidity
mystorage = new SimpleStorage();
```

分成两步理解：

```text
new SimpleStorage() → 部署新合约，得到引用
mystorage = ...     → 保存引用
```

新合约拥有自己的地址与存储（storage），变量中没有保存整份合约代码或全部数据。

### 1.2 单个变量只保存当前引用

反复执行：

```solidity
mystorage = new SimpleStorage();
```

会产生不同实例（instances）：

```text
第一次 → mystorage 指向 A
第二次 → mystorage 指向 B
第三次 → mystorage 指向 C
```

A、B 不会因为变量重新赋值而消失；只是变量当前仅保存 C 的引用。

要记录多次创建的实例，可以使用数组。

### 1.3 public getter

对于：

```solidity
SimpleStorage public mystorage;
```

编译器会生成读取函数（getter）。外部调用 `mystorage()`，可以读取保存的合约地址。

它不会自动把目标合约的 `store()` 等函数变成工厂合约自己的函数。

材料记录过 getter 返回非零地址，但没有提供该地址上代码的独立检查。部署地址不需要与教程一致。

## 2. 动态数组

### 2.1 数组声明

```solidity
SimpleStorage[] public ListOfmystorage;
```

| 部分 | 含义 |
|---|---|
| `SimpleStorage` | 单个合约引用的类型 |
| `SimpleStorage[]` | 保存此类引用的动态数组（dynamic array） |
| `ListOfmystorage` | 数组变量名 |
| `public` | 编译器生成相应的公开访问函数 |

数组保存的是引用，不会复制各个合约的代码和全部状态。

### 2.2 创建并追加元素

以下函数片段假设所在合约已声明上述数组，并能使用 `SimpleStorage` 类型：

```solidity
function CreateSimpleStorageFactory() public {
    SimpleStorage newStorage = new SimpleStorage();
    ListOfmystorage.push(newStorage);
}
```

执行顺序：

1. `new SimpleStorage()` 部署新合约。
2. 局部变量（local variable）`newStorage` 保存引用。
3. `push(newStorage)` 将引用追加到数组末尾。

`newStorage` 是中间变量，它保存的值被作为实参传给 `push()`；变量本身不是形参。

可以省略中间变量：

```solidity
ListOfmystorage.push(new SimpleStorage());
```

函数结束后，局部变量不再保留，但新合约仍存在，数组也已经保存了引用。

## 3. 从数组选择已有合约

```solidity
SimpleStorage mySimpleStorage =
    ListOfmystorage[_simpleStorageIndex];
```

| 部分 | 含义 |
|---|---|
| `SimpleStorage` | 新变量的合约类型（contract type） |
| `mySimpleStorage` | 新声明的变量名 |
| `ListOfmystorage` | 合约引用数组 |
| `[_simpleStorageIndex]` | 按索引读取元素 |
| `=` | 将读取的引用赋给变量 |

在函数内部使用时，`mySimpleStorage` 是局部变量。

这行代码不会部署新合约，也不会复制目标合约的代码或状态。

### 3.1 索引从 0 开始

```text
索引：  0    1    2
合约：  A    B    C
```

`ListOfmystorage[1]` 选择第二个合约 B。

如果数组为空或索引越界，访问会导致调用回退（revert）。材料没有展开自定义检查与错误处理。

### 3.2 三种操作的区别

| 操作 | 作用 |
|---|---|
| `new SimpleStorage()` | 部署新合约 |
| `ListOfmystorage.push(newStorage)` | 保存引用到数组 |
| `ListOfmystorage[_simpleStorageIndex]` | 选择数组中已有的引用 |

是否部署新合约取决于是否执行 `new SimpleStorage()`，不能仅根据变量名判断。

## 4. 跨合约写入

以下片段沿用 `ListOfmystorage` 版本，并假设目标合约提供兼容、可从外部调用的 `store` 函数：

```solidity
function sfstore(
    uint _simpleStorageIndex,
    uint _simpleStorageNumber
) public {
    SimpleStorage mySimpleStorage =
        ListOfmystorage[_simpleStorageIndex];

    mySimpleStorage.store(_simpleStorageNumber);
}
```

参数含义：

- `_simpleStorageIndex`：选择哪个合约。
- `_simpleStorageNumber`：传给目标函数的数字。

其他片段使用 `uint256` 声明参数。`uint256` 是 256 位无符号整数类型；参数名前面的 `_` 只是命名方式，没有特殊执行效果。

### 4.1 调用结构

```solidity
mySimpleStorage.store(_simpleStorageNumber);
```

| 部分 | 作用 |
|---|---|
| `mySimpleStorage` | 指定目标合约 |
| `.` | 访问成员 |
| `store` | 函数名 |
| `(_simpleStorageNumber)` | 调用函数并传入参数 |

例如，`sfstore(1, 99)` 在第二个合约存在的前提下，会调用它的 `store(99)`。

具体如何保存数字，由目标 `store` 的实现决定。

仅取得引用：

```solidity
SimpleStorage mySimpleStorage =
    ListOfmystorage[_simpleStorageIndex];
```

不会自动把 `_simpleStorageNumber` 保存到目标合约。

### 4.2 引用已有地址

```solidity
mystorage = SimpleStorage(existingAddress);
```

将已有地址转换为 `SimpleStorage` 类型，并保存引用。

这里的 `existingAddress` 是解释用变量名。这种转换不会部署新合约，也不会自动验证目标地址上存在符合预期的合约。

## 5. 读取与返回值

### 5.1 写入和读取是不同操作

材料中的 `sfstore` 没有返回数字。

- 写入函数负责修改状态。
- 读取函数负责返回当前值。

可以在工厂中另外提供读取入口。这不意味着更新后的值无法读取，也不意味着只能通过工厂读取；可用入口取决于合约接口。

### 5.2 读取函数示例

以下片段保留另一版本中的数组名 `listOfmystorageContracts`，假设该数组已经声明，并且目标合约提供兼容的 `retrieve()`：

```solidity
function sfGet(uint256 _simpleStorageIndex)
    public
    view
    returns (uint256)
{
    SimpleStorage mySimpleStorage =
        listOfmystorageContracts[_simpleStorageIndex];

    return mySimpleStorage.retrieve();
}
```

| 写法 | 作用 |
|---|---|
| `view` | 声明函数不修改链上状态 |
| `returns (uint256)` | 声明返回值类型 |
| `retrieve()` | 调用目标合约的读取函数 |
| `return` | 将结果返回给当前函数的调用者 |

`sfGet` 是示例函数名。该片段不能与使用另一数组名的代码直接拼接。

如果 `store` 和 `retrieve` 操作同一个保存值，写入成功且状态未被其他操作改变，那么写入 `99` 后读取同一实例，应得到 `99`。材料没有提供这一过程的实际运行结果。

### 5.3 return 后面可以是函数调用

```solidity
return mySimpleStorage.retrieve();
```

执行过程：

1. 调用目标合约的 `retrieve()`。
2. 得到返回值。
3. 将该值返回给当前函数的调用者。

可以拆开理解：

```solidity
uint256 number = mySimpleStorage.retrieve();
return number;
```

在这里，两种写法具有相同的返回逻辑。

C 和 Solidity 的 `return` 后面都可以使用类型适当的表达式，包括变量、计算和函数调用，并非只能写变量名。

## 6. 导入与文件路径

如果目标文件名为 `SimpleStorage.sol`，且与当前源文件位于同一目录：

```solidity
import {SimpleStorage} from "./SimpleStorage.sol";
```

| 部分 | 需要匹配的内容 |
|---|---|
| `{SimpleStorage}` | 被导入文件中的符号名 |
| `"./SimpleStorage.sol"` | 实际文件路径 |
| `./` | 当前源文件所在目录 |

文件名与合约名可以不同，但必须分别匹配。

**待核实：** 原始材料同时出现 `SimpleStorage.sol` 和 `"./simpleStorage.sol"`。当时实际文件名与目录未确认，不能直接认定其中一个版本正确。

本仓库采用每个合约单独一个文件夹的结构。位于 `storage-factory/` 的源码如果需要导入兄弟目录中的 `SimpleStorage.sol`，相对路径应对应为：

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

`../` 表示返回上一级目录。这是根据当前目录结构给出的路径调整，尚未提供编译验证；也不应在添加源码时忽略原文件中的导入方式。

## 7. 常见错误与排查

### 7.1 new 缺少括号

**错误：**

```solidity
mystorage = new SimpleStorage;
```

**原因：** 缺少调用括号，即使没有构造参数也需要 `()`。

**修正：**

```solidity
mystorage = new SimpleStorage();
```

材料没有提供该错误的编译器诊断原文。

### 7.2 将单个引用赋给整个数组

**错误：**

```solidity
ListOfmystorage = new SimpleStorage();
```

**原因：** 左边是 `SimpleStorage[]`，右边是单个 `SimpleStorage`，类型不匹配。

**修正：**

```solidity
SimpleStorage newStorage = new SimpleStorage();
ListOfmystorage.push(newStorage);
```

### 7.3 名称与声明不一致

Solidity 标识符区分大小写（case-sensitive）。

| 错误写法 | 原因 | 按对应声明修正 |
|---|---|---|
| `listOfStorageContract` | 数组名不同 | `ListOfmystorage` |
| `ListOfmyStorage` | `S` 大小写不同 | `ListOfmystorage` |
| `_SimpleStorageUndex` | 参数名拼写及大小写不同 | `_simpleStorageIndex` |
| `listOfSimpleStorageContract` | 与另一版本的声明不同 | `listOfmystorageContracts` |

另一个错误片段：

```solidity
SimpleStorage newStorage = new SimpleStorage();
listOfmystorageContracts.push(newSimpleStorageContract);
```

**原因：** 声明的是 `newStorage`，使用的却是另一个名称。

**修正：**

```solidity
SimpleStorage newStorage = new SimpleStorage();
listOfmystorageContracts.push(newStorage);
```

教师示例可以使用不同名称，但自己代码中的声明和引用必须一致。

### 7.4 函数调用多出句点、缺少分号

**错误：**

```solidity
mySimpleStorage.store.(_simpleStorageNumber)
```

**原因：** 函数名后多了 `.`，语句末尾缺少 `;`。

**修正：**

```solidity
mySimpleStorage.store(_simpleStorageNumber);
```

另一份材料中的数组赋值文本也没有结尾分号。

**待核实：** 只能确认粘贴文本缺少分号，不能据此断定实际源文件也缺失，或曾因此编译失败。

### 7.5 导入符号拼写错误

**错误：**

```solidity
import {SimmpleStorage} from "./SimpleStorage.sol";
```

**原因：** 如果目标符号是 `SimpleStorage`，`SimmpleStorage` 就是不同名称。

**修正：** 将符号改为 `SimpleStorage`，并独立核对实际文件路径。

### 7.6 文件解析失败

材料提供的诊断：

```text
Dependency resolution failed: File not found: SimpleStorage.sol
Could not resolve package version for "SimpleStorage.sol". Package may not exist or version could not be determined.
```

**已确认：** 工具无法找到或解析目标文件。

**待核实：** 当时究竟是文件名、大小写、目录、路径还是编辑环境造成，材料没有最终结论。

**排查顺序：**

1. 核对实际文件名与扩展名。
2. 核对文件所在目录。
3. 核对导入路径与大小写。
4. 重新编译，查看完整诊断。

不能仅因诊断出现 `package`，就认定需要安装名为 `SimpleStorage.sol` 的软件包。

### 7.7 Remix 中混淆文件名与合约名

一个 `.sol` 文件可以定义多个合约。

材料中的卡片显示：

```text
SimpleStorage
StorageFactory.sol
```

不能仅凭文件名认定当前选中的是 `StorageFactory`。

| 项目 | 含义 |
|---|---|
| 源文件名 | 代码所在文件 |
| 合约名 | 文件中的合约定义 |
| 待部署合约 | 本次准备部署的合约定义 |
| 已部署合约 | 已有地址的合约实例 |

- `Deploy`：部署合约。
- `Deployed Contracts`：查看和操作已部署实例。
- 当时的 `⋮` 菜单包含 `Copy ABI`、`Save ABI`、`Copy Bytecode`，不是教程中的合约选择菜单。

**待核实：** “点击合约卡片或名称打开选择列表”没有得到明确确认。找不到合约是否由编译问题造成，也没有最终证据。

### 7.8 注释与诊断位置

许可证注释推荐格式：

```solidity
// SPDX-License-Identifier: MIT
```

注释不会作为程序语句执行，但工具可以读取其中的特定信息。

材料曾出现不带空格的格式，但没有证据证明少空格就是标红原因。后来提供的实际诊断是依赖解析失败，应根据诊断内容排查，不能只看红线位置。

ABI 全称是 **Application Binary Interface**。`Appliction` 是拼写错误，但注释拼写不会改变程序执行。

中文逗号 `，` 如果实际出现在 Solidity 语法中会造成问题；如果只是提问标点，则与编译无关。
