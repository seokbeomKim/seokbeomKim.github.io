---
title: "이맥스 Tree-sitter Major Mode 구현"
date: 2024-09-09T22:39:58+09:00
categories:
- emacs
tags:
- tree-sitter
- emacs
toc: true
draft: true
---

이 글에서는 이맥스에서 bitbake tree-sitter parser를 사용하기 위해 major mode를 구현하는 방법을 소개한다.

## Syntax Tree Generator 출현

Tree-sitter[^treesitter] 는 소스 코드를 syntax tree로 만드는 'parser generator tool'이다. Emacs, Neovim, Zed 등의
편집기에 기본으로 builtin 되어 제공된다. 편집기에서 지원하는 건 별개이지만 2018년에 처음 릴리즈 되었다고 하니 벌써
6년이나 된 기능이다. 처음 tree-sitter 출현을 접했을 때 들었던 생각은 '대체 왜 만든걸까?' 였다. 이미 syntax highlighting
기능은 오래 전부터 제공되던 기능이었기에 실시간으로 소스 코드로부터 syntax tree를 만들 수 있다는 게 어떤 장점을 가질지
예상하기 힘들었다.

## 레거시 방식

Emacs는 버퍼 확장자에 따라 언어 지원을 위한 major mode가 로드된다. 예를 들어, C언어(*.c, *.h)는 c-mode 패키지가 자동으로
로드되며 해당 패키지를 통해 syntax highlighting 기능이 제공된다. `C-h v auto-mode-alist` 명령어를 통해
`auto-mode-alist`를 확인하면 아래와 같이 c-mode가 할당된 확장자를 확인할 수 있다.

```
 ("\\.ii\\'" . c++-mode)
 ("\\.i\\'" . c-mode)
 ("\\.lex\\'" . c-mode)
 ("\\.y\\(acc\\)?\\'" . c-mode)
 ("\\.h\\'" . c-or-c++-mode)
 ("\\.c\\'" . c-mode)
 ("\\.\\(CC?\\|HH?\\)\\'" . c++-mode)
 ("\\.[ch]\\(pp\\|xx\\|\\+\\+\\)\\'" . c++-mode)
 ("\\.\\(cc\\|hh\\)\\'" . c++-mode)
```

그렇다면 이러한 Major Mode 패키지가 있는데도 불구하고 tree-sitter를 사용하는 이유는 무엇일까? 훨씬 빠르기 때문이다.
tree-sitter 이전까지 이맥스 패키지 대부분은 syntax highlighting을 위해 정규식을 사용했다. cc-mode 코드를 살펴보면 아래와
같이 아름다운 정규식으로 짜여져 있는 것을 볼 수 있다.

```
(defconst c-or-c++-mode--regexp
  (eval-when-compile
    (let ((id "[a-zA-Z_][a-zA-Z0-9_]*") (ws "[ \t]+") (ws-maybe "[ \t]*")
          (headers '("string" "string_view" "iostream" "map" "unordered_map"
                     "set" "unordered_set" "vector" "tuple")))
      (concat "^" ws-maybe "\\(?:"
                    "using"     ws "\\(?:namespace" ws
                                     "\\|" id "::"
                                     "\\|" id ws-maybe "=\\)"
              "\\|" "\\(?:inline" ws "\\)?namespace"
                    "\\(:?" ws "\\(?:" id "::\\)*" id "\\)?" ws-maybe "{"
              "\\|" "class"     ws id
                    "\\(?:" ws "final" "\\)?" ws-maybe "[:{;\n]"
              "\\|" "struct"     ws id "\\(?:" ws "final" ws-maybe "[:{\n]"
                                         "\\|" ws-maybe ":\\)"
              "\\|" "template"  ws-maybe "<.*?>"
              "\\|" "#include"  ws-maybe "<" (regexp-opt headers) ">"
              "\\)")))
  "A regexp applied to C header files to check if they are really C++.")
```

이렇게 성능이 떨어지는 방식으로 syntax highlighting 기능을 꾸역꾸역 제공하는 대신 tree-sitter를 이용하면 내가 원하는
파일의 syntax를 실시간으로 parser를 통해 얻어올 수 있고 indentation rule 이나 특정 키워드를 통해 각 노드들의 카테고리를
만들어 가져올 수 있다.

## Bitbake syntax highlighting 구현

이미 수많은 tree-sitter parser 들이 공개되어 있다. Github의 tree-sitter-grammars[^tree-sitter-grammars] 를 살펴보면
다양한 언어들에 대해 지원하고 있음을 알 수 있다. 그런데 이러한 parser가 있다고 해서 곧바로 이맥스에서 사용할 수 있는
것은 아니다. 현재 열려있는 버퍼에 대해 매핑되는 major mode를 정의하고 해당 mode에서 tree-sitter 파서가 주는 syntax
tree를 이용해 노드 별 카테고리를 만들고 syntax highlighting 컬러에 할당해줘야 한다.

[^treesitter]: https://tree-sitter.github.io/tree-sitter
[^tree-sitter-grammars]: https://github.com/tree-sitter-grammars

