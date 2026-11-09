# SimpleStorage：保存数字与人员信息

## 目录

1. [这个合约做什么](#1-这个合约做什么)
2. [保存和读取一个数字](#2-保存和读取一个数字)
3. [用结构体表示一个人](#3-用结构体表示一个人)
4. [用数组保存多人](#4-用数组保存多人)
5. [用映射按名字查数字](#5-用映射按名字查数字)
6. [addPerson 的完整过程](#6-addperson-的完整过程)
7. [容易混淆的地方](#7-容易混淆的地方)

## 1. 这个合约做什么

源码：[SimpleStorage.sol](SimpleStorage.sol)

合约有两组功能：

| 功能 | 保存位置 | 写入入口 | 读取入口 |
|---|---|---|---|
| 保存一个数字 | `myFavoriteNumber` | `store()` | `retrieve()` |
| 保存人员信息 | `listOfPeople`、`nameToFavoriteNumber` | `addPerson()` | 自动生成的公开读取函数 |

这两组数据相互独立。调用 `addPerson()` 不会修改 `myFavoriteNumber`；调用 `store()` 也不会修改人员记录。

本笔记根据当前源码解释行为，示例结果为代码推导，未进行编译或运行验证。

## 2. 保存和读取一个数字

### 保存位置：状态变量

```solidity
uint256 myFavoriteNumber;
```

这是状态变量（state variable），用来保存合约中的数字。

`uint256` 表示 256 位无符号整数，只能表示非负整数。未赋值时，它的默认值为 `0`。

### 写入：store

```solidity
function store(uint256 _favoriteNumber) public virtual {
    myFavoriteNumber = _favoriteNumber;
}
```

调用 `store(99)` 时：

```text
参数 _favoriteNumber 得到 99
            ↓
执行 myFavoriteNumber = _favoriteNumber
            ↓
合约保存的数字变成 99
```

- `_favoriteNumber` 是本次调用传进来的参数。
- `myFavoriteNumber` 是合约中保存数据的变量。
- `public` 让该函数可以被外部调用。
- `virtual` 允许派生合约重写它，后续 AddFiveStorage 会用到。

源码中的 `//+5` 只是注释。实际执行的赋值没有加 5，建议删除这个误导性注释。

### 读取：retrieve

```solidity
function retrieve() public view returns (uint256) {
    return myFavoriteNumber;
}
```

- `view`：函数不修改状态。
- `returns (uint256)`：声明返回一个无符号整数。
- `return myFavoriteNumber`：把当前保存的数字交给调用者。

按代码推导：调用 `store(99)` 后，再调用 `retrieve()`，应读到 `99`，前提是期间没有其他调用修改该值。

## 3. 用结构体表示一个人

```solidity
struct Person {
    uint256 favoriteNumber;
    string name;
}
```

结构体（struct）把相关字段组合成一种类型。

这里，一个 `Person` 包含：

- `favoriteNumber`：这个人喜欢的数字。
- `name`：这个人的名字。

例如：

```solidity
Person(7, "Alice")
```

表示名字为 Alice、喜欢数字 7 的一条人员记录。

参数顺序对应结构体字段的声明顺序：先数字，后名字。

声明结构体只是定义数据的组织方式，不会自动添加任何人员记录。

## 4. 用数组保存多人

```solidity
Person[] public listOfPeople;
```

`Person[]` 是元素类型为 `Person` 的动态数组（dynamic array）。

可以把它理解为按顺序排列的人员列表：

```text
索引 0 → Alice，7
索引 1 → Bob，12
```

数组索引从 `0` 开始。

`public` 会生成读取入口。例如，在 Remix 中向 `listOfPeople` 的读取入口输入 `0`，可以读取第一个元素的字段。它不是一次返回整个数组。

## 5. 用映射按名字查数字

```solidity
mapping(string => uint256) public nameToFavoriteNumber;
```

映射（mapping）建立“名字 → 数字”的对应关系：

```text
"Alice" → 7
"Bob"   → 12
```

与数组的区别：

| 数据结构 | 查找依据 | 本项目中的用途 |
|---|---|---|
| 数组 `listOfPeople` | 索引，例如 `0` | 按位置读取人员记录 |
| 映射 `nameToFavoriteNumber` | 名字，例如 `"Alice"` | 按名字查询喜欢的数字 |

对于尚未写入的名字，映射读取结果为 `0`。因此，单凭结果为 `0`，不能判断这个名字不存在，还是它对应的数字本来就是 `0`。

## 6. addPerson 的完整过程

```solidity
function addPerson(string memory _name, uint256 _favoriteNumber) public {
    listOfPeople.push(Person(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
}
```

调用示例：

```text
addPerson("Alice", 7)
```

函数做两件事：

1. 创建 `Person(7, "Alice")`，追加到数组末尾。
2. 在映射中保存 `"Alice" → 7`。

`push()` 表示向动态数组末尾追加元素。

`string memory _name` 中的 `memory` 指定这个字符串参数在调用期间使用的临时数据位置，不表示名字不能被保存到状态变量中。

### 同名记录会怎样

再次调用：

```text
addPerson("Alice", 9)
```

按代码推导：

- 数组会追加另一条 Alice 的记录。
- 映射中 Alice 对应的数字会更新为 `9`。

原因是数组使用 `push()` 追加，而映射使用赋值更新同一个键。源码没有禁止重名。

## 7. 容易混淆的地方

### 把两个数字当成同一个变量

**误解 →** `store(99)` 后，所有人的 `favoriteNumber` 都变成 99。

**原因 →** 混淆了合约的 `myFavoriteNumber` 和结构体字段 `favoriteNumber`。

**修正 →** 它们是不同的保存位置，分别由不同函数修改。

### 认为 myFavoriteNumber 没有 public 就无法读取

**误解 →** 没有自动生成的读取按钮，所以变量不能读取。

**原因 →** 混淆变量的直接访问与函数提供的读取入口。

**修正 →** 当前合约通过 `retrieve()` 返回这个变量。

`myFavoriteNumber` 没有显式声明可见性，默认是 `internal`：当前合约和派生合约可以在代码内部访问它。

### 将注释当成执行逻辑

**误解 →** 看到 `//+5`，就认为 SimpleStorage 保存时会加 5。

**原因 →** 注释描述与实际赋值不一致。

**修正 →** 以执行语句为准，删除不准确的注释。加 5 的逻辑位于 AddFiveStorage。
