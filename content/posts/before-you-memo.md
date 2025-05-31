+++
date = '2025-05-27T16:00:42+08:00'
draft = false
title = 'Before You Memo()'
+++

## 这是一篇译文，原文是Dan Abramov博客上的[同名文章](https://overreacted.io/before-you-memo/)，没有任何商业目的，仅本身兴趣所致。

网上有许多介绍React性能优化的文章，通常来说，如果某些状态更新很慢，你需要：


1. 确保你运行的是生产环境下构建出的产物（开发环境下本身就会更慢，极端情况下甚至会慢一个数级）
2. 确保你没有把组件状态提升到不必要的层级（比如，把input框的状态保存在一个中心化的Store中）
3. 用React开发工具Profiler查看哪些组件在重绘，并用`memo()`包装那些开销最大的子树（并在需要时加上`useMemo()`）


最后一步很烦人，尤其是那些位于中间层的组件。理想情况下，编译器能替你完成这些工作。未来也许会实现的。

在这篇文章中，我想分享两种不同的技巧。他们过于基础，乃至于人们很少意识到他们实实在在地提升了渲染性能。

这两种技巧可以作为你已经知道的那些技巧的补充。他们不会替代`memo` 和`useMemo`，但通常都是可以优先考虑的、不错的尝试。

## 一个人为的慢组件

这是一个有严重性能问题的组件：

```jsx {linenos=inline}
import { useState } from 'react';

export default function App() {
  let [color, setColor] = useState('red');
  return (
    <div>
      <input value={color} onChange={(e) => setColor(e.target.value)} />
      <p style={{ color }}>Hello, world!</p>
      <ExpensiveTree />
    </div>
  )
}

function ExpensiveTree() {
  let now = performance.now();
  while (performance.now() - now < 100) {
    // Artificial delay -- do nothing for 100ms
  }
  return <p>I am a very slow component tree.</p>
}


```

问题在于不管color什么时候改变，我们都会重绘`<ExpensiveTree />`，这个组件内部会被人为地延迟，所以很慢。

我可以在它外面加上`memo()`，然后大功告成。但关于这一点已经有很多现成的文章，因此我不会在这上面花时间，我想展示两种不同的方案。

## 方案1：把状态向下转移（Move state down）

如果你仔细看一下渲染部分的代码，你会注意到返回的组件树中，只有一部分关心当前的`color`状态：

```jsx {linenos=inline hl_lines=[2, "6-7"]}
export default function App() {
  let [color, setColor] = useState('red');
 
  return (
    <div>
      <input value={color} onChange={(e) => setColor(e.target.value)} />
      <p style={{ color }}>Hello, world!</p>
      <ExpensiveTree />
    </div>
  )
}
```

因此我们来把这部分抽象到一个`Form`组件中，并把状态向下转移：

```jsx {linenos=inline hl_lines=[4, 11, "14-15"]}
export default function App() {
  return (
    <>
      <Form />
      <ExpensiveTree />
    </>
  )
}

function Form() {
  let [color, setColor] = useState('red');
  return (
    <>
      <input value={color} onChange={(e) => setColor(e.target.value)} /> 
      <p style={{ color }}>Hello, world!</p>
    </>
  )
}
```
现在，当`color`改变时，只有`Form`会重新渲染，问题解决了。

## 方案2：提升内容层级（Lift Content Up）

如果一部分状态在`ExpensiveTree`之上被用到，那么就不能用方案1了。假设，我们把`color`放在父`div`上

```jsx {linenos=inline}
export default function App() {
  let [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={(e) => setColor(e.target.value)} 
      <p>Hello, world!</p>
      <ExpensiveTree />
    </div>
  )
}
```
目前看起来我们不能仅仅把没有用到`color`的部分放在另一个独立的组件里了，因为那会包含整个`div`，也就把`<ExpensiveTree />`给囊括进来了。这次再也无法避免使用`memo`了对吧。

或许，我们也能？

试试看你能否自己想出办法来。

...


...

...

...

答案出乎意料得直白：

```jsx {linenos=inline hl_lines=[4,5, 9, 14]}
export default function App() {
  return (
    <ColorPicker>
      <p>Hello, world!</p>
      <ExpensiveTree />
    </ColorPicker>
  )
}
function ColorPicker({ children }) {
  let [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={(e) => setColor(e.target.value)} />
      {children}
    </div>
  )
}
```

我们把`App`组件一分为二。依赖`color`的那部分，和`color`状态本身，一起移到了`ColorPicker`这个组件中。

不关心`color`的部分仍然待在`App`组件里，作为JSX传给`ColorPicker`，也就是`children`这个prop。

当`color`改变时，`ColorPicker`重绘。但它的从`App`拿到的`children`prop没有变，因此React不会访问这棵子树。

结果就是，`<ExpensiveTree />`没有重绘。

## 准则是什么？

在你用`memo`或`useMemo`做优化前，也许你可以先检查一下你是否可以把会改变的部分和不会改变的部分分离。

**有趣的是，本质上这些方案和性能优化没有任何关系。** 使用`children`这个prop去分离组件通常会让应用的数据流更容易跟踪，并且也减少了透传到子组件里的prop数量。性能提升（正如在上面的例子中所展示的）是额外的奖励，不是最初的目的。

在未来，这一模式同样解锁了更多性能上的好处。

例如，当`Server Components`稳定且被可接受时，我们的`ColorPicker`组件会从`server`端收到它的`children`。整个`<ExpensiveTree />`组件和它的部分都会运行在服务端，在客户端，即使顶层的React状态的更新也会“跳过”那些部分。

这是`memo`做不到的！但是，再次声明，这些方法是互为补充的。请不要忽略状态下移和内容提升。

然后，如果还不够，请使用Profiler并加上那些memo。

## 我之前好像在哪里读过这些？

[也许是的](https://kentcdodds.com/blog/optimize-react-re-renders)

这不是一个新点子。这是React组件组合模式下很自然的结果。它太过简单以至于常被低估，它值得更多一点关注！



