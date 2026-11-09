# SimpleStorage 学习笔记

## 范围与验证状态

本笔记整理材料中涉及的合约类型、变量、合约引用、部署和读取入口。

## 1. 合约类型与变量名

```solidity
SimpleStorage public mystorage;
```

| 部分 | 含义 |
|---|---|
| `SimpleStorage` | 合约类型（contract type） |
| `public` | 可见性（visibility） |
| `mystorage` | 变量名（variable name） |

与普通整数变量对照：

```solidity
uint256 public favoriteNumber;
```

定义 `contract SimpleStorage` 后，`SimpleStorage` 就可以作为类型使用。

`mystorage` 保存合约引用（contract reference），可以理解为带有合约类型信息的地址。它没有保存整份合约代码或全部状态数据。

## 2. 标识符区分大小写

Solidity 区分大小写（case-sensitive）：

```text
SimpleStorage
simpleStorage
simplestorage
```

以上是不同标识符，不能混用。

合约名通常大写开头，变量名通常小写开头，这是命名惯例。变量可以换名，但声明和后续使用必须一致。

材料中出现过 `simpleStorage`、`mystorage`、`myStorage` 等名称，它们属于不同示例，不能直接视为同一个变量。

## 3. 声明不等于部署

声明状态变量（state variable）：

```solidity
SimpleStorage public mystorage;
```

这里只声明用于保存合约引用的变量，没有创建新合约。尚未赋值时，对应零地址。

在函数体内部署新合约：

```solidity
mystorage = new SimpleStorage();
```

可以分成两步理解：

```text
new SimpleStorage() → 部署新合约，得到引用
mystorage = ...     → 将引用保存到变量
```

新实例（instance）有自己的地址与存储（storage）。部署时执行初始化代码，包括构造函数（constructor，如果有）。

以上是不同位置的代码片段，不是完整合约。

## 4. 部署与调用的区别

部署：

```solidity
mystorage = new SimpleStorage();
```

调用已有实例的函数：

```solidity
mystorage.store(123);
```

第二行以目标合约提供兼容、可调用的 `store` 函数为前提。它调用已有合约，不会再次部署合约。

具体如何保存数字取决于 `store` 的实际实现，材料没有完整展示该实现。

## 5. public 与 getter

```solidity
SimpleStorage public mystorage;
```

编译器会为这个公开状态变量生成读取函数（getter）。

外部调用 `mystorage()`，可以读取它保存的合约地址。这不会自动把目标合约的 `store()` 等函数变成当前合约自己的函数。

材料记录了 getter 返回非零地址。结合创建代码，可以将其理解为新合约地址，但材料没有提供该地址上代码的独立检查。

部署地址不需要与教程一致。

## 6. 常见错误

### 6.1 创建合约缺少括号

**错误：**

```solidity
mystorage = new SimpleStorage;
```

**原因：** 创建合约时缺少调用括号，即使没有构造参数也需要 `()`。

**修正：**

```solidity
mystorage = new SimpleStorage();
```

材料记录了红色波浪线，没有提供该错误的编译器诊断原文，也没有提供修正后的完整编译结果。

### 6.2 类型名与变量名混淆

**误解：** `SimpleStorage` 和 `mystorage` 都是合约名称。

**原因：** 没有区分类型与变量。

**修正理解：**

- `SimpleStorage` 指定变量的合约类型。
- `mystorage` 是保存某个合约引用的变量名。
- 新合约由 `new SimpleStorage()` 创建，不由变量名决定。
