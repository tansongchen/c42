# c42 简介

C 输入（下简称 C）是百度贴吧用户 @dsscicin 于 2015 年发布的字词混打的形音码输入方案。C 对 GB 字库中的 6729 字进行了编码（去除部分部首），在此范围内具有三码重码极低的特点（即 C 原为四码方案，但只取前三码时仅有 873 个选重），故适于改编为四二顶单字输入方案。

在改编过程中，出于易学性等考虑，简化了一部分拆分规则，并去除了一定量的低频字根，同时保持重码数量基本不变。

# 配置方法

1. 下载 main 分支上的所有文件并复制到 Rime 用户目录下；您也可以用 `plum` 脚本安装，即运行命令 `bash rime-install tansongchen/c42`；
2. 在 `default.custom.yaml` 中添加方案 `c42`；
3. 重新部署。

# 输入规则

## 四二顶

四二顶是一种特殊的顶功模式。在四二顶方案中，取交集为空的两键集 A、B，A 与 B 的并集为 U，则单字有且仅有两种编码，分别为 UA 和 UAUB。（详细论述见拙作《顶功集萃》。）

本方案中，取 A = 【a-z;】共 27 键，B =【空格】共 1 键，实际编码空间为 AA （27 × 27）和 AAAB （27 × 27 × 27 × 1），另外加入一简三重 AC （C =【,./】）。

## 拆分、选根与编码

### 拆分

本方案选取字根数量较多，以常用部首为基准，拆字较为直观明晰。本方案将汉字拆分为字根后，依照字根首笔的顺序将字根排列成字根序列，然后从字根序列中选取适当的字根编码。拆分时，共有 4 条规则，优先级依次降低：

1. 字根数量尽可能少。例：因 = 【囗 大】，而不是【冂 大 一】；
2. 字根数量相同时，字根之间尽可能不交叉。例：来 = 【未 丷】，而不是 【一 米】；
3. 字根数量相同、且交叉情况相同时，字根序列应该尽可能符合笔顺。例：戋 = 【一 戈】，而不是 【戈 一】；
4. 字根数量相同、交叉情况相同、符合笔顺情况也相同时，字根序列中靠前的字根包含的笔画数要尽量多，靠后的字根尽量少。例：首 = 【䒑 丿 目】，而不是【丷 丆 目】；

### 选根

字根数量 ≤ 3 时，全取。

字根数量 > 3 时，出于离散考虑，本方案并不采用常规的【首、二、末】这一相对低效的选根方式。在选根时，本方案吸收四角号码检字法精华，先取四角字根，再按字根序补充，最后按字根序排列。具体可以分 3 种情况：

1. 四个角有四个字根，舍弃右上角。例：乾 = 【十 十 乙】
2. 四个角有三个字根，则直接全取。例：到 = 【一 土 刂】
3. 四个角有两个字根或一个字根，则取完所有角后，按照字根序再补一根或两根。例：感 = 【戊 心】补【一】，排列为【戊 一 心】，国 = 【囗】补【王 丶】，排列为【囗 王 丶】。

如果遇到双编码字根，取码的时候要视为两个字根，如絷，拆分为【执 幺 小】，取码认为是【执1 执2 小】。

注：这些规则是改编时简化得到的，与原作者拆分方式不一致（原作拆分方式更为复杂）。

### 编码

字根图参见 Releases，此处不再复制。本方案采用类似于五笔的整体布局，并兼容了表形的特点，字根易于记忆。部分字根为双编码，需要特别注意。编码也分 3 种情况：

1. 有 3 个字根，则各自编码即可。例：说 = 【讠丷 儿】= 【u k a】= uka；
2. 有 2 个字根，则补拼音首字母。例：我 = 【手 戈】 = 【j l】= jlw；
3. 有 1 个字根，则补拼音首字母和末字母。例：一 = 【一】 = 【t】= tyi 。

## 简码

对于编码长度为 3 的全码来说，需要击空格上屏，键长为 4。除此之外，还有一些键长为 2 的编码种类。

### 常规简码

常规简码即取全码的前 2 码，无需空格上屏。

### 一简三重码

用【,./】三个键选重。

### 无理码

非常规简码并非全码前 2 码，共有 36 字，需要特别记忆。分为 2 类：

1. 取全码的第 1 码和第 3 码。例：一，全码为 tyi，简码为 ti；我，全码为 jlw，简码为 jw。此类共有 30 字。
2. 改编前一简编入二简时加 k 或 d。例：是，全码为 btz，简码为 bk。共 6 字。

### 简码词

简码二字词，分取两字的第 1 码，共 70 个。

### 特码

特码不属于正常编码，可根据个人习惯选用。特码用于三码重码且两个字都很常用时的避重。例：仪，全码为 iux，与“信”重码，故取其首根 i 和拼音 yi 组成特码。

## 词语

由于 c42 是以单字为主的输入方案，所以并没有常规的词组编码。但是，如果打开输入方案中的 `prediction` 选项时，则会在单字后面提示相应的联想词语。

### 导入联想词库

在本仓库的文件中有一个 `c42.import.txt`，里面存放了从国家语委现代汉语语料库词频中生成的六千余条常用词。您可以用 `rime_dict_manager` 来导入 c42 的用户词典：

```bash
rime_dict_manager -i c42 c42.import.txt
```

### 数字的左右互击

导入该文件后，在联想开启的情况下，可以看到类似下面的联想内容：

![](https://images.tansongchen.com/1707510743.png)

若单字的末码在右手，则建议用 2, 3, 4, 5, 6 来选择第一至五个联想词；反之，则建议用 0, 9, 8, 7, 6 来选择第一至五个联想词。这样的打法可以明显降低数字的击键难度。候选上的注释也会随着左手和右手的不同而改变：

![](https://images.tansongchen.com/1707510901.png)

### 手动造词

您还可以根据自己的需要来添加更多的联想词。方法为：在已有编码的情况下，按一下单引号键进入造词状态，然后继续输入该词中的所有单字，按下回车结束。然后，该词就会出现在联想词中。

例如，想造「顶功」一词，在已经输入［顶 jid］的情况下，按一下单引号，系统提示已进入造词状态：

![](https://images.tansongchen.com/1707511157.png)

然后继续输入［功 ;;］，两字均完成之后留在缓冲栏中，并未上屏：

![](https://images.tansongchen.com/1707511327.png)

然后回车确认，再打［顶 jid］时，就可以看到

![](https://images.tansongchen.com/1707511393.png)

联想词是动态调频的，意味着自造的词以及常用的词总会出现在前面，方便使用。

---

若想在没有编码的情况下直接进入造词模式，则不能按单引号，而是要按 Control+Shift+6。

## 反查

### 拼音反查

以「\`」为引导，输入汉字的全拼，查本方案编码。例：

![](https://images.tansongchen.com/1707509753.png)

### 笔画反查

以「\`」为引导，输入汉字的笔画，查本方案编码。例：

![](https://images.tansongchen.com/1707509835.png)

笔画反查也可以作为一种输入本方案主码表中没有的生僻字的办法。

## 评价

从以下几个方面讨论：

1. 键长：2.44，高于小兮等二码顶（二码顶在 2.25 - 2.30 之间），但低于三码定长（至至郑码等，在 2.50 -
   2.70 之间）。
2. 离散：GB 集 6729 字（多音字只取其中一音）全码选重数为 860（五笔全码为 261）。经过码表处理（两键
   字不出全码）后，最终选重数为 669，加权选重 0.37% （五笔一二三简不出全后为 0.25%，真码一简不出全
   后为 0.24%，可以说，C 已经用 3 码做到了其他形码 4 码的水平）。
3. 手感：按键分布合理，手感优于一般形码。
4. 易学：字根难度相比一般二码顶稍高，但无理码难度低。上手后，确定性高（只有二码、四码）。

# 参考资料与致谢

## 原作者提供的信息表与说明

百度贴吧发布贴 http://tieba.baidu.com/p/3779915194 （2019 年 11 月 25 日更新：该贴已被删除）。但其中的下载链接已指向其他输入方案（原作者停止了对 C 输入的维护）。

信息表中包含了字音，但没有考虑多音字，每字只有一个编码。

## 字频

C 输入（四二顶版）选取的字频来自于输入法吧吧友「mgcgogo」所统计的「十亿网络小说字频」，顾名思义，是统计大量小说得到的字频。

- 优点：比较接近日常使用。
- 缺点：「魔」等玄幻类用字字频偏高。

## 测试工具

使用了法月开发的「科学形码测评系统 1.6」。

## 致谢

- 对原作者 Cicin 表示感谢。
- 对以上制作输入方案所用资料的提供者表示感谢。
- 对法月提供的关于四二顶的介绍表示感谢。
