+++
date = '2025-05-29T18:05:21+08:00'
draft = true
title = 'ArrayBuffer'
+++

## 引子

对`ArrayBuffer`的关注，始于一次面试。那次面试，聊到Web Worker，被问到使用`Worker`是否一定能提升性能。

回答自然是否，一是`Worker`和主线程之间有通信开销，二是因为`Worker`本身是一个线程，创建新线程本身也有成本，三是增加了开发的调试成本。

然后被问到，通信开销具体有哪些。

答曰，主线程和`Worker`之间通过`postMessage`和`onmessage`来传递消息，每次消息传递都会深拷贝一份数据（所谓结构化克隆 | Structured Clone）。如果传递的数据量很大时（几十MB甚至更大），克隆的成本很高。

然后被问到，有什么办法可以规避吗。

...我表示不知道。

然后面试官很nice地告诉我，可以用`ArrayBuffer`来存储需要传递的数据，这样数据就可以被`转移`而非`拷贝`。

不知道多少人和我一样，对`ArrayBuffer`几乎可以说一无所知，作为前端开发，平时很少有机会和二进制、内存打交道。于是下来特意查了下，就有了这篇文章。

## What is ArrayBuffer

MDN上是这么说的

> `ArrayBuffer`对象用来表示通用的原始二进制数据缓冲区。

> 它是一个字节数组，通常在其他语言中称为`byte array`。你不能直接操作`ArrayBuffer`中的内容；而要通过类型化数组对象或`DataView`对象来操作，它们会将缓冲区中的数据表示为特定的格式，并通过这些格式来读写缓冲区的内容。

> **`ArrayBuffer` 是一个可转移对象**。

> ArrayBuffer 对象可以在初始化时传入 `maxByteLength`选项使其大小可变，通过`resize()`为可变`ArrayBuffer`分配一个新的大小。

> ArrayBuffer 实例可以在不同的执行上下文之间传输，通过在调用`postMessage`时传入`ArrayBuffer对象`作为`可转移对象`来完成。

> 当ArrayBuffer对象被传输时，它原来的副本会被`detached`，不再可用。可以通过`detached`属性检查`ArrayBuffer`是否已分离。

## A Real Scene

让我们来搭一个舞台，看一下ArrayBuffer在实际场景中的用法。

