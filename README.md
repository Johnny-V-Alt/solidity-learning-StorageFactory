# Solidity Learning: StorageFactory

Solidity 学习项目，记录从 SimpleStorage 到 StorageFactory，再到 AddFiveStorage 的学习过程。

每个合约单独一个文件夹，分别保存源码与对应笔记。

## 学习顺序

1. **SimpleStorage**：合约类型、变量、合约实例与基本调用。
2. **StorageFactory**：部署合约、动态数组、跨合约调用与返回值。
3. **AddFiveStorage**：继承、函数重写、`virtual`、`override` 与 `super`。

## 项目结构

以下为项目的组织结构；文件添加进度以仓库实际内容为准。

```text
.
├── README.md
├── simple-storage/
│   ├── SimpleStorage.sol
│   └── notes.md
├── storage-factory/
│   ├── StorageFactory.sol
│   └── notes.md
└── add-five-storage/
    ├── AddFiveStorage.sol
    └── notes.md
```

## 学习笔记

- [SimpleStorage 笔记](simple-storage/notes.md)
- [StorageFactory 笔记](storage-factory/notes.md)
- [AddFiveStorage 笔记](add-five-storage/notes.md)

## 开发环境与导入路径

学习过程中使用 Remix 编写、编译和部署合约，使用 GitHub 保存源码和笔记。

由于各合约位于不同文件夹，StorageFactory 和 AddFiveStorage 引用 SimpleStorage 时，路径需要与目录结构一致：

```solidity
import {SimpleStorage} from "../simple-storage/SimpleStorage.sol";
```

该路径以本文所列结构和文件名为前提。实际编译时，也需要保留对应目录关系。
