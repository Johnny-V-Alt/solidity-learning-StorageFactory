# AddFiveStorage：继承并修改保存规则

## 目录

1. [这个合约做什么](#1-这个合约做什么)
2. [导入与继承](#2-导入与继承)
3. [virtual 与 override](#3-virtual-与-override)
4. [实际代码如何加-5](#4-实际代码如何加-5)
5. [继承与工厂调用的区别](#5-继承与工厂调用的区别)
6. [补充理解-super](#6-补充理解-super)
7. [常见错误](#7-常见错误)

## 1. 这个合约做什么

源码：[AddFiveStorage.sol](AddFiveStorage.sol)

SimpleStorage 的保存规则是：

```text
传入 10 → 保存 10
```

AddFiveStorage 继承 SimpleStorage，并重写 `store()`：

```text
传入 10 → 加 5 → 保存 15
```

它沿用父合约的读取功能，不需要再写一份 `retrieve()`。

以上是根据源码推导的行为，未进行编译或运行验证。

## 2. 导入与继承

### 导入：让代码能够使用 SimpleStorage 类型

当前源码的导入路径是：

```solidity
import {SimpleStorage} from "./simpleStorage.sol";
```

它与当前仓库目录不匹配。按仓库实际结构，应调整为：

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

### 继承：使用 is 声明父合约

```solidity
contract AddFiveStorage is SimpleStorage {
    // 派生合约的内容
}
```

- `SimpleStorage` 是父合约（base contract）。
- `AddFiveStorage` 是派生合约（derived contract）。
- `is SimpleStorage` 声明继承关系。

`import` 和 `is` 负责不同的事情：导入符号之后，还需要显式声明继承。

## 3. virtual 与 override

父合约的函数：

```solidity
function store(uint256 _favoriteNumber) public virtual {
    myFavoriteNumber = _favoriteNumber;
}
```

派生合约的函数：

```solidity
function store(uint256 _NewNumber) public override {
    myFavoriteNumber = _NewNumber + 5;
}
```

这两个片段分别属于两个合约。

| 关键词 | 所在位置 | 本项目中的含义 |
|---|---|---|
| `virtual` | SimpleStorage 的 `store()` | 允许派生合约修改实现 |
| `override` | AddFiveStorage 的 `store()` | 声明这里提供重写实现 |

两个函数的参数名不同，但参数类型都是 `uint256`。参数名不必相同。

## 4. 实际代码如何加 5

当前源码直接执行：

```solidity
myFavoriteNumber = _NewNumber + 5;
```

调用 `store(10)` 时：

1. `_NewNumber` 得到 `10`。
2. 计算 `10 + 5`。
3. 将 `15` 写入 `myFavoriteNumber`。

### 为什么能访问父合约中声明的变量

父合约中：

```solidity
uint256 myFavoriteNumber;
```

该状态变量没有显式声明可见性，默认是 `internal`，因此派生合约可以在代码内部访问它。

### 为什么不需要重写 retrieve

父合约已经提供：

```solidity
function retrieve() public view returns (uint256) {
    return myFavoriteNumber;
}
```

AddFiveStorage 继承这个函数。它读取的是当前 AddFiveStorage 实例中的 `myFavoriteNumber`。

按代码推导：对同一个 AddFiveStorage 实例调用 `store(10)` 后，再调用 `retrieve()`，应得到 `15`。

## 5. 继承与工厂调用的区别

| 情况 | 实际发生的事情 |
|---|---|
| StorageFactory 执行 `new SimpleStorage()` | 部署另一个有独立地址的合约实例 |
| StorageFactory 调用目标的 `store()` | 调用另一个实例的函数 |
| AddFiveStorage 继承 SimpleStorage | 在派生合约中获得父级定义的变量和函数 |

部署 AddFiveStorage 不需要先部署一个独立的 SimpleStorage。

AddFiveStorage 使用继承得到的变量时，修改的是自身实例的状态，不是某个另外部署的 SimpleStorage 实例。

另外，当前 StorageFactory 创建的是 SimpleStorage，因此通过该工厂写入数字不会自动应用 AddFiveStorage 的加 5 规则。

## 6. 补充理解 super

当前源码没有使用 `super`，而是直接给变量赋值。

学习中还讨论过另一种实现方式：

```solidity
function store(uint256 _NewNumber) public override {
    super.store(_NewNumber + 5);
}
```

这里先计算加 5 的结果，再调用父级 `store()` 的实现。

两种方式的区别：

| 写法 | 谁执行最终赋值 |
|---|---|
| `myFavoriteNumber = _NewNumber + 5;` | 派生合约直接赋值 |
| `super.store(_NewNumber + 5);` | 交给父级函数赋值 |

根据当前父级函数只有一次直接赋值的实现，两种方式对保存数字的效果相同。

如果以后父级函数增加其他逻辑，两种方式可能出现差别。因此，不能把“直接赋值”与“调用父级函数”在所有情况下都当作等价操作。

这个补充片段不是当前源码，也没有进行编译或运行验证。

## 7. 常见错误

### 只 import，没有声明继承

**错误 →**

```solidity
contract AddFiveStorage {}
```

却希望使用父合约变量或重写父合约函数。

**原因 →** 导入不会自动建立继承关系。

**修正 →**

```solidity
contract AddFiveStorage is SimpleStorage {
    // ...
}
```

### 函数缺少可见性

**错误 →**

```solidity
function store(uint256 _NewNumber) {}
```

**材料中的诊断 →**

```text
SyntaxError: No visibility specified. Did you intend to add "public"?
```

**原因 →** 函数没有声明可见性。

**修正 →** 本项目的重写函数使用 `public override`。

### 重写函数缺少 override

**材料中的诊断 →**

```text
TypeError: Overriding function is missing "override" specifier.
```

**原因 →** 编译器识别到重写，但没有对应标记。

**修正 →**

```solidity
function store(uint256 _NewNumber) public override {
    myFavoriteNumber = _NewNumber + 5;
}
```

当前父级源码已经声明 `virtual`，当前派生源码也已经声明 `override`。

### 空函数体不保存数字

**错误理解 →**

```solidity
function store(uint256 _NewNumber) public override {}
```

会自动执行父级保存逻辑。

**原因 →** 混淆了继承函数与重写函数。

**修正 →** 重写后使用新函数体。需要保存数字时，应在函数体中明确赋值或调用父级实现；空函数体不会自动执行父级 `store()`。

### 导入路径不匹配

**错误 →** 当前使用 `"./simpleStorage.sol"`。

**原因 →** 目标文件实际位于兄弟目录，且文件名为 `SimpleStorage.sol`。

**修正 →**

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

修正后的完整编译结果尚未验证。
