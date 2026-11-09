# StorageFactory：创建并操作多个 SimpleStorage

## 目录

1. [这个合约做什么](#1-这个合约做什么)
2. [导入 SimpleStorage](#2-导入-simplestorage)
3. [用数组记录合约](#3-用数组记录合约)
4. [创建一个新合约](#4-创建一个新合约)
5. [向指定合约写入数字](#5-向指定合约写入数字)
6. [从指定合约读取数字](#6-从指定合约读取数字)
7. [串起整个过程](#7-串起整个过程)
8. [常见错误](#8-常见错误)

## 1. 这个合约做什么

源码：[StorageFactory.sol](StorageFactory.sol)

SimpleStorage 负责保存数据，StorageFactory 负责创建多个 SimpleStorage，并提供选择和调用它们的入口。

```text
StorageFactory
    ├── 数组第 0 项 → SimpleStorage A
    └── 数组第 1 项 → SimpleStorage B
```

A、B 使用相同的合约定义，但各有自己的地址和数据。

StorageFactory 当前创建的是 SimpleStorage，不是 AddFiveStorage。

本笔记使用当前源码中的实际名称。示例结果为代码推导，未进行编译或运行验证。

## 2. 导入 SimpleStorage

当前源码使用：

```solidity
import {SimpleStorage} from "./simpleStorage.sol";
```

但目标文件实际位于：

```text
simple-storage/SimpleStorage.sol
```

从当前 `storage-factory/` 目录出发，应调整为：

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

- `{SimpleStorage}`：需要使用的合约类型名。
- `../`：回到仓库根目录。
- `simple-storage/SimpleStorage.sol`：进入目标目录并找到文件。

当前源码的导入路径与仓库文件位置不匹配。修正路径后的编译结果尚未验证。

## 3. 用数组记录合约

```solidity
SimpleStorage[] public listOfmystorageContracts;
```

从左到右理解：

| 部分 | 含义 |
|---|---|
| `SimpleStorage` | 合约类型 |
| `[]` | 表示数组 |
| `public` | 生成公开读取入口 |
| `listOfmystorageContracts` | 数组变量名 |

数组元素保存合约类型的值，包含目标合约的地址信息。它不复制目标合约的代码或全部数据。

索引从 `0` 开始：

```text
listOfmystorageContracts[0] → 第一个合约
listOfmystorageContracts[1] → 第二个合约
```

在数组公开读取入口中输入索引，可以读到对应合约的地址。

## 4. 创建一个新合约

```solidity
function CreateSimpleStorageFactory() public {
    SimpleStorage newStorage = new SimpleStorage();
    listOfmystorageContracts.push(newStorage);
}
```

虽然函数名里有 `Factory`，但函数体实际创建的是 SimpleStorage。阅读函数时，应同时看名称和执行语句。

### 第一步：部署

```solidity
SimpleStorage newStorage = new SimpleStorage();
```

- 左边 `SimpleStorage`：局部变量的类型。
- `newStorage`：局部变量名。
- 右边 `new SimpleStorage()`：部署新合约并返回引用。

### 第二步：记录地址

```solidity
listOfmystorageContracts.push(newStorage);
```

`push()` 把新合约的引用追加到数组末尾。

局部变量 `newStorage` 在函数结束后不再保留，但数组已经保存了引用，新合约也继续存在。

每成功调用一次创建函数，就会多创建一个 SimpleStorage，并往数组追加一项。

## 5. 向指定合约写入数字

```solidity
function sfstore(
    uint256 _simpleStorageIndex,
    uint256 _simpleStorageNumber
) public {
    SimpleStorage mySimpleStorage =
        listOfmystorageContracts[_simpleStorageIndex];

    mySimpleStorage.store(_simpleStorageNumber);
}
```

两个参数各负责一件事：

| 参数 | 作用 | 示例 |
|---|---|---|
| `_simpleStorageIndex` | 选择哪个合约 | `1` 表示第二个 |
| `_simpleStorageNumber` | 保存什么数字 | `99` |

### 选择目标

```solidity
SimpleStorage mySimpleStorage =
    listOfmystorageContracts[_simpleStorageIndex];
```

从数组中取出已有合约的引用，保存到局部变量 `mySimpleStorage`。

这一步没有部署新合约，也没有写入数字。

### 调用目标

```solidity
mySimpleStorage.store(_simpleStorageNumber);
```

调用选中合约的 `store()`，传入要保存的数字。

写入位置是目标 SimpleStorage 的 `myFavoriteNumber`，不是 StorageFactory 自己的某个数字变量。

## 6. 从指定合约读取数字

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

执行顺序：

1. 根据索引找到目标合约。
2. 调用目标合约的 `retrieve()`。
3. 把得到的数字返回给调用 `sfGet()` 的人。

| 写法 | 作用 |
|---|---|
| `view` | 不修改状态 |
| `returns (uint256)` | 声明函数的返回值类型 |
| `return` | 实际返回一个值 |

### return 后面可以直接写函数调用

```solidity
return mySimpleStorage.retrieve();
```

可以拆成：

```solidity
uint256 number = mySimpleStorage.retrieve();
return number;
```

两种写法在这里具有相同的返回逻辑。

`retrieve` 是函数名，`retrieve()` 才表示调用函数。

## 7. 串起整个过程

假设刚部署工厂，数组还没有元素。

下面是操作顺序与按源码推导的结果，不是实际测试记录：

| 顺序 | 调用 | 结果 |
|---|---|---|
| 1 | `CreateSimpleStorageFactory()` | 创建 A，保存在索引 0 |
| 2 | `CreateSimpleStorageFactory()` | 创建 B，保存在索引 1 |
| 3 | `sfstore(1, 99)` | 将 B 的数字改成 99 |
| 4 | `sfGet(1)` | 应返回 99 |
| 5 | `sfGet(0)` | A 未被写入，应仍为默认值 0 |

由此可以看到：

- 数组索引决定操作哪个实例。
- 写入 B 不会自动修改 A。
- 创建、选择、写入、读取是四个不同步骤。

## 8. 常见错误

### 创建合约少了括号

**错误 →**

```solidity
new SimpleStorage
```

**原因 →** 缺少创建合约所需的调用括号。

**修正 →**

```solidity
new SimpleStorage()
```

### 把单个引用赋给整个数组

**错误 →**

```solidity
listOfmystorageContracts = new SimpleStorage();
```

**原因 →** 左边是数组，右边是单个合约引用，类型不匹配。

**修正 →** 使用 `push()`：

```solidity
listOfmystorageContracts.push(new SimpleStorage());
```

### 变量名与声明不一致

**错误 →** 声明 `newStorage`，后面却使用 `newSimpleStorageContract`；或把数组名写成另一套名称。

**原因 →** Solidity 按完整标识符识别变量，并区分大小写。

**修正 →** 当前源码统一使用：

```text
数组：listOfmystorageContracts
创建时的局部变量：newStorage
调用时的局部变量：mySimpleStorage
索引参数：_simpleStorageIndex
```

### 调用语法错误

**错误 →**

```solidity
mySimpleStorage.store.(_simpleStorageNumber)
```

**原因 →** 多了句点，缺少分号。

**修正 →**

```solidity
mySimpleStorage.store(_simpleStorageNumber);
```

### 使用不存在的索引

**错误 →** 只创建一个合约，就访问索引 `1`。

**原因 →** 一个元素只有索引 `0`；索引越界会导致调用回退（revert）。

**修正 →** 使用已有索引，或先创建足够数量的合约。当前源码没有额外编写索引检查提示。

### 找不到导入文件

**错误 →** 使用当前源码中的 `"./simpleStorage.sol"`。

**原因 →** 文件目录和大小写与仓库实际结构不一致。

**修正 →**

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```
